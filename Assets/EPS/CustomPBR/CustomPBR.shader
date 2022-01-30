Shader "Grater/CustomPBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Normal ("Normal Map", 2D) = "bump" {}
        _Color ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _MetallicTex ("Metallic Texture", 2D) = "white" {} //default to white, so we can multiply thsi with the metallic value
        [Gamma]_Metallic ("Metallic", Range(0, 1)) = 1.0
        _SmoothnessTex ("Smoothness (Roughness) Texture", 2D) = "white" {} // same as above
        _Smoothness ("Smoothness Multiplier)", Range(0, 1)) = 1.0
        _BRDF_Lut("BRDF Lookup", 2D) = "white" {}
        [Toggle]_RoughnessWorflow("Use Roughness Workflow", Float) = 0.0
        [Toggle]_AlphaIsSmoothness("Alpha is Smoothness (Roughness)", Float) = 0.0
    }
    SubShader
    {
        
        LOD 100
        CGINCLUDE 
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "UnityImageBasedLighting.cginc"
            #include "GraterPBR.cginc"
            
            //#define IMAGE_BASED_LIGHTING
 
            ////////////// REFLECTION PROBE STUFF /////////////////
            
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //we'll deal with you later...
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float3 bitangent : BINORMAL;
                float3 viewDir : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
                float4 worldPos : TEXCOORD5;
                
            };

            sampler2D _MainTex;
            sampler2D _Normal;
            sampler2D _MetallicTex;
            sampler2D _SmoothnessTex;
            sampler2D _BRDF_Lut;
            float4 _MainTex_ST;
            fixed _Smoothness;
            fixed _Metallic;
            fixed4 _Color;
            int _RoughnessWorflow;
            int _AlphaIsSmoothness;
            //UNITY_DECLARE_TEXCUBE(_CubeMap);
            //half4 _CubeMap_HDR;
            //float3 _WorldSpaceLightPos0;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);

                float3 normal = UnityObjectToWorldNormal(v.normal);
                float3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 bitangent = cross(normal, tangent) * v.tangent.w;

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.bitangent = bitangent;
                o.tangent = tangent;
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            
            
            inline fixed decode_roughness(fixed value){
                fixed roughness;
                if(_RoughnessWorflow){
                    roughness = 1.0 - ((1.0 - value) * (_Smoothness));
                }
                else{
                    roughness = 1.0 - value * _Smoothness;
                }
                roughness *= roughness;
                roughness = lerp(0.02, 0.98, roughness);
                return roughness;
            }

            inline fixed3 map_normal(float2 uv, fixed3 normal, fixed3 tangent, fixed3 bitangent){
                fixed3 tangentSpaceNormal = UnpackNormal(tex2D(_Normal, uv));
                float3x3 tbn = float3x3(
                    tangent.x, bitangent.x, normal.x,
                    tangent.y, bitangent.y, normal.y,
                    tangent.z, bitangent.z, normal.z
                );
                return normalize(mul(tbn, tangentSpaceNormal));
            }

            inline void sample_smoothness_metallic(float2 uv, out fixed smoothness, out fixed metallic){

                
                fixed4 metallic_val = tex2D(_MetallicTex, uv) * _Metallic;
                metallic = metallic_val.r;
                if(_AlphaIsSmoothness){
                    smoothness = metallic_val.a;
                }
                else{
                    smoothness = tex2D(_SmoothnessTex, uv);
                }
            }


            inline float3 indirect_lighting(float3 albedo, float3 normal, float nDotV, float3 reflDir, fixed3 f0, fixed roughness, fixed metallic){
                nDotV = lerp(0, 0.99, nDotV);
                
                ////////////////// INDIRECT IRRADIANCE ///////////////////////////////
                half3 indirectColor = ShadeSH9(float4(normal, 1));
                float3 f = dfg_f(nDotV, f0, roughness);
                float kd = (1 - f) * (1 - metallic);

                float3 indirectDiffuse = indirectColor * kd * albedo;
                
                ///////////////// INDIRECT REFLECTION ///////////////////////////////
                float2 environmentBrdf = tex2D(_BRDF_Lut, float2(nDotV, roughness)).xy;
                //return float3(environmentBrdf, 0);
                float lod = get_lod_from_roughness(roughness);
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, lod);
                half3 indirectSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                
                indirectSpecular = indirectSpecular * (f * environmentBrdf.x + environmentBrdf.y);
                return indirectDiffuse + indirectSpecular;
            }

            inline float3 direct_lighting(half3 albedo, fixed nDotV, fixed nDotL, fixed nDotH, fixed vDotH, fixed roughness, fixed metallic, fixed f0){
                float d = dfg_d(nDotH, roughness);
                float3 f = dfg_f_roughless(vDotH, f0, roughness);
                float g = dfg_g(nDotV, nDotL, roughness);

                float3 ks = f;
                float3 kd = (1.0 - f) * (1.0 - metallic);
                float3 diffuse = kd * albedo;
                fixed ks_denom = 4 * nDotV * nDotL;
                ks_denom = max(ks_denom, 0.001);
                float3 reflection = d * f * g / ks_denom;
                return diffuse + reflection * PI;
            }

        ENDCG
        Pass
        {
            Tags {
                 "RenderType"="Opaque" 
                 "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            fixed4 frag (v2f i) : SV_Target
            {
                ///////////// SAMPLING TEXTURES ////////////////
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                fixed smoothness, metallic;
                sample_smoothness_metallic(i.uv, smoothness, metallic);
                //since everything is in gamma space...
                //we should probably convert the color to gamma space too...

                ///////////// BASE COMPUTATIONS /////////////////
                fixed3 worldNormal = map_normal(i.uv, normalize(i.normal), normalize(i.tangent), normalize(i.bitangent));//normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed3 halfVector = normalize(viewDir + lightDir);
                
                fixed roughness = decode_roughness(smoothness);
                metallic = lerp(0.02, 0.98, metallic);

                fixed nDotV = saturate(dot(worldNormal, viewDir));
                fixed nDotL = saturate(dot(worldNormal, lightDir));
                fixed nDotH = saturate(dot(worldNormal, halfVector));
                fixed vDotH = saturate(dot(viewDir, halfVector));

                fixed3 f0 = unity_ColorSpaceDielectricSpec.rgb;
                f0 = lerp(f0, col, metallic);

                ///////////// UNITY OPERATIONS ///////////////////
                fixed lighting = LIGHT_ATTENUATION(i);
                
                //return dfg_d(worldNormal, halfVector, _Roughness);
                //return float4(dfg_f(worldNormal, viewDir, f0, roughness), 1.0);
                //return dfg_g(worldNormal, viewDir, lightDir, _Roughness);
                
                ///////////// COMPOSITION ////////////////////////
                float3 direct = direct_lighting(col, nDotV, nDotL, nDotH, vDotH, roughness, metallic, f0);
                float3 indirect = indirect_lighting(col, worldNormal, nDotV, reflect(-viewDir, worldNormal), f0, roughness, metallic);
                float3 ambient = 0.03 * col;
                direct += ambient;
                float3 lightAmount =_LightColor0.rgb * min(nDotL, lighting);

                float4 composite = float4(direct * lightAmount + indirect + saturate(pow(1.0 - nDotV, 6) * (1 - vDotH)), 1.0);
                UNITY_APPLY_FOG(i.fogCoord, composite);
                //return float4(ShadeSH9(float4(worldNormal, 1)), 1);
                return composite;
            }
            ENDCG
        }
        
        Pass
        {
            Tags {
                 "RenderType"="Opaque" 
                 "LightMode"="ForwardAdd"
            }
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows

            fixed4 frag (v2f i) : SV_Target
            {
                ///////////// SAMPLING TEXTURES ////////////////
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                fixed smoothness, metallic;
                sample_smoothness_metallic(i.uv, smoothness, metallic);
                //since everything is in gamma space...
                //we should probably convert the color to gamma space too...

                //////////// DIRECTIONAL OR POINT? ///////////////
                fixed3 lightDir;
                if(_WorldSpaceLightPos0.w == 0){
                    //directional light
                    lightDir = normalize(_WorldSpaceLightPos0);
                }
                else{
                    lightDir = normalize(_WorldSpaceLightPos0 - i.worldPos);
                }

                ///////////// BASE COMPUTATIONS /////////////////
                fixed3 worldNormal = map_normal(i.uv, normalize(i.normal), normalize(i.tangent), normalize(i.bitangent));
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 halfVector = normalize(viewDir + lightDir);

                fixed roughness = decode_roughness(smoothness);
                metallic = lerp(0.02, 0.98, metallic);

                fixed nDotV = saturate(dot(worldNormal, viewDir));
                fixed nDotL = saturate(dot(worldNormal, lightDir));
                fixed nDotH = saturate(dot(worldNormal, halfVector));
                fixed vDotH = saturate(dot(viewDir, halfVector));

                fixed3 f0 = unity_ColorSpaceDielectricSpec.rgb;
                f0 = lerp(f0, col, metallic);



                ///////////// UNITY OPERATIONS ///////////////////
                fixed lighting = LIGHT_ATTENUATION(i);
                
                //return dfg_d(worldNormal, halfVector, _Roughness);
                //return float4(dfg_f(worldNormal, viewDir, f0, roughness), 1.0);
                //return dfg_g(worldNormal, viewDir, lightDir, _Roughness);
                
                ///////////// COMPOSITION ////////////////////////
                float3 direct = direct_lighting(col, nDotV, nDotL, nDotH, vDotH, roughness, metallic, f0);
                float3 lightAmount =_LightColor0.rgb * min(nDotL, lighting);
                float4 color = float4(direct * lightAmount, 1.0);
                //UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDCG
        }
        
    }
    Fallback "VertexLit"
}
