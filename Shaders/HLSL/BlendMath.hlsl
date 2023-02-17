// based on https://mouaif.wordpress.com/2009/01/05/photoshop-math-with-glsl-shaders/
//      and http://www.chilliant.com/rgb2hsv.html

float4 Desaturate(float3 color, float Desaturation)
{
    float3 grayXfer = float3(0.3, 0.59, 0.11);
    float3 gray = dot(grayXfer, color);
    return float4(lerp(color, gray, Desaturation), 1.0);
}

float3 ColorTemperatureToRGB(float temperatureInKelvins)
{
    float3 retColor;
    
    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;
    
    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = clamp(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098, 0.0, 1.0);
    }
    else
    {
        float t = temperatureInKelvins - 60.0;
        retColor.r = clamp(1.29293618606274509804 * pow(t, -0.1332047592), 0.0, 1.0);
        retColor.g = clamp(1.12989086089529411765 * pow(t, -0.0755148492), 0.0, 1.0);
    }
    
    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = clamp(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914, 0.0, 1.0);

    return retColor;
}

// HSL - Hue, Saturation, Luminance
// HCV - Hue, Chroma, Value

float3 RGBtoHCV(float3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6.0 * C + 1e-7) + Q.z);
    return float3(H, C, Q.x);
}

float3 RGBtoHSL(float3 RGB)
{
    float3 HCV = RGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1.0 - abs(L * 2.0 - 1.0) + 1e-7);
    return float3(HCV.x, S, L);
}

float3 HUEtoRGB(float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return clamp(float3(R, G, B), 0.0, 1.0);
}


float3 HSLtoRGB(float3 HSL)
{
    float3 RGB = HUEtoRGB(HSL.x);
    float C = (1.0 - abs(2.0 * HSL.z - 1.0)) * HSL.y;
    return (RGB - 0.5) * C + HSL.z;
}



// Contrast, saturation, brightness
// Code of this function is from TGM's shader pack
// http://irrlicht.sourceforge.net/phpBB2/viewtopic.php?t=21057
//

// For all settings: 1.0 = 100% 0.5=50% 1.5 = 150%
float3 ContrastSaturationBrightness(float3 color, float brt, float sat, float con)
{
    // Increase or decrease theese values to adjust r, g and b color channels seperately
    const float AvgLumR = 0.5;
    const float AvgLumG = 0.5;
    const float AvgLumB = 0.5;
    
    const float3 LumCoeff = float3(0.2125, 0.7154, 0.0721);
    
    float3 AvgLumin = float3(AvgLumR, AvgLumG, AvgLumB);
    float3 brtColor = color * brt;
    float3 intensity = dot(brtColor, LumCoeff);
    float3 satColor = lerp(intensity, brtColor, sat);
    float3 conColor = lerp(AvgLumin, satColor, con);
    return conColor;
}

// blend functions
float  BF_Add(float base, float blend)        { return min(base + blend, 1.0); }
float3 BF_Add(float3 base, float3 blend)      { return min(base + blend, 1.0); }

float  BF_Subtract(float base, float blend)   { return max(base + blend - 1.0, 0.0); }
float3 BF_Subtract(float3 base, float3 blend) { return max(base + blend - 1.0, 0.0); }

// BF_LinearDodge=BF_Add
// BF_LinearBurn=BF_Subtract
// BF_HardLight = BF_Overlay
// BF_Glow = BF_Reflect

float  BF_Lighten(float base, float blend)    { return max(blend, base); }
float3 BF_Lighten(float3 base, float3 blend)  { return max(blend, base); }

float  BF_Darken(float base, float blend)     { return min(blend, base); }
float3 BF_Darken(float3 base, float3 blend)   { return min(blend, base); }

// Linear Light is another contrast-increasing mode
// If the blend color is darker than midgray, Linear Light darkens the image by decreasing the brightness. If the blend color is lighter than midgray, the result is a brighter image due to increased brightness.
float  BF_LinearLight(float base, float blend)    { return blend < 0.5 ? BF_Subtract(base,(2.0*blend)) : BF_Add(base,(2.0*(blend-0.5))); }
float3 BF_LinearLight(float3 base, float3 blend)  { return float3(BF_LinearLight(base.r,blend.r), BF_LinearLight(base.g,blend.g), BF_LinearLight(base.b,blend.b)); }

float  BF_Screen(float base, float blend)     { return 1.0-((1.0-base)*(1.0-blend)); }  
float3 BF_Screen(float3 base, float3 blend)   { return 1.0-((1.0-base)*(1.0-blend)); }; // zs

float  BF_Overlay(float base, float blend)    { return (base < 0.5 ? (2.0 * (base) * (blend)) : (1.0 - 2.0 * (1.0 - (base)) * (1.0 - (blend)))); }
float3 BF_Overlay(float3 base, float3 blend)  { return float3(BF_Overlay(base.r,blend.r), BF_Overlay(base.g,blend.g), BF_Overlay(base.b,blend.b)); }

