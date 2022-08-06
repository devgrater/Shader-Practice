﻿Shader "Unlit/CheapWaterSurface"
{
    Properties
    {
        _FoamTex ("白浪材质", 2D) = "black" {}
        _DistortionTex ("扭曲材质", 2D) = "gray" {}
        _NoiseCutoff ("白浪强度", Range(0, 1)) = 0.5
        _ShallowColor ("深水颜色", Color) = (1.0,1.0,1.0,1.0)
        _DeepColor ("浅水颜色", Color) = (1.0,1.0,1.0,1.0)
        _MaxWaterDepth ("水体深度", Float) = 1.0
        _Wave1 ("波浪1设置 (波浪角度, 波长, 波幅, 波浪速度)", Vector) = (1,1,0,0)
        _Wave2 ("波浪2设置 (波浪角度, 波长, 波幅, 波浪速度)", Vector) = (1,1,0,0)
        _Wave3 ("波浪3设置 (波浪角度, 波长, 波幅, 波浪速度)", Vector) = (1,1,0,0)
        _WaterTransparency ("水体不透明度", Range(0.0, 1.0)) = 0.2

        _CausticTex ("焦散材质", 2D) = "black" {}
        _CausticTiling ("焦散平铺", Float) = 3.0
        _CausticPower ("焦散强度", Range(0, 1)) = 0.3
        _CausticBaseDepth ("焦散深度", Float) = 10.0

        //_OffsetCeil ("OffsetCeil", Float) = 1.0
    }
    SubShader
    {
            Tags {
                "RenderType"="Transparent"
                "Queue"="Transparent+1" 
                
            }

        GrabPass{

        }

        Pass
        {
            Tags {
                "RenderType"="Transparent"
                "Queue"="Transparent+1" 
                
            }

            //AlphaToMask On
            //Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Off
            
            LOD 100


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            //#include "AutoLight.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float4 screenPosition : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD4;
                //LIGHTING_COORDS(5, 6)
            };

            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize; //welp...

            sampler2D _FoamTex;
            float4 _FoamTex_ST;
            sampler2D _CausticTex;
            float4 _CausticTex_ST;
            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;

            float4 _ShallowColor;
            float4 _DeepColor;
            float _MaxWaterDepth;
            float _NoiseCutoff;
            float4 _Wave1, _Wave2, _Wave3;
            float _WaterTransparency;
            float _CausticTiling;
            float _CausticBaseDepth;
            float _CausticPower;
            float _OffsetBase;
            fixed _BlurAmount;


            float3 gerstner(float4 data, float4 vertex, out float3 tangent, out float3 binormal){
                //r channel: angle (convert to vector)
                //g channel: wavelength
                //b channel: steepness
                //a channel: speed

                //r channel:
                float2 d = normalize(float2(sin(data.r), cos(data.r)));
                float k = UNITY_PI / data.g;
                float f = k * (dot(d, vertex.xz) - data.a * _Time.y);
                float a = data.b / k;

                tangent = float3(
                    -d.x * d.x * (data.b * sin(f)),
                    d.x * (data.b * cos(f)),
                    -d.x * d.y * (data.b * sin(f))
                );
                binormal = float3(
                    -d.x * d.y * (data.b * sin(f)),
                    d.y * (data.b * cos(f)),
                    -d.y * d.y * (data.b * sin(f))
                );


                //float3 tangent = normalize(float3(1, k * a * cos(f), 0));
                //normal = fixed3(-tangent.y, tangent.x, 0.0f);
                return float3(d.x * cos(f) * a, sin(f) * a, d.y * cos(f) * a);
            }

            v2f vert (appdata v)
            {
                v2f o;
                /*
                float2 d = normalize(_Wave1);
                float k = UNITY_PI / _Wavelength;
                float f = k * (dot(d, v.vertex.xz) - _Speed * _Time.y);
                float a = _Steepness / k;

                
                v.vertex.x += d.x * cos(f) * a;
                v.vertex.z += d.y * cos(f) * a;
                v.vertex.y = sin(f) * a;*/
                float3 tangent = float3(1, 0, 0), bitangent = float3(0, 0, 1);
                float3 newTangent, newBitangent;
                float3 wave1 = gerstner(_Wave1, v.vertex, newTangent, newBitangent);
                tangent += newTangent;
                bitangent += newBitangent;
                
                float3 wave2 = gerstner(_Wave2, v.vertex, newTangent, newBitangent);
                tangent += newTangent;
                bitangent += newBitangent;

                float3 wave3 = gerstner(_Wave3, v.vertex, newTangent, newBitangent);
                tangent += newTangent;
                bitangent += newBitangent;

                o.normal = normalize(cross(normalize(bitangent), normalize(tangent)));
                o.normal = UnityObjectToWorldNormal(o.normal);


                float3 wavesum = wave1;// + wave2 + wave3;

                v.vertex.xz += wavesum.xz;
                v.vertex.y = wavesum.y;

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                

                o.pos = UnityObjectToClipPos(v.vertex);
                //o.vertex.y = 0.5 * sin(_Time.r * 32 - v.vertex.z * 4);
                //o.vertex.x += cos(_Time.r * 16 + v.vertex.x);
                o.uv = TRANSFORM_TEX(v.uv, _FoamTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.screenPosition = ComputeScreenPos(o.pos);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                //TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 blur3x3(float blurDistance, fixed2 uv){
                fixed2 xOffset = fixed2(_GrabTexture_TexelSize.x * blurDistance, 0.0f);
                fixed2 yOffset = fixed2(0.0f, _GrabTexture_TexelSize.y * blurDistance);
                //fixed2 uvOffset = _GrabTexture_TexelSize.xy * blurDistance;
                float4 colorSum = 0.0f;
                
                
                for(int x = -2; x <= 2; x++){
                    for(int y = -2; y <= 2; y++){
                        fixed2 newUV = xOffset * x + yOffset * y + uv;
                        colorSum += tex2D(_GrabTexture, newUV);
                        //return colorSum;
                    }
                }
                return colorSum / 25;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 distortionCol = tex2D(_DistortionTex, i.uv + float2(0, _Time.r * 4)); 
                fixed2 uvDistortion = (distortionCol.xy - 0.5) * 2 * 0.02;

                fixed3 halfDir = normalize(normalize(i.viewDir) + _WorldSpaceLightPos0.xyz);

                fixed highlight = pow(saturate(dot(halfDir, normalize(i.normal))), 128);
                highlight = smoothstep(0.89, 0.991, highlight) * 2;


                fixed fresnel = saturate(dot(normalize(i.normal), normalize(i.viewDir)));
                fresnel = 1 - fresnel;
                fresnel = pow(fresnel, 4) * 0.2;
                //return float4(i.normal, 1.0f);

                //fixed atten = LIGHT_ATTENUATION(i);
                
                //return lighting;
                

                fixed2 uvOffset = i.uv + fixed2(0, _Time.x);
                fixed4 noiseTex = tex2D(_FoamTex, uvOffset);
                float4 depthTexEncoded = tex2D(_CameraDepthTexture, i.screenPosition.xy / i.screenPosition.w);//tex2D(_CameraDepthNormalTexture, i.screenPosition.xy / i.screenPosition.w);

                //float3 normal;
                //float depth;
                //DecodeDepthNormal(depthTexEncoded, depth, normal);
                float depth = depthTexEncoded.r;

                float linearDepth = LinearEyeDepth(depth);
                //w of the vertex is the depth it seems.
                float surfaceDepth = i.screenPosition.w;
                float depthDifference = linearDepth - i.screenPosition.w;
                fixed blurAmount = 1 - 1 / max(depthDifference, 0.01);
                /*
                
                blurAmount = saturate(blurAmount);
                blurAmount = blurAmount * blurAmount;
                //return blurAmount;

                //return tex2D(_GrabTexture, i.screenPosition.xy / i.screenPosition.w + uvDistortion);
                fixed4 screenCol = blur3x3(blurAmount * 12 * _BlurAmount, i.screenPosition.xy / i.screenPosition.w + uvDistortion);//
                */
                fixed4 screenCol = tex2D(_GrabTexture, i.screenPosition.xy / i.screenPosition.w + uvDistortion);

                //return screenCol;

                float cutoff = _NoiseCutoff * (depthDifference);
                float foam = noiseTex.r < cutoff ? 0 : 1;

                //Naive approach:
                //Take the difference between the depth & the water surface.
                //Sample using world UV.
                float3 causticWorldUV = i.viewDir / i.screenPosition.w * linearDepth - _WorldSpaceCameraPos;
                fixed4 caustic = tex2D(_CausticTex, causticWorldUV.xz * _CausticTiling + uvDistortion * 2) * saturate(depthDifference / _CausticBaseDepth); 
                caustic = pow(caustic, _CausticPower);
                caustic = lerp(0, caustic, 1 - blurAmount);
                

                float4 finalColor = lerp(_ShallowColor, _DeepColor, _WaterTransparency - saturate(depthDifference / _MaxWaterDepth));
                finalColor = lerp(finalColor * (1+caustic * 0.1), screenCol * (1+caustic*2), 1-saturate(depthDifference / _MaxWaterDepth) * _WaterTransparency);
                finalColor += finalColor * foam * 0.5;
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                
                return finalColor + highlight + fresnel;//saturate(depthDifference / 10);//finalColor;
            }
            ENDCG
        }
    }
}
