using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToonLightingRamp : MonoBehaviour
{

    
    [Header("Colors")]
    public Gradient gradient = new Gradient();
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
    }


}
