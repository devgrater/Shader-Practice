Shader "Grater/FakeInterior"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RoomDepth ("Room Depth", Range(0, 4)) = 0.25
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
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"
            #include "UnityImageBasedLighting.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                /////////// OBJECT SPACE STUFF FOR PLANE TRACING /////////////
                float4 objectSpaceVertex : TEXCOORD2;
                float3 objectSpaceViewDir : TEXCOORD3;
                float3 objectSpaceCamPos : TEXCOORD4;
                float3 objectSpaceNormal : NORMAL;
                float3 objectSpaceTangent : TANGENT;
                float3 objectSpaceBinormal : BINORMAL;
                float3 worldSpaceNormal : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _RoomDepth;
            

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //some of them are just constant!
                //constant, you hear me?
                o.objectSpaceCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.objectSpaceViewDir = ObjSpaceViewDir(v.vertex); //don't normalize first! otherwise the interpolation goes wrong
                o.objectSpaceVertex = v.vertex;
                o.objectSpaceNormal = v.normal;
                //mainly we need tangent and binormal to offset stuff..
                o.objectSpaceTangent = v.tangent;
                o.objectSpaceBinormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                o.worldSpaceNormal = UnityObjectToWorldNormal(v.normal);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 trace_backplane(float3 vertexPos, fixed3 normal, float3 camPos, fixed3 viewDir){
                //using the view direciton, dot with the normal:
                float offsetDirection = dot(viewDir, normal);
                vertexPos += _RoomDepth * normal;
                return vertexPos;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.objectSpaceNormal);
                fixed3 viewDir = normalize(i.objectSpaceViewDir);
                //trace backplane:

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //float3 backplanePos = trace_backplane(i.objectSpaceVertex, normal, i.objectSpaceCamPos, viewDir);
                //once we have this position...
                //we need to compute how much uv has been moved.

                float realPlaneDistance = i.objectSpaceCamPos - i.objectSpaceVertex;
                float fakePlaneDistance = realPlaneDistance + _RoomDepth;

                float tangentOffset = _RoomDepth * dot(viewDir, i.objectSpaceTangent);
                float binormalOffset = _RoomDepth * dot(viewDir, i.objectSpaceBinormal);

                float2 uv = i.uv - float2(tangentOffset, binormalOffset) / dot(normal, viewDir);
                float3 objectSpaceLightPos = mul(unity_WorldToObject, float4(_WorldSpaceLightPos0.xyz, 0)).xyz;
                objectSpaceLightPos = normalize(objectSpaceLightPos);

                fixed atten = saturate(dot(normal, objectSpaceLightPos));
                atten = ((atten + 1.0) * 0.5);
                atten *= atten;
                fixed3 lighting = atten * _LightColor0.rgb;
                half3 indirectColor = ShadeSH9(normalize(float4(i.worldSpaceNormal, 1)));
                col = tex2D(_MainTex, uv);
                col.rgb *= lighting + indirectColor;
                //transform uv to the correct scale...
                //return float4(uv, 0, 1);

                return float4(indirectColor, 1.0);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
