Shader "Unlit/TextureCube"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
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

            float first_hit(float3 rayOrigin, float3 rayDirection, float hit_x, float hit_y){

                //test for ceilings:
                float horizontalPlanePos;
                float floorHeight = 1 / _RoomCountV;
                if(rayDirection.y < 0){
                    //is looking at the floor.
                    horizontalPlanePos = 1 - (ceil(hit_y * _RoomCountV)) / _RoomCountV - 0.5;
                }
                else{
                    //is looking at the ceiling
                    horizontalPlanePos = 1 - (floor(hit_y * _RoomCountV)) / _RoomCountV - 0.5;
                }


                //test for collision on the x, y, z planes. 
                float tx = (sign(rayDirection.x) * 0.5f - rayOrigin.x) / rayDirection.x;
                float ty = (horizontalPlanePos - rayOrigin.y) / rayDirection.y;
                float tz = (sign(rayDirection.z) * 0.5f - rayOrigin.z) / rayDirection.z;

                if(ty < 0){ ty = 3.402823466e+38F; };

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
                float hit_t = first_hit(-objectSpaceCameraPos, normalize(objectSpaceViewDir), i.uv.x, pixelPosition.y + 0.5);
                float3 objectPos = -objectSpaceCameraPos + objectSpaceViewDir * hit_t;

                fixed4 col = texCUBElod(_CubeMap, normalize(float4(-objectPos, 0)));
                //but this is what happens when we are outside the cube.
                //what we want is to pretend that we are inside the cube, and texture it based on wj
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return hit_t / 5;
            }
            ENDCG
        }
    }
}
