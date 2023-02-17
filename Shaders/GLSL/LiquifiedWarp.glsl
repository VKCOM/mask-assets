
#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "Fog.glsl"
#include "ScreenPos.glsl"
#line 5  

#define MAXPOINTS 15

varying vec2 vTexCoord;

uniform vec2 cAspectRatio;

uniform vec4 cCenter[MAXPOINTS];    // Center (x, y) and direction(z, w).
uniform vec4 cRadiusAndType[MAXPOINTS];         // We use only x and y, z for type
uniform vec4 cScaleAngleDirection[MAXPOINTS];         // It is: Scale, UMin, UMax  

uniform float cCount;
uniform float cProgress;

uniform mat4 cFaceInvMatrix; // world transform for face node
uniform mat4 cFaceMatrix;

uniform vec2 cTexCoordX;
uniform vec2 cTexCoordY;
uniform vec2 cTexCoordOffset;

#ifdef DEBUG_MODE
varying vec4 vColor;
#endif

#ifdef VERSION_1
vec4 rayCastPlane(vec3 rayOrigin, vec3 rayDirection, vec3 planeOrigin, vec3 planeNormal) 
{
  float dotp = dot(planeNormal, rayDirection);
  float distToHit = dot(planeOrigin - rayOrigin, planeNormal) / dotp;
  vec3 hitPoint = rayOrigin + rayDirection * distToHit;
  return vec4(hitPoint, distToHit);
}


vec3 rotatePoint(vec3 p, vec3 orig, vec3 dir, float ang) {
  float w = cos(ang * 0.5);
  vec3 u = normalize(dir) * sin(ang * 0.5);
  vec3 v = p - orig;

  vec3 vn  = v + cross(u * 2.0, cross(u,v) + v * w) + orig;
  return vn;
}
#endif


float DistToLine(vec2 pt1, vec2 pt2, vec2 testPt)
{
    vec2 lineDir = pt2 - pt1;
    vec2 perpDir = vec2(lineDir.y, -lineDir.x);
    vec2 dirToPt1 = pt1 - testPt;
    return abs(dot(normalize(perpDir), dirToPt1));
}

vec4 ColorForPoint(vec2 uv, vec2 center, vec2 direction)
{
    vec4 res = vec4(0.7, 0.7, 0.7, 1.0);
#ifdef VERSION_0
    float lineWidth = 0.01;
#endif

#ifdef VERSION_1
    float lineWidth = 5.0;
#endif

    // red dot
    if (length((uv - center)) < lineWidth)
    {
        res = vec4(1.0, 0.0, 0.0, 1.0);
    }

    // draw vector
    vec2 v = uv - center;
    if (dot(vec2(direction), vec2(v)) > 0.0 && DistToLine(center, center + direction, uv) < lineWidth)
    {
        res = vec4(0.0, 1.0, 0.0, 1.0);
    }

    return res;
}


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetTexCoord(iTexCoord);

#ifdef DEBUG_MODE
    vColor = vec4(1.0, 1.0, 1.0, 1.0);
#endif

#ifdef VERSION_0
    vec2 uv = cTexCoordOffset + vec2(dot(cTexCoordX, vTexCoord), dot(cTexCoordY, vTexCoord));
    uv.y    = 1.0 - uv.y;

    
    for (int i = 0; i < int(cCount); i++)
    {
        float scale = cScaleAngleDirection[i].x;
        float type  = cRadiusAndType[i].z;
        vec2 center = cCenter[i].xy;
        vec2 radius = cRadiusAndType[i].xy;
        float  debug  = cRadiusAndType[i].w;
        vec2 direction = cCenter[i].zw;

        vec2 currentUV = uv;


        vec2 ee = (currentUV - center) / cAspectRatio;

        vec2 direction2 = normalize(direction / cAspectRatio);

        ee = vec2(
            ee.x * direction2.x + ee.y * direction2.y, 
            ee.x * direction2.y - ee.y * direction2.x
        ); 

        vec2 e = ee / radius;

        float d = length(e);

        // Fix border case. TODO: works wrong under S5 Android 7.
        float actualScale = scale;//min(min(scale, min(uv.x, uv.y)), min(1.0 - uv.x, 1.0 - uv.y));


        if (d < 1.0)
        {


    #ifdef DEBUG_MODE
            if (debug == 1.0)
            {
                vColor = ColorForPoint(currentUV, center, direction);
            }
    #endif
            if (type == 1.0) {
                // zoom
                vec2 dist = vec2(d * radius.x, d * radius.y);
                currentUV -= center;

                vec2 delta = ((radius - dist) / radius);
                float deltaScale = actualScale;
                // if(deltaScale > 0.0) {
                //     deltaScale = smoothstep(0.0, 1.0, deltaScale);
                // } 
                // else {
                //     deltaScale = -smoothstep(0.0, 1.0, deltaScale);
                // }                    


                vec2 percent = 1.0 - ((delta * deltaScale) * cProgress);

                currentUV = currentUV * percent;
                uv = currentUV + center;
            } else if (type == 2.0) {
                // shift
                float dist = 1.0 - d;
                float delta = actualScale * dist * cProgress;

                float deltaScale = smoothstep(0.0, 1.0, dist);
                vec2 direction2 = direction * deltaScale * cAspectRatio;
                uv = currentUV - delta * direction2;


            }
        }
    }

    uv.y    = 1.0 - uv.y;
    vTexCoord.xy = uv;

