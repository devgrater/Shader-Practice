Shader "Hidden/RampFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            sampler2D _CameraDepthTexture;
            sampler2D _GradientMap;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _NearbyTint;


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float depth = tex2D(_CameraDepthTexture, i.uv);
                float linearDepth = LinearEyeDepth(depth);
                fixed oneOverDepth = 1 / linearDepth;
                fixed depthAmount = 1 - oneOverDepth;
                depthAmount = pow(depthAmount, 12.0f);

                float brightness = dot(col, fixed3(0.299, 0.587, 0.114));
                //sample the gradient map:
                float4 rampColor = tex2D(_GradientMap, fixed2(depthAmount, 0.1));
                float4 nearColor = col * _NearbyTint;//lerp(col, brightness * _NearbyTint, rampColor.r);
                col = lerp(nearColor, rampColor, rampColor.a);
                float3 outColor = lerp(col, rampColor.rgb, rampColor.a);

                //lerp over the ramp
                return float4(outColor, 1.0f);
                return 1 / linearDepth;
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
