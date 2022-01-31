// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Grater/Stylized/StylizedRendererBase"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        //_Color ("Color", Color) = (1, 1, 1, 1)
        _ShadowTex ("Shadow Texture", 2D) = "black" {}
        _BaseTex ("Base Tex", 2D) = "white" {} //controlling alpha
        _ControlTex ("Control Tex", 2D) = "black" {}
        _Cutoff ("Cutoff", Range(0,1)) = 0.5
        _HighlightIntensity ("Highlight Intensity", Range(0, 1)) = 0.0
        _Outline ("Outline Thickness", Range(0.001, 1.0)) = 0.002
        _EnvLightContrib ("Environment Light Contribution", Range(0, 1)) = 0.5
    }
    SubShader
    {
        LOD 100
        //AlphaTest Greater [_Cutoff]
        CGINCLUDE

            //remember to include unity cg before autolight!
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "StylizedHelper.cginc"
            #include "UnityImageBasedLighting.cginc"
            
            //#include "UnityShadowLibrary.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _ShadowTex;
            sampler2D _BaseTex;
            sampler2D _ControlTex;
            
            float4 _BaseTex_ST;
            float4 _MainTex_ST;
            fixed _Cutoff;
            fixed _EnvLightContrib;

            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(2, 3)
                float4 pos : SV_POSITION;
                fixed3 normal : NORMAL;
                fixed3 viewDir : TEXCOORD4;
                float4 vertexColor : COLOR;
                float4 worldPos : TEXCOORD5;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.vertexColor = v.vertexColor;
                o.uv2 = v.uv2;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }


        ENDCG

        

        Pass
        {
            Name "Outline"
            Cull Front
            Tags {
                "RenderType"="Opaque"
            }

            CGPROGRAM

            #pragma vertex outline_vert
            #pragma fragment outline_frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct outline_v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            half _Outline;
            float4 _OutlineColor;

            outline_v2f outline_vert (appdata v)
            {
                outline_v2f o;
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                normal.z = -0.5;
                float3 ndcNormal = normalize(TransformViewToProjection(normal)) * pos.w; 

                pos.xy += 0.01 * ndcNormal.xy * _Outline;
                o.vertex = pos;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                return o;
            }

            fixed4 outline_frag (outline_v2f i) : SV_Target
            {
                // sample the texture
                //and clip out what we don't need.
                fixed alphaMask = tex2D(_BaseTex, i.uv).b;
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                clip(alphaMask - _Cutoff);
                return _OutlineColor * baseColor;
            }
            ENDCG
        }


        Pass
        {
            Name "Base"
            Tags {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
                
            }
        
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag_base

                #pragma multi_compile_fog
                #pragma multi_compile_fwdbase
                
                fixed _HighlightIntensity;

                fixed4 frag_base(v2f i) : SV_Target
                {
                    //return i.uv2;
                    //return i.vertexColor;
                    //there is no vertex color
                    //then, where did the adjusted normal go?

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

                    fixed3 controlTexVal = tex2D(_ControlTex, i.uv);
                    fixed rimMask = controlTexVal.b;
                    fixed envContrib = controlTexVal.g;
                    //g channel - environment color
                    //b channel - rim mask
                    

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
                    rimLight = smoothstep(0.4, 0.4, rimLight);

                    //fixed4 toonLightingColors = tex2D(_ToonLightingRamp, fixed2(compositeShading, 0.0f));

                    // apply fog
                    //UNITY_APPLY_FOG(i.fogCoord, col);
                    
                    float4 compositeColor = lerp(shadowCol, col, compositeShading);//compositeShading * col;
                    compositeColor.rgb += rimLight * environmentShadow * _LightColor0.rgb * rimMask;
                    compositeColor.rgb += specular * col * _HighlightIntensity;
                    compositeColor.rgb += _EnvLightContrib * ShadeSH9(float4(normal, 1.0f)) * envContrib;

                    clip(alphaMask - _Cutoff);

                    return compositeColor;//compositeShading * col;
                }

            ENDCG
        }

        
        Pass
        {
            
            Name "Additional"
            Tags {
                 "RenderType"="Opaque" 
                 "LightMode"="ForwardAdd"
            }
            Blend One One
            CGPROGRAM

            
                #pragma vertex vert
                #pragma fragment frag

                #pragma multi_compile_fog
                #pragma multi_compile_fwdadd_fullshadows


                fixed4 frag(v2f i) : SV_Target
                {
                    
                    fixed3 normal = normalize(i.normal);
                    fixed3 baseTexVal = tex2D(_BaseTex, i.uv);
                    fixed selfShadowing = baseTexVal.r;
                    fixed alphaMask = baseTexVal.b;
                    //now lets find out about the colors
                    fixed3 lightDir;
                    if(_WorldSpaceLightPos0.w == 0){
                        //directional light
                        lightDir = normalize(_WorldSpaceLightPos0);
                    }
                    else{
                        lightDir = normalize(_WorldSpaceLightPos0 - i.worldPos);
                    }

                    fixed normalShading = dot(i.normal, lightDir);
                    fixed lighting = LIGHT_ATTENUATION(i);


                    //mix them together
                    lighting = combine_shadow(normalShading, lighting);
                    lighting = combine_shadow(selfShadowing, lighting);
                    //lighting = toonify(lighting, 1.0f) * _LightColor0;
                    float4 coloredLighting = float4(light_toonify(lighting, 1.0f) * _LightColor0.xyz, 1.0f);
                    clip(alphaMask - _Cutoff);
                    return coloredLighting;
                }

            ENDCG
        }

        UsePass "Grater/VertexCutout/CASTER"

    }
    Fallback "VertexLit"
}
