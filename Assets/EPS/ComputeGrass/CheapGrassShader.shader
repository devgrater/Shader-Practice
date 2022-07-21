Shader "Unlit/CheapGrass"
{
    Properties
    {
        _GrassInfluence ("草地压弯（未使用)", 2D) = "white" {}
        _OutlineColor ("边线颜色", Color) = (0.0, 0.2, 0.0, 1.0)
        _DeepColor ("下部颜色", Color) = (0.0, 0.5, 0.1, 1.0)
        _ShallowColor ("上部颜色", Color) = (0.6, 0.8, 0.1, 1.0)
        _ShadowColor ("阴影颜色", Color) = (0.05, 0.2, 0.05, 1.0)
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
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
            #pragma multi_compile_fwdbase
            //#pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(2, 3)
                float4 pos : SV_POSITION;
            };
           

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ShallowColor;
            fixed4 _OutlineColor;
            fixed4 _DeepColor;
            fixed4 _ShadowColor;
            float4 _InfluenceBounds;
            sampler2D _GrassInfluence;


            v2f vert (appdata v)
            {
                v2f o;
                /*
                float3 centerOffset = v.vertex.xyz; 
                float2 tweakedUV = (v.uv.xy - 0.5f);
                float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
                float3 scale = unity_ObjectToWorld._m00_m11_m22;
                viewSpaceUV = normalize(viewSpaceUV * scale);
                //o.pos = UnityObjectToClipPos(v.vertex);
                

                v.vertex.xyz += viewSpaceUV.xyz;
                v.vertex.xyz += v.normal;*/
                //o.vertex = UnityObjectToClipPos(v.vertex);


                
                float4 worldPos = mul(unity_ObjectToWorld, v.pos);
                //compute uv:
                fixed relativeU = (worldPos.x - _InfluenceBounds.x) / (_InfluenceBounds.y - _InfluenceBounds.x);
                fixed relativeV = (worldPos.z - _InfluenceBounds.z) / (_InfluenceBounds.w - _InfluenceBounds.z);
                fixed2 relativeUV = fixed2(relativeU, relativeV);

                //sample the influence:
                //fixed4 influenceSample = tex2Dlod (_GrassInfluence, fixed4(relativeUV, 0, 0));
                //fixed xInfluence = (influenceSample.x - 0.5) * 2;
                //fixed zInfluence = (influenceSample.y - 0.5) * 2;
                //fixed hasInfluence = sign(length(fixed2(xInfluence, zInfluence))) != 0;
                //fixed3 influenceDir = fixed3(xInfluence, 0.01f, zInfluence);
                //influenceDir = normalize(influenceDir) * abs(sign(length(influenceDir)));

                worldPos.x += sin(worldPos.z / 4 + _Time.b) * v.uv.y * 0.1; 
                worldPos.z += sin(worldPos.x / 3 + _Time.b) * v.uv.y * 0.1; 

                fixed3 objectPos = mul(unity_WorldToObject, fixed4(worldPos.xyz, 1.0f));

                //worldPos.xz += influenceDir.xz * v.uv.y * influenceSample.z;
                //worldPos.y -= v.uv.y * influenceSample.z * 2.0f;
                o.pos = mul(UNITY_MATRIX_VP, worldPos);//UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                #if defined (SHADOWS_SCREEN)
                    #if defined(UNITY_NO_SCREENSPACE_SHADOWS)
                        o._ShadowCoord = mul(unity_WorldToShadow[0], mul(unity_ObjectToWorld, fixed4(0, 0, 0, 1)));
                    #else
                        o._ShadowCoord = ComputeScreenPos(UnityObjectToClipPos(fixed4(objectPos.x, 0,objectPos.z, 1)));
                    //return i._ShadowCoord;
                    #endif
                #endif
                //o._ShadowCoord = mul(unity_WorldToShadow[0], mul(unity_ObjectToWorld, fixed4(0, 0, 0, 1)));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //procedural outline:
                fixed xDist = step(0.04, min(i.uv.x, 1 - i.uv.x));
                fixed yDist = step(0.01, 1 - i.uv.y);

                fixed4 baseColor = lerp(_DeepColor, _ShallowColor, i.uv.y);
                
                fixed lighting = LIGHT_ATTENUATION(i);


                //return lighting;
                fixed outline = saturate(xDist * yDist);
                outline = lerp(outline, 1.0, 1 - i.uv.y);
                baseColor = lerp(_OutlineColor * baseColor, baseColor, outline);
                baseColor *= lerp(_ShadowColor, 1.0, lighting);

                return baseColor;
                //return fixed4(i.uv.xy, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
