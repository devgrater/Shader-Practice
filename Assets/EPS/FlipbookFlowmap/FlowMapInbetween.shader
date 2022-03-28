Shader "Unlit/FlowmapInbetween"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UV1 ("Uv1", 2D) = "white" {}
        _UV2 ("UV2", 2D) = "white" {}
        _LerpAmount ("Lerp Amount", Range(0, 1)) = 0
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _UV1;
            sampler2D _UV2;
            fixed _LerpAmount;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //return float4(i.uv, 0, 1);
                //sample the two uvs
                fixed2 uv1 = tex2D(_UV1, i.uv);
                fixed2 uv2 = tex2D(_UV2, i.uv);

                fixed2 inbetweenUv = lerp(uv1, uv2, _LerpAmount);
                //return float4(inbetweenUv, 0, 1);
                //using the inbetwen, sample main tex:

                //and lerp between the two
                // sample the texture
                fixed4 col = tex2D(_MainTex, inbetweenUv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
