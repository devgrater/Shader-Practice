Shader "Unlit/ScreenSpaceReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StepSize ("StepSize", Float) = 1.0
        _BlueNoise ("Blue Noise", 2D) = "black" {}
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent+1"
        }
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
                float3 viewSpacePos : TEXCOORD4; 
                float4 screenPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _GrabTexture;
            sampler2D _CameraDepthTexture;
            sampler2D _BlueNoise;
            float _StepSize;
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
                o.viewSpacePos = UnityObjectToViewPos(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //can probably trace everything in ndc space.,

                //do it in the view space? //nah no need
                float2 uv = i.screenPos.xy / i.screenPos.w;
                float blueNoiseValue = tex2D(_BlueNoise, uv * 3.0f);
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.worldNormal);

                float3 reflectedVector = normalize(reflect(-viewDir, normal));
                reflectedVector = normalize(mul(UNITY_MATRIX_V, float4(reflectedVector, 0.0f)).xyz);

                float3 viewStart = i.viewSpacePos + reflectedVector * blueNoiseValue; //if you are already beyond, we don't even need to check. (TODO)
                float startDepth = -viewStart.z;
                //return float4(viewStart, 0.0f);
                //then, we march along this....
                for(int i = 0; i < 32; i++){
                    viewStart += reflectedVector * _StepSize;
                    //and then...
                    float4 clipPosHead = mul(UNITY_MATRIX_P, float4(viewStart, 1.0f));
                    float2 screenUV = clipPosHead.xy / clipPosHead.w;
                    screenUV = (screenUV + 1.0) * 0.5f;
                    //return float4(screenUV, 0.0f , 1.0f);

                    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                    if(-viewStart.z >= depth && startDepth < depth){
                        //return the uv, maybe?
                        return tex2D(_GrabTexture, screenUV);
                        //return float4(screenUV, 0.0f, 1.0f);
                    }
                }
                return 0.0f;

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
