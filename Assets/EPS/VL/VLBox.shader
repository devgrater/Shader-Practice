Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Depth ("Depth", Float) = 0.5
    }
    SubShader
    {
        Cull Off
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
            float _Depth;

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
                
                /*
                if(plane1 < plane2){
                    minPlane = plane1;
                    maxPlane = plane2;
                }
                else{
                    minPlane = plane2;
                    maxPlane = plane1;
                }*/
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //in object space, lets say, ideally,
                //that the front plane happens to be 0.5 units away from teh origin.
                //same goes for every other plane.
                fixed3 camPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                //first lets trace the front and back plane.
                fixed3 viewDir = normalize(i.osViewDir);
                fixed3 zPlaneNormal = fixed3(0, 0, 1); //doesn't matter that much (we only care the first hit time and the last hit time.)
                float minZPlane, maxZPlane;
                //trace_dual_plane(zPlaneNormal, viewDir, , _Depth, minZPlane, maxZPlane);
                maxZPlane = trace_one_plane(zPlaneNormal, viewDir, camPos, sign(viewDir.z) * _Depth);

                float depthBehind = LinearEyeDepth(tex2D(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w).r);
                //perspective correct
                
                //return float4(i.osCamPos, 1.0);
                float3 objectSpaceZPos = (maxZPlane * viewDir) + camPos;
                float3 worldSpaceZDiff = mul(unity_ObjectToWorld, float4(objectSpaceZPos, 1.0));
                //using this....
                float3 worldSpaceVector = worldSpaceZDiff - _WorldSpaceCameraPos;
                float3 worldSpaceNormal = UnityObjectToWorldNormal(zPlaneNormal * -sign(viewDir.z));
                worldSpaceNormal = normalize(worldSpaceNormal);
                float perspectiveCorrection = dot(viewDir, zPlaneNormal * sign(viewDir.z));
                //return perspectiveCorrection;
                float3 viewForward = unity_CameraToWorld._m02_m12_m22;
                float depth = dot(worldSpaceVector, normalize(viewForward));

                return 10 / min(depthBehind, depth);

                /*
                return float4(zDir, 1.0);
                zDir = mul(unity_ObjectToWorld, float4(zDir, 1.0)) - _WorldSpaceCameraPos;
                float maxDepth = sqrt(dot(zDir, zDir));
                return 10 / min(depthBehind, maxDepth) ;
                float depth = minZPlane;*/

                return maxZPlane - minZPlane;

                /*
                fixed3 xPlaneNormal = fixed3(1, 0, 0);
                float minXPlane, maxXPlane;
                trace_dual_plane(xPlaneNormal, viewDir, origin, 0.1, minXPlane, maxXPlane);
                

                fixed3 yPlaneNormal = fixed3(0, 1, 0);
                float minYPlane, maxYPlane;
                trace_dual_plane(yPlaneNormal, viewDir, origin, 0.1, minYPlane, maxYPlane);

                float firstHit = min(minZPlane, min(minXPlane, minYPlane));
                float lastHit = min(maxZPlane, min(minXPlane, maxYPlane));
                return lastHit;

                //return min(minZPlane, min(minYPlane, minXPlane));
               

                //forgetabout everything else!
                //start with the object space camera pos...
                return mul(unity_ObjectToWorld, float4(firstHit * viewDir + i.osCamPos, 1.0));*/
            }
            ENDCG
        }
    }
}
