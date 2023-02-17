#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS

vec4 TextureEffectMain()
{
    vec2 uv = vScreenPos;
    int kSize = int(cMatSpecColor.x * 5.0); //количество циклов сглаживания (FPS hungry)
    float steps = 3.0; //шаг одного цикла сглаживания (чем больше тем смазаннее)
    vec4 tex1Color = texture2D(sEnvMap,uv);

    vec3 avg = vec3(0.0,0.0,0.0);
    for (int i=-kSize; i <= kSize; ++i) {
        for (int j = -kSize; j <= kSize; ++j) {
            avg = avg + texture2D(sEnvMap, vScreenPos + (vec2(float(i)*steps, float(j)*steps)/cFrameSizeInvSizePS.xy)).xyz;
        }
    }
    int area = (2*kSize + 1) * (2*kSize + 1);
    avg = avg.xyz/vec3(area);
    
	return vec4(avg, tex1Color.a);
    //return vec4(1.0,0.0,0.0,1.0);
}

#endif
