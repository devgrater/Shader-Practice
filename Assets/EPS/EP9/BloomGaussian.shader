Shader "Hidden/BloomGaussian"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
        _Threshold ("Threshold", Float) = 1.0
        _BloomOnly ("Bloom Texture", 2D) = "black" {}
        _BloomIntensity ("Bloom Intensity", Float) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        CGINCLUDE
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _BloomOnly;
            float _BlurSize;
            float _Threshold;
            float _BloomIntensity;

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

            
            fixed luminance(fixed4 color){
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            fixed4 falloff_luminance(fixed4 color){
                const fixed3 falloff = fixed3(1.2125, 1.7154, 1.0721);
                color.rgb *= falloff;
                color.rgb = normalize(color.rgb);
                return color;
            }

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

        Pass
        {
            NAME "BLOOM_EXTRACT"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment bloomFrag
            struct v_to_f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v_to_f vert (appdata v)
            {
                v_to_f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            fixed4 bloomFrag (v_to_f i) : SV_Target
            {
                
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed luma = saturate(luminance(col) - _Threshold);
                col = falloff_luminance(col); //clamp it to 01 range
                //more red... and green.
                //make it more obvious...
                return saturate(col * luma);
            }
            ENDCG
        }

        Pass
        {
            NAME "BLOOM_COMPOSITE"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment bloomFrag


            struct v_to_f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v_to_f vert (appdata v)
            {
                v_to_f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 bloomFrag (v_to_f i) : SV_Target
            {
                
                fixed4 col = tex2D(_MainTex, i.uv);// + tex2D(_BloomOnly, i.uv);
                //col.rgb -= _Threshold;
                fixed luma = saturate(luminance(col) - _Threshold); //the closer to 1, the whiter...
                col = lerp(col, float4(1, 1, 1, 1), luma);
                col += tex2D(_BloomOnly, i.uv) * _BloomIntensity;
                return col;//saturate(col);
            }
            ENDCG
        }
    }
}
