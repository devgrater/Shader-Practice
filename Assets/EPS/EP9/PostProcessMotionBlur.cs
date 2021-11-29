using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostProcessMotionBlur : MonoBehaviour
{
    // Start is called before the first frame update
    private RenderTexture accumulation;
    [Range(0.0f, 0.9f)]
    [SerializeField] private float blurAmount;
    [SerializeField] private Material postProcess;
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            if(accumulation == null || accumulation.width != src.width || accumulation.height != src.height){
                DestroyImmediate(accumulation);
                accumulation = new RenderTexture(src.width, src.height, 0);
                accumulation.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, accumulation);
            }
            accumulation.MarkRestoreExpected();
            postProcess.SetFloat("_BlurAmount", 1.0f - blurAmount);
            Graphics.Blit(src, accumulation, postProcess);
            Graphics.Blit(accumulation, dest);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
