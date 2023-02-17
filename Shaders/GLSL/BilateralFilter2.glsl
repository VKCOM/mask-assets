#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "Fog.glsl"
#include "ScreenPos.glsl"
#line 6


varying vec3 vNormal;

varying HIGHP_AUTO vec4 vWorldPos;

varying vec2 vScreenPos;

const int BLUR_SAMPLES = 9;

uniform vec2 cTexelOffset;

varying vec2 blurCoordinates[BLUR_SAMPLES];

uniform MEDIUMP_AUTO float cDistanceNormalizationFactor; // 7.0

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vNormal = GetWorldNormal(modelMatrix);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));
    vScreenPos = GetScreenPosPreDiv(gl_Position);
    
    int multiplier = 0;
    vec2 blurStep;
    vec2 singleStep = cTexelOffset;
    
    for (int i = 0; i < BLUR_SAMPLES; i++)
    {
        multiplier = (i - ((BLUR_SAMPLES - 1) / 2));
        blurStep = float(multiplier) * singleStep * cDistanceNormalizationFactor;
        blurCoordinates[i] = blurStep;
    }
}


void PS()
{
    LOWP_AUTO vec4 centralColor;
    LOWP_AUTO float gaussianWeightTotal;
    LOWP_AUTO vec4 sum;
    LOWP_AUTO vec4 sampleColor;
    LOWP_AUTO float distanceFromCentralColor;
    LOWP_AUTO float gaussianWeight;
    
    centralColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[4] * cFrameSizeInvSizePS.zw);
    gaussianWeightTotal = 0.18;
    sum = centralColor * 0.18;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[0] * cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[1]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[2]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[3]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[5]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[6]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[7]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(sEnvMap, vScreenPos.xy + blurCoordinates[8]* cFrameSizeInvSizePS.zw);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * cDistanceNormalizationFactor, 1.0);
    gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    if(gaussianWeightTotal < 0.5){
        if(gaussianWeightTotal < 0.4){
            gl_FragColor = centralColor;
        }else{
            gl_FragColor = mix(sum / gaussianWeightTotal, centralColor, (gaussianWeightTotal - 0.4) / 0.1);
        }
    } else{
        gl_FragColor = sum / gaussianWeightTotal;
    }
}
