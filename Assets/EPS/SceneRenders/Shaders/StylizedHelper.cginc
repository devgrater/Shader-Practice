inline float stylized_lighting(fixed3 normal, fixed3 lightDir){
    fixed lighting = dot(normal, lightDir);
    //half lambert
    return lighting;
    //return half_lambertify(lighting);
}

inline float combine_shadow(fixed shadow1, fixed shadow2){
    return min(shadow1, shadow2);
}

inline float half_lambertify(fixed lighting){
    lighting = saturate(lighting);
    lighting = (lighting + 1) * 0.5f;
    lighting *= lighting;
    return lighting;
}

inline float toonify(fixed lighting, fixed maskValue){
    return smoothstep(0.01, 0.2, lighting);
}