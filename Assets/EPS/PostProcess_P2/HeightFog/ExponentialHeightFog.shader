Shader "Hidden/Custom/ExponentialHeightFog"
{
    HLSLINCLUDE
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"
        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        float4 _MainTex_ST;
        float _Blend;
        float _ScanlineCount;
        float _ChromaAberrationDistance;

        float4x4 unity_CameraInvProjection;

        struct Varyings
        {
            float4 position : SV_Position;
            float2 texcoord : TEXCOORD0;
            float3 ray : TEXCOORD1;
        };

        // Vertex shader that procedurally outputs a full screen triangle
        Varyings Vertex(uint vertexID : SV_VertexID)
        {
            // Render settings
            float far = _ProjectionParams.z;
            float2 orthoSize = unity_OrthoParams.xy;
            float isOrtho = unity_OrthoParams.w; // 0: perspective, 1: orthographic

            // Vertex ID -> clip space vertex position
            float x = (vertexID != 1) ? -1 : 3;
            float y = (vertexID == 2) ? -3 : 1;
            float3 vpos = float3(x, y, 1.0);

            // Perspective: view space vertex position of the far plane
            float3 rayPers = mul(unity_CameraInvProjection, vpos.xyzz * far).xyz;

            // Orthographic: view space vertex position
            float3 rayOrtho = float3(orthoSize * vpos.xy, 0);

            Varyings o;
            o.position = float4(vpos.x, -vpos.y, 1, 1);
            o.texcoord = (vpos.xy + 1) / 2;
            o.ray = lerp(rayPers, rayOrtho, isOrtho);
            return o;
        }

        
        float4 Frag(Varyings i) : SV_Target
        {
            return float4(i.ray.xyz, 1.0f);
            //reconstruct world pos:
            ///float3 viewVector = mul(unity_CameraInvProjection, float4(i.texcoord * 2 - 1, 0, -1));
            //viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
            //float2 UV = i.positionHCS.xy / _ScaledScreenParams.xy;
            //float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
            //return baseCol;// float4(viewVector, 1.0f);

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
