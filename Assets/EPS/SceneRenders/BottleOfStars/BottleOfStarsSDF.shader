Shader "Hidden/BottleOfStars"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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




            


            //equivalent of map() in iq's example
            float evalGlass(float3 checkPoint){
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 3.0f);
                float tube = cylinderSDF(checkPoint, float3(0.0f, 2.8f, 0.0f), 2.4f, 0.8f);
                minDist = sdfSmoothUnion(minDist, tube, 0.6f);

                float torus = torusSDF(checkPoint, float3(0.0f, 5.2f, 0.0f), 0.8f, 0.3f);
                minDist = sdfSmoothUnion(minDist, torus, 0.2f);
                //return torus;
                /*
                float sphere1 = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 1.0f);
                float sphere2 = sphereSDF(checkPoint, float3(1.0f, 0.0f, 0.0f), 1.5f);
                minDist = sdfSmoothUnion(sphere1, sphere2, 0.2f);
                float sphere3 = sphereSDF(checkPoint, float3(0.5f, 1.0f, 1.0f), 2.0f);
                minDist = sdfSmoothUnion(sphere3, minDist, 0.2f);
                float box1 = boxSDF(checkPoint, float3(1.5f + sin(_Time.g), 1.5f, 1.5f), float3(1.0f, 2.0f, 1.0f));
                minDist = sdfSmoothSubtract(minDist, box1, 0.2f);
                float box2 = boxSDF(checkPoint, float3(4.0f, 2.0f, 5.0f), float3(1.5f, 1.0f, 2.0f));
                minDist = min(box2, minDist);*/

                return minDist;
            }

            float waveDisplace(float3 sdfPoint){
                
                return (sin(5 * (sdfPoint.z + _Time.g))) * 0.05;
            }

            float evalInner(float3 checkPoint){
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 2.8f);

                float3 ddt = checkPoint - float3(1.5f + sin(_Time.g), 1.5f, 1.5f);
                float box = boxSDF(checkPoint, float3(1.5f + sin(_Time.g), 1.5f, 1.5f), float3(1.0f, 1.0f, 1.0f));
                float plane = planeSDF(checkPoint, 1.0f, -1.0f) + waveDisplace(ddt);
                return sdfSubtract(plane, minDist);



                return box + waveDisplace(ddt);


                //return sdfSubtract(sphere);


                //float tube = cylinderSDF(checkPoint, float3(0.0f, 2.8f, 0.0f), 2.4f, 0.8f);
                //minDist = sdfSmoothUnion(minDist, tube, 0.6f);

                //float torus = torusSDF(checkPoint, float3(0.0f, 5.2f, 0.0f), 0.8f, 0.3f);
                //minDist = sdfSmoothUnion(minDist, torus, 0.2f);

                return box;
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
                fixed highlight = dot(halfDir, normal);
                highlight = saturate(highlight);
                highlight = pow(highlight, 512);

                fixed rimlight = saturate(dot(-viewDir, normal));
                
                rimlight = 1 - rimlight;
                rimlight = pow(rimlight, 3);

                fixed lerpFactor = rimlight;

                rimlight = sin(rimlight * 6.28);
                rimlight = saturate(rimlight);
                rimlight = pow(rimlight, 4);


                fixed3 innerColor = lerp(screenCol * 0.8, 1.0f, rimlight);

                
                //return float4(innerColor, 1.0f);


                fixed lerpAmount = rimlight * hit;

                rimlight = saturate(rimlight + highlight);



                fixed3 outCol = innerColor * hit + (1.0f - hit) * screenCol.rgb;
                return float4(outCol, 1.0f);
            }

            fixed4 fragInner(fixed4 screenCol, fixed3 lightDir, fixed3 viewDir, fixed3 halfDir){

                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                rayMarchInnerSDF(worldCamPos, viewDir, hit, col, dst);
                float3 worldPos = worldCamPos + viewDir * dst;
                fixed3 normal = findInnerNormal(worldPos);
                normal = (normal + 1) * 0.5f;

                float3 outCol = saturate(normal) * hit + (1.0f - hit) * screenCol.rgb;

                return float4(outCol, 1.0f);



            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 screenCol = tex2D(_MainTex, i.uv);

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 halfDir = normalize(lightDir - viewDir);

                fixed4 innerColor = fragInner(screenCol, lightDir, viewDir, halfDir);
                fixed4 glassColor = fragGlass(innerColor, lightDir, viewDir, halfDir);
                return glassColor;

                /*
                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                //rayMarchGlassSDF(worldCamPos, viewDir, hit, col, dst);
                rayMarchInnerSDF(worldCamPos, viewDir, hit, col, dst);

                float3 worldPos = worldCamPos + viewDir * dst;
                float4 pos = float4(worldPos, 1.0f);

                fixed3 normal = findInnerNormal(worldPos);
                fixed lighting = dot(lightDir, normal);
                fixed highlight = dot(halfDir, normal);
                highlight = saturate(highlight);
                highlight = pow(highlight, 512);
                //highlight /= cos(highlight);

                fixed rimlight = saturate(dot(-viewDir, normal));
                rimlight = 1 - rimlight;
                rimlight = pow(rimlight, 4);

                fixed inLight = saturate(dot(halfDir, -normal));
                fixed innerDim = inLight * 0.2;
                inLight = pow(inLight, 64);
                //return inLight;
                
                

                //return hit;
                //return (lighting + highlight) * hit;
                normal = (normal + 1.0f) * 0.5f;
                fixed3 tangent = cross(normal, fixed3(0, 1, 0));
                //return float4((tangent + 1) * 0.5, 1.0f);
                fixed3 bitangent = cross(normal, tangent);

                //fixed3 normal = fixed3(1.0, 1.0, 1.0f);
                fixed4 outNormal = fixed4(normal, 1.0f);

                //fixed innerNormal = 
                

                hit = saturate(hit);
                //return horizontalRim * verticalRim;
                //this is just the hull
                //return (highlight + rimlight) * hit;

                fixed glossyParts =  (highlight + rimlight + innerDim) * hit;

                return outNormal;
                //return float4(worldPos, 1.0f);
                //return lerp(screenCol, 0.0f, hit);
                return glossyParts + screenCol * (1 - glossyParts);
                return screenCol * (1 - hit);
                return lerp(float4(worldPos, 1.0) * hit, screenCol, hit);
                */

            }
            ENDCG
        }
    }
}
