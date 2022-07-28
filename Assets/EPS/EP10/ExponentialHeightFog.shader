Shader "Hidden/ExponentialHeightFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogNoise ("FogNoise", 2D) = "white" {}
        _Control ("Control", Vector) = (0.003, 0.1, 0.0, 0.0)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                half3 viewVector : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _FogNoise;
            float4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            float4x4 _FrustumCornersRay;

            //fog related
            float _FogStart;
            float _FogEnd;
            fixed4 _FogColor;
            half _FogDensity;
            float4 _Control;

        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));

                //o.interpolatedRay = tlarea * _FrustumCornersRay[3] + brarea * _FrustumCornersRay[1];


                //interpolate...

                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                fixed depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float3 worldPos = _WorldSpaceCameraPos + depth * i.viewVector;

                //return depth / 1000000;
                //using the y coordinates..
                //return float4(frac(worldPos / 1000), 1.0f);
                float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
                fogDensity = saturate(fogDensity * _FogDensity);
                

                fixed rdir = normalize(i.viewVector).y;



                //fishy!
                //float fogAmountVertical = exp(-worldPos.y * _Control.g);
                //fogAmountVertical = saturate(fogAmountVertical);
                //integral over y:

                float higherY = max(worldPos.y, _WorldSpaceCameraPos.y);
                float lowerY = min(worldPos.y, _WorldSpaceCameraPos.y);

                //return densityPlayer;

                //densityWorld *= exp(-depth * 0.001);

                float highDensityPos = exp(-higherY * _Control.g);
                //return highDensityPos;
                float lowDensityPos = exp(-lowerY * _Control.g);
                //return lowDensityPos;


                //return saturate(deltaDensity);
                float xDirDiff = exp(-depth * _Control.r);

                //integrate the fog.... over the height difference.
                //approximation: 
                float heightIntegral = saturate((highDensityPos + lowDensityPos) * 0.5f);
                //return heightIntegral;//exp((-worldPos.y - _WorldSpaceCameraPos.y) * _Control.g);
                xDirDiff = exp(-depth * heightIntegral * _Control.r);
                
                
                //inscatter:
                float sunAmount = pow(saturate(dot(normalize(depth * i.viewVector.xyz), normalize(_WorldSpaceLightPos0.xyz))), 4 );
         
                float dirExponentialHeightLineIntegral = max(length(depth * i.viewVector.xyz) - 1.0, 0.0f);
                float DirectionalInscatteringFogFactor = saturate(exp2(-dirExponentialHeightLineIntegral)); 
                sunAmount *= (1 - DirectionalInscatteringFogFactor);
                //atmospheric scattering:

                fixed4 fogColor = _FogColor;
                fogColor.rgb = lerp(_FogColor.rgb, fixed3(1.0, 1.0, 1.0), sunAmount);
                col.rgb = lerp(fogColor, col.rgb, saturate(xDirDiff));

                //col.rgb = lerp(col.rgb, _FogColor.rgb, exp(-depth * _Control.g));
                //col.rgb = fog(_WorldSpaceCameraPos, i.viewVector, _FogColor.rgb, exp(-depth) * _Control.g);
                return col;
            }
            ENDCG
        }
    }
}

