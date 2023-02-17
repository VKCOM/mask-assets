#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "Fog.glsl"
#include "ScreenPos.glsl"
#line 6

varying vec2 vTexCoord;
varying vec3 vNormal;

varying HIGHP_AUTO vec4 vWorldPos;

varying vec2 vScreenPos;
varying vec2 vScreenCoordCenter;

#if defined(COMPILEVS) && !defined(BILLBOARD)
  #error This shader must be used with BB
#endif


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vNormal = GetWorldNormal(modelMatrix);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));
    vTexCoord = GetTexCoord(iTexCoord);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
    vec4 centerPos = GetClipPos((iPos * modelMatrix).xyz);
    vScreenCoordCenter = GetScreenPosPreDiv(centerPos);

}



void PS()
{
  float radius     = cMatSpecColor.x;
  float coeficient = cMatSpecColor.y;
  float scale      = cMatSpecColor.z;

  HIGHP_AUTO vec2 S = vScreenPos-vScreenCoordCenter;
  HIGHP_AUTO vec2 T = vTexCoord-vec2(0.5, 0.5);

  float Rt = length(T);

  vec2 liqVec=vec2(0, 0);

  if( Rt < radius && Rt > 0.0) {
    float interpolationFactor = Rt / radius;
    float newR = pow(interpolationFactor, coeficient) * radius;
    vec2 newVector = S * newR / Rt;
    liqVec = newVector-S;
  }

  gl_FragColor=texture2D(sEnvMap, vScreenPos+liqVec*scale );
}