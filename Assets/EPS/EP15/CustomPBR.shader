Shader "Unlit/CustomPBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness ("Roughness", Range(0, 1)) = 1.0
        _Metallic ("Metallic", Range(0, 1)) = 1.0
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
            fixed _Roughness;
            fixed _Metallic;
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

            float dfg_d(float normal, float halfVector, float roughness){
                fixed alpha2 = roughness * roughness;
                fixed nDotH2 = max(dot(normal, halfVector), 0.0);
                nDotH2 *= nDotH2;
                float denom = nDotH2 * (alpha2 - 1) + 1;
                denom = denom * denom * PI;
                return alpha2 / denom;
            }

            float3 dfg_f(fixed3 normal, fixed3 viewDir, float3 f0){
                fixed cosTheta = saturate(dot(normal, viewDir));
                return (f0) + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
            }
        
            float dfg_g(float normal, float halfVector){
                float roughnessSquared = _Roughness * _Roughness;
            }

            float schlick_ggx(float3 n, float3 dir, float3 k){
                fixed nDotDir = saturate(dot(n, dir));
                return nDotDir / (nDotDir * (1.0 - k) + k);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                ///////////// SAMPLING TEXTURES ////////////////
                fixed4 col = tex2D(_MainTex, i.uv);

                ///////////// BASE COMPUTATIONS /////////////////
                fixed3 worldNormal = normalize(i.normal);
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0);
                fixed3 halfVector = normalize(viewDir + lightDir);

                fixed3 f0 = fixed3(0.04, 0.04, 0.04);
                f0 = lerp(f0, col, _Metallic);
                

                ///////////// UNITY OPERATIONS ///////////////////
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return saturate(dot(halfVector, worldNormal));
                //return dfg_d(worldNormal, halfVector, _Roughness);
                //return dot(worldNormal, viewDir);
                return float4(dfg_f(worldNormal, viewDir, f0), 1);
                //return float4(halfVector, 1);
            }
            ENDCG
        }
    }
}