float  BF_SoftLight(float base, float blend)    { return ((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend))); }
float3 BF_SoftLight(float3 base, float3 blend)  { return float3(BF_SoftLight(base.r,blend.r), BF_SoftLight(base.g,blend.g), BF_SoftLight(base.b,blend.b)); }

float  BF_SoftLight2(float base, float blend)     { return 2.0 * base * blend + base * base *(1.0 - 2.0 * blend); }
float3 BF_SoftLight2(float3 base, float3 blend)   { return float3(BF_SoftLight2(base.r,blend.r), BF_SoftLight2(base.g,blend.g), BF_SoftLight2(base.b,blend.b)); }

float  BF_ColorDodge(float base, float blend)     { return min(base/(1.0 - blend + 1e-7), 1.0); } //{ return (blend==1.0) ? blend : min(base/(1.0-blend), 1.0); }
float3 BF_ColorDodge(float3 base, float3 blend)   { return min(base/(1.0 - blend + 1e-7), 1.0); }

float  BF_ColorBurn(float base, float blend)      { return  max((1.0 - ((1.0 - base) / (blend + 1e-7))), 0.0); }   //{ return (blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0); }
float3 BF_ColorBurn(float3 base, float3 blend)    { return  max((1.0 - ((1.0 - base) / (blend + 1e-7))), 0.0); }

float  BF_VividLight(float base, float blend)     { return (blend < 0.5) ? BF_ColorBurn(base, 2.0 * blend) : BF_ColorDodge(base, 2.0 * (blend - 0.5)); }
float3 BF_VividLight(float3 base, float3 blend)   { return float3(BF_VividLight(base.r,blend.r), BF_VividLight(base.g,blend.g), BF_VividLight(base.b,blend.b)); }

float  BF_PinLight(float base, float blend)       { return (blend<0.5) ? BF_Darken(base,(2.0*blend)) : BF_Lighten(base,(2.0*(blend-0.5))); }
float3 BF_PinLight(float3 base, float3 blend)     { return float3(BF_PinLight(base.r,blend.r), BF_PinLight(base.g,blend.g), BF_PinLight(base.b,blend.b)); }

float  BF_HardMix(float base, float blend)        { return (BF_VividLight(base,blend) < 0.5) ? 0.0: 1.0; }
float3 BF_HardMix(float3 base, float3 blend)      { return float3(BF_HardMix(base.r,blend.r), BF_HardMix(base.g,blend.g), BF_HardMix(base.b,blend.b)); }

float  BF_Reflect(float base, float blend)        { return min(base*base/(1.0 - blend + 1e-7), 1.0); } //{ return (blend==1.0) ? blend : min(base*base/(1.0-blend),1.0) }
float3 BF_Reflect(float3 base, float3 blend)      { return min(base*base/(1.0 - blend + 1e-7), 1.0); }

float3 BF_Multiply(float3 base, float3 blend)     { return base * blend; }
float3 BF_Average(float3 base,  float3 blend)     { return (base + blend) / 2.0; }
float3 BF_Difference(float3 base,  float3 blend)  { return abs(base - blend); }
float3 BF_Negation(float3 base, float3 blend)     { return 1.0 - abs(1.0 - base - blend); }
float3 BF_Exclusion(float3 base, float3 blend)    { return base + blend - 2.0 * base * blend; }
float3 BF_Phoenix(float3 base, float3 blend)      { return min(base, blend) - max(base, blend) + 1.0; }

// Hue Blend mode creates the result color by combining the luminance and saturation of the base color with the hue of the blend color.
float3 BF_Hue(float3 base, float3 blend)
{
  float3 baseHSL = RGBtoHSL(base);
  return HSLtoRGB(float3(RGBtoHSL(blend).r, baseHSL.g, baseHSL.b));
}

// Saturation Blend mode creates the result color by combining the luminance and hue of the base color with the saturation of the blend color.
float3 BF_Saturation(float3 base, float3 blend)
{
  float3 baseHSL = RGBtoHSL(base);
  return HSLtoRGB(float3(baseHSL.r, RGBtoHSL(blend).g, baseHSL.b));
}

// Color Mode keeps the brightness of the base color and applies both the hue and saturation of the blend color.
float3 BF_Color(float3 base, float3 blend)
{
  float3 blendHSL = RGBtoHSL(blend);
  return HSLtoRGB(float3(blendHSL.r, blendHSL.g, RGBtoHSL(base).b));
}

// Luminosity Blend mode creates the result color by combining the hue and saturation of the base color with the luminance of the blend color.
float3 BF_Luminosity(float3 base, float3 blend)
{
  float3 baseHSL = RGBtoHSL(base);
  return HSLtoRGB(float3(baseHSL.r, baseHSL.g, RGBtoHSL(blend).b));
}

//
// Gamma correction
// Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
//

#define GammaCorrection(color, gamma)               pow(color, 1.0 / gamma)


//
// Levels control (input (+gamma), output)
// Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
//

#define LevelsControlInputRange(color, minInput, maxInput)          min(max(color - (minInput), 0.0) / ((maxInput) - (minInput)), 1.0)
#define LevelsControlInput(color, minInput, gamma, maxInput)        GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput)       lerp((minOutput), (maxOutput), color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput)   LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)
