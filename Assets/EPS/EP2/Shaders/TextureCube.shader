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

                float x_diff = 0.5f;
                float sinx = abs(dot(normalize(i.viewDir), float3(1, 0, 0)));
                float dist = x_diff / sinx;

                float3 actual_position = i.viewDir * 4.5 / 3.5 - _WorldSpaceCameraPos;

                fixed3 objectCenterVector = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)) - _WorldSpaceCameraPos;
                fixed3 theoreticalVector = i.viewDir - objectCenterVector;

                fixed4 col = texCUBElod(_CubeMap, normalize(float4(actual_position, 0)));
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
