#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

String []DEFAULT_TEXCOORD_FILE = {"Facemodel/default_mapping.bin", "Facemodel/sym_tex_coords_compatible.bin", "Facemodel/tex_coords_mediapipe.bin", "Facemodel/tex_coords_arkit.bin"};
String []DEFAULT_INDEXES_FILE  = {"Facemodel/GENERATED_decimated_patched_hole_indices.bin","Facemodel/fm_render_ind.bin", "Facemodel/indexes_mediapipe.bin", "Facemodel/indexes_arkit.bin"};
String []DEFAULT_LE_FILE       = {"Facemodel/eye1_indices_decimated.bin",                  "Facemodel/sym_left_eye_poly.bin", "Facemodel/left_eye_indexes_mediapipe.bin", "Facemodel/left_eye_indexes_arkit.bin"};
String []DEFAULT_RE_FILE       = {"Facemodel/eye2_indices_decimated.bin",                  "Facemodel/sym_right_eye_poly.bin", "Facemodel/right_eye_indexes_mediapipe.bin", "Facemodel/right_eye_indexes_arkit.bin"};
String []DEFAULT_MOUTH_FILE    = {"Facemodel/mouth_indices_decimated.bin",                 "Facemodel/sym_mouth_poly.bin", "Facemodel/mouth_indexes_mediapipe.bin", "Facemodel/mouth_indexes_arkit.bin"};

String MEDIAPIPE_MESH = "mediapipe_mesh";
String ARKIT_MESH     = "arkit_mesh";

class facemodel : BaseEffectImpl
{
    private String _indexes;
    private String _indexes_mouth;
    private String _indexes_LE;
    private String _indexes_RE;
    private String _texcoords;
    private BaseEffect@ _texture;
    private Model@ _model;
    private Model@ _ownModel;
    private Node@ _node;
    private bool _eyes = false;
    private bool _mouth = false;
    private VectorBuffer _idx_face_model;
    private int _files_index;
    private bool _loadTextureFromDefaultFile = true;

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        // append render path
        if (!InitRenderPass(effect_desc.Get("pass"), UNLIT_RENDER_PASS_FILE))
        {
            return false;
        }

        if (!effect_desc.Get("pass").isString && GetGlobalVar("facemodel_version").GetInt() >= 2) {
            // Add clear depth after facemodel, because face model writes a depth to
            // fix artifacts on head rotation around vertical axe.
            RenderPath@ defaultRP = renderer.defaultRenderPath;
            defaultRP.Append(cache.GetResource("XMLFile", "RenderPaths/clear_depth.xml"));
        }

        _files_index = GetFacemodelIndex();

        if (effect_desc.Get("texture_coords").isString)
        {
            _texcoords = effect_desc.Get("texture_coords").GetString();
            _loadTextureFromDefaultFile = false;
        }

        if (!UpdateResources(_files_index))
        {
            return false;
        }

        _eyes = effect_desc.Get("eyes").GetBool();
        _mouth = effect_desc.Get("mouth").GetBool();

        Node@ faceNode = scene.GetChild(_faceNodeName);
        if (faceNode is null)
        {
            return false;
        }

        _node = faceNode.CreateChild("facemodel");
        _node.position = Vector3(0.0f, 0.0f, 0.0f);
        _node.enabled = false;

        AddTags(effect_desc, _node);

        @_texture = AddChildEffect("texture");
        if (_texture is null)
        {
            log.Error("facemodel: Failed to create texture effect");
            return false;
        }

        if (!_texture.Init(effect_desc.Get("texture"), this))
        {
            log.Error("facemodel: Failed to init texture effect");
            return false;
        }

        Array<String> reservedField = { "texture" };
        _inited = LoadAddons(effect_desc, reservedField);

