using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SDFMaker : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] private RenderTexture rt;
    [SerializeField] private RenderTexture rt2;
    [SerializeField] private ComputeShader compute;
    //private bool isFirstTextureUsed = false;
    public void ComputeSDF(Texture2D tex){
        rt = new RenderTexture(tex.width, tex.height, 24);
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.wrapMode = TextureWrapMode.Clamp;
        rt.Create();

        rt2 = new RenderTexture(tex.width, tex.height, 24);
        rt2.enableRandomWrite = true;
        rt2.filterMode = FilterMode.Point;
        rt2.wrapMode = TextureWrapMode.Clamp;
        rt2.Create();

        compute.SetTexture(0, "_MainTex", rt);
        compute.SetTexture(0, "_Previous", tex);
        compute.SetVector("_Dimensions", new Vector4(tex.width, tex.height, 0.0f, 1.0f));
        int xRound = Mathf.CeilToInt(tex.width / 8);
        int yRound = Mathf.CeilToInt(tex.height / 8);
        compute.Dispatch(0, xRound, yRound, 1);
        //this creates the initial image.

        float stepWidth = tex.width * 0.5f;
        float stepHeight = tex.height * 0.5f;
        bool isFirstTextureUsed = true;
        while(stepWidth >= 1 || stepHeight >= 1){
            if(isFirstTextureUsed){
                // use first texture as source, second texture as dest;
                Debug.Log("Step SDF 1st");
                StepSDF(rt, rt2, stepWidth, stepHeight);
                isFirstTextureUsed = false;
            }
            else{
                Debug.Log("Step SDF 2nd");
                StepSDF(rt2, rt, stepWidth, stepHeight);
                isFirstTextureUsed = true;
            }
            stepWidth *= 0.5f;
            stepHeight *= 0.5f;
        }


    }

    public void StepSDF(RenderTexture src, RenderTexture dest, float stepWidth, float stepHeight){
        
        int w = Mathf.RoundToInt(stepWidth);
        int h = Mathf.RoundToInt(stepHeight);
        compute.SetTexture(1, "_Previous", src);
        compute.SetTexture(1, "_MainTex", dest);
        compute.SetVector("_Dimensions", new Vector4(src.width, src.height, 0.0f, 1.0f));
        compute.SetVector("_StepSize", new Vector4(w, h, 0.0f, 1.0f));
        int xRound = Mathf.CeilToInt(src.width / 8);
        int yRound = Mathf.CeilToInt(src.height / 8);
        compute.Dispatch(0, xRound, yRound, 1);
    }
}
