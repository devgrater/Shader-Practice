Shader "Hidden/Custom/Daynight"
{
    HLSLINCLUDE
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        float4 _MainTex_ST;
        float _TimeOfDay;
        float _DaylightContribution;
        float4 _ShadowColor;
        float4 _LightColor;
        float3 _Levels;

        float4 Frag(VaryingsDefault i) : SV_Target
        {
            float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
            float brightness = dot(baseCol.rgb, float3(0.2126f, 0.7152f, 0.0722f));

            //lerp between...
            float grayness = lerp(_Levels.x, _Levels.z, brightness);
            //return grayness;
            float leveledBrightness = lerp(lerp(_Levels.x, _Levels.y, brightness), lerp(_Levels.y, _Levels.z, brightness), brightness);
            //return leveledBrightness;

            brightness = pow(saturate(brightness), _DaylightContribution);
            //return brightness;
            float4 saturatedImage = lerp(brightness, baseCol, leveledBrightness + _TimeOfDay);
            float4 brightImage = baseCol * _LightColor;
            //return saturatedImage;
            float4 shadowCol = leveledBrightness * _ShadowColor;
            return saturate(lerp(shadowCol, brightImage, leveledBrightness));
            return shadowCol;
            return 1 - baseCol;

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
}
