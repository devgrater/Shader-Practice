using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class VolumetricCloudMaster : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] private Camera targetCamera;
    [SerializeField] private Material postProcessMat;
    [Tooltip("The Box Volume to Hold the Clouds")]
    [SerializeField] private Transform boxVolume;

    
    void UpdateMaterialParams(){
        if(targetCamera == null){
            targetCamera = GetComponent<Camera>();
        }
        Matrix4x4 viewMat = targetCamera.worldToCameraMatrix;
        Matrix4x4 projMat = GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, false);
        Matrix4x4 viewProjMat = (projMat * viewMat);
        postProcessMat.SetMatrix("_ViewProjInv", viewProjMat.inverse);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //regardless, you need to pass in some data...
        UpdateMaterialParams();
        Graphics.Blit(src, dest, postProcessMat);
    }
}
