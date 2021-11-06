Shader "Unlit/SphereTracing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SphereSize ("Sphere Radius", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Pass
        {
            Tags { 
                "RenderType"="Transparent"
                "Queue"="Transparent+10"
            }
            Blend SrcAlpha OneMinusSrcAlpha 
            Cull Off
            //ZWrite Off
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

                float4 out_col = float4(1, 0, 0, 0); 
                float depth_diff;
                float depth;
                if(a_2 != 0){
                    float lesser_t = (-b - b_sqr_4ac) / a_2;
                    float larger_t = (-b + b_sqr_4ac) / a_2;
                    if(lesser_t <= 0 && larger_t <= 0){
                        //hit
                        //return max(lesser_t, larger_t);
                        depth_diff = abs((lesser_t - larger_t));
                        depth = -(max(lesser_t, larger_t));
                        
                        out_col = float4(1, 1, 1, 1);
                        
                    }
                    else if(lesser_t > 0 || larger_t > 0){
                        //return float4(0, 1, 0, 0);
                        //no hit
                        depth_diff = abs(min(lesser_t, larger_t));
                        depth = -min(lesser_t, larger_t);
                        out_col = float4(1, 1, 0, 1);
                    }
                    depth *= corrected_depth;
                    depth *= unity_ObjectToWorld[0].x;
                    depth_diff = -depth + sceneDepth;
                    //also need to increase...
                    //out_col.a = saturate(depth_diff);
                    if(depth > sceneDepth){
                        out_col.a = 0; //clip 
                    }

                }
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip(out_col.a - 0.5);
                out_col.a = saturate(depth_diff);
                //out_col.rgb *= saturate(out_col.a); //premultiply
                out_f.color = out_col;//out_col;
                out_f.depth = depth ;
                return out_f;
            }
            ENDCG
        }
    }
}
