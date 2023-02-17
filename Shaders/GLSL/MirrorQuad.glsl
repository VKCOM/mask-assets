#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

varying vec2 vTexCoord;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetQuadTexCoord(gl_Position);
#ifdef VERTICAL
    vTexCoord.y = 1.0 - vTexCoord.y;
#else
    vTexCoord.x = 1.0 - vTexCoord.x;
#endif
}

void PS()
{
    gl_FragColor = texture2D(sDiffMap, vTexCoord);// * vec4(0.0, 1.0, 0.0, 1.0);
}
