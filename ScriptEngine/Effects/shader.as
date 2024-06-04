#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class shader : BaseEffectImpl
{
    BaseEffect@ shaderPatchMaker;
    String makerXml;
    XMLFile@ xmlFile;
    String shader_file;

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        String paramsXml;

        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        shader_file = effect_desc.Get("file").GetString();

        if (shader_file.empty) {
            log.Error("shader effect: No shader file name");
            return false;
        }

        if (effect_desc.Contains("params")) {
            JSONValue paramsRoot = effect_desc.Get("params");
            if (paramsRoot.isArray) {

                for (uint effIdx = 0; effIdx < paramsRoot.size; effIdx++) {

                    JSONValue params = paramsRoot[effIdx];
                    String paramName;

                    if (params.Contains("name")) {
                        paramName = params.Get("name").GetString();
                    } else {log.Error("shader effect: No parameter name");}

                    if (params.Contains("value")) {
                        JSONValue valueArray = params.Get("value");
                        if (valueArray.isArray == false) {
                            paramsXml += "<parameter name=\"" + paramName + "\" value=\"" + valueArray.GetFloat() + "\" />";
                        } else {

                            switch ( valueArray.size )
                            {
                            case 2:
                                paramsXml += "<parameter name=\"" + paramName + "\" value=\"" + valueArray[0].GetFloat() + " " + valueArray[1].GetFloat() + "\" />";
                                break;

                            case 3:
                                paramsXml += "<parameter name=\"" + paramName + "\" value=\"" + valueArray[0].GetFloat() + " " + valueArray[1].GetFloat() + " " + valueArray[2].GetFloat() + "\" />";
                                break;

                            case 4:
                                paramsXml += "<parameter name=\"" + paramName + "\" value=\"" + valueArray[0].GetFloat() + " " + valueArray[1].GetFloat() + " " + valueArray[2].GetFloat() + " " + valueArray[3].GetFloat() + "\" />";
                                break;

                            default:
                                log.Error("shader effect: Probably values out of range");
                            }
                        }
                    } else {log.Error("shader effect: No parameter value");}
                }
            }
        }

        makerXml = "<renderpath><command type=\"quad\" vs=\"" + shader_file + "\" ps=\"" + shader_file + "\" output=\"viewport\">" + paramsXml +
                   "<texture unit=\"environment\" name=\"viewport\" />" +
                   "</command></renderpath>";

        xmlFile = XMLFile();
        xmlFile.FromString(makerXml);
        String stamp = String(time.timeSinceEpoch);
        xmlFile.name = shader_file + "_pass" + stamp + ".xml";
        cache.AddManualResource(xmlFile);

        String patchCopyMakerText = "{\"name\": \"patch\",\"anchor\": \"fullscreen\",\"pass\":\"" + xmlFile.name + "\",\"visible\": \"always\",\"texture\":{\"color\": [1, 1, 1, 1]}}";

        @shaderPatchMaker = AddChildEffect("patch");
        if (shaderPatchMaker !is null)
        {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString(patchCopyMakerText);

            if (!shaderPatchMaker.Init(jsonFile.GetRoot(), parent))
            {
                log.Info("shader effect: cannot init shaderPatchMaker");
                return false;
            }
        }

        _inited = true;
        return _inited;
    }

    String GetName() override
    {
        return "shader";
    }
}
}
