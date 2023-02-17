#include "TextureEffectBase.glsl"

#ifdef COMPILEPS
#include "BlendMath.glsl"
#line 5


#ifndef BLEND_FN
  #error BLEND_FN is not defined
#endif

vec4 TextureEffectMain()
{
  vec3 base = texture2D(sEnvMap, vScreenPos).rgb;
  vec4 blend = texture2D(sDiffMap, vTexCoord);

  blend = blend * cMatDiffColor;

#ifdef ALPHA_TEXTURE
  blend.rgb*=blend.a;
#endif

#ifdef ALPHA_MASK
  return vec4( mix(base, BLEND_FN(base, blend.rgb), blend.a) , 1.0);
#else
  return vec4( BLEND_FN(base, blend.rgb), 1.0);
#endif

}

#endif
