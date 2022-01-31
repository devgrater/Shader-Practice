Shader "Grater/Stylized/StylizedEyes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "black" {}
        _HighLight ("Eye Highlight", 2D) = "black" {}
        _BaseTex ("Base Tex", 2D) = "white" {} //controlling alpha //not used really
        _Cutoff ("Cutoff", Range(0,1)) = 0.5
        _HighlightIntensity ("Highlight Intensity", Range(0, 1)) = 0.0
        _Outline ("Outline Thickness", Range(0.001, 1.0)) = 0.002
    }
    SubShader
    {
        UsePass "Grater/Stylized/StylizedRendererBase/OUTLINE"
        //UsePass "Grater/Stylized/StylizedRendererBase/BASE"
        Pass {
            Name "Base"
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "StylizedHelper.cginc"

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 eyeUV : TEXCOORD6;
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(2, 3)
                float4 pos : SV_POSITION;
                fixed3 normal : NORMAL;
                fixed3 viewDir : TEXCOORD4;
                float4 vertexColor : COLOR;
                float4 worldPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            sampler2D _ShadowTex;
            sampler2D _BaseTex;
            sampler2D _HighLight;
            
            float4 _BaseTex_ST;
            float4 _MainTex_ST;
            float4 _HighLight_ST;
            fixed _Cutoff;

            fixed _HighlightIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.eyeUV = TRANSFORM_TEX(v.uv, _HighLight);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                
                return o;
            }

            
                fixed4 frag(v2f i) : SV_Target
                {
                    //return i.vertexColor;
                    //there is no vertex color
                    //then, where did the adjusted normal go?

                    // sample the texture
                    fixed4 col = tex2D(_MainTex, i.uv);
                    fixed4 shadowCol = tex2D(_ShadowTex, i.uv);
                    fixed3 normal = normalize(i.normal); //welp
                    fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                    fixed3 viewDir = normalize(i.viewDir);

                    fixed3 highLightVal = tex2D(_HighLight, i.eyeUV);
                    

                    fixed3 halfVector = normalize(viewDir + lightDir);

                    fixed normalShading = dot(normal, lightDir);
                    fixed environmentShadow = LIGHT_ATTENUATION(i);
                    
                    fixed compositeShading = combine_shadow(normalShading, environmentShadow);
                    compositeShading = toonify(compositeShading, 1.0f);
                    //fixed toonShading = half_lambertify(toonify(compositeShading, 1.0f));
                    //sample the ramp with the toon shading value

                    fixed rimLight = saturate(dot(normal, viewDir));
                    fixed rimLightOcclusion = saturate(dot(halfVector, lightDir));
                    //rimLight = 1 - (1 - rimLightOcclusion) * (rimLight);
                    rimLight = saturate(pow(1.0f - rimLight, 6.0f) * (1.0f - rimLightOcclusion));
                    rimLight = smoothstep(0.4, 0.5, rimLight);

                    //fixed4 toonLightingColors = tex2D(_ToonLightingRamp, fixed2(compositeShading, 0.0f));

                    // apply fog
                    //UNITY_APPLY_FOG(i.fogCoord, col);
                    
                    float4 compositeColor = lerp(shadowCol, col, compositeShading);//compositeShading * col;
                    compositeColor.rgb += rimLight * environmentShadow * _LightColor0.rgb;
                    compositeColor.rgb += highLightVal.rgb;

                    return compositeColor;//compositeShading * col;
                }


            ENDCG
        }


        UsePass "Grater/Stylized/StylizedRendererBase/ADDITIONAL"
        UsePass "Grater/VertexCutout/CASTER"
    }
    Fallback "VertexLit"
}
