Shader "Unlit/ShadowMapping"
{
    Properties
    {
        _DepthMap ("ShadowMap", 2D) = "white" {}
        _Bias ("Shadow Bias", Range(0, 1)) = 0.0
        _ShadowFade ("Shadow Fade", Range(0, 8)) = 1.0
        [IntRange]_LightMapFadeDistance ("LightMap Edge Fade", Range(1, 4)) = 2
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

            sampler2D _DepthMap;
            float4 _DepthMap_ST;
            float4 _cst_LightDir;
            float4 _cst_NearFar;
            float4x4 _cst_WorldToCamera;
            float _Bias;
            float _ShadowFade;
            int _LightMapFadeDistance;

            v2f vert (appdata v)
            {
                //construct world space coordinates:
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); //now we are in world pos...
                o.uv = TRANSFORM_TEX(v.uv, _DepthMap);
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

            float dot_lighting(float3 normal, float3 lightDirection){
                return saturate(dot(normalize(normal), normalize(lightDirection)));
            }

            float half_lambertify(float shading){
                return (shading + 1.0) / 2.0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 cameraSpaceCoords = mul(_cst_WorldToCamera, i.worldPos);
                float2 projectedUV = proj_uv(cameraSpaceCoords);
                
                float depthDifference = sample_depth_difference(cameraSpaceCoords.z, projectedUV);
                float lightmapFade = lightmap_fadeout(projectedUV);
                float shadow = 1 - saturate(depthDifference);
                //shadow = smoothstep(0.01, 0.01, shadow);
                //shadow = saturate(1 - shadow); //now shadow is closer to 0 and light is closer to 1
                

                //fade out at the edge of the frustum
                float nDotL = dot_lighting(i.worldNormal, -_cst_LightDir);
                
                float shading = saturate(half_lambertify(shadow * nDotL));
                return shading;
                /*
                float depthCoord = (cameraSpaceCoords.z + _Bias);
                float oneOverDepth = 1 / depthCoord;
                //sample the shadow texture:
                float2 screenUV = cameraSpaceCoords.xy / cameraSpaceCoords.w;
                screenUV = (screenUV + 1) / 2;
                float depthTextureDepth = tex2D(_DepthMap, screenUV);
                float depthDiff = depthTextureDepth.rrr - oneOverDepth;
                float shadow = ((1 - smoothstep(0.01, 0.01, depthDiff)));
                

                float shadowFadeCoeff = saturate(1 / (exp(depthDiff * _ShadowFade)));
                shadow += shadowFadeCoeff;
                shadow = saturate(shadow);
                shadow = (shadow + 1) / 2; 

                float atten = dot(normalize(i.worldNormal), normalize(-_cst_LightDir));
                atten = saturate(shadow * atten);
                atten = (atten + 1) / 2;
                atten = atten * atten;
                
                //fade out closer depth...?

                return float4((atten).rrr, 1);*/
            }
            ENDCG
        }
    }
}
