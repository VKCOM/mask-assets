#include "TextureEffectBase.hlsl"
#line 2

#ifdef COMPILEPS

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
    int area;
    float2 uv = (iScreenCoord * cFrameSizeInvSizePS.xy);   // UV
    uv *= cFrameSizeInvSizePS.zw;
    int kSize = int(cMatSpecColor.x * 5.0); //количество циклов сглаживания (FPS hungry)
    float steps = 3.0; //шаг одного цикла сглаживания (чем больше тем смазаннее)
    float4 tex1Color = Sample2D(EnvMap,uv);
    float c = cMatSpecColor.x;
    float3 avg = float3(0.0,0.0,0.0);
    if (c > 0.8) {
      
        for (int i=-5; i <= 5; ++i) {
        for (int j = -5; j <= 5; ++j) {
            float numI = float(i);
            float numJ = float(j);
            float numAone = (numI*steps)/cFrameSizeInvSizePS.x;
            float numAtwo = (numJ*steps)/cFrameSizeInvSizePS.y;
            avg = avg + Sample2D(EnvMap, uv.xy + float2(numAone,numAtwo)).rgb;
            area = (2*5 + 1) * (2*5 + 1);
        }
    }} else if (c > 0.8) {
      
        for (int i=-4; i <= 4; ++i) {
        for (int j = -4; j <= 4; ++j) {
            float numI = float(i);
            float numJ = float(j);
            float numAone = (numI*steps)/cFrameSizeInvSizePS.x;
            float numAtwo = (numJ*steps)/cFrameSizeInvSizePS.y;
            avg = avg + Sample2D(EnvMap, uv.xy + float2(numAone,numAtwo)).rgb;
            area = (2*4 + 1) * (2*4 + 1);
        }
    }} else if (c > 0.6) {
      
        for (int i=-3; i <= 3; ++i) {
        for (int j = -3; j <= 3; ++j) {
            float numI = float(i);
            float numJ = float(j);
            float numAone = (numI*steps)/cFrameSizeInvSizePS.x;
            float numAtwo = (numJ*steps)/cFrameSizeInvSizePS.y;
            avg = avg + Sample2D(EnvMap, uv.xy + float2(numAone,numAtwo)).rgb;
            area = (2*3 + 1) * (2*3 + 1);
        }
    }} else if (c > 0.4) {
      
        for (int i=-2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            float numI = float(i);
            float numJ = float(j);
            float numAone = (numI*steps)/cFrameSizeInvSizePS.x;
            float numAtwo = (numJ*steps)/cFrameSizeInvSizePS.y;
            avg = avg + Sample2D(EnvMap, uv.xy + float2(numAone,numAtwo)).rgb;
            area = (2*2 + 1) * (2*2 + 1);
        }
    }} else if (c > 0.2) {
      
        for (int i=-1; i <= 1; ++i) {
        for (int j = -1; j <= 1; ++j) {
            float numI = float(i);
            float numJ = float(j);
            float numAone = (numI*steps)/cFrameSizeInvSizePS.x;
            float numAtwo = (numJ*steps)/cFrameSizeInvSizePS.y;
            avg = avg + Sample2D(EnvMap, uv.xy + float2(numAone,numAtwo)).rgb;
            area = (2*1 + 1) * (2*1 + 1);
        }
    }} else if (c > 0.0) {
            avg = Sample2D(EnvMap, uv).rgb;
            area = 1;
        
    }
    float areaz = float(area);
    avg = avg.rgb/float3(areaz,areaz,areaz);
    
	return float4(avg.rgb, tex1Color.a);
    //return float4(1.0,0.0,0.0,1.0);
}

#endif
