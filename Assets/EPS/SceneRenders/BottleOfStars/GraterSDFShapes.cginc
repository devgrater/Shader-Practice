
float sphereSDF(float3 checkPoint, float3 origin, float radius){
    return length(checkPoint - origin) - radius;
}

float boxSDF(float3 checkPoint, float3 center, float3 bounds){
    float3 sdVector = checkPoint - center;
    float3 diff = abs(sdVector) - bounds;
    return length(max(diff, 0.0f)) + min(max(diff.x, max(diff.y, diff.z)), 0.0f);
}