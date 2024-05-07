#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Constants.as"


class pickerui : BasePlugin
{
    String pluginName = "pickerui";

    GalleryMode pickerMode = DefaultImages;

    Array<String> mask_tags = {};
    Array<String> picker_icon_paths = {};
    uint current_mask = 0;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        LoadSettings(plugin_config);

        if (mask_tags.empty || picker_icon_paths.empty)
        {
            log.Error("PickerUIPlugin: neither 'tags' nor 'icons' can be empty");
            return false;
        }

        if (mask_tags.length != picker_icon_paths.length)
        {
            log.Error("PickerUIPlugin: number of 'tags' must be equal to number of 'icons'");
            return false;
        }

        SubscribeToEvent("PostUpdate", "HandlePostUpdate");
        SubscribeToEvent(
            "GalleryAssetSelect",
            "HandleGalleryAssetSelect"
        );

        maskengine.ShowGallery(
            pickerMode,
            picker_icon_paths,
            current_mask
        );
        OnAssetSelected();

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("tags"))
            {
                JSONValue tags = plugin_config.Get("tags");
                if (tags.isArray)
                {
                    for (uint i = 0; i < tags.size; i++)
                        mask_tags.Push(tags[i].GetString());
                }
                else
                {
                    log.Error("PickerUIPlugin: `icons` must be an array");
                }
            }

            if (plugin_config.Contains("icons"))
            {
                JSONValue paths = plugin_config.Get("icons");
                if (paths.isArray)
                {
                    for (uint i = 0; i < paths.size; i++)
                        picker_icon_paths.Push(paths[i].GetString());
                }
                else
                {
                    log.Error("PickerUIPlugin: `icons` must be an array");
                }
            }
        }
    }


    bool VerifySelectedIndex(uint idx)
    {
        if (current_mask < 0 || current_mask >= mask_tags.length)
        {
            log.Error("PickerUIPlugin: menu index is out of bound for picker items");
            return false;
        }
        return true;
    }

    void OnAssetSelected()
    {
        if (!VerifySelectedIndex(current_mask))
            return;
        
        VariantMap galleryAssetUpdateEventData;

        String filename = picker_icon_paths[current_mask];
        Texture2D@ texture = cache.GetResource("Texture2D", filename);
        if (texture is null)
        {
            log.Error("PickerUIPlugin: cannot load texture from '" + filename + "'");
            return;
        }

        galleryAssetUpdateEventData["Name"] = filename;
        galleryAssetUpdateEventData["Texture"] = texture;
        galleryAssetUpdateEventData["Action"] = "user_select";

        SendEvent(
            MaskEngine::GALLERY_ASSET_UPDATE_EVENT,galleryAssetUpdateEventData
        );
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (VerifySelectedIndex(current_mask))
            disableAllMasksExcept(current_mask);
    }

    void HandleGalleryAssetSelect(StringHash eventType, VariantMap& eventData)
    {
        current_mask = eventData["Index"].GetInt();
        OnAssetSelected();
    }


    void disableAllMasksExcept(uint current)
    {
        for (uint i = 0; i < mask_tags.length; i++)
        {
            Array<Node@> nodes = scene.GetChildrenWithTag(
                mask_tags[i],
                true
            );
            
            if (i == current)
            {
                for (uint j = 0; j < nodes.length; j++)
                    nodes[j].enabled = true;
            }
            else
            {
                for (uint j = 0; j < nodes.length; j++)
                    nodes[j].enabled = false;
            }
        }
    }

}
