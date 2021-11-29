Shader "Unlit/Billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VerticalBillboard ("Vertical Billboarding", Range(0, 1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _VerticalBillboard;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                float3 center = float3(0, 0, 0);
                float3 viewerPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                
                float3 normalVector = viewerPos;
                normalVector.y *= _VerticalBillboard;
                normalVector = normalize(normalVector);

                float3 upDir = abs(normalVector.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalVector));
                upDir = normalize(cross(normalVector, rightDir));

                float3 centerOffset = v.vertex.xyz; 
                float3 rotatedLocal = rightDir * centerOffset.x + upDir * centerOffset.y + normalVector * centerOffset.z;
                o.vertex = UnityObjectToClipPos(rotatedLocal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
