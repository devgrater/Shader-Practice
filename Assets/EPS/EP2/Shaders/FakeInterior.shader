Shader "Grater/FakeInterior"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
        _RoomOffset ("RoomOffset", Float) = 0
        _AOIntensity ("AO Intensity", Range(0, 1)) = 0.5
        _AOPower ("AO Power", Range(1, 16)) = 4
        [IntRange]_RoomCountH ("Room Count Horizontal", Range(1, 16)) = 1
        [IntRange]_RoomCountV ("Room Count Horizontal", Range(1, 16)) = 1
    }
    SubShader
    {
        Tags {
             "RenderType"="Opaque" 
             "LightMode"="ForwardBase"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityImageBasedLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                //float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD2;
                //float4 screenPos : TEXCOORD3;
                float4 objectSpaceVertex : TEXCOORD3;
            };

            sampler2D _MainTex;
            samplerCUBE _CubeMap;
            float4 _MainTex_ST;
            float3 Nx = float3(1, 0, 0);
            float3 Ny = float3(0, 1, 0);
            float3 Nz = float3(0, 0, 1);
            float _RoomCountH;
            float _RoomCountV;
            float _RoomOffset;
            float _AOIntensity;
            float _AOPower;

            static const float3 random_vector = float3(1.334f, 2.241f, 3.919f);
            static const float random_amount = 3838438.66411;
            inline float random_from_pos(float3 pos){
                return frac(dot(pos, random_vector) * 383.8438);
            }

            float first_hit(float3 rayOrigin, float3 rayDirection, float3 hitPos, out float3 surfaceNormal, out fixed2 uv){
                
                float3 roomCenter;
                //////////////////////// WHICH SIDE OF THE PLANE WE NEED TO HIT //////////////////////////
                float roomHeight = 1 / _RoomCountV;
                float roomWidth = 1 / _RoomCountH;
                hitPos *= 0.999;
                hitPos += 0.0005;

                float yDirection = sign(rayDirection.y);
                float offset = max(yDirection, 0.0); //no negative directions
                float yPlanePos = 1 - (floor(hitPos.y * _RoomCountV + offset) - yDirection) * roomHeight - 0.5;
                roomCenter.y = yPlanePos - yDirection * roomHeight * 0.5;

                float xDirection = sign(rayDirection.x);
                offset = max(xDirection, 0.0);
                float xPlanePos = 1 - (floor(hitPos.x * _RoomCountH + offset) - xDirection) * roomWidth - 0.5;
                roomCenter.x = xPlanePos - xDirection * roomWidth * 0.5;

                float zDirection = sign(rayDirection.z);
                offset = max(zDirection, 0.0);
                float zPlanePos = 1 - (floor(hitPos.z * _RoomCountH + offset) - zDirection) * roomWidth - 0.5;
                roomCenter.z = zPlanePos - zDirection * roomWidth * 0.5;

                //////////////////////// HOW LONG DOES IT TAKE TO HIT THIS PLANE? ////////////////////////
                fixed3 zNormal = fixed3(0, 0, zDirection);
                fixed3 xNormal = fixed3(xDirection, 0, 0);
                fixed3 yNormal = fixed3(0, yDirection, 0);

                float tx = ((xPlanePos) - rayOrigin.x) / rayDirection.x;
                float ty = ((yPlanePos) - rayOrigin.y) / rayDirection.y;
                float tz = ((zPlanePos) - rayOrigin.z) / rayDirection.z;

                ////////////////////// EXTRACT SURFACE NORMAL DIRECTION ////////////////////////////
                float3 roomSpacePos = min(tz, min(ty, tx)) * rayDirection + rayOrigin - roomCenter;

                float min_t = tz;
                uv = -roomSpacePos.xy * fixed2(_RoomCountH, _RoomCountV);
                
                //fixed2 worldUV = fixed2();
                surfaceNormal = zNormal;
                if(tx < min_t){
                    min_t = tx;
                    surfaceNormal = xNormal;
                    uv = -roomSpacePos.zy * fixed2(_RoomCountH, _RoomCountV);
                }
                if(ty < min_t){
                    min_t = ty;
                    surfaceNormal = yNormal;
                    uv = roomSpacePos.xz * _RoomCountH;
                }
                uv = saturate(frac(uv - 0.5));
                

                ////////////////////// FIRST HIT /////////////////////////////////////
                return min_t; //find the first hit!
            }

            float half_lambert_atten(float attenuation){
                attenuation = saturate((attenuation + 1) / 2);
                return attenuation * attenuation;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                //compute the view direct:
                o.viewDir = WorldSpaceViewDir(v.vertex);
                //o.screenPos = ComputeScreenPos(o.vertex);
                o.objectSpaceVertex = v.vertex;
                return o;
            }

            fixed ambient_occlusion(float2 uv){
                fixed ao = saturate(1 - pow(uv.x * 2.0 - 1.0, 4));
                ao *= saturate(1 - pow(uv.y * 2.0 - 1.0, 8));
                ao = 1 - ((1 - ao) * _AOIntensity);
                //return half_lambert_atten(ao);
                //float4 col = texCUBElod(_CubeMap, normalize(float4(-sampleDir, 1)));
                return ao;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //1. translate stuff to object space.
                //but don't do it yet
                //lets test our  theory in world space.

                //float x_diff = 0.5f;
                //float sinx = abs(dot(normalize(i.viewDir), float3(1, 0, 0)));
                //float dist = x_diff / sinx;

                //this is accurate for this case specifically.
                //now, lets project things back to the object space:    

                //float3 rayDir = normalize(i.viewDir / i.screenPos.w);
                float3 pixelPosition = i.objectSpaceVertex;
                float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 objectSpaceViewDir = normalize(mul(unity_WorldToObject, float4(i.viewDir, 0)));

                ///////////////////////// ACTUAL TRACING /////////////////////////////
                //avoid stepping into the negative 
                float3 surfaceNormal;
                fixed2 uv;
                float hit_t = first_hit(-objectSpaceCameraPos, normalize(objectSpaceViewDir), pixelPosition.xyz + 0.5, surfaceNormal, uv);
                //float3 objectPos = -objectSpaceCameraPos + objectSpaceViewDir * hit_t;
                //float3 sampleDir = normalize(objectPos - roomCenter);

                //////////////////////// SAMPLING TEXTURES /////////////////////////////
                float4 col = tex2D(_MainTex, uv);
                fixed atten = dot(normalize(surfaceNormal), normalize(_WorldSpaceLightPos0.xyz));
                atten = half_lambert_atten(atten);
                fixed3 environmentLight = ShadeSH9(float4(surfaceNormal, 1));
                fixed3 worldLighting = atten * _LightColor0.rgb + environmentLight * 0.5;

                //////////////////////// FAKE AMBIENT OCCLUSION ///////////////////////////
                fixed ao = ambient_occlusion(uv);
                col.rgb *= worldLighting * ao;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
