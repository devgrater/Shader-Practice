Shader "Unlit/ApproximateSSS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Smoothness ("Smoothness", 2D) = "white" {} //very smooth
        _Tint ("Tint", Color) = (0.0, 0.0, 0.0, 0.0)
        _BackSurfaceDistortion ("Scatter Distortion (Back)", float) = 1.0
        _FrontSurfaceDistortion ("Scatter Distortion (Front)", float) = 1.0
        _InnerColor ("Inner Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SSIntensity ("SSS Intensity", Range(0, 8)) = 0.5
        

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
                float4 screenPosition : TEXCOORD5;
                float3 normal : NORMAL;
            };

            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize; //welp...
            sampler2D _CameraDepthTexture;
            sampler2D _MainTex;
            sampler2D _Smoothness;
            float4 _MainTex_ST;
            float4 _InnerColor;
            float _BackSurfaceDistortion;
            float _FrontSurfaceDistortion;
            float _SSIntensity;
            float4 _Tint;



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
                o.screenPosition = ComputeScreenPos(o.vertex);
                //o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }


        ENDCG
        /*
        GrabPass{

        }*/


        Pass
        {
            Tags{
                "RenderType" = "Opaque"
                "Queue"="Transparent+1"
                "LightMode"="ForwardBase"
            }
            //for extremely thin surfaces, we can probably run the crysis style
            //because they are thin af
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            fixed4 blur3x3(float blurDistance, fixed2 uv){
                fixed2 xOffset = fixed2(_GrabTexture_TexelSize.x * blurDistance, 0.0f);
                fixed2 yOffset = fixed2(0.0f, _GrabTexture_TexelSize.y * blurDistance);
                //fixed2 uvOffset = _GrabTexture_TexelSize.xy * blurDistance;
                float4 colorSum = 0.0f;
                
                
                for(int x = -2; x <= 2; x++){
                    for(int y = -2; y <= 2; y++){
                        fixed2 newUV = xOffset * x + yOffset * y + uv;
                        colorSum += tex2D(_GrabTexture, newUV);
                        //return colorSum;
                    }
                }
                return colorSum / 25;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                float3 backlitDir = normal * _BackSurfaceDistortion + _WorldSpaceLightPos0.xyz;
                float3 frontlitDir = normal * _FrontSurfaceDistortion - _WorldSpaceLightPos0.xyz;
                float bss = saturate(dot(-backlitDir, viewDir));
                float fss = saturate(dot(-frontlitDir, viewDir));

                float ssSum = bss + fss;
                float lighting = saturate(dot(normal, _WorldSpaceLightPos0.xyz));

                float3 backColor = lerp(_InnerColor.rgb, _LightColor0.rgb, saturate(pow(ssSum, _SSIntensity))) * ssSum;

                float4 baseCol = tex2D(_MainTex, i.uv.xy) * _Tint;
                float roughness = tex2D(_Smoothness, i.uv);

                float fresnel = saturate(dot(normal, viewDir));
                fresnel = 1 - fresnel;
                fresnel = pow(fresnel, 16) * roughness * 0.3;

                
                float depthEncoded = tex2D(_CameraDepthTexture, i.screenPosition.xy / i.screenPosition.w);
                float linearDepth = LinearEyeDepth(depthEncoded);

                float surfaceDepth = i.screenPosition.w;
                float depthDifference = linearDepth - i.screenPosition.w;

                fixed blurAmount = 1 - 1 / max(depthDifference, 0.01);
                blurAmount = saturate(blurAmount);
                blurAmount = blurAmount * blurAmount;
                //float4 colorBehind = blur3x3(blurAmount * 12, i.screenPosition.xy / i.screenPosition.w);
                //return colorBehind;
                //baseCol = lerp(colorBehind, baseCol, saturate(blurAmount));

                float3 unlitCol = baseCol.rgb * _InnerColor.rgb * 0.5f;
                float3 diffuse = lerp(unlitCol, baseCol.rgb, lighting);

                float3 halfDir = normalize(viewDir + _WorldSpaceLightPos0.xyz);
                
                float highlight = saturate(dot(halfDir, normal));
                //float innerhighlight = pow(highlight, 128);
                highlight = pow(highlight, 1024) * 0.5;
                
                //float3 subsurfaceHL = highlight * _InnerColor;


                return float4(backColor + diffuse + ShadeSH9(float4(normal, 1.0f)) * 0.2, 1.0f) + fresnel + highlight;
                //return bss + fss;

                /*
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normalizedViewDir = normalize(i.viewDir);

                float lighting = dot(normal, lightDir);
                float subsurfaceLighting = dot(normalizedViewDir, lightDir);
                return lighting * subsurfaceLighting;*/
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
    Fallback "VertexLit"
}
