#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "ScreenPos.hlsl"
#line 5
float sdRoundBox( float2 p, float2 b, float r )
{
  float2 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void VS(float4 iPos : POSITION,
		float2 iTexCoord : TEXCOORD0,
  #if defined(BILLBOARD) || defined(DIRBILLBOARD)
    float2 iSize : TEXCOORD1,
  #endif
	out float2 oTexCoord : TEXCOORD0,
	out float2 oScreenPos : TEXCOORD3,
	out float4 oPos : SV_POSITION)
{
  float4x3 modelMatrix = iModelMatrix;
  float3 worldPos      = GetWorldPos(modelMatrix);
  float4 vertexClip      = GetClipPos(worldPos);
  oTexCoord = GetTexCoord(iTexCoord);
  oScreenPos = GetScreenPosPreDiv(vertexClip);

    //upd
  
  // oPos = vertexClip;
  
  //upd

  float2 vertexScreen = oTexCoord * 2.0 - 1.0;
  oPos.xy = float2(vertexScreen.x, -vertexScreen.y);
  oPos.z = .0;
  oPos.w = vertexClip.w;
    
}

void PS(
	float2 iTexCoord : TEXCOORD0,
	float2 iScreenPos : TEXCOORD3,
	out float4 oColor : OUTCOLOR0)
{
  float2 borderSize = float2(cMatDiffColor.x, cMatDiffColor.y);
  float borderSmooth = cMatDiffColor.a;

  float mask = Sample2D(DiffMap, iScreenPos).x;
  float4 viewport = Sample2D(NormalMap,iScreenPos);

  float border = sdRoundBox(iTexCoord - 0.5, borderSize - borderSmooth, borderSmooth);
  border = smoothstep(-borderSmooth,0.0, border);
  oColor = float4(viewport.rgb, max(mask - border,0.0));

  
  // upd
  // oColor = float4(1.0, 1.0, 1.0, 1.0);
  // oColor = float4(step(0.5, iTexCoord.x), iTexCoord.y, 0. , 1.);

  // oColor = float4()
  // upd
}
