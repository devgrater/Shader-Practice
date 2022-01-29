Shader "Unlit/StylizedRendererBase"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseTex ("Base Tex", 2D) = "white" {} //controlling alpha
    }
    SubShader
    {
        CGINCLUDE
            // make fog work
            #pragma multi_compile_fog
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "StylizedHelper.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(2, 3)
                float4 pos : SV_POSITION;
                fixed3 normal : NORMAL;
                fixed3 viewDir : TEXCOORD4;
            };

            sampler2D _MainTex;
            sampler2D _BaseTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag_base(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 controlTexVal = tex2D(_BaseTex, i.uv);
                fixed3 normal = normalize(i.normal); //welp
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed3 viewDir = normalize(i.viewDir);

                //half vector
                fixed3 halfVector = normalize(viewDir + lightDir);

                fixed normalShading = dot(normal, lightDir);
                fixed environmentShadow = LIGHT_ATTENUATION(i);
                
                fixed compositeShading = combine_shadow(normalShading, environmentShadow);
                fixed toonShading = half_lambertify(toonify(compositeShading, 1.0f));

                fixed rimLight = saturate(dot(normal, viewDir));
                fixed rimLightOcclusion = saturate(dot(halfVector, lightDir));
                //rimLight = 1 - (1 - rimLightOcclusion) * (rimLight);
                rimLight = saturate(pow(1.0f - rimLight, 6.0f) * (1.0f - rimLightOcclusion));


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip(controlTexVal.b - 0.5f);
                
                return toonShading * col + rimLight * environmentShadow;//compositeShading * col;
            }
        ENDCG

        LOD 100

        Pass
        {
            
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
            }
        
            CGPROGRAM
                #pragma multi_compile_fwdbase
                #pragma vertex vert
                #pragma fragment frag_base
            ENDCG
        }
    }
    Fallback "VertexLit"
}
