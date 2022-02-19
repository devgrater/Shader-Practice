Shader "Hidden/TerrainEngine/Details/BillboardWavingDoublePass"
{
    Properties
    {
        _WavingTint ("Fade Color", Color) = (.7,.6,.5, 0)
        _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
        _WaveAndDistance ("Wave and distance", Vector) = (12, 3.6, 1, 1)
        _Cutoff ("Cutoff", float) = 0.5
        _ShadowColor ("Shadow Color", Color) = (0.373, 0.427, 0.471,1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        //AlphaToMask On
        ZWrite On
        ZTest LEqual
        //ColorMask 0
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "TerrainEngine.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            float4 _ShadowColor;
            uniform float4 _LightColor0; //From UnityCG

            v2f vert (appdata_full v)
            {
                v2f o;
                WavingGrassBillboardVert (v);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.color = v.color;
                //o.color.rgb *= ShadeVertexLights (v.vertex, v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;
                col.a = col.a * (i.uv.y);
                float NdotL = dot(_WorldSpaceLightPos0, normalize(i.viewDir));
                //float lightStrength = smoothstep(0.00, 0.01, NdotL);
                float lightStrength = 1;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip (col.a - 0.1);
                return col * lerp(_ShadowColor, _LightColor0, lightStrength) *(1+unity_AmbientSky);
            }
            ENDCG
        }
    }
}
