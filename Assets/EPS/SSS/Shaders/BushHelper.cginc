
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"


struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 pos : SV_POSITION;
    LIGHTING_COORDS(2, 3)
    float3 normal : NORMAL;
    float rim : TEXCOORD4;
    float3 viewDir : TEXCOORD5;
};

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _Color;
fixed _Cutoff;

v2f vert (appdata v)
{
    v2f o;
    //i have no idea what to do
    //but i do know that I need to have the faces face the camera.
    //and i can do that with billboards.
    

    float3 centerOffset = v.vertex.xyz; 
    float2 tweakedUV = (v.uv.xy - 0.5f) * 2.0f;
    float3 viewSpaceUV = mul(float4(tweakedUV, 0.0f, 0.0f), UNITY_MATRIX_MV);
    //o.pos = UnityObjectToClipPos(v.vertex);

    float3 viewDir = normalize(WorldSpaceLightDir(v.vertex)) * 1.5;//ObjSpaceLightDir((v.vertex);)
    viewDir = mul(unity_WorldToObject, float4(viewDir, 1.0f));
    v.vertex.xyz += viewDir;
    v.vertex.xyz += v.normal * EXTRUSION;
    
    
    v.vertex.xyz += viewSpaceUV.xyz;
    o.pos = UnityObjectToClipPos(v.vertex.xyz);
    v.vertex.xyz -= viewDir;
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    o.pos = UnityObjectToClipPos(v.vertex.xyz);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    UNITY_TRANSFER_FOG(o, o.pos);
    //per vertex rimlight, because...
    o.viewDir = WorldSpaceViewDir(v.vertex);
    o.rim = dot(o.normal, o.viewDir);
    o.rim = saturate(o.rim);
    


    return o;
}

fixed4 frag (v2f i) : SV_Target
{
    
    // sample the texture
    fixed4 col = tex2D(_MainTex, i.uv) * _Color;
    fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);
    //return float4(i.uv, 0.0f, 1.0f);

    fixed shadow = LIGHT_ATTENUATION(i);
    fixed lighting = dot(normalize(i.normal), lightDir);
    //reduce lighting contribution here:
    fixed edgeHighlight = 1 - saturate(dot(normalize(i.normal), normalize(i.viewDir)));
    edgeHighlight = pow(edgeHighlight, 8) * 1.5;
    fixed shadowContrib = dot(normalize(lightDir), normalize(i.viewDir));
    shadowContrib = saturate(shadowContrib);
    shadowContrib = pow(shadowContrib, 16) * 0.3f;
    edgeHighlight *= 1 - shadowContrib;
    shadowContrib = 1 - shadowContrib;
    //shadowContrib = pow(shadowContrib, 4);
    //return shadowContrib;

    lighting = min(saturate(lighting), shadow);
    lighting = 1 - (1 - lighting) * shadowContrib;
    lighting += edgeHighlight;
    lighting = lighting * 0.5f + 0.5f;
    clip(col.a - CUTOFF);
    return col * lighting;
}