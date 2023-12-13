#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Effects/Base/BaseAudio.as"

namespace MaskEngine
{

class audio : BaseEffectImpl
{
    BaseAudio@ _baseAudio;
    bool _connectedToEvent = false;

    audio()
    {
    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }
        bool   loop = false;
        bool   pureSound = false;
        int64  offset = 0;
        float  volume = 1.0;

        @_baseAudio = BaseAudio(this, effect_desc.Get("filename").GetString());

        if (effect_desc.Get("loop").isBool)
        {
            loop = effect_desc.Get("loop").GetBool();
        }

        if (effect_desc.Get("pureSound").isBool)
        {
            pureSound = effect_desc.Get("pureSound").GetBool();
        }

        if (effect_desc.Get("offset").isNumber)
        {
            offset = effect_desc.Get("offset").GetInt();
        }

        if (effect_desc.Get("volume").isNumber)
        {
            volume = effect_desc.Get("volume").GetFloat();
        }

        _baseAudio.Init(loop, volume, pureSound, offset);

        Array<String> reservedField;
        _inited = LoadAddons(effect_desc, reservedField);

        return _inited;
    }

    void Update(float timeDelta)
    {
      if (!_connectedToEvent && (_baseAudio is null) && _baseAudio.IsPlaying())
      {
        _baseAudio.Play();
      }
    }

    Node@ GetNode(uint index) override
    {
        return null;
    }

    void _SetVisible(bool visible) override
    {
    }

    String GetName() override
    {
        return "audio";
    }

    BaseAnimation@ GetAnimation() override
    {
        if (_baseAudio is null)
            return null;

        _connectedToEvent = true;
        return _baseAudio;
    }
}

}