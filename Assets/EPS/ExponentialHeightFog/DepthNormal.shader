Shader "Hidden/MotionBlur"
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
            sampler2D _CameraDepthNormalsTexture;
            fixed _BlurAmount;


            half4 frag (v2f i) : SV_Target {
                float4 depthNormal = tex2D(_CameraDepthNormalsTexture, i.uv);
                float depthY = sqrt(1 - dot(depthNormal.xy, depthNormal.xy));
                //return tex2D(_CameraDepthNormalsTexture, i.uv);
                float depth;
                float3 normal;
                DecodeDepthNormal(depthNormal, depth, normal);
                depth = Linear01Depth(depth);
                return float4(normal * (depth * 30), 1.0);
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
