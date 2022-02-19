Shader "Unlit/VegetationToonShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Cutoff", Range(0,1)) = 0.5
        _Normal ("Normal", 2D) = "bump" {}
        _AmbientColor ("Ambient Color", Color) = (0.1,0.1,0.1,1.0)
        _ShadowColor ("Shadow Color", Color) = (0.373, 0.427, 0.471,1.0)
        [HDR] _LightColor ("Light Color", Color) = (1.0,0.98,0.84,1.0)
        _TimeScaleFactor ("Time Scale Factor", Float) = 32
        _WaveAmount ("Wave Amount", Float) = 0.01
        _VectorPosFactor ("Vector Position Factor", Float) = 20
        [HideInInspector]
        _Color("Main Color", Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
        Tags {
            //Fuck shadows I gave up
            "Queue" = "Geometry"
            "RenderType"="Opaque"
            "LightMode" = "ForwardBase"
        }
        LOD 100
        
        Pass
        {        
            Tags {
                //Fuck shadows I gave up
                "Queue" = "Geometry"
                "RenderType"="Opaque"
                "LightMode" = "ForwardBase"
            }
            Cull Front
            CGPROGRAM

            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 tbn[3] : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Normal;
            float4 _Normal_ST;
            float4 _AmbientColor;
            uniform float4 _LightColor0;
            float4 _ShadowColor;
            float _TimeScaleFactor;
            float _WaveAmount;
            float _VectorPosFactor;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                v.vertex.x = v.vertex.x + sin(v.vertex.x * _VectorPosFactor + v.vertex.y * 5 + _Time * _TimeScaleFactor) * _WaveAmount;
                v.vertex.z = v.vertex.z + cos(v.vertex.z * _VectorPosFactor + v.vertex.y * 5 + _Time * _TimeScaleFactor) * _WaveAmount;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormal = i.worldNormal;
                worldNormal = -worldNormal;
                // sample main texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 normal = normalize(worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                // apply fog
                
                clip(col.w - 0.4);
                //float lightStrength = smoothstep(0, 0.01, NdotL);
                float lightStrength = 1.0;
                col = col * lerp(_ShadowColor, _LightColor0, lightStrength) * (1+unity_AmbientSky);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

        

        Pass
        {
            Cull Back
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
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                SHADOW_COORDS(2)
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Normal;
            float4 _Normal_ST;
            float4 _AmbientColor;
            uniform float4 _LightColor0;
            float4 _ShadowColor;
            float _TimeScaleFactor;
            float _WaveAmount;
            float _VectorPosFactor;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                v.vertex.x = v.vertex.x + sin(v.vertex.x * _VectorPosFactor + v.vertex.y * 5 + _Time * _TimeScaleFactor) * _WaveAmount;
                v.vertex.z = v.vertex.z + cos(v.vertex.z * _VectorPosFactor + v.vertex.y * 5 + _Time * _TimeScaleFactor) * _WaveAmount;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample normal
                float3 tangentNormal = tex2D(_Normal, TRANSFORM_TEX(i.uv, _Normal));
                tangentNormal = tangentNormal * 2 - 1;
                //Convert tangent normal to world normal:
                float3 worldNormal = i.worldNormal;
                // sample main texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 normal = normalize(worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                //Credit: https://roystan.net/articles/toon-shader.html

                //Specular and rim light are ignored because I'm being lazy and it doesn't really make too much difference.
                //Only shadow is used.
                // apply fog
                
                clip(col.w - 0.4);
                float shadow = SHADOW_ATTENUATION(i);
                //float lightStrength = smoothstep(0, 0.01, NdotL * shadow);
                float lightStrength = 1.0;
                col = col * lerp(_ShadowColor, _LightColor0, lightStrength) * (1+unity_AmbientSky);
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
            sampler2D _MainTex;
            float4 _MainTex_ST;

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
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.posWorld = mul(unity_ObjectToWorld, v.vertex); //Calculate the world position for our point
                o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz); //Calculate the normal
                o.pos = UnityObjectToClipPos(v.vertex); //And the position
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                

                //Sample main texture:
                float4 col = tex2D(_MainTex, i.uv);

                float3 normalDirection = normalize(i.normal);
                float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);

                float3 vert2LightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
                float3 normalizedDist = normalize(vert2LightSource);

                float oneOverDistance = max(1 / length(vert2LightSource) / length(vert2LightSource) - 0.5, 0.0);
                float attenuation = smoothstep(0.00, 0.01, lerp(1.0, oneOverDistance, _WorldSpaceLightPos0.w));
               
               
                float3 lightDirection = _WorldSpaceLightPos0.xyz - i.posWorld.xyz * _WorldSpaceLightPos0.w;

                //float attenuation = tex2D(_LightTextureB0, (normalizedDist * normalizedDist).xx).UNITY_ATTEN_CHANNEL;
                //float attenuation = tex2D(_LightTextureB0, (dot(vert2LightSource, vert2LightSource) * _WorldSpaceLightPos0.w).rr).UNITY_ATTEN_CHANNEL;
                //float attenuation = tex2D(_LightTextureB0, float2(length(vert2LightSource), length(vert2LightSource))).a;
                float3 diffuseReflection = col.w * attenuation * _LightColor0.rgb * float3(0.05,0.05,0.05) * max(0.0, dot(normalDirection, lightDirection)); //Diffuse component

                float3 color = diffuseReflection; //No ambient component this time
                return float4(color, 1.0);
            }
            ENDCG
        }

        //UsePass "Legacy Shaders/Transparent/Cutout/VertexLit/Caster"
        UsePass "Legacy Shaders/Transparent/Cutout/VertexLit/Caster"
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
        
    }
}
