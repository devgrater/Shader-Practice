using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera)), ImageEffectAllowedInSceneView]
public class RampFog : MonoBehaviour
{
    [Header("Base Settings")]
    [SerializeField] private Camera targetCamera;

    [Header("Colors")]
    public Gradient gradient = new Gradient();
    private Texture2D gradientMap;
    [SerializeField] private Material postProcessMat;
    // Start is called before the first frame update
    void Start()
    {
        RecomputeGradientMap();
    }

    void RecomputeGradientMap(){
        //no mip
        gradientMap = new Texture2D(256, 1, TextureFormat.ARGB32, false);
        for(int i = 0; i < 256; i++){
            gradientMap.SetPixel(i, 0, gradient.Evaluate(i / 256.0f));
        }
        gradientMap.Apply();
        gradientMap.wrapMode = TextureWrapMode.Clamp;
    }

    // Update is called once per frame
    void Update()
    {
        if(!Application.isPlaying){
            // The script is executing inside the editor
            RecomputeGradientMap();
        }
    }

    void UpdateMaterialParams(){
        if(targetCamera == null){
            targetCamera = GetComponent<Camera>();
        }
        postProcessMat.SetTexture("_GradientMap", gradientMap);
    }
    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //regardless, you need to pass in some data...
        if(!Application.isPlaying){
            // The script is executing inside the editor
            RecomputeGradientMap();
        }
 

        UpdateMaterialParams();
        //command buffer
        Graphics.Blit(src, dest, postProcessMat);
    }
}