#endif // end of VERSION_0



#ifdef VERSION_1
    vec3 vertexInFace = (vec4(worldPos.xyz, 1.0) * cFaceInvMatrix).xyz;
    // vec3 cameraInFace = (vec4(cCameraPos, 1.0) * cFaceInvMatrix).xyz; 
    vec3 forwardInFace = (vec4(0.0, 0.0, 1.0, 0.0) * cFaceInvMatrix).xyz;

    vec3 rayOrigin = vertexInFace;
    vec3 rayDirection = forwardInFace;
    vec3 hitPoint = vec3(0.0);

    for (int i = 0; i < int(cCount); i++)
    {
        float scale = cScaleAngleDirection[i].x;
        vec3 center = cCenter[i].xyz;
        vec2 radius = cRadiusAndType[i].xy;
        float type  = cRadiusAndType[i].z;
        float  debug  = cRadiusAndType[i].w;
        float angle = cScaleAngleDirection[i].y;
        vec2 direction = cScaleAngleDirection[i].zw;


        vec3 planeCenter = center;
        vec3 planeNormal = vec3(0.0, 0.0, 1.0);

        hitPoint = rayCastPlane(rayOrigin, rayDirection, planeCenter, planeNormal).xyz;
        hitPoint -= planeCenter;


        vec3 radialVectorNorm = hitPoint;

        radialVectorNorm = rotatePoint(radialVectorNorm, vec3(0.0), planeNormal, angle);
        radialVectorNorm = radialVectorNorm * vec3(vec2(1.0) / radius, 0.0);

        float d = length(radialVectorNorm);

        if (d < 1.0)
        {

#ifdef DEBUG_MODE
            if (debug == 1.0)
            {
                vColor = ColorForPoint(hitPoint.xy, vec2(0.0), direction);
            }
#endif

            if (type == 1.0) 
            {
                // zoom

                vec2 hitDisplace =  vec2(1.0 - scale * smoothstep(1.0,0.0, d) * cProgress);
                hitPoint *= vec3(hitDisplace, 0.0);

            } 
            else if (type == 2.0) 
            {
                // shift
                float dist = 1.0 - d;
                float delta = scale * dist * cProgress;

                float deltaScale = smoothstep(0.0, 1.0, dist);
                vec2 direction2 = direction * deltaScale * radius;

                hitPoint -=  vec3(delta * direction2, 0.0);
            }

        } 

        hitPoint += planeCenter;
        rayOrigin = hitPoint;

    }

    worldPos = (vec4(hitPoint, 1.0) * cFaceMatrix).xyz;
    vTexCoord = GetScreenPosPreDiv(GetClipPos(worldPos));
#endif // end of VERSION_1

}

void PS()
{
	vec2 uv = vTexCoord;

#ifdef DEBUG_MODE
    gl_FragColor = texture2D(sEnvMap, uv) * vColor;

    // Indicate debug mode. 
    if (uv.x < 0.05 && uv.y < 0.05)
    {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }

#else
    gl_FragColor = texture2D(sEnvMap, uv);
#endif

}
