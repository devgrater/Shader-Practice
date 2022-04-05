float sdfUnion(float d1, float d2){
    return min(d1, d2);
}

float sdfSmoothUnion(float d1, float d2, float factor){
    float h = max(factor - abs(d1 - d2), 0.0f);//clamp(0.5f + 0.5f * (d2 - d1) / factor, 0.0f, 1.0f);
    return min(d1, d2) - h * h * 0.25 / factor;
    //return lerp(d2, d1, h) - factor * h * (1.0f - h);
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