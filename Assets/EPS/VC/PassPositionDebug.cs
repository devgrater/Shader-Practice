using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PassPositionDebug : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField]private GameObject tPos;
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
        mat.SetVector("_WorldPos", tPos.transform.position);
    }
}
