Shader "Unlit/PBR"
{
    
    Properties
    {
        
        _Albedo("Albedo",2D) = "white"{
    } //主贴图
        _MainColor("Main Color",Color) = (1,1,1,1) //主色调
        _Metallic("Metallic",2D) = "white"{
    } // 金属度贴图
        _MetallicScale("MetallicScale",Range(0,1)) = 1 // 金属强度
        _NormalMap("Normal Map",2D) = "white"{
    } // 法线贴图
        _NormalScale("Scale",Float) = 1.0  // 凹凸程度
        _Occlusion("Occlusion",2D) = "white"{
    } // Ao贴图
        _Smoothness("Smothness",Range(0,1)) = 1 // 光滑度
        _LUT("LUT",2D) = "white"{
    } // Lut贴图
    }
    SubShader
    {
    

        Pass
        {
    
            Tags{
    "LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vv
            #pragma fragment ff
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            struct v2f
            {
    
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 m0 : TEXCOORD1;
                float4 m1 : TEXCOORD2;
                float4 m2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            
            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Metallic;
            sampler2D _NormalMap;
            sampler2D _Occlusion;
            sampler2D _LUT;
            float _NormalScale;
            float _Smoothness;
            float4 _MainColor;
            float _MetallicScale;
            uniform float3 Albedo;
            uniform float Metallic;
            uniform float Roughness;

            v2f vv(appdata_tan v)
            {
    
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_Albedo);
                float3 worldpos = mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldnormal = UnityObjectToWorldNormal(v.normal);
                float3 worldtangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldbinormal = cross(worldnormal,worldtangent) * v.tangent.w;
                o.m0 = float4(worldtangent.x,worldbinormal.x,worldnormal.x,worldpos.x);
                o.m1 = float4(worldtangent.y,worldbinormal.y,worldnormal.y,worldpos.y);
                o.m2 = float4(worldtangent.z,worldbinormal.z,worldnormal.z,worldpos.z);
                TRANSFER_SHADOW(o);
                return o;
            }
            float3 fresnelSchlick(float cosTheta,float3 F0)
            {
    
                return F0 + (1 - F0) * pow(1.0 - cosTheta,5.0);
            }
            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
    
                return F0 + (max(float3(1.0 - roughness,1.0 - roughness,1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }   
            float DistributionGGX(float NdotH,float roughness)
            {
    
                float a = pow(roughness,2);
                float a2 = pow(a,2);
                float fenmu = UNITY_PI * pow(pow(NdotH,2) * (a2 - 1) + 1,2);
                return a2 / max(fenmu,0.001);
            }
            float GeometrySchlickGGX(float NdotV, float roughness)
            {
    
                float r = pow(roughness,2);
                float k = pow(r + 1,2) / 8;
                float fenmu = NdotV * (1 - k) + k;
                return NdotV / max(fenmu,0.001);
            }
            float GeometrySmith(float NdotV,float NdotL,float roughness)
            {
    
                float ggx1 = GeometrySchlickGGX(NdotV,roughness);
                float ggx2 = GeometrySchlickGGX(NdotL,roughness);
                return ggx1 * ggx2;
            }
            float3 BRDFspecular(float HdotL,float NdotH,float NdotV,float NdotL,float F0)
            {
    
                float3 F = fresnelSchlick(HdotL,F0);
                float NDF = DistributionGGX(NdotH,Roughness);
                float G = GeometrySmith(NdotV,NdotL,Roughness);
                float3 specular = NDF * F * G / max((4 * NdotV * NdotL),0.001);
                return specular;
            }
            fixed4 ff(v2f i) : SV_TARGET
            {
    
                float3 worldpos = float3(i.m0.w,i.m1.w,i.m2.w);
                UNITY_LIGHT_ATTENUATION(atten,i,worldpos);
                float3 L = normalize(UnityWorldSpaceLightDir(worldpos));
                float3 V = normalize(UnityWorldSpaceViewDir(worldpos));
                float3 N = UnpackNormal(tex2D(_NormalMap,i.uv));
                N.xy *= _NormalScale;
                N.z = sqrt(1.0 - saturate(dot(N.xy,N.xy)));
                N = normalize(half3(dot(i.m0.xyz,N),dot(i.m1.xyz,N),dot(i.m2.xyz,N)));
                float4 Metal = tex2D(_Metallic,i.uv);
                Metallic = Metal.r * _MetallicScale;
                Roughness = (1 - Metal.a * _Smoothness);

                float3 H = normalize(V + L);
                float NV = saturate(dot(N,V));
                float NL = saturate(dot(N,L));
                float NH = saturate(dot(N,H));
                float LV = saturate(dot(L,V));
                float LH = saturate(dot(L,H));

                Albedo = tex2D(_Albedo,i.uv) * _MainColor;//对主帖图进行采样
                float3 F0 = float3(0.04,0.04,0.04);//定义物体的基础反射率，大部分都为0.04
                F0 = lerp(F0,Albedo,Metallic);//考虑到如果为金属的话，基础反射率需要带有颜色信息，所以使用lerp进行处理
                
                float3 Ks = fresnelSchlick(max(dot(H,V),0.0),F0);
                float3 Kd = (float3(1.0,1.0,1.0) - Ks) * (1 - Metallic);
                //另一种漫反射系数的算法
                //float3 Kd = OneMinusReflectivityFromMetallic(Metallic);
               
                float3 diffuse = Kd * Albedo;
                float3 specular = BRDFspecular(LH,NH,NV,NL,F0);
                return float4(specular, 1.0);
                float3 Lo = (diffuse + specular * UNITY_PI) * _LightColor0.rgb * NL;

                float3 ambient = 0.03 * Albedo;//计算基础的环境光
                float3 sh = ShadeSH9(float4(N,1));//内置宏ShadeSH9计算相应的采样数据
                float3 iblDiffuse = max(float3(0,0,0),sh + ambient.rgb);
                float3 Flast = fresnelSchlickRoughness(max(dot(N,V), 0.0), F0, Roughness);//引入了粗糙度的菲涅耳项计算高光反射比例 反推出漫反射比例
				float kd = (1 - Flast) * (1 - Metallic);//这里也可以使用直接光计算时使用的内置宏
                iblDiffuse *= Kd * Albedo;//最后乘上漫反射系数和兰伯特定值
                //注意这里同样跟直接光一样把反射方程简化了出来 通过采样代替积分计算，所以不需要除系数π

                /*
                float3 reflectDir = normalize(reflect(-V,N));//计算反射向量 使用该方向对CubeMap进行取样
                float percetualRoughness = Roughness * (1.7 - 0.7 * Roughness);//因为粗糙度和mipmap的等级关系不是线性的 所以我们需要进行处理
                float mip = percetualRoughness * 6;// 把数值范围映射到0到6之间，Unity默认的mip层级为6，也可以改为内置宏UNITY_SPECCUBE_LOD_STEPS
                float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflectDir,mip);//对CubeMap进行采样，unity_SpecCube0为天空盒或最近的反射探针的数据
                float3 iblSpecular = DecodeHDR(rgbm,unity_SpecCube0_HDR);//最后把采样到的颜色进行HDR解码处理

                
                float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99, NV), lerp(0, 0.99, Roughness))).rg; // LUT采样
                iblSpecular *= (Flast * envBDRF.r + envBDRF.g);//最后通过使用采样得到的r值进行缩放和g值进行偏移得到结果

                //instead for LUT
                // float grazingTerm = saturate(1 - Roughness + OneMinusReflectivityFromMetallic(Metallic.r));
                // float surfaceReduction = 1 / (pow(Roughness,2) + 1);
                // iblSpecular = surfaceReduction * iblSpecular * FresnelLerp(float4(F0,1.0),grazingTerm,NV);

                float ao = tex2D(_Occlusion,i.uv).r;//计算Ao环境光遮罩效果
                float3 color = Lo + (iblSpecular + iblDiffuse) * ao;//Lo为直接计算的直接光部分，后面为IBL间接光部分，需要注意的是要乘上Ao贴图的系数
                
                return fixed4(color,1.0); */

            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}