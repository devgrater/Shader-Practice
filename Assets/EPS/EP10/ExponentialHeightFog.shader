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
             float4 _MainTex_TexelSize;
             sampler2D _CameraDepthTexture;
             sampler2D _ColorRamp;
             float _TimeOfDay;

             //fog related
             fixed4 _FogColor;
             float4 _Control;
             fixed _Density;

             half3 _SunControl;
             half3 _MoonControl;
             fixed3 _SunDir;
             fixed3 _MoonDir;

             fixed4 _SunColor;
             fixed4 _MoonColor;
             sampler2D _FogRamp;

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
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                fixed depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                fixed depth01 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float3 worldPos = _WorldSpaceCameraPos + depth * i.viewVector;

                //return 
                fixed rdir = normalize(i.viewVector).y;
                


                //fishy!
                //float fogAmountVertical = exp(-worldPos.y * _Control.g);
                //fogAmountVertical = saturate(fogAmountVertical);
                //integral over y:

                float higherY = max(worldPos.y, _WorldSpaceCameraPos.y);
                float lowerY = min(worldPos.y, _WorldSpaceCameraPos.y);

                //return densityPlayer;

                //densityWorld *= exp(-depth * 0.001);

                float startDensityPos = -exp2(-(_WorldSpaceCameraPos.y - _Control.b) * _Control.g * _Density) / (_Control.g * _Density * i.viewVector.y);
                float endDensityPos = -exp2(-(_WorldSpaceCameraPos.y - _Control.b + depth * i.viewVector.y) * _Control.g * _Density) / (_Control.g * _Density * i.viewVector.y);

                float highDensityPos = exp((_WorldSpaceCameraPos.y + _Control.b) * _Control.g);
                float lowDensityPos = exp((-lowerY + _Control.b) * _Control.g);

                float integral = endDensityPos - startDensityPos;


                //return integral;

                //return -integral;

                //integrate the fog.... over the height difference.
                //* depth / depth's y
                //approximation: 
                float heightIntegral = integral;//saturate((highDensityPos + lowDensityPos) * 0.5f);
                //return heightIntegral;//exp((-worldPos.y - _WorldSpaceCameraPos.y) * _Control.g);
                float xDirDiff = exp2((-depth + _Control.a) * heightIntegral * _Density * _Control.r);
                
                
                //inscatter: sun
                
                
                float sunAmount = pow(saturate(dot(normalize(depth * i.viewVector.xyz), normalize(_WorldSpaceLightPos0.xyz))), 12);
         
                float dirExponentialHeightLineIntegral = max(length((depth + _Control.a) * i.viewVector.xyz) - 1.0, 0.0f);
                float DirectionalInscatteringFogFactor = saturate(exp2(-dirExponentialHeightLineIntegral)); 
                sunAmount *= (1 - DirectionalInscatteringFogFactor);

                //inscatter: atmospheric
                //scattering from both the sun, and from the environment:
                //get view dir:
                fixed4 skyCol = tex2D(
                    _ColorRamp, fixed2(1 - (rdir + 1.0f) * 0.5f, _TimeOfDay)
                );

                fixed4 fogCol = tex2D(_FogRamp, fixed2(saturate(xDirDiff), 0.0f));

                //return skyCol;

                fixed4 fogColor = skyCol;
                fogColor.rgb = lerp(fogCol, fogCol + _LightColor0.xyz * (1 - saturate(xDirDiff)), sunAmount);
                //skyCol += sunAmount;
                col.rgb = lerp(fogColor, col.rgb, saturate(xDirDiff));

                return col;
            }
            ENDCG
        }
    }
}

