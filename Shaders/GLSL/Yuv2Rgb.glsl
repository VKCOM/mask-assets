#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Fog.glsl"

varying vec2 vTexCoord;

varying HIGHP_AUTO vec4 vWorldPos;

#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

// zzz - this line is 603

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    #ifdef QUAD    
        vTexCoord = GetScreenPosPreDiv(gl_Position);
    #else
        vTexCoord = GetTexCoord(iTexCoord);
    #endif
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));

    #ifdef VERTEXCOLOR
        vColor = iColor;
        //#ifdef TRAIL
        //    vColor = vec4(normalize(cCameraPos), 1.0);
        //#endif
    #endif

}


vec4 I420toRGB(vec3 yuv)
{
    const vec3 offset = vec3(-0.0627451017, -0.501960814, -0.501960814);
    const vec3 Rcoeff = vec3(1.164,  0.000,  1.596);
    const vec3 Gcoeff = vec3(1.164, -0.391, -0.813);
    const vec3 Bcoeff = vec3(1.164,  2.018,  0.000);

    
    yuv += offset;
    return vec4(   dot(yuv, Rcoeff),
                   dot(yuv, Gcoeff),
                   dot(yuv, Bcoeff),
                   1.0 );
}

#define TextureY sDiffMap
#define TextureU sNormalMap
#define TextureV sSpecMap


void PS()
{
     vec4   diffColor =   I420toRGB(  vec3( texture2D(TextureY, vTexCoord).x,
                                            texture2D(TextureU, vTexCoord).x,
                                            texture2D(TextureV, vTexCoord).x ) );        // should *cMatDiffColor ?
    //vec4 diffColor = texture2D(sDiffMap, vTexCoord);

    #ifdef VERTEXCOLOR
        diffColor *= vColor;
    #endif

    // Get fog factor
    #ifdef HEIGHTFOG
        float fogFactor = GetHeightFogFactor(vWorldPos.w, vWorldPos.y);
    #else
        float fogFactor = GetFogFactor(vWorldPos.w);
    #endif

    #ifdef QUAD
        gl_FragColor = diffColor;
    #elif defined(PREPASS)
        // Fill light pre-pass G-Buffer
        gl_FragData[0] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[1] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(DEFERRED)
        gl_FragData[0] = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
        gl_FragData[2] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[3] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #else
        gl_FragColor = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
    #endif
}