using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraReplacement : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField]private Shader shader;
    void Start()
    {
        GetComponent<Camera>().SetReplacementShader(shader, "RenderType");
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
