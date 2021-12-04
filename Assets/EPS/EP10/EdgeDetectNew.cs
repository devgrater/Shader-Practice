using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class EdgeDetectNew : MonoBehaviour
{
    // Start is called before the first frame update
    
    [SerializeField] private Material postProcess;
    [SerializeField] private Vector2 sensitivity;
    [SerializeField] private float sampleDistance;
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        
        if(postProcess != null){
            Graphics.Blit(src, dest, postProcess);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
