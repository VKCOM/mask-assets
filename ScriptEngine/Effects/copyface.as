#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class copyface : BaseEffectImpl
{
    private BaseEffect@ copyfacePatch1;
    private BaseEffect@ copyfacePatch2;
    private BaseEffect@ copyfacePatch3;
    private BaseEffect@ copyfacePatch4;
    private BaseEffect@ copyfacePatch5;
    private BaseEffect@ copyfacePatch6;
    private BaseEffect@ copyfacePatch7;
    private BaseEffect@ copyfacePatch8;
    private BaseEffect@ copyfacePatch9;

    String maskFile1;
    String maskFile2;


    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
      {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }


    //________________получение текстур альфа-масок _____________//
    if(effect_desc.Contains("facemask")) 
        {
                maskFile1 = effect_desc.Get("facemask").GetString(); 
               
        } else {
          
                maskFile1 = "Textures/Copyface/FaceMask.png";
        }

    if(effect_desc.Contains("facemask_nose")) 
        {
                maskFile2 = effect_desc.Get("facemask_nose").GetString(); 
           
        } else {
         
                maskFile2 = "Textures/Copyface/FaceMaskNose.png";
        }



    //________________________________#1  copyFacePatches______________________________//
        String patchText1 = "{\"name\": \"patch\",\"anchor\": \"fullscreen\",\"pass\": \"RenderPaths/saveViewport.xml\",\"texture\": {\"color\": [1, 1, 1, 1]}}";

        @copyfacePatch1 = AddChildEffect("patch");
        if (copyfacePatch1 !is null)
        {
            JSONFile@ jsonFile1 = JSONFile();
            jsonFile1.FromString(patchText1);

            if (!copyfacePatch1.Init(jsonFile1.GetRoot(), parent))
            {
                
                return false;
            }
        }

    //________________________________#2  copyFacePatches______________________________//
        String patchText2 = "{\"name\": \"facemodel\",\"texture\": {\"diffuse\": \""+maskFile1+"\"},\"eyes\": true,\"mouth\": true}";

        @copyfacePatch2 = AddChildEffect("facemodel");
        if (copyfacePatch2 !is null)
        {
            JSONFile@ jsonFile2 = JSONFile();
            jsonFile2.FromString(patchText2);

            if (!copyfacePatch2.Init(jsonFile2.GetRoot(), parent))
            {
                
                return false;
            }
        }

    //________________________________#3  copyFacePatches______________________________//
        String patchText3 = "{\"name\": \"patch_copy\",\"tag\": \"mouth_copy\",\"anchor\": \"mouth\",\"texture\": {\"color\": [1, 1, 1, 1],\"shader\": \"Copyface\",\"MatDiffColor\": [0.27, 0.27, 0.0, 0.15]},\"size\": [75, 75],\"offset\": [0, 0, 0]}";

        @copyfacePatch3 = AddChildEffect("patch_copy");    
        if (copyfacePatch3 !is null)
        {
            JSONFile@ jsonFile3 = JSONFile();
            jsonFile3.FromString(patchText3);

            if (!copyfacePatch3.Init(jsonFile3.GetRoot(), parent))
            {
               
                return false;
            }
        }

    //________________________________#4  copyFacePatches______________________________//
        String patchText4 = "{\"name\": \"patch_copy\",\"tag\": \"right_eye_copy\",\"anchor\": \"right_eye\",\"texture\": {\"color\": [1, 1, 1, 1],\"shader\": \"Copyface\",\"MatDiffColor\": [0.45, 0.45, 0.0, 0.3]},\"size\": [30, 30],\"offset\": [0, 0, 0]}";

        @copyfacePatch4 = AddChildEffect("patch_copy");
        if (copyfacePatch4 !is null)
        {
            JSONFile@ jsonFile4 = JSONFile();
            jsonFile4.FromString(patchText4);

            if (!copyfacePatch4.Init(jsonFile4.GetRoot(), parent))
            {
                
                return false;
            }
        }

    //________________________________#5  copyFacePatches______________________________//
        String patchText5 = "{\"name\": \"patch_copy\",\"tag\": \"left_eye_copy\",\"anchor\": \"left_eye\",\"texture\": {\"color\": [1, 1, 1, 1],\"shader\": \"Copyface\",\"MatDiffColor\": [0.45, 0.45, 0.0, 0.3]},\"size\": [30, 30],\"offset\": [0, 0, 0]}";

        @copyfacePatch5 = AddChildEffect("patch_copy");
        if (copyfacePatch5 !is null)
        {
            JSONFile@ jsonFile5 = JSONFile();
            jsonFile5.FromString(patchText5);

            if (!copyfacePatch5.Init(jsonFile5.GetRoot(), parent))
            {
               
                return false;
            }
        }

    //________________________________#6  copyFacePatches______________________________//
        String patchText6 = "{\"name\": \"patch\",\"anchor\": \"fullscreen\",\"pass\": \"RenderPaths/clear.xml\",\"texture\": {\"color\": [1, 1, 1, 1]}}";

        @copyfacePatch6 = AddChildEffect("patch");
        if (copyfacePatch6 !is null)
        {
            JSONFile@ jsonFile6 = JSONFile();
            jsonFile6.FromString(patchText6);

            if (!copyfacePatch6.Init(jsonFile6.GetRoot(), parent))
            {
                
                return false;
            }
        }

    //________________________________#7  copyFacePatches______________________________//
        String patchText7 = "{\"name\": \"facemodel\",\"texture\": {\"diffuse\": \""+maskFile2+"\"},\"eyes\": true,\"mouth\": true}";

        @copyfacePatch7 = AddChildEffect("facemodel");
        if (copyfacePatch7 !is null)
        {
            JSONFile@ jsonFile7 = JSONFile();
            jsonFile7.FromString(patchText7);

            if (!copyfacePatch7.Init(jsonFile7.GetRoot(), parent))
            {
              
                return false;
            }
        }

    //________________________________#8  copyFacePatches______________________________//
        String patchText8 = "{\"name\": \"patch_copy\",\"tag\": \"nose_copy\",\"anchor\": \"nose\",\"texture\": {\"color\": [1, 1, 1, 1],\"shader\": \"Copyface\",\"MatDiffColor\": [0.4, 0.3, 0.0, 0.2]},\"size\": [75, 75],\"offset\": [0, 0, 0]}";

        @copyfacePatch8 = AddChildEffect("patch_copy");
        if (copyfacePatch8 !is null)
        {
            JSONFile@ jsonFile8 = JSONFile();
            jsonFile8.FromString(patchText8);

            if (!copyfacePatch8.Init(jsonFile8.GetRoot(), parent))
            {
               
                return false;
            }
        }

    //________________________________#9  copyFacePatches______________________________//
        String patchText9 = "{\"name\": \"patch\",\"anchor\": \"fullscreen\",\"pass\": \"RenderPaths/restoreViewport.xml\",\"texture\": {\"color\": [1, 1, 1, 1]}}";

        @copyfacePatch9 = AddChildEffect("patch");
        if (copyfacePatch9 !is null)
        {
            JSONFile@ jsonFile9 = JSONFile();
            jsonFile9.FromString(patchText9);

            if (!copyfacePatch9.Init(jsonFile9.GetRoot(), parent))
            {
               
                return false;
            }
        }  

        _inited = true;
        return _inited;
    }


    String GetName() override
        {
            return "copyface";
        }
    }

}