Shader "Unlit/WaterSurface"
{
    Properties
    {
        _FoamTex ("Noise", 2D) = "black" {}
        _DistortionTex ("Distortion Texture", 2D) = "gray" {}
        _NoiseCutoff ("Noise Cutoff", Float) = 0.5
        _ShallowColor ("Shallow Color", Color) = (1.0,1.0,1.0,1.0)
        _DeepColor ("Deep Color", Color) = (1.0,1.0,1.0,1.0)
        _MaxWaterDepth ("Max Water Depth", Float) = 1.0
        _Wave1 ("Wave 1 (Angle, Wavelength, Steepness, Speed)", Vector) = (1,1,0,0)
        _Wave2 ("Wave 2 (Angle, Wavelength, Steepness, Speed)", Vector) = (1,1,0,0)
        _Wave3 ("Wave 3 (Angle, Wavelength, Steepness, Speed)", Vector) = (1,1,0,0)
        _WaterTransparency ("Water Transparency", Range(0.0, 1.0)) = 0.2

        _CausticTex ("Caustic Texture", 2D) = "black" {}
        _CausticTiling ("Caustic Tiling", Float) = 3.0
        _CausticPower ("Caustic Power", Float) = 10.0
        _CausticBaseDepth ("Caustic Base Depth", Float) = 10.0
        [HDR]_CausticBlendColor ("Caustic Blend Color", Color) = (1.0, 1.0, 1.0, 1.0)

        _OffsetBase ("OffsetBase", Float) = 0.0
        //_OffsetCeil ("OffsetCeil", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+1" }
        //AlphaToMask On
        //Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On
        Cull Off
        
        LOD 100

        GrabPass{

        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
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
            float4 _CausticBlendColor;
            float _OffsetBase;


            float3 gerstner(float4 data, float4 vertex){
                //r channel: angle (convert to vector)
                //g channel: wavelength
                //b channel: steepness
                //a channel: speed

                //r channel:
                float2 d = normalize(float2(sin(data.r), cos(data.r)));
                float k = UNITY_PI / data.g;
                float f = k * (dot(d, vertex.xz) - data.a * _Time.y);
                float a = data.b / k;

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

                float3 wave1 = gerstner(_Wave1, v.vertex);
                float3 wave2 = gerstner(_Wave2, v.vertex);
                float3 wave3 = gerstner(_Wave3, v.vertex);
                float3 wavesum = wave1 + wave2 + wave3;

                v.vertex.xz += wavesum.xz;
                v.vertex.y = wavesum.y;
                
                

                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.vertex.y = 0.5 * sin(_Time.r * 32 - v.vertex.z * 4);
                //o.vertex.x += cos(_Time.r * 16 + v.vertex.x);
                o.uv = TRANSFORM_TEX(v.uv, _FoamTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 blurNxN(int blurCount, float blurDistance, fixed2 uv){

            }


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 distortionCol = tex2D(_DistortionTex, i.uv + float2(0, _Time.r * 4)); 
                fixed2 uvDistortion = (distortionCol.xy - 0.5) * 2 * 0.02;
                fixed4 screenCol = tex2D(_GrabTexture, i.screenPosition.xy / i.screenPosition.w + uvDistortion);

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



                
                float cutoff = _NoiseCutoff * (depthDifference);
                float foam = noiseTex.r < cutoff ? 0 : 1;

                //Naive approach:
                //Take the difference between the depth & the water surface.
                //Sample using world UV.
                float3 causticWorldUV = i.viewDir / i.screenPosition.w * linearDepth - _WorldSpaceCameraPos;
                fixed4 caustic = tex2D(_CausticTex, causticWorldUV.xz * _CausticTiling + uvDistortion * 2) * saturate(depthDifference / _CausticBaseDepth); 
                caustic = pow(caustic, _CausticPower);
                

                float4 finalColor = lerp(_ShallowColor, _DeepColor, _WaterTransparency - saturate(depthDifference / _MaxWaterDepth));
                finalColor = lerp(finalColor * (1+caustic * 0.1), screenCol * (1+caustic*2), 1-saturate(depthDifference / _MaxWaterDepth) * _WaterTransparency) + float4(foam, foam, foam, 1.0);
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                
                return finalColor;//saturate(depthDifference / 10);//finalColor;
            }
            ENDCG
        }
    }
}
