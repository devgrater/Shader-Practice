            ////////////////////// BRDF /////////////////////////
#define PI 3.1415926
inline float dfg_d(fixed nDotH, float roughness){
    fixed a = roughness * roughness;
    fixed alpha2 = a * a;
    fixed nDotH2 = nDotH * nDotH;
    float denom = nDotH2 * (alpha2 - 1) + 1;
    denom = denom * denom * PI;
    return alpha2 / denom;
}

inline float3 dfg_f_roughless(fixed cosTheta, float3 f0, fixed roughness){
    fixed omRoughness = 1.0 - roughness;
    return (f0) + (1 - f0) * pow(saturate(1.0 - cosTheta), 5.0);
}

inline float3 dfg_f(fixed cosTheta, float3 f0, fixed roughness){
    fixed omRoughness = 1.0 - roughness;
    return (f0) + (max(fixed3(omRoughness, omRoughness, omRoughness), f0) - f0) * pow(saturate(1.0 - cosTheta), 5.0);
}

inline float schlick_ggx(fixed nDotDir, fixed k){
    return saturate(nDotDir / (nDotDir * (1.0 - k) + k));
}

inline float dfg_g(fixed nDotV, fixed nDotL, fixed roughness){
    float r = roughness + 1.0;
    fixed k = r * r / 8.0;
    return schlick_ggx(nDotV, k) * schlick_ggx(nDotL, k);
}

inline float get_lod_from_roughness(fixed roughness){
    return roughness * (1.7 - 0.7 * roughness) * UNITY_SPECCUBE_LOD_STEPS;
}


inline fixed4 linear_space_color(fixed4 color){
    color = pow(color, 2.2);
    color *= (color + 1.0);
    return color;
}
