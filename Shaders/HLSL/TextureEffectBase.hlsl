#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "Fog.hlsl"
#include "ScreenPos.hlsl"

void VS(float4 iPos : POSITION,
    #ifndef NOUV
        float2 iTexCoord : TEXCOORD0,
    #endif
    #ifdef VERTEXCOLOR
        float4 iColor : COLOR0,
    #endif
    #ifdef SKINNED
        float4 iBlendWeights : BLENDWEIGHT,
        int4 iBlendIndices : BLENDINDICES,
    #endif
    #ifdef INSTANCED
        float4x3 iModelInstance : TEXCOORD4,
    #endif
    #if defined(BILLBOARD) || defined(DIRBILLBOARD)
        float2 iSize : TEXCOORD1,
    #endif
    #if defined(DIRBILLBOARD) || defined(TRAILBONE)
        float3 iNormal : NORMAL,
    #endif
    #if defined(TRAILFACECAM) || defined(TRAILBONE)
        float4 iTangent : TANGENT,
    #endif
    out float2 oTexCoord : TEXCOORD0,
    out float4 oWorldPos : TEXCOORD2,
    out float2 oScreenCoord : TEXCOORD3,
    #ifdef VERTEXCOLOR
        out float4 oColor : COLOR0,
    #endif
    #if defined(D3D11) && defined(CLIPPLANE)
        out float oClip : SV_CLIPDISTANCE0,
    #endif
    out float4 oPos : OUTPOSITION)
{
    // Define a 0,0 UV coord if not expected from the vertex data
    #ifdef NOUV
    float2 iTexCoord = float2(0.0, 0.0);
    #endif

    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);

    oScreenCoord = GetScreenPosPreDiv(oPos);
    #if defined(QUAD) || defined(TEXCOORD_EQ_SCREENCOORD)
        oTexCoord = oScreenCoord;
    #else
        oTexCoord = GetTexCoord(iTexCoord);
        #ifdef SCREENCOORD_EQ_TEXCOORD
            oScreenCoord = oTexCoord;
        #endif
    #endif    
    

    oWorldPos = float4(worldPos, GetDepth(oPos));

    #if defined(D3D11) && defined(CLIPPLANE)
        oClip = dot(oPos, cClipPlane);
    #endif
    
    #ifdef VERTEXCOLOR
        oColor = iColor;
    #endif
}

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord);


void PS(float2 iTexCoord : TEXCOORD0,
        float4 iWorldPos: TEXCOORD2,
        float2 iScreenCoord : TEXCOORD3,
    #ifdef VERTEXCOLOR
        float4 iColor : COLOR0,
    #endif
    #if defined(D3D11) && defined(CLIPPLANE)
        float iClip : SV_CLIPDISTANCE0,
    #endif
    #ifdef PREPASS
        out float4 oDepth : OUTCOLOR1,
    #endif
    #ifdef DEFERRED
        out float4 oAlbedo : OUTCOLOR1,
        out float4 oNormal : OUTCOLOR2,
        out float4 oDepth : OUTCOLOR3,
    #endif
    out float4 oColor : OUTCOLOR0)
{
    #ifdef PREPASS
        // Fill light pre-pass G-Buffer
        oColor = float4(0.5, 0.5, 0.5, 1.0);
        oDepth = iWorldPos.w;    
    #else
        float4 diffColor =   TextureEffectMain(iTexCoord, iScreenCoord);

        #ifdef VERTEXCOLOR
            diffColor *= iColor;
        #endif

        // Get fog factor
        #ifdef HEIGHTFOG
            float fogFactor = GetHeightFogFactor(iWorldPos.w, iWorldPos.y);
        #else
            float fogFactor = GetFogFactor(iWorldPos.w);
        #endif

        #ifdef QUAD
            oColor = diffColor;
        #elif defined(DEFERRED)
            // Fill deferred G-buffer
            oColor = float4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
            oAlbedo = float4(0.0, 0.0, 0.0, 0.0);
            oNormal = float4(0.5, 0.5, 0.5, 1.0);
            oDepth = iWorldPos.w;
        #else
            oColor = float4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
        #endif
    #endif
}