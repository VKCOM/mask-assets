#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

varying vec2 vScreenPos;
varying vec2 vTexCoord;

float sdRoundBox( vec2 p, vec2 b, float r )
{
  vec2 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x, q.y), 0.0) - r;
}


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    vec4 vertexClip = GetClipPos(worldPos);

    vTexCoord = GetTexCoord(iTexCoord);        
    vScreenPos = GetScreenPosPreDiv(vertexClip);

    gl_Position.xy = vTexCoord * 2.0 - 1.0;
    gl_Position.z = .0;
    gl_Position.w = vertexClip.w;
}

void PS()
{
    vec2 borderSize = vec2(cMatDiffColor.x, cMatDiffColor.y);
    float borderSmooth = cMatDiffColor.a;

    float mask = texture2D(sDiffMap, vScreenPos).x;
    vec4 viewport = texture2D(sNormalMap, vScreenPos);

    float border = sdRoundBox(vTexCoord - .5, borderSize - borderSmooth, borderSmooth);
    border = smoothstep(-borderSmooth, .0, border);
    gl_FragColor = vec4(viewport.rgb, max(mask - border, .0));
    // gl_FragColor = vec4(max(border, mask));
    // gl_FragColor = vec4(mask - border);
    // gl_FragColor = vec4(border);

}

