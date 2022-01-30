Shader "Grater/Stylized/StylizedFace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "black" {}
        _FaceShadow ("Face Shadow Adjustment", 2D) = "gray" {}
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
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(2, 3)
                float4 pos : SV_POSITION;
                fixed3 normal : NORMAL;
                fixed3 viewDir : TEXCOORD4;
                float4 vertexColor : COLOR;
                float4 worldPos : TEXCOORD5;
                fixed3 upVector : TEXCOORD6;
                fixed3 forwardVector : TEXCOORD7;
            };

            sampler2D _MainTex;
            sampler2D _ShadowTex;
            sampler2D _BaseTex;
            sampler2D _FaceShadow;
            
            float4 _BaseTex_ST;
            float4 _MainTex_ST;
            fixed _Cutoff;

            fixed _HighlightIntensity;

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
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.forwardVector = mul(unity_ObjectToWorld, float4(0, 0, 1, 0));
                o.upVector = mul(unity_ObjectToWorld, float4(0, 1, 0, 0));
                return o;
            }

        
            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 shadowCol = tex2D(_ShadowTex, i.uv);
                fixed3 normal = normalize(i.normal); //welp
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed3 viewDir = normalize(i.viewDir);

                fixed3 baseTexVal = tex2D(_FaceShadow, i.uv);
                fixed selfShadowing = baseTexVal.r;
                fixed faceShadow = baseTexVal.g;

                fixed cheekLight = faceShadow * 2.0f - 1.0f;
                fixed noseShadow = (faceShadow * 2.0f);

                //return noseShadow;
                faceShadow = faceShadow * 2.0f - 1.0f;

                fixed3 rightDir = cross(normalize(i.upVector), normalize(i.forwardVector));

                fixed nDotL = dot(normal, lightDir);
                fixed horizontalLight = dot(lightDir.xz, i.forwardVector.xz);
                fixed rDotL = dot(rightDir, lightDir);
                fixed sideDotL = abs(rDotL);

                //the brightest case:
                fixed facingLightAtten = abs(cheekLight) + nDotL;
                
                fixed uvCutoff = step(0.5f, i.uv.x); //but which side?
                if(rDotL > 0){
                    uvCutoff = 1 - uvCutoff;// dont worry because everythign will evaluate to the same reuslt.
                }
                
                //and then, for the dark parts, we need to use the noseShadow version
                //for the light parts, we use the cheek light version....

                fixed compositeLight = lerp(noseShadow - 1, abs(cheekLight), uvCutoff);
                //and lerp this with 1
                compositeLight = lerp(compositeLight, 1.0f, facingLightAtten);

                return compositeLight + nDotL;
                return uvCutoff;
                //fixed sideLightAtten = 
                return sideDotL;


                //              v some kind of dummy value for now
                return horizontalLight * (1.0f);

                /*


                
                fixed rDotL = dot(rightDir, lightDir);
                fixed lDotL = -rDotL;
                fixed fDotL =  dot(normalize(i.forwardVector), lightDir);
                
                fixed hasNoseDetail = saturate(abs(rDotL));
                
                return (-nDotL * faceShadow + 1) * 0.5f;
                fixed cheekDetail = abs(cheekLight * nDotL);
                fixed noseDetail = noseShadow * hasNoseDetail; //make it switch across sign:
                //noseDetail = lerp(noseShadow, -noseShadow, (pow(nDotL, 0.5) * 2 - 1));

                return noseDetail * 2 - 1;*/

                fixed3 halfVector = normalize(viewDir + lightDir);


                fixed environmentShadow = LIGHT_ATTENUATION(i);
                
                fixed compositeShading = combine_shadow(nDotL, environmentShadow);
                compositeShading = combine_shadow(selfShadowing, compositeShading);
                //compositeShading = saturate(compositeShading + faceShadow);
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
                //compositeColor.rgb += specular * col * _HighlightIntensity;

                //clip(alphaMask - _Cutoff);
                return compositeColor;//compositeShading * col;
            }


            ENDCG
        }


        UsePass "Grater/Stylized/StylizedRendererBase/ADDITIONAL"
        UsePass "Grater/VertexCutout/CASTER"
    }
    Fallback "VertexLit"
}
