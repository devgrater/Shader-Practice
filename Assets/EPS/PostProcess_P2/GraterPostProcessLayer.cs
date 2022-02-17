using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//extend this, and voila
public class GraterPostProcessLayer
{
    // Start is called before the first frame update
    private Material postProcessMaterial;
    public void OnRenderImage(RenderTexture src, RenderTexture dest){
        Graphics.Blit(src, dest, postProcessMaterial);
    }
}
