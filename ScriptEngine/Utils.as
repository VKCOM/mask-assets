
namespace MaskEngine
{

Vector4 ONES_VECTOR = Vector4(1.0, 1.0, 1.0, 1.0);

Array<String> HAND_GESTURE_NAMES = {
    "PALM", "OK", "POINTER", "KHABIB", "FIST", "VICTORY",
    "NOT_GESTURE", "NOT_HAND", "ONE", "ROCK", "CROSS", "HOMMIE",
    "THUMB", "THUMB_UP", "THUMB_DOWN",
    "HEART", "HEART_LEFT", "HEART_RIGHT",
    "OTHER", "UNDEFINED_GESTURE"
};


/**
* Read position value, it can be simple float vector in pixels:
* [100.0, 10.0]
* Or related value like:
* [{"w": 0.1, "h": 0.4, "pix": 20, "max" : 0.1, "min" : 0.14}, {"w": 0.1, "pix": 20}]
* w - is procent of width, h - procent of height, pix - pixels,
* max - procent of maximum side,
* min - procent of minimal side.
*/
class BillboardPosition
{
    float pix = 0.0;
    float w = 0.0;
    float h = 0.0;
    float min = 0.0;
    float max = 0.0;
};

class POIIndex
{
    POIIndex()
    {
    }

    POIIndex(String& name_, String& poi1_, String& poi2_)
    {
        name = name_;
        poi1 = poi1_;
        poi2 = poi2_;
    }
    String name;
    String poi1;
    String poi2;
}

Array<POIIndex> poiIndexes =
{
    POIIndex("right_eye",    "RightEyeOuterCorner",  "RightEyeInnerCorner"),
    POIIndex("left_eye",     "LeftEyeOuterCorner",   "LeftEyeInnerCorner"),
    POIIndex("middle_eyes",  "PointBetweenEyes",     ""),
    POIIndex("forehead",     "ForeheadCenter",       ""),
    POIIndex("nose",         "NoseTip",              ""),
    POIIndex("mouth",        "RightLipCorner",       "LeftLipCorner"),
    POIIndex("right_cheek",  "RightCheek",           ""),
    POIIndex("left_cheek",   "LeftCheek",            ""),
    POIIndex("chin",         "Chin",                 ""),
    POIIndex("upper_lip",    "UpperLipRight",       "UpperLipLeft"),
    POIIndex("lower_lip",    "LowerLipRight",       "LowerLipLeft"),

    POIIndex( "left_eye0",    "LeftEye0", ""  ),
    POIIndex( "left_eye1",    "LeftEye1",""  ),
    POIIndex( "left_eye2",    "LeftEye2",""  ),
    POIIndex( "left_eye3",    "LeftEye3",""  ),
    POIIndex( "left_eye4",    "LeftEye4",""  ),
    POIIndex( "left_eye5",    "LeftEye5",""  ),

    POIIndex( "right_eye0",   "RightEye0","" ),
    POIIndex( "right_eye1",   "RightEye1","" ),
    POIIndex( "right_eye2",   "RightEye2","" ),
    POIIndex( "right_eye3",   "RightEye3","" ),
    POIIndex( "right_eye4",   "RightEye4","" ),
    POIIndex( "right_eye5",   "RightEye5","" ),
 
    POIIndex( "left_brow0", "LeftBrow0","" ),
    POIIndex( "left_brow1", "LeftBrow1","" ),
    POIIndex( "left_brow2", "LeftBrow2","" ),
    POIIndex( "left_brow3", "LeftBrow3","" ),
    POIIndex( "left_brow4", "LeftBrow4","" ),

    POIIndex( "right_brow0", "RightBrow0",""),
    POIIndex( "right_brow1", "RightBrow1",""),
    POIIndex( "right_brow2", "RightBrow2",""),
    POIIndex( "right_brow3", "RightBrow3",""),
    POIIndex( "right_brow4", "RightBrow4",""),

    POIIndex( "right_mouth_corner", "RightLipCorner","" ),
    POIIndex( "left_mouth_corner",  "LeftLipCorner", "" ),
    POIIndex( "nose_bridge", "NoseBridge", "") 
};                                                 
                                                   
                                                   
class ScreenPatchAnchor
{
    ScreenPatchAnchor() {}
    ScreenPatchAnchor(String& name_, Vector2 position_)
    {
        name     = name_;
        position = position_;
    }

