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
            sampler3D _CloudMask;
            sampler2D _GradientMap;
            

            /////////// User Params //////////////
            float _Scale;
            float _WeatherMapScale;
            float _DensityMultiplier;
            float _LightAbsorption;
            float _HeightMapOffset;
            float _MarchDistance;
            float _BlueNoiseStrength;
            float _WeatherMapOffset;
            float _CloudMaskScale;
            float _MaxMarchDistance;

            float _ShadowPower;
            float _BrightnessPower;
            float _ShadowThreshold;

            float4 _CloudMaskWeight;
            float4 _CloudDetailWeight;

            float4 _ShadowColor;
            float4 _MidColor;
            float4 _PhaseParams;
            
            float3 _BaseMapAnim;
            float2 _WeatherMapAnim;
            float3 _DetailMapAnim;
            

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

            fixed sample_detail_texture(float3 pos){
                fixed4 volume = tex3D(_VolumeTex, (pos + _Time.ggg * _DetailMapAnim) * _Scale ) * _DensityMultiplier;
                return saturate(dot(volume, _CloudDetailWeight));
            }

            fixed sample_noise_mask(float3 pos){
                return tex3D(_CloudMask, pos * _CloudMaskScale) * _DensityMultiplier;
            }

            fixed sample_cloud_baseshape(float3 pos){
                float3 noiseMask = sample_noise_mask(pos + _Time.ggg * _BaseMapAnim);
                noiseMask = noiseMask * noiseMask; //make some part less visible....
                noiseMask = saturate(noiseMask - 0.2f);

                float maskValue = dot(noiseMask, _CloudMaskWeight.xyz);
                return maskValue;
            }

            fixed sample_weather_map(float3 pos){
                float depthInClouds = (pos.y - _VBoxMin.y) / (_VBoxMax.y - _VBoxMin.y);
                float weatherMask = tex2D(_WeatherMap, (pos.xz + _Time.gg * _WeatherMapAnim.xy) * _WeatherMapScale).r;
                weatherMask = saturate(weatherMask + _WeatherMapOffset);
                float gMin = remap(weatherMask, 0, 1, 0.1, 0.6);
                float gMax = remap(weatherMask, 0, 1, gMin, 0.9);
                
                float heightGradient = saturate(remap(depthInClouds, 0.0, gMin, 0, 1)) * saturate(remap(depthInClouds, 1, gMax, 0, 1));
                float heightGradient2 = saturate(remap(depthInClouds, 0.0, weatherMask.r, 1, 0)) * saturate(remap(depthInClouds, 0.0, gMin, 0, 1));
                heightGradient = saturate(lerp(heightGradient, heightGradient2, _HeightMapOffset));
                
                const float containerEdgeFadeDst = 50;
                float dstFromEdgeX = min(containerEdgeFadeDst, min(pos.x - _VBoxMin.x, _VBoxMax.x - pos.x));
                float dstFromEdgeZ = min(containerEdgeFadeDst, min(pos.z - _VBoxMin.z, _VBoxMax.z - pos.z));
                float edgeWeight = min(dstFromEdgeZ,dstFromEdgeX) / containerEdgeFadeDst;

                return saturate(heightGradient * edgeWeight);
            }

            float hg(float a, float g) 
            {
                float g2 = g * g;
                return (1 - g2) / (12.5664f * pow(1 + g2 - 2 * g * (a), 1.5));
            }

            float phase(float a) 
            {
                float blend = 0.5;
                float hgBlend = hg(a, _PhaseParams.x) * (1 - blend) + hg(a, -_PhaseParams.y) * blend;
                return _PhaseParams.z + hgBlend * _PhaseParams.w;
            }

            fixed sample_cloud(float3 pos){
                fixed baseShape = sample_cloud_baseshape(pos);
                fixed weatherMap = sample_weather_map(pos);
                fixed baseSum = baseShape * weatherMap;
                if(baseSum > 0.01){
                    return sample_detail_texture(pos) * baseSum;
                }
                return baseSum;
            }

            //nothign else to worry about.
            fixed march_lightray(float3 pos, float3 inverseLightVector){
                //trace for the light plane:
                float maxHit = trace_vbox_planes(pos, inverseLightVector).y;
                //this will guaratee for a hit... almost.
                float stepSize = maxHit * 0.25f;
                float3 stepVector = _WorldSpaceLightPos0 * stepSize;
                float densitySum = 0.0f;
                for(int i = 0; i < 4; i++){
                    //take a step in the light direct:
                    pos += stepVector;
                    //sample the texture
                    fixed density = sample_cloud(pos);
                    densitySum += density * stepSize;
                }
                float outEnergy = exp(-densitySum * _LightAbsorption);
                return outEnergy;
                //return _ShadowThreshold + outEnergy * (1 - _ShadowThreshold);
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
                float3 inverseViewVector = 1 / viewVector;
                float3 inverseLightVector = 1 / _WorldSpaceLightPos0;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = LinearEyeDepth(depth);
                float blueNoiseOffset = tex2D(_BlueNoise, (i.uv + _Time.gg) * 3.0f );


                //now, test for whether you hit the box or not.
                float2 vboxHitInfo = trace_vbox_planes(_WorldSpaceCameraPos, inverseViewVector);
                float dstToBox = vboxHitInfo.x;
                float dstInBox = vboxHitInfo.y;
                float dstToBoxBack = min(dstInBox, linearDepth - dstToBox);
                float isRayHittingBox = sign(dstToBoxBack);

                float totalDistanceStep = _MarchDistance;//min(max(dstToBoxBack - dstToBox, 0) / 32, _MarchDistance);//_MarchDistance * sign(max(dstToBoxBack - dstToBox, 0));
                float distanceStep = totalDistanceStep;
                //float distanceStep = max(dstToBoxBack - dstToBox, 0) / 24;

                float dstTravelled = blueNoiseOffset * _BlueNoiseStrength;
                float transmittance = 1.0f;
                float lightEnergy = 0.0f;
                float3 headPos = _WorldSpaceCameraPos + (dstToBox + dstTravelled) * viewVector;
                float3 stepVector = distanceStep * normalizedVector;
                float absorptionAmount = distanceStep * _LightAbsorption;
                
                [loop]
                while(dstTravelled < dstToBoxBack && transmittance > 0.01){
                    fixed cubemapDensity = sample_cloud(headPos); //_DensityMultiplier has been multiplied inside
                    dstTravelled += distanceStep;
                    //trace the lightrays for light transmittance
                    if(cubemapDensity > 0.01){
                        
                        lightEnergy += transmittance * march_lightray(headPos, inverseLightVector) * cubemapDensity * distanceStep;
                        transmittance *= exp(-absorptionAmount * cubemapDensity);
                    }
                    
                    headPos += stepVector;
                    
                }

                //return lightEnergy;
                float cosAngle = dot(normalizedVector, _WorldSpaceLightPos0.xyz);
                float3 phaseVal = phase(cosAngle);
                float transmittancePower = (1 - transmittance);
                float scatterOffset = saturate(lightEnergy) + phaseVal;

                float3 finalColor = tex2D(_GradientMap, fixed2(scatterOffset, 0.0f));

                //return scatterOffset;
                /*
                float midOffset = saturate(scatterOffset - (1 - _ShadowPower)) / _ShadowPower;
                float hlOffset = pow(scatterOffset, _BrightnessPower);
                

                float3 lowToneColor = lerp(_ShadowColor, _MidColor, midOffset);
                float3 finalColor = lerp(lowToneColor, _LightColor0, hlOffset);

                finalColor += phaseVal;*/
                //return float4((finalColor + phaseVal) * transmittancePower, transmittancePower);

                fixed4 col = tex2D(_MainTex, i.uv);
                return lerp(col, float4(finalColor, 1.0f), (1 - transmittance) * (1 - transmittance) );

                // just invert the colors
                //col.rgb = 1 - col.rgb;
            }
            ENDCG
        }
    }
}
