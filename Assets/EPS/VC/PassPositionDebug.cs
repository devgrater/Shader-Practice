using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PassPositionDebug : MonoBehaviour
{
    // Start is called before the first frame update
    private Material mat;
    private MaterialPropertyBlock mpb;
    private Renderer renderer;
    void Start()
    {
        
        
    }

    // Update is called once per frame
    void Update()
    {
        //renderer.GetPropertyBlock(mpb);
        if(mat == null){
            renderer = GetComponent<Renderer>();
            mat = renderer.sharedMaterial;
        }
        float centerPos = transform.position.y;
        mat.SetFloat("_WorldBottom", centerPos - transform.localScale.y / 2.0f);
        mat.SetFloat("_WorldTop", centerPos + transform.localScale.y / 2.0f);
    }
}
