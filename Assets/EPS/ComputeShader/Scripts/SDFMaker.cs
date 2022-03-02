using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SDFMaker : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] private RenderTexture rt;
    [SerializeField] private ComputeShader compute;
    public void ComputeSDF(Texture2D tex){
        rt = new RenderTexture(tex.width, tex.height, 24);
        rt.enableRandomWrite = true;
        rt.Create();

        compute.SetTexture(0, "_MainTex", rt);
        compute.SetVector("_Dimensions", new Vector4(tex.width, tex.height, 0.0f, 1.0f));
        int xRound = Mathf.CeilToInt(tex.width / 8);
        int yRound = Mathf.CeilToInt(tex.height / 8);
        compute.Dispatch(0, xRound, yRound, 1);
    }
}
