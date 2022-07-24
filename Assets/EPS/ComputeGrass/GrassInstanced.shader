Shader "Unlit/GrassInstanced"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0.0, 0.2, 0.0, 1.0)
        _DeepColor ("Deep Color", Color) = (0.0, 0.5, 0.1, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.6, 0.8, 0.1, 1.0)
        _GrassThickness ("Grass Thickness", Range(0, 1)) = 0.4
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque" 
        }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma target 4.5
            //#pragma multi_compile_instancing
            #pragma instancing_options procedural:setup
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"

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
                float4 pos : SV_POSITION;

            };

            #if SHADER_TARGET >= 45
                StructuredBuffer<float4> _PositionBuffer;
                StructuredBuffer<float4> _ColorDataBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif

           

            sampler2D _MainTex;
            sampler2D _SplatMap;
            float4 _MainTex_ST;
            fixed4 _ShallowColor;
            fixed4 _OutlineColor;
            fixed4 _DeepColor;
            float4 _InfluenceBounds;
            fixed _GrassThickness;
            sampler2D _GrassInfluence;
            sampler2D _HeightMap;
            fixed2 _HeightControl;
            fixed4 _GrassBounds;


            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                #if SHADER_TARGET >= 45
                float4 data = _PositionBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                float4 colorData = _ColorDataBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];

                    //float rotation = data.w * data.w * _Time.y * 0.5f;
                   // rotate2D(data.xz, rotation);

                    unity_ObjectToWorld._11_21_31_41 = float4(_GrassThickness, 0, 0, 0);
                    unity_ObjectToWorld._12_22_32_42 = float4(0, colorData.w + 0.5f, 0, 0);
                    unity_ObjectToWorld._13_23_33_43 = float4(0, 0, _GrassThickness, 0);
                    unity_ObjectToWorld._14_24_34_44 = float4(data.xyz, 1);
                    unity_WorldToObject = unity_ObjectToWorld;
                    unity_WorldToObject._14_24_34 *= -1;
                    unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
                #endif

                v2f o;

                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.uv.xy - 0.5f);
                float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
                float3 scale = unity_ObjectToWorld._m00_m11_m22;
                viewSpaceUV = normalize(viewSpaceUV * scale);
                //o.pos = UnityObjectToClipPos(v.vertex);
                

                v.vertex.xyz += viewSpaceUV.xyz;
                v.vertex.xyz += v.normal;
                o.pos = UnityObjectToClipPos(v.vertex.xyz);


                
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                //compute uv:
                fixed relativeU = (worldPos.x - _InfluenceBounds.x) / (_InfluenceBounds.y - _InfluenceBounds.x);
                fixed relativeV = (worldPos.z - _InfluenceBounds.z) / (_InfluenceBounds.w - _InfluenceBounds.z);
                fixed2 relativeUV = fixed2(relativeU, relativeV);

                //sample the influence:
                fixed4 influenceSample = tex2Dlod (_GrassInfluence, fixed4(relativeUV, 0, 0));
                fixed grassRelativeU = (worldPos.x - _GrassBounds.x) / (_GrassBounds.y - _GrassBounds.x);
                fixed grassRelativeV = (worldPos.z - _GrassBounds.z) / (_GrassBounds.w - _GrassBounds.z);
                fixed xInfluence = (influenceSample.x - 0.5) * 2;
                fixed zInfluence = (influenceSample.y - 0.5) * 2;
                //fixed hasInfluence = sign(length(fixed2(xInfluence, zInfluence))) != 0;
                fixed3 influenceDir = fixed3(xInfluence, 0.01f, zInfluence);
                influenceDir = normalize(influenceDir) * abs(sign(length(influenceDir)));
                
                /*
                worldPos.x += sin(worldPos.z / 4 + _Time.b) * v.uv.y * 0.1; 
                worldPos.z += sin(worldPos.x / 3 + _Time.b) * v.uv.y * 0.1; 
                worldPos.xz += influenceDir.xz * v.uv.y * influenceSample.z;
                worldPos.y -= v.uv.y * influenceSample.z * 2.0f;*/
                //offset y:
               // worldPos.y += _HeightControl.x + heightMapSample.r * _HeightControl.y;
               // worldPos.y -= (1 - splatMap.r) * 10 * randomHeight;
                o.pos = mul(UNITY_MATRIX_VP, worldPos);//UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                
                //procedural outline:
                fixed xDist = step(0.04, min(i.uv.x, 1 - i.uv.x));
                fixed yDist = step(0.01, 1 - i.uv.y);


                fixed4 baseColor = lerp(_DeepColor, _ShallowColor, i.uv.y);
                baseColor = lerp(_OutlineColor * baseColor, baseColor, saturate(xDist * yDist));
                UNITY_APPLY_FOG(i.fogCoord, baseColor);
                return baseColor;
                //return fixed4(i.uv.xy, 1.0, 1.0);
            }
            ENDCG
        }

    }
}
