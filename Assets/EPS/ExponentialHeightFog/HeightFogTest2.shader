Shader "MyDemo/FogShader/HeightFogTest3"
{

    Properties
    {
        [KeywordEnum(VIEWSPACE, WORLDSPACE)] _DIST_TYPE ("Distance type", int) = 0
        [KeywordEnum(LINEAR, EXP, EXP2)] _FUNC_TYPE("Calculate Func type", int) = 0
        
    
        _MainTex("Base (RBG)", 2D) = "while"{}
        _FogDensity ("Fog Density", Float) = 1.0
        _FogColor ("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
     
        _HeightFogStart ("Fog Start", Float) = 0.0
        _HeightFogEnd ("Fog End", Float) = 1.0

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _FogXSpeed ("Fog Horizontal Speed", Float) = 0.1
        _FogYSpeed ("Fog Vertical Speed", Float) = 0.1
        _NoiseAmount ("Noise Amount", Float) = 1

    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        float4x4 _FrustumCornersRay;
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        half _FogDensity;
        fixed4 _FogColor;
        float _HeightFogStart;
        float _HeightFogEnd;
        sampler2D _NoiseTex;
        half _FogXSpeed;
        half _FogYSpeed;
        half _NoiseAmount;

        //函数曲线弯曲程度
        half _HeightFalloff;
        half _FstartDistance;
        half _InscatterStartDistance;
        half _InscatteringExponent;
        fixed4 _InscatterColor;

        struct v2f{
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;


        };

        v2f vert(appdata_img v,uint vid:SV_VertexID){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            float3 viewVector = mul(unity_CameraInvProjection, float4(v.texcoord * 2 - 1, 0, -1));
            o.interpolatedRay = mul(unity_CameraToWorld, float4(viewVector,0));
     
            return o;
        }

        fixed4 frag(v2f i):SV_Target {
            //四边形上的  当前点的  线性深度值
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;



           // float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
            //float noise = (tex2D(_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;

            //float fogDensity = (_HeightFogEnd - worldPos.y) / (_HeightFogEnd - _HeightFogStart);
            //fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));

            //unity的高度雾
            //float fogDensity =  exp(-_FogDensity*(worldPos.y));

            //ue的高度雾
            //float fogDensity =  _FogDensity * exp2(-(_WorldSpaceCameraPos.y - _HeightFogEnd));
            
            
            _HeightFalloff = 0.01;
            float fogDensity =  _FogDensity * exp2(-_HeightFalloff*(_WorldSpaceCameraPos.y - _HeightFogEnd));
            float falloff = _HeightFalloff * (worldPos.y - _WorldSpaceCameraPos.y);
            float fogFactor = (1-exp2(-falloff))/falloff;

            float fog  = fogDensity * fogFactor;

            return fog;

            //加入距离影响因素,fragment到摄像机的距离
            fog *= max(length(linearDepth * i.interpolatedRay.xyz) - _FstartDistance, 0);
            fog = saturate(fog);

            //加入光晕
            float sunAmount = pow(saturate(dot(normalize(linearDepth * i.interpolatedRay.xyz), normalize(_WorldSpaceLightPos0.xyz))), _InscatteringExponent );
         
            float dirExponentialHeightLineIntegral = max(length(linearDepth * i.interpolatedRay.xyz) - _InscatterStartDistance, 0.0f);
            float DirectionalInscatteringFogFactor = saturate(exp2(-dirExponentialHeightLineIntegral)); 
            sunAmount *= (1 - DirectionalInscatteringFogFactor);
            
            float4 fogColor = fixed4(0,0,0,1);
            //混合雾色和光晕颜色
            fogColor.rgb = lerp(_FogColor.rgb, _InscatterColor.rgb, sunAmount);
           
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            finalColor.rgb = lerp(finalColor.rgb, fogColor.rgb, fog);
            
            return finalColor;
        }
       
        ENDCG
        Pass{
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    FallBack Off
}