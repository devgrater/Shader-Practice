Shader "Unlit/CustomPBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness ("Metallic", Range(0, 1)) = 1.0
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
            #define PI 3.1415926

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
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Roughness;
            //float3 _WorldSpaceLightPos0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float3 getRandomDirection(){
                return float3(0, 0, 0);
            }

            float3 monteCarloEstimate(float2 uv, float3 normal, float3 lightDir, float3 viewDir){
                int steps = 256;
                fixed dW = 1.0 / steps;
                float sum = 0.0f;
                for(int i = 0; i < steps; i++){
                    //get a random direction from the uv,
                    float3 randomDir = getRandomDirection();
                    //do something...
                    //well, why not just sample a random direction?
                    //you can easily do that from the given uv direction...
                    //and just pick a random direction to sample in
                    //sum += fr() * l(normal, lightDir) * dot(normal, randomDir);
                }
                sum *= dW;
                return float3(0, 0, 0);
            }

            float l(float3 normal, float3 lightDir){
                //we don't know what this will return yet.
                return dot(normal, lightDir);
            }
            
            float3 fr(fixed kd, float3 surfaceColor){
                fixed ks = 1.0 - kd;
                //return surfaceColor * kd / PI + ks * cook_torrace();
                return 0;
            }

            float3 cook_torrace(){
                
            }

            float dfg_d(float normal, float halfVector){
                float roughnessSquared = _Roughness * _Roughness;
            }

            float schlick_ggx(){

            }

            float schlick_fresnel(){

            }

            fixed4 frag (v2f i) : SV_Target
            {
                //so, compute ks and kd
                //s -> scatter,
                //d -> diffuse
                float ks = _Roughness;
                float kd = 1.0 - ks;
                float3 halfVector = normalize(normalize(i.viewDir) + normalize(_WorldSpaceLightPos0));

                //well, why not?
                //if you are summing stuff up anyways, why not just do it here too?


                float res = saturate(dot(i.normal, normalize(halfVector)));
                float phong = saturate(dot(normalize(i.normal), normalize(_WorldSpaceLightPos0)));
                res = pow(res, 128);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return res + phong;//float4(halfVector, 1);
            }
            ENDCG
        }
    }
}
