Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _VolumeTex ("Volume Texture", 3D) = "white" {}
        _StepDistance ("Step Distance", Range(0, 10)) = 0.1
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 0.4)) = 0.1
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [HDR]_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        
        _FogPower ("Fog Power", Range(1, 8)) = 1
        _TransmittenceOffset ("Transmittance Offset", Range(0, 40)) = 1
        [IntRange]_StepCount ("Sampling Steps", Range(1, 128)) = 32
        [PowerSlider]_Scale ("Scale", Range(0, 0.3)) = 0.05
        [PowerSlider]_LV2Scale ("LV2 Scale", Range(0, 0.3)) = 0.05
        [PowerSlider]_LV3Scale ("LV3 Scale", Range(0, 0.3)) = 0.05
    }

    

    SubShader
    {

        LOD 100
        Tags {
            //"LightMode"="ForwardBase"
            "RenderType"="Transparent" 
            "Queue"="Transparent+1"
        }

        Pass
        {
                    
        
            //premultiplied
            Blend One OneMinusSrcAlpha
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
            sampler2D _CameraDepthTexture;
            float4 _FogColor;
            float4 _ShadowColor;
            fixed _FogDensity;
            float _StepCount;
            float _Scale;
            float _LV2Scale;
            float _LV3Scale;
            float _FogPower;
            float _StepDistance;
            float _TransmittenceOffset;
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


            float find_bounding_box_back(float3 camPos, float3 viewDir){
                fixed3 zPlaneNormal = sign(viewDir.z) * fixed3(0, 0, 1); //doesn't matter that much (we only care the first hit time and the last hit time.)
                fixed3 yPlaneNormal = sign(viewDir.y) * fixed3(0, 1, 0);
                fixed3 xPlaneNormal = sign(viewDir.x) * fixed3(1, 0, 0);

                float maxZPlane = trace_one_plane(zPlaneNormal, viewDir, camPos, -0.5);
                float maxYPlane = trace_one_plane(yPlaneNormal, viewDir, camPos, -0.5);
                float maxXPlane = trace_one_plane(xPlaneNormal, viewDir, camPos, -0.5);
            
                return max(max(maxZPlane, maxYPlane), maxXPlane);

            }

            float find_bounding_box_front(float3 osBackPos, float3 viewDir){
                fixed3 zPlaneNormal = sign(viewDir.z) * fixed3(0, 0, 1); //doesn't matter that much (we only care the first hit time and the last hit time.)
                fixed3 yPlaneNormal = sign(viewDir.y) * fixed3(0, 1, 0);
                fixed3 xPlaneNormal = sign(viewDir.x) * fixed3(1, 0, 0);
                
                float minZPlane = trace_one_plane(zPlaneNormal, -viewDir, osBackPos, 0.5);
                float minXPlane = trace_one_plane(xPlaneNormal, -viewDir, osBackPos, 0.5);
                float minYPlane = trace_one_plane(yPlaneNormal, -viewDir, osBackPos, 0.5);

                return max(max(minZPlane, minXPlane), minYPlane);
            }

            float calculate_transmittance(fixed density, float stepSize){
                return exp(-density * stepSize);
            }

            fixed4 sample_volume_texture(float3 pos){
                return tex3D(_VolumeTex, pos * _Scale);
            }

            /*float3 march_lightdir(float3 worldPos, fixed3 lightDir){
                float dstToBounds = find_bounding_box_back(worldPos, lightDir);
                //just start marching towards the boundary...
                float stepSize = dstToBounds / 8;
                float densitySum = 0.0f;
                for(int i = 0; i < 4.0f; i++){
                    worldPos += stepSize * lightDir;
                    //sample!
                    densitySum += sample_volume_texture(worldPos) * _FogDensity * stepSize;
                }
                float transmittance = exp(-densitySum);
                return float3(transmittance, transmittance, transmittance);
            }*/

            float3 march_lightdir(float3 worldPos, fixed3 lightDir){
                //instead of doing all the fancy stuff
                //we nudge the worldpos a bit towards the light direction.
                worldPos -= lightDir * _TransmittenceOffset;
                //and then sample...the cube map.
                fixed volume = sample_volume_texture(worldPos) * _FogDensity;
                //lerp between the 3 colors.
                return float3(1 - volume, 1 - volume, 1 - volume);

            }


            fixed4 frag (v2f i) : SV_Target
            {
                //in object space, lets say, ideally,
                //that the front plane happens to be 0.5 units away from teh origin.
                //same goes for every other plane.
                /////////////////// TRACING PLANES //////////////////////////
                float3 camPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                fixed3 viewDir = normalize(i.osViewDir);

                //once we have these, trace from the furthest point,
                //and trace for the front face from there.
                float backPlaneDepth = find_bounding_box_back(camPos, viewDir);
                //find_bounding_box(camPos, viewDir, backPlaneDepth, frontPlaneDepth);

                float3 osBackVector = (backPlaneDepth * viewDir);
                float3 osBackPos = camPos + osBackVector;
                //now, trace for the front face. We can safely assume that nothing else is in the way,
                //because even if there is, it makes no difference at all.
                //using this, compute a front plane vector...
                float frontPlaneDepth = find_bounding_box_front(osBackPos, viewDir);
                float3 osFrontPos = osBackPos -viewDir * frontPlaneDepth;
                float3 osFrontVector = osFrontPos - camPos;

                
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
                float depthColumnWidth = saturate(depthDiff / 32);
                float transmittance = 1.0;

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                float lightAmount = 0.0;
                float3 finalColor = float3(0, 0, 0);
                for(float step = 0; step < 32; step++){
                    float depthStep = (depthColumnWidth * step + minStart);
                    if(depthStep > minDepth){
                        break;
                    }
                    if(lightAmount >= 1.0f){
                        break;
                    }
                    float3 fogWorldSpot = _WorldSpaceCameraPos + wsViewDir * depthStep / perspectiveCorrection;

                    //just sample the 3d texture
                    fixed4 fogAmount = sample_volume_texture(fogWorldSpot);
                    lightAmount += fogAmount.r * _FogDensity;
                    transmittance *= calculate_transmittance(fogAmount.r * _FogDensity, depthColumnWidth); 
                    float3 lightTransmittance = march_lightdir(fogWorldSpot, lightDir);
                    finalColor += transmittance * (1 - lightTransmittance);
                    
                    //lightAmount += GetSunShadowsAttenuation_PCF5x5(fogWorldSpot, depthStep, 0.1);
                    //using this, we can sample the shadow map.
                }

                //lightAmount = pow(lightAmount, _FogPower);

                return float4(finalColor, 1.0);//_FogColor * (1 - transmittance);//lightAmount * depthColumnWidth;

                

                //float4 screenColor = tex2D(_GrabTexture, screenUV);
                //now we can ask the basic question.
                float depthDifference = max(depthDiff, 0) * lightAmount * perspectiveCorrection;
                return depthDifference;
                /*
                fixed fogAmount = 1 - 1 / exp(depthDifference * _FogDensity * (lightAmount));
                return fogAmount;//float4(_FogColor.rgb, 1 - saturate(fogAmount));*/
                //return lerp(_FogColor, screenColor, saturate(fogAmount));
                

                //return 10 / minDepth;


            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
