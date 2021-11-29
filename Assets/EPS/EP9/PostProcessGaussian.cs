using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostProcessGaussian : MonoBehaviour
{
    [Range(0, 8)]
    [SerializeField] private float blurAmount;
    [Range(0, 8)]
    [SerializeField] private int iterations;
    [Range(1, 8)]
    [SerializeField] private int downSample;
    [SerializeField] private Material postProcess;
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            float ratio = rtW / rtH;
            postProcess.SetFloat("_BlurSize", blurAmount);
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src, buffer);
            for(int i = 0; i < iterations; i++){
                postProcess.SetFloat("_BlurSize", 1.0f + i * blurAmount);
                RenderTexture secondaryBuffer = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer, secondaryBuffer, postProcess, 0);
                RenderTexture.ReleaseTemporary(buffer);
                buffer = secondaryBuffer;
                secondaryBuffer = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer, secondaryBuffer, postProcess, 1);
                RenderTexture.ReleaseTemporary(buffer);
                buffer = secondaryBuffer;
            }
            
            //downsample for easier processing
            Graphics.Blit(buffer, dest);
            RenderTexture.ReleaseTemporary(buffer);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
