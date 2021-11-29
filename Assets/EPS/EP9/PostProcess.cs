using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostProcess : MonoBehaviour
{
    [Range(0, 3)]
    [SerializeField] private float brightness;
    [Range(0, 3)]
    [SerializeField] private float saturation;
    [Range(0, 3)]
    [SerializeField] private float contrast;
    [SerializeField] private Material postProcess;
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            postProcess.SetFloat("_Brightness", brightness);
            postProcess.SetFloat("_Saturation", saturation);
            postProcess.SetFloat("_Contrast", contrast);
            Graphics.Blit(src, dest, postProcess);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
