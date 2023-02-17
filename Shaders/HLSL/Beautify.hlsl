#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "ScreenPos.hlsl"

#define NEIGHBOUR_SAMPLES 12



float luma(float4 color)
{
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

void VS(
    float4 iPos : POSITION,
    float2 iTexCoord : TEXCOORD0,
    out float2 oTexCoord : TEXCOORD0,
    out float4 oWorldPos : TEXCOORD2,
    out float2 oScreenCoord : TEXCOORD3,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);

    oScreenCoord = GetScreenPosPreDiv(oPos);
    oTexCoord = GetTexCoord(iTexCoord);

    oWorldPos = float4(worldPos, GetDepth(oPos));
}

void PS(float2 iTexCoord : TEXCOORD0,
        float4 iWorldPos: TEXCOORD2,
        float2 iScreenCoord : TEXCOORD3,
        out float4 oColor : OUTCOLOR0)
{

    float cSoftMix         = cMatSpecColor.x; // .65 default
    float cRangeMultiplier = cMatSpecColor.y;
    float cSharpStr        = cMatSpecColor.z;
    float cWhitenStr       = cMatSpecColor.w;

    float2 neighbourPositions[NEIGHBOUR_SAMPLES] = {
        float2(0.06497, 0.06296),
        float2(0.08135, -0.02559),
        float2(-0.04903, 0.07145),
        float2(-0.084, -0.00369),
        float2(-0.04743, -0.07369),
        float2(0.01728, -0.08378),
        float2(-0.08067, 0.03261),
        float2(0.00627, -0.0876),
        float2(0.08159, 0.02346),
        float2(-0.06845, -0.04935),
        float2(0.01914, -0.08833),
        float2(0.06018, -0.06039)
    };

    float4 cameraColor = Sample2D(EnvMap, iScreenCoord.xy);
    float4 outColor = cameraColor;


    float4 neighbourColor;
    float neighbourIntens;
    float currentWeight;

    float sum = 1.0;
    float intens = luma(outColor);


    for (int i = 0; i < NEIGHBOUR_SAMPLES; i++)
    {
        neighbourColor = Sample2D(EnvMap, iScreenCoord.xy + neighbourPositions[i].xy / 10.0 * cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = Sample2D(SpecMap, float2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    outColor /= sum;

    float4 whitened = lerp(cameraColor, float4(1.0, 1.0, 1.0, 1.0), intens * cWhitenStr);
    float4 sharpened = whitened + (whitened - outColor) * cSharpStr;


    outColor = lerp(cameraColor, outColor, cSoftMix * Sample2D(DiffMap, iTexCoord.xy).r);
    oColor = lerp(outColor, sharpened, Sample2D(DiffMap, iTexCoord.xy).g);

}
