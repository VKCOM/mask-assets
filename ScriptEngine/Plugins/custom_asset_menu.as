#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Constants.as"

class custom_asset_menu: BasePlugin
{
    String pluginName = "custom_asset_menu";

    GalleryMode mode      = GalleryImages;
    Array<String> defaultFiles = {};
    bool hideAfterSelect = false;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        LoadSettings(plugin_config);
        SubscribeToEvent("GalleryAssetSelect", "HandleGalleryAssetSelect");

        maskengine.ShowGallery(mode, defaultFiles);

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("mode")) {
                String modeStr = plugin_config.Get("mode").GetString();
                if (modeStr == "GalleryImages") {
                    mode = GalleryImages;
                } else if (modeStr == "DefaultImages") {
                    mode = DefaultImages;
                } else if (modeStr == "GalleryAndDefaultImages") {
                    mode = GalleryAndDefaultImages;
                }
            }

            if (plugin_config.Contains("default_files")) {
                defaultFiles = plugin_config.Get("default_files").GetFields();
            }

            if (plugin_config.Contains("hide_after_select")) {
                hideAfterSelect = plugin_config.Get("hide_after_select").GetBool();
            }
        }
    }

    void HandleGalleryAssetSelect(StringHash eventType, VariantMap& eventData)
    {
        VariantMap eventDataEvent;

        bool selected = eventData["IsSelect"].GetBool();
        if (selected) {
            if (eventData["Type"].GetString() != "image") {
                log.Error("custom_asset_menu: We support only image asset");
                return;
            }
            String filename = eventData["Filaname"].GetString();
            Texture2D@ tex = cache.GetResource("Texture2D", filename);
            if (tex is null) {
                log.Error("custom_asset_menu: Cannot load asset '" + filename + "'");
                return;
            }
            eventDataEvent["Texture"] = tex;
            eventDataEvent["Name"] = filename;
            eventDataEvent["Action"] = "user_select";
            if (hideAfterSelect) {
                maskengine.HideGallery();
            }
        }

        SendEvent(MaskEngine::GALLERY_ASSET_UPDATE_EVENT, eventDataEvent);
    }
}
