using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


public class GrassPainter : EditorWindow
{
    static GameObject target;
    static GrassPointScatter targetScatter;
    [MenuItem("刷草/刷草")]
    public static void OpenEditorWindow()
    {
        EditorWindow.GetWindow<GrassPainter>(false, "刷草！");
    }

    private void OnGUI()
    {
        if (GUILayout.Button("在选中目标上刷草") && Selection.activeGameObject != null)
        {
            target = Selection.activeGameObject;
            bool hasCreatedScatter = false;
            foreach(GrassPointScatter gps in GameObject.FindObjectsOfType<GrassPointScatter>())
            {
                //check if the active is the one, if none exists, create new:
                if(gps.GetMatchedMesh() == target)
                {
                    targetScatter = gps;
                    hasCreatedScatter = true;
                    break;
                }
            }
            if (!hasCreatedScatter)
            {
                //create scatter;
            }
        }
        
    }
}
