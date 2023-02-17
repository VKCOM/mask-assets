#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class color_filter : BaseEffectImpl
{
    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        String lut_file = effect_desc.Get("lut").GetString();
        if (lut_file.empty)
        {
            log.Error("color_filter: lut param is not set.");
            return false;
        }

        // append render path
        if (!InitRenderPass(effect_desc.Get("pass"), VIEWPORT_RENDER_PASS_FILE))
        {
            return false;
        }

        String tag = "viewportpass" + String(_renderPassIdx);

        RenderPath@ rp = renderer.defaultRenderPath;
        int index = -1;
        for (uint i = 0; i < rp.numCommands; i++)
        {
            RenderPathCommand command = rp.commands[i];
            if (command.tag == tag)
            {
                index = i;
                break;
            }
        }

        if (index < 0)
        {
            log.Error("color_filter: failed to find render path command");
            return false;
        }

        RenderPathCommand command = rp.commands[index];
        command.vertexShaderName = "ColorFilter";
        command.pixelShaderName = "ColorFilter";
        command.textureNames[TU_DIFFUSE] = lut_file;
        rp.commands[index] = command;

        _inited = true;

        return _inited;
    }

    String GetName() override
    {
        return "color_filter";
    }
}

}