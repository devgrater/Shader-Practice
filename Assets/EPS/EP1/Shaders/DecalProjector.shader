Shader "Unlit/DecalProjector"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Splash Color", Color) = (1, 0, 0, 1)
    }
    SubShader
    {
        Tags {
             "RenderType"="Opaque" 
             "Queue"="Geometry+1"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest Off
        Cull Off
        ZWrite Off
        LOD 100

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float4 screenPosition : TEXCOORD4;
                float4 objectSpaceVertex : TEXCOORD5;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.objectSpaceVertex = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //what do we need:
                //1. world pos of the pixel
                float3 cameraDirection = i.viewDir;

                fixed4 screenDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition));
                float linearEyeDepth = LinearEyeDepth(screenDepth);
                //with depth, we can compute world pos?
                float3 pixelWorldPos = cameraDirection / i.screenPosition.w * linearEyeDepth - _WorldSpaceCameraPos;

                //inverse project to object space:
                float3 objectSpacePos = mul(unity_WorldToObject, pixelWorldPos);
                objectSpacePos.xz -= mul(unity_WorldToObject, float4(0, 0, 0, 1)).xz;
            
                float4 sampledCol = tex2D(_MainTex, objectSpacePos.xz + 0.5);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //if(objectSpacePos.x > 1 || objectSpacePos.x < 0 || objectSpacePos.z > 1 || objectSpacePos.z < 0){
                //    clip(1.0 - objectSpacePos.x - 1.0);
                //}

                float clip_amount = min(0.5 - objectSpacePos.x * objectSpacePos.x, 0.5 - objectSpacePos.z * objectSpacePos.z);
                
                clip(clip_amount - (1 - sampledCol.a));

                return sampledCol * _Color;
            }
            ENDCG
        }
    }
}
