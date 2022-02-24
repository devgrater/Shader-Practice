Shader "Unlit/Flocker"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #pragma target 4.5
            #pragma multi_compile_instancing 
            #pragma instancing_options procedural:ConfigureProcedural

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
            };

            struct BoidData{
                float3 position;
                float3 velocity;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            StructuredBuffer<BoidData> _Boids;

            void ConfigureProcedural(){
                #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                    float3 position = _Boids[unity_InstanceID].position;
                    unity_ObjectToWorld = 0.0;
                    unity_ObjectToWorld._m03_m13_m23_m33 = float4(position, 1.0f);
                    unity_ObjectToWorld._m00_m11_m22 = 0.1f;
			    #endif
            }

            v2f vert (appdata v)
            {
                v2f o;
               // unity_ObjectToWorld._m00_m11_m22 = 0.1f;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.vertex = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
