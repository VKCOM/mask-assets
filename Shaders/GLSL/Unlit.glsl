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

#if defined(PERSON_SEGMENTATION)
   varying HIGHP_AUTO vec2 vScreenPos;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetTexCoord(iTexCoord);
    vWorldPos = vec4(worldPos, GetDepth(gl_Position));
#if defined(PERSON_SEGMENTATION)
    vScreenPos = GetScreenPosPreDiv(gl_Position);
#endif

    #ifdef VERTEXCOLOR
        vColor = iColor;
        //#ifdef TRAIL
        //    vColor = vec4(normalize(cCameraPos), 1.0);
        //#endif
    #endif

}

void PS()
{
    // Get material diffuse albedo
    #ifdef DIFFMAP
        vec4 diffColor = cMatDiffColor * texture2D(sDiffMap, vTexCoord);
        #ifdef ALPHAMASK
            if (diffColor.a < 0.5)
                discard;
        #endif
    #else
        vec4 diffColor = cMatDiffColor;
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

    #if defined(PREPASS)
        // Fill light pre-pass G-Buffer
        gl_FragData[0] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[1] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(DEFERRED)
        gl_FragData[0] = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
        gl_FragData[2] = vec4(0.5, 0.5, 0.5, 1.0);
        gl_FragData[3] = vec4(EncodeDepth(vWorldPos.w), 0.0);
    #elif defined(PERSON_SEGMENTATION)
        vec4 textureColor      = texture2D(sEnvMap, vScreenPos);
        vec4 segmentationColor = texture2D(sSegmMap, vScreenPos);
        vec4 backColor = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
        gl_FragColor = vec4(mix(backColor.rgb, textureColor.rgb, segmentationColor.a), textureColor.a);
    #else
        gl_FragColor = vec4(GetFog(diffColor.rgb, fogFactor), diffColor.a);
    #endif
}
