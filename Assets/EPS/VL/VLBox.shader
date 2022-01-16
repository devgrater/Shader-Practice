Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Depth ("Depth", Float) = 0.5
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 0.1)) = 0.1
    }

    

    SubShader
    {
        Tags {
             "RenderType"="Opaque" 
             "Queue"="Transparent+1"
        }
        LOD 100
        GrabPass{

        }

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
                
                float4 screenPos : TEXCOORD2;
                float3 normal : NORMAL;
                float3 osViewDir : TEXCOORD1;
                //float3 osVertex : TEXCOORD3;
                float3 camDir : TEXCOORD3;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;
            float _Depth;
            float4 _FogColor;
            fixed _FogDensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.screenPos = ComputeScreenPos(o.vertex);
                //o.osNormal = v.normal; //prob dont need this
                //o.osVertex = v.vertex;
                
                o.osViewDir = ObjSpaceViewDir(v.vertex);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float trace_one_plane(fixed3 normal, fixed3 viewDir, float3 origin, float c){
                return (c - dot(normal, origin)) / dot(normal, viewDir);
            }

            void trace_dual_plane(fixed3 normal, fixed3 viewDir, float3 origin, float c, out float minPlane, out float maxPlane){
                float nDotO = dot(normal, origin);
                float nDotV = dot(normal, viewDir);
                //because this is in object space, we can cheat our way thru
                float plane1 = (c - nDotO) / nDotV;
                float plane2 = (-c - nDotO) / nDotV;
                fixed plane1Closer = (plane1 < plane2);
                
                //if true, plane1Closer evaluates to 1
                //otherwise evalueates to 0 and plane2 gets pulled out.
                //linearly combine them, and you get which plane is closer than the other.
                
                minPlane = plane1Closer * plane1 + (1 - plane1Closer) * plane2;
                maxPlane = (1 - plane1Closer) * plane1 + plane1Closer * plane2;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //in object space, lets say, ideally,
                //that the front plane happens to be 0.5 units away from teh origin.
                //same goes for every other plane.
                fixed3 camPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                //first lets trace the front and back plane.
                fixed3 viewDir = normalize(i.osViewDir);

                fixed3 zPlaneNormal = sign(viewDir.z) * fixed3(0, 0, 1); //doesn't matter that much (we only care the first hit time and the last hit time.)
                float maxZPlane = trace_one_plane(zPlaneNormal, viewDir, camPos, _Depth);

                fixed3 yPlaneNormal = sign(viewDir.y) * fixed3(0, 1, 0);
                float maxYPlane = trace_one_plane(yPlaneNormal, viewDir, camPos, _Depth);

                fixed3 xPlaneNormal = sign(viewDir.x) * fixed3(1, 0, 0);
                float maxXPlane = trace_one_plane(xPlaneNormal, viewDir, camPos, _Depth);


                float maxDepth = max(max(maxZPlane, maxYPlane), maxXPlane);

                fixed2 screenUV = i.screenPos.xy / i.screenPos.w;
                float depthBehind = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUV).r);
                //perspective correct
                
                //convert object space to world space,
                //and take the union with the existing depth map.
                float3 objectSpacePos = (maxDepth * viewDir);
                float3 worldSpaceDepthDiff = mul(unity_ObjectToWorld, float4(objectSpacePos, 0.0));
                //using this....
                float3 worldSpaceVector = worldSpaceDepthDiff;

                float3 viewForward = unity_CameraToWorld._m02_m12_m22;
                float perspectiveCorrectDepth = dot(worldSpaceVector, normalize(viewForward));
                float minDepth = min(depthBehind, perspectiveCorrectDepth);

                float perspectiveCorrection = dot(normalize(worldSpaceVector), normalize(viewForward));

                float4 screenColor = tex2D(_GrabTexture, screenUV);

                //now we can ask the basic question.
                float depthDifference = abs(i.screenPos.w - minDepth) * perspectiveCorrection;
                fixed fogAmount = 1 / exp(depthDifference * _FogDensity);
                return lerp(_FogColor, screenColor, saturate(fogAmount));

                return 10 / i.screenPos.w;
                return 10 / (i.screenPos.z / perspectiveCorrection);
                return 10 / minDepth;


            }
            ENDCG
        }
    }
}