        return _inited;
    }

    void _SetVisible(bool visible) override
    {
        _node.enabled = visible;
    }

    String GetName() override
    {
        return "facemodel";
    }

    void Update(float timeDelta)
    {
        if (!_inited)
        {
            return;
        }

        if (!maskengine.IsFaceDetected(_faceIdx))
        {
            _node.enabled = false;
            return;
        }

        int filesIndex = GetFacemodelIndex();
        if (filesIndex != _files_index)
        {
            if (!UpdateResources(filesIndex))
            {
                return;
            }
            _files_index = filesIndex;
            _model = null;
            _node.RemoveAllComponents();
        }

        if (_model is null)
        {
            CreateModel();
        }

        if (_model !is null)
        {

            // Prevent update the same model several times per frame.
            if (_ownModel !is null)
            {
                UpdateModel();
            }

            _node.enabled = _visible;
        }
        else
        {
            _node.enabled = false;
        }
    }

    void CreateModel()
    {
        // Search existing model suitable for the requirements.
        StaticModel@ existingStaticModel = SearchExistingModel();

        if (existingStaticModel is null)
        {
            Array<String> indexesList;
            if (!_indexes.empty)
            {
                indexesList.Push(_indexes);
                if (_eyes && (!_indexes_LE.empty && !_indexes_RE.empty))
                {
                    indexesList.Push(_indexes_LE);
                    indexesList.Push(_indexes_RE);
                }
                if (_mouth && !_indexes_mouth.empty)
                {
                    indexesList.Push(_indexes_mouth);
                }
            }

            StaticModel@ static_model = maskengine.CreateFaceStaticModel(_node, _faceIdx, _texcoords, Variant(indexesList), _idx_face_model);
            _ownModel = static_model.model;
            _model = static_model.model;
        }
        else
        {
            // Reuse early created model for this facemodel.
            Component@ component = _node.CloneComponent(existingStaticModel);
            StaticModel@ newStaticModel = cast<StaticModel>(component);
            _model = existingStaticModel.model;
            newStaticModel.model = _model;
        }

        _texture.Apply();

        setUserVars(_node);
    }

    void setUserVars(Node@ node)
    {
        node.vars["facemodel"] = true;
        node.vars["texcoords"] = _texcoords;
        node.vars["eyes"] = _eyes;
        node.vars["mouth"] = _mouth;
    }

    void UpdateModel()
    {
        maskengine.UpdateFaceStaticModel(_model, _faceIdx, _idx_face_model);
    }

    StaticModel@ SearchExistingModel()
    {
        StaticModel@ res;

        Node@ faceNode = scene.GetChild(_faceNodeName);
        if (faceNode !is null)
        {
            Array < Node@> faceModelNodes = faceNode.GetChildren();

            Node@ suitableNode;
            // Search suitable node.
            for (uint i = 0; i < faceModelNodes.length; i++)
            {
                Node@ node = faceModelNodes[i];
                if (node.vars["facemodel"].GetBool() && node.vars["texcoords"].ToString() == _texcoords &&
                    node.vars["eyes"].GetBool() == _eyes && node.vars["mouth"].GetBool() == _mouth)
                {
                    suitableNode = node;
                    break;
                }
            }

            if (suitableNode !is null)
            {
                res = suitableNode.GetComponent("StaticModel");
            }
        }

        return res;
    }

    Node@ GetNode(uint index) override
    {
        return index == 0 ? _node : null;
    }

    int GetFacemodelIndex()
    {
        int facemodel_version = GetGlobalVar(FACEMODEL_VERSION).GetInt();
        int filesIndex        = facemodel_version;

        if (facemodel_version == 2 && !globalVars["FACEMODEL_MESH"].empty) {
            filesIndex = globalVars["FACEMODEL_MESH"] == ARKIT_MESH ? 3 : 2;
        }
        return filesIndex;
    }

    bool UpdateResources(int filesIndex)
    {
        if (_loadTextureFromDefaultFile)
        {
            _texcoords = DEFAULT_TEXCOORD_FILE[filesIndex];
        }
        _indexes = DEFAULT_INDEXES_FILE[filesIndex];
        _indexes_mouth = DEFAULT_MOUTH_FILE[filesIndex];
        _indexes_LE = DEFAULT_LE_FILE[filesIndex];
        _indexes_RE = DEFAULT_RE_FILE[filesIndex];

        // check file exist
        Array<String> files = { _texcoords , _indexes , _indexes_mouth , _indexes_LE, _indexes_RE };
        for (uint i = 0; i < files.length; i++)
        {
            String fileName = files[i];
            if (!fileName.empty)
            {
                File@ file = cache.GetFile(fileName);
                if (file is null)
                {
                    log.Error("Failed to load file '" + fileName + "' in facemodel");
                    return false;
                }
            }
        }
        return true;
    }
}

}