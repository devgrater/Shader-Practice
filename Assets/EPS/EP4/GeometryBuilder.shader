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


            struct g2f
            {
                float4 pos : SV_POSITION;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            [maxvertexcount(3)]
            void geom (triangle v2g IN[3] : SV_POSITION, inout TriangleStream<g2f> triStream){
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

                o.pos = UnityObjectToClipPos(float4(-0.25, 0, 0, 0)) + IN[0].vertex;
                triStream.Append(o);

                o.pos = UnityObjectToClipPos(float4(0.25, 0, 0, 0)) + IN[0].vertex;
                triStream.Append(o);

                o.pos = UnityObjectToClipPos(float4(0, 1, 0, 0)) + IN[0].vertex;
                triStream.Append(o);
            }


            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }




            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(0.2, 0.85, 0.4, 1);
            }
            ENDCG
        }
    }
}
