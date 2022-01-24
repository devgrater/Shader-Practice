Shader "Hidden/PostProcessing/PostProcessVC"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE



        ENDCG

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
            sampler2D _CameraDepthTexture;
            float3 _MaxBounds;
            float3 _MinBounds;
            float4x4 _ViewProjInv;

            float4 reconstruct_worldpos(float2 uv){
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float4 H = float4(uv * 2.0f - 1.0f, depth, 1.0f);
                float4 D = mul(_ViewProjInv, H);
                return D / D.w;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                return reconstruct_worldpos(i.uv);
                fixed4 col = tex2D(_MainTex, i.uv);

                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
