using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ToonLightingRamp : MonoBehaviour
{

    
    [Header("Colors")]
    public Gradient gradient = new Gradient();
    

    [Header("Outlines")]
    public Color color = new Color();

    private Texture2D gradientMap;

    void RecomputeGradientMap(){
        //no mip
        gradientMap = new Texture2D(256, 1, TextureFormat.ARGB32, false);
        for(int i = 0; i < 256; i++){
            gradientMap.SetPixel(i, 0, gradient.Evaluate(i / 256.0f));
        }
        gradientMap.Apply();
        gradientMap.wrapMode = TextureWrapMode.Clamp;
        //assign it to the shaders as a global
    }
    // Start is called before the first frame update
    void Start()
    {
        RecomputeGradientMap();
        PassDataToShader();
    }

    void PassDataToShader(){
        Shader.SetGlobalColor("_OutlineColor", color);
    }
    void Update(){
        //only in editor
        //if(!Application.isPlaying){
        // The script is executing inside the editor
            RecomputeGradientMap();
            //Shader.SetGlobalTexture("_ToonLightingRamp", gradientMap);
            PassDataToShader();
        //}
    }

}
