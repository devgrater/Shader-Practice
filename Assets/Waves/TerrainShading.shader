// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ToonTerrain"
{
    Properties
    {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        [HideInInspector] _Color ("Main Color", Color) = (1.000000,1.000000,1.000000,1.000000)
        // Splat Map Control Texture
        [HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
        
        // Textures
        [HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
        [HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
        [HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
        [HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
        
        // Normal Maps
        [HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
        [HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
        [HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
        [HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}

        _ShadowColor ("Shadow Color", Color) = (0.373, 0.427, 0.471,1.0)
        _Tint ("Tint", Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {


        Pass
        {
            Name "TOON"
            Tags {
                "LightMode" = "ForwardBase"
            }
            LOD 100
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv_Control : TEXCOORD0;
                float2 uv_Splat0 : TEXCOORD1;
                float2 uv_Splat1 : TEXCOORD2;
                float2 uv_Splat2 : TEXCOORD3;
                float2 uv_Splat3 : TEXCOORD4;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                SHADOW_COORDS(8)
                UNITY_FOG_COORDS(7)
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float2 uv_Control : TEXCOORD0;
                float2 uv_Splat0 : TEXCOORD1;
                float2 uv_Splat1 : TEXCOORD2;
                float2 uv_Splat2 : TEXCOORD3;
                float2 uv_Splat3 : TEXCOORD4;
                

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Control, _Splat0, _Splat1, _Splat2, _Splat3;
            float4 _Control_ST, _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
            uniform float4 _LightColor0; //From UnityCG
            float4 _ShadowColor;
            float4 _Tint;
            float _Rotation;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv_Control = TRANSFORM_TEX(v.uv_Control, _Control);
                o.uv_Splat0 = TRANSFORM_TEX(v.uv_Splat0, _Splat0);
                o.uv_Splat1 = TRANSFORM_TEX(v.uv_Splat1, _Splat1);
                o.uv_Splat2 = TRANSFORM_TEX(v.uv_Splat2, _Splat2);
                o.uv_Splat3 = TRANSFORM_TEX(v.uv_Splat3, _Splat3);
                UNITY_TRANSFER_FOG(o,o.pos);


                //Unpack: 

                //Then we need to apply the normal
                //float3 normal = UnityObjectToWorldNormal(v.normal);
                //float3 tangent = UnityObjectToWorldNormal(v.tangent);
                //float3 bitangent = cross(tangent, normal);
                //Apply the normal:
                //o.tbn[0] = tangent;
                //o.tbn[1] = bitangent;
                //o.tbn[2] = normal;
                

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample main texture
                fixed4 splat_control = tex2D (_Control, i.uv_Control);
                fixed4 col;// = tex2D(_MainTex, i.uv);
                col.rgb  = splat_control.r * tex2D (_Splat0, i.uv_Splat0).rgb;
                col.rgb += splat_control.g * tex2D (_Splat1, i.uv_Splat1).rgb;
                col.rgb += splat_control.b * tex2D (_Splat2, i.uv_Splat2).rgb;
                col.rgb += splat_control.a * tex2D (_Splat3, i.uv_Splat3).rgb;

                col.a = 1.0;



                // sample normal
                //float3 tangentNormal = tex2D(_Normal, TRANSFORM_TEX(i.uv, _Normal));
                //tangentNormal = tangentNormal * 2 - 1;
                //Convert tangent normal to world normal:
                //float3 worldNormal = float3(i.tbn[0] * tangentNormal.r + i.tbn[1] * tangentNormal.g + i.tbn[2] * tangentNormal.b);
                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                //Credit: https://roystan.net/articles/toon-shader.html
                float shadow = SHADOW_ATTENUATION(i);
                //float lightStrength = smoothstep(0.00, 0.01, NdotL * shadow);
                float lightStrength = 1;


                //Specular and rim light are ignored because I'm being lazy and it doesn't really make too much difference.
                //Only shadow is used.
                // apply fog

                col = col * lerp(_ShadowColor, _LightColor0, lightStrength) *(1+unity_AmbientSky);
                UNITY_APPLY_FOG(i.fogCoord, col);
                 
                return col;
            }
            ENDCG
        }
        
        Pass 
            {
            Tags {
                 "LightMode" = "ForwardAdd" 
            } //For every additional light
            Blend One One //Additive blending

                CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc" //Provides us with light data, camera information, etc

            uniform float4 _LightColor0; //From UnityCG
            float4 _LightColor, _LightDir, _LightPos;
            sampler2D _LightTexture0, _LightTextureB0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float4 posWorld : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.posWorld = mul(unity_ObjectToWorld, v.vertex); //Calculate the world position for our point
                o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz); //Calculate the normal
                o.pos = UnityObjectToClipPos(v.vertex); //And the position

                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                float3 normalDirection = normalize(i.normal);
                float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);

                float3 vert2LightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
                float3 normalizedDist = normalize(vert2LightSource);

                float oneOverDistance = max(1 / length(vert2LightSource) / length(vert2LightSource) - 0.5, 0.0);
                float attenuation = lerp(1.0, oneOverDistance, _WorldSpaceLightPos0.w);
                attenuation = attenuation > 0? 1 : 0;
               
               
                float3 lightDirection = _WorldSpaceLightPos0.xyz - i.posWorld.xyz * _WorldSpaceLightPos0.w;

                //float attenuation = tex2D(_LightTextureB0, (normalizedDist * normalizedDist).xx).UNITY_ATTEN_CHANNEL;
                //float attenuation = tex2D(_LightTextureB0, (dot(vert2LightSource, vert2LightSource) * _WorldSpaceLightPos0.w).rr).UNITY_ATTEN_CHANNEL;
                //float attenuation = tex2D(_LightTextureB0, float2(length(vert2LightSource), length(vert2LightSource))).a;
                float3 diffuseReflection = attenuation * _LightColor0.rgb * float3(0.05,0.05,0.05) * max(0.0, dot(normalDirection, lightDirection)); //Diffuse component

                float3 color = diffuseReflection; //No ambient component this time
                return float4(color, 1.0);
            }
            ENDCG
        }
        
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
