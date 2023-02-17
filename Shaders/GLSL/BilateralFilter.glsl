#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS

float GetLuminance(vec4 color)
{
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

float filterPixel(float lum0, vec4 col1)
{
  float lum1 = GetLuminance( col1 );

  vec2 intValue   = texture2D(sDiffMap, vec2(lum0, lum1)).xy;
  float  floatValue = 2.0 * (intValue.x + intValue.y / 256.0);
  return 0.36787944 * floatValue;
}


vec4 TextureEffectMain()
{
  vec4 pix0 = texture2D(sEnvMap, vScreenPos);
  float  lum0 = GetLuminance(pix0);

  vec4 pix1;
  float  filterSum = 1.0;
  float  filterVal;

#define RADIUS 4.0

  pix1 = texture2D(sEnvMap, vScreenPos + cFrameSizeInvSizePS.zw*vec2(-RADIUS, -RADIUS)  );
  filterVal = filterPixel(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = texture2D(sEnvMap, vScreenPos + cFrameSizeInvSizePS.zw*vec2(RADIUS, -RADIUS)  );
  filterVal = filterPixel(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = texture2D(sEnvMap, vScreenPos + cFrameSizeInvSizePS.zw*vec2(-RADIUS, RADIUS)  );
  filterVal = filterPixel(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = texture2D(sEnvMap, vScreenPos + cFrameSizeInvSizePS.zw*vec2(RADIUS, RADIUS)  );
  filterVal = filterPixel(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

#if 1
  return pix0/filterSum;
#else
  if( mod(cElapsedTimePS, 4.0)< 2.0)
    return pix0/filterSum;
  else
    return texture2D(sEnvMap, vScreenPos);
#endif

}

#endif