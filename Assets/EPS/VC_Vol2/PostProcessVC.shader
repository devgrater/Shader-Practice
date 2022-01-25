Shader "Hidden/PostProcessing/PostProcessVC"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
            #include "UnityLightingCommon.cginc"

            //////////// Main textures /////////////
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            sampler2D _WeatherMap;
            sampler2D _BlueNoise;
            sampler3D _VolumeTex;
            

            /////////// User Params //////////////
            float _Scale;
            float _WeatherMapScale;
            float _DensityMultiplier;
            float _LightAbsorption;
            float _HeightMapOffset;
            float _MarchDistance;
            float _BlueNoiseStrength;


            ////////// Automatic Operations /////////////
            float3 _VBoxMin;
            float3 _VBoxMax;
            float _DistanceStep;
            
            float remap(float original_value, float original_min, float original_max, float new_min, float new_max)
            {
                return new_min + (((original_value - original_min) / (original_max - original_min)) * (new_max - new_min));
            }

            float2 trace_vbox_planes(float3 cameraPos, float3 oneOverCameraVector){
                float3 hitT0 = (_VBoxMin - cameraPos) * oneOverCameraVector;
                float3 hitT1 = (_VBoxMax - cameraPos) * oneOverCameraVector;

                float3 minT = min(hitT0, hitT1);
                float3 maxT = max(hitT0, hitT1);

                float dstA = max(max(minT.x, minT.y), minT.z);
                float dstB = min(min(maxT.x, maxT.y), maxT.z);

                float dstToBox = max(0, dstA);//if you are inside the box, this returns 0
                float dstInBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInBox);
            }

            fixed sample_volume_texture(float3 pos){
                return tex3D(_VolumeTex, pos * _Scale) * _DensityMultiplier;
            }

            fixed sample_weather_map(float3 pos){
                float depthInClouds = (pos.y - _VBoxMin.y) / (_VBoxMax.y - _VBoxMin.y);
                float weatherMask = tex2D(_WeatherMap, pos.xz * _WeatherMapScale).r;
                float gMin = remap(weatherMask, 0, 1, 0.1, 0.6);
                float gMax = remap(weatherMask, 0, 1, gMin, 0.9);
                
                float heightGradient = saturate(remap(depthInClouds, 0.0, gMin, 0, 1)) * saturate(remap(depthInClouds, 1, gMax, 0, 1));
                float heightGradient2 = saturate(remap(depthInClouds, 0.0, weatherMask.r, 1, 0)) * saturate(remap(depthInClouds, 0.0, gMin, 0, 1));
                heightGradient = saturate(lerp(heightGradient, heightGradient2, _HeightMapOffset));

                return heightGradient;
            }

            fixed sample_cloud(float3 pos){
                return sample_volume_texture(pos) * sample_weather_map(pos);
            }

            //nothign else to worry about.
            fixed march_lightray(float3 pos){
                //trace for the light plane:
                float maxHit = trace_vbox_planes(pos, 1 / _WorldSpaceLightPos0).y;
                //this will guaratee for a hit... almost.
                float stepSize = maxHit / 8;
                float densitySum = 0.0f;
                for(int i = 0; i < 8; i++){
                    //take a step in the light direct:
                    pos += _WorldSpaceLightPos0 * stepSize;
                    //sample the texture
                    fixed density = sample_cloud(pos);
                    densitySum += density * stepSize;
                }
                float outEnergy = exp(-densitySum * _LightAbsorption);
                return outEnergy;
            }


        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }



            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewVector = i.viewVector;
                fixed3 normalizedVector = normalize(viewVector);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = LinearEyeDepth(depth);
                float blueNoiseOffset = tex2D(_BlueNoise, i.uv);


                //now, test for whether you hit the box or not.
                float2 vboxHitInfo = trace_vbox_planes(_WorldSpaceCameraPos, 1 / viewVector);
                float dstToBox = vboxHitInfo.x;
                float dstInBox = vboxHitInfo.y;
                float dstToBoxBack = min(dstInBox + dstToBox, linearDepth);
                float isRayHittingBox = sign(dstInBox);

                float distanceStep = max(dstToBoxBack - dstToBox, 0) / 32;

                float dstTravelled = blueNoiseOffset * _BlueNoiseStrength;
                float transmission = 1.0f;
                float lightEnergy = 0.0f;
                float3 headPos = _WorldSpaceCameraPos + (dstToBox + dstTravelled) * viewVector;
                for(uint step = 0; step < 32; step++){
                    float currentStepDistance = distanceStep;//distanceStep * exp(step / 32) / 1.7;
                    if(dstTravelled > dstToBoxBack){
                        break;
                    }
                    if(transmission < 0.01){
                        break; //too occluded to do anything
                    }
                    fixed cubemapDensity = sample_cloud(headPos); //_DensityMultiplier has been multiplied inside
                    //trace the lightrays for light transmission
                    lightEnergy += transmission * march_lightray(headPos) * cubemapDensity * currentStepDistance;

                    transmission *= exp(-currentStepDistance * cubemapDensity * _LightAbsorption);
                    headPos += currentStepDistance * normalizedVector;
                    dstTravelled += currentStepDistance;
                }


                fixed4 col = tex2D(_MainTex, i.uv);
                //return transmission;
                return (lightEnergy * isRayHittingBox);
                return lerp(col, float4(1.0, 1.0, 1.0, 1.0), (1 - transmission));

                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }
}
