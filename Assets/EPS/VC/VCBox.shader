Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _VolumeTex ("Volume Texture", 3D) = "white" {}
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 1)) = 0.1
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [HDR]_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        
        _FogPower ("Fog Power", Range(1, 8)) = 1
        [PowerSlider]_TransmittenceOffset ("Transmittance Offset", Range(0, 1)) = 1
        [IntRange]_StepCount ("Sampling Steps", Range(1, 128)) = 32
        [PowerSlider]_Scale ("Scale", Range(0, 0.3)) = 0.05
        //[PowerSlider]_LV2Scale ("LV2 Scale", Range(0, 0.3)) = 0.05
        //[PowerSlider]_LV3Scale ("LV3 Scale", Range(0, 0.3)) = 0.05
    }

    

    SubShader
    {

        LOD 100
        Tags {
            "LightMode"="ForwardBase"
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
            //#pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            //#include "Shadows.cginc"

            struct appdata
            {
                float4 pos : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float3 osViewDir : TEXCOORD1;
                
                float3 camDir : TEXCOORD3;
                float3 camPos : TEXCOORD4;
                float3 osLightDir : TEXCOORD5;
                float2 ratio : TEXCOORD6; //x - os:ws Light
                                          //y - os:ws Camera
                /*
                float wsDistance : TEXCOORD5;
                float3 wsZNormal : TEXCOORD6;
                float3 wsXNormal : TEXCOORD7;
                float3 wsYNormal : TEXCOORD8;
                float3 wsNormalOffset : TEXCOORD9;*/
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
            float _TransmittenceOffset;

            float2 computeWorldSpaceRatio(fixed3 osLightDir, fixed3 osViewDir){
                //perform a transformation to world space:
                float3 wsLightDirDst = mul(unity_ObjectToWorld, float4(osLightDir, 0.0f)).xyz;
                float3 wsViewDirDst = mul(unity_ObjectToWorld, float4(osViewDir, 0.0f)).xyz;
                float wsLightLength = length(wsLightDirDst);
                float wsViewLength = length(wsViewDirDst);
                return float2(wsLightLength, wsViewLength);
            }



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                
                o.screenPos = ComputeScreenPos(o.pos);
                o.camPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                o.osViewDir = ObjSpaceViewDir(v.pos);
                o.osLightDir = normalize(mul(unity_WorldToObject, float4(_WorldSpaceLightPos0.xyz, 0.0f)).xyz);
                o.ratio = computeWorldSpaceRatio(
                    normalize(o.osLightDir),
                    normalize(o.osViewDir)
                );
                return o;
            }

            float trace_one_plane(float3 normal, float3 viewDir, float3 origin, float c){
                return (c - dot(normal, origin)) / dot(normal, viewDir);
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

            float trace_worldspace_back(float3 pos, float3 dir, float3 nx, float3 ny, float3 nz, float3 offsets){
                float maxZPlane = trace_one_plane(nz, dir, pos, offsets.z);
                float maxYPlane = trace_one_plane(ny, dir, pos, offsets.y);
                float maxXPlane = trace_one_plane(nx, dir, pos, offsets.x);
            
                return max(max(maxZPlane, maxYPlane), maxXPlane);
            }

            float calculate_transmittance(fixed density, float stepSize){
                return exp(-density * stepSize);
            }

            fixed4 sample_volume_texture(float3 pos){
                return tex3D(_VolumeTex, pos * _Scale);
            }
            
            float march_lightdir(float3 worldPos, fixed3 lightDir, float dstToBounds){
                float stepSize = dstToBounds / 4;
                float densitySum = 0.0f;
                for(int i = 0; i < 4; i++){
                    worldPos += stepSize * lightDir;
                    //sample!
                    densitySum += sample_volume_texture(worldPos) * _FogDensity * stepSize;
                }
                float transmittance = exp(-densitySum * _TransmittenceOffset);
                return transmittance;//transmittance;//return float3(transmittance, transmittance, transmittance);
            }
            /*
            float3 march_lightdir(float3 worldPos, fixed3 lightDir){
                //instead of doing all the fancy stuff
                //we nudge the worldpos a bit towards the light direction.
                //and then sample...the cube map.
                fixed volume = sample_volume_texture(worldPos + lightDir * _TransmittenceOffset) * _FogDensity;
                //lerp between the 3 colors.
                return float3(1 - volume, 1 - volume, 1 - volume);

            }*/


            fixed4 frag (v2f i) : SV_Target
            {
                //in object space, lets say, ideally,
                //that the front plane happens to be 0.5 units away from teh origin.
                //same goes for every other plane.
                /////////////////// TRACING PLANES //////////////////////////
                float3 camPos = i.camPos;//mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
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
                float3 osFrontPos = osBackPos - viewDir * frontPlaneDepth;
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
                fixed3 realOsViewDir = normalize(osFrontVector);
                //outside -> front Vector > 0
                //inside -> front vector < 0

                
                float wsBackFaceDepth = sqrt(dot(wsBackVector, wsBackVector)) * perspectiveCorrection;
                float wsFrontFaceDepth = sqrt(dot(wsFrontVector, wsFrontVector)) * perspectiveCorrection;
                float minDepth = min(existingDepth, wsBackFaceDepth);
                float minStart = max(wsFrontFaceDepth * frontVectorSign, 0);
                float osStart = max(length(osFrontVector) * frontVectorSign, 0);

                //return float4(normalize(osFrontVector) * osStart + camPos, 1.0f);
                float depthDiff = (minDepth - minStart);
                //return saturate(10 / depthDiff);
                float depthColumnWidth = 5.0f;//saturate(depthDiff / 32);
                float osColumnWidth = depthColumnWidth / i.ratio.y;
                float transmittance = 1.0;
                
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                //return float4(osStart * normalize(osFrontVector) + camPos, 1.0);

                //convert to world space.
                
                //using the object space light directions, we can compute out....
                //the planes in their world space.

                float lightAmount = 0.0;
                float outScattering = 0.0;

                //object space light dir, and object space pos.
                for(float step = 0; step < 32; step++){
                    float depthStep = (depthColumnWidth * step) + minStart;
                    float osStep = (depthColumnWidth * step) / i.ratio.y + osStart;
                    if(depthStep > minDepth){
                        break;
                    }

                    float3 fogWorldSpot = _WorldSpaceCameraPos + wsViewDir * depthStep / perspectiveCorrection;
                    float3 fogObjectSpot = camPos + realOsViewDir * osStep;
                    //just sample the 3d texture
                    fixed4 fogAmount = sample_volume_texture(fogWorldSpot);
                    transmittance *= calculate_transmittance(fogAmount.r * _FogDensity, depthColumnWidth); 
                    float marchDistance = find_bounding_box_back(fogObjectSpot, i.osLightDir) * i.ratio.x;
                    float lightTransmittance = march_lightdir(fogWorldSpot, lightDir, marchDistance);
                    
                    outScattering += transmittance * lightTransmittance * depthColumnWidth;
                }
                //return float4(0, 0, 0, 1 - transmittance);
                //return outScattering;
                return float4(lerp(_ShadowColor, _FogColor, saturate(outScattering)).rgb * (1 - transmittance), 1 - transmittance);
                
                //return saturate(float4(outScattering, outScattering, outScattering, 1.0)); //finalColor.r;//_FogColor * (1 - transmittance);//lightAmount * depthColumnWidth;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
