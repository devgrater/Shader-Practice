float sdfUnion(float d1, float d2){
    return min(d1, d2);
}

float sdfSmoothUnion(float d1, float d2, float factor){
    float h = max(factor - abs(d1 - d2), 0.0f);
    return min(d1, d2) - h * h * 0.25 / factor;
}


float sdfIntersect(float d1, float d2){
    return max(d1, d2);
}

float sdfSmoothIntersect(float d1, float d2, float factor){
    float h = max(factor - abs(d1 - d2), 0.0f);
    return max(d1, d2) + h * h * 0.25 / factor;
}

float sdfSubtract(float d1, float d2){
    return max(-d1, d2);
}

float sdfSmoothSubtract(float d1, float d2, float factor){
    float h = max(factor - abs(-d1 - d2), 0.0f);
    return max(-d1, d2) + h * h * 0.25 / factor;
}