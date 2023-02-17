#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "ScreenPos.hlsl"

void VS(float4 iPos : POSITION,
    out float2 oScreenPos : TEXCOORD0,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);
    oScreenPos = GetScreenPosPreDiv(oPos);
}

#define TextureY DiffMap
#define TextureU NormalMap
#define TextureV SpecMap


void PS(    float2 iScreenPos : TEXCOORD0,
        out float4 oColor : OUTCOLOR0)
{

    const float3 offset = {-0.0627451017, -0.501960814, -0.501960814};
    const float3 Rcoeff = {1.164,  0.000,  1.596};
    const float3 Gcoeff = {1.164, -0.391, -0.813};
    const float3 Bcoeff = {1.164,  2.018,  0.000};

    float3 yuv;
    
    yuv.x = Sample2D(TextureY, iScreenPos).x;
    yuv.y = Sample2D(TextureU, iScreenPos).x;
    yuv.z = Sample2D(TextureV, iScreenPos).x;

    yuv += offset;
    
    oColor.r = dot(yuv, Rcoeff);
    oColor.g = dot(yuv, Gcoeff);
    oColor.b = dot(yuv, Bcoeff);
    oColor.a = 1.0f;
}
