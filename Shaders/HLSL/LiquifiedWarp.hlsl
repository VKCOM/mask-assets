#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "ScreenPos.hlsl"
#include "Fog.hlsl"  
#line 5  

#define MAXPOINTS 15



uniform float4 cCenter[MAXPOINTS];    // Center (x, y) and direction(z, w).
uniform float4 cRadiusAndType[MAXPOINTS];         // We use only x and y, z for type
uniform float4 cScaleAngleDirection[MAXPOINTS];         // It is: Scale, UMin, UMax  

uniform float2 cAspectRatio;
uniform float cCount;
uniform float cProgress;


uniform float2 cTexCoordX;
uniform float2 cTexCoordY;
uniform float2 cTexCoordOffset;

uniform float4x4 cFaceMatrix;
uniform float4x4 cFaceInvMatrix; // world transform for face node

#ifdef VERSION_1
float4 rayCastPlane(float3 rayOrigin, float3 rayDirection, float3 planeOrigin, float3 planeNormal) 
{
  float dotp = dot(planeNormal, rayDirection);
  float distToHit = dot(planeOrigin - rayOrigin, planeNormal) / dotp;
  float3 hitPoint = rayOrigin + rayDirection * distToHit;
  return float4(hitPoint, distToHit);
}


float3 rotatePoint(float3 p, float3 orig, float3 dir, float ang) {
  float w = cos(ang * 0.5);
  float3 u = normalize(dir) * sin(ang * 0.5);
  float3 v = p - orig;

  float3 vn  = v + cross(u * 2.0, cross(u,v) + v * w) + orig;
  return vn;
}
#endif



#ifdef DEBUG_MODE
float DistToLine(float2 pt1, float2 pt2, float2 testPt)
{
    float2 lineDir = pt2 - pt1;
    float2 perpDir = float2(lineDir.y, -lineDir.x);
    float2 dirToPt1 = pt1 - testPt;
    return abs(dot(normalize(perpDir), dirToPt1));
}

float4 ColorForPoint(float2 uv, float2 center, float2 direction)
{
    float4 res = float4(0.7, 0.7, 0.7, 1.0);

#ifdef VERSION_0
    float lineWidth = 0.01;
#endif

#ifdef VERSION_1
    float lineWidth = 5.0;
#endif

    if (length((uv - center) / cAspectRatio) < lineWidth)
    {
        res = float4(1.0, 0.0, 0.0, 1.0);
    }

    // draw vector
    float2 v = uv - center;
    if (dot(float2(direction), float2(v)) > 0.0 && DistToLine(center, center + direction, uv) < lineWidth)
    {
        res = float4(0.0, 1.0, 0.0, 1.0);
    }

    return res;
}
#endif // end of DEBUG_MODE

void VS(float4 iPos : POSITION,
        float2 iTexCoord : TEXCOORD0,
    out float2 oTexCoord : TEXCOORD0,
    out float4 oWorldPos : TEXCOORD2,
    out float4 oPos : OUTPOSITION
#ifdef DEBUG_MODE
    ,
    out float4 oColor : COLOR0
#endif
)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos      = GetWorldPos(modelMatrix);
    oPos      = GetClipPos(worldPos);
    oTexCoord = GetTexCoord(iTexCoord);
    oWorldPos = float4(worldPos, GetDepth(oPos));


#ifdef DEBUG_MODE
    oColor = float4(1.0, 1.0, 1.0, 1.0);
#endif



