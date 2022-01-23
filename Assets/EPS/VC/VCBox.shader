Shader "Grater/Experimental/VLBox"
{
    Properties
    {
        _WeatherMap ("Weather Map", 2D) = "white" {}
        _VolumeTex ("Volume Texture", 3D) = "white" {}
        _BlueNoise ("Blue Noise", 2D) = "gray" {}
        [PowerSlider]_FogDensity ("Fog Density", Range(0, 1)) = 0.1
        [HDR]_FogColor ("Fog Color", Color) = (0, 0, 0, 1)
        [HDR]_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _Offsets ("Offsets", Vector) = (0, 0, 0, 0)
        _BrightnessPower ("Brightness Power", Range(0.01, 0.99)) = 0.95
        _ShadowPower ("Shadow Power", Range(0.01, 0.99)) = 0.95
        _ShadowThreshold ("Shadow Threshold", Range(0.0, 1.0)) = 0.5
        _LightAbsorption ("Light Absorption", Range(0.0, 2.0)) = 1.6
        _PhaseParams ("Phase Params", Vector) = (0, 0, 0, 0)
        _HeightMapOffset ("HeightMap Offset", Range(0, 1)) = 0.5
        _StepDistance ("Step Distance", Range(0, 128)) = 5
        [PowerSlider]_Scale ("Scale", Range(0, 0.3)) = 0.05
        [PowerSlider]_WeatherMapScale ("Weather Map Scale", Range(0, 0.1)) = 0.01
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
            sampler2D _WeatherMap;
            sampler2D _CameraDepthTexture;
            float4 _FogColor;
            float4 _ShadowColor;
            fixed _FogDensity;
            fixed _ShadowThreshold;
            float _StepDistance;
            float _Scale;
            float _WeatherMapScale;
            float _LV3Scale;
            float _BrightnessPower;
            float _ShadowPower;
            float _HeightMapOffset;
            float _LightAbsorption;
            float _WorldBottom;
            float _WorldTop;
            float4 _PhaseParams;
            float4 _Offsets;

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

            float hg(float a, float g) 
            {
                float g2 = g * g;
                return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * (a), 1.5));
            }
            float phase(float a) 
            {
                float blend = 0.5;
                float hgBlend = hg(a, _PhaseParams.x) * (1 - blend) + hg(a, -_PhaseParams.y) * blend;
                return _PhaseParams.z + hgBlend * _PhaseParams.w;
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

            float calculate_transmittance(float density, float stepSize){
                return exp(-density * stepSize);
            }

            fixed4 sample_volume_texture(float3 pos){
                return tex3D(_VolumeTex, pos * _Scale) * _FogDensity;
            }

            float remap(float original_value, float original_min, float original_max, float new_min, float new_max)
            {
                return new_min + (((original_value - original_min) / (original_max - original_min)) * (new_max - new_min));
            }
                        
            fixed sample_weather_mask(float2 uv, float depthInClouds){
                float weatherMask = tex2D(_WeatherMap, uv * _WeatherMapScale).r;
                float gMin = remap(weatherMask, 0, 1, 0.1, 0.6);
                float gMax = remap(weatherMask, 0, 1, gMin, 0.9);
                //premis:
                //depth in clouds range from 0 to 1, where 1 is the top of the clouds.
                //if the depth in clouds is greater than weather mask,
                //we add in the contribution.
                float heightGradient = saturate(remap(depthInClouds, 0.0, gMin, 0, 1)) * saturate(remap(depthInClouds, 1, gMax, 0, 1));
                float heightGradient2 = saturate(remap(depthInClouds, 0.0, weatherMask.r, 1, 0)) * saturate(remap(depthInClouds, 0.0, gMin, 0, 1));
                heightGradient = saturate(lerp(heightGradient, heightGradient2, _HeightMapOffset));
                //return gMin;
                return heightGradient;//sqrt(gradient);
            }
            
            float march_lightdir(float3 worldPos, float3 osPos, float3 osLightDir, float3 lightDir, float dstToBounds){
                float stepSize = dstToBounds / 4;
                float densitySum = 0.0f;
                worldPos += stepSize * lightDir * 0.5f;
                for(int i = 0; i < 4; i++){
                    worldPos += stepSize * lightDir;
                    osPos += osLightDir * stepSize;
                    //sample!
                    float density = sample_volume_texture(worldPos) * sample_weather_mask(worldPos.xz, osPos.y);
                    densitySum += saturate(density * stepSize);
                }
                float transmittance = exp(-densitySum * _LightAbsorption);
                return _ShadowThreshold + transmittance * (1 - _ShadowThreshold);//transmittance;//return float3(transmittance, transmittance, transmittance);
            }

            float sample_cloud_value(float3 worldPos){
                
                fixed normalizedY = (worldPos.y - _WorldBottom) / (_WorldTop - _WorldBottom);
                worldPos.xz += _Time.gg * _Offsets.xz;
                fixed weatherMask = sample_weather_mask(worldPos.xz, normalizedY);
                fixed densityMask = sample_volume_texture(worldPos);
                return weatherMask * densityMask;
            }

            float light_march(float3 worldPos, float3 osPos, float3 osLightDir, float3 lightDir, float dstToBounds){
                float stepSize = dstToBounds / 8;
                float densitySum = 0.0f;
                worldPos += stepSize * lightDir * 0.5f;
                for(int i = 0; i < 8; i++){
                    worldPos += stepSize * lightDir;
                    osPos += osLightDir * stepSize;
                    float density = sample_cloud_value(worldPos);//sample_volume_texture(worldPos);
                    densitySum += density * stepSize;
                }
                float transmittance = exp(-densitySum * _LightAbsorption);
                return _ShadowThreshold + transmittance * (1 - _ShadowThreshold);
            }



            fixed4 frag (v2f i) : SV_Target
            {
                //in object space, lets say, ideally,
                //that the front plane happens to be 0.5 units away from teh origin.
                //same goes for every other plane.
                /////////////////// TRACING PLANES //////////////////////////
                float3 camPos = i.camPos;
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
                //fixed3 osViewForward = normalize(mul(unity_WorldToObject, float4(viewForward, 0.0f)).xyz);
                float perspectiveCorrection = dot(wsViewDir, viewForward);
                
                
                //dot the vector with the front direction
                fixed frontVectorSign = sign(dot(viewForward, wsFrontVector));
                fixed3 realOsViewDir = normalize(osBackVector);
                //float osPerspectiveCorrection = dot(realOsViewDir, osViewForward);
                //return perspectiveCorrection;
                //outside -> front Vector > 0
                //inside -> front vector < 0

                
                float wsBackFaceDepth = sqrt(dot(wsBackVector, wsBackVector)) * perspectiveCorrection;
                float wsFrontFaceDepth = sqrt(dot(wsFrontVector, wsFrontVector)) * perspectiveCorrection;
                float minDepth = min(existingDepth, wsBackFaceDepth);
                float minStart = max(wsFrontFaceDepth * frontVectorSign, 0);
                float osStart = max(length(osFrontVector) * frontVectorSign, 0);

                float depthDiff = (minDepth - minStart);
                //return saturate(10 / depthDiff);
                float depthColumnWidth = depthDiff / 32;
                float osColumnWidth = depthColumnWidth / i.ratio.y;
                float transmittance = 1.0;

                float3 worldPos = _WorldSpaceCameraPos + wsViewDir * minStart / perspectiveCorrection;
                float3 objPos = camPos + realOsViewDir * osStart;
                float distanceTravelled = 0.0;


                //return float4(objPos + realOsViewDir * osColumnWidth * 32, 1.0f);
                //float ratio = 

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 osLightDir = normalize(i.osLightDir);
                float lightEnergy = 0.0f;

                float cosAngle = dot(wsViewDir, _WorldSpaceLightPos0.xyz);
                float3 phaseVal = phase(cosAngle);
                
                for(float step = 0; step < 32; step++){
                    worldPos += wsViewDir * depthColumnWidth;
                    distanceTravelled += depthColumnWidth;
                    //stop early
                    if(distanceTravelled > minDepth){
                        break;
                    }
                    objPos += realOsViewDir * osColumnWidth;
                    //sample texture...
                    fixed cloudDensity = sample_cloud_value(worldPos);
                    //assume that it's just a flat plane.
                    float depthToLightBounds = find_bounding_box_back(objPos, osLightDir) * i.ratio.x;
                    //using this, trace the planes.
                    float lightTransmittance = light_march(worldPos, objPos, osLightDir / i.ratio.x, lightDir, depthToLightBounds);
                    lightEnergy += lightTransmittance * transmittance * depthColumnWidth * cloudDensity;

                    transmittance *= exp(-cloudDensity * depthColumnWidth * _LightAbsorption);
                    if(transmittance < 0.001f){
                        break;
                    }
                }
                float transmittancePower = (1 - transmittance);
                float scatterOffset = saturate(lightEnergy);
                float midOffset = saturate(scatterOffset - (1 - _ShadowPower)) / _ShadowPower;
                float hlOffset = pow(scatterOffset, _BrightnessPower);
                

                float3 lowToneColor = lerp(_ShadowColor, _FogColor, midOffset);
                float3 finalColor = lerp(lowToneColor, _LightColor0, hlOffset);
                return float4((finalColor + phaseVal) * transmittancePower, transmittancePower);
                //return float4(transmittance, transmittance, transmittance, 1.0f);
                
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
