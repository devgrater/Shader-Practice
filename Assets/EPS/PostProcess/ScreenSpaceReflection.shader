Shader "Unlit/ScreenSpaceReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StepSize ("StepSize", Float) = 1.0
        _BlueNoise ("Blue Noise", 2D) = "black" {}
        _BlueNoiseIntensity ("Blue Noise Intensity", Range(0, 5)) = 1.0
        _EdgeFade ("Edge Fade", Range(0, 1)) = 0.1
        _ReflectionOffset ("Reflection Offset", Float) = 0.0
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
            float4 _MainTex_ST;
            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize;
            sampler2D _CameraDepthTexture;
            sampler2D _BlueNoise;
            float _StepSize;
            float _ReflectionOffset;
            float _EdgeFade;
            float _BlueNoiseIntensity;
            

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

            float fresnel(fixed cosTheta){
                return pow(saturate(1.0 - cosTheta), 5.0);
            }

            float4 sample_reflection_color(float2 uv){
                //offset the uv to blur it a bit?
                return tex2D(_GrabTexture, uv);
                float4 averageColor = 0.0f;
                fixed2 uvNudge = _GrabTexture_TexelSize.xy;
                //blur out the result:
                for(int i = -1; i <= 1; i++){
                    for(int j = -1; j <= 1; j++){
                        //do something!
                        averageColor += tex2D(_GrabTexture, uv + uvNudge * fixed2(i, j));
                    }
                }
                return averageColor / 9.0f;//tex2D(_GrabTexture, uv);
            }

            float4 trace_reflection(float4 baseColor, float3 viewStart, float3 reflectedVector){
                float startDepth = -viewStart.z;
                
                for(uint i = 0; i < 16; i++){
                    //step exponentially if you need...
                    viewStart += reflectedVector * exp(i / 16) * _StepSize;
                    //and then...
                    float4 clipPosHead = mul(UNITY_MATRIX_P, float4(viewStart, 1.0f));
                    //normalize the coordinates
                    float2 screenUV = clipPosHead.xy / clipPosHead.w;
                    screenUV = (screenUV + 1.0) * 0.5f;
                    screenUV.y = 1 - screenUV.y;
                    
                    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                    if(-viewStart.z >= depth && startDepth + _ReflectionOffset < depth){
                        //calculate out uv fade:

                        float depthDiff = depth - startDepth + _ReflectionOffset;
                        float depthFade = saturate(depthDiff / 4);


                        float dstFromEdgeX = min(_EdgeFade, min(screenUV.x, 1 - screenUV.x));
                        float dstFromEdgeY = min(_EdgeFade, min(screenUV.y, 1 - screenUV.y));
                        float edgeWeight = max(dstFromEdgeY, dstFromEdgeX) / _EdgeFade;
                        return lerp(baseColor, sample_reflection_color(screenUV), edgeWeight * depthFade);
                    }
                }
                //no hit
                return float4(baseColor.xyz, 0.0f);
            }


            fixed4 frag (v2f i) : SV_Target
            {
                //can probably trace everything in ndc space.,

                //do it in the view space? //nah no need
                float2 uv = i.screenPos.xy / i.screenPos.w;
                float blueNoiseValue = tex2D(_BlueNoise, (uv) * 3.0f);
                float3 viewDir = normalize(i.viewDir);
                float3 normal = normalize(i.worldNormal);

                float cosTheta = dot(viewDir, normal);
                float fresnelValue = fresnel(cosTheta);

                float4 baseColor = tex2D(_MainTex, i.uv);



                float3 reflectedVector = normalize(reflect(-viewDir, normal));
                reflectedVector = normalize(mul(UNITY_MATRIX_V, float4(reflectedVector, 0.0f)).xyz);

                float3 viewStart = i.viewSpacePos + reflectedVector * blueNoiseValue * _BlueNoiseIntensity; //if you are already beyond, we don't even need to check. (TODO)
                float4 outColor = trace_reflection(baseColor, viewStart, reflectedVector);
                return lerp(baseColor, outColor, fresnelValue);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
