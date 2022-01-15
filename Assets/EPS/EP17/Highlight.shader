Shader "Grater/Highlight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 tangent : TANGENT;
                float3 normal : NORMAL;
                float3 binormal : BINORMAL;
                float3 viewDir : TEXCOORD1;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = normalize(UnityObjectToWorldNormal(v.tangent.xyz));
                o.binormal = cross(normalize(o.normal), normalize(o.tangent)) * v.tangent.w;
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                fixed shift = tex2D(_MainTex, i.uv).r - 0.5;
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 tangent = normalize(i.tangent); ///instead of doing this
                //why not cross this with the world space up
                
                fixed3 normal = normalize(i.normal);
                fixed3 binormal = normalize(i.binormal);
                fixed wst = cross(float3(0, 0, 1), normal);
                fixed hlf = normalize(float3(0, 0, 1) + wst);
                //return float4(tangent, 1.0);
                fixed hl = dot(hlf, halfDir);
                return abs(hl);
                return pow(sqrt(1 - hl * hl), 128);
                //return float4(binormal, 0);
                // sample the texture
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return col;
                return float4(viewDir, 1.0);
            }
            ENDCG
        }
    }
}
