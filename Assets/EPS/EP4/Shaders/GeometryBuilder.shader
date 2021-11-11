// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/GeometryBuilder"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma geometry geom
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "GraterHelper.cginc"




            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float rngesus : TEXCOORD1;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float rngesus : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            
            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = v.normal;
                o.tangent = v.tangent;
                //o.bitangent = cross(o.normal, o.tangent.xyz) * o.tangent.w;
                o.rngesus = random_from_pos(v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom (triangle v2g IN[3] : SV_POSITION, inout TriangleStream<g2f> triStream){
                float4 vTangent = IN[0].tangent;
                float3 vNormal = IN[0].normal;
                float3 vBinormal = cross(vNormal, vTangent.xyz) * vTangent.w;
                float4x4 mvp = UNITY_MATRIX_MVP;
                //rotate around z axis:
                
                //float4x4 rot = float4x4(

                //);
                float4x4 tangentToLocal = mul(mvp, float4x4(
                    vTangent.x, vBinormal.x, vNormal.x, 0,
                    vTangent.y, vBinormal.y, vNormal.y, 0,
                    vTangent.z, vBinormal.z, vNormal.z, 0,
                    0         , 0           , 0        , 1
                ));
                
                //IN[0].vertex.xyz);
                /*
                g2f o;
                o.pos = IN[0].vertex;
                triStream.Append(o);

                o.pos = IN[1].vertex;
                triStream.Append(o);

                o.pos = IN[2].vertex;
                triStream.Append(o);*/
                g2f o;
                //float4 tangent = 
                o.rngesus = IN[0].rngesus;

                o.pos = mul(tangentToLocal, float4(-0.25, 0, 0, 0)) + IN[0].vertex;
                o.uv = float2(0, 0);
                triStream.Append(o);

                o.pos = mul(tangentToLocal, float4(0.25, 0, 0, 0)) + IN[0].vertex;
                o.uv = float2(1, 0);
                triStream.Append(o);

                
                o.pos = mul(tangentToLocal, float4(0, 0, 1, 0)) + IN[0].vertex;
                o.uv = float2(0.5, 1);
                triStream.Append(o);
            }






            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(0.2, lerp(0.85, i.rngesus, 1 - i.uv.y), 0.4, 1);
                //return float4(i.uv, 0, 1);
            }
            ENDCG
        }
    }
}
