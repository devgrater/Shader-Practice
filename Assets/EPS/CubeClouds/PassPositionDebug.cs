using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PassPositionDebug : MonoBehaviour
{
    // Start is called before the first frame update
    private Material mat;
    private MaterialPropertyBlock mpb;
    private Renderer targetRenderer;
    void Start()
    {
        
        
    }

    // Update is called once per frame
    void Update()
    {
        //targetRenderer.GetPropertyBlock(mpb);
        if(mat == null){
            targetRenderer = GetComponent<Renderer>();
            mat = targetRenderer.sharedMaterial;
        }
        float centerPos = transform.position.y;
        mat.SetFloat("_WorldBottom", centerPos - transform.localScale.y / 2.0f);
        mat.SetFloat("_WorldTop", centerPos + transform.localScale.y / 2.0f);
    }
}
