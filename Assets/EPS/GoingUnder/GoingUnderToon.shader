Shader "Unlit/GoingUnderToon"
{
    Properties
    {
        _MainTex ("Light Texture", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        _GradientAmount ("Gradient Amount", Float) = 0.5
        [HDR]_BrightColor ("Bright Color", Color) = (0.5, 0.5, 0.5, 1)
        _TopHeight ("Top Height", Float) = 0.5
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
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                fixed3 normal : NORMAL;
                float3 worldPos : TEXCOORD2;
                float3 rootPos : TEXCOORD3;
                LIGHTING_COORDS(5, 6)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowTex;
            float _GradientAmount;
            half4 _BrightColor;
            float _TopHeight;
            sampler2D _NoiseTex;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.rootPos = mul(unity_ObjectToWorld, float4(0.0f, _TopHeight, 0.0f, 1.0f)).xyz;
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 lightCol = tex2D(_MainTex, i.uv);
                fixed4 shadowCol = tex2D(_ShadowTex, i.uv);
                fixed noiseCol = tex2D(_NoiseTex, i.uv * 16);
                fixed3 normal = normalize(i.normal);

                float height = i.worldPos.y - i.rootPos.y;
                // apply fog
                fixed lighting = dot(normal, _WorldSpaceLightPos0.xyz);
                fixed shadow = LIGHT_ATTENUATION(i);
                lighting = saturate(lighting);
                lighting = min(lighting, shadow);
                lighting = lighting + (1 - noiseCol.r) * 0.3f;//smoothstep(0.2f, 0.5f, lighting + (1 - noiseCol.r) * 0.3f);
                lighting = smoothstep(0.3, 0.8, lighting);
                fixed4 col = lerp(shadowCol, lightCol, lighting);
                float gradientVal = 1 - exp(height * _GradientAmount);
                //return gradientVal;
                gradientVal = saturate(gradientVal);
                fixed4 tintedCol = col * _BrightColor;
                //fixed4 finalCol = col;
                fixed4 finalCol = lerp(col, tintedCol, gradientVal);
                //return lighting;
                UNITY_APPLY_FOG(i.fogCoord, finalCol);
                return finalCol;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
