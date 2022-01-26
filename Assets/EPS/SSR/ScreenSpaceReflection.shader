Shader "Unlit/ScreenSpaceReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        GrabPass {}

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
                float3 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD1;
                float4 screenPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _GrabTexture;
            sampler2D _CameraDepthTexture;

            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //compute the view direction
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //can probably trace everything in ndc space.,
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.worldNormal);

                float3 reflectedVector = normalize(reflect(-viewDir, normal));
                //how to go to ndc space?
                float4 screenSpaceVector = mul(UNITY_MATRIX_VP, reflectedVector);


                /*
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.worldNormal);
                //reflect the view direction
                float3 reflectedVector = normalize(reflect(-viewDir, normal));
                float4 startReflectionPos = i.vertex; //look!
                

                //need to find a way to convert the coordinates to screen space.
                float4 screenSpaceVector = mul(UNITY_MATRIX_VP, reflectedVector);
                return tex2D(_GrabTexture, screenSpaceVector.xy);
                return float4(screenSpaceVector.xy / screenSpaceVector.w, 0.0f, 1.0f);*/
            }
            ENDCG
        }
    }
}
