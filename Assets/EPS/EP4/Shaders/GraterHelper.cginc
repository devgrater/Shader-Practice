
static const float3 random_vector = float3(1.334f, 2.241f, 3.919f);
static const float random_amount = 3838438.66411;
inline float random_from_pos(float3 pos){
    return frac(cos(dot(pos, random_vector)) * 383.8438);
}

inline float half_lambert_atten(float attenuation){
    attenuation = saturate((attenuation + 1) / 2);
    return attenuation * attenuation;
}