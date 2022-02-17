using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class PostEffect : MonoBehaviour
{
    // Start is called before the first frame update
    public Material mat;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // Copy the source Render Texture to the destination,
        // applying the material along the way.
        Graphics.Blit(src, dest, mat);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
