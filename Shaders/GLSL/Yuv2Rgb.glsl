#if defined(COMPILEPS) && defined(ANDROID_OES)
#extension GL_OES_EGL_image_external : require
#endif

#include "Uniforms.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Fog.glsl"

varying vec2 vTexCoord;

varying HIGHP_AUTO vec4 vWorldPos;

#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

//#ifdef ANDROID_OES
//precision mediump float;
//#endif

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
#if defined(BT709_COLOR_SPACE)
    const vec3 Rcoeff = vec3(1.1644,  0.000,   1.7927);
    const vec3 Gcoeff = vec3(1.1644, -0.2132, -0.5329);
    const vec3 Bcoeff = vec3(1.1644,  2.1124,  0.000);
#else
    const vec3 Rcoeff = vec3(1.1644,  0.000,   1.596);
    const vec3 Gcoeff = vec3(1.1644, -0.3918, -0.813);
    const vec3 Bcoeff = vec3(1.1644,  2.0172,  0.000);
#endif
    
    yuv += offset;
    return vec4(   dot(yuv, Rcoeff),
                   dot(yuv, Gcoeff),
                   dot(yuv, Bcoeff),
                   1.0 );
}

#if defined(COMPILEPS)
 
#if defined(ANDROID_OES)
uniform samplerExternalOES 	sDiffMap;
#else
uniform sampler2D sDiffMap;
uniform sampler2D sNormalMap;
uniform sampler2D sSpecMap;

#define TextureY sDiffMap
#define TextureU sNormalMap
#define TextureV sSpecMap
#endif

#endif





void PS()
{
    #if defined(ANDROID_OES)
     vec4   diffColor =   texture2D(sDiffMap, vTexCoord);
    #elif defined(NV12)
     vec4   diffColor =   I420toRGB(  vec3( texture2D(TextureY, vTexCoord).x,
                                            texture2D(TextureU, vTexCoord).ra) );
    #else
     vec4   diffColor =   I420toRGB(  vec3( texture2D(TextureY, vTexCoord).x,
                                            texture2D(TextureU, vTexCoord).x,
                                            texture2D(TextureV, vTexCoord).x ) );        // should *cMatDiffColor ?
    //vec4 diffColor = texture2D(sDiffMap, vTexCoord);
    #endif
    
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