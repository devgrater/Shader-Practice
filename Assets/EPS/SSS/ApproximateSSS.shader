Shader "Unlit/ApproximateSSS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE 

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
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex); //welp.
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


        ENDCG




        Pass
        {
            Name "Pre-SSS-Render"
            Cull Front
            Tags { "RenderType"="Opaque" }
            LOD 100
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog


            fixed4 frag (v2f i) : SV_Target
            {



                //how deep is this?
                return 1 / i.screenPos.w;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog



                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
        GrabPass {}
        Pass
        {
            CGPROGRAM 
                sampler2D _BackfaceDepthTexture;

                #pragma vertex vert
                #pragma fragment frag
                // make fog work
                #pragma multi_compile_fog
                fixed4 frag (v2f i) : SV_Target
                {
                    //welp.
                    fixed2 screenUV = i.screenPos.xy / i.screenPos.w;



                    //how deep is this?
                    return 1 / i.screenPos.w;
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
