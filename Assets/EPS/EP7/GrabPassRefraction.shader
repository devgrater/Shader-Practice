Shader "Unlit/GrabPassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bump Map", 2D) = "bump" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
        _ReflAmount ("Reflection Amount", Range(0, 1)) = 0.5 //half reflective
        _BumpIntensity ("Bump Intensity", Range(0, 1)) = 1.0
        _Distortion ("Distortion", Float) = 1.0
        _Tint ("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _BlurDistance ("Blur Distance", Range(1, 2)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        //grab pass
        GrabPass { "_CameraPass" }
        Pass
        {
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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float4 TtoW0 : TEXCOORD3;
                float4 TtoW1 : TEXCOORD4;
                float4 TtoW2 : TEXCOORD5;
                float3 viewDir : TEXCOORD6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraPass;
            float4 _CameraPass_TexelSize;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            fixed _BumpIntensity;
            fixed _ReflAmount;
            float _Distortion;
            fixed4 _Tint;
            float _BlurDistance;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeGrabScreenPos(o.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpMap);
                UNITY_TRANSFER_FOG(o,o.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //and then..
                fixed3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;
                o.TtoW0 = float4(worldTangent.x, worldBitangent.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBitangent.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBitangent.z, worldNormal.z, worldPos.z);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 box_blur(float2 uv){
                //offset the uv...
                float2 uvOffsetX = (_CameraPass_TexelSize.x, 0);
                float2 uvOffsetY = (0, _CameraPass_TexelSize.y);
                float2 uvBase = uv;
                float4 colorSum = float4(0, 0, 0, 0);
                for(int i = -1; i <= 1; i++){
                    for(int j = -1; j <= 1; j++){
                        uvBase = uv + (i * uvOffsetX + j * uvOffsetY) * _BlurDistance;
                        //using this info, we sample the texture
                        colorSum += tex2D(_CameraPass, uvBase);
                    }
                }
                return colorSum / 9;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                float3 worldPos = float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);

                
                //convert normal from tangent space to world space
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                

                bump = lerp(fixed3(0, 0, 1), bump, _BumpIntensity);
                bump = normalize(half3(
                    dot(i.TtoW0.xyz, bump),
                    dot(i.TtoW1.xyz, bump),
                    dot(i.TtoW2.xyz, bump)
                ));

                float2 offset = bump.xy * _CameraPass_TexelSize * _Distortion;
                
                //compute fresnel


                //using the bump, we can compute reflection
                float4 reflectionDir = float4(reflect(-i.viewDir, bump), 0);

                fixed3 reflCol = texCUBElod(_CubeMap, reflectionDir) * col.rgb;

                fixed3 refrCol = box_blur((i.screenPos.xy + offset) / i.screenPos.w).rgb;//tex2D(_CameraPass, (i.screenPos.xy + offset) / i.screenPos.w).rgb;
                //fixed reflInten = saturate(dot(reflCol, reflCol));
                fixed fresnel = saturate(1 - dot(normalize(i.viewDir), bump));
                fresnel = pow(fresnel, 1);
                float4 finalCol = fixed4(lerp(refrCol, reflCol, _ReflAmount * fresnel), 1);
                finalCol *= _Tint;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return finalCol;
            }
            ENDCG
        }
        
    }
    Fallback "VertexLit"
}
