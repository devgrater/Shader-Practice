Shader "Unlit/BuiltInShadowMapper"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowOffset ("Float", Range(-1, 1)) = 0.0
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            #include "PCFHelper.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                SHADOW_COORDS(3)
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ShadowOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_SHADOW(o);
                return o;
            }

        ENDCG

        Pass
        {
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardBase"
            }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                fixed shadow = SHADOW_ATTENUATION(i);//SHADOW_ATTEN_OFFSET(i, float4(_ShadowOffset, _ShadowOffset, 0, 0));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return shadow * col;
            }
            ENDCG
        }
        //forward add shadows
        Pass
        {
            Blend One One
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardAdd"
            }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //#pragma multi_compile_fwdadd
            #pragma multi_compile_fwdadd_fullshadows


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                fixed shadow = SHADOW_ATTENUATION(i);//SHADOW_ATTEN_OFFSET(i, float4(_ShadowOffset, _ShadowOffset, 0, 0));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return shadow;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
