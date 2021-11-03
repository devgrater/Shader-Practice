Shader "Unlit/TextureCube"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
        _RoomOffset ("RoomOffset", Vector) = (0, 0, 0)
        [IntRange]_RoomCountH ("Room Count Horizontal", Range(1, 16)) = 1
        [IntRange]_RoomCountV ("Room Count Horizontal", Range(1, 16)) = 1
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 objectSpaceVertex : TEXCOORD4;
            };

            sampler2D _MainTex;
            samplerCUBE _CubeMap;
            float4 _MainTex_ST;
            float3 Nx = float3(1, 0, 0);
            float3 Ny = float3(0, 1, 0);
            float3 Nz = float3(0, 0, 1);
            float _RoomCountH;
            float _RoomCountV;
            float3 _RoomOffset;

            float first_hit(float3 rayOrigin, float3 rayDirection, float3 hitPos, out float3 roomCenter){

                //test for ceilings:
                float horizontalPlanePos;
                float roomHeight = 1 / _RoomCountV;
                float roomWidth = 1 / _RoomCountH;
                hitPos *= 0.99;
                hitPos += 0.005;
                if(rayDirection.y < 0){
                    //is looking at the floor.
                    horizontalPlanePos = 1 - (ceil(hitPos.y * _RoomCountV)) * roomHeight - 0.5;
                    roomCenter.y = horizontalPlanePos + roomHeight * 0.5;
                }
                else{
                    //is looking at the ceiling
                    horizontalPlanePos = 1 - (ceil(hitPos.y * _RoomCountV) - 1) * roomHeight - 0.5;
                    roomCenter.y = horizontalPlanePos - roomHeight * 0.5;
                }

                float xPlanePos;
                if(rayDirection.x < 0){
                    xPlanePos = 1 - (ceil(hitPos.x * _RoomCountH)) * roomWidth - 0.5;
                    roomCenter.x = xPlanePos + roomWidth * 0.5;
                }
                else{
                    xPlanePos = 1 - (ceil(hitPos.x * _RoomCountH) - 1) * roomWidth - 0.5;
                    roomCenter.x = xPlanePos - roomWidth * 0.5;
                }

                float zPlanePos;
                if(rayDirection.z < 0){
                    zPlanePos = 1 - (ceil(hitPos.z * _RoomCountH)) * roomWidth - 0.5;
                    roomCenter.z = zPlanePos + roomWidth * 0.5;
                }
                else{
                    zPlanePos = 1 - (ceil(hitPos.z * _RoomCountH) - 1) * roomWidth - 0.5;
                    roomCenter.z = zPlanePos - roomWidth * 0.5;
                }


                float tx = ((xPlanePos + _RoomOffset.x) - rayOrigin.x) / rayDirection.x;
                float ty = ((horizontalPlanePos + _RoomOffset.y) - rayOrigin.y) / rayDirection.y;
                float tz = ((zPlanePos + _RoomOffset.z) - rayOrigin.z) / rayDirection.z;



                return min(min(tx, ty), tz); //find the first hit!
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                //compute the view direct:
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.objectSpaceVertex = v.vertex;
                return o;
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
                //avoid stepping into the negative 
                float3 roomCenter;
                float hit_t = first_hit(-objectSpaceCameraPos, normalize(objectSpaceViewDir), pixelPosition.xyz + 0.5, roomCenter);
                float3 objectPos = -objectSpaceCameraPos + objectSpaceViewDir * hit_t;
                float3 sampleDir = objectPos - roomCenter;

                float4 col = texCUBElod(_CubeMap, normalize(float4(-sampleDir, 1)))


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
