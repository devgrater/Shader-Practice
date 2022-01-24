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
                float3 viewVector : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float3 _VBoxMin;
            float3 _VBoxMax;
            float4x4 _ViewProjInv;

            float4 reconstruct_worldpos(float2 uv){
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float4 H = float4(uv * 2.0f - 1.0f, depth, 1.0f);
                float4 D = mul(_ViewProjInv, H);
                return D / D.w;
            }

            float2 trace_vbox_planes(float3 cameraPos, float3 cameraVector){
                float3 hitT0 = (_VBoxMin - cameraPos) / cameraVector;
                float3 hitT1 = (_VBoxMax - cameraPos) / cameraVector;

                float3 minT = min(hitT0, hitT1);
                float3 maxT = max(hitT0, hitT1);

                float dstA = max(max(minT.x, minT.y), minT.z);
                float dstB = min(min(maxT.x, maxT.y), maxT.z);

                float dstToBox = max(0, dstA);
                float dstInBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInBox);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewVector = i.viewVector;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = LinearEyeDepth(depth);
                /*
                float3 worldPos = reconstruct_worldpos(i.uv).xyz;
                float3 cameraVector = normalize(worldPos - _WorldSpaceCameraPos);*/
                float3 worldPos = _WorldSpaceCameraPos + i.viewVector * linearDepth;


                return float4(worldPos, 1.0f);//reconstruct_worldpos(i.uv);

                
                fixed4 col = tex2D(_MainTex, i.uv);

                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
