#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class wiggle : BaseEffectImpl
{
    private Node@ _parentNode;
    private float _wiggleSpeed;
    private float _wiggleAmplitude;
    private float _wiggleRollSpeed;
    private float timeZtep;
    private bool isWiggled;
    private float _fpsRoll;
    private ValueAnimation@ posAni = ValueAnimation();

    void WiggleThis(Node@ node, float delta, float duration, float rot)
    {
        Vector3 oldPos = node.position;
        //SetRandomSeed(time.systemTime + time.timeSinceEpoch);
        if (delta > 0.0 && duration > 0.0) {
            posAni.SetKeyFrame(0.0, Variant(oldPos));
            posAni.SetKeyFrame(duration * 0.1, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.2, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.3, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.4, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.5, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.6, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.7, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.8, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.9, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration, Variant(oldPos));
            node.SetAttributeAnimation("Position", posAni, WM_LOOP);
        }

    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {

        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        if (effect_desc.Get("wiggle").isArray) {

            if (effect_desc.Get("wiggle")[0].isNumber && effect_desc.Get("wiggle")[0].GetFloat() > 0.0) {
                _wiggleSpeed = SmoothStep(0.0, 1.0, effect_desc.Get("wiggle")[0].GetFloat());
                _wiggleSpeed = 50.0 / (_wiggleSpeed * 70.0);
            }
            if (effect_desc.Get("wiggle")[1].isNumber) {
                _wiggleAmplitude = effect_desc.Get("wiggle")[1].GetFloat();
            }
            if (effect_desc.Get("wiggle")[2].isNumber) {
                _wiggleRollSpeed = effect_desc.Get("wiggle")[2].GetFloat();
                _fpsRoll = (3600.0/_wiggleRollSpeed)*3.14 + _wiggleRollSpeed;
                _wiggleRollSpeed =_fpsRoll + Clamp(_wiggleRollSpeed, -360.0, 360.0) * 2.5 - _fpsRoll;
            }
        }
        _parentNode = parent.GetNode(0);

        SubscribeToEvent("PostUpdate", "HandleUpdate");
        Apply();

        return true;
    }

    // Apply effect to parent
    void Apply() override
    {
        //empty due the face anchors issue. All implemantations goes to HandleUpdate()
        //WiggleThis(_parentNode, _wiggleAmplitude, _wiggleSpeed, _wiggleRollSpeed);

    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        timeZtep = eventData["TimeStep"].GetFloat();
        _parentNode.Rotate(Quaternion(0.0, 0.0, timeZtep * _wiggleRollSpeed));
        if (!isWiggled) {
            WiggleThis(_parentNode, _wiggleAmplitude, _wiggleSpeed, _wiggleRollSpeed);
            isWiggled = true;
        }
    }

    bool NeedCallInUpdate() override
    {
        return false;
    }

    String GetName() override
    {
        return "wiggle";
    }
}

}