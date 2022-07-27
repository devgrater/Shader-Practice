Shader "Hidden/BlitHeightMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TargetTex ("Texture", 2D) = "black" {}
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
            sampler2D _TargetTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_TargetTex, i.uv);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                col.g = 0.0f;
                col.ba = 1.0f;
                return col;
            }
            ENDCG
        }
    }
}
