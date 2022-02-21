using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera)), ImageEffectAllowedInSceneView]
public class BottleOfStarComponent : MonoBehaviour
{

    [SerializeField] private Material postProcessMat;
    private Camera targetCamera;

    void UpdateMaterialParams(){
        if(targetCamera == null){
            targetCamera = GetComponent<Camera>();
        }
        //////////////// USER PARAMETERS //////////////////
        
        
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //regardless, you need to pass in some data...
        UpdateMaterialParams();
        //command buffer
        Graphics.Blit(src, dest, postProcessMat);
    }
}
