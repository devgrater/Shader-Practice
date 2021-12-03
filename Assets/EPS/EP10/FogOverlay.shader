Shader "Hidden/FogOverlay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
                float4 interpolatedRay : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4x4 _FrustumCornersRay;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                int index = 0;
                if(o.uv.x < 0.5f){
                    if(o.uv.y < 0.5f){
                        //bottom left
                        index = 0;
                    }
                    else{
                        //top left
                        index = 3;
                    }
                }
                else{
                    if(o.uv.y < 0.5f){
                        //bottom right
                        index = 1;
                    }
                    else{
                        //whatever the remaining one is
                        index = 2;
                    }
                }
                o.interpolatedRay = _FrustumCornersRay[index];
                return o;
            }



            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                fixed depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv));

                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
    }
}



class Circle{
    public static float pi = 3.14159f;
    public float radius;

    public static void pi_equals_4(){
        pi = 4;
    }

    public float getArea(){
        return pi * this.radius * this.radius;
    }
}

Circle a = new Circle(5);
Circle b = new Circle(10);

Circle.pi_equals_4() //这个可以
a.getArea();