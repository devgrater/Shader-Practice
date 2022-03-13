Shader "Unlit/Bush"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _SpecColor ("Spec Color", Color) = (1,1,1,0)
        _Emission ("Emissive Color", Color) = (0,0,0,0)
        [PowerSlider(5.0)] _Shininess ("Shininess", Range (0.1, 1)) = 0.7
        _Color ("Main Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque" 
            "LightMode"="ForwardBase"
        }
        LOD 100

        Pass
        {
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
                LIGHTING_COORDS(2, 3)
                float3 normal : NORMAL;
                float rim : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            fixed _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                //i have no idea what to do
                //but i do know that I need to have the faces face the camera.
                //and i can do that with billboards.
                

                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.uv.xy - 0.5f);
                float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
                //o.pos = UnityObjectToClipPos(v.vertex);

               
                

                v.vertex.xyz += viewSpaceUV.xyz;
                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o, o.pos);
                //per vertex rimlight, because...
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.rim = dot(o.normal, o.viewDir);
                o.rim = saturate(o.rim);
                


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return float4(i.uv, 0.0f, 1.0f);

                fixed shadow = LIGHT_ATTENUATION(i);
                fixed lighting = dot(normalize(i.normal), lightDir);
                //reduce lighting contribution here:
                fixed edgeHighlight = 1 - saturate(dot(normalize(i.normal), normalize(i.viewDir)));
                edgeHighlight = pow(edgeHighlight, 8) * 2;
                fixed shadowContrib = dot(lightDir, normalize(i.viewDir));
                shadowContrib = saturate(shadowContrib);
                shadowContrib = pow(shadowContrib, 4);
                //edgeHighlight *= 1 - shadowContrib;
                shadowContrib = 1 - shadowContrib * 0.8;
                //return shadowContrib;

                lighting = min(saturate(lighting), shadow);
                lighting = 1 - (1 - lighting) * shadowContrib;
                lighting += edgeHighlight;
                lighting = lighting * 0.5f + 0.5f;
                clip(col.a - _Cutoff);
                return col * lighting;
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
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform float4 _MainTex_ST;

            v2f vert( appdata_base v )
            {
                v2f o;
                //float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.texcoord.xy - 0.5f);
                float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
                v.vertex.xyz += viewSpaceUV;

                
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
                clip( texcol.a * _Color.a - _Cutoff );

                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
