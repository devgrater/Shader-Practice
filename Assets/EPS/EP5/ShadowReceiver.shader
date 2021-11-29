Shader "Unlit/ShadowReceiver"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            Tags {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                SHADOW_COORDS(4)
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                TRANSFER_SHADOW(o);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }


            fixed4 triple_lerp_ambient(fixed3 normal, fixed lightIntensity){
                //
                //fixed lerp_t = dot(normal, )
                fixed phi = abs(normal.y);//sqrt(1.0f - dot(normal.xz, normal.xz)) * sign(normal.y);
                fixed sky_phi = phi * 0.5f + 0.5f;
                fixed ground_phi = -(phi * 0.5f - 0.5f);
                
                //phi = phi * 0.5f + 0.5f;//top is 1, bottom is 0
                /*
                fixed4 col_1 = (1.0f - phi) * (1.0f - phi) * unity_AmbientGround;
                fixed4 col_2 = 2.0f * phi * (1.0f - phi) * unity_AmbientEquator;
                fixed4 col_3 = phi * phi * unity_AmbientSky;*/

                return sky_phi * unity_AmbientSky + phi * unity_AmbientEquator + ground_phi * unity_AmbientGround * (1 - lightIntensity);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = WorldSpaceViewDir(i.pos);
                float3 lightDir = WorldSpaceLightDir(i.pos);
                fixed lightIntensity = dot(normalize(i.worldNormal), normalize(lightDir));
                //half lambert:

                fixed shadow = SHADOW_ATTENUATION(i);
                lightIntensity = smoothstep(0, 0.01f, lightIntensity);
                lightIntensity *= shadow;
                lightIntensity = saturate((lightIntensity * 0.5f) + 0.5f);
                lightIntensity *= lightIntensity;
                //lightIntensity += fresnel;
                
                // sample the texture
                fixed4 ambient = triple_lerp_ambient(i.worldNormal, lightIntensity);
                fixed4 lightColor = lightIntensity * (_LightColor0) + ambient;
                fixed4 falloffColor = _LightColor0;
                falloffColor *= fixed4(0.001, 0.001, 1.0, 1.0);
                //fixed falloffLerp = saturate(sin(lightIntensity * 3.1415926));
                //lightColor = lerp(_LightColor0, falloffColor, falloffLerp);
                fixed4 col = tex2D(_MainTex, i.uv) * lightColor * _Color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

        
        Pass {
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One //multiply

            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 worldPos : TEXCOORD1;
                //float3 viewDir : TEXCOORD1;
                //float3 lightDir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //o.viewDir = WorldSpaceViewDir(v.vertex);
                //o.lightDir = WorldSpaceLightDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldLightDir;
                fixed atten = 1.0f;
                #ifdef USING_DIRECTIONAL_LIGHT
                    worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                #endif

                float lightIntensity = saturate(dot(worldLightDir, i.worldNormal));
                
                #ifdef USING_DIRECTIONAL_LIGHT
                    atten = 1.0f; //no falloff
                #else
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    //return float4(dot(lightCoord, lightCoord).rrr, 1);
                #endif
                lightIntensity = smoothstep(0.00, 0.01f, lightIntensity * atten);
                //falloff towards lower spectrum
                fixed4 falloffColor = _LightColor0;
                falloffColor *= fixed4(0.001, 0.001, 1.0, 1.0);
                
                return lightIntensity * lerp(falloffColor, _LightColor0, lightIntensity);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
