// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

#ifndef PCFHELPER_INCLUDED
#define PCFHELPER_INCLUDED

    #include "HLSLSupport.cginc"

    // ------------ Shadow helpers --------


	// ---- Screen space shadows
	#if defined (SHADOWS_SCREEN)

		uniform float4 _ShadowOffsets[4];

		#if defined(SHADOWS_NATIVE)
			UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
		#else
			uniform sampler2D _ShadowMapTexture;
		#endif

		#define SHADOW_COORDS(idx1) float4 _ShadowCoord : TEXCOORD##idx1;

		#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
			#define TRANSFER_SHADOW(a) a._ShadowCoord = mul( unity_WorldToShadow[0], mul( unity_ObjectToWorld, v.vertex ) );

			inline fixed unitySampleShadow (float4 shadowCoord)
			{
				#if defined(SHADOWS_NATIVE)

					fixed shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);
					shadow = _LightShadowData.r + shadow * (1-_LightShadowData.r);
					return shadow;

				#else

					float dist = tex2Dproj( _ShadowMapTexture, UNITY_PROJ_COORD(shadowCoord) ).x;

					// tegra is confused if we use _LightShadowData.x directly
					// with "ambiguous overloaded function reference max(mediump float, float)"
					half lightShadowDataX = _LightShadowData.x;
					return max(dist > (shadowCoord.z/shadowCoord.w), lightShadowDataX);

				#endif
			}

		#else // UNITY_NO_SCREENSPACE_SHADOWS

			#define TRANSFER_SHADOW(a) a._ShadowCoord = ComputeScreenPos(a.pos);

			inline fixed unitySampleShadow (float4 shadowCoord)
			{
				fixed shadow = tex2Dproj( _ShadowMapTexture, UNITY_PROJ_COORD(shadowCoord) ).r;
				return shadow;
			}

		#endif

		#define SHADOW_ATTENUATION(a, b) unitySampleShadow(a + b)

	#endif


	// ---- Depth map shadows

	#if defined (SHADOWS_DEPTH) && defined (SPOT)

		#if !defined(SHADOWMAPSAMPLER_DEFINED)
			UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
		#endif
		#if defined (SHADOWS_SOFT)
			uniform float4 _ShadowOffsets[4];
		#endif

		inline fixed unitySampleShadow (float4 shadowCoord)
		{
			// Always 1-tap
			// 1-tap shadows

            #if defined (SHADOWS_NATIVE)
                half shadow = UNITY_SAMPLE_SHADOW_PROJ(_ShadowMapTexture, shadowCoord);
                shadow = _LightShadowData.r + shadow * (1-_LightShadowData.r);
            #else
                half shadow = SAMPLE_DEPTH_TEXTURE_PROJ(_ShadowMapTexture, UNITY_PROJ_COORD(shadowCoord)) < (shadowCoord.z / shadowCoord.w) ? _LightShadowData.r : 1.0;
            #endif
			return shadow;
		}
		
		#define SHADOW_COORDS(idx1) float4 _ShadowCoord : TEXCOORD##idx1;
		#define TRANSFER_SHADOW(a) a._ShadowCoord = mul (unity_WorldToShadow[0], mul(unity_ObjectToWorld,v.vertex));
		#define SHADOW_ATTENUATION(a, b) unitySampleShadow(a + b)

	#endif


	// ---- Point light shadows

	#if defined (SHADOWS_CUBE)

		uniform samplerCUBE _ShadowMapTexture;
		inline float SampleCubeDistance (float3 vec)
		{
			float4 packDist = texCUBE (_ShadowMapTexture, vec);
			return DecodeFloatRGBA( packDist );
		}
		inline float unityCubeShadow (float3 vec)
		{
			float mydist = length(vec) * _LightPositionRange.w;
			mydist *= 0.97; // bias
            float dist = SampleCubeDistance (vec);
            return dist < mydist ? _LightShadowData.r : 1.0;
		}
		#define SHADOW_COORDS(idx1) float3 _ShadowCoord : TEXCOORD##idx1;
		#define TRANSFER_SHADOW(a) a._ShadowCoord = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
		#define SHADOW_ATTENUATION(a, b) unityCubeShadow(a + b)

	#endif



	// ---- Shadows off
	#if !defined (SHADOWS_SCREEN) && !defined (SHADOWS_DEPTH) && !defined (SHADOWS_CUBE)

		#define SHADOW_COORDS(idx1)
		#define TRANSFER_SHADOW(a)
		#define SHADOW_ATTENUATION(a, b) 1.0

	#endif



	// ------------ Light helpers --------

	// If none of the keywords are defined, assume directional?
	#if !defined(POINT) && !defined(SPOT) && !defined(DIRECTIONAL) && !defined(POINT_COOKIE) && !defined(DIRECTIONAL_COOKIE)
		#define DIRECTIONAL
	#endif


	#ifdef POINT
		#define LIGHTING_COORDS(idx1,idx2) float3 _LightCoord : TEXCOORD##idx1; SHADOW_COORDS(idx2)
		uniform sampler2D _LightTexture0;
		uniform float4x4 unity_WorldToLight;
		#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz; TRANSFER_SHADOW(a)
		#define LIGHT_ATTENUATION(lc, sc, b)	(tex2D(_LightTexture0, dot(lc, lc).rr).UNITY_ATTEN_CHANNEL * SHADOW_ATTENUATION(sc, b))
        #define LIGHT_FADEOUT(lc) (tex2D(_LightTexture0, dot(lc, lc).rr).UNITY_ATTEN_CHANNEL)
	#endif

	#ifdef SPOT
		#define LIGHTING_COORDS(idx1,idx2) float4 _LightCoord : TEXCOORD##idx1; SHADOW_COORDS(idx2)
		uniform sampler2D _LightTexture0;
		uniform float4x4 unity_WorldToLight;
		uniform sampler2D _LightTextureB0;
		#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)); TRANSFER_SHADOW(a)
		inline fixed UnitySpotCookie(float4 LightCoord)
		{
			return tex2D(_LightTexture0, LightCoord.xy / LightCoord.w + 0.5).w;
		}
		inline fixed UnitySpotAttenuate(float3 LightCoord)
		{
			return tex2D(_LightTextureB0, dot(LightCoord, LightCoord).xx).UNITY_ATTEN_CHANNEL;
		}
		#define LIGHT_ATTENUATION(lc, sc, b)	( (lc.z > 0) * UnitySpotCookie(lc) * UnitySpotAttenuate(lc.xyz) * SHADOW_ATTENUATION(sc, b))
        #define LIGHT_FADEOUT(lc) ((lc.z > 0) * UnitySpotCookie(lc) * UnitySpotAttenuate(lc.xyz))
	#endif


	#ifdef DIRECTIONAL
		#define LIGHTING_COORDS(idx1,idx2) SHADOW_COORDS(idx1)
		#define TRANSFER_VERTEX_TO_FRAGMENT(a) TRANSFER_SHADOW(a)
		#define LIGHT_ATTENUATION(lc, sc, b) SHADOW_ATTENUATION(sc, b)
        #define LIGHT_FADEOUT(lc) 1.0
	#endif


	#ifdef POINT_COOKIE
		#define LIGHTING_COORDS(idx1,idx2) float3 _LightCoord : TEXCOORD##idx1; SHADOW_COORDS(idx2)
		uniform samplerCUBE _LightTexture0;
		uniform float4x4 unity_WorldToLight;
		uniform sampler2D _LightTextureB0;
		#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz; TRANSFER_SHADOW(a)
		#define LIGHT_ATTENUATION(lc, sc, b)	(tex2D(_LightTextureB0, dot(lc,lc).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lc).w * SHADOW_ATTENUATION(sc, b))
        #define LIGHT_FADEOUT(lc) (tex2D(_LightTextureB0, dot(lc,lc).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lc).w)
	#endif

	#ifdef DIRECTIONAL_COOKIE
		#define LIGHTING_COORDS(idx1,idx2) float2 _LightCoord : TEXCOORD##idx1; SHADOW_COORDS(idx2)
		uniform sampler2D _LightTexture0;
		uniform float4x4 unity_WorldToLight;
		#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xy; TRANSFER_SHADOW(a)
		#define LIGHT_ATTENUATION(lc, sc, b)	(tex2D(_LightTexture0, lc).w * SHADOW_ATTENUATION(sc, b))
        #define LIGHT_FADEOUT(lc) (tex2D(_LightTexture0, lc).w)
	#endif
    /*
    inline float PCF_SampleShadowMap(float2 lc, float4 sc, float4 offset){
        float shadow = SHADOW_ATTENUATION(sc, offset);
        float fade = LIGHT_FADEOUT(lc);
        return fade * shadow;
    }

    inline float PCF_SampleShadowMap(float3 lc, float4 sc, float4 offset){
        float shadow = SHADOW_ATTENUATION(sc, offset);
        float fade = LIGHT_FADEOUT(lc);
        return fade * shadow;
    }

    inline float PCF_SampleShadowMap(float4 lc, float4 sc, float4 offset){
        float shadow = SHADOW_ATTENUATION(sc, offset);
        float fade = LIGHT_FADEOUT(lc);
        return fade * shadow;
    }*/
#endif
