Shader "Unlit/TwoPassTransparency"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent" 
            
            "Queue"="Transparent"
        }
        Cull Off
        LOD 100
        Pass
        {
            //depth writing only, nothing else.
            Cull Front
            ZWrite On
            ColorMask 0
        }


        Pass
        {
            Tags {
                "LightMode"="ForwardBase" 
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
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
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                //float4 worldPos : TEXCOORD1;
                //float3 viewDir : TEXCOORD1;
                //float3 lightDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //o.viewDir = WorldSpaceViewDir(v.vertex);
                //o.lightDir = WorldSpaceLightDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 triple_lerp_ambient(fixed3 normal){
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

                return sky_phi * unity_AmbientSky + phi * unity_AmbientEquator + ground_phi * unity_AmbientGround;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = WorldSpaceViewDir(i.vertex);
                float3 lightDir = WorldSpaceLightDir(i.vertex);
                float lightIntensity = dot(normalize(i.worldNormal), normalize(lightDir));
                //half lambert:
                lightIntensity = ((lightIntensity * 0.5f) + 0.5f);
                lightIntensity *= lightIntensity;
                // sample the texture
                fixed4 ambient = triple_lerp_ambient(i.worldNormal);
                fixed4 lightColor = lightIntensity * (_LightColor0) + ambient;
                fixed4 col = tex2D(_MainTex, i.uv) * lightColor;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col * _Color;
            }
            ENDCG
        }

        /*
        Pass
        {
            //depth writing only, nothing else.
            Cull Back
            ZWrite On
            ColorMask 0
        }*/

        Pass
        {
            Tags {
                "LightMode"="ForwardBase" 
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
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
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                //float4 worldPos : TEXCOORD1;
                //float3 viewDir : TEXCOORD1;
                //float3 lightDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //o.viewDir = WorldSpaceViewDir(v.vertex);
                //o.lightDir = WorldSpaceLightDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 triple_lerp_ambient(fixed3 normal){
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

                return sky_phi * unity_AmbientSky + phi * unity_AmbientEquator + ground_phi * unity_AmbientGround;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = WorldSpaceViewDir(i.vertex);
                float3 lightDir = WorldSpaceLightDir(i.vertex);
                float lightIntensity = dot(normalize(i.worldNormal), normalize(lightDir));
                //half lambert:
                lightIntensity = ((lightIntensity * 0.5f) + 0.5f);
                lightIntensity *= lightIntensity;
                // sample the texture
                fixed4 ambient = triple_lerp_ambient(i.worldNormal);
                fixed4 lightColor = lightIntensity * (_LightColor0) + ambient;
                fixed4 col = tex2D(_MainTex, i.uv) * lightColor;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col.rgb *= _Color.rgb;
                col.a *= _Color.a;
                return col;
            }
            ENDCG
        }
    }
}
