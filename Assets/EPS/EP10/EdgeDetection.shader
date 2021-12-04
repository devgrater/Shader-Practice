Shader "Hidden/EdgeDetection"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[5] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _CameraDepthNormalsTexture;
            float4 _Sensitivity;
            float _SampleDistance;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float2 horizontalDir = float2(_MainTex_TexelSize.x, 0) * _SampleDistance;
                float2 verticalDir = float2(0, _MainTex_TexelSize.y) * _SampleDistance;
                
                o.uv[1] = v.uv + horizontalDir + verticalDir;;
                o.uv[2] = v.uv - horizontalDir - verticalDir;
                o.uv[3] = v.uv - horizontalDir + verticalDir;
                o.uv[4] = v.uv + horizontalDir - verticalDir;
                o.uv[0] = v.uv;
                
                return o;
            }

            
            fixed isSameEdge(half4 center, half4 sample){
                half2 centerNormal = center.xy;
                float centerDepth = DecodeFloatRG(center.zw);

                half2 sampleNormal = sample.xy;
                float sampleDepth = DecodeFloatRG(sample.zw);

                half2 normalDiff = abs(centerNormal - sampleNormal) * _Sensitivity.x;
                int isSameNormal = (normalDiff.x + normalDiff.y) < 0.1;
                float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
                int isSameDepth = diffDepth < 0.1 * centerDepth;
                return isSameNormal * isSameDepth ? 1.0 : 0.0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
                half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
                half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
                half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);

                half edge = 1.0;
                edge *= isSameEdge(sample1, sample2);
                edge *= isSameEdge(sample3, sample4);
                fixed4 col = tex2D(_MainTex, i.uv[0]);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return float4(isSameEdge(sample1, sample2).rrr, 1);
            }
            ENDCG
        }
    }
}
