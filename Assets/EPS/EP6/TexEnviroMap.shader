Shader "Unlit/TexEnviroMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cubemap ("Cubemap", Cube) = "white" {}
        _IOR ("Index of Refraction", Range(0, 1)) = 0.3
        [IntRange]_FresnelIntensity ("Fresnel Intensity", Range(1, 16)) = 1
        _SchlickIntensity ("Schlick Fresnel Intensity", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : NORMAL;
                float3 worldViewDir : TEXCOORD3;
                float3 reflDir : TEXCOORD4;
                float3 refrDir : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _Cubemap;
            float _IOR;
            float _FresnelIntensity;
            float _SchlickIntensity;

            fixed schlick_fresnel(float3 normal, float3 view){

                fixed powered_dot = pow(1 - dot(normalize(normal), normalize(view)), _FresnelIntensity);
                return _SchlickIntensity + (1 - _SchlickIntensity) * powered_dot;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.reflDir = reflect(-o.worldViewDir, o.worldNormal);
                o.refrDir = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _IOR);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed fresnel = 1 - dot(normalize(i.worldViewDir), normalize(i.worldNormal));
                //fresnel = pow(fresnel, _FresnelIntensity);
                fixed fresnel = schlick_fresnel(i.worldNormal, i.worldViewDir);
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 reflCol = texCUBElod(_Cubemap, float4(i.reflDir, 0.0f));
                fixed4 refrCol = texCUBElod(_Cubemap, float4(i.refrDir, 0.0f));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return lerp(refrCol, reflCol, fresnel);
            }
            ENDCG
        }
    }
}
