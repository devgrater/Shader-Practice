Shader "Hidden/SDFWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Galaxy ("Galaxy", 2D) = "black" {}
        _Stars ("StarMap", 2D) = "white" {}
        _Offset ("Offset", Float) = 0.2
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
            float4 _Galaxy_TexelSize;
            sampler2D _Stars;
            float _Offset;

            float random( float2 p ) {
                float h = dot(p, float2(127.1,311.7));	
                return frac(sin(h)*43758.5453123);
            }

            float noise( in float2 p ) {
                float2 i = floor(p);
                float2 f = frac(p);	
                float2 u = f * f * (3.0f - 2.0f * f);

                //bilinear filtering the noise
                return -1.0f + 2.0f * 
                    lerp(
                        lerp(random(i + float2(0.0f, 0.0f)), random(i + float2(1.0f, 0.0f)), u.x),
                        lerp(random(i + float2(0.0f, 1.0f)), random(i + float2(1.0f, 1.0f)), u.x)
                    , u.y);
            }


            float waveDisplace(float3 sdfPoint, float choppy){
                //float dfc = length(sdfPoint.xz);
                float2 dsp = abs(float2(sin(sdfPoint.x), sin(sdfPoint.z)));
                float2 dsp2 = 1 - abs(float2(cos(sdfPoint.x), cos(sdfPoint.z)));;
                float2 hybrid = lerp(dsp, dsp2, dsp);
                //return hybrid.x + hybrid.y;
                return 1 - pow(1.0f - pow(hybrid.x * hybrid.y, 0.65f), choppy);//hybrid.x + hybrid.y;//abs(sin(4 * (dfc - _Time.g * 1.5))) * 0.2f;// + (sin(2 * (sdfPoint.x + _Time.b * 1))) * 0.1;
                
                //return (sin(2 * (sdfPoint.x + _Time.g * 3))) * 0.2;
            }

            float evalInner(float3 checkPoint){
                float minDist;

                float3 dst = float3(0.0f, 1.0f, 0.0f) - checkPoint;

                minDist = sphereSDF(checkPoint, float3(0.0f, 0.0f, 0.0f), -2.8f);
                float3 ddt = checkPoint;
                float offset = noise(checkPoint.xz * _Offset);
                //float subOffset = noise(checkPoint.xz *  _Offset * 2 + _Time.b);
                //ddt.xz += offset * 2 + subOffset;
                ddt.xz += offset * 3;
                float disp = 0;
                float weight = 0.15f;
                float scale = 0.1f;
                float cosx = 1.6;
                float sinx = 1.2;
                float choppy = 4.0f;
                for(int i = 0; i < 3; i++){
                    disp += waveDisplace((ddt + _Time.g) * scale, choppy) * weight;
                    //disp += waveDisplace((ddt - _Time.g) * scale) * weight;
                    weight *= 0.5f;
                    scale *= 1.9f;
                    ddt.x = ddt.x * cosx - ddt.z * sinx;
                    ddt.z = ddt.x * sinx + ddt.z * cosx;
                    choppy = lerp(choppy, 1.0f, 0.2f);
                    
                }
                float plane = planeSDFDft(dst, -1.0f) + disp * 4;

                return plane;//sdfSmoothSubtract(plane, minDist, 0.3f);
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
                    eps.xyy * evalInner(pos + eps.xyy) + 
                    eps.yyx * evalInner(pos + eps.yyx) + 
                    eps.yxy * evalInner(pos + eps.yxy) + 
                    eps.xxx * evalInner(pos + eps.xxx)
                );
                
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
                for(uint i = 1; i < 8; i++){
                    head += viewDir;
                    fixed3 newNormal = normalize(head);
                    float theta = (atan2(head.x, head.z) + 3.1415926535f) / 6.283185307;
                    float phi = (newNormal.y + 1) * 0.5;
                    baseUV = float2(theta + _Time.r * 4 - (1 - phi) * 0.6, (2 * phi - _Time.g * 0.2) * 0.25);
                    //fixed3 tex = tex2D(_Galaxy, baseUV, _Galaxy_TexelSize.x, _Galaxy_TexelSize.y);
                    fixed3 tex = fixed3(0.1, 0.7, 0.6);

                    texSum += tex * weight; 
                    weight *= 0.5f;
                }
                texSum *= lighting;

                fixed highlight = saturate(dot(normal, halfDir));
                highlight = pow(highlight, 512);

                //float3 plainTex = tex2D(_Stars, screenUV);
                float3 compositeCol = texSum + highlight * texSum * 2.9;

                fixed fresnel = saturate(dot(normal, -viewDir));
                fresnel = 1 - fresnel;
                fresnel = pow(fresnel, 2) * hit;
                compositeCol += lerp(fixed3(0.0, 0.6, 1.0), fixed3(0.0, 0.9, 1.0), fresnel * fresnel) * fresnel;

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
                return innerColor;

            }
            ENDCG
        }
    }
}
