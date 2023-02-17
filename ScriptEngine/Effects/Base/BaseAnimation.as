#include "ScriptEngine/Utils.as"


namespace MaskEngine
{

String START_ANIMATION_EVENT    = "StartAnimation";
String PAUSE_ANIMATION_EVENT    = "PauseAnimation";
String STOP_ANIMATION_EVENT     = "StopAnimation";
String SET_TIME_ANIMATION_EVENT = "SetTimeAnimation";

shared interface BaseAnimation
{   
    void Play();
    void Stop();
    void Pause();
    bool IsPlaying();
    void SetTime(float localTime);
}

class BaseAnimationImpl : BaseAnimation
{
    bool _isPlaying = false;
    BaseEffect@ parentEffect;

    BaseAnimationImpl(BaseEffect@ parentEffect_)
    {
        @parentEffect = parentEffect_;
    }

    void Play() override
    {
        _isPlaying = true;
        VariantMap eventData = GetEventMap();
        SendEvent(START_ANIMATION_EVENT, eventData);
    }

    void Stop() override
    {
        _isPlaying = false;
        VariantMap eventData = GetEventMap();
        SendEvent(STOP_ANIMATION_EVENT, eventData);
    }

    void Pause() override
    {
        VariantMap eventData = GetEventMap();
        SendEvent(PAUSE_ANIMATION_EVENT, eventData);
    }

    bool IsPlaying() override
    {
        return _isPlaying;
    }

    void SetTime(float localTime) override
    {
        VariantMap eventData = GetEventMap();
        eventData["localTime"] = Variant(localTime);

        SendEvent(SET_TIME_ANIMATION_EVENT, eventData);
        //log.Warning("Method SetTime should be override");
    }

    VariantMap GetEventMap()
    {
        VariantMap eventData;
        eventData["RootEffect"] = Variant(parentEffect.GetRootEffect());
        eventData["AnimationObject"] = Variant(parentEffect);

        return eventData;
    }
}

}