#ifdef VERSION_0

    float2 uv = oTexCoord.xy;


    for (int i = 0; i < int(cCount); i++)
    {            
        float scale = cScaleAngleDirection[i].x;
        float type  = cRadiusAndType[i].z;
        float2 center = cCenter[i].xy;
        float2 radius = cRadiusAndType[i].xy;
        float  debug  = cRadiusAndType[i].w;
        float2 direction = cScaleAngleDirection[i].zw;
        
        float2 currentUV = uv;

        float2 ee = (currentUV - center) / cAspectRatio;

        float2 direction2 = normalize(direction / cAspectRatio);

        ee = float2(
            ee.x * direction2.x + ee.y * direction2.y, 
            ee.x * direction2.y - ee.y * direction2.x
        ); 

        float2 e = ee / radius;

        float d = length(e);

        float actualScale   = scale;

        if (d < 1.0)
        {
#ifdef DEBUG_MODE
            if (debug == 0.0)
            {
                continue;
            }

            oColor = ColorForPoint(uv, center, direction);
#else
            if (type == 1.0) {
                // zoom
                float2 dist = float2(d * radius.x, d * radius.y);
                currentUV -= center;
                
                float2 delta = ((radius - dist) / radius);
                float deltaScale = actualScale;
                if(deltaScale > 0.0) {
                    deltaScale = smoothstep(0.0, 1.0, deltaScale);
                }
                
                float2 percent = 1.0 - ((delta * deltaScale) * cProgress);
                currentUV = currentUV * percent;
                uv = currentUV + center;
            } else if (type == 2.0) {
                // shift
                float dist = 1.0 - d;
                float delta = actualScale * dist * cProgress;

                float deltaScale = smoothstep(0.0, 1.0, dist);
                float2 direction2 = direction * deltaScale * cAspectRatio;
                uv = currentUV - delta * direction2;
            }
#endif
        }
    }

    oTexCoord.xy = uv;

#endif // end of VERSION_0




#ifdef VERSION_1
    float3 vertexInFace = mul(float4(worldPos.xyz, 1.0), cFaceInvMatrix).xyz;
    float3 forwardInFace = mul(float4(0.0, 0.0, 1.0, 0.0), cFaceInvMatrix).xyz;

    float3 rayOrigin = vertexInFace;
    float3 rayDirection = forwardInFace;
    float3 hitPoint = float3(0.0, 0.0, 0.0);

    for (int i = 0; i < int(cCount); i++)
    {   
        float scale = cScaleAngleDirection[i].x;
        float3 center = cCenter[i].xyz;
        float2 radius = cRadiusAndType[i].xy;
        float type  = cRadiusAndType[i].z;
        float  debug  = cRadiusAndType[i].w;
        float angle = cScaleAngleDirection[i].y;
        float2 direction = cScaleAngleDirection[i].zw;


        float3 planeCenter = center;
        float3 planeNormal = float3(0.0, 0.0, 1.0);

        hitPoint = rayCastPlane(rayOrigin, rayDirection, planeCenter, planeNormal).xyz;
        hitPoint -= planeCenter;


        float3 radialVectorNorm = hitPoint;

        radialVectorNorm = rotatePoint(radialVectorNorm, float3(0.0, 0.0, 0.0), planeNormal, angle);
        radialVectorNorm = radialVectorNorm * float3(float2(1.0, 1.0) / radius, 0.0);

        float d = length(radialVectorNorm);

        if (d < 1.0)
        {

            
#ifdef DEBUG_MODE
            if (debug == 0.0)
            {
                hitPoint += planeCenter;
                rayOrigin = hitPoint;
                continue;
            }
            oColor = ColorForPoint(hitPoint.xy, float2(0.0, 0.0), direction);
#endif


            if (type == 1.0) 
            {
                // zoom
                float2 hitDisplace =  (1.0 - scale * smoothstep(1.0, 0.0, d) * cProgress);
                hitPoint *= float3(hitDisplace, 0.0);

            } 
            else if (type == 2.0) 
            {
                // shift
                float dist = 1.0 - d;
                float delta = scale * dist * cProgress;

                float deltaScale = smoothstep(0.0, 1.0, dist);
                float2 direction2 = direction * deltaScale * radius;

                hitPoint -=  float3(delta * direction2, 0.0);
            }

            // WARNING!!! DO NOT DELETE THSEESE 3 LINES!!!
            // FUCKING MAGIC! I DON'T KNOW WHY BUT IT DOESN'T WORK WITHOUT THEM
            hitPoint += planeCenter;
            rayOrigin = hitPoint;
            continue;

        } 

        hitPoint += planeCenter;
        rayOrigin = hitPoint;

    }
    worldPos = mul(float4(hitPoint, 1.0), cFaceMatrix).xyz;
    oTexCoord = GetScreenPosPreDiv(GetClipPos(worldPos));
#endif // end of VERSION_1


}

void PS(float2 iTexCoord : TEXCOORD0,
    float4 iWorldPos: TEXCOORD2,
#ifdef DEBUG_MODE
    float4 iColor : COLOR0,
#endif
    out float4 oColor : OUTCOLOR0)
{
#ifdef DEBUG_MODE
    oColor     = Sample2D(EnvMap, iTexCoord) * iColor;
#else
    oColor = Sample2D(EnvMap, iTexCoord);
#endif

}
