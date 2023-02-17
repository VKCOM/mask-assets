#include "TextureEffectBase.hlsl"
#line 4

#ifdef COMPILEPS

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
#if defined(INTENSITY_MAP)
    float intensity = Sample2D(NormalMap, iTexCoord).a * cMatDiffColor.a;
#elif defined(INTENSITY_VALUE)
    float intensity = cMatDiffColor.a;
#else    
    static const float intensity = 1.0;
#endif    

    float4 textureColor = Sample2D(EnvMap, iScreenCoord);
    float  blueColor= textureColor.b * 63.0;

    float2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
    float2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);


    float2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

    float2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

    float4 newColor1 = Sample2D(DiffMap, texPos1);
    float4 newColor2 = Sample2D(DiffMap, texPos2);
     
    float4 newColor = lerp(newColor1, newColor2, frac(blueColor));
    return lerp(textureColor, float4(newColor.rgb, textureColor.w), intensity);
}

#endif
