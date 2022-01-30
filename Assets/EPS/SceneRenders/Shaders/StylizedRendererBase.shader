Shader "Grater/StylizedRendererBase"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Color ("Color", Color) = (1, 1, 1, 1)
        _ShadowTex ("Shadow Texture", 2D) = "black" {}
        _BaseTex ("Base Tex", 2D) = "white" {} //controlling alpha
        _Cutoff ("Cutoff", Range(0,1)) = 0.5
        _HighlightIntensity ("Highlight Intensity", Range(0, 1)) = 0.0
    }
    SubShader
    {

        //AlphaTest Greater [_Cutoff]
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
            sampler2D _ShadowTex;
            sampler2D _BaseTex;
            float4 _MainTex_ST;
            float4 _Color;
            fixed _HighlightIntensity;
            fixed _Cutoff;

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

                sampler2D _ToonLightingRamp;

                fixed4 frag_base(v2f i) : SV_Target
                {
                    // sample the texture
                    fixed4 col = tex2D(_MainTex, i.uv);
                    fixed4 shadowCol = tex2D(_ShadowTex, i.uv);
                    fixed3 normal = normalize(i.normal); //welp
                    fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                    fixed3 viewDir = normalize(i.viewDir);

                    fixed3 baseTexVal = tex2D(_BaseTex, i.uv);
                    fixed selfShadowing = baseTexVal.r;
                    fixed specular = baseTexVal.g;
                    fixed alphaMask = baseTexVal.b;
                    

                    //half vector
                    fixed3 halfVector = normalize(viewDir + lightDir);

                    fixed normalShading = dot(normal, lightDir);
                    fixed environmentShadow = LIGHT_ATTENUATION(i);
                    
                    fixed compositeShading = combine_shadow(normalShading, environmentShadow);
                    compositeShading = combine_shadow(selfShadowing, compositeShading);
                    compositeShading = toonify(compositeShading, 1.0f);
                    //fixed toonShading = half_lambertify(toonify(compositeShading, 1.0f));
                    //sample the ramp with the toon shading value

                    fixed rimLight = saturate(dot(normal, viewDir));
                    fixed rimLightOcclusion = saturate(dot(halfVector, lightDir));
                    //rimLight = 1 - (1 - rimLightOcclusion) * (rimLight);
                    rimLight = saturate(pow(1.0f - rimLight, 6.0f) * (1.0f - rimLightOcclusion));

                    

                    //fixed4 toonLightingColors = tex2D(_ToonLightingRamp, fixed2(compositeShading, 0.0f));





                    // apply fog
                    //UNITY_APPLY_FOG(i.fogCoord, col);
                    
                    
                    float4 compositeColor = lerp(shadowCol, col, compositeShading);//compositeShading * col;
                    compositeColor.rgb += rimLight * environmentShadow;
                    compositeColor.rgb += specular * col * _HighlightIntensity;

                    clip(alphaMask - _Cutoff);

                    return compositeColor;//compositeShading * col;
                }

            ENDCG
        }
        UsePass "Grater/VertexCutout/CASTER"
        /*
        Pass {
            Name "Caster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
                #pragma vertex sc_vert
                #pragma fragment sc_frag
                #pragma target 2.0
                #pragma multi_compile_shadowcaster
                #pragma multi_compile_instancing
                #include "UnityCG.cginc"

                struct sc_v2f {
                    V2F_SHADOW_CASTER;
                    float2  uv : TEXCOORD1;
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                uniform float4 _MainTex_ST;

                sc_v2f sc_vert( appdata_base v )
                {
                    sc_v2f o;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    return o;
                }

                uniform sampler2D _BaseTex;
                uniform fixed _Cutoff;
                uniform fixed4 _Color;

                float4 sc_frag( sc_v2f i ) : SV_Target
                {
                    fixed4 texcol = tex2D( _BaseTex, i.uv );
                    clip(texcol.b - _Cutoff);
                    SHADOW_CASTER_FRAGMENT(i)
                }
            ENDCG
        }*/
    }
    Fallback "VertexLit"
}
