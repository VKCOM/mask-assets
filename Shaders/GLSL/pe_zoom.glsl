#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS

vec4 TextureEffectMain()
{
	float strengh = cMatSpecColor.x * 0.05;
    int samples;
    samples = 32;
    vec4 mask = texture2D(sDiffMap,vec2(vScreenPos.x,1.0-vScreenPos.y));
    vec4 original = texture2D(sEnvMap,vScreenPos);
    vec4 result = vec4(0.0);   
	for (int i=0; i<=samples; i++)
    {        
        float q = float(i)/float(samples);
        result += texture2D(sEnvMap, vScreenPos + (vec2(0.5,0.5)- vScreenPos)*q*strengh)/32.0;
    }
   
	return vec4(mix(original.rgb,result.rgb,clamp(1.0-mask.r,cMatSpecColor.x,1.0)),1.0);


}

#endif