Shader "Hidden/Gaussian"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        CGINCLUDE
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _BlurSize;

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

            v2f vertBlurVertical (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half2 horiz = half2(0, 1) * _MainTex_TexelSize.y * _BlurSize;
                half2 horiz_double = horiz * 2;
                o.uv[0] = v.uv;
                o.uv[1] = v.uv + horiz;
                o.uv[2] = v.uv - horiz;
                o.uv[3] = v.uv + horiz_double;
                o.uv[4] = v.uv - horiz_double;
                return o;
            }

            v2f vertBlurHorizontal (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half2 horiz = half2(1, 0) * _MainTex_TexelSize.y * _BlurSize;
                half2 horiz_double = horiz * 2;
                o.uv[0] = v.uv;
                o.uv[1] = v.uv + horiz;
                o.uv[2] = v.uv - horiz;
                o.uv[3] = v.uv + horiz_double;
                o.uv[4] = v.uv - horiz_double;
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                /*
                fixed4 col = tex2D(_MainTex, i.uv[4]);
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;*/
                float weight[3] = {0.4026, 0.2442, 0.0545};

                fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
                for(int it = 1; it < 3; it++){
                    sum += tex2D(_MainTex, i.uv[2 * it - 1]).rgb * weight[it];
                    sum += tex2D(_MainTex, i.uv[2 * it]).rgb * weight[it];
                    //sum += tex2D(_MainTex, i.uv[it]).rgb * weight[it];
                    //sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
                }

                return fixed4(sum, 1.0);
            }
        ENDCG

        Pass 
        {
            NAME "HORIZONTAL_GAUSSIAN"
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment frag
            ENDCG
        }

        Pass 
        {
            NAME "VERTICAL_GAUSSIAN"
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment frag
            ENDCG
        }
    }
}
