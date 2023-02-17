//#include "TextureEffectBase.hlsl"
#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "Fog.hlsl"
#include "ScreenPos.hlsl"
#line 6

#if defined(COMPILEVS) && !defined(BILLBOARD)
  #error This shader must be used with BB
#endif

void VS(float4 iPos : POSITION,
        float2 iTexCoord : TEXCOORD0,
        float2 iSize : TEXCOORD1,
    #if defined(DIRBILLBOARD) || defined(TRAILBONE)
        float3 iNormal : NORMAL,
    #endif
    out float2 oTexCoord : TEXCOORD0,
    out float4 oWorldPos : TEXCOORD2,
    out float2 oScreenCoord : TEXCOORD3,
    out float2 oScreenCoordCenter: TEXCOORD1,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);

    oScreenCoord = GetScreenPosPreDiv(oPos);
    oTexCoord = GetTexCoord(iTexCoord);

    float4 centerPos = GetClipPos(mul(iPos, modelMatrix));
    oScreenCoordCenter = GetScreenPosPreDiv(centerPos);
    oWorldPos = float4(worldPos, GetDepth(oPos));
}


void PS(float2 iTexCoord : TEXCOORD0,
        float4 iWorldPos: TEXCOORD2,
        float2 iScreenCoord : TEXCOORD3,
        float2 iScreenCoordCenter: TEXCOORD1,
    out float4 oColor : OUTCOLOR0)
{
  float radius     = cMatSpecColor.x;
  float coeficient = cMatSpecColor.y;
  float scale      = cMatSpecColor.z;

  float2 S = iScreenCoord-iScreenCoordCenter;
  float2 T = iTexCoord-float2(0.5, 0.5);

  float Rt = length(T);

  float2 liqVec=float2(0, 0);

  if( Rt < radius && Rt > 0.0) {
    float interpolationFactor = Rt / radius;
    float newR = pow(interpolationFactor, coeficient) * radius;
    float2 newVector = S * newR / Rt;
    liqVec = newVector-S;
  }

  float4 pix0 = Sample2D(EnvMap, iScreenCoord+liqVec*scale );

  oColor = pix0; 
}