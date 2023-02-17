#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "ScreenPos.hlsl"

void VS(float4 iPos : POSITION,
    out float2 oTexCoord : TEXCOORD0,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);

oTexCoord = GetQuadTexCoord(oPos);
#ifdef VERTICAL
    oTexCoord.y = 1.0 - oTexCoord.y;
#else
    oTexCoord.x = 1.0 - oTexCoord.x;
#endif
}

void PS(float2 iTexCoord : TEXCOORD0,
    out float4 oColor : OUTCOLOR0)
{
    oColor = Sample2D(DiffMap, iTexCoord);
}
