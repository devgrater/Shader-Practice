Shader "Unlit/SH9Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _SH9Vals[9];

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 outColor = float4(0,0,0,1);
                float x = i.worldNormal.x;
                float y = i.worldNormal.y;
                float z = i.worldNormal.z;
                float zSqr = z * z;
                float xSqr = x * x;
                float ySqr = y * y;
                
                outColor.rgb += 0.28209479f * _SH9Vals[0].rgb; //yup, because the first basis is constant.
                outColor.rgb += 0.48860251f * y * _SH9Vals[1].rgb; //r is constant (1)
                outColor.rgb += 0.48860251f * z * _SH9Vals[2].rgb;
                outColor.rgb += 0.48860251f * x * _SH9Vals[3].rgb;
                outColor.rgb += 2.18509686f * 0.5f * x * y * _SH9Vals[4].rgb;
                outColor.rgb += 2.18509686f * 0.5f * y * z * _SH9Vals[5].rgb;
                outColor.rgb += 1.26156626f * 0.25f * (3 * zSqr) * _SH9Vals[6].rgb;
                outColor.rgb += 2.18509686f * 0.5f * z * x * _SH9Vals[7].rgb;
                outColor.rgb += 2.18509686f * 0.25f * (xSqr - ySqr) * _SH9Vals[8].rgb;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                /*#   ifdef UNITY_COLORSPACE_GAMMA
                        outColor.rgb = LinearToGammaSpace(outColor.rgb);
                #   endif*/
                return outColor;
            }
            ENDCG
        }
    }
}
