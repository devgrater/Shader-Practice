using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class MotionBlurWithDepth : MonoBehaviour
{
    // Start is called before the first frame update
    [Range(0, 1)]
    [SerializeField] private float blurAmount;
    [SerializeField] private Material postProcess;

    private Camera currentCamera;
    public Camera targetCamera {
        get {
            if(currentCamera == null){
                currentCamera = GetComponent<Camera>();
            }
            return currentCamera;
        }
    }
    private Matrix4x4 previousProjectionMatrix;
    private Matrix4x4 currentProjectionMatrix;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            postProcess.SetFloat("_BlurAmount", blurAmount);
            postProcess.SetMatrix("_PreviousProjection", previousProjectionMatrix);
            currentProjectionMatrix = targetCamera.projectionMatrix * targetCamera.worldToCameraMatrix;
            Matrix4x4 inverse = currentProjectionMatrix.inverse;
            postProcess.SetMatrix("_CurrentProjectionInverse", inverse);
            previousProjectionMatrix = currentProjectionMatrix;
            //with these...

            Graphics.Blit(src, dest, postProcess);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
