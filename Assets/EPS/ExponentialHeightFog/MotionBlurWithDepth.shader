Shader "Hidden/MotionBlurWithDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Float) = 0.5
    }



    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                half2 uv_depth : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            float4x4 _PreviousProjection;
            float4x4 _CurrentProjectionInverse;
            fixed _BlurAmount;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv_depth = v.uv;
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0){
                    o.uv_depth.y = 1 - o.uv_depth.y;
                }
                #endif
                return o;
            }


            half4 frag (v2f i) : SV_Target {
                //1. sample depth texture and recreate camera space coordinate?
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
                //map everything to -1, 1 space
                float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
                //inverse transform to world space...
                float4 D = mul(_CurrentProjectionInverse, H);
                float4 worldPos = D / D.w; 

                float4 currentPos = H;
                //reconstruct screen position previous frame:
                float4 previousPos = mul(_PreviousProjection, worldPos);
                previousPos /= previousPos.w;
                float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;
                //sample based on the distance....
                float2 uv = i.uv;
                float4 c = tex2D(_MainTex, uv);
                for(int iter = 1; iter < 8; iter++, uv += velocity * _BlurAmount / 8.0){
                    //sample at the uv...
                    c += tex2D(_MainTex, uv);
                }
                c /= 8;

                return float4(c.rgb, 1.0);
            }
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            

            ENDCG
        }
    }
}
