Shader "Unlit/SimpleGrass"
{
    Properties
    {
        _GrassInfluence ("Grass Influence", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0.0, 0.2, 0.0, 1.0)
        _DeepColor ("Deep Color", Color) = (0.0, 0.5, 0.1, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.6, 0.8, 0.1, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //#pragma multi_compile_instancing
            #include "UnityCG.cginc"

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
            };
           

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ShallowColor;
            fixed4 _OutlineColor;
            fixed4 _DeepColor;
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


                
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                //compute uv:
                fixed relativeU = (worldPos.x - _InfluenceBounds.x) / (_InfluenceBounds.y - _InfluenceBounds.x);
                fixed relativeV = (worldPos.z - _InfluenceBounds.z) / (_InfluenceBounds.w - _InfluenceBounds.z);
                fixed2 relativeUV = fixed2(relativeU, relativeV);

                //sample the influence:
                /*fixed4 influenceSample = tex2Dlod (_GrassInfluence, fixed4(relativeUV, 0, 0));
                fixed xInfluence = (influenceSample.x - 0.5) * 2;
                fixed zInfluence = (influenceSample.y - 0.5) * 2;
                //fixed hasInfluence = sign(length(fixed2(xInfluence, zInfluence))) != 0;
                fixed3 influenceDir = fixed3(xInfluence, 0.01f, zInfluence);
                influenceDir = normalize(influenceDir) * abs(sign(length(influenceDir)));*/

                worldPos.x += sin(worldPos.z / 4 + _Time.b) * v.uv.y * 0.1; 
                worldPos.z += sin(worldPos.x / 3 + _Time.b) * v.uv.y * 0.1; 

                //worldPos.xz += influenceDir.xz * v.uv.y * influenceSample.z;
                //worldPos.y -= v.uv.y * influenceSample.z * 2.0f;
                o.vertex = mul(UNITY_MATRIX_VP, worldPos);//UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
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
                baseColor = lerp(_OutlineColor * baseColor, baseColor, saturate(xDist * yDist));
                return baseColor;
                //return fixed4(i.uv.xy, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
