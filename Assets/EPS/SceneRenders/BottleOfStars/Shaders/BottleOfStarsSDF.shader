Shader "Hidden/BottleOfStars"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Galaxy ("Galaxy", 2D) = "black" {}
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
            #pragma enable_d3d11_debug_symbols

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
            float4 _Galaxy_TexelSize;

            ////////////////////////////////////
            //          GLASS BOTTLE          //
            ////////////////////////////////////
            float evalGlassBottle(float3 checkPoint){
                //a bottle is just the union
                //of a sphere, a cylinder and a torus.
                float minDist;
                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 3.0f);
                float tube = cylinderSDF(checkPoint, float3(0.0f, 2.8f, 0.0f), 2.4f, 0.8f);
                minDist = sdfSmoothUnion(minDist, tube, 0.6f);

                float torus = torusSDF(checkPoint, float3(0.0f, 5.2f, 0.0f), 0.8f, 0.3f);
                minDist = sdfSmoothUnion(minDist, torus, 0.2f);
                return minDist;
            }

            void rayMarchGlassSDF(float3 startPos, float3 viewDir, out float hit, out float dst){
                float minDist = 0.0f;
                float dstTravelled = 0.0f;
                float3 headPos = startPos;
                hit = 0.0f;

                for(uint i = 0; i < 70; i++){
                    //raymarch until hits...
                    minDist = evalGlassBottle(headPos);
                    headPos += minDist * viewDir;
                    dstTravelled += minDist;
                    if(abs(minDist) <= 0.005f){
                        hit = 1.0f;
                        break;
                    }
                }
                dst = dstTravelled;
            }

            //credits to inigo quilez 
            fixed3 findGlassNormal(float3 pos){
                fixed2 eps = fixed2(1.0f, -1.0f) * 0.5773f * 0.0005f;
                return normalize(
                    eps.xyy * evalGlassBottle(pos + eps.xyy) + 
                    eps.yyx * evalGlassBottle(pos + eps.yyx) + 
                    eps.yxy * evalGlassBottle(pos + eps.yxy) + 
                    eps.xxx * evalGlassBottle(pos + eps.xxx)
                );
                
            }

            fixed4 fragGlass(fixed4 screenCol, fixed3 lightDir, fixed3 viewDir, fixed3 halfDir){
                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                rayMarchGlassSDF(worldCamPos, viewDir, hit, col, dst);
                //reconstruct world position of the bottle
                float3 worldPos = worldCamPos + viewDir * dst;
                fixed3 normal = findGlassNormal(worldPos);

                //use a weird way to calculate highlight
                //it gives this long beam of highlight which looks cool
                fixed3 reflDir = reflect(viewDir, normal);
            
                fixed highlight = dot(reflDir, normalize(lightDir + viewDir));
                highlight = saturate(highlight);
                highlight = pow(highlight, 512);


                fixed fresnel = saturate(dot(-viewDir, normal));
                fresnel = 1 - fresnel;
                fresnel = pow(fresnel, 3);

                //simulate glass thickness
                fixed internalThickness = sin(fresnel * 4.5);
                internalThickness = saturate(internalThickness);
                internalThickness = pow(internalThickness, 4);

                //environmental lighting
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0);

                //dim the color of the bottle, due to internal thickness.
                fixed3 compositeColor = lerp(screenCol * 0.8f, rgbm.rgb, internalThickness);

                fixed3 outCol = compositeColor * hit + (1.0f - hit) * screenCol.rgb;
                return float4(outCol, 1.0f);
            }


            ////////////////////////////////////
            //         FLUID IN BOTTLE        //
            ////////////////////////////////////
            float waveDisplace(float3 sdfPoint){
                return sin(2.0f * (sdfPoint.x + _Time.b)) * 0.1f;
            }

            float evalFluid(float3 checkPoint){
                float3 planeVector = checkPoint - float3(0.0f, 1.0f, 0.0f);
                //rotate the plane so that the result looks rotated
                float3 cosx = cos(-UNITY_PI / 6);
                float3 sinx = sin(-UNITY_PI / 6);
                planeVector.x = cosx * planeVector.x - sinx * planeVector.y;
                planeVector.y = sinx * planeVector.x + cosx * planeVector.y;

                //union of a sphere and a tilted wave plane
                float sphereDst = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 2.8f);
                float planeDst = planeSDFDft(planeVector, -1.0f) + waveDisplace(checkPoint);

                return sdfSmoothSubtract(planeDst, sphereDst, 0.3f);
            }

            void rayMarchFluidSDF(float3 startPos, float3 viewDir, out float hit, out float dst){
                float minDist = 0.0f;
                float dstTravelled = 0.0f;
                float3 headPos = startPos;
                hit = 0.0f;
                for(uint i = 0; i < 70; i++){
                    //raymarch!
                    minDist = evalFluid(headPos);
                    headPos += minDist * viewDir;
                    dstTravelled += minDist;
                    if(abs(minDist) <= 0.005f){
                        hit = 1.0f;
                        break;
                    }
                }
                dst = dstTravelled;
            }

            fixed3 findInnerNormal(float3 pos){
                fixed2 eps = fixed2(1.0f, -1.0f) * 0.5773f * 0.0005f;
                return normalize(
                    eps.xyy * evalFluid(pos + eps.xyy) + 
                    eps.yyx * evalFluid(pos + eps.yyx) + 
                    eps.yxy * evalFluid(pos + eps.yxy) + 
                    eps.xxx * evalFluid(pos + eps.xxx)
                );
            }

            fixed4 fragInner(float2 screenUV, fixed4 screenCol, fixed3 lightDir, fixed3 viewDir, fixed3 halfDir){

                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                rayMarchFluidSDF(worldCamPos, viewDir, hit, dst);
                float3 worldPos = worldCamPos + viewDir * dst;
                fixed3 normal = findInnerNormal(worldPos);
                //normal computed using surface point coordinates
                //because the center sits in (0,0,0)
                fixed3 fakeNormal = normalize(worldPos * 0.2 + normal * 0.8);
                
                fixed3 tangent = normalize(cross(fixed3(0, 1, 0), fakeNormal));
                fixed3 bitangent = normalize(cross(fakeNormal, tangent));
                float3 texSum = 0.0f;

                float stepDistance = 0.0f;
                
                float weight = 0.5f;

                fixed lighting = dot(normal, lightDir);
                lighting = (lighting + 1.0f) * 0.5f;
                lighting = lighting * 0.4f + 0.6f;
                float3 head = worldPos;
                float2 baseUV;

                //pseudo parallax effect
                for(uint i = 0; i < 8; i++){
                    head += viewDir;
                    fixed3 newNormal = normalize(head);
                    float theta = (atan2(head.x, head.z) + UNITY_PI) / UNITY_TWO_PI;
                    float phi = (newNormal.y + 1.0f) * 0.5;
                    //map from 3d to 2d
                    //and distort using phi
                    baseUV = float2(
                        theta + _Time.r * 4.0f - (1.0f - phi) * 0.6f,
                        (2.0f * phi - _Time.g * 0.2f) * 0.25f
                    );
                    fixed3 tex = tex2D(_Galaxy, baseUV, _Galaxy_TexelSize.x, _Galaxy_TexelSize.y);
                    texSum += tex * weight; 
                    weight *= 0.5f;
                }
                texSum *= lighting;

                fixed highlight = saturate(dot(normal, halfDir));
                highlight = pow(highlight, 32);

                float3 compositeCol = texSum + highlight * texSum * 0.9f;

                fixed fresnel = saturate(dot(normal, -viewDir));
                fresnel = 1.0f - fresnel;
                fresnel = pow(fresnel, 2.0f) * hit;

                //brighten up the edge of the fluid
                compositeCol += lerp(0.0f, fixed3(0.0f, 0.9f, 1.0f), fresnel * fresnel);

                float3 outCol = max(compositeCol, 0.0f) * hit + (1.0f - hit) * screenCol.rgb;
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
