Shader "Unlit/CustomPBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _Roughness ("Roughness", Range(0, 1)) = 1.0
        _Metallic ("Metallic", Range(0, 1)) = 1.0
    }
    SubShader
    {
        
        LOD 100
        CGINCLUDE 
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #define PI 3.1415926
            //#define IMAGE_BASED_LIGHTING
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
                float4 worldPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Roughness;
            fixed _Metallic;
            fixed4 _Color;
            //float3 _WorldSpaceLightPos0;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            
            ////////////////////// BRDF /////////////////////////

            float dfg_d(fixed3 normal, fixed3 halfVector, float roughness){
                fixed a = roughness * roughness;
                fixed alpha2 = a * a;
                fixed nDotH2 = max(dot(normal, halfVector), 0.0);
                nDotH2 *= nDotH2;
                float denom = nDotH2 * (alpha2 - 1) + 1;
                denom = denom * denom * PI;
                return alpha2 / denom;
            }

            float3 dfg_f(fixed3 d1, fixed3 d2, float3 f0){
                fixed cosTheta = saturate(dot(d1, d2));
                return (f0) + (1.0 - f0) * pow(saturate(1.0 - cosTheta), 5.0);
            }
        
            float schlick_ggx(fixed3 n, fixed3 dir, fixed k){
                fixed nDotDir = saturate(dot(n, dir));
                return saturate(nDotDir / (nDotDir * (1.0 - k) + k));
            }

            float dfg_g(fixed3 normal, fixed3 viewVector, fixed3 lightVector, fixed a){
                
                #ifdef IMAGE_BASED_LIGHTING
                    //pretty much guarantted to use ibl at this stage
                    fixed k = a * a / 2;
                #else
                    float r = a + 1.0;
                    fixed k = r * r / 8.0;
                #endif
                return schlick_ggx(normal, viewVector, k) * schlick_ggx(normal, lightVector, k);
            }

            float3 cook_torrace(float3 baseColor, fixed3 normal, fixed3 lightDir, fixed3 viewDir, fixed roughness){
                //omega_o - viewDir
                //omega_i - lightDir
                fixed3 halfVector = normalize(viewDir + lightDir);
                fixed3 f0 = fixed3(0.04, 0.04, 0.04);
                f0 = lerp(f0, baseColor, _Metallic);
                float d = dfg_d(normal, halfVector, roughness);
                float3 f = dfg_f(halfVector, normal, f0);
                float g = dfg_g(normal, viewDir, lightDir, roughness);
                
                float3 ks = f;
                float3 kd = 1.0 - ks;
                kd *= 1.0 - _Metallic;
                
                float3 kd_cpi = (kd * baseColor / PI);
                fixed ks_denom = 4.0 * saturate(dot(viewDir, normal)) * saturate(dot(lightDir, normal));
                ks_denom = max(ks_denom, 0.001);
                float3 ks_dfg = d * f * g / ks_denom;
                return (kd_cpi + ks_dfg); 
                //return kd_cpi;
            }

            fixed4 linear_space_color(fixed4 color){
                color = pow(color, 2.2);
                color *= (color + 1.0);
                return color;
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
                fixed4 col = linear_space_color(tex2D(_MainTex, i.uv)) * _Color;

                //since everything is in gamma space...
                //we should probably convert the color to gamma space too...

                ///////////// BASE COMPUTATIONS /////////////////
                fixed3 worldNormal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed3 halfVector = normalize(viewDir + lightDir);

                
                fixed3 f0 = fixed3(0.04, 0.04, 0.04);
                f0 = lerp(f0, col, _Metallic);

                ///////////// UNITY OPERATIONS ///////////////////
                fixed NdotL = max(dot(worldNormal, lightDir), 0.0);
                fixed lighting = LIGHT_ATTENUATION(i);
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return dfg_d(worldNormal, halfVector, _Roughness);
                //return float4(dfg_f(worldNormal, halfVector, f0), 1.0);
                //return dfg_g(worldNormal, viewDir, lightDir, _Roughness);
                float3 cookTorraceInfluence = cook_torrace(col, worldNormal, lightDir, viewDir, _Roughness);
                
                float3 Lo = cookTorraceInfluence * _LightColor0 * min(NdotL, lighting);
                float3 ambient = 0.03 * col;

                //everything is in gamma space...
                float3 color = Lo + ambient;
                color = color / (color + 1.0);
                color = pow(color, 1.0 / 2.2);

                return float4(color, 1.0);
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
                fixed4 col = linear_space_color(tex2D(_MainTex, i.uv)) * _Color;

                ///////////// BASE COMPUTATIONS /////////////////
                fixed3 worldNormal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                //////////// DIRECTIONAL OR POINT? ///////////////
                fixed3 lightDir;
                if(_WorldSpaceLightPos0.w == 0){
                    //directional light
                    lightDir = normalize(_WorldSpaceLightPos0);
                }
                else{
                    lightDir = normalize(_WorldSpaceLightPos0 - i.worldPos);
                }
                
                fixed3 halfVector = normalize(viewDir + lightDir);

                
                fixed3 f0 = fixed3(0.04, 0.04, 0.04);
                f0 = lerp(f0, col, _Metallic);

                ///////////// UNITY OPERATIONS ///////////////////
                fixed NdotL = max(dot(worldNormal, lightDir), 0.0);
                fixed lighting = LIGHT_ATTENUATION(i);
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return dfg_d(worldNormal, halfVector, _Roughness);
                //return float4(dfg_f(lightDir, worldNormal, f0), 1.0);
                //return dfg_g(worldNormal, viewDir, lightDir, _Roughness);
                float3 cookTorraceInfluence = cook_torrace(col, worldNormal, lightDir, viewDir, _Roughness);
                float3 Lo = cookTorraceInfluence * _LightColor0 * min(NdotL, lighting);
                float3 color = Lo;
                color = color / (color + 1.0);
                color = pow(color, 1.0 / 2.2);

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
