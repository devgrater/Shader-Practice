using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using System.IO;


public class GrassPainter : EditorWindow
{
    private Texture2D WriteImage(RenderTexture texture, string name)
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
        try
        {
            string path = dirPath + "Grass_" + name + ".jpg";
            File.WriteAllBytes(path, bytes);
            AssetDatabase.ImportAsset("./Assets/GrassData/" + "Grass_" + name + ".jpg");
            Texture2D targetTex = (Texture2D)AssetDatabase.LoadAssetAtPath("./Assets/GrassData/" + "Grass_" + name + ".jpg", typeof(Texture2D));
            return targetTex;
        }
        catch (System.Exception e)
        {
            Debug.LogError(e);
            return null;
        }
        
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
    [MenuItem("刷草/刷草")]
    public static void OpenEditorWindow()
    {
        EditorWindow.GetWindow<GrassPainter>(false, "刷草！");
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

        GUILayout.Label("  I. 选择你的刷草地形", header);
        if (!target)
        {
            
            GUILayout.Label("    选中需要刷草的物体，然后点击在\"选中目标上刷草\"");
        }
        if (GUILayout.Button("在选中目标上刷草") && Selection.activeGameObject != null)
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
            GUILayout.Label("  II. 刷草信息载入", header);
            GUILayout.Label("    如果之前有保存过信息，可以选择信息图后直接载入。");
            userTargetColorInfo = (Texture2D)EditorGUILayout.ObjectField("草地颜色信息图", userTargetColorInfo, typeof(Texture2D), false); //rgb - color
            userTargetHeightInfo = (Texture2D)EditorGUILayout.ObjectField("草地高矮&数量信息图", userTargetHeightInfo, typeof(Texture2D), false); //r - heightmap, g - amount, b - patch height
            if (GUILayout.Button("载入选中的草地信息"))
            {
                //generate render textures from these info:
                RenderTexture colorInfo = targetScatter.RTFromTexture(userTargetColorInfo);
                RenderTexture heightInfo = targetScatter.RTFromTexture(userTargetHeightInfo);
                targetScatter.SetTextures(colorInfo, heightInfo);
                targetColorInfo = targetScatter.GetColorInfoTexture();
                targetHeightInfo = targetScatter.GetHeightInfoTexture();
                targetScatter.FullReset();
            }


            GUILayout.Label("  III. 快乐刷草人", header);
            GUILayout.Label("    调整笔刷，然后开始刷草吧！");
            EditorGUILayout.BeginHorizontal();
            if(GUILayout.Toggle(currentPaintMode == PaintMode.DENSITY, "绘制：草地数量", "Button"))
                currentPaintMode = PaintMode.DENSITY;
            if (GUILayout.Toggle(currentPaintMode == PaintMode.HEIGHT, "绘制：草地高矮", "Button"))
                currentPaintMode = PaintMode.HEIGHT;
            if (GUILayout.Toggle(currentPaintMode == PaintMode.COLOR, "绘制：草地染色", "Button"))
                currentPaintMode = PaintMode.COLOR;
            
            if (GUILayout.Toggle(currentPaintMode == PaintMode.FREEROAM, "关闭绘制功能", "Button"))
                currentPaintMode = PaintMode.FREEROAM;
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Toggle(isSetColorsMode, "绘制模式：设置颜色", "Button"))
                isSetColorsMode = true;
            if (GUILayout.Toggle(!isSetColorsMode, "绘制模式：叠加颜色", "Button"))
                isSetColorsMode = false;
            EditorGUILayout.EndHorizontal();
            brushSize = EditorGUILayout.Slider("画笔大小([]键更改)", brushSize, 0, 100);
            brushSoftness = EditorGUILayout.Slider("画笔硬度(Shift []键更改)", brushSoftness, 0, 1);
            brushStrength = EditorGUILayout.Slider("画笔强度(+-键更改)", brushStrength, 0, 1);
            brushValue = EditorGUILayout.Slider("画笔数值(Shift +-键更改)", brushValue, 0, 1);
            if(currentPaintMode != PaintMode.FREEROAM)
            {
                int controlId = GUIUtility.GetControlID(FocusType.Passive);
                GUIUtility.hotControl = controlId;
            }
            //color slider:
            brushColor = EditorGUILayout.ColorField("画笔颜色(仅染色模式生效)", brushColor);

            GUILayout.Label("  IV. 功能区", header);
            if (GUILayout.Button("草叶不显示？点我重置！"))
            {
                targetScatter.SetTextures(targetColorInfo, targetHeightInfo);
                targetScatter.FullReset();
            }
            if (GUILayout.Button("保存生成的草地信息"))
            {
                //targetScatter.GetColorInfoTexture().Apply(false); 
                //targetScatter.GetHeightInfoTexture().Apply(false);
                Texture2D colorTex = WriteImage(targetScatter.GetColorInfoTexture(), target.gameObject.name + "_" + SceneManager.GetActiveScene().name + "_color");
                Texture2D heightTex = WriteImage(targetScatter.GetHeightInfoTexture(), target.gameObject.name + "_" + SceneManager.GetActiveScene().name + "_height");
                //targetScatter.ApplyTextures(colorTex, heightTex);
            }//save
            if (GUILayout.Button("草地不在地面上？重新生成草地信息"))
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
