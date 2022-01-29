Shader "Unlit/DepthReplacement"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _cst_NearFar;
            float3 _cst_LightDir;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            //this we have 01 depth?
            //to make it work with the depth buffer
            //we need to store it differently.
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //note that this depth texture right here
                //its computed in, well, distance relative to the camera,
                //not the camera plane.
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //when we use i.vertex.w, the further away,
                //the brighter. however, this wouldn't do the trick...
                //because we run out of precision quickly.

                //so the first thing we do is to compute 1/z.
                //this gives us... a range from 0 to 1.
                //but we wasted too much precision on the closer areas.
                //in this case, w is in clip space.
                float wCoord = i.vertex.w;

                float perspectiveCorrection = dot(i.viewDir, _cst_LightDir);
                //return perspectiveCorrection;
                //wCoord /= perspectiveCorrection;
                //remap wCoord so that the near plane gives d = 1 and far plane gives d = 0;
                //float nDF = _cst_NearFar.y / _cst_NearFar.x;
                //wCoord = (wCoord - (1 / _cst_NearFar.y)) / ((1 - nDF) / (_cst_NearFar.y)); 
                //lets assume that this worked...
                clip(col.a - 0.5f);
                return 1.0f / wCoord;
            }
            ENDCG
        }
    }
}
