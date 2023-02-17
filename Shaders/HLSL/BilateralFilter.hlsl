#include "TextureEffectBase.hlsl"
#line 3

#ifdef COMPILEPS

float GetLuminance(float4 color)
{
    return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

float mod(float x, float y)
{
  return x - y * floor(x/y);
}

float filter(float lum0, float4 col1)
{
  float lum1 = GetLuminance( col1 );

  float2 intValue   = Sample2D(DiffMap, float2(lum0, lum1)).xy;
  float  floatValue = 2.0 * (intValue.x + intValue.y / 256.0);
  return 0.36787944 * floatValue;
}


float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
  float4 pix0 = Sample2D(EnvMap, iScreenCoord);
  float  lum0 = GetLuminance(pix0);

  float4 pix1;
  float  filterSum = 1.0;
  float  filterVal;


  pix1 = Sample2D(EnvMap, iScreenCoord + cFrameSizeInvSizePS.zw*float2(-6.0, -6.0)  );
  filterVal = filter(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = Sample2D(EnvMap, iScreenCoord + cFrameSizeInvSizePS.zw*float2(6.0, -6.0)  );
  filterVal = filter(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = Sample2D(EnvMap, iScreenCoord + cFrameSizeInvSizePS.zw*float2(-6.0, 6.0)  );
  filterVal = filter(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

  pix1 = Sample2D(EnvMap, iScreenCoord + cFrameSizeInvSizePS.zw*float2(6.0, 6.0)  );
  filterVal = filter(lum0, pix1);
  filterSum+=filterVal;
  pix0 += pix1*filterVal;

#if 1
  return pix0/filterSum;
#else
  if( mod(cElapsedTimePS, 4.0)< 2.0)
    return pix0/filterSum;
  else
    return Sample2D(EnvMap, iScreenCoord);
#endif

}

#endif