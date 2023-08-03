#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class pasteface : BaseEffectImpl
{
    private BaseEffect@ patchCopyMaker;

    Array<String> sizes;
    Array<String> offsets;
    Array<String> rotations;

    String anchorPlace;
    String tagz;
    String textureFile;
    float maxsize;

    pasteface()
    {
        sizes.Resize(2);
        offsets.Resize(3);
        rotations.Resize(3);

    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
      {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }


    //________________получение дочерних свойств json-файла _____________//
    if(effect_desc.Contains("element")) 
        {
                textureFile = effect_desc.Get("element").GetString();
        
                log.Info("→pasteface: source element loaded");
        } else {
                log.Info("→pasteface: source element not specified");
        }

    //________________получение дочерних свойств json-файла _____________//
    if(effect_desc.Contains("tag")) 
        {
                tagz = effect_desc.Get("tag").GetString();
        
                log.Info("→pasteface: patch has tags");
        } else {
                log.Info("→pasteface: source element not specified");
        }

    //________________получение дочерних свойств json-файла _____________//
    maxsize = 0.0;

    if(effect_desc.Contains("max_size")) 
        {
                maxsize = effect_desc.Get("max_size").GetFloat();
                
                log.Info("→pasteface: max_size variable loaded");
        } else {
                log.Info("→pasteface: max_size not specified");
        }

    //________________получение якорей патчей__________________________//
    if(effect_desc.Contains("anchor")) 
        {
                anchorPlace = effect_desc.Get("anchor").GetString();
                

                log.Info("→pasteface: anchor loaded normally");
            

        } else {
            anchorPlace = textureFile;
            log.Info("→pasteface: anchor not specified (will use element)");
        }

    //________________получение размеров патчей__________________________//
    if(effect_desc.Contains("size")) 
        {
                JSONValue sizze = effect_desc.Get("size");
                if (sizze.isArray)
                    {
                        if (sizze.size >= 2)
                        {
                            JSONValue xsize = sizze[0];
                            JSONValue ysize = sizze[1];
                            float xcor = xsize.GetFloat();
                            float ycor = ysize.GetFloat();

                            if (textureFile == "mouth" || textureFile =="nose") {

                                xcor *= 75.0;
                                ycor *= 75.0;
                                } else {

                                xcor *= 30.0;
                                ycor *= 30.0;
                                } 

                            sizes[0] = String(xcor);
                            sizes[1] = String(ycor);

                            if (anchorPlace == "free") {
                                BerryReadPosition2D(effect_desc.Get("size"), sizes[0], sizes[1]);
                            }  

                        } else
                        {
                            log.Info("→pasteface: size specified in wrong way");
                        }

                    } else
                    {
                        log.Info("→pasteface: size specified in wrong way, must be an array");
                    }
    } else {                   
                            if (textureFile == "mouth" || textureFile =="nose") {

                                sizes[0] = "75.0";
                                sizes[1] = "75.0";
                                } else {
                                sizes[0] = "30.0";
                                sizes[1] = "30.0";
                                }
                                log.Info("pasteface: sizes are not specified scale=1:1");
    }

    
    //________________получение смещений патчей__________________________//
    if(effect_desc.Contains("offset")) 
        {
                BerryReadOffset3D(effect_desc.Get("offset"), offsets[0], offsets[1], offsets[2]);
                log.Info("→pasteface: offsets are loaded normally");
        } else {
            offsets = {"0.0","0.0","0.0"};
            log.Info("pasteface: offsets not specified (will use defaults)");
        }

    //________________получение угла поворота патчей__________________________//
    if(effect_desc.Contains("rotation")) 
        {
               JSONValue rot = effect_desc.Get("rotation");
                if (rot.isArray)
                    {
                        if (rot.size >= 3)
                        {
                            JSONValue xrot = rot[0];
                            JSONValue yrot = rot[1];
                            JSONValue zrot = rot[2];
                            rotations[0] = String(xrot.GetFloat());
                            rotations[1] = String(yrot.GetFloat());
                            rotations[2] = String(zrot.GetFloat());
                            
                        } else
                        {
                            log.Info("→pasteface: rotations are specified in wrong way");
                        }

                    } else
                    {
                        log.Info("→pasteface: rotations are specified in wrong way, must be an array");
                    }
        } else
        {
            rotations = {"0.0","0.0","0.0"};
            log.Info("→pasteface: rotations are not specified (will use defaults)");
        }


        
    //________________________________patchCopyMaker______________________________//
        textureFile += "_copy"; 

        String patchCopyMakerText = "{\"name\": \"patch\",\"anchor\":\""+anchorPlace+"\",\"tag\":\""+tagz+"\",\"texture\": { \"texture\":\""+textureFile+"\"},\"size\":["+sizes[0]+","+sizes[1]+"],\"offset\":["+offsets[0]+","+offsets[1]+","+offsets[2]+"],\"rotation\": ["+rotations[0]+","+rotations[1]+","+rotations[2]+"]}";
        if (textureFile == "mouth_copy") {
        patchCopyMakerText = "{\"name\": \"patch\",\"tag\": \"maxsizer\",\"anchor\":\""+anchorPlace+"\",\"tag\":\""+tagz+"\",\"texture\": { \"texture\":\""+textureFile+"\"},\"size\":["+sizes[0]+","+sizes[1]+"],\"offset\":["+offsets[0]+","+offsets[1]+","+offsets[2]+"],\"rotation\": ["+rotations[0]+","+rotations[1]+","+rotations[2]+"]}";
        }
        @patchCopyMaker = AddChildEffect("patch");
        if (patchCopyMaker !is null)
        {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString(patchCopyMakerText);

            if (!patchCopyMaker.Init(jsonFile.GetRoot(), parent))
            {
                log.Info("→pasteface: cannot init patchCopyMaker");
                return false;
            }
        }

        if (textureFile == "mouth_copy" && maxsize > 1.0) {
            SubscribeToEvent("UpdateFacePOI", "Handlepoi");
        }

        _inited = true;
        return _inited;
    }
     

    String GetName() override
        {
            return "pasteface";
        }

    void Handlepoi(StringHash eventType, VariantMap& eventData)
{      
    Scene@  scene = script.defaultScene; 
    Node@ maxsizer = scene.GetChildrenWithTag("maxsizer", true)[0];

    if (eventData["Detected"].GetBool() ) {
    Vector3 upLip   = eventData["PoiMap"].GetVariantMap()["upper_lip"].GetVector3();    
    Vector3 downLip = eventData["PoiMap"].GetVariantMap()["lower_lip"].GetVector3();    
    float mouth = upLip.y-downLip.y;
    
    if (mouth > 5.0f) {
    float delta = smooth(5.0,20.0,mouth);    
    maxsizer.scale = Vector3 (1.0+(maxsize-1.0)*delta,1.0+(maxsize-1.0)*delta,1.0);

   
    } else {

    maxsizer.scale = Vector3 (1.0,1.0,1.0); 
    }

  }
}

    }

}
bool  BerryReadPositionValue(const JSONValue &jval, String &position)
{
    if (jval.isNumber)
    {
        position = String(jval.GetFloat());
    }
    else if (jval.isObject)
    {
        position = jval.Contains("w") ? "{\"w\":"+String(jval.Get("w").GetFloat())+"}" : "0.0f";
        position = jval.Contains("h") ? "{\"h\":"+String(jval.Get("h").GetFloat())+"}" : position;
        position = jval.Contains("pix") ? "{\"pix\":"+String(jval.Get("pix").GetFloat())+"}" : position;
        position = jval.Contains("max") ? "{\"max\":"+String(jval.Get("max").GetFloat())+"}" : position;
        position = jval.Contains("min") ? "{\"min\":"+String(jval.Get("min").GetFloat())+"}" : position;
    }
    else
    {
        return false;
    }

    return true;
}
bool BerryReadPosition2D(const JSONValue &jval, String &x, String &y)
{
    if (jval.isArray)
    {
        if (jval.size >= 2)
        {
            if (!BerryReadPositionValue(jval[0], x))
            {
                return false;
            }
            if (!BerryReadPositionValue(jval[1], y))
            {
                return false;
            }

            return true;
        }
    }

    return false;
}
bool BerryReadOffset3D(const JSONValue &jval, String &x, String &y, String &z)
{
    if (jval.isArray)
    {
        if (jval.size >= 3)
        {
            if (!BerryReadPositionValue(jval[0], x))
            {
                return false;
            }
            if (!BerryReadPositionValue(jval[1], y))
            {
                return false;
            }
            if (!BerryReadPositionValue(jval[2], z))
            {
                return false;
            }
            return true;
        }
    }

    return false;
}
float smooth (float min, float max, float value) {
  float x = Max(0.0, Min(1.0, (value-min)/(max-min)));
  return x*x*(3.0 - 2.0*x);
};
