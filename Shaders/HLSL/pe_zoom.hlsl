#include "TextureEffectBase.hlsl"
#line 2

#ifdef COMPILEPS

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
	float strengh = cMatSpecColor.x * 0.05;
    int samples;
    samples = 32;
    float4 mask = Sample2D(DiffMap,float2(iScreenCoord.x,1.0-iScreenCoord.y));
    float4 original = Sample2D(EnvMap,iScreenCoord);
    float4 result = float4(0.0,0.0,0.0,0.0);   
	for (int i=0; i<=samples; i++)
    {        
        float q = float(i)/float(samples);
        result += Sample2D(EnvMap, iScreenCoord + (float2(0.5,0.5)- iScreenCoord)*q*strengh)/32.0;
    }
   
	return float4(lerp(original.rgb,result.rgb,clamp(1.0-mask.r,cMatSpecColor.x,1.0)),1.0);


}

#endif