    String name;
    Vector2 position;
};

Array<ScreenPatchAnchor> screenPatchAnchors = {
    ScreenPatchAnchor("free", Vector2(0.0f, 0.0f)),
    ScreenPatchAnchor("lt_corner", Vector2(-0.5f, 0.5f)),
    ScreenPatchAnchor("lb_corner", Vector2(-0.5f, -0.5f)),
    ScreenPatchAnchor("rt_corner", Vector2(0.5f, 0.5f)),
    ScreenPatchAnchor("rb_corner", Vector2(0.5f, -0.5f)),
    ScreenPatchAnchor("top_center", Vector2(0.0f, 0.5f)),
    ScreenPatchAnchor("left_center", Vector2(-0.5f, 0.0f)),
    ScreenPatchAnchor("right_center", Vector2(0.5f, 0.0f)),
    ScreenPatchAnchor("bottom_center", Vector2(0.0f, -0.5f))
};


bool    IsValidPointOfInterestName(const String &name)
{
    for (uint i = 0; i < poiIndexes.length; i++)
        if (name == poiIndexes[i].name || (name == poiIndexes[i].poi1) || (!poiIndexes[i].poi2.empty && name == poiIndexes[i].poi2))
            return true;

    return false;
}


ScreenPatchAnchor@ FindScreenAnchor(const String& anchor)
{
    for (uint i = 0; i < screenPatchAnchors.length; i++)
    {
        if (screenPatchAnchors[i].name == anchor)
        {
            return screenPatchAnchors[i];
        }
    }

    return null;
}

uint  ReadFloatVector(const JSONValue &jval, Array<float>& dst, uint max_size)
{
    if( jval.isArray )
    {
        uint num = jval.size >= max_size ? max_size : jval.size;
        for(uint i=0; i < num; i++)
        {
            if( jval[i].isNumber )
                dst[i] = jval[i].GetFloat();
            else
                return 0;
        }
        return num;
    }

    return 0;
}


bool    ReadVector4(const JSONValue &jval, Vector4 &dst, bool allow_vector3)
{
    Array<float> v = {dst.x, dst.y, dst.z, dst.z};
    uint n = ReadFloatVector(jval, v, 4);
    if( n==4 || (n==3 && allow_vector3)  )
    {
        dst = Vector4(v);
        return true;
    }
    return false;
}

bool    ReadVector3(const JSONValue &jval, Vector3 &dst, bool allow_vector2 = false)
{
    Array<float> v = { dst.x, dst.y, dst.z };
    uint n = ReadFloatVector(jval, v, 3);
    if (n == 3 || (n == 2 && allow_vector2))
    {
        dst = Vector3(v);
        return true;
    }
    return false;
}

bool  ReadPositionValue(const JSONValue &jval, BillboardPosition &position)
{
    if (jval.isNumber)
    {
        position.pix = jval.GetFloat();
    }
    else if (jval.isObject)
    {
        position.w = jval.Contains("w") ? jval.Get("w").GetFloat() : 0.0f;
        position.h = jval.Contains("h") ? jval.Get("h").GetFloat() : 0.0f;
        position.pix = jval.Contains("pix") ? jval.Get("pix").GetFloat() : 0.0f;
        position.max = jval.Contains("max") ? jval.Get("max").GetFloat() : 0.0f;
        position.min = jval.Contains("min") ? jval.Get("min").GetFloat() : 0.0f;
    }
    else
    {
        return false;
    }

    return true;
}

bool    ReadPosition2D(const JSONValue &jval, BillboardPosition &x, BillboardPosition &y)
{
    if (jval.isArray)
    {
        if (jval.size >= 2)
        {
            if (!ReadPositionValue(jval[0], x))
            {
                return false;
            }
            if (!ReadPositionValue(jval[1], y))
            {
                return false;
            }

            return true;
        }
    }

    return false;
}

bool    ReadPosition3D(const JSONValue &jval, BillboardPosition &x, BillboardPosition &y, BillboardPosition &z, bool allow_vector2)
{
    if (!ReadPosition2D(jval, x, y))
    {
        return false;
    }
    if (jval.isArray)
    {
        if (jval.size >= 3)
        {
            if (!ReadPositionValue(jval[2], z))
            {
                return false;
            }
        }
    }

    return true;
}

bool FileExists(String& filename)
{
    File@ file = cache.GetFile(filename);
    return file !is null;
}

}