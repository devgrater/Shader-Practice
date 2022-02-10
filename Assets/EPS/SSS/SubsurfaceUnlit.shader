Shader "Unlit/SubsurfaceUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SSLookup ("SSS Lookup Table", 2D) = "white" {} //literally nothing!
        _Color ("Face Tone", Color) = (0.7, 0.2, 0.2, 0.0)
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

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityImageBasedLighting.cginc"

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
                float3 viewDir : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _SSLookup;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normalizedViewDir = normalize(i.viewDir);
                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed nDotL = dot(lightDir, normal);
                nDotL = (nDotL + 1.0f) * 0.5f;
                fixed fresnel = 1 - saturate(dot(normalizedViewDir, normal));
                fresnel = 0.0f;//pow(fresnel, 8.0);

                float3 deltaNormal = length(fwidth(normal));
                float3 deltaPos = length(fwidth(i.worldPos));

                float oneOverR = deltaNormal / deltaPos;
                //lookup...
                float4 lookupValue = tex2D(_SSLookup, fixed2(saturate(nDotL + fresnel), oneOverR));
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed3 envCol = ShadeSH9(float4(normal, 1.0f));
                fixed4 outCol = lookupValue * col * _Color;
                //outCol.rgb += envCol * 0.4;
                return outCol;//lookupValue * col * _Color;

                // sample the texture
                /*
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;*/
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
