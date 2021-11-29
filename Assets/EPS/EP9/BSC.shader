Shader "Hidden/BSC"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness ("Brightness", Float) = 1
        _Saturation ("Saturation", Float) = 1
        _Contrast ("Contrast", Float) = 1
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

            float _Brightness;
            float _Saturation;
            float _Contrast;

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

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 finalColor = col;
                col.rgb *= _Brightness;
                fixed luminance = 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b;
                fixed4 luminanceColor = fixed4(luminance, luminance, luminance, 1);
                finalColor = lerp(luminance, finalColor, _Saturation);
                // just invert the colors
                fixed4 avgColor = fixed4(0.5, 0.5, 0.5, 1.0);
                avgColor = lerp(avgColor, finalColor, _Contrast);
                avgColor.a = col.a;
                return avgColor;
            }
            ENDCG
        }
    }
}
