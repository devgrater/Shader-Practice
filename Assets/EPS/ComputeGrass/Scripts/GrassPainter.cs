using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using System.IO;


public class GrassPainter : EditorWindow
{

    private void WriteImage(RenderTexture texture, string name)
    {
        RenderTexture.active = texture;
        Texture2D tex = new Texture2D(texture.width, texture.height, TextureFormat.RGB24, false);
        tex.ReadPixels(new Rect(0, 0, texture.width, texture.height), 0, 0);
        RenderTexture.active = null;

        byte[] bytes = tex.EncodeToPNG();
        var dirPath = Application.dataPath + "/GrassData/";
        if (!Directory.Exists(dirPath))
        {
            Directory.CreateDirectory(dirPath);
        }
        File.WriteAllBytes(dirPath + "Grass_" + name + ".jpg", bytes);
        AssetDatabase.ImportAsset(dirPath);
    }
    private void OnEnable()
    {
        SceneView.duringSceneGui += OnSceneView;
    }

    private void OnDisable()
    {
        SceneView.duringSceneGui -= OnSceneView;

    }
    private enum PaintMode {
        COLOR,
        DENSITY,
        HEIGHT,
        FREEROAM,
        CALIBRATION
    }

    private enum CalibrationMode
    {
        BASE,
        HEIGHT,
        NONE
    }

    static GameObject target;
    static GrassPointScatter targetScatter;
    static float brushSize = 4.0f;
    static float brushSoftness = 0.5f;
    static float brushStrength = 0.5f;
    static float brushValue = 0.5f;
   
    static RenderTexture targetColorInfo;
    static RenderTexture targetHeightInfo;
    static PaintMode currentPaintMode = PaintMode.FREEROAM;
    static CalibrationMode currentCalibrationMode = CalibrationMode.NONE;
    static bool isSetColorsMode = false;
    static Color brushColor;

    static Shader paintBrushShader;
    static RenderTexture blitBuffer;
    static Material paintBrushMaterial;

    static Texture2D userTargetColorInfo;
    static Texture2D userTargetHeightInfo;

    static int isCapturingControls = 1;
    [MenuItem("ˢ��/ˢ��")]
    public static void OpenEditorWindow()
    {
        EditorWindow.GetWindow<GrassPainter>(false, "ˢ�ݣ�");
        paintBrushShader = Shader.Find("Hidden/GrassPaint/PaintBrushShader");
   
        paintBrushMaterial = new Material(paintBrushShader);
    }


