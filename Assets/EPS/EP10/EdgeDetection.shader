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


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float2 horizontalDir = float2(_MainTex_TexelSize.x, 0);
                float2 verticalDir = float2(0, _MainTex_TexelSize.y);
                
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

                half2 sampleNormal = center.xy;
                float sampleDepth = DecodeFloatRG(center.zw);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 sample0 = tex2D(_CameraDepthNormalsTexture, i.uv[0]);
                half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
                half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
                half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);


                fixed4 col = tex2D(_MainTex, i.uv[4]);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
