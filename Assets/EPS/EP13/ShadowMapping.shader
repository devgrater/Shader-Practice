Shader "Unlit/ShadowMapping"
{
    Properties
    {
        _MainTex ("ShadowMap", 2D) = "white" {}
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
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _cst_LightDir;
            float4x4 _cst_WorldToCamera;

            v2f vert (appdata v)
            {
                //construct world space coordinates:
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); //now we are in world pos...
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //using the world coordinates, convert to camera space...
                float4 cameraSpaceCoords = mul(_cst_WorldToCamera, i.worldPos);
                cameraSpaceCoords /= cameraSpaceCoords.w;
                //using these...
                //float z = cameraSpaceCoords.xy / cameraSpaceCoords.z;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(cameraSpaceCoords.zzz, 1);
            }
            ENDCG
        }
    }
}
