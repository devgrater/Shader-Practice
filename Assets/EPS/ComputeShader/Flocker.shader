Shader "Unlit/Flocker"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Cutoff", Range(0, 1)) = 0.5
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Cull Off
        Tags {
            "RenderType"="Opaque"
            "LightMode"="ForwardBase"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma instancing_options procedural:ConfigureProcedural
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma target 4.5
            #pragma multi_compile_instancing 
            

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
                float3 color : COLOR;
                float3 normal : NORMAL;
                fixed2 lighting : TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
            };

            struct BoidOutputData {
                float3 position;
                float3 velocity;
                float3 param3;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                StructuredBuffer<BoidOutputData> _Boids;
            #endif
            

            void ConfigureProcedural(){

            }

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                o.color = fixed3(0, 0, 0);
                #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                    BoidOutputData bd = _Boids[instanceID];
                    unity_ObjectToWorld = 0.0;
                    unity_ObjectToWorld._m03_m13_m23_m33 = float4(bd.position, 1.0f);
                    unity_ObjectToWorld._m00_m11_m22 = bd.param3.y;
                    //o.color = fixed3(bd.color);
                    //find rotation from bd.velocity
                    //oh wow copilot....
                    float3 up = float3(0, 1, 0);
                    float3 forward = normalize(bd.velocity);
                    float3 right = normalize(cross(up, forward));
                    float3 up2 = cross(forward, right);
                    float3x3 rot = float3x3(right, up2, forward);

                    v.vertex.z += sin(v.vertex.x * 1.1 + _Time.b * length(bd.velocity) * 5 + instanceID / 1024) * 0.3;
                    float3 centerOffset = v.vertex.xyz;
                    
                    //save from vertex multiplication
                    float3 rotatedLocal = forward * centerOffset.x + up2 * centerOffset.y + right * centerOffset.z;
                    float3 rotatedNormal = forward * v.normal.x + up2  * v.normal.y + right * v.normal.z;
                    o.vertex = UnityObjectToClipPos(rotatedLocal);

                    o.normal = UnityObjectToWorldNormal(rotatedNormal);
                #else   
                    // unity_ObjectToWorld._m00_m11_m22 = 0.1f;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.normal = UnityObjectToWorldNormal(v.normal);
			    #endif

                


               
                //o.vertex = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.lighting = 0.0f;
                o.lighting.r = dot(normalize(o.normal), _WorldSpaceLightPos0.xyz);
                o.lighting.g = abs(dot(normalize(-o.normal) * 1.1, _WorldSpaceLightPos0.xyz));
                o.worldViewDir = WorldSpaceViewDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 halfDir = normalize(i.worldViewDir + _WorldSpaceLightPos0.xyz);
                fixed specular = dot(halfDir, normalize(i.normal));
                specular = saturate(specular);
                specular = pow(specular, 256);
                // sample the texture
                fixed rim = dot(i.normal * 1.3, i.worldViewDir);
                rim = 1 - saturate(rim);
                fixed lighting = i.lighting.r + i.lighting.g;
                //return float4(lighting, lighting, lighting, 1.0f);
                //lighting = saturate(lighting);
                //half-lambert lighting
                lighting = lighting * 0.5f + 0.5f;
                lighting = lighting * lighting;
                lighting = max(lighting, rim * 0.3);
                lighting += specular * 2;
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                col.rgb *= lighting;
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                clip(col.a - 0.5);
                return col;
            }
            ENDCG
            
        }

        Pass {
            Cull Off
            Name "TwoSidedCaster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma target 2.0
            #pragma instancing_options procedural:ConfigureProcedural
            #pragma multi_compile_shadowcaster
            #pragma target 4.5
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct BoidOutputData {
                float3 position;
                float3 velocity;
                float3 param3;
            };


            #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                StructuredBuffer<BoidOutputData> _Boids;
            #endif

            uniform float4 _MainTex_ST;

            void ConfigureProcedural(){

            }

            v2f vert( appdata_base v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                    BoidOutputData bd = _Boids[instanceID];
                    unity_ObjectToWorld = 0.0;
                    unity_ObjectToWorld._m03_m13_m23_m33 = float4(bd.position, 1.0f);
                    unity_ObjectToWorld._m00_m11_m22 = bd.param3.y;
                    //o.color = fixed3(bd.color);
                    //find rotation from bd.velocity
                    //oh wow copilot....
                    float3 up = float3(0, 1, 0);
                    float3 forward = normalize(bd.velocity);
                    float3 right = normalize(cross(up, forward));
                    float3 up2 = cross(forward, right);
                    float3x3 rot = float3x3(right, up2, forward);

                    v.vertex.z += sin(v.vertex.x * 1.1 + _Time.b * length(bd.velocity) * 5 + instanceID / 1024) * 0.3;
                    float3 centerOffset = v.vertex.xyz;
                    //save from vertex multiplication
                    float3 rotatedLocal = forward * centerOffset.x + up2 * centerOffset.y + right * centerOffset.z;
                    v.vertex.xyz = rotatedLocal;
                    o.pos = UnityObjectToClipPos(v.vertex);
                #else   
                    // unity_ObjectToWorld._m00_m11_m22 = 0.1f;
                    o.pos = UnityObjectToClipPos(v.vertex);
			    #endif



                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            uniform sampler2D _MainTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;

            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                clip( texcol.a*_Color.a - _Cutoff );

                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
