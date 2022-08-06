Shader "Custom/ProceduralSkybox"
{
    Properties
    {
        //[IntRange]_SunSize ("太阳大小", Range(0, 256)) = 1.0
        //_SunStrength ("太阳亮度", Range(0, 16)) = 1.0
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
            #define CLOUDS;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                half3 viewDir : TEXCOORD2;
            };

            
            sampler2D _ColorRamp;
            ///TODO: 合并参数，减少传递次数
            /*
            half _SunSize;
            half _SunStrength;
            half _MoonSize;
            half _MoonStrength;
            fixed _MoonSheen;
            fixed _SunSheen;*/

            half3 _SunControl;
            half3 _MoonControl;
            fixed3 _SunDir;
            fixed3 _MoonDir;

            half2 _StarControl;
            half4 _StarRed;
            half4 _StarBlue;

            fixed4 _SunColor;
            fixed4 _MoonColor;

            fixed4 _CloudControl;
            sampler2D _CloudsTex;
            fixed _TimeOfDay;

            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                fixed3 viewDir = normalize(i.viewDir);

                /////////////////////////////// SKY BASE COLOR /////////////////////////////////
                fixed4 skyCol = tex2D(
                    _ColorRamp, fixed2((viewDir.y + 1.0f) * 0.5f, _TimeOfDay)
                );

                ////////////////////////////// THE SUN ///////////////////////////////////
                fixed3 sunDir = -_SunDir;
                half sunDisk = saturate(1 - distance(i.uv.xyz, sunDir));
                //return sunDistance;
                //fixed sunDisk = dot(viewDir, -lightDir);
                sunDisk = saturate(sunDisk);
                half sun = saturate(pow(sunDisk, _SunControl.r)) * _SunControl.g;
                fixed sunSheen = pow(sunDisk, 2);
                sun += sunSheen * _SunControl.b;
                sun *= saturate(sunDir.y + 0.3f);

                ///////////////////////////// THE MOON ////////////////////////////////////
                fixed3 moonDir = -_MoonDir;
                half moonDisk = saturate(1 - distance(i.uv.xyz, moonDir));
                moonDisk = saturate(moonDisk);
                half moon = saturate(pow(moonDisk, _MoonControl.r)) * _MoonControl.g;
                fixed moonSheen = pow(moonDisk, 2);
                moon += moonSheen * 0.7f * _MoonControl.b;
                moon *= saturate(moonDir.y + 0.3f);


                ////////////////////////////// CLOUDS /////////////////////////////////////
               
                fixed theta = atan2(i.uv.x, i.uv.z);
                theta = (theta + UNITY_PI) / UNITY_TWO_PI;
                //fixed phi = asin(i.uv.y);
                fixed phi = acos(i.uv.y) / UNITY_PI;
                //fixed phi = (i.uv.y + 1.0) * 0.5f;
                fixed2 polarUV = fixed2(theta, (1 - phi) * 2);
                fixed2 rotatingSkyUV = polarUV;
                rotatingSkyUV += (_Time.r * 0.02) % 1;
                fixed3 cloudNStars = tex2D(_CloudsTex, rotatingSkyUV, 0.0f, 0.0f);
                fixed cloud = cloudNStars.r;
                
                #ifdef CLOUDS
                    //is it lit?
                    fixed lit = max(moonSheen, sunSheen + sunDir.y);
                    fixed cloudVisibilityHigh = saturate(saturate(sin(i.uv.y * 2.5 + 0.5)) * i.uv.y);
                    cloudVisibilityHigh *= cloudVisibilityHigh;
                    fixed cloudDecay = phi;
                    cloud = lerp(0.0, cloud, cloudVisibilityHigh);
                    cloud = smoothstep(_CloudControl.g, _CloudControl.g + _CloudControl.b, cloud);
                    cloud *= _CloudControl.r * lit;
                #else
                    cloud = 0.0f;
                #endif


                ////////////////////////////// STARS //////////////////////////////////////
                fixed starsVisibility = cloudNStars.b;
                starsVisibility = smoothstep(0.32, 0.6, starsVisibility) * saturate(moonDir.y);

                fixed starTemperature = cloudNStars.r;
                starTemperature = (starTemperature - 0.5f) * 2.0f; //remap from -1 to 1
                fixed redShift = saturate(-starTemperature);
                fixed blueShift = saturate(starTemperature);

                

                //0~0.5
                fixed4 starColor = 1.0;
                starColor -= (1 - _StarRed) * redShift + (1 - _StarBlue) * blueShift;


                //return starColor;

                //return pow(starTemperature, 2);
                //return starsVisibility;
                fixed2 rotatingStarsUV = polarUV * 4;
                rotatingStarsUV.x *= 3;
                rotatingStarsUV.x += (_Time.r * 0.1) % 1;

                cloudNStars = tex2D(_CloudsTex, rotatingStarsUV, 0.0f, 0.0f);
                half4 stars = cloudNStars.g;
                stars = pow(stars, _StarControl.r) * starsVisibility * saturate(i.uv.y) * starColor;
                stars *= _StarControl.g * (1 - cloud);
               



                ////////////////////////////// HORIZON ////////////////////////////////////

                //Gradient?
                //return fixed4(frac(i.uv.xyz * 10), 1);
                half4 result = skyCol;
                // ADD SUN
                result.rgb += sun * _SunColor;
                result.rgb += moon * _MoonColor;
                // SUN ATTEN
                result.rgb += cloud + cloud * sunSheen * 6;
                result.rgb += cloud + cloud * moonSheen * 6 * _MoonColor;
                // STARS
                result.rgb += stars;


                return result;//fixed4(viewDir, 1.0f);    
            }
            ENDCG
        }
    }
}
