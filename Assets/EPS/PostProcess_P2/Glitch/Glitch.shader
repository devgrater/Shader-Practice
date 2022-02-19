Shader "Hidden/Custom/Glitch Effect"
{
    HLSLINCLUDE
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        TEXTURE2D_SAMPLER2D(_PreviousFrame, sampler_PreviousFrame);
        float4 _MainTex_ST;
        float _Blend;
        float _ScanlineCount;
        float _ChromaAberrationDistance;

        static const float3 random_vector = float3(1.334f, 2.241f, 3.919f);

        float random_from_pos(float3 pos){
            return frac(dot(pos, random_vector) * 383.8438 + (_Time.g % 10));
        }

        float4 Frag(VaryingsDefault i) : SV_Target
        {
            
            float noiseWeight = sin((frac(_Time.r * 16) + i.texcoord.y) * 2 * (_Time.r % 2));
            float noiseWeight2 = cos((frac(_Time.r * 5) + i.texcoord.y * 8));
            noiseWeight *= noiseWeight2;
            noiseWeight = noiseWeight + random_from_pos(float3(i.texcoord.yy * 0.001, 0.0));
            float offsetAmount = random_from_pos(float3(i.texcoord.xy * 0.001 + _Time.rr % 5, 0.0f));
            float2 offset = (abs(noiseWeight) > 0.8f) * float2((noiseWeight - 0.5) * 2 * offsetAmount, 0.0f);
            float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + offset);
            return baseCol;

        }
    ENDHLSL
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM
                #pragma vertex VertDefault
                #pragma fragment Frag
            ENDHLSL
        }
    }
    /*
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
        }
    }*/
}
