Shader "Unlit/GrassInstanced"
{
    Properties
    {
       // _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("边线染色", Color) = (0.0, 0.2, 0.0, 1.0)
        [HDR]_DeepColor ("根部染色", Color) = (0.0, 0.5, 0.1, 1.0)
        //[HDR]_ShallowColor ("顶部染色", Color) = (0.6, 0.8, 0.1, 1.0)
        _GrassThickness ("草叶宽度", Range(0, 1)) = 0.4
        _MinWidth ("草叶最小宽度", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque" 
            "LightMode"="ForwardBase"
        }
        LOD 100

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
            #pragma multi_compile_fwdbase
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
                float4 colorData : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            #if SHADER_TARGET >= 45
                StructuredBuffer<float4> _PositionBuffer;
                StructuredBuffer<float4> _ColorDataBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif

           

            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            //fixed4 _ShallowColor;
            fixed4 _OutlineColor;
            fixed4 _DeepColor;
            float4 _InfluenceBounds;
            fixed _GrassThickness;
            sampler2D _GrassInfluence;
            fixed _MinWidth;
            //fixed2 _HeightControl;
            //fixed4 _GrassBounds;


            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                #if SHADER_TARGET >= 45
                float4 data = _PositionBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                fixed4 colorData = _ColorDataBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];

                    //float rotation = data.w * data.w * _Time.y * 0.5f;
                   // rotate2D(data.xz, rotation);
                   data.y += data.w;

                    unity_ObjectToWorld._11_21_31_41 = float4(max(_GrassThickness * colorData.w, _MinWidth), 0, 0, 0);
                    unity_ObjectToWorld._12_22_32_42 = float4(0, colorData.w + 0.5f, 0, 0);
                    unity_ObjectToWorld._13_23_33_43 = float4(0, 0, max(_GrassThickness * colorData.w, _MinWidth), 0);
                    unity_ObjectToWorld._14_24_34_44 = float4(data.xyz, 1);
                    unity_WorldToObject = unity_ObjectToWorld;
                    unity_WorldToObject._14_24_34 *= -1; //who the fuck does that? what the fuck unity
                    unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
                    unity_WorldToObject._14_24_34 *= unity_WorldToObject._11_22_33;
                #else
                    colorData = fixed4(1.0, 1.0, 1.0, 1.0);
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
                //o.pos = UnityObjectToClipPos(v.vertex.xyz);


                
                //float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                //compute uv:
                fixed relativeU = (worldPos.x - _InfluenceBounds.x) / (_InfluenceBounds.y - _InfluenceBounds.x);
                fixed relativeV = (worldPos.z - _InfluenceBounds.z) / (_InfluenceBounds.w - _InfluenceBounds.z);
                fixed2 relativeUV = fixed2(relativeU, relativeV);

                //sample the influence:
                fixed4 influenceSample = tex2Dlod (_GrassInfluence, fixed4(relativeUV, 0, 0));
                fixed xInfluence = (influenceSample.x - 0.5) * 2;
                fixed zInfluence = (influenceSample.y - 0.5) * 2;
                //fixed hasInfluence = sign(length(fixed2(xInfluence, zInfluence))) != 0;
                fixed3 influenceDir = fixed3(xInfluence, 0.01f, zInfluence);
                influenceDir = normalize(influenceDir) * abs(sign(length(influenceDir)));
                
                
                worldPos.x += sin(worldPos.z / 4 + _Time.b) * v.uv.y * 0.1; 
                worldPos.z += sin(worldPos.x / 3 + _Time.b) * v.uv.y * 0.1; 
                worldPos.xz += influenceDir.xz * v.uv.y * influenceSample.z;
                worldPos.y -= v.uv.y * influenceSample.z * 2.0f;
                //offset y:
               // worldPos.y += _HeightControl.x + heightMapSample.r * _HeightControl.y;
               // worldPos.y -= (1 - splatMap.r) * 10 * randomHeight;
                o.pos = mul(UNITY_MATRIX_VP, worldPos);//UnityObjectToClipPos(v.vertex);
                //v.vertex = mul(unity_WorldToObject, worldPos);
                //v.vertex = mul(unity_WorldToObject, worldPos);

                o.uv = v.uv;//TRANSFORM_TEX(v.uv, _MainTex);
                o.colorData = colorData;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                // apply fog
                
                //procedural outline:
                fixed xDist = step(0.04, min(i.uv.x, 1 - i.uv.x));
                fixed yDist = step(0.01, 1 - i.uv.y);

                fixed lighting = LIGHT_ATTENUATION(i);
                //lighting *= i.uv.y;
                fixed4 lightColor = fixed4(0, 0, 0, 1);
                lightColor.rgb = lerp(_DeepColor, _LightColor0.xyz, lighting);
                lightColor.rgb *= lerp(_DeepColor, 1.0, i.uv.y);


               
                //fixed4 baseColor = lerp(_DeepColor, _ShallowColor, i.uv.y);
                
                //baseColor = lerp(_OutlineColor * baseColor, baseColor, saturate(xDist * yDist));
                //baseColor.rgb *= i.colorData.rgb;
                lightColor.rgb  *= i.colorData.rgb;
                UNITY_APPLY_FOG(i.fogCoord, lightColor);
                return lightColor;//fixed4(i.colorData.rgb, 1.0f);//fixed4(lighting, 1.0f);
                //return fixed4(i.uv.xy, 1.0, 1.0);
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5
            //#pragma multi_compile_instancing
            //#pragma instancing_options procedural:setup
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            fixed _GrassThickness;
            fixed _MinWidth;
            fixed4 _ShallowColor;
            fixed4 _OutlineColor;
            fixed4 _DeepColor;
            float4 _InfluenceBounds;
            sampler2D _GrassInfluence;

            struct v2f {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #if SHADER_TARGET >= 45
                StructuredBuffer<float4> _PositionBuffer;
                StructuredBuffer<float4> _ColorDataBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif

            v2f vert( appdata_base v, uint instanceID : SV_InstanceID )
            {
                #if SHADER_TARGET >= 45
                float4 data = _PositionBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                fixed4 colorData = _ColorDataBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                   data.y += data.w;

                    unity_ObjectToWorld._11_21_31_41 = float4(max(_GrassThickness * colorData.w, _MinWidth), 0, 0, 0);
                    unity_ObjectToWorld._12_22_32_42 = float4(0, colorData.w + 0.5f, 0, 0);
                    unity_ObjectToWorld._13_23_33_43 = float4(0, 0, max(_GrassThickness * colorData.w, _MinWidth), 0);
                    unity_ObjectToWorld._14_24_34_44 = float4(data.xyz, 1);
                    unity_WorldToObject = unity_ObjectToWorld;
                    unity_WorldToObject._14_24_34 *= -1;
                    unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
                    unity_WorldToObject._14_24_34 *= unity_WorldToObject._11_22_33;
                #endif
                v2f o;

                
                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.texcoord.xy - 0.5f);
                float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
                float3 scale = unity_ObjectToWorld._m00_m11_m22;
                viewSpaceUV = normalize(viewSpaceUV * scale);
                //o.pos = UnityObjectToClipPos(v.vertex);
                

                v.vertex.xyz += viewSpaceUV.xyz;
                v.vertex.xyz += v.normal;
                //o.pos = UnityObjectToClipPos(v.vertex.xyz);
                
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                //compute uv:
                fixed relativeU = (worldPos.x - _InfluenceBounds.x) / (_InfluenceBounds.y - _InfluenceBounds.x);
                fixed relativeV = (worldPos.z - _InfluenceBounds.z) / (_InfluenceBounds.w - _InfluenceBounds.z);
                fixed2 relativeUV = fixed2(relativeU, relativeV);

                //sample the influence:
                fixed4 influenceSample = tex2Dlod (_GrassInfluence, fixed4(relativeUV, 0, 0));
                fixed xInfluence = (influenceSample.x - 0.5) * 2;
                fixed zInfluence = (influenceSample.y - 0.5) * 2;
                //fixed hasInfluence = sign(length(fixed2(xInfluence, zInfluence))) != 0;
                fixed3 influenceDir = fixed3(xInfluence, 0.01f, zInfluence);
                influenceDir = normalize(influenceDir) * abs(sign(length(influenceDir)));
                
                
                worldPos.x += sin(worldPos.z / 4 + _Time.b) * v.texcoord.y * 0.1; 
                worldPos.z += sin(worldPos.x / 3 + _Time.b) * v.texcoord.y * 0.1; 
                worldPos.xz += influenceDir.xz * v.texcoord.y * influenceSample.z;
                worldPos.y -= v.texcoord.y * influenceSample.z * 2.0f;
                //offset y:
               // worldPos.y += _HeightControl.x + heightMapSample.r * _HeightControl.y;
               // worldPos.y -= (1 - splatMap.r) * 10 * randomHeight;
                o.pos = mul(UNITY_MATRIX_VP, worldPos);//UnityObjectToClipPos(v.vertex);
                v.vertex = mul(unity_WorldToObject, worldPos);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

    }
}
