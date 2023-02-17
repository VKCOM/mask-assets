#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS


vec4 TextureEffectMain()
{
#if defined(INTENSITY_MAP)
    float intensity = texture2D(sNormalMap, vTexCoord).a * cMatDiffColor.a;
#elif defined(INTENSITY_VALUE)
    float intensity = cMatDiffColor.a;
#else    
    const float intensity = 1.0;
#endif    

    vec4 textureColor = texture2D(sEnvMap, vScreenPos);

    float  blueColor= textureColor.b * 63.0;


    vec2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
    vec2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);


    vec2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

    vec2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

    vec4 newColor1 = texture2D(sDiffMap, texPos1);
    vec4 newColor2 = texture2D(sDiffMap, texPos2);
     
    vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
}

#endif