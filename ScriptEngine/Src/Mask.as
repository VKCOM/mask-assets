/**
 * Mask class
 *
 */

#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

Mask@ mask = Mask();

shared class Mask
{
    Scene@ scene;
    Array<BaseEffect@> effects;
    Array<BasePlugin@> plugins; //+

    Mask()
    {
        scene = script.defaultScene;
    }
    ~Mask()
    {
        log.Info("~Mask()");
    }

    void AddEffect(BaseEffect@ baseEffect)
    {
        effects.Push(baseEffect);
    }

    Array<BaseEffect@> GetEffectsByTag(const String& tag)
    {
        Array<BaseEffect@> output;
        for (uint i = 0; i < this.effects.length; i++)
        {
            Node@ effectNode = this.effects[i].GetNode(0);
            if (effectNode !is null && effectNode.tags.Find(tag) != -1)
                output.Push(this.effects[i]);
        }
        return output;
    }

    void AddPlugin(BasePlugin@ BasePlugin)
    {
        plugins.Push(BasePlugin);
    }

    // Unload mask
    void Unload()
    {
        UnsubscribeFromAllEvents();

        for (uint i = 0; i < effects.length; i ++)
            effects[i].Unload();

        effects.Clear();

        Array<Node@> children = scene.GetChildren(true);
        for (uint i = 0; i < children.length; i++)
            children[i].RemoveComponents("ScriptInstance");

        scene.RemoveComponents("ScriptInstance");
        @scene = null;
    }
}

}
