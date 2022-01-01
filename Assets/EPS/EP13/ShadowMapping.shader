Shader "Unlit/ShadowMapping"
{
    Properties
    {
        _LightColor ("Light Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _MainTex ("MainTex", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _DepthMap ("ShadowMap", 2D) = "white" {}
        _Bias ("Shadow Bias", Range(0, 1)) = 0.0
        _ShadowFade ("Shadow Fade", Range(0, 8)) = 1.0
        //_PCSSSampleDistance ("Light Size", Range(0, 2)) = 1
        //[IntRange]_PCSSIteration ("PCSS Iteration", Range(1, 4)) = 2

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #define PCSS
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
                float4 worldPos : TEXCOORD1;
                float3 worldNormal : NORMAL;
            };


            float4 _Color;
            float4 _LightColor;
            float4 _ShadowColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DepthMap;
            float4 _DepthMap_ST;
            float4 _DepthMap_TexelSize;
            float4 _cst_LightDir;
            float4 _cst_NearFar;
            float4x4 _cst_WorldToCamera;
            float _Bias;
            float _ShadowFade;
            int _LightMapFadeDistance;
            int _PCSSIteration;
            float _PCSSSampleDistance;

            v2f vert (appdata v)
            {
                //construct world space coordinates:
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); //now we are in world pos...
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float lightmap_fadeout(float2 uvCoords){
                float2 fadeouts = saturate(1.0 - pow(2.0 * uvCoords.xy - 1.0, 2));
                //return fadeouts.x * fadeouts.y;
                return saturate(saturate(1 - uvCoords.y) * fadeouts.x);//saturate(fadeouts.x * saturate());
            }

            float2 proj_uv(float4 camCoords){
                float2 screenUV = camCoords.xy / camCoords.w;
                screenUV = (screenUV + 1) / 2;
                return screenUV;
            }

            float sample_depth_difference(float z, float2 projectedUV){
                float pixelDepth = 1  / (z + _Bias);
                float lightSpaceDepth = tex2D(_DepthMap, projectedUV);
                //float depth_difference =  = 
                return lightSpaceDepth - pixelDepth;
            }

            float pcss_sample_depth_difference(float z, float averageDepth){
                float pixelDepth = 1  / (z + _Bias);
                return averageDepth - pixelDepth;
            }

            float dot_lighting(float3 normal, float3 lightDirection){
                return saturate(dot(normalize(normal), normalize(lightDirection)));
            }

            float half_lambertify(float shading){
                return (shading + 1.0) / 2.0;
            }

            float get_depth_average(float z, float2 uv){
                //sample the shadow values around
                //and filter it out...
                int sampleCount = _PCSSIteration * 2 + 1;
                float pixelDepth = 1  / (z + _Bias);
                float averageDepth = 0;
                float2 uvOffset = _DepthMap_TexelSize.xy / sampleCount * z * _PCSSSampleDistance;
                for(int i = -_PCSSIteration; i <= _PCSSIteration; i++){
                    for(int j = -_PCSSIteration; j <= _PCSSIteration; j++){
                        float2 offsetUV = float2(i, j) * uvOffset + uv;
                        float lightSpaceDepth = tex2D(_DepthMap, offsetUV);
                        //if pixel depth is greater than light space depth, then, the pixel is not occluded.
                        averageDepth += lightSpaceDepth < pixelDepth;
                    }
                }
                return averageDepth / (sampleCount * sampleCount);
            }

            float get_depth_average_left(float z, float2 uv){
                                //sample the shadow values around
                //and filter it out...
                int sampleCount = _PCSSIteration * 2 + 1;
                float pixelDepth = 1  / (z + _Bias);
                float averageDepth = 0;
                float2 uvOffset = _DepthMap_TexelSize.xy / sampleCount * z * _PCSSSampleDistance;
                for(int i = -_PCSSIteration; i <= _PCSSIteration; i++){
                    for(int j = -_PCSSIteration; j <= _PCSSIteration; j++){
                        float2 offsetUV = float2(i, j) * uvOffset + uv;
                        float lightSpaceDepth = tex2D(_DepthMap, offsetUV);
                        //if pixel depth is greater than light space depth, then, the pixel is not occluded.
                        averageDepth += lightSpaceDepth < pixelDepth;
                    }
                }
                return averageDepth / (sampleCount * sampleCount);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 baseTexture = tex2D(_MainTex, i.uv);
                float4 cameraSpaceCoords = mul(_cst_WorldToCamera, i.worldPos);
                float2 projectedUV = proj_uv(cameraSpaceCoords);
                float lightmapFade = pow(lightmap_fadeout(projectedUV), 0.9);
                
                #ifdef PCSS
                    float averageDepth = get_depth_average(cameraSpaceCoords.z, projectedUV);
                    //float pcssShadow = pcss_sample_depth_difference(cameraSpaceCoords.z, averageDepth);
                    float shadow = averageDepth;
                #else
                    float depthDifference = sample_depth_difference(cameraSpaceCoords.z, projectedUV);
                    
                    float shadow = saturate(depthDifference);
                    shadow = 1 - smoothstep(0.01, 0.01, shadow);
                #endif


                //shadow = saturate(1 - shadow); //now shadow is closer to 0 and light is closer to 1
                

                //fade out at the edge of the frustum
                float nDotL = dot_lighting(i.worldNormal, -_cst_LightDir);
                float shading = saturate(shadow * nDotL);
                shading = 1 - (1 - shading) * lightmapFade;
                return lerp(_ShadowColor, _LightColor, shading) * baseTexture * _Color;
                //return averageDepth;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
