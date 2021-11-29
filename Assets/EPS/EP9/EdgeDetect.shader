Shader "Hidden/EdgeDetect"
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

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[9] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half2 uv = v.uv;
                half2 vertical = half2(0, 1) * _MainTex_TexelSize.xy;
                half2 horizontal = half2(1, 0) * _MainTex_TexelSize.xy;
                o.uv[0] = uv - horizontal - vertical;
                o.uv[1] = uv - vertical;
                o.uv[2] = uv + horizontal - vertical;
                o.uv[3] = uv - horizontal;
                o.uv[4] = uv;
                o.uv[5] = uv + horizontal;
                o.uv[6] = uv - horizontal + vertical;
                o.uv[7] = uv + vertical;
                o.uv[8] = uv + horizontal + vertical;

                return o;
            }



            fixed luminance(fixed4 color){
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i){
                const half Gx[9] = {
                    -1, -2, -1,
                     0,  0,  0,
                     1,  2,  1
                };
                const half Gy[9] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };

                //run the kernel...
                half texColor;
                half edgeX = 0;
                half edgeY = 0;

                for(int it = 0; it < 9; it++){
                    texColor = luminance(tex2D(_MainTex, i.uv[it]));
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }

                return 1 - abs(edgeX) - abs(edgeY);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half edge = Sobel(i);
                //fixed4 col = tex2D(_MainTex, i.uv[4]);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return float4(edge.rrr, 1);
            }
            ENDCG
        }
    }
}
