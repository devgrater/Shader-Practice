// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Effect/All"
{
	Properties
	{
		[Header(Instruction)]_Tile1("Custom：添加Custom1.xy、Custom1.xyzw、Custom2.xyzw", Float) = 0
		_Tile2("Custom1.xy是主贴图流动，Custom1.z是溶解强度，Custom1.w是扰动强度", Float) = 0
		_Tile3("Custom2.xy是遮罩流动，Custom2.z是顶点偏移强度，Custom2.w是空气扭曲强度", Float) = 0
		[Header(Set Mode)][KeywordEnum(Mesh,Particle)] _Custom2xyKey("制作模式", Float) = 1
		[Enum(AlphaBlend,10,Additive,1)]_Dst("材质模式", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式", Float) = 2
		[Enum(Default,0,On,1,Off,2)]_ZWrite("深度模式", Float) = 0
		_DepthFade("深度消隐强度", Float) = 0
		[KeywordEnum(Off,On)] _FresnelKey("菲尼尔开关", Float) = 0
		[HDR]_FresnelColor("菲尼尔颜色", Color) = (1,1,1,1)
		_FresnelScale("菲尼尔宽度", Float) = 1
		_FresnelPower("菲尼尔强度", Float) = 2
		[KeywordEnum(Off,On)] _if_ModeDepthFade1("边缘虚化开关", Float) = 0
		_ModeFresnel_Scale1("虚化范围", Float) = 1
		_ModeFresnel_Power1("虚化范围过渡", Float) = 0
		_ModeFresnel_Bias1("虚化强度", Float) = 0
		[HDR][Header(Main Mode)]_Color("颜色", Color) = (1,1,1,1)
		_MainTex("主贴图", 2D) = "white" {}
		_Maintexrotate("主帖图旋转", Range( -180 , 180)) = 0
		[Toggle(_TRANSPARENTFORR_ON)] _transparentforR("利用R通道作为透明度", Float) = 0
		[Toggle(_TRANSPARENTFORR1_ON)] _transparentforR1("主贴图clamp模式", Float) = 0
		[Toggle(_TRANSPARENTFORR2_ON)] _transparentforR2("溶解贴图clamp模式", Float) = 0
		_Gradation("色阶", Vector) = (0,1,0,0)
		_MainTex_U("主贴图流动_U", Float) = 0
		_MainTex_V("主贴图流动_V", Float) = 0
		[Toggle(_MAINTEXTODISSOLVE1_ON)] _MainTexToDissolve1("主贴图流动影响溶解", Float) = 0
		[Header(Dissslve Mode)]_DissolveTex("溶解贴图", 2D) = "white" {}
		_DissolveTexrotate("溶解贴图旋转", Range( -180 , 180)) = 180
		_DissolveTex_U1("溶解贴图流动_U", Float) = 0
		_DissolveTex_V1("溶解贴图流动_V", Float) = 0
		_DissolveIntensityCustom1z("溶解强度", Range( 0 , 1)) = 0
		_SoftaDissolve("软硬边强度", Range( 0 , 1)) = 0
		[HDR]_DissolveLineColor("亮边颜色", Color) = (1,1,1,1)
		_LineWidth("亮边值", Range( 0 , 0.85)) = 0
		[Header(Noise Mode)]_DestortionTex("扰动贴图", 2D) = "white" {}
		_DestortionTexRotate("扰动贴图旋转", Range( -180 , 180)) = 0
		_DestortionIntensity("扰动强度", Float) = 0
		_DestortionTex_U1("扰动流动_U", Float) = 0
		_DestortionTex_V1("扰动流动_V", Float) = 0
		[Header(Mask Mode)]_MaskTex("遮罩贴图", 2D) = "white" {}
		_MaskTexrotate1("遮罩贴图1旋转", Range( -180 , 180)) = 0
		[KeywordEnum(On,Off)] _MaskCustomDataKey2("遮罩自定义数据开关", Float) = 1
		_MaskTex_U1("遮罩贴图流动_U", Float) = 0
		_MaskTex_V1("遮罩贴图流动_V", Float) = 0
		_MaskTex02("遮罩贴图02", 2D) = "white" {}
		_MaskTexrotate2("遮罩贴图2旋转", Range( -180 , 180)) = 0
		_MaskTex02_U1("遮罩流动02_U", Float) = 0
		_MaskTex02_V1("遮罩流动02_V", Float) = 0
		[Toggle(_DESTORTIONTOVERTEXOFFSET_ON)] _DestortionToVertexOffset("扰动影响顶点偏移", Float) = 0
		[Header(Vertex Mode)]_VertexOffsetTex("顶点偏移贴图", 2D) = "white" {}
		_VertexOffsetTexRotate("顶点偏移贴图旋转", Range( -180 , 180)) = 0
		_VertexOffsetIntensity("顶点偏移强度", Float) = 0
		_VertexOffsetTex_U1("顶点偏移流动_U", Float) = 0
		_VertexOffsetTex_V1("顶点偏移流动_V", Float) = 0
		[Header(AirDistortion Mode)][KeywordEnum(Off,On)] _AirDistortionSwitch1("空气扭曲开关", Float) = 0
		_AirDistortionTex("空气扭曲贴图", 2D) = "white" {}
		_AirDistortionTexRotate("空气扭曲贴图旋转", Range( -180 , 180)) = 0
		_AirDistortion_Intensity1("扭曲强度", Float) = 0
		_AirDistortionTex_U1("扭曲流动_U", Float) = 0
		_AirDistortionTex_V1("扭曲流动_V", Float) = 0
		[HideInInspector] _tex4coord( "", 2D ) = "white" {}
		[HideInInspector] _tex4coord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _tex4coord3( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IsEmissive" = "true"  }
		Cull [_CullMode]
		ZWrite [_ZWrite]
		Blend SrcAlpha [_Dst]
		
		GrabPass{ }
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature_local _DESTORTIONTOVERTEXOFFSET_ON
		#pragma shader_feature_local _CUSTOM2XYKEY_MESH _CUSTOM2XYKEY_PARTICLE
		#pragma shader_feature_local _AIRDISTORTIONSWITCH1_OFF _AIRDISTORTIONSWITCH1_ON
		#pragma shader_feature_local _TRANSPARENTFORR2_ON
		#pragma shader_feature_local _MAINTEXTODISSOLVE1_ON
		#pragma shader_feature_local _TRANSPARENTFORR1_ON
		#pragma shader_feature_local _FRESNELKEY_OFF _FRESNELKEY_ON
		#pragma shader_feature_local _TRANSPARENTFORR_ON
		#pragma shader_feature_local _IF_MODEDEPTHFADE1_OFF _IF_MODEDEPTHFADE1_ON
		#pragma shader_feature_local _MASKCUSTOMDATAKEY2_ON _MASKCUSTOMDATAKEY2_OFF
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#undef TRANSFORM_TEX
		#define TRANSFORM_TEX(tex,name) float4(tex.xy * name##_ST.xy + name##_ST.zw, tex.z, tex.w)
		struct Input
		{
			float2 uv_texcoord;
			float4 uv_tex4coord;
			float4 uv2_tex4coord2;
			float4 vertexColor : COLOR;
			float3 worldPos;
			half3 worldNormal;
			float4 screenPos;
			float4 uv3_tex4coord3;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform half _Tile3;
		uniform half _Tile2;
		uniform half _CullMode;
		uniform half _ZWrite;
		uniform half _Dst;
		uniform half _Tile1;
		uniform sampler2D _VertexOffsetTex;
		uniform half _VertexOffsetTex_U1;
		uniform half _VertexOffsetTex_V1;
		uniform float4 _VertexOffsetTex_ST;
		uniform sampler2D _DestortionTex;
		uniform half _DestortionTex_U1;
		uniform half _DestortionTex_V1;
		uniform float4 _DestortionTex_ST;
		uniform half _DestortionTexRotate;
		uniform half _DestortionIntensity;
		uniform half _VertexOffsetTexRotate;
		uniform half _VertexOffsetIntensity;
		uniform half _SoftaDissolve;
		uniform sampler2D _DissolveTex;
		uniform half _MainTex_U;
		uniform half _MainTex_V;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform half _DissolveTex_U1;
		uniform half _DissolveTex_V1;
		uniform float4 _DissolveTex_ST;
		uniform half _DissolveTexrotate;
		uniform half _DissolveIntensityCustom1z;
		uniform half _LineWidth;
		uniform half4 _DissolveLineColor;
		uniform half _Maintexrotate;
		uniform half2 _Gradation;
		uniform half4 _Color;
		uniform half4 _FresnelColor;
		uniform half _FresnelScale;
		uniform half _FresnelPower;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform sampler2D _AirDistortionTex;
		uniform half _AirDistortionTex_U1;
		uniform half _AirDistortionTex_V1;
		uniform half _AirDistortionTexRotate;
		uniform half _AirDistortion_Intensity1;
		uniform sampler2D _MaskTex;
		uniform half _MaskTex_U1;
		uniform half _MaskTex_V1;
		uniform float4 _MaskTex_ST;
		uniform half _MaskTexrotate1;
		uniform sampler2D _MaskTex02;
		uniform half _MaskTex02_U1;
		uniform half _MaskTex02_V1;
		uniform float4 _MaskTex02_ST;
		uniform half _MaskTexrotate2;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform half _DepthFade;
		uniform half _ModeFresnel_Bias1;
		uniform half _ModeFresnel_Scale1;
		uniform half _ModeFresnel_Power1;


		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			half2 appendResult455 = (half2(_VertexOffsetTex_U1 , _VertexOffsetTex_V1));
			float2 uv0_VertexOffsetTex = v.texcoord.xy * _VertexOffsetTex_ST.xy + _VertexOffsetTex_ST.zw;
			half2 temp_output_459_0 = ( ( _Time.y * appendResult455 ) + uv0_VertexOffsetTex );
			half2 appendResult428 = (half2(_DestortionTex_U1 , _DestortionTex_V1));
			float2 uv0_DestortionTex = v.texcoord.xy * _DestortionTex_ST.xy + _DestortionTex_ST.zw;
			float cos485 = cos( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin485 = sin( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator485 = mul( ( ( _Time.y * appendResult428 ) + uv0_DestortionTex ) - float2( 0.5,0.5 ) , float2x2( cos485 , -sin485 , sin485 , cos485 )) + float2( 0.5,0.5 );
			half3 Destortion113 = (tex2Dlod( _DestortionTex, float4( rotator485, 0, 0.0) )).rgb;
			float4 uv_TexCoord303 = v.texcoord;
			uv_TexCoord303.xy = v.texcoord.xy * float2( 0,0 );
			half4 appendResult305 = (half4(uv_TexCoord303.z , uv_TexCoord303.w , v.texcoord1.z , v.texcoord1.w));
			#if defined(_CUSTOM2XYKEY_MESH)
				half4 staticSwitch306 = float4( 0,0,0,0 );
			#elif defined(_CUSTOM2XYKEY_PARTICLE)
				half4 staticSwitch306 = appendResult305;
			#else
				half4 staticSwitch306 = appendResult305;
			#endif
			half4 break307 = staticSwitch306;
			half Costom1W353 = break307.w;
			half DestortionIntensity_Var115 = ( _DestortionIntensity + Costom1W353 );
			half3 lerpResult116 = lerp( half3( temp_output_459_0 ,  0.0 ) , Destortion113 , DestortionIntensity_Var115);
			#ifdef _DESTORTIONTOVERTEXOFFSET_ON
				half3 staticSwitch118 = lerpResult116;
			#else
				half3 staticSwitch118 = half3( temp_output_459_0 ,  0.0 );
			#endif
			float cos486 = cos( (-3.15 + (_VertexOffsetTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin486 = sin( (-3.15 + (_VertexOffsetTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator486 = mul( staticSwitch118.xy - float2( 0.5,0.5 ) , float2x2( cos486 , -sin486 , sin486 , cos486 )) + float2( 0.5,0.5 );
			half3 desaturateInitialColor102 = tex2Dlod( _VertexOffsetTex, float4( rotator486, 0, 0.0) ).rgb;
			half desaturateDot102 = dot( desaturateInitialColor102, float3( 0.299, 0.587, 0.114 ));
			half3 desaturateVar102 = lerp( desaturateInitialColor102, desaturateDot102.xxx, 1.0 );
			half3 ase_vertexNormal = v.normal.xyz;
			half Costom2z394 = v.texcoord2.z;
			half3 VertexOffset339 = ( desaturateVar102 * ase_vertexNormal * ( _VertexOffsetIntensity + Costom2z394 ) );
			v.vertex.xyz += VertexOffset339;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_worldNormal = i.worldNormal;
			half fresnelNdotV248 = dot( ase_worldNormal, ase_worldViewDir );
			half fresnelNode248 = ( 0.0 + _FresnelScale * pow( 1.0 - fresnelNdotV248, _FresnelPower ) );
			half3 Fresnel399 = ( (_FresnelColor).rgb * fresnelNode248 );
			#if defined(_FRESNELKEY_OFF)
				half3 staticSwitch228 = float3( 0,0,0 );
			#elif defined(_FRESNELKEY_ON)
				half3 staticSwitch228 = Fresnel399;
			#else
				half3 staticSwitch228 = float3( 0,0,0 );
			#endif
			float4 uv_TexCoord303 = i.uv_tex4coord;
			uv_TexCoord303.xy = i.uv_tex4coord.xy * float2( 0,0 );
			half4 appendResult305 = (half4(uv_TexCoord303.z , uv_TexCoord303.w , i.uv2_tex4coord2.z , i.uv2_tex4coord2.w));
			#if defined(_CUSTOM2XYKEY_MESH)
				half4 staticSwitch306 = float4( 0,0,0,0 );
			#elif defined(_CUSTOM2XYKEY_PARTICLE)
				half4 staticSwitch306 = appendResult305;
			#else
				half4 staticSwitch306 = appendResult305;
			#endif
			half4 break307 = staticSwitch306;
			half2 appendResult173 = (half2(break307.x , break307.y));
			half2 Costom1XY350 = appendResult173;
			half2 appendResult13 = (half2(_MainTex_U , _MainTex_V));
			float2 uv0_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			half2 MainUVMove332 = ( ( _Time.y * appendResult13 ) + uv0_MainTex );
			half2 appendResult428 = (half2(_DestortionTex_U1 , _DestortionTex_V1));
			float2 uv0_DestortionTex = i.uv_texcoord * _DestortionTex_ST.xy + _DestortionTex_ST.zw;
			float cos485 = cos( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin485 = sin( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator485 = mul( ( ( _Time.y * appendResult428 ) + uv0_DestortionTex ) - float2( 0.5,0.5 ) , float2x2( cos485 , -sin485 , sin485 , cos485 )) + float2( 0.5,0.5 );
			half3 Destortion113 = (tex2D( _DestortionTex, rotator485 )).rgb;
			half Costom1W353 = break307.w;
			half DestortionIntensity_Var115 = ( _DestortionIntensity + Costom1W353 );
			half3 lerpResult75 = lerp( half3( MainUVMove332 ,  0.0 ) , Destortion113 , DestortionIntensity_Var115);
			float cos462 = cos( (-3.15 + (_Maintexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin462 = sin( (-3.15 + (_Maintexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator462 = mul( ( half3( Costom1XY350 ,  0.0 ) + lerpResult75 ).xy - float2( 0.5,0.5 ) , float2x2( cos462 , -sin462 , sin462 , cos462 )) + float2( 0.5,0.5 );
			#ifdef _TRANSPARENTFORR1_ON
				half2 staticSwitch515 = saturate( rotator462 );
			#else
				half2 staticSwitch515 = frac( rotator462 );
			#endif
			half4 tex2DNode1 = tex2Dlod( _MainTex, float4( staticSwitch515, 0, 0.0) );
			half2 appendResult383 = (half2(_MaskTex_U1 , _MaskTex_V1));
			float2 uv0_MaskTex = i.uv_texcoord * _MaskTex_ST.xy + _MaskTex_ST.zw;
			half2 appendResult446 = (half2(i.uv3_tex4coord3.x , i.uv3_tex4coord3.y));
			#if defined(_MASKCUSTOMDATAKEY2_ON)
				half2 staticSwitch447 = appendResult446;
			#elif defined(_MASKCUSTOMDATAKEY2_OFF)
				half2 staticSwitch447 = float2( 0,0 );
			#else
				half2 staticSwitch447 = float2( 0,0 );
			#endif
			half2 Costom2y393 = staticSwitch447;
			float cos475 = cos( (-3.15 + (_MaskTexrotate1 - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin475 = sin( (-3.15 + (_MaskTexrotate1 - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator475 = mul( ( ( _Time.y * appendResult383 ) + uv0_MaskTex + Costom2y393 ) - float2( 0.5,0.5 ) , float2x2( cos475 , -sin475 , sin475 , cos475 )) + float2( 0.5,0.5 );
			half3 desaturateInitialColor50 = tex2D( _MaskTex, rotator475 ).rgb;
			half desaturateDot50 = dot( desaturateInitialColor50, float3( 0.299, 0.587, 0.114 ));
			half3 desaturateVar50 = lerp( desaturateInitialColor50, desaturateDot50.xxx, 1.0 );
			half2 appendResult385 = (half2(_MaskTex02_U1 , _MaskTex02_V1));
			float2 uv0_MaskTex02 = i.uv_texcoord * _MaskTex02_ST.xy + _MaskTex02_ST.zw;
			float cos479 = cos( (-3.15 + (_MaskTexrotate2 - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin479 = sin( (-3.15 + (_MaskTexrotate2 - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator479 = mul( ( ( _Time.y * appendResult385 ) + uv0_MaskTex02 ) - float2( 0.5,0.5 ) , float2x2( cos479 , -sin479 , sin479 , cos479 )) + float2( 0.5,0.5 );
			half3 desaturateInitialColor61 = tex2D( _MaskTex02, rotator479 ).rgb;
			half desaturateDot61 = dot( desaturateInitialColor61, float3( 0.299, 0.587, 0.114 ));
			half3 desaturateVar61 = lerp( desaturateInitialColor61, desaturateDot61.xxx, 1.0 );
			half3 Mask396 = ( (desaturateVar50).xyz * (desaturateVar61).xyz );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			half4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth78 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			half distanceDepth78 = abs( ( screenDepth78 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _DepthFade ) );
			half clampResult81 = clamp( distanceDepth78 , 0.0 , 1.0 );
			half DepthFade341 = clampResult81;
			half3 temp_output_324_0 = ( staticSwitch228 + ( ( tex2DNode1.a * _Color.a * i.vertexColor.a * Mask396 ) * DepthFade341 ) );
			half fresnelNdotV271 = dot( ase_worldNormal, ase_worldViewDir );
			half fresnelNode271 = ( _ModeFresnel_Bias1 + _ModeFresnel_Scale1 * pow( 1.0 - fresnelNdotV271, ( 1.0 - _ModeFresnel_Power1 ) ) );
			half FresnelFeather398 = saturate( ( 1.0 - fresnelNode271 ) );
			#if defined(_IF_MODEDEPTHFADE1_OFF)
				half3 staticSwitch275 = temp_output_324_0;
			#elif defined(_IF_MODEDEPTHFADE1_ON)
				half3 staticSwitch275 = ( temp_output_324_0 * FresnelFeather398 );
			#else
				half3 staticSwitch275 = temp_output_324_0;
			#endif
			#ifdef _MAINTEXTODISSOLVE1_ON
				half2 staticSwitch412 = ( MainUVMove332 + Costom1XY350 );
			#else
				half2 staticSwitch412 = float2( 0,0 );
			#endif
			half2 appendResult371 = (half2(_DissolveTex_U1 , _DissolveTex_V1));
			float2 uv0_DissolveTex = i.uv_texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
			half3 lerpResult158 = lerp( half3( ( staticSwitch412 + ( ( _Time.y * appendResult371 ) + uv0_DissolveTex ) ) ,  0.0 ) , Destortion113 , DestortionIntensity_Var115);
			float cos471 = cos( (-3.15 + (_DissolveTexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin471 = sin( (-3.15 + (_DissolveTexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator471 = mul( lerpResult158.xy - float2( 0.5,0.5 ) , float2x2( cos471 , -sin471 , sin471 , cos471 )) + float2( 0.5,0.5 );
			#ifdef _TRANSPARENTFORR2_ON
				half2 staticSwitch519 = saturate( rotator471 );
			#else
				half2 staticSwitch519 = frac( rotator471 );
			#endif
			half3 desaturateInitialColor125 = tex2D( _DissolveTex, staticSwitch519 ).rgb;
			half desaturateDot125 = dot( desaturateInitialColor125, float3( 0.299, 0.587, 0.114 ));
			half3 desaturateVar125 = lerp( desaturateInitialColor125, desaturateDot125.xxx, 1.0 );
			half Costom1Z352 = break307.z;
			half clampResult130 = clamp( ( ( (desaturateVar125).x + 1.0 ) - ( 2.0 * ( _DissolveIntensityCustom1z + Costom1Z352 ) ) ) , 0.0 , 1.0 );
			half smoothstepResult142 = smoothstep( 0.0 , ( 1.0 - _SoftaDissolve ) , clampResult130);
			half Dissolve345 = smoothstepResult142;
			half3 temp_output_315_0 = saturate( ( staticSwitch275 * Dissolve345 ) );
			#ifdef _TRANSPARENTFORR_ON
				half3 staticSwitch470 = ( tex2DNode1.r * temp_output_315_0 );
			#else
				half3 staticSwitch470 = temp_output_315_0;
			#endif
			c.rgb = 0;
			c.a = staticSwitch470.x;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			half2 appendResult13 = (half2(_MainTex_U , _MainTex_V));
			float2 uv0_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			half2 MainUVMove332 = ( ( _Time.y * appendResult13 ) + uv0_MainTex );
			float4 uv_TexCoord303 = i.uv_tex4coord;
			uv_TexCoord303.xy = i.uv_tex4coord.xy * float2( 0,0 );
			half4 appendResult305 = (half4(uv_TexCoord303.z , uv_TexCoord303.w , i.uv2_tex4coord2.z , i.uv2_tex4coord2.w));
			#if defined(_CUSTOM2XYKEY_MESH)
				half4 staticSwitch306 = float4( 0,0,0,0 );
			#elif defined(_CUSTOM2XYKEY_PARTICLE)
				half4 staticSwitch306 = appendResult305;
			#else
				half4 staticSwitch306 = appendResult305;
			#endif
			half4 break307 = staticSwitch306;
			half2 appendResult173 = (half2(break307.x , break307.y));
			half2 Costom1XY350 = appendResult173;
			#ifdef _MAINTEXTODISSOLVE1_ON
				half2 staticSwitch412 = ( MainUVMove332 + Costom1XY350 );
			#else
				half2 staticSwitch412 = float2( 0,0 );
			#endif
			half2 appendResult371 = (half2(_DissolveTex_U1 , _DissolveTex_V1));
			float2 uv0_DissolveTex = i.uv_texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
			half2 appendResult428 = (half2(_DestortionTex_U1 , _DestortionTex_V1));
			float2 uv0_DestortionTex = i.uv_texcoord * _DestortionTex_ST.xy + _DestortionTex_ST.zw;
			float cos485 = cos( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin485 = sin( (-3.15 + (_DestortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator485 = mul( ( ( _Time.y * appendResult428 ) + uv0_DestortionTex ) - float2( 0.5,0.5 ) , float2x2( cos485 , -sin485 , sin485 , cos485 )) + float2( 0.5,0.5 );
			half3 Destortion113 = (tex2D( _DestortionTex, rotator485 )).rgb;
			half Costom1W353 = break307.w;
			half DestortionIntensity_Var115 = ( _DestortionIntensity + Costom1W353 );
			half3 lerpResult158 = lerp( half3( ( staticSwitch412 + ( ( _Time.y * appendResult371 ) + uv0_DissolveTex ) ) ,  0.0 ) , Destortion113 , DestortionIntensity_Var115);
			float cos471 = cos( (-3.15 + (_DissolveTexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin471 = sin( (-3.15 + (_DissolveTexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator471 = mul( lerpResult158.xy - float2( 0.5,0.5 ) , float2x2( cos471 , -sin471 , sin471 , cos471 )) + float2( 0.5,0.5 );
			#ifdef _TRANSPARENTFORR2_ON
				half2 staticSwitch519 = saturate( rotator471 );
			#else
				half2 staticSwitch519 = frac( rotator471 );
			#endif
			half3 desaturateInitialColor125 = tex2D( _DissolveTex, staticSwitch519 ).rgb;
			half desaturateDot125 = dot( desaturateInitialColor125, float3( 0.299, 0.587, 0.114 ));
			half3 desaturateVar125 = lerp( desaturateInitialColor125, desaturateDot125.xxx, 1.0 );
			half Costom1Z352 = break307.z;
			half clampResult130 = clamp( ( ( (desaturateVar125).x + 1.0 ) - ( 2.0 * ( _DissolveIntensityCustom1z + Costom1Z352 ) ) ) , 0.0 , 1.0 );
			half smoothstepResult142 = smoothstep( 0.0 , ( 1.0 - _SoftaDissolve ) , clampResult130);
			half Dissolve345 = smoothstepResult142;
			half4 DissolveLine154 = ( ( step( Dissolve345 , 0.85 ) - step( ( Dissolve345 + _LineWidth ) , 0.85 ) ) * _DissolveLineColor );
			half3 lerpResult75 = lerp( half3( MainUVMove332 ,  0.0 ) , Destortion113 , DestortionIntensity_Var115);
			float cos462 = cos( (-3.15 + (_Maintexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin462 = sin( (-3.15 + (_Maintexrotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator462 = mul( ( half3( Costom1XY350 ,  0.0 ) + lerpResult75 ).xy - float2( 0.5,0.5 ) , float2x2( cos462 , -sin462 , sin462 , cos462 )) + float2( 0.5,0.5 );
			#ifdef _TRANSPARENTFORR1_ON
				half2 staticSwitch515 = saturate( rotator462 );
			#else
				half2 staticSwitch515 = frac( rotator462 );
			#endif
			half4 tex2DNode1 = tex2Dlod( _MainTex, float4( staticSwitch515, 0, 0.0) );
			half4 temp_cast_6 = (_Gradation.x).xxxx;
			half4 temp_cast_7 = (_Gradation.y).xxxx;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_worldNormal = i.worldNormal;
			half fresnelNdotV248 = dot( ase_worldNormal, ase_worldViewDir );
			half fresnelNode248 = ( 0.0 + _FresnelScale * pow( 1.0 - fresnelNdotV248, _FresnelPower ) );
			half3 Fresnel399 = ( (_FresnelColor).rgb * fresnelNode248 );
			#if defined(_FRESNELKEY_OFF)
				half3 staticSwitch228 = float3( 0,0,0 );
			#elif defined(_FRESNELKEY_ON)
				half3 staticSwitch228 = Fresnel399;
			#else
				half3 staticSwitch228 = float3( 0,0,0 );
			#endif
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			half4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			half2 appendResult283 = (half2(_AirDistortionTex_U1 , _AirDistortionTex_V1));
			half2 panner286 = ( 1.0 * _Time.y * appendResult283 + i.uv_texcoord);
			float cos482 = cos( (-3.15 + (_AirDistortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			float sin482 = sin( (-3.15 + (_AirDistortionTexRotate - -180.0) * (3.15 - -3.15) / (180.0 - -180.0)) );
			half2 rotator482 = mul( panner286 - float2( 0.5,0.5 ) , float2x2( cos482 , -sin482 , sin482 , cos482 )) + float2( 0.5,0.5 );
			half Costom2w395 = i.uv3_tex4coord3.w;
			half4 screenColor293 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( ase_grabScreenPosNorm + ( tex2D( _AirDistortionTex, rotator482 ) * ( _AirDistortion_Intensity1 + Costom2w395 ) ) ).xy);
			half4 AirDistortion331 = screenColor293;
			#if defined(_AIRDISTORTIONSWITCH1_OFF)
				half4 staticSwitch294 = ( DissolveLine154 + half4( ( ( (saturate( (temp_cast_6 + (tex2DNode1 - float4( 0,0,0,0 )) * (temp_cast_7 - temp_cast_6) / (float4( 1,1,1,1 ) - float4( 0,0,0,0 ))) )).rgb * (_Color).rgb * (i.vertexColor).rgb ) + staticSwitch228 ) , 0.0 ) );
			#elif defined(_AIRDISTORTIONSWITCH1_ON)
				half4 staticSwitch294 = AirDistortion331;
			#else
				half4 staticSwitch294 = ( DissolveLine154 + half4( ( ( (saturate( (temp_cast_6 + (tex2DNode1 - float4( 0,0,0,0 )) * (temp_cast_7 - temp_cast_6) / (float4( 1,1,1,1 ) - float4( 0,0,0,0 ))) )).rgb * (_Color).rgb * (i.vertexColor).rgb ) + staticSwitch228 ) , 0.0 ) );
			#endif
			o.Emission = staticSwitch294.rgb;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float4 customPack3 : TEXCOORD3;
				float4 customPack4 : TEXCOORD4;
				float3 worldPos : TEXCOORD5;
				float4 screenPos : TEXCOORD6;
				float3 worldNormal : TEXCOORD7;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack2.xyzw = customInputData.uv_tex4coord;
				o.customPack2.xyzw = v.texcoord;
				o.customPack3.xyzw = customInputData.uv2_tex4coord2;
				o.customPack3.xyzw = v.texcoord1;
				o.customPack4.xyzw = customInputData.uv3_tex4coord3;
				o.customPack4.xyzw = v.texcoord2;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				o.color = v.color;
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv_tex4coord = IN.customPack2.xyzw;
				surfIN.uv2_tex4coord2 = IN.customPack3.xyzw;
				surfIN.uv3_tex4coord3 = IN.customPack4.xyzw;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				surfIN.screenPos = IN.screenPos;
				surfIN.vertexColor = IN.color;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT( UnityGI, gi );
				o.Alpha = LightingStandardCustomLighting( o, worldViewDir, gi ).a;
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18100
945;90;448;596;194.5788;1571.337;1.746089;False;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;304;-1169.344,-497.8573;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;303;-1169.344,-673.8585;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;11;100.7668,-541.4943;Half;False;Property;_MainTex_V;主贴图流动_V;25;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;99.59985,-613.2946;Half;False;Property;_MainTex_U;主贴图流动_U;24;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;427;-3092.747,-2529.653;Half;False;Property;_DestortionTex_V1;扰动流动_V;39;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;305;-914.4757,-547.5231;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;426;-3093.914,-2601.454;Half;False;Property;_DestortionTex_U1;扰动流动_U;38;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;428;-2923.09,-2556.253;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;306;-770.4028,-577.7506;Inherit;False;Property;_Custom2xyKey;制作模式;4;0;Create;False;0;0;False;1;Header(Set Mode);False;0;1;1;True;;KeywordEnum;2;Mesh;Particle;Create;True;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleTimeNode;432;-2929.313,-2627.372;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;270.4257,-568.0945;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;23;263.1686,-641.9739;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;483;-2377.253,-2364.217;Inherit;False;Property;_DestortionTexRotate;扰动贴图旋转;36;0;Create;False;0;0;False;0;False;0;0;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;8;257.5007,-466.7482;Inherit;False;0;1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;307;-545.6491,-570.4002;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TextureCoordinatesNode;430;-2936.014,-2454.906;Inherit;False;0;73;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;429;-2746.346,-2574.933;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;447.1677,-586.7742;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;484;-2341.004,-2543.528;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;9;627.9943,-580.3872;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;173;-332.3184,-570.3377;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;431;-2620.518,-2571.545;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;332;889.2137,-588.7006;Inherit;False;MainUVMove;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;350;-216.2833,-576.4705;Inherit;False;Costom1XY;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;485;-2350.325,-2674.888;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;369;-1258.125,-1041.135;Half;False;Property;_DissolveTex_U1;溶解贴图流动_U;29;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;368;-1256.956,-969.334;Half;False;Property;_DissolveTex_V1;溶解贴图流动_V;30;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;353;-217.5821,-434.2707;Inherit;False;Costom1W;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;371;-1087.299,-995.9348;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;355;-2041.234,-2364.894;Inherit;False;353;Costom1W;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;370;-1094.555,-1069.814;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;405;-1308.531,-1317.674;Inherit;False;332;MainUVMove;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-2023.684,-2443.776;Half;False;Property;_DestortionIntensity;扰动强度;37;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;375;-1289.717,-1225.593;Inherit;False;350;Costom1XY;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;73;-2135.816,-2666.095;Inherit;True;Property;_DestortionTex;扰动贴图;35;0;Create;False;0;0;False;1;Header(Noise Mode);False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;374;-1100.223,-894.5892;Inherit;False;0;123;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;221;-1078.142,-1290.264;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;372;-910.5558,-1014.614;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;74;-1841.293,-2665.821;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;-1822.365,-2411.225;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;412;-888.9376,-1304.102;Inherit;False;Property;_MainTexToDissolve1;主贴图流动影响溶解;26;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;373;-778.5491,-1013.248;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;113;-1622.058,-2666.443;Half;False;Destortion;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;-1672.809,-2372.283;Half;False;DestortionIntensity_Var;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;161;-1316.203,-1356.621;Inherit;False;3153.071;580.6782;;7;471;158;517;519;472;473;123;溶解;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;189;-63.98279,-2562.61;Inherit;False;2;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;157;-401.2158,-1068.662;Inherit;False;115;DestortionIntensity_Var;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;-372.3371,-1159.086;Inherit;False;113;Destortion;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;472;-596.8586,-951.2231;Inherit;False;Property;_DissolveTexrotate;溶解贴图旋转;28;0;Create;False;0;0;False;0;False;180;180;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;344;-598.1347,-1233.288;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;446;139.1952,-2540.336;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;158;-185.4081,-1188.98;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;473;-286.4436,-954.1438;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;381;-27.32186,-1674.557;Half;False;Property;_MaskTex02_V1;遮罩流动02_V;48;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;471;-38.85088,-1052.207;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;379;-28.48885,-1746.358;Half;False;Property;_MaskTex02_U1;遮罩流动02_U;47;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;382;-23.51081,-2147.907;Half;False;Property;_MaskTex_U1;遮罩贴图流动_U;43;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;447;266.8608,-2582.714;Inherit;False;Property;_MaskCustomDataKey2;遮罩自定义数据开关;42;0;Create;False;0;0;False;0;False;0;1;1;True;;KeywordEnum;2;On;Off;Create;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;380;-22.34382,-2076.107;Half;False;Property;_MaskTex_V1;遮罩贴图流动_V;44;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;377;-100.4029,-2239.989;Inherit;False;813.3964;389.2258;UV流动组件;1;389;UV流动组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;518;-99.05506,-826.8046;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;517;-86.8481,-905.0277;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;386;140.0566,-2176.586;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;385;142.334,-1701.157;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;393;519.9705,-2582.349;Inherit;False;Costom2y;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;384;135.0791,-1775.036;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;383;147.3125,-2102.708;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;389;-18.58915,-2003.905;Inherit;False;0;47;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;477;238.4567,-1893.657;Inherit;False;Property;_MaskTexrotate2;遮罩贴图2旋转;46;0;Create;False;0;0;False;0;False;0;0;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;441;173.6147,-1918.736;Inherit;False;393;Costom2y;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;390;129.4112,-1599.811;Inherit;False;0;59;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;519;32.77036,-874.6622;Inherit;False;Property;_transparentforR2;溶解贴图clamp模式;22;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;387;324.0558,-2121.387;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;388;319.0782,-1719.837;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;476;142.5969,-2360.669;Inherit;False;Property;_MaskTexrotate1;遮罩贴图1旋转;41;0;Create;False;0;0;False;0;False;0;0;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;391;499.9053,-1713.45;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;478;522.8638,-1888.24;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;123;96.00948,-1246.85;Inherit;True;Property;_DissolveTex;溶解贴图;27;0;Create;False;0;0;False;1;Header(Dissslve Mode);False;-1;None;60ea76ffaabed9e428d8b52338218435;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;392;446.1621,-2121.246;Inherit;True;3;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;352;-213.7803,-503.2705;Inherit;False;Costom1Z;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;474;446.298,-2358.87;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;357;-4307.604,167.0052;Inherit;False;115;DestortionIntensity_Var;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;356;-4274.189,82.14182;Inherit;False;113;Destortion;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;132;256.0336,-949.2099;Half;False;Property;_DissolveIntensityCustom1z;溶解强度;31;0;Create;False;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;479;730.8538,-1927.258;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DesaturateOpNode;125;380.0887,-1223.625;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;354;329.3839,-869.4948;Inherit;False;352;Costom1Z;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;424;-4278.167,4.241505;Inherit;False;332;MainUVMove;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;475;644.6409,-2379.799;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;311;591.737,-1005.118;Inherit;False;Constant;_Float1;Float 1;54;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;127;360.2088,-1064.518;Half;False;Constant;_Float0;Float 0;26;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;59;737.0088,-1705.701;Inherit;True;Property;_MaskTex02;遮罩贴图02;45;0;Create;False;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;460;-3811.485,92.05013;Inherit;False;Property;_Maintexrotate;主帖图旋转;19;0;Create;False;0;0;False;0;False;0;180;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;124;546.372,-1229.325;Inherit;True;True;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;47;748.2192,-2142.836;Inherit;True;Property;_MaskTex;遮罩贴图;40;0;Create;False;0;0;False;1;Header(Mask Mode);False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;376;-4270.625,-98.63583;Inherit;False;350;Costom1XY;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;208;598.1088,-929.0492;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;75;-4038.83,9.783424;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;177;-3796.16,-94.63113;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;461;-3532.485,99.05013;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;61;1027.321,-1700.956;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;310;757.8365,-977.1183;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;126;790.4267,-1224.877;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;50;1032.943,-2136.897;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;225;-1270.395,-2366.468;Inherit;False;Property;_FresnelPower;菲尼尔强度;12;0;Create;False;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;144;898.1696,-966.388;Half;False;Property;_SoftaDissolve;软硬边强度;32;0;Create;False;0;0;False;0;False;0;0.9;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;224;-1272.627,-2438.151;Inherit;False;Property;_FresnelScale;菲尼尔宽度;11;0;Create;False;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;266;-1248.948,-2119.127;Inherit;False;Property;_ModeFresnel_Power1;虚化范围过渡;15;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;190;819.3256,-1079.839;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;48;1193.102,-2140.578;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RotatorNode;462;-3300.743,-96.48003;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;233;-1271.106,-2646.214;Inherit;False;Property;_FresnelColor;菲尼尔颜色;10;1;[HDR];Create;False;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;122;-3176.95,-2196.87;Inherit;False;1766.87;743.8306;;3;453;458;455;顶点偏移;1,1,1,1;0;0
Node;AmplifyShaderEditor.ComponentMaskNode;62;1187.479,-1702.914;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;80;829.1334,-2471.077;Half;False;Property;_DepthFade;深度消隐强度;8;0;Create;False;0;0;False;0;False;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;453;-3063.064,-2010.578;Half;False;Property;_VertexOffsetTex_V1;顶点偏移流动_V;54;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;267;-1248.141,-2285.155;Inherit;False;Property;_ModeFresnel_Bias1;虚化强度;16;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;78;1010.867,-2491.459;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;511;-2839.086,-10.71583;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;147;1203.734,-1004.532;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;512;-2833.564,-131.4536;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;268;-1241.688,-2203.338;Inherit;False;Property;_ModeFresnel_Scale1;虚化范围;14;0;Create;False;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;454;-3064.232,-2082.377;Half;False;Property;_VertexOffsetTex_U1;顶点偏移流动_U;53;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;1375.968,-1945.173;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;258;-1044.748,-2632.699;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;248;-1073.577,-2495.363;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;270;-1049.413,-2118.563;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;130;995.0477,-1226.348;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;396;1654.792,-1940.868;Inherit;False;Mask;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;142;1213.513,-1219.715;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;234;-724.9946,-2586.074;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;456;-2900.663,-2111.055;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;271;-894.0822,-2262.943;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;281;-3218.76,-936.5535;Inherit;False;Property;_AirDistortionTex_U1;扭曲流动_U;59;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;81;1262.527,-2497.462;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;120;-2153.76,-188.5954;Inherit;False;618.6554;280;;1;1;主帖图;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;455;-2893.407,-2037.178;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;282;-3215.691,-838.2527;Inherit;False;Property;_AirDistortionTex_V1;扭曲流动_V;60;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;516;-2262.25,16.3704;Inherit;False;Constant;_Float2;Float 2;60;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;515;-2542.23,-112.0121;Inherit;False;Property;_transparentforR1;主贴图clamp模式;21;0;Create;False;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;25;-1962.587,164.4151;Half;False;Property;_Color;颜色;17;1;[HDR];Create;False;0;0;False;1;Header(Main Mode);False;1,1,1,1;2.118547,2.118547,2.118547,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;457;-2716.664,-2055.857;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;345;1442.518,-1225.437;Inherit;False;Dissolve;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;480;-3136.026,-1276.311;Inherit;False;Property;_AirDistortionTexRotate;空气扭曲贴图旋转;57;0;Create;False;0;0;False;0;False;0;0;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;29;-2042.991,472.1846;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;272;-652.675,-2251.467;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;341;1414.072,-2458.07;Inherit;False;DepthFade;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;283;-2945.758,-907.5535;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;458;-2906.331,-1935.831;Inherit;False;0;98;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;295;-3268.76,-1367.748;Inherit;False;1848.344;686.4165;;1;286;热扭曲;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;399;-468.2402,-2579.225;Inherit;False;Fresnel;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;397;-1922.654,745.441;Inherit;False;396;Mask;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;1;-2108.401,-138.5955;Inherit;True;Property;_MainTex;主贴图;18;0;Create;False;0;0;False;0;False;-1;None;a469614a18d86f346ac6d9fd04bf7500;True;0;False;white;Auto;False;Object;-1;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;284;-3023.964,-1087.868;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;114;-3017.161,-1652.61;Inherit;False;113;Destortion;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;459;-2535.836,-2049.47;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;342;-683.4825,478.2032;Inherit;False;341;DepthFade;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;273;-491.1678,-2255.494;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;286;-2839.756,-1082.555;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;400;-737.4606,266.1151;Inherit;False;399;Fresnel;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-1184.405,365.9721;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;481;-2832.325,-1274.512;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;149;-1312.831,-1674.263;Half;False;Property;_LineWidth;亮边值;34;0;Create;False;0;0;False;0;False;0;0;0;0.85;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;395;518.1968,-2445.887;Inherit;False;Costom2w;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;117;-3032.06,-1576.359;Inherit;False;115;DestortionIntensity_Var;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;348;-1317.672,-1881.984;Inherit;False;345;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;398;-360.8409,-2260.564;Inherit;False;FresnelFeather;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;404;-2492.531,-763.6229;Inherit;False;395;Costom2w;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;287;-2441.837,-840.4577;Inherit;False;Property;_AirDistortion_Intensity1;扭曲强度;58;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;482;-2633.982,-1295.441;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;152;-1124.336,-1610;Half;False;Constant;_LineRange;LineRange;18;0;Create;True;0;0;False;0;False;0.85;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;116;-2802.499,-1646.228;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;228;-564.1088,241.4926;Inherit;False;Property;_FresnelKey;菲尼尔开关;9;0;Create;False;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;Off;On;Create;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;148;-1123.993,-1896.978;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;466;-2006.393,-316.1572;Inherit;False;Property;_Gradation;色阶;23;0;Create;False;0;0;False;0;False;0,1;0,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;83;-502.4268,368.2565;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;488;-2604.003,-2153.53;Inherit;False;Property;_VertexOffsetTexRotate;顶点偏移贴图旋转;51;0;Create;False;0;0;False;0;False;0;0;-180;180;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;118;-2656.168,-1684.907;Inherit;False;Property;_DestortionToVertexOffset;扰动影响顶点偏移;49;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StepOpNode;150;-901.3428,-1888.352;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;467;-1719.393,-127.1572;Inherit;False;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,1;False;3;COLOR;0,0,0,0;False;4;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;324;-61.88151,339.7911;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;289;-2293.182,-811.4977;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;401;-81.4759,466.2568;Inherit;False;398;FresnelFeather;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;151;-895.5808,-1670.085;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;288;-2486.357,-1116.654;Inherit;True;Property;_AirDistortionTex;空气扭曲贴图;56;0;Create;False;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;487;-2263.948,-2156.138;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-180;False;2;FLOAT;180;False;3;FLOAT;-3.15;False;4;FLOAT;3.15;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;153;-654.1105,-1843.158;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;486;-2003.563,-2149.545;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;394;518.1968,-2509.159;Inherit;False;Costom2z;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;290;-2427.434,-1317.748;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;291;-2139.839,-933.2736;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;318;146.9144,445.1352;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;166;-606.9142,-1635.623;Half;False;Property;_DissolveLineColor;亮边颜色;33;1;[HDR];Create;False;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;468;-1530.393,-128.1572;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;346;358.1221,464.5862;Inherit;False;345;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;292;-1986.508,-1057.248;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-2130.681,-1700.998;Inherit;False;Property;_VertexOffsetIntensity;顶点偏移强度;52;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;167;-403.2583,-1694.492;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;2;-1395.104,-136.3302;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;275;307.6561,336.9938;Inherit;False;Property;_if_ModeDepthFade1;边缘虚化开关;13;0;Create;False;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;Off;On;Create;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;98;-2300.827,-1985.485;Inherit;True;Property;_VertexOffsetTex;顶点偏移贴图;50;0;Create;False;0;0;False;1;Header(Vertex Mode);False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;30;-1824.378,461.5714;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;403;-2129.692,-1634.833;Inherit;False;394;Costom2z;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;28;-1778.528,161.9293;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DesaturateOpNode;102;-1995.017,-1979.615;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScreenColorNode;293;-1873.38,-1061.953;Inherit;False;Global;_GrabScreen0;Grab Screen 0;2;0;Create;True;0;0;False;0;False;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-1187.358,84.04826;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;154;-360.7444,-1851.956;Half;False;DissolveLine;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;326;549.2067,341.7461;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;100;-2006.687,-1841.593;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;209;-1920.246,-1692.887;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;331;-1615.497,-1065.823;Inherit;False;AirDistortion;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;163;-262.0775,-7.115593;Inherit;False;154;DissolveLine;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;99;-1749.339,-2002.639;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;325;-201.8443,89.46216;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;315;702.4304,264.1497;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;469;854.7173,174.2421;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;-4.515182,-2.162216;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;339;-1617.901,-2001.639;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;334;338.0401,55.04776;Inherit;False;331;AirDistortion;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;261;1484.223,188.3296;Inherit;False;Property;_Tile1;Custom：添加Custom1.xy、Custom1.xyzw、Custom2.xyzw;1;0;Create;False;2;Alpha;10;Add;1;0;True;1;Header(Instruction);False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;262;1483.518,266.7404;Inherit;False;Property;_Tile2;Custom1.xy是主贴图流动，Custom1.z是溶解强度，Custom1.w是扰动强度;2;0;Create;False;2;Alpha;10;Add;1;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;514;-4113.755,809.1733;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;264;1502.275,-62.08017;Inherit;False;Property;_ZWrite;深度模式;7;1;[Enum];Create;False;3;Default;0;On;1;Off;2;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;340;763.1603,382.5781;Inherit;False;339;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;263;1486.788,345.9188;Inherit;False;Property;_Tile3;Custom2.xy是遮罩流动，Custom2.z是顶点偏移强度，Custom2.w是空气扭曲强度;3;0;Create;False;2;Alpha;10;Add;1;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;470;1000.717,200.2421;Inherit;False;Property;_transparentforR;利用R通道作为透明度;20;0;Create;False;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;237;1502.818,111.1872;Inherit;False;Property;_Dst;材质模式;5;1;[Enum];Create;False;2;AlphaBlend;10;Additive;1;0;True;0;False;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;294;590.954,-14.27068;Inherit;False;Property;_AirDistortionSwitch1;空气扭曲开关;55;0;Create;False;0;0;False;1;Header(AirDistortion Mode);False;0;0;0;True;;KeywordEnum;2;Off;On;Create;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;39;1504.432,21.77116;Inherit;False;Property;_CullMode;剔除模式;6;1;[Enum];Create;False;1;Option1;0;1;UnityEngine.Rendering.CullMode;True;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1249.31,-49.34332;Half;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Effect/All;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Off;0;True;264;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;236;10;True;237;0;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;True;39;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.CommentaryNode;425;-3107.892,-2678.417;Inherit;False;813.3964;389.2258;UV流动组件;0;UV流动组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;64;-118.0904,-2282.847;Inherit;False;1965.9;852.6161;;0;Mask组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;308;-1219.344,-723.8587;Inherit;False;1178.722;433.0001;;0;制作模式开关;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;32;-2096.586,111.9291;Inherit;False;541.0586;264.4858;;0;颜色;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;35;-1234.405,315.9721;Inherit;False;212;209;;0;不透明度;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;34;-1237.358,34.04826;Inherit;False;212;209;;0;自发光;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;121;815.1823,-2614.591;Inherit;False;795.401;274.4528;;0;深度消隐;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;378;-105.3809,-1838.438;Inherit;False;813.3964;389.2258;UV流动组件;0;UV流动组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;276;-1334.37,-2681.139;Inherit;False;1171.577;668.1097;;0;Fresnel外发光和边缘虚化;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;33;-2092.99,406.1845;Inherit;False;496.9998;273.0001;;0;顶点颜色;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;367;-1308.123,-1119.814;Inherit;False;773.2299;347.313;UV流动组件;0;UV流动组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;162;-1328.742,-1956.911;Inherit;False;1150.629;524.4127;;0;描边;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;119;-3041.383,-1739.87;Inherit;False;677.2575;254.0538;;0;UV扰动影响顶点偏移;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;24;49.59985,-691.9741;Inherit;False;1119.304;385.9007;UV流动组件;0;MainUV流动组件;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;77;-3129.786,-2726.448;Inherit;False;1711.626;453.7844;;0;UV扰动;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;155;-404.4238,-1298.541;Inherit;False;398.7141;319.8806;;0;UV扰动影响溶解;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;313;-76.13221,-2622.435;Inherit;False;812.0739;258.0855;;0;自定义数据开关;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;452;-3114.231,-2161.055;Inherit;False;813.3964;389.2258;UV流动组件;0;UV流动组件;1,1,1,1;0;0
WireConnection;305;0;303;3
WireConnection;305;1;303;4
WireConnection;305;2;304;3
WireConnection;305;3;304;4
WireConnection;428;0;426;0
WireConnection;428;1;427;0
WireConnection;306;0;305;0
WireConnection;13;0;10;0
WireConnection;13;1;11;0
WireConnection;307;0;306;0
WireConnection;429;0;432;0
WireConnection;429;1;428;0
WireConnection;22;0;23;0
WireConnection;22;1;13;0
WireConnection;484;0;483;0
WireConnection;9;0;22;0
WireConnection;9;1;8;0
WireConnection;173;0;307;0
WireConnection;173;1;307;1
WireConnection;431;0;429;0
WireConnection;431;1;430;0
WireConnection;332;0;9;0
WireConnection;350;0;173;0
WireConnection;485;0;431;0
WireConnection;485;2;484;0
WireConnection;353;0;307;3
WireConnection;371;0;369;0
WireConnection;371;1;368;0
WireConnection;73;1;485;0
WireConnection;221;0;405;0
WireConnection;221;1;375;0
WireConnection;372;0;370;0
WireConnection;372;1;371;0
WireConnection;74;0;73;0
WireConnection;196;0;76;0
WireConnection;196;1;355;0
WireConnection;412;0;221;0
WireConnection;373;0;372;0
WireConnection;373;1;374;0
WireConnection;113;0;74;0
WireConnection;115;0;196;0
WireConnection;344;0;412;0
WireConnection;344;1;373;0
WireConnection;446;0;189;1
WireConnection;446;1;189;2
WireConnection;158;0;344;0
WireConnection;158;1;156;0
WireConnection;158;2;157;0
WireConnection;473;0;472;0
WireConnection;471;0;158;0
WireConnection;471;2;473;0
WireConnection;447;1;446;0
WireConnection;518;0;471;0
WireConnection;517;0;471;0
WireConnection;385;0;379;0
WireConnection;385;1;381;0
WireConnection;393;0;447;0
WireConnection;383;0;382;0
WireConnection;383;1;380;0
WireConnection;519;1;517;0
WireConnection;519;0;518;0
WireConnection;387;0;386;0
WireConnection;387;1;383;0
WireConnection;388;0;384;0
WireConnection;388;1;385;0
WireConnection;391;0;388;0
WireConnection;391;1;390;0
WireConnection;478;0;477;0
WireConnection;123;1;519;0
WireConnection;392;0;387;0
WireConnection;392;1;389;0
WireConnection;392;2;441;0
WireConnection;352;0;307;2
WireConnection;474;0;476;0
WireConnection;479;0;391;0
WireConnection;479;2;478;0
WireConnection;125;0;123;0
WireConnection;475;0;392;0
WireConnection;475;2;474;0
WireConnection;59;1;479;0
WireConnection;124;0;125;0
WireConnection;47;1;475;0
WireConnection;208;0;132;0
WireConnection;208;1;354;0
WireConnection;75;0;424;0
WireConnection;75;1;356;0
WireConnection;75;2;357;0
WireConnection;177;0;376;0
WireConnection;177;1;75;0
WireConnection;461;0;460;0
WireConnection;61;0;59;0
WireConnection;310;0;311;0
WireConnection;310;1;208;0
WireConnection;126;0;124;0
WireConnection;126;1;127;0
WireConnection;50;0;47;0
WireConnection;190;0;126;0
WireConnection;190;1;310;0
WireConnection;48;0;50;0
WireConnection;462;0;177;0
WireConnection;462;2;461;0
WireConnection;62;0;61;0
WireConnection;78;0;80;0
WireConnection;511;0;462;0
WireConnection;147;0;144;0
WireConnection;512;0;462;0
WireConnection;51;0;48;0
WireConnection;51;1;62;0
WireConnection;258;0;233;0
WireConnection;248;2;224;0
WireConnection;248;3;225;0
WireConnection;270;0;266;0
WireConnection;130;0;190;0
WireConnection;396;0;51;0
WireConnection;142;0;130;0
WireConnection;142;2;147;0
WireConnection;234;0;258;0
WireConnection;234;1;248;0
WireConnection;271;1;267;0
WireConnection;271;2;268;0
WireConnection;271;3;270;0
WireConnection;81;0;78;0
WireConnection;455;0;454;0
WireConnection;455;1;453;0
WireConnection;515;1;512;0
WireConnection;515;0;511;0
WireConnection;457;0;456;0
WireConnection;457;1;455;0
WireConnection;345;0;142;0
WireConnection;272;0;271;0
WireConnection;341;0;81;0
WireConnection;283;0;281;0
WireConnection;283;1;282;0
WireConnection;399;0;234;0
WireConnection;1;1;515;0
WireConnection;1;2;516;0
WireConnection;459;0;457;0
WireConnection;459;1;458;0
WireConnection;273;0;272;0
WireConnection;286;0;284;0
WireConnection;286;2;283;0
WireConnection;27;0;1;4
WireConnection;27;1;25;4
WireConnection;27;2;29;4
WireConnection;27;3;397;0
WireConnection;481;0;480;0
WireConnection;395;0;189;4
WireConnection;398;0;273;0
WireConnection;482;0;286;0
WireConnection;482;2;481;0
WireConnection;116;0;459;0
WireConnection;116;1;114;0
WireConnection;116;2;117;0
WireConnection;228;0;400;0
WireConnection;148;0;348;0
WireConnection;148;1;149;0
WireConnection;83;0;27;0
WireConnection;83;1;342;0
WireConnection;118;1;459;0
WireConnection;118;0;116;0
WireConnection;150;0;148;0
WireConnection;150;1;152;0
WireConnection;467;0;1;0
WireConnection;467;3;466;1
WireConnection;467;4;466;2
WireConnection;324;0;228;0
WireConnection;324;1;83;0
WireConnection;289;0;287;0
WireConnection;289;1;404;0
WireConnection;151;0;348;0
WireConnection;151;1;152;0
WireConnection;288;1;482;0
WireConnection;487;0;488;0
WireConnection;153;0;151;0
WireConnection;153;1;150;0
WireConnection;486;0;118;0
WireConnection;486;2;487;0
WireConnection;394;0;189;3
WireConnection;291;0;288;0
WireConnection;291;1;289;0
WireConnection;318;0;324;0
WireConnection;318;1;401;0
WireConnection;468;0;467;0
WireConnection;292;0;290;0
WireConnection;292;1;291;0
WireConnection;167;0;153;0
WireConnection;167;1;166;0
WireConnection;2;0;468;0
WireConnection;275;1;324;0
WireConnection;275;0;318;0
WireConnection;98;1;486;0
WireConnection;30;0;29;0
WireConnection;28;0;25;0
WireConnection;102;0;98;0
WireConnection;293;0;292;0
WireConnection;26;0;2;0
WireConnection;26;1;28;0
WireConnection;26;2;30;0
WireConnection;154;0;167;0
WireConnection;326;0;275;0
WireConnection;326;1;346;0
WireConnection;209;0;103;0
WireConnection;209;1;403;0
WireConnection;331;0;293;0
WireConnection;99;0;102;0
WireConnection;99;1;100;0
WireConnection;99;2;209;0
WireConnection;325;0;26;0
WireConnection;325;1;228;0
WireConnection;315;0;326;0
WireConnection;469;0;1;1
WireConnection;469;1;315;0
WireConnection;164;0;163;0
WireConnection;164;1;325;0
WireConnection;339;0;99;0
WireConnection;470;1;315;0
WireConnection;470;0;469;0
WireConnection;294;1;164;0
WireConnection;294;0;334;0
WireConnection;0;2;294;0
WireConnection;0;9;470;0
WireConnection;0;11;340;0
ASEEND*/
//CHKSM=DA10AC0C136472D4B3525CD40F31714820279271