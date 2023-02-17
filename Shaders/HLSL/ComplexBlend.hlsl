#include "TextureEffectBase.hlsl"
#include "BlendMath.hlsl"
#line 4

#ifdef COMPILEPS

#ifndef BLEND_FN
  #error BLEND_FN is not defined
#endif

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
  float3 base = Sample2D(EnvMap, iScreenCoord).rgb;
  float4 blend = Sample2D(DiffMap, iTexCoord);

  blend = blend * cMatDiffColor;

#ifdef ALPHA_TEXTURE
  blend.rgb*=blend.a;
#endif

#ifdef ALPHA_MASK
  return float4( lerp(base, BLEND_FN(base, blend.rgb), blend.a) , 1.0);
#else
  return float4( BLEND_FN(base, blend.rgb), 1.0);
#endif

}

#endif
