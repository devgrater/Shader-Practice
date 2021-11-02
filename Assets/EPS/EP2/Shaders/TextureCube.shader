Shader "Unlit/TextureCube"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
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
            };

            sampler2D _MainTex;
            samplerCUBE _CubeMap;
            float4 _MainTex_ST;
            float3 Nx = float3(1, 0, 0);
            float3 Ny = float3(0, 1, 0);
            float3 Nz = float3(0, 0, 1);


            float first_hit(float3 rayOrigin, float3 rayDirection){
                //test for collision on the x, y, z planes.
                float tx = (sign(rayDirection.x) * 0.5 - rayOrigin.x) / rayDirection.x;
                float ty = (sign(rayDirection.y) * 0.5 - rayOrigin.y) / rayDirection.y;
                float tz = (sign(rayDirection.z) * 0.5 - rayOrigin.z) / rayDirection.z;

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
                float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 objectSpaceViewDir = normalize(mul(unity_WorldToObject, float4(i.viewDir, 0)));
                float hit_t = first_hit(-objectSpaceCameraPos, objectSpaceViewDir);
                float3 objectPos = -objectSpaceCameraPos + objectSpaceViewDir * hit_t;
                

                /*
                float3 objectSpaceCenter = mul(unity_WorldToObject, float4(0, 0, 0, 1));
                float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 objectSpaceViewDir = mul(unity_WorldToObject, float4(i.viewDir, 0));

                float abs_z = abs(objectSpaceCameraPos.z);
                float abs_x = abs(objectSpaceCameraPos.x);
                float abs_y = abs(objectSpaceCameraPos.y);
                float abs_max = max(abs_z, abs_x);
                float abs_min = min(abs_z, abs_x);
                float3 actual_position = -objectSpaceCameraPos + float3(
                    objectSpaceViewDir.x * (abs_x + 0.5f) / (abs_x - 0.5f),
                    objectSpaceViewDir.y * (abs_y + 0.5f) / (abs_y - 0.5f),
                    objectSpaceViewDir.z * (abs_z + 0.5f) / (abs_z - 0.5f)
                );
            

                //float3 actual_position = (objectSpaceViewDir) * (abs_max + 0.5f) / (abs_max - 0.5f) - objectSpaceCameraPos;

                fixed3 objectCenterVector = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)) - _WorldSpaceCameraPos;
                fixed3 theoreticalVector = i.viewDir - objectCenterVector;*/

                fixed4 col = texCUBElod(_CubeMap, normalize(float4(-objectPos, 0)));
                //but this is what happens when we are outside the cube.
                //what we want is to pretend that we are inside the cube, and texture it based on wj
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
