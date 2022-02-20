Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Depth ("Depth", Float) = 0.5
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 0.4)) = 0.1
        [IntRange]_StepCount ("Sampling Steps", Range(1, 128)) = 32
    }

    

    SubShader
    {

        
        Tags {
            "LightMode"="ForwardBase"
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
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Shadows.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float3 osViewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;
            float _Depth;
            float4 _FogColor;
            fixed _FogDensity;
            float _StepCount;
            //sampler2D _SunCascadedShadowMap; //thanks, my hero!

            v2f vert (appdata v)
            {
                v2f o;
                //o.pos = mul(unity_ObjectToWorld, v.pos);
                //o.pos = mul(UNITY_MATRIX_VP, o.pos);
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.screenPos = ComputeScreenPos(o.pos);
                //o.osNormal = v.normal; //prob dont need this
                //o.osVertex = v.vertex;
                
                o.osViewDir = ObjSpaceViewDir(v.pos);
                //question:
                //UNITY_TRANSFER_FOG(o,o.pos);
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
                
                float backPlaneDepth = max(max(maxZPlane, maxYPlane), maxXPlane);

                fixed2 screenUV = i.screenPos.xy / i.screenPos.w;
                float existingDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUV).r);
                //perspective correct
                
                //convert object space to world space,
                //and take the union with the existing depth map.
                float3 objectSpacePos = (backPlaneDepth * viewDir);
                float3 worldSpaceVector = mul(unity_ObjectToWorld, float4(objectSpacePos, 0.0));

                fixed3 wsViewDir = normalize(worldSpaceVector);
                fixed3 viewForward = normalize(unity_CameraToWorld._m02_m12_m22);
                float perspectiveCorrection = dot(wsViewDir, viewForward);
                
                float perspectiveCorrectDepth = sqrt(dot(worldSpaceVector, worldSpaceVector)) * perspectiveCorrection;//dot(worldSpaceVector, normalize(viewForward));
                float minDepth = min(existingDepth, perspectiveCorrectDepth);

                float depthDiff = (minDepth - i.screenPos.w);
                float depthColumnWidth = depthDiff / _StepCount;

                float lightAmount = 0.0;
                float transmission = 1.0f;
                for(float step = 0; step < _StepCount; step++){
                    float depthStep = (depthColumnWidth * step + i.screenPos.w) / perspectiveCorrection;
                    float3 fogWorldSpot = _WorldSpaceCameraPos + wsViewDir * depthStep;
                    //using this, sample the shadowmap.
                    //essentially, the part thats not under the sun have almost no transmission.
                    lightAmount += GetSunShadowsAttenuation_PCF5x5(fogWorldSpot, depthStep, 0.1);
                    //using this, we can sample the shadow map.
                }

                lightAmount = lightAmount / _StepCount;

                

                float4 screenColor = tex2D(_GrabTexture, screenUV);

                //now we can ask the basic question.
                float depthDifference = (minDepth - i.screenPos.w) * perspectiveCorrection;
                fixed fogAmount = 1 / exp(depthDifference * _FogDensity * (lightAmount));
                return lerp(_LightColor0 * 2.2, screenColor, saturate(fogAmount));


                //return 10 / minDepth;


            }
            ENDCG
        }
    }
    //Fallback "VertexLit"
}
