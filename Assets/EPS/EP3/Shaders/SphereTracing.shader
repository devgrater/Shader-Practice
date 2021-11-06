Shader "Unlit/SphereTracing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SphereSize ("Sphere Radius", Range(0, 1)) = 0.5
        _FogDensity ("Fog Density", Range(0, 4)) = 1.0
        _FogPower ("Fog Power", Range(1, 8)) = 1.0
        _FresnelIntensity ("Fresnel Intensity", Range(0, 8)) = 1.0
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { 
                "RenderType"="Transparent"
                "Queue"="Transparent+1"
            }
            Blend One OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            ZTest Always
            LOD 100

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
                float3 worldViewDir : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            struct f_out
            {
                float4 color : SV_TARGET;
                float depth : SV_Depth;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            float _SphereSize;
            float _FogDensity;
            float _FresnelIntensity;
            float _FogPower;
            float4 _FogColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldViewDir = WorldSpaceViewDir(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            f_out frag (v2f i)
            {
                f_out out_f;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 objectSpaceViewDir = normalize(mul(unity_WorldToObject, float4(i.worldViewDir, 0)));
                float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float sceneDepth = tex2Dproj(_CameraDepthTexture, i.screenPos);
                float corrected_depth = dot(normalize(i.worldViewDir), UNITY_MATRIX_V[2].xyz);
                sceneDepth = LinearEyeDepth(sceneDepth);
                //convert stuff to object space coords
                //trace it there
                //solve:

                float a = dot(objectSpaceViewDir, objectSpaceViewDir);
                float b = 2 * dot(objectSpaceCameraPos, objectSpaceViewDir);
                float c = dot(objectSpaceCameraPos, objectSpaceCameraPos) - _SphereSize * _SphereSize;
                float a_2 = a * 2;
                float b_sqr_4ac = sqrt(b * b - 4 * a * c);

                float4 out_col = float4(0, 0, 0, 0); 
                float3 pixel_pos;
                float depth_diff;
                float depth;
                float distance_from_center;
                bool is_inside = false;


                if(a_2 != 0){
                    float lesser_t = (-b - b_sqr_4ac) / a_2;
                    float larger_t = (-b + b_sqr_4ac) / a_2;
                    if(lesser_t <= 0 && larger_t <= 0){
                        //hit
                        //return max(lesser_t, larger_t);
                        depth_diff = abs((lesser_t - larger_t));
                        depth = -(max(lesser_t, larger_t));
                        out_col = _FogColor;
                        
                    }
                    else if(lesser_t > 0 || larger_t > 0){
                        //inside the sphere
                        depth_diff = abs(min(lesser_t, larger_t));
                        depth = -min(lesser_t, larger_t);
                        out_col = _FogColor;
                        is_inside = true;
                    }
                    pixel_pos = objectSpaceCameraPos - objectSpaceViewDir * depth;
                    float3 camera_dir = pixel_pos - objectSpaceCameraPos;
                    camera_dir = mul(unity_ObjectToWorld, float4(camera_dir, 0));
                    
                    //depth *= unity_ObjectToWorld[0].x;
                    depth = sqrt(dot(camera_dir, camera_dir));
                    depth *= corrected_depth;
                    distance_from_center = sqrt(dot(pixel_pos, pixel_pos));
                    float density_falloff = pow(1 - distance_from_center, _FresnelIntensity);
                    depth_diff = min(depth_diff, (-depth + sceneDepth) * density_falloff) / 2 * density_falloff;
                    
                    
                    //also need to increase...
                    //out_col.a = saturate(depth_diff);
                    if(depth > sceneDepth && !is_inside){
                        out_col.a = 0; //clip 
                    }
                    if(is_inside){
                        depth_diff = log(sceneDepth / corrected_depth) / 16 * (1 - distance_from_center);
                    }
                }
                


                UNITY_APPLY_FOG(i.fogCoord, col);
                //clip(out_col.a - 0.5);
                //fresnel
                //just to make the density look a bit more natural
                float fresnel = is_inside? 1 : pow(dot(pixel_pos, normalize(objectSpaceViewDir)), _FresnelIntensity);
                
                out_col.a = saturate(depth_diff * _FogDensity);
                out_col.a = pow(out_col.a, _FogPower);
                //out_col.rgb *= saturate(out_col.a); //premultiply
                out_f.color = out_col * out_col.a;
                out_f.depth = depth ;
                return out_f;
            }
            ENDCG
        }
    }
}