    private void OnGUI()
    {
        GUIStyle header = new GUIStyle();
        header.normal.textColor = Color.white;
        header.fontSize = 18; // whatever you set

        GUIStyle subheader = new GUIStyle();
        subheader.normal.textColor = Color.white;
        subheader.fontSize = 12; // whatever you set

        GUILayout.Label("  I. ѡ�����ˢ�ݵ���", header);
        if (!target)
        {
            
            GUILayout.Label("    ѡ����Ҫˢ�ݵ����壬Ȼ������\"ѡ��Ŀ����ˢ��\"");
        }
        if (GUILayout.Button("��ѡ��Ŀ����ˢ��") && Selection.activeGameObject != null)
        {
            target = Selection.activeGameObject;
            bool hasCreatedScatter = false;
            foreach (GrassPointScatter gps in GameObject.FindObjectsOfType<GrassPointScatter>())
            {
                //check if the active is the one, if none exists, create new:
                Debug.Log(gps.GetMatchedMesh());
                if (gps.GetMatchedMesh() == target)
                {
                    targetScatter = gps;
                    hasCreatedScatter = true;
                    break;
                }
            }
            if (!hasCreatedScatter)
            {
                //create scatter;
                GameObject empty = new GameObject();
                targetScatter = empty.AddComponent<GrassPointScatter>();
            }
            //add collider if none exists:
            if(target.GetComponent<Collider>() == null)
            {
                target.AddComponent<MeshCollider>();
            }
            targetColorInfo = targetScatter.GetColorInfoTexture();
            targetHeightInfo = targetScatter.GetHeightInfoTexture();
            targetScatter.FullReset();
        }
        
        if (target)
        {
            GUILayout.Label("  II. ˢ����Ϣ����", header);
            GUILayout.Label("    ���֮ǰ�б������Ϣ������ѡ����Ϣͼ��ֱ�����롣");
            userTargetColorInfo = (Texture2D)EditorGUILayout.ObjectField("�ݵ���ɫ��Ϣͼ", userTargetColorInfo, typeof(Texture2D), false); //rgb - color
            userTargetHeightInfo = (Texture2D)EditorGUILayout.ObjectField("�ݵظ߰�&������Ϣͼ", userTargetHeightInfo, typeof(Texture2D), false); //r - heightmap, g - amount, b - patch height
            if (GUILayout.Button("����ѡ�еĲݵ���Ϣ"))
            {
                //generate render textures from these info:
                RenderTexture colorInfo = targetScatter.RTFromTexture(userTargetColorInfo);
                RenderTexture heightInfo = targetScatter.RTFromTexture(userTargetHeightInfo);
                targetScatter.SetTextures(colorInfo, heightInfo);
                targetColorInfo = targetScatter.GetColorInfoTexture();
                targetHeightInfo = targetScatter.GetHeightInfoTexture();
                targetScatter.FullReset();
            }


            GUILayout.Label("  III. ����ˢ����", header);
            GUILayout.Label("    ������ˢ��Ȼ��ʼˢ�ݰɣ�");
            EditorGUILayout.BeginHorizontal();
            if(GUILayout.Toggle(currentPaintMode == PaintMode.DENSITY, "���ƣ��ݵ�����", "Button"))
                currentPaintMode = PaintMode.DENSITY;
            if (GUILayout.Toggle(currentPaintMode == PaintMode.HEIGHT, "���ƣ��ݵظ߰�", "Button"))
                currentPaintMode = PaintMode.HEIGHT;
            if (GUILayout.Toggle(currentPaintMode == PaintMode.COLOR, "���ƣ��ݵ�Ⱦɫ", "Button"))
                currentPaintMode = PaintMode.COLOR;
            
            if (GUILayout.Toggle(currentPaintMode == PaintMode.FREEROAM, "�رջ��ƹ���", "Button"))
                currentPaintMode = PaintMode.FREEROAM;
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Toggle(isSetColorsMode, "����ģʽ��������ɫ", "Button"))
                isSetColorsMode = true;
            if (GUILayout.Toggle(!isSetColorsMode, "����ģʽ��������ɫ", "Button"))
                isSetColorsMode = false;
            EditorGUILayout.EndHorizontal();
            brushSize = EditorGUILayout.Slider("���ʴ�С([]������)", brushSize, 0, 100);
            brushSoftness = EditorGUILayout.Slider("����Ӳ��(Shift []������)", brushSoftness, 0, 1);
            brushStrength = EditorGUILayout.Slider("����ǿ��(+-������)", brushStrength, 0, 1);
            brushValue = EditorGUILayout.Slider("������ֵ(Shift +-������)", brushValue, 0, 1);
            if(currentPaintMode != PaintMode.FREEROAM)
            {
                int controlId = GUIUtility.GetControlID(FocusType.Passive);
                GUIUtility.hotControl = controlId;
            }
            //color slider:
            brushColor = EditorGUILayout.ColorField("������ɫ(��Ⱦɫģʽ��Ч)", brushColor);

            GUILayout.Label("  IV. ������", header);
            if (GUILayout.Button("��Ҷ����ʾ���������ã�"))
            {
                targetScatter.SetTextures(targetColorInfo, targetHeightInfo);
                targetScatter.FullReset();
            }
            if (GUILayout.Button("�������ɵĲݵ���Ϣ"))
            {
                //targetScatter.GetColorInfoTexture().Apply(false); 
                //targetScatter.GetHeightInfoTexture().Apply(false);
                WriteImage(targetScatter.GetColorInfoTexture(), target.gameObject.name + "_" + SceneManager.GetActiveScene().name + "_color");
                WriteImage(targetScatter.GetHeightInfoTexture(), target.gameObject.name + "_" + SceneManager.GetActiveScene().name + "_height");

            }//save
            if (GUILayout.Button("�ݵز��ڵ����ϣ��������ɲݵ���Ϣ"))
            {
                targetColorInfo = targetScatter.GetColorInfoTexture(true);
                targetHeightInfo = targetScatter.GetHeightInfoTexture(true);
                targetScatter.FullReset();
            }
        }

    }

    private PaintMode previousPaintMode;

    public void OnSceneView(SceneView sceneview)
    {
        /*


        //for (int i = 0; i < ((Path)target).nodes.Count; i++)
        //    ((Path)target).nodes[i] = Handles.PositionHandle(((Path)target).nodes[i], Quaternion.identity);

        //Handles.DrawPolyLine(((Path)target).nodes.ToArray());

        */
        Event e = Event.current;
        HandleBrushTweak(e);
        if (!target || currentPaintMode == PaintMode.FREEROAM) return;



        Ray worldRay = HandleUtility.GUIPointToWorldRay(e.mousePosition);
        RaycastHit hitInfo;

        //Debug.DrawRay(worldRay.origin, worldRay.direction * 50);
        
        if (Physics.Raycast(worldRay, out hitInfo, float.MaxValue))
        {
            //Debug.Log("hit");
            
            if(hitInfo.collider.gameObject == target)
            {
                Handles.DrawWireDisc(hitInfo.point, hitInfo.normal, brushSize);
                Handles.DrawWireDisc(hitInfo.point, hitInfo.normal, Mathf.Clamp(brushSoftness, 0.01f, 0.99f) * brushSize);
                if (e.type == EventType.MouseDrag || e.type == EventType.MouseDown)
                {
                    if (e.button == 0)
                    {
                        int controlId = GUIUtility.GetControlID(FocusType.Passive);
                        GUIUtility.hotControl = controlId;
                        e.Use();
                        //HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
                        HandleDrawing(hitInfo.point, e.shift ? -1.0f : 1.0f);
                    }
                }
                /*
                if(e.type == EventType.MouseDown && e.button != 0)
                {
                    currentPaintMode = previousPaintMode;
                    int controlId = GUIUtility.GetControlID(FocusType.Passive);
                    GUIUtility.hotControl = controlId;
                    e.Use();
                    //HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
                }*/
            }
        }

        SceneView.RepaintAll();
        Repaint();
        //if (GUI.changed)
            //EditorUtility.SetDirty(target);

    }



    void HandleDrawing(Vector3 worldPos, float reverseInfo)
    {

        //Compute UV Coordinates:
        if (!paintBrushMaterial)
        {
            paintBrushShader = Shader.Find("Hidden/GrassPaint/PaintBrushShader");
            paintBrushMaterial = new Material(paintBrushShader);
        }
        Vector2 uvCoords = targetScatter.ConvertToUVSpace(worldPos);
        float minX, maxX, minZ, maxZ;
        targetScatter.GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        //compute aspect ratio:
        float widthHeightRatio = (maxX - minX) / (maxZ - minZ); //Crucial key to correct aspect
        Vector4 mouseInfoBundle = new Vector4(uvCoords.x, uvCoords.y, widthHeightRatio, 0.0f);
        float scaledBrushSize = brushSize / (maxZ - minZ);
        Vector4 brushSettingsBundle = new Vector4(scaledBrushSize, brushSoftness, brushStrength, reverseInfo);

        Vector4 paintChannelBundle = new Vector4(
            0.0f, currentPaintMode == PaintMode.DENSITY ? 1.0f : 0.0f,
            currentPaintMode == PaintMode.HEIGHT ? 1.0f : 0.0f, 0.0f
        );

        paintBrushMaterial.SetVector("_MouseInfo", mouseInfoBundle);
        paintBrushMaterial.SetVector("_BrushSettings", brushSettingsBundle);
        paintBrushMaterial.SetVector("_ActiveChannel", paintChannelBundle);

        RenderTexture activeContext;

        int passId = 1;
        Color c;
        if (currentPaintMode == PaintMode.COLOR)
        {
            activeContext = targetColorInfo;
            c = brushColor;
            passId = 2;
        }
        else
        {
            activeContext = targetHeightInfo;
            c = new Color(brushValue, brushValue, brushValue, 1.0f);
            if (isSetColorsMode)
                passId = 0;
        }
        paintBrushMaterial.SetVector("_BrushColor", c);



        //argetHeightInfo.
        blitBuffer = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);//new Texture2D(1024, 1024, TextureFormat.ARGB32, false, true);
        //                                                                     use color pass if we in color mode. shift work as removing color (setting to 0)
        Graphics.Blit(activeContext, blitBuffer, paintBrushMaterial, passId);
        Graphics.CopyTexture(blitBuffer, activeContext);
        //activeContext.Apply();
        //blitBuffer.Release();
    }

    void HandleBrushTweak(Event e)
    {
        if (e.type == EventType.KeyDown)
        {
            switch (e.keyCode)
            {
                case KeyCode.LeftBracket:
                    if (e.shift)
                    {
                        //softness
                        brushSoftness -= 0.05f;
                        brushSoftness = Mathf.Max(0.0f, brushSoftness);
                    }
                    else
                    {
                        brushSize -= 1.0f;
                        brushSize = Mathf.Max(1.0f, brushSize);
                    }
                    break;
                case KeyCode.RightBracket:
                    if (e.shift)
                    {
                        brushSoftness += 0.05f;
                        brushSoftness = Mathf.Min(1.0f, brushSoftness);
                    }
                    else
                    {
                        brushSize += 1.0f;
                        brushSize = Mathf.Min(100.0f, brushSize);
                    }

                    break;
                case KeyCode.Equals:
                    //fall thru
                    goto case KeyCode.KeypadPlus;
                case KeyCode.KeypadPlus:
                    if (e.shift)
                    {
                        brushValue += 0.05f;
                        brushValue = Mathf.Min(brushValue, 1.0f);
                    }
                    else
                    {
                        brushStrength += 0.05f;
                        brushStrength = Mathf.Min(brushStrength, 1.0f);
                    }
                    break;
                case KeyCode.Minus:
                    //fall thru
                    goto case KeyCode.KeypadMinus;
                case KeyCode.KeypadMinus:
                    if (e.shift)
                    {
                        brushValue -= 0.05f;
                        brushValue = Mathf.Max(brushValue, 0.0f);
                    }
                    else
                    {
                        brushStrength -= 0.05f;
                        brushStrength = Mathf.Max(brushStrength, 0.0f);
                    }
                    break;
                case KeyCode.Escape:
                    HandleUtility.Repaint();
                    currentPaintMode = PaintMode.FREEROAM;
                    break;
                default:
                    break;
            }
        }
    }

}
