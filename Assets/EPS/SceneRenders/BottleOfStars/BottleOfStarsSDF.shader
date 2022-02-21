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


            float sphereSDF(float3 checkPoint, float3 origin, float radius){
                return length(checkPoint - origin) - radius;
            }

            float boxSDF(float3 checkPoint, float3 center, float3 bounds){
                float3 sdVector = checkPoint - center;
                float3 diff = abs(sdVector) - bounds;
                return length(max(diff, 0.0f)) + min(max(diff.x, max(diff.y, diff.z)), 0.0f);
            }

            //equivalent of map() in iq's example
            float evalScene(float3 checkPoint){
                float minDist;
                float sphere1 = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), 1.0f);
                float sphere2 = sphereSDF(checkPoint, float3(1.0f, 0.0f, 0.0f), 1.5f);
                minDist = min(sphere1, sphere2);
                float sphere3 = sphereSDF(checkPoint, float3(0.5f, 1.0f, 1.0f), 2.0f);
                minDist = min(sphere3, minDist);
                float box1 = boxSDF(checkPoint, float3(1.5f, 1.5f, 1.5f), float3(1.0f, 2.0f, 1.0f));
                minDist = min(box1, minDist);
                float box2 = boxSDF(checkPoint, float3(4.0f, 2.0f, 5.0f), float3(1.5f, 1.0f, 2.0f));
                minDist = min(box2, minDist);

                return minDist;
            }

            void rayMarchSDF(float3 startPos, float3 viewDir, out float hit, out float3 col, out float dst){
                float minDist = 3.402823466e+38F;
                float dstTravelled = 0.0f;
                float3 headPos = startPos;
                hit = 0.0f;
                for(int i = 0; i < 70; i++){
                    //raymarch!
                    minDist = evalScene(headPos);
                    headPos += minDist * viewDir;
                    dstTravelled += minDist;
                    if(abs(minDist) <= 0.011f){
                        hit = 1.0f;
                        break;
                    }
                }
                dst = dstTravelled;
                col = float3(1, 1, 1);
                
            }

            
            //No idea what this is all about yet... thanks regardless iq
            fixed3 findNormal(float3 pos){
                
                fixed2 eps = fixed2(1.0, -1.0) * 0.5773 * 0.0005;
                return normalize(
                    eps.xyy * evalScene(pos + eps.xyy).x + 
                    eps.yyx * evalScene(pos + eps.yyx).x + 
                    eps.yxy * evalScene(pos + eps.yxy).x + 
                    eps.xxx * evalScene(pos + eps.xxx).x
                );
                
            }



            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 screenCol = tex2D(_MainTex, i.uv);

                fixed3 viewDir = normalize(i.viewDir);
                float3 worldCamPos = _WorldSpaceCameraPos;
                float dst, hit;
                float3 col;
                rayMarchSDF(worldCamPos, viewDir, hit, col, dst);

                float3 worldPos = worldCamPos + viewDir * dst;
                float4 pos = float4(worldPos, 1.0f);

                fixed3 normal = findNormal(worldPos);
                //fixed3 normal = fixed3(1.0, 1.0, 1.0f);
                fixed4 outNormal = fixed4(normal, 1.0f);

                hit = saturate(hit);

                //return float4(worldPos, 1.0f);
                //return lerp(screenCol, 0.0f, hit);
                return max(outNormal, 0.0f) * hit + screenCol * (1 - hit);
                return screenCol * (1 - hit);
                return lerp(float4(worldPos, 1.0) * hit, screenCol, hit);




                /*


                fixed dst = sphereSDF(worldCamPos, float3(0.0f, 0.0f, 0.0f), 10.0f);
                //fixed4 outcol = fixed4(1 / max(dst, 0.1f), 1 / max(-dst, 0.1f), 0.0f, 1.0f);
                //return outcol;
                
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;*/
            }
            ENDCG
        }
    }
}
