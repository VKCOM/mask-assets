#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS


vec4 TextureEffectMain()
{

    vec2 uv = vScreenPos;   // UV


    vec2 step = 2.0 / cFrameSizeInvSizePS.yx;
    //vec2 step = 1.0 / vec2(750.0,1334.0);

    vec3 texA = texture2D( sEnvMap, uv + vec2(-step.x, -step.y)).rgb;
    vec3 texB = texture2D( sEnvMap, uv + vec2( step.x, -step.y)).rgb;
    vec3 texC = texture2D( sEnvMap, uv + vec2(-step.x,  step.y)).rgb;
    vec3 texD = texture2D( sEnvMap, uv + vec2( step.x,  step.y)).rgb;

    vec3 around = 0.25* (texA + texB + texC + texD);
    vec3 center  = texture2D( sEnvMap, uv ).rgb;

    float sharpness = 2.5;
    
  
    vec3 col = center + (center - around) * sharpness;


   return vec4(mix(texture2D(sEnvMap,uv).rgb,col.rgb,cMatSpecColor.x),1.0);
    //return vec4(1.0,0.0,0.0,1.0);
}

#endif
