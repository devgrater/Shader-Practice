Shader "Hidden/WorldReconstruct"
{
	Properties
	{
		
	}

	SubShader
	{


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldDirection : TEXCOORD1;
				float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD2;
			};

			float4x4 clipToWorld;

			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				//float4 clip = float4(o.vertex.xy, 0.0, 1.0);
				o.worldDirection = WorldSpaceViewDir(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);

				return o;
			}
			
			sampler2D_float _CameraDepthTexture;
			float4 _CameraDepthTexture_ST;

			float4 frag (v2f i) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
				depth = LinearEyeDepth(depth);
				float3 worldspace = -i.worldDirection / i.screenPos.w * depth + _WorldSpaceCameraPos;

				float4 color = float4(worldspace, 1.0);
				return float4(worldspace, 1.0);
			}
			ENDCG
		}
	}
}