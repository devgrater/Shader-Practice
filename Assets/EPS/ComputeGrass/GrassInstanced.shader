Shader "Unlit/GrassInstanced"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DeepColor ("Deep Color", Color) = (0.0, 0.5, 0.1, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.6, 0.8, 0.1, 1.0)
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
            //#pragma multi_compile_instancing
            #pragma instancing_options procedural:setup
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

            #if SHADER_TARGET >= 45
                StructuredBuffer<float3> positionBuffer;
            #endif

           

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ShallowColor;
            fixed4 _DeepColor;


            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                #if SHADER_TARGET >= 45
                float3 data = positionBuffer[instanceID];

                    //float rotation = data.w * data.w * _Time.y * 0.5f;
                   // rotate2D(data.xz, rotation);

                    unity_ObjectToWorld._11_21_31_41 = float4(4, 0, 0, 0);
                    unity_ObjectToWorld._12_22_32_42 = float4(0, 4, 0, 0);
                    unity_ObjectToWorld._13_23_33_43 = float4(0, 0, 4, 0);
                    unity_ObjectToWorld._14_24_34_44 = float4(data.xyz, 1);
                    unity_WorldToObject = unity_ObjectToWorld;
                    unity_WorldToObject._14_24_34 *= -1;
                    unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
                #endif


                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
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
                return lerp(_DeepColor, _ShallowColor, i.uv.y);
                //return fixed4(i.uv.xy, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
