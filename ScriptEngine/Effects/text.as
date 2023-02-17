#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class text : BaseEffectImpl
{
    BaseEffect@ patchEffectText;

    Node@ tagNode; // нода, которая содержит биллборды текста
    float rows = 13.0; //дефолтные размер таблицы символов
    float cols = 13.0;
    bool onFace = true; // для проверки anchor face/free
    float spacing = 1.0; // можно задать кернинг
    bool isFrontCamera; // какая из камер задняя/фронтальная
    bool switched = false; // событие переключения камеры
    String symbols = ""; // содержание текстурного файла
    Vector2 defaultSize; // размер одного биллборда (буквы)
    Vector3 defaultOffset; // доп. смещение от места привязки
    Vector3 defaultRotation; // углы поворота текста
    String defaultAnchor; // место привязки текста
    String patchTag = "textEffect"; // тег по-умолчанию
    String defaultTexture; // путь к текстуре
    Vector4 color; // MatDiffColor - цвет текста
    String text; // содержание текста
    String defaultVisible; // видимость текста
    Material@ material; // материал Биллборд сета
    BillboardSet@ bbs;

    // стандартный набор букв и спец. символов по-умолчанию
    String standartSymbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                             "abcdefghijklmnopqrstuvwxyz" +
                             "1234567890 #&.,!?()'\"/|\\:;" +
                             "АБВГДЕËЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" +
                             "-_@$%=абвгдеёжзийклмнопрстуфхцчшщъыьэюя+*{}[]";

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        if (!loadSetup(effect_desc)) {
            log.Info("✓text: can't parse text parameters");
            return false;
        }

        // интерпретация эффекта в стандартный патч
        String patchEffectString =
            "{" +
            "\"name\" : \"patch\"," +
            "\"size\" : [" + defaultSize.x + "," + defaultSize.y + "]," +
            "\"offset\" : [" + defaultOffset.x + "," + defaultOffset.y + "," + defaultOffset.z + "]," +
            "\"rotation\" : [" + defaultRotation.x + "," + defaultRotation.y + "," + defaultRotation.z + "]," +
            "\"tag\" : \"" + patchTag + "\"," +
            "\"visible\" : \"" + defaultVisible + "\"," +
            "\"anchor\" : \"" + defaultAnchor + "\"," +
            "\"texture\" : {" +
            "\"texture\" : \"" + defaultTexture + "\"," +
            "\"color\" : [" + color.x + "," + color.y + "," + color.z + "," + color.w + "]," +
            "\"blend_mode\" : \"alpha\"," +
            "\"auto_mirror\" : true" +
            "}" +
            "}";

        // создаем патч эффект
        bool wasSkip = false;
        patchEffectText = CreateEffect("patch", wasSkip);
        if (patchEffectText !is null)
        {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString(patchEffectString);

            if (!patchEffectText.Init(jsonFile.GetRoot(), parent))
            {
                log.Info("✓text: error creating text patch");
                return false;
            }
        }

        // "печатаем"текст, добавляем доп. биллборды...
        PrintThat();

        SubscribeToEvent("SrcFrameUpdate", "SrcFrameUpdate");
        SubscribeToEvent("PostUpdate", "HandlePostUpdate");

        _inited = true;

        return _inited;
    }

    bool loadSetup(const JSONValue& effect_desc)
    {
        // заполняем все данные и переменные конфигурации

        if (effect_desc.Contains("text"))
        {
            text = effect_desc.Get("text").GetString();

        } else  {log.Info("✓text: you didn't specify what to print"); text = "текст";}

        if (effect_desc.Contains("tag"))
        {
            patchTag = effect_desc.Get("tag").GetString();
        } else  {log.Info("✓text: use default tag: \"textEffect\"");}

        if (effect_desc.Contains("symbol_size")) {
            defaultSize.x = effect_desc.Get("symbol_size")[0].GetFloat();
            defaultSize.y = effect_desc.Get("symbol_size")[1].GetFloat();
        } else {defaultSize = Vector2(25.0, 25.0);}

        if (effect_desc.Contains("offset")) {
            defaultOffset.x = effect_desc.Get("offset")[0].GetFloat();
            defaultOffset.y = effect_desc.Get("offset")[1].GetFloat();
            defaultOffset.z = effect_desc.Get("offset")[2].GetFloat();
        } else {defaultOffset = Vector3(0.0, 0.0, 0.0);}

        if (effect_desc.Contains("rotation")) {
            defaultRotation.x = effect_desc.Get("rotation")[0].GetFloat();
            defaultRotation.y = effect_desc.Get("rotation")[1].GetFloat();
            defaultRotation.z = effect_desc.Get("rotation")[2].GetFloat();
        } else {defaultRotation = Vector3(0.0, 0.0, 0.0);}

        if (effect_desc.Contains("font")) {
            JSONValue maskTextureRoot = effect_desc.Get("font");

            if (maskTextureRoot.isObject) {
                if (maskTextureRoot.Contains("rows")) {
                    rows = maskTextureRoot.Get("rows").GetFloat();
                } else {rows = 13;}
                if (maskTextureRoot.Contains("cols")) {
                    cols = maskTextureRoot.Get("cols").GetFloat();
                } else {cols = 13;}
                if (maskTextureRoot.Contains("symbols")) {
                    symbols = maskTextureRoot.Get("symbols").GetString();
                } else {
                    symbols = standartSymbols;
                }
                if (maskTextureRoot.Contains("symbol_map")) {
                    defaultTexture = maskTextureRoot.Get("symbol_map").GetString();
                } else {
                    defaultTexture = "Textures/DefaultFont.png";
                    log.Info("✓text: use default font: \"Textures/DefaultFont.png\"");
                }
            }
        } else {
            symbols = standartSymbols;
            defaultTexture = "Textures/DefaultFont.png";
            color = Vector4(1.0, 1.0, 1.0, 1.0);
        }
        if (effect_desc.Contains("color")) {
            color.x = effect_desc.Get("color")[0].GetFloat();
            color.y = effect_desc.Get("color")[1].GetFloat();
            color.z = effect_desc.Get("color")[2].GetFloat();
            color.w = effect_desc.Get("color")[3].GetFloat();
        } else {color = Vector4(1.0, 1.0, 1.0, 1.0);}

        if (effect_desc.Contains("spacing")) {
            spacing = effect_desc.Get("spacing").GetFloat();
        } else {spacing = 1.0;}

        if (effect_desc.Contains("visible")) {
            defaultVisible = effect_desc.Get("visible").GetString();
        } else {defaultVisible = "always";}

        if (effect_desc.Contains("anchor")) {
            defaultAnchor = effect_desc.Get("anchor").GetString();
            if (defaultAnchor == "fullscreen" || defaultAnchor == "lt_corner" || defaultAnchor == "lb_corner" ||
                    defaultAnchor == "rt_corner" || defaultAnchor == "rb_corner" || defaultAnchor == "top_center" ||
                    defaultAnchor == "bottom_center" || defaultAnchor == "left_center" || defaultAnchor == "right_center") {
                defaultAnchor = "free";
                log.Info("✓text: sorry, these anchor points not working yet");
            }
        } else {defaultAnchor = "free";}

        return true;
    }

    void SrcFrameUpdate(StringHash eventType, VariantMap& eventData)
    {
        // проверка камеры
        isFrontCamera = (!eventData["IsFlipHorizontal"].empty) ? eventData["IsFlipHorizontal"].GetBool() :
                        eventData["IsFrontCamera"].GetBool();
    }

    void HandlePostUpdate (StringHash eventType, VariantMap& eventData)
    {
        // переворачиваем зеркально каждый биллборд для задней камеры

        // проверяем переменную temporary, если true значит изменен текст через скрипты и надо обновить координаты
        if (patchEffectText.GetNode(0).temporary == true)
        {
            // в node.name содержится текст
            text = patchEffectText.GetNode(0).name;
            PrintThat();

            // если задняя камера, то...
            if (!isFrontCamera) {MirrorUV();} else {MirrorBackUV();}
            patchEffectText.GetNode(0).temporary = false;
        }

        if (!isFrontCamera && switched == false) { MirrorUV();}
        if (isFrontCamera && switched == true) { MirrorBackUV(); switched = false;}
    }

    // вычисление смещения UV каждой буквы
    Rect CharUV (String letter, bool front) {

        float xcor = 0.0;
        float ycor = 0.0;
        float finded = -1;

        // находим индекс текущей буквы в наборе symbols
        for (uint indx = 0; indx < symbols.utf8Length; indx++) {
            if (symbols.SubstringUTF8(indx, 1) == letter) { finded = indx; break;}
        }

        // если нашли. то вычисляем координаты в зависимости от фронтальной/задней камеры
        if (finded != -1) {
            if (front) {
                xcor = 1.0 - (1.0 / cols * Abs(finded % cols));
            } else {
                xcor = (1.0 / cols * Abs(finded % cols)) + (1.0 / cols);
            }
            ycor = Floor(finded / cols) * (1.0 / rows);
            return Rect(Vector2(xcor - (1.0 / cols), ycor), Vector2(xcor, ycor + (1.0 / rows)));
        }
        // не нашли?! возвращаем пустую текстуру
        return Rect(Vector2(0.0, 0.0), Vector2(0.0, 0.0));
    }

    void MirrorUV () {
        for (uint num = 0; num < bbs.numBillboards; num++) {
            bbs.billboards[num].size *= Vector2(1.0, 1.0);
            bbs.billboards[bbs.numBillboards - num - 1].uv = CharUV(text.SubstringUTF8(num, 1), false);
        }
        switched = true;
    }

    void MirrorBackUV () {
        for (uint num = 0; num < bbs.numBillboards; num++) {
            bbs.billboards[num].size = Vector2(Abs(bbs.billboards[num].size.x), Abs(bbs.billboards[num].size.y));
            bbs.billboards[num].uv = CharUV(text.SubstringUTF8(num, 1), true);
        }
    }

    void PrintThat () {

        tagNode = patchEffectText.GetNode(0);
        Node@ parents = tagNode.parent;
        if (parents.name == "Face") {onFace = true;} else {onFace = false;}

        bbs = tagNode.GetComponent("BillboardSet");
        bbs.material.set_cullMode(CULL_NONE);
        material = bbs.material;


        bbs.numBillboards = text.utf8Length; // кол-во букв в тексте

        // настройки billboardSet, чтобы отображался как надо
        bbs.fixedScreenSize = false;
        bbs.sorted = true;
        bbs.scaled = true;

        float charWidth = (defaultSize.x) * spacing; // величина отступа одной буквы от другой

        // создаем еще billboard для всех букв в слове
        for (uint num = 0; num < text.utf8Length; num++) {

            Billboard@ bbnew = bbs.billboards[num];
            if (onFace) { bbnew.position = Vector3(-charWidth * num + (text.utf8Length - 1.0) * (0.5 * charWidth), 0.0, 0.0);} // текст на лице или free?
            else { bbnew.position = Vector3(-charWidth * num, bbs.billboards[0].position.y, 0.0); tagNode.position = Vector3((text.utf8Length - 1.0) * (0.5 * charWidth) + defaultOffset.x, tagNode.position.y, tagNode.position.z);} // Меняем позицию в зависимости от этого
            bbnew.size = defaultSize;
            bbnew.enabled = true;
            bbnew.uv = CharUV(text.SubstringUTF8(num, 1), true);
        }
        bbs.Commit();
    }
    void SetVisible(bool visible_) override
    {
        // _node.enabled = visible;
    }

    Material@ GetMaterial() override
    {
        return null;
    }

    int GetFaceIndex() override
    {
        return _faceIdx;
    }

    String GetName() override
    {
        return "text";
    }
}
}
