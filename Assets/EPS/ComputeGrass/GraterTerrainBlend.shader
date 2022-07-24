Shader "Unlit/GraterTerrainBlend"
{
    Properties
    {
        _TexA ("基础颜色A", 2D) = "white" {}
        _TintA ("染色A", Color) = (1, 1, 1, 1)
        _TexB ("基础颜色", 2D) = "white" {}
        _TintB ("染色B", Color) = (1, 1, 1, 1)
        _SplatMap ("地形混合图", 2D) = "black" {} //no splat
        
        
        _ORMTexture ("AO&粗糙&金属度贴图", 2D) = "white" {}
        _NormalMap ("法线贴图", 2D) = "bump" {}
        

        _AOMultiplier("AO强度", Range(0, 1)) = 1.0
        _RoughnessMultiplier ("粗糙度强度", Range(0, 1)) = 1.0
        _MetallicMultiplier ("金属度强度", Range(0, 1)) = 1.0
        _EnvironmentMultiplier ("环境光强度", Range(0, 1)) = 1.0
        _NormalMultiplier ("法线强度", Range(0, 1)) = 1.0

        [Toggle(ENABLE_NORMAL)] _EnableNormal_Attr("开启法线", Int) = 1
    }
    SubShader
    {
        
        CGINCLUDE
        #include "UnityCG.cginc"
        #include "UnityLightingCommon.cginc"
        #include "AutoLight.cginc"
        #include "UnityImageBasedLighting.cginc"

        #pragma multi_compile __ ENABLE_NORMAL
        
        sampler2D _TexB;
        sampler2D _TexA;
        sampler2D _SplatMap;
        sampler2D _ORMTexture;
        
        sampler2D _NormalMap;

        fixed _NormalMultiplier;
        float4 _TexB_ST;
        fixed4 _ShadowColor;
        fixed4 _TintA;
        fixed4 _TintB;
        fixed _AOMultiplier;
        fixed _RoughnessMultiplier;
        fixed _MetallicMultiplier;
        fixed _EnvironmentMultiplier;
        fixed _EmissionMultiplier;

        
        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
                
            fixed3 normal : NORMAL;
            fixed4 tangent : TANGENT;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            UNITY_FOG_COORDS(1)
            float4 pos : SV_POSITION;
            //light coordinates...
            LIGHTING_COORDS(2, 3)
            fixed3 normal : TEXCOORD6;
            #if defined(ENABLE_NORMAL)
            fixed3 tangent : TEXCOORD7;
            fixed3 bitangent : TEXCOORD8;
            #endif
            half3 viewDir : TEXCOORD4;
            float3 worldPos : TEXCOORD5;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _TexB);
            o.normal = UnityObjectToWorldNormal(normalize(v.normal));//mul(unity_ObjectToWorld, v.normal);
            #if defined(ENABLE_NORMAL)
            o.tangent = UnityObjectToWorldDir(normalize(v.tangent.xyz));
            o.bitangent = cross(o.normal, o.tangent.xyz) * v.tangent.w;
            #endif
            o.viewDir = WorldSpaceViewDir(v.vertex);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex);
            UNITY_TRANSFER_FOG(o,o.pos);
            TRANSFER_VERTEX_TO_FRAGMENT(o);
            return o;
        }

        inline float get_lod_from_roughness(fixed roughness){
            return roughness * (1.7 - 0.7 * roughness) * UNITY_SPECCUBE_LOD_STEPS;
        }


        inline float dfg_d(fixed nDotH, float roughness){
            fixed a = roughness * roughness;
            fixed alpha2 = a * a;
            fixed nDotH2 = nDotH * nDotH;
            float denom = nDotH2 * (alpha2 - 1) + 1;
            denom = denom * denom * UNITY_PI;
            return alpha2 / denom;
        }

        ENDCG


        Pass
        {
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardBase"
            }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase 


            fixed4 frag (v2f i) : SV_Target
            {
                //setup
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 normal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 reflDir = reflect(-viewDir, normal);

                ////////////////////// NORMAL MAPPING ////////////////////////
                #if defined(ENABLE_NORMAL)
                float3x3 TBN = float3x3(normalize(i.tangent), normalize(i.bitangent), normalize(i.normal));
                TBN = transpose(TBN);
                //tweak normal:
                fixed3 tangentNormal = tex2D(_NormalMap, i.uv).xyz;
				tangentNormal = normalize(tangentNormal * 2 - 1);
                tangentNormal = lerp(fixed3(0, 0, 1), tangentNormal, _NormalMultiplier);
                //tangentNormal = normalize(tangentNormal);
                normal = mul(TBN, tangentNormal);
                #endif

                //computations
                fixed nDotH = saturate(dot(normal, halfDir));

                //sample
                fixed4 ormSample = tex2D(_ORMTexture, i.uv);
                fixed ao = 1 - (1 - ormSample.r) * _AOMultiplier;
                fixed roughness = 1 - (1 - ormSample.g) * _RoughnessMultiplier;
                fixed metallic = ormSample.b * _MetallicMultiplier;

                ////////////////////// DIRECT LIGHTING - DIFFUSE ////////////////////////////
                fixed4 splatMap = tex2D(_SplatMap, i.uv);
                fixed4 diffuseA = tex2D(_TexA, i.uv);
                diffuseA.rgb *= _TintA.rgb;
                fixed4 diffuseB = tex2D(_TexB, i.uv);
                diffuseB.rgb *= _TintB.rgb;
                fixed4 diffuse = diffuseA * splatMap.r + diffuseB * splatMap.g;

                fixed lighting = dot(normal, lightDir);
                lighting = saturate(lighting);
                fixed shadowSample = LIGHT_ATTENUATION(i);
                lighting = min(shadowSample, lighting);
                lighting = smoothstep(0.2f, 0.46f, lighting);
                lighting *= ao;

                fixed4 lightColor = lighting * _LightColor0;
                

                ////////////////////// DIRECT LIGHTING - SPECULAR ////////////////////////////
                half lod = get_lod_from_roughness(roughness);
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, lod);
                half3 indirectSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                diffuse.rgb = lerp(indirectSpecular.rgb, diffuse.rgb, roughness);


                fixed4 specularColor = lerp(1.0, diffuse, metallic);
                half4 highlights = dfg_d(nDotH, roughness) * specularColor * (1 - roughness);


                ////////////////////// DIRECT LIGHTING - RAMPING ////////////////////////////


                ///////////////////// DIRECT LIGHTING - ENVIRONMENT /////////////////////////
                half3 indirectColor = ShadeSH9(float4(normal, 1));
                //return fixed4(indirectColor, 1.0f);

                ///////////////////// EMISSION //////////////////////////////////////////////
                
                fixed4 result = diffuse * lightColor;
                result += (highlights * (1 - roughness)) * lightColor;
                result.rgb += diffuse * indirectColor * _EnvironmentMultiplier;

                UNITY_APPLY_FOG(i.fogCoord, col);
                // fixed4 coloredLighting = rampCol * diffuse;//lerp(_ShadowColor, fixed4(1, 1, 1, 1), lighting);
                return result;//fixed4(normalize(i.normal), 1.0f);
            }
            ENDCG
        }



        Pass
        {
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardAdd"
            }
            LOD 100
            Blend One One
            CGPROGRAM


            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows


            fixed4 frag (v2f i) : SV_Target
            {
                //setup
                fixed3 lightDir;
                if(_WorldSpaceLightPos0.w == 0){
                    //directional light
                    lightDir = normalize(_WorldSpaceLightPos0);
                }
                else{
                    lightDir = normalize(_WorldSpaceLightPos0 - i.worldPos);
                }

                fixed3 normal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 reflDir = reflect(-viewDir, normal);

                //computations
                fixed nDotH = saturate(dot(normal, halfDir));

                //sample
                fixed4 ormSample = tex2D(_ORMTexture, i.uv);
                fixed ao = 1 - (1 - ormSample.r) * _AOMultiplier;
                fixed roughness = 1 - (1 - ormSample.g) * _RoughnessMultiplier;
                fixed metallic = ormSample.b * _MetallicMultiplier;

                ////////////////////// DIRECT LIGHTING - DIFFUSE ////////////////////////////
                fixed4 splatMap = tex2D(_SplatMap, i.uv);
                fixed4 diffuseA = tex2D(_TexA, i.uv);
                diffuseA.rgb *= _TintA.rgb;
                fixed4 diffuseB = tex2D(_TexB, i.uv);
                diffuseB.rgb *= _TintB.rgb;
                fixed4 diffuse = diffuseA * splatMap.r + diffuseB * splatMap.g;

                fixed lighting = dot(normal, lightDir);
                lighting = saturate(lighting);
                fixed shadowSample = LIGHT_ATTENUATION(i);
                lighting = min(shadowSample, lighting);
                lighting = smoothstep(0.2f, 0.46f, lighting);
                lighting *= ao;

                fixed4 lightColor = lighting * _LightColor0;
                

                ////////////////////// DIRECT LIGHTING - SPECULAR ////////////////////////////
                half lod = get_lod_from_roughness(roughness);
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, lod);
                half3 indirectSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                diffuse.rgb = lerp(indirectSpecular.rgb, diffuse.rgb, roughness);


                fixed4 specularColor = lerp(1.0, diffuse, metallic);
                half4 highlights = dfg_d(nDotH, roughness) * specularColor;

                //return specularColor;


                ////////////////////// DIRECT LIGHTING - RAMPING ////////////////////////////

                fixed4 result = lightColor * 0.3;
                result += (highlights * (1 - roughness)) * lightColor;

                UNITY_APPLY_FOG(i.fogCoord, col);
                
                // fixed4 coloredLighting = rampCol * diffuse;//lerp(_ShadowColor, fixed4(1, 1, 1, 1), lighting);
                return result;//fixed4(normalize(i.normal), 1.0f);
            }
            ENDCG
        }

    }
    Fallback "VertexLit"
}
