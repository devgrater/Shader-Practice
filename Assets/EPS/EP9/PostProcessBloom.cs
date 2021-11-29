using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostProcessBloom : MonoBehaviour
{
    [Range(0, 4)]
    [SerializeField] private float bloomIntensity;  
    [Range(0, 4)]
    [SerializeField] private float bloomThreshold;  
    [Range(0, 4)]
    [SerializeField] private float blurAmount;  
    [Range(1, 8)]
    [SerializeField] private int iterations;
    [Range(1, 16)]
    [SerializeField] private int downSample;
    [SerializeField] private Material postProcess;
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            float ratio = rtW / rtH;
            postProcess.SetFloat("_BlurSize", blurAmount);
            postProcess.SetFloat("_BloomIntensity", bloomIntensity);
            postProcess.SetFloat("_Threshold", bloomThreshold);
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src, buffer, postProcess, 2); // extract features
            
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
            postProcess.SetTexture("_BloomOnly", buffer);
            Graphics.Blit(src, dest, postProcess, 3);
            RenderTexture.ReleaseTemporary(buffer);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
