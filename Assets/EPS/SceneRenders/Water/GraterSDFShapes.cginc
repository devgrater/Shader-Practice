
float sphereSDF(float3 checkPoint, float3 origin, float radius){
    return length(checkPoint - origin) - radius;
}

float sphereSDFDft(float3 p, float radius){
    return length(p) - radius;
}

float cylinderSDF(float3 checkPoint, float3 origin, float radius, float height){
    float3 sdVector = checkPoint - origin;
    float2 d = abs(float2(length(sdVector.xz), sdVector.y)) - float2(height, radius);
    return min(max(d.x, d.y), 0.0f) + length(max(d, 0.0f));
}

float cylinderSDFDft(float3 sdVector, float radius, float height){
    float2 d = abs(float2(length(sdVector.xz), sdVector.y)) - float2(height, radius);
    return min(max(d.x, d.y), 0.0f) + length(max(d, 0.0f));
}

float boxSDF(float3 checkPoint, float3 center, float3 bounds){
    float3 sdVector = checkPoint - center;
    float3 diff = abs(sdVector) - bounds;
    return length(max(diff, 0.0f)) + min(max(diff.x, max(diff.y, diff.z)), 0.0f);
}

float torusSDF(float3 checkPoint, float3 center, float torusHeight, float ringRadius){
    float3 sdVector = checkPoint - center;
    float2 q = float2(length(sdVector.xz) - torusHeight, sdVector.y);
    return length(q) - ringRadius;
}

float planeSDF(float3 checkPoint, float planeHeight, float inverse){
    
    return (checkPoint.y - planeHeight) * inverse;
}

float planeSDFDft(float3 p, float inverse){
    
    return (p.y) * inverse;
}