#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "Fog.hlsl"
#include "ScreenPos.hlsl"
#line 6  

#define BLUR_SAMPLES 9

uniform float2 cTexelOffset;

uniform float cDistanceNormalizationFactor; // 7.0

void VS(float4 iPos : POSITION,
    out float2 oTexCoord : TEXCOORD0,
    out float4 oWorldPos : TEXCOORD2,
    out float2 oScreenCoord : TEXCOORD3,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);

    oScreenCoord = GetScreenPosPreDiv(oPos);
    oTexCoord = oScreenCoord;

    oWorldPos = float4(worldPos, GetDepth(oPos));
}

void PS(float2 iTexCoord : TEXCOORD0,
        float4 iWorldPos: TEXCOORD2,
        float2 iScreenCoord : TEXCOORD3,
        out float4 oColor : OUTCOLOR0)
{
    float4 centralColor;
    float gaussianWeightTotal;
    float4 sum;
    float4 sampleColor;
    float distanceFromCentralColor;
    float gaussianWeight;


    float2 singleStep = cTexelOffset;

    float multiplier = (4 - ((BLUR_SAMPLES - 1) / 2));
    float2 blurStep = float(multiplier) * singleStep * cDistanceNormalizationFactor;
    
    centralColor = Sample2D(EnvMap, iScreenCoord.xy + blurStep * cFrameSizeInvSizePS.zw);
    gaussianWeightTotal = 0.18;
    sum = centralColor * 0.18;

    float kof[BLUR_SAMPLES] = {0.05, 0.09, 0.12, 0.15, 0.01, 0.15, 0.12, 0.09, 0.05};

    for (int i = 0; i < BLUR_SAMPLES; i++)
    {
        if (i != 4)
        {
            multiplier = (i - ((BLUR_SAMPLES - 1) / 2));
            blurStep = float(multiplier) * singleStep * cDistanceNormalizationFactor;

            sampleColor = Sample2D(EnvMap, iScreenCoord.xy + blurStep * cFrameSizeInvSizePS.zw);
            distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
            gaussianWeight = kof[i] * (1.0 - distanceFromCentralColor);
            gaussianWeightTotal += gaussianWeight;
            sum += sampleColor * gaussianWeight;       
       }
    }

    if(gaussianWeightTotal < 0.5){
        if(gaussianWeightTotal < 0.4){
            oColor = centralColor;
        }else{
            oColor = lerp(sum / gaussianWeightTotal, centralColor, (gaussianWeightTotal - 0.4) / 0.1);
        }
    } else{
        oColor = sum / gaussianWeightTotal;
    }
}
