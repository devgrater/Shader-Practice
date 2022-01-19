Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _VolumeTex ("Volume Texture", 3D) = "white" {}
        _VolumeTex2 ("Volume Texture 2", 3D) = "white" {}
        _VolumeTex3 ("Volume Texture", 3D) = "white" {}
        _Depth ("Depth", Float) = 0.5
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 0.4)) = 0.1
        _FogPower ("Fog Power", Range(1, 8)) = 1
        [IntRange]_StepCount ("Sampling Steps", Range(1, 128)) = 32
        [PowerSlider]_Scale ("Scale", Range(0, 0.3)) = 0.05
        [PowerSlider]_LV2Scale ("LV2 Scale", Range(0, 0.3)) = 0.05
        [PowerSlider]_LV3Scale ("LV3 Scale", Range(0, 0.3)) = 0.05
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
            Cull Front
            ZTest Off
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float3 normal : NORMAL;
                float3 osViewDir : TEXCOORD1;
                float3 camDir : TEXCOORD3;
            };

            sampler3D _VolumeTex;
            sampler3D _VolumeTex2;
            sampler3D _VolumeTex3;
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;
            float _Depth;
            float4 _FogColor;
            fixed _FogDensity;
            float _StepCount;
            float _Scale;
            float _LV2Scale;
            float _LV3Scale;
            float _FogPower;
            //sampler2D _SunCascadedShadowMap; //thanks, my hero!

            v2f vert (appdata v)
            {
                v2f o;
                //o.pos = mul(unity_ObjectToWorld, v.pos);
                //o.pos = mul(UNITY_MATRIX_VP, o.pos);
                o.pos = UnityObjectToClipPos(v.pos);
                
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

                //once we have these, trace from the furthest point,
                //and trace for the front face from there.
                fixed3 zPlaneNormal = sign(viewDir.z) * fixed3(0, 0, 1); //doesn't matter that much (we only care the first hit time and the last hit time.)
                float maxZPlane = trace_one_plane(zPlaneNormal, viewDir, camPos, -0.5);

                fixed3 yPlaneNormal = sign(viewDir.y) * fixed3(0, 1, 0);
                float maxYPlane = trace_one_plane(yPlaneNormal, viewDir, camPos, -0.5);

                fixed3 xPlaneNormal = sign(viewDir.x) * fixed3(1, 0, 0);
                float maxXPlane = trace_one_plane(xPlaneNormal, viewDir, camPos, -0.5);
                
                float backPlaneDepth = max(max(maxZPlane, maxYPlane), maxXPlane);

                float3 osBackVector = (backPlaneDepth * viewDir);
                float3 osBackPos = camPos + osBackVector;
                //now, trace for the front face. We can safely assume that nothing else is in the way,
                //because even if there is, it makes no difference at all.

                float minZPlane = trace_one_plane(zPlaneNormal, -viewDir, osBackPos, 0.5);
                float minXPlane = trace_one_plane(xPlaneNormal, -viewDir, osBackPos, 0.5);
                float minYPlane = trace_one_plane(yPlaneNormal, -viewDir, osBackPos, 0.5);

                float frontPlaneDepth = max(max(minZPlane, minXPlane), minYPlane);
                
                //using this, compute a front plane vector...
                float3 osFrontPos = osBackPos -viewDir * frontPlaneDepth;
                float3 osFrontVector = osFrontPos - camPos;

                //return 0.5 / sqrt(dot(osFrontVector, osFrontVector));


                
                ///////////////////// SAMPLING DEPTH TEXTURE ////////////////////////////
                fixed2 screenUV = i.screenPos.xy / i.screenPos.w;
                float existingDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUV).r);




                /////////////////// CONVERTING VECTORS TO WORLD SPACE ///////////////////////

                //convert object space to world space,
                //and take the union with the existing depth map.
                float3 wsBackVector = mul(unity_ObjectToWorld, float4(osBackVector, 0.0));
                float3 wsFrontVector = mul(unity_ObjectToWorld, float4(osFrontVector, 0.0));
                fixed3 wsViewDir = normalize(wsBackVector); //doesn't matter which one you use.

                ///////////////////////// PERSPECTIVE CORRECT DEPTH /////////////////////////////
                fixed3 viewForward = normalize(unity_CameraToWorld._m02_m12_m22);
                float perspectiveCorrection = dot(wsViewDir, viewForward);
                
                //dot the vector with the front direction
                fixed frontVectorSign = sign(dot(viewForward, wsFrontVector));
                //outside -> front Vector > 0
                //inside -> front vector < 0


                
                float wsBackFaceDepth = sqrt(dot(wsBackVector, wsBackVector)) * perspectiveCorrection;
                float wsFrontFaceDepth = sqrt(dot(wsFrontVector, wsFrontVector)) * perspectiveCorrection;
                float minDepth = min(existingDepth, wsBackFaceDepth);
                float minStart = max(wsFrontFaceDepth * frontVectorSign, 0);
                float depthDiff = (minDepth - minStart);
                //return saturate(10 / depthDiff);
                float depthColumnWidth = depthDiff / _StepCount;

                float lightAmount = 0.0;
                
                for(float step = 0; step < _StepCount; step++){
                    float depthStep = (depthColumnWidth * step + minStart) / perspectiveCorrection;
                    float3 fogWorldSpot = _WorldSpaceCameraPos + wsViewDir * depthStep;
                    //using this, sample the shadowmap.
                    //instead of doing this...
                    //just sample the 3d texture
                    fixed4 fogAmount = tex3D(_VolumeTex, (fogWorldSpot) * _Scale);
                    //float fogAmount = tex3D(_VolumeTex, (fogWorldSpot + _Time.bbb) * _Scale).r * 0.5f;
                    fixed fog = fogAmount.r * 0.5f + fogAmount.g * 0.25f + fogAmount.b * 0.125f + fogAmount.a * 0.0625f;
                    lightAmount += fog;
                    //lightAmount += GetSunShadowsAttenuation_PCF5x5(fogWorldSpot, depthStep, 0.1);
                    //using this, we can sample the shadow map.
                }

                lightAmount = lightAmount / _StepCount;
                lightAmount = pow(lightAmount, _FogPower);

                

                float4 screenColor = tex2D(_GrabTexture, screenUV);

                //now we can ask the basic question.
                float depthDifference = depthDiff * perspectiveCorrection;
                fixed fogAmount = 1 / exp(depthDifference * _FogDensity * (lightAmount));
                return lerp(_LightColor0 * _FogColor, screenColor, saturate(fogAmount));


                //return 10 / minDepth;


            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
