using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SDFMaker : MonoBehaviour
{
    // Start is called before the first frame update
    private RenderTexture rt;
    [SerializeField] private ComputeShader compute;
    void ComputeSDF(Texture2D tex){
        rt = new RenderTexture(tex.width, tex.height, 24);
    }
}
