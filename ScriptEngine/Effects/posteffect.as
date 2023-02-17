#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class posteffect : BaseEffectImpl
{
    BaseEffect@ patchEffectShader;
    String makerXml; // контейнер для хранения сжатого xml
    RenderPath@ rp; // глобальная переменная rp
    XMLFile@ xmlFile; // указатель на xml файл

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        String shader_type = effect_desc.Get("type").GetString(); // строка shader_type содержит название нужного шейдера

        float intensity = 1.0;

        if (effect_desc.Get("intensity").isNull == false) {
            intensity = effect_desc.Get("intensity").GetFloat();
        } // получаем интенсивность патча

        intensity = Clamp (intensity, 0.0, 1.0); // Отсекаем значения вне предела 0...1

        if (shader_type.empty) {
            log.Error("shader patch: type param is not set.");      // если строка пустая, то вылетает ошибка
            return false;
        }

        if (shader_type == "glow" || shader_type == "blur" || shader_type == "sharpen" || shader_type == "noise" || shader_type == "dispersion") {
        } else {
            log.Error("shader patch: wrong type of shader"); // ошибка если название шейдера не соответствует списку
            return false;
        }

        makerXml = "<renderpath><rendertarget name=\"buffer\" size=\"2048 2048\" format=\"rgb\" filter=\"true\" />" +
                   "<command type=\"quad\" vs=\"pe_" + shader_type + "\" ps=\"pe_" + shader_type + "\" output=\"buffer\">" +
                   "<texture unit=\"environment\" name=\"viewport\" /><parameter name=\"MatSpecColor\" value=\"" + intensity + " 0.0 0.0 0.0\" />" +
                   "</command><command type=\"quad\" vs=\"CopyFramebuffer\" ps=\"CopyFramebuffer\" output=\"viewport\">" +
                   "<texture unit=\"diffuse\" name=\"buffer\" /></command></renderpath>";


        if (shader_type == "dispersion") {

            makerXml = "<renderpath><rendertarget name=\"buffer\" size=\"2048 2048\" format=\"rgb\" filter=\"true\" />" +
                       "<command type=\"quad\" vs=\"pe_chromatic\" ps=\"pe_chromatic\" output=\"buffer\"><texture unit=\"environment\" name=\"viewport\" />" +
                       "<texture unit=\"diffuse\" name=\"Textures/vignette.png\" /><parameter name=\"MatSpecColor\" value=\"" + intensity + " 0.0 0.0 0.0\" /></command>" +
                       "<command type=\"quad\" vs=\"pe_zoom\" ps=\"pe_zoom\" output=\"viewport\"><texture unit=\"environment\" name=\"buffer\" />" +
                       "<texture unit=\"diffuse\" name=\"Textures/vignette.png\" /><parameter name=\"MatSpecColor\" value=\"" + intensity + " 0.0 0.0 0.0\" /></command></renderpath>";

        }

        if (shader_type == "noise") {

            makerXml = "<renderpath><rendertarget name=\"buffer\" size=\"2048 2048\" format=\"rgb\" filter=\"true\" />" +
                       "<command type=\"quad\" vs=\"pe_noise\" ps=\"pe_noise\" output=\"buffer\"><texture unit=\"environment\" name=\"viewport\" />" +
                       "<texture unit=\"diffuse\" name=\"Textures/noise.png\" /><parameter name=\"MatSpecColor\" value=\"" + intensity + " 0.0 0.0 0.0\" />" +
                       "</command><command type=\"quad\" vs=\"CopyFramebuffer\" ps=\"CopyFramebuffer\" output=\"viewport\">" +
                       "<texture unit=\"diffuse\" name=\"buffer\" /></command></renderpath>";

        }

        if (shader_type == "glow") {

            makerXml = "<renderpath><rendertarget name=\"blurv\" tag=\"Bloom\" size=\"200 560\" format=\"rgb\" filter=\"true\" />" +
                       "<rendertarget name=\"blurh\" tag=\"Bloom\" size=\"150 280\" format=\"rgb\" filter=\"true\" />" +
                       "<command type=\"quad\" tag=\"Bloom\" vs=\"Bloom\" ps=\"Bloom\" psdefines=\"BRIGHT\" output=\"blurv\">" +
                       "<parameter name=\"BloomThreshold\" value=\"0.1\" />" +
                       "<texture unit=\"diffuse\" name=\"viewport\" /></command>" +
                       "<command type=\"quad\" tag=\"Bloom\" vs=\"Bloom\" ps=\"Bloom\" psdefines=\"BLURH\" output=\"blurh\">" +
                       "<texture unit=\"diffuse\" name=\"blurv\" /></command>" +
                       "<command type=\"quad\" tag=\"Bloom\" vs=\"Bloom\" ps=\"Bloom\" psdefines=\"BLURV\" output=\"blurv\">" +
                       "<texture unit=\"diffuse\" name=\"blurh\" /></command>" +
                       "<command type=\"quad\" tag=\"Bloom\" vs=\"Bloom\" ps=\"Bloom\" psdefines=\"COMBINE\" output=\"viewport\">" +
                       "<parameter name=\"BloomMix\" value=\""+(1.0)+" "+intensity+"\" /><texture unit=\"diffuse\" name=\"viewport\" />" +
                       "<texture unit=\"normal\" name=\"blurv\" /></command></renderpath>";

        }

        RenderPath@ rp = renderer.defaultRenderPath;
        xmlFile = XMLFile();
        xmlFile.FromString(makerXml); // создаем xml файл из строкового представления
        rp.Append(xmlFile); // и инжектим его в поток
        renderer.defaultRenderPath = rp; // переключаем рендер-поток на наш

        _inited = true;

        return _inited;
    }

    String GetName() override
    {
        return "posteffect";
    }
}

}