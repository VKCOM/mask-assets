#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Effects/Base/BaseAnimation.as"

namespace MaskEngine
{

int autoIncAudioID = 0;

class BaseAudio : BaseAnimation
{
    String  _filename;
    int     _id = 0;
    bool _isPlaying = false;
    bool _loop = false;
    float _volume = 1.0;
    bool _pureAudio = false;
    int64 _offset = 0;
    BaseEffect@ parentEffect;

    BaseAudio(String filename)
    {
        _filename = filename;
        autoIncAudioID++;
        _id = autoIncAudioID;
        maskengine.PreloadAudio(_id, _filename);
    }

    BaseAudio(BaseEffect@ parentEffect_, String filename)
    {
        @parentEffect = parentEffect_;
        _filename = filename;
        autoIncAudioID++;
        _id = autoIncAudioID;
        maskengine.PreloadAudio(_id, _filename);
    }

    ~BaseAudio()
    {
        maskengine.StopAudio(_id);
    }

    void Init(bool loop, float volume, bool pureAudio, int64 offset)
    {
        _loop = loop;
        _pureAudio = pureAudio;
        _offset = offset;
        _volume = volume;
    }

    void Play() override
    {
        _isPlaying = true;
        VariantMap eventData = GetEventMap();
        SendEvent(START_ANIMATION_EVENT, eventData);
        Start(_loop, _volume, _pureAudio, _offset);
    }

    void Stop() override
    {
        _isPlaying = false;
        VariantMap eventData = GetEventMap();
        SendEvent(STOP_ANIMATION_EVENT, eventData);
        maskengine.StopAudio(_id);
    }

    void Pause() override
    {
        VariantMap eventData = GetEventMap();
        SendEvent(PAUSE_ANIMATION_EVENT, eventData);
        maskengine.PauseAudio(_id);
    }

    bool IsPlaying() override
    {
        return _isPlaying;
    }

    void SetTime(float localTime) override
    {
    }

    // Start play audio
    void Start()
    {
        maskengine.StartAudio(_id, _filename, false, 1.0, false, 0);
    }

    void Start(bool loop)
    {
        maskengine.StartAudio(_id, _filename, loop, 1.0, false, 0);
    }

    void Start(bool loop, float volume)
    {
        maskengine.StartAudio(_id, _filename, loop, volume, false, 0);
    }

    void Start(bool loop, float volume, bool pureAudio)
    {
        maskengine.StartAudio(_id, _filename, loop, volume, pureAudio, 0);
    }

    void Start(bool loop, float volume, bool pureAudio, int64 offset)
    {
        maskengine.StartAudio(_id, _filename, loop, volume, pureAudio, offset);
    }

    void Resume()
    {
        maskengine.ResumeAudio(_id);
    }

    void SetVolume(float volume)
    {
        maskengine.SetAudioVolume(_id, volume);
    }

    VariantMap GetEventMap()
    {
        VariantMap eventData;
        eventData["RootEffect"]      = Variant(parentEffect.GetRootEffect());
        eventData["AnimationObject"] = Variant(parentEffect);
        eventData["filename"]        = _filename;

        return eventData;
    }
}

}
