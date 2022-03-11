Shader "Unlit/TwoSidedFeather"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Interior ("Interior Thickness", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _SpecColor ("Spec Color", Color) = (1,1,1,0)
        _Emission ("Emissive Color", Color) = (0,0,0,0)
        [PowerSlider(5.0)] _Shininess ("Shininess", Range (0.1, 1)) = 0.7
        _Color ("Main Color", Color) = (1,1,1,1)
    }
    SubShader
    {


        Pass
        {
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardBase"
                //"Queue"="Transparent+8"
            }
            LOD 100
            Cull Off
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
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            sampler2D _MainTex;
            sampler2D _Interior;
            float4 _MainTex_ST;
            float3 _Color;
            fixed _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed lighting = dot(normalize(normal), _WorldSpaceLightPos0.xyz);
                fixed fresnel = saturate(dot(normal, viewDir));

                fixed3 backlitDir = normal + _WorldSpaceLightPos0.xyz;
                fresnel = saturate(dot(viewDir, -backlitDir));

                //
                
                //fresnel = 1 - fresnel;
                fresnel = pow(fresnel, 3) * 0.5;
                //fresnel = 
                //return fresnel;

                lighting = min(lighting, LIGHT_ATTENUATION(i));
                
                lighting = (lighting + 1) * 0.5f;

                


                //return lighting;
               
                //return fresnel;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - _Cutoff);
                //return lighting;
                //return col * lighting;

                fixed thickness = tex2D(_Interior, i.uv).r;
                //col.rgb *= saturate(lighting + fresnel) * _Color.rgb;
                col.rgb += ShadeSH9(float4(i.normal, 1.0f));
                //col.rgb = lerp(fixed3(0, 0.2, 0.3), col.rgb, saturate(lighting + fresnel) * thickness) * _Color.rgb * _LightColor0.xyz;
                
                // apply fog
                
                UNITY_APPLY_FOG(i.fogCoord, col);
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
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform float4 _MainTex_ST;

            v2f vert( appdata_base v )
            {
                v2f o;
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
    Fallback "Transparent/Cutout/VertexLit"
}
