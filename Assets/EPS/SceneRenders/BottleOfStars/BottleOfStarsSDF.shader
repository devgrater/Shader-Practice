Shader "Hidden/BottleOfStars"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Galaxy ("Galaxy", 2D) = "black" {}
        _Stars ("StarMap", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "GraterSDFShapes.cginc"
            #include "GraterSDFOperators.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewDir = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }

            sampler2D _MainTex;
            sampler2D _Galaxy;
            sampler2D _Stars;




            


            //equivalent of map() in iq's example
            float evalGlass(float3 checkPoint){
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 3.0f);
                float tube = cylinderSDF(checkPoint, float3(0.0f, 2.8f, 0.0f), 2.4f, 0.8f);
                minDist = sdfSmoothUnion(minDist, tube, 0.6f);

                float torus = torusSDF(checkPoint, float3(0.0f, 5.2f, 0.0f), 0.8f, 0.3f);
                minDist = sdfSmoothUnion(minDist, torus, 0.2f);
                return minDist;
            }

            float evalBackGlass(float3 checkPoint){
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 3.0f);
                float tube = cylinderSDF(checkPoint, float3(0.0f, 2.8f, 0.0f), 2.4f, 0.8f);
                minDist = sdfSmoothUnion(minDist, tube, 0.6f);

                float torus = torusSDF(checkPoint, float3(0.0f, 5.2f, 0.0f), 0.8f, 0.3f);
                minDist = sdfSmoothUnion(minDist, torus, 0.2f);
                return minDist;
            }

            float waveDisplace(float3 sdfPoint){
                float dfc = length(sdfPoint.xz);
                return (sin(4 * (dfc - _Time.g * 1.5))) * 0.05 + (sin(2 * (sdfPoint.x + _Time.b * 1))) * 0.1;
                
                //return (sin(2 * (sdfPoint.x + _Time.g * 3))) * 0.2;
            }

            float evalInner(float3 checkPoint){
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 2.8f);
                float3 ddt = checkPoint;
                float plane = planeSDF(checkPoint, 1.0f, -1.0f) + waveDisplace(ddt);
                return sdfSmoothSubtract(plane, minDist, 0.3f);
            }

            void rayMarchGlassSDF(float3 startPos, float3 viewDir, out float hit, out float3 col, out float dst){
                float minDist = 3.402823466e+38F;
                float dstTravelled = 0.0f;
                float3 headPos = startPos;
                hit = 0.0f;
                //float initDist = evalGlass(headPos);
                for(uint i = 0; i < 70; i++){
                    //raymarch!
                    minDist = evalGlass(headPos);
                    headPos += minDist * viewDir;
                    dstTravelled += minDist;
                    if(abs(minDist) <= 0.005f){
                        hit = 1.0f;
                        break;
                    }
                }
                /*for(int i = 0; i < 70; i++){

                }*/
                dst = dstTravelled;
                col = float3(1, 1, 1);
            }


            void rayMarchInnerSDF(float3 startPos, float3 viewDir, out float hit, out float3 col, out float dst){
                float minDist = 3.402823466e+38F;
                float dstTravelled = 0.0f;
                float3 headPos = startPos;
                hit = 0.0f;
                //float initDist = evalGlass(headPos);
                for(uint i = 0; i < 70; i++){
                    //raymarch!
                    minDist = evalInner(headPos);
                    headPos += minDist * viewDir;
                    dstTravelled += minDist;
                    if(abs(minDist) <= 0.005f){
                        hit = 1.0f;
                        break;
                    }
                }
                dst = dstTravelled;
                col = float3(1, 1, 1);
            }
            

            
            //No idea what this is all about yet... thanks regardless iq
            fixed3 findInnerNormal(float3 pos){
                
                fixed2 eps = fixed2(1.0, -1.0) * 0.5773 * 0.0005;
                return normalize(
                    eps.xyy * evalInner(pos + eps.xyy).x + 
                    eps.yyx * evalInner(pos + eps.yyx).x + 
                    eps.yxy * evalInner(pos + eps.yxy).x + 
                    eps.xxx * evalInner(pos + eps.xxx).x
                );
                
            }


            fixed3 findGlassNormal(float3 pos){
                
                fixed2 eps = fixed2(1.0, -1.0) * 0.5773 * 0.0005;
                return normalize(
                    eps.xyy * evalGlass(pos + eps.xyy).x + 
                    eps.yyx * evalGlass(pos + eps.yyx).x + 
                    eps.yxy * evalGlass(pos + eps.yxy).x + 
                    eps.xxx * evalGlass(pos + eps.xxx).x
                );
                
            }

            fixed4 fragGlass(fixed4 screenCol, fixed3 lightDir, fixed3 viewDir, fixed3 halfDir){
                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                rayMarchGlassSDF(worldCamPos, viewDir, hit, col, dst);
                float3 worldPos = worldCamPos + viewDir * dst;
                fixed3 normal = findGlassNormal(worldPos);
                fixed lighting = dot(lightDir, normal);
                

                fixed3 reflDir = reflect(viewDir, normal);
                //this gives a really long highlight, which looks amazing

                fixed highlight = dot(reflDir, normalize(lightDir + viewDir));
                highlight = saturate(highlight);
                highlight = pow(highlight, 192);
                //highlight = smoothstep(0.5, 0.7, highlight);



                fixed rimlight = saturate(dot(-viewDir, normal));
                
                rimlight = 1 - rimlight;
                rimlight = pow(rimlight, 3);

                fixed fresnel = pow(rimlight, 4);

                fixed lerpFactor = rimlight;

                rimlight = sin(rimlight * 4.5);
                rimlight = saturate(rimlight);
                rimlight = pow(rimlight, 4);

            
            

                

                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0);
                //return rgbm;

                fixed3 innerColor = lerp(screenCol * 0.8, rgbm.rgb, rimlight);
                innerColor = lerp(innerColor, 4.0f, highlight + fresnel);
                innerColor -= fresnel * 3.8;
                innerColor += pow(saturate(rimlight), 2) * 0.1;
                //innerColor += highlight + fresnel;

                
                //return float4(innerColor, 1.0f);


                fixed lerpAmount = rimlight * hit;

                rimlight = saturate(rimlight + highlight);



                fixed3 outCol = innerColor * hit + (1.0f - hit) * screenCol.rgb;
                return float4(outCol, 1.0f);
            }

            fixed4 fragInner(float2 screenUV, fixed4 screenCol, fixed3 lightDir, fixed3 viewDir, fixed3 halfDir){

                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                rayMarchInnerSDF(worldCamPos, viewDir, hit, col, dst);
                float3 worldPos = worldCamPos + viewDir * dst;
                fixed3 normal = findInnerNormal(worldPos);
                fixed3 fakeNormal = normalize(worldPos * 0.2 + normal * 0.8);
                //normal = (normal + 1) * 0.5f;

                
                fixed3 tangent = normalize(cross(fixed3(0, 1, 0), fakeNormal));
                fixed3 bitangent = normalize(cross(fakeNormal, tangent));
                float3 texSum = 0.0f;

                float stepDistance = 0.0f;
                float2 baseUV;

                //baseUV = float2(theta + _Time.r, phi + _Time.r);
                float weight = 0.5f;

                fixed lighting = dot(normal, lightDir);
                lighting = (lighting + 1.0f) * 0.5;
                lighting = lighting * 0.4 + 0.6;
                float3 head = worldPos;
                for(uint i = 1; i < 16; i++){
                    head += viewDir * 0.08;
                    fixed3 newNormal = normalize(head + normal * 0.5);
                    float theta = (atan2(head.x, head.z) + UNITY_PI) / UNITY_TWO_PI;
                    float phi = (newNormal.y + 1) * 0.5;
                    baseUV = float2(theta + _Time.r * 4 + i * 0.003 - (1 - phi) * 0.6, (phi - _Time.g * 0.2) * 0.25);
                    fixed3 tex = tex2D(_Galaxy, baseUV);

                    texSum += tex * weight; 
                    weight *= 0.5f;
                }
                texSum *= lighting;

                fixed highlight = saturate(dot(normal, halfDir));
                highlight = pow(highlight, 32);

                float3 plainTex = tex2D(_Stars, screenUV);
                float3 compositeCol = texSum + highlight * texSum * 0.9;

                //texSum = tex2D(_Galaxy, baseUV);
                float3 outCol = max(compositeCol, 0) * hit + (1.0f - hit) * screenCol.rgb;
                return float4(outCol, 1.0f);



            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 screenCol = tex2D(_MainTex, i.uv);

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 halfDir = normalize(lightDir - viewDir);

                fixed4 innerColor = fragInner(i.uv, screenCol, lightDir, viewDir, halfDir);
                fixed4 glassColor = fragGlass(innerColor, lightDir, viewDir, halfDir);
                return glassColor;

            }
            ENDCG
        }
    }
}
