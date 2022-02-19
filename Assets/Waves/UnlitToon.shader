// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ToonShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _AmbientColor ("Ambient Color", Color) = (0.1,0.1,0.1,1.0)
        _ShadowColor ("Shadow Color", Color) = (0.373, 0.427, 0.471,1.0)
        [HDR] _LightColor ("Light Color", Color) = (1.0,0.98,0.84,1.0)
        _Tint ("Tint", Color) = (1.0,1.0,1.0,1.0)
        _Rotation ("UV Rotation", Float) = 0
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
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                SHADOW_COORDS(2)
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(7)
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 tbn[3] : TEXCOORD3;
                float4 posWorld : TEXCOORD6;
                

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Normal;
            float4 _Normal_ST;
            float4 _AmbientColor;
            float4 _LightColor;
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

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);

                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

                

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample main texture
                fixed4 col = tex2D(_MainTex, i.uv);


                //Convert tangent normal to world normal:
                float3 worldNormal = i.worldNormal;
                float3 normal = normalize(worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                //Credit: https://roystan.net/articles/toon-shader.html
                float shadow = SHADOW_ATTENUATION(i);
                float lightStrength = 1;
                //Specular and rim light are ignored because I'm being lazy and it doesn't really make too much difference.
                //Only shadow is used.
                // apply fog
                col = col * _Tint * lerp(_ShadowColor, _LightColor0, lightStrength) * (1+unity_AmbientSky);
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
