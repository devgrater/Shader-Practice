Shader "Unlit/ApproximateSSS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        

    }
    SubShader
    {
        CGINCLUDE 

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

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
                float4 screenPos : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 viewDir : TEXCOORD4;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex); //welp.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }


        ENDCG
        Pass
        {
            //for extremely thin surfaces, we can probably run the crysis style
            //because they are thin af
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.normal);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normalizedViewDir = normalize(i.viewDir);

                float lighting = dot(normal, lightDir);
                float subsurfaceLighting = dot(normalizedViewDir, lightDir);
                return lighting * subsurfaceLighting;
                //return float4(i.uv, i.screenPos.w, 1.0f);
            }
            ENDCG
        }
    /*
        Pass
        {
            Cull Front
            //regardless lets just get a depth texture....
            //xy for the uv, z for the depth
            //this way we can probably recreate stuff...
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.uv, i.screenPos.w, 1.0f);
            }
            ENDCG
        }

        GrabPass { "_ScreenInfoPass" }
        
        
        Pass
        {
            Name "Pre-SSS-Render"
            Cull Front
            Tags { "RenderType"="Opaque" }
            LOD 100
            CGPROGRAM

            sampler2D _ScreenInfoPass;
            float4 _ScreenInfoPass_TexelSize;
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            fixed isOccluded(float3 worldPos, float depth){
                float3 eyeSpacePos = mul(UNITY_MATRIX_V, float4(worldPos, 1.0f));
                return eyeSpacePos > depth;
            }

            fixed4 frag (v2f i) : SV_Target
            {


                
                //how deep is this?
                //ambient occlusion..?
                //float3 worldPos = _WorldSpaceCameraPos.xyz + i.viewDir * i.screenPos.w;

                float3 worldPos = i.worldPos; //and then, using the normals, to create a few sample points.

                return float4(i.worldPos, 1.0f);

                ///pick a few random positions, i suppose?
                //first lets reconstruct world pos.
                return 1 / i.screenPos.w;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog



                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }*/
        /*
        GrabPass { "_BackfaceDepthTexture" }
        Pass
        {
            CGPROGRAM 
                sampler2D _BackfaceDepthTexture;
                float4 _BackfaceDepthTexture_TexelSize;

                #pragma vertex vert
                #pragma fragment frag
                // make fog work
                #pragma multi_compile_fog

                float blurScreenDepth(sampler2D screenSampler, fixed2 uv, float2 texelSize){
                    float2 uvX = float2(texelSize.x, 0);
                    float2 uvY = float2(0, texelSize.y);
                    float screenDepthSum = 0.0f;
                    for(int x = -2; x <= 2; x++){
                        for(int y = -2; y <= 2; y++){
                            float2 nudgeUV = uvX * x + uvY * y;
                            screenDepthSum += tex2D(screenSampler, uv + nudgeUV * 1).r;
                        }
                    }
                    return screenDepthSum / 25.0f;
                }

                fixed4 frag (v2f i) : SV_Target
                {
                    //welp.
                    fixed2 screenUV = i.screenPos.xy / i.screenPos.w;
                    //hey!
                    //return float4(_BackfaceDepthTexture_TexelSize.zw, 0, 1);
                    //lets blur this out!

                    //return 1 / (i.screenPos.w - tex2D(_BackfaceDepthTexture, screenUV));

                    float blurredDepth = blurScreenDepth(_BackfaceDepthTexture, screenUV, _BackfaceDepthTexture_TexelSize.xy);
                    float depthDiff = 1 / i.screenPos.w - 1 / blurredDepth;
                    return exp(i.screenPos.w - blurredDepth);


                    //how deep is this?
                    return 1 / i.screenPos.w;
                    // sample the texture
                    fixed4 col = tex2D(_MainTex, i.uv);
                    // apply fog



                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                }
            ENDCG
        }*/
    }
}
