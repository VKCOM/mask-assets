#include "Uniforms.glsl"
#include "Transform.glsl"
#include "Samplers.glsl"
#include "ScreenPos.glsl"

varying vec2 vTexCoord;
varying vec3 vNormal;
varying vec4 vWorldPos;
varying vec2 vScreenPos;
varying vec2 vScreenCoordCenter;

varying vec2 blurCoordinates[6];

float luma(vec4 color)
{
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vNormal = GetWorldNormal(modelMatrix);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));
    vTexCoord = GetTexCoord(iTexCoord);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

void PS()
{
    float cSoftMix         = cMatSpecColor.x; // .65 default
    float cRangeMultiplier = cMatSpecColor.y;
    float cSharpStr        = cMatSpecColor.z;
    float cWhitenStr       = cMatSpecColor.w;

    //mat4 points;
    //points[0] = vec4(0.06497, 0.06296, 0.0, 0.0);
    //points[1] = vec4(0.08135, -0.02559, 0.0, 0.0);
    //points[2] = vec4(-0.04903, 0.07145, 0.0, 0.0);
    //points[3] = vec4(-0.04743, -0.07369, 0.0, 0.0);

    vec2 poissons0 = vec2(0.06497, 0.06296);
    vec2 poissons1 = vec2(0.08135, -0.02559);
    vec2 poissons2 = vec2(-0.04903, 0.07145);
    vec2 poissons3 = vec2(-0.084, -0.00369);
    vec2 poissons4 = vec2(-0.04743, -0.07369);
    vec2 poissons5 = vec2(0.01728, -0.08378);
    vec2 poissons6 = vec2(-0.08067, 0.03261);
    vec2 poissons7 = vec2(0.00627, -0.0876);
    vec2 poissons8 = vec2(0.08159, 0.02346);
    vec2 poissons9 = vec2(-0.06845, -0.04935);
    vec2 poissons10 = vec2(0.01914, -0.08833);
    vec2 poissons11 = vec2(0.06018, -0.06039);


    vec4 cameraColor = texture2D(sEnvMap, vScreenPos);
    vec4 outColor = cameraColor;

    vec4 neighbourColor;
    float neighbourIntens;
    float currentWeight;

    float sum = 1.0;
    float intens = luma(outColor);


    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons0.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons1.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons2.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons3.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons4.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons5.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons6.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons7.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons8.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons9.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons10.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }
    {
        neighbourColor = texture2D(sEnvMap, vScreenPos + poissons11.xy/10.0*cRangeMultiplier);
        neighbourIntens = luma(neighbourColor);

        currentWeight = texture2D(sSpecMap, vec2(intens, 1.0 - neighbourIntens)).r;

        sum += currentWeight;
        outColor += neighbourColor * currentWeight;
    }

    outColor /= sum;

    vec4 whitened = mix(cameraColor, vec4(1.0), intens * cWhitenStr);
    vec4 sharpened = whitened + (whitened - outColor) * cSharpStr;

    outColor = mix(cameraColor, outColor, cSoftMix * texture2D(sDiffMap, vTexCoord).r);

    gl_FragColor = mix(outColor, sharpened, texture2D(sDiffMap, vTexCoord).g);
}