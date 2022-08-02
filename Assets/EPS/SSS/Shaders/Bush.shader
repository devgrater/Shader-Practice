Shader "Unlit/Bush"
{
    Properties
    {
        _MainTex ("叶片材质", 2D) = "white" {}
        
        _Cutoff ("Alpha透贴", Range(0,1)) = 0.5
        //_SpecColor ("Spec Color", Color) = (1,1,1,0)
        //_Emission ("Emissive Color", Color) = (0,0,0,0)
        //[PowerSlider(5.0)] _Shininess ("Shininess", Range (0.1, 1)) = 0.7
        _Color ("主颜色", Color) = (1,1,1,1)
        _TopColor ("顶部颜色", Color) = (1,1,1,1)
        //_GradientRange("渐变开始位置", Float) = 0.0
        _GradientOffset("渐变开始偏移", Range(-1, 1)) = 0.0
        _BillboardSize ("面片大小", Range(-4, 4)) = 2.0
        _Inflate ("面片扩展", Range(-4, 4)) = 0.0
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
                //float rim : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _TopColor;
            fixed _Cutoff;
            fixed _Amount;
            fixed _GradientOffset;
            half _BillboardSize;
            half _Inflate;

            v2f vert (appdata v)
            {
                v2f o;
                //i have no idea what to do
                //but i do know that I need to have the faces face the camera.
                //and i can do that with billboards.
                

                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.uv.xy - 0.5f) * 2.0f;
                float3 viewSpaceUV = mul(float3(tweakedUV, 0.0f), UNITY_MATRIX_MV);
                //float3 scale = unity_ObjectToWorld._m00_m11_m22;
                viewSpaceUV = normalize(viewSpaceUV);

                v.vertex.xyz += viewSpaceUV.xyz * _BillboardSize;
                v.vertex.xyz += v.normal * _Inflate;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o, o.pos);
                //per vertex rimlight, because...
                o.viewDir = WorldSpaceViewDir(v.vertex);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed3 normal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                // sample the texture
                fixed4 gradient = lerp(_Color, _TopColor, saturate(normal.y + _GradientOffset));
                fixed4 col = tex2D(_MainTex, i.uv) * gradient;
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                fixed shadow = LIGHT_ATTENUATION(i);
                fixed lighting = dot(normal, lightDir);
                //reduce lighting contribution here:
                fixed edgeHighlight = 1 - saturate(dot(normal, viewDir));
                edgeHighlight = pow(edgeHighlight, 8) * 0.5;

                lighting = min(saturate(lighting), shadow);
                //lighting = 1 - (1 - lighting) * shadowContrib;
                lighting += edgeHighlight;

                clip(col.a - _Cutoff);
                fixed4 envLighting = col * fixed4(ShadeSH9(float4(normal, 1.0f)), 1.0f);
                
                return col * lighting + envLighting;
            }
            ENDCG
        }

        
        Pass {
            //Cull Off
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
            fixed _Amount;
            float _BillboardSize;
            float _Inflate;

            v2f vert( appdata_base v )
            {
                v2f o;
                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.texcoord.xy - 0.5f) * 2.0f;
                float3 viewSpaceUV = mul(float3(tweakedUV, 0.0f), UNITY_MATRIX_MV);
                //float3 scale = unity_ObjectToWorld._m00_m11_m22;
                viewSpaceUV = normalize(viewSpaceUV);

                v.vertex.xyz += viewSpaceUV.xyz * _BillboardSize;
                v.vertex.xyz += v.normal * _Inflate;
                
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
