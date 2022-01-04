Shader "Unlit/BuiltInShadowMapper"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowOffset ("Float", Range(-1, 1)) = 0.0
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            #include "PCFHelper.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(3, 4)
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ShadowOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            
            float random_from_pos(float2 pos){
                return frac(dot(pos, half2(1.334f, 2.241f + _Time.w * 60 % 1919.3)) * 383.8438);
            }

            float get_random_rotation(float2 pos){
                return random_from_pos(pos) * 6.29;
            }

            float2 rotate_vector(float2 vec, float angle){
                float sinx = sin(angle);
                float cosx = cos(angle);
                return float2(
                    -sinx * vec.y + cosx * vec.x,
                    sinx * vec.x + cosx * vec.y
                );
            }
            float2 _ShadowMapTexture_TexelSize;
            float pcf_sample_shadowmap(float4 shadowCoords){
                //for spots
                //sample the shadow values around
                //and filter it out...
                int sampleCount = 5;
                float averageDepth = 0;
                
                for(int i = -2; i <= 2; i++){
                    for(int j = -2; j <= 2; j++){
                        
                        #if defined (SHADOWS_CUBE)
                            float offset = shadowCoords.z * _ShadowMapTexture_TexelSize.xy / sampleCount * 2048;
                            float brightness = SHADOW_ATTENUATION(shadowCoords.xyz, half4(offset, offset, offset,  0));
                        #else
                            float2 uvOffset = shadowCoords.z * _ShadowMapTexture_TexelSize.xy / sampleCount * 2048;
                            half2 offsetUV = rotate_vector(float2(i, j) * uvOffset, get_random_rotation(shadowCoords.xy));
                            float brightness = SHADOW_ATTENUATION(shadowCoords, half4(offsetUV, 0, 0));

                        #endif
                        
                        averageDepth += brightness;
                    }
                }
                return averageDepth / (sampleCount * sampleCount);
            }


            #define PCF_SAMPLE(x) (pcf_sample_shadowmap(x))

        ENDCG

        Pass
        {
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardBase"
            }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
        

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                fixed shadow = LIGHT_ATTENUATION(i._LightCoord, i._ShadowCoord, float4(0, 0, 0, 0));//SHADOW_ATTEN_OFFSET(i, float4(_ShadowOffset, _ShadowOffset, 0, 0));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return shadow * col;
            }
            ENDCG
        }
        //forward add shadows
        Pass
        {
            Blend One One
            Tags {
                "RenderType"="Opaque" 
                "LightMode"="ForwardAdd"
            }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //#pragma multi_compile_fwdadd
            #pragma multi_compile_fwdadd_fullshadows


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                float fadeout = LIGHT_FADEOUT(i._LightCoord);
                
                #if defined (SHADOWS_CUBE)
                    float4 shadowCoord = float4(i._ShadowCoord.xyz, 0);
                #else
                    float4 shadowCoord = i._ShadowCoord.xyzw;
                #endif

                float shadow = PCF_SAMPLE(shadowCoord);//SHADOW_ATTENUATION(i._ShadowCoord, float4(0, 0, 0, 0));
                shadow *= fadeout;
                //fixed shadow = LIGHT_ATTENUATION(i._LightCoord, i._ShadowCoord, float4(0, 0, 0, 0));//SHADOW_ATTEN_OFFSET(i, float4(_ShadowOffset, _ShadowOffset, 0, 0));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return shadow;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
