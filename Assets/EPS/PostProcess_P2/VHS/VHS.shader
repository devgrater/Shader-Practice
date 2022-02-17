Shader "Hidden/Custom/VHS Effect"
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
            float2 offset = float2(_ChromaAberrationDistance, 0.0f);
            float4 rChannel = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - offset);
            float4 gChannel = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
            float4 bChannel = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + offset);

            float4 color = float4(rChannel.r, gChannel.g, bChannel.b, gChannel.a);

            float4 prevR = SAMPLE_TEXTURE2D(_PreviousFrame, sampler_MainTex, i.texcoord - offset);
            float4 prevG = SAMPLE_TEXTURE2D(_PreviousFrame, sampler_MainTex, i.texcoord);
            float4 prevB = SAMPLE_TEXTURE2D(_PreviousFrame, sampler_MainTex, i.texcoord + offset);
            float4 prevColor = float4(prevR.r, prevG.g, prevB.b, prevG.a);
            

            
            float randomVal = random_from_pos(float3(i.texcoord, (_Time.r % 10) + i.texcoord.x));
            //return randomVal;
            //return randomVal * sin((_Time.g + i.texcoord.y) * (_Time.b % 30));

            float noiseWeight = sin((frac(_Time.g * 4) + i.texcoord.y) * 3 * (_Time.b % 3));
            float noiseWeight2 = cos((frac(_Time.b * 2) + i.texcoord.y * 4));
            noiseWeight *= noiseWeight2;
            //return randomVal * noiseWeight;
            



            //return _ChromaAberrationDistance;
            // Compute the luminance for the current pixel
            //float luminance = dot(color.rgb, float3(0.2126729, 0.7151522, 0.0721750));
            //color.rgb = lerp(color.rgb, luminance.xxx, 0.8f);
            //interleave:
            float screenColor = sin(i.texcoord.y * _ScanlineCount * 3.1415926);
            screenColor = screenColor > 0 ? 1 : 0;
            float4 finalColor = lerp(color, prevColor, screenColor);
            //return finalColor;
            return lerp(finalColor, randomVal.rrrr, (noiseWeight * randomVal > 0.5) * 0.3);

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
