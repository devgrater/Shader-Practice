Shader "Hidden/SSAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //anything beyond this distance will not be taken into account.
        _SampleDistance ("Sample Distance", Float) = 15.0
        _SampleStep ("Sample Step Distance", Float) = 3.0
        _MaxDepth ("MaxDepth", Range(0, 1)) = 0.5
        _MinDepth ("Minimum Depth", Float) = 0.5

    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
//#pragma exclude_renderers d3d11 gles
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
            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;
            float _SampleDistance;
            float _SampleStep;
            float _MaxDepth;
            float _MinDepth;

            float sampleDepthAt(float2 uv){
                fixed4 poiDepth = tex2D(_CameraDepthTexture, uv);
                //return LinearEyeDepth(poiDepth.r);
                return 1-poiDepth.r;
            }

            float4 sampleNormalAt(float2 uv){
                return (tex2D(_CameraNormalsTexture, uv) - 0.5) * 2;
            }

            float calculateAOContribution(float srcDepth, float3 srcNormal, float sampledDepth, float3 sampledNormal){
                if(srcDepth - sampledDepth <= _MinDepth){
                    //There's no blocking happening.
                    return 1;
                }
                else{
                    return _MaxDepth / (1 + srcDepth - sampledDepth) * max(0.0, dot(srcNormal, sampledNormal));
                }
                
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float2 step = float2(1/_ScreenParams.x,1/_ScreenParams.y);
                

                fixed4 col = tex2D(_MainTex, i.uv);
                //Unpack the normal
                fixed4 normal = (tex2D(_CameraNormalsTexture, i.uv) - 0.5) * 2;

                //Now, if we sample the depth on the uv:
                //Depth of the point of interest
                float poiDepth = sampleDepthAt(i.uv);

                //for(x = -1; x )
                float2 uUV = float2(0, step.y);
                float2 dUV =  float2(0, -step.y);
                float2 lUV = float2(-step.x, 0);
                float2 rUV = float2(step.x, 0);

                //Now lets sample them!
                //One day I'll find a way to automate this
                //But I guess this way its faster
                float depthSum = 0.0;
                for(float stepLength = _SampleStep; stepLength < _SampleDistance; stepLength+=_SampleStep){
                    float2 uUV = i.uv + float2(0, step.y) * stepLength;
                    float2 dUV =  i.uv + float2(0, -step.y) * stepLength;
                    float2 lUV = i.uv + float2(-step.x, 0) * stepLength;
                    float2 rUV = i.uv + float2(step.x, 0) * stepLength;
                    

                    depthSum += 
                    (calculateAOContribution(poiDepth, normal, sampleDepthAt(uUV), sampleNormalAt(uUV)) +
                    calculateAOContribution(poiDepth, normal, sampleDepthAt(dUV), sampleNormalAt(dUV)) +
                    calculateAOContribution(poiDepth, normal, sampleDepthAt(lUV), sampleNormalAt(lUV)) +
                    calculateAOContribution(poiDepth, normal, sampleDepthAt(rUV), sampleNormalAt(rUV))) / 4 / stepLength;
                }




        
                return saturate(depthSum) * col;
            }
            ENDCG
        }
    }
}
