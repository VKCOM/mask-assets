#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "Fog.glsl"
#include "ScreenPos.glsl"
#line 6

#ifdef NORMALMAP
    varying vec4 vTexCoord;
    varying vec4 vTangent;
#else
    varying vec2 vTexCoord;
#endif

varying vec3 vNormal;

varying HIGHP_AUTO vec4 vWorldPos;

#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

varying HIGHP_AUTO vec2 vScreenPos;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vNormal = GetWorldNormal(modelMatrix);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));

    #ifdef VERTEXCOLOR
        vColor = iColor;
    #endif

    #ifdef NORMALMAP
        vec3 tangent = GetWorldTangent(modelMatrix);
        vec3 bitangent = cross(tangent, vNormal) * iTangent.w;
        vTexCoord = vec4(GetTexCoord(iTexCoord), bitangent.xy);
        vTangent = vec4(tangent, bitangent.z);
    #else
        vTexCoord = GetTexCoord(iTexCoord);
    #endif
        
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

#ifdef COMPILEPS
vec4 TextureEffectMain();
#endif


void PS()
{
    vec4 diffColor = TextureEffectMain();

    #ifdef VERTEXCOLOR
        diffColor *= vColor;
    #endif

    gl_FragColor = diffColor;   
}
