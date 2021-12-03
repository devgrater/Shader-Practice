Shader "Hidden/FogOverlay"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 interpolatedRay : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            float4x4 _FrustumCornersRay;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                int index = 0;
                if(o.uv.x < 0.5f){
                    if(o.uv.y < 0.5f){
                        //bottom left
                        index = 0;
                    }
                    else{
                        //top left
                        index = 3;
                    }
                }
                else{
                    if(o.uv.y < 0.5f){
                        //bottom right
                        index = 1;
                    }
                    else{
                        //top right
                        index = 2;
                    }
                }
                #if UNITY_UV_STARTS_AT_TOP
                    if(_MainTex_TexelSize.y < 0){
                        index = 3 - index;
                    }
                #endif

                o.interpolatedRay = _FrustumCornersRay[index];

                float tlarea = o.uv.x * o.uv.y;
                float brarea = (1 - o.uv.x) * (1 - o.uv.y);

                float sum_area = tlarea + brarea;
                tlarea = tlarea / sum_area;
                brarea = brarea / sum_area;

                //o.interpolatedRay = tlarea * _FrustumCornersRay[3] + brarea * _FrustumCornersRay[1];


                //interpolate...

                return o;
            }



            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                fixed depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float3 worldPos = _WorldSpaceCameraPos + depth * i.interpolatedRay.xyz;
                return float4(worldPos.xyz, 1);
            }
            ENDCG
        }
    }
}

