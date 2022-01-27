using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraProperties : MonoBehaviour
{
    // Start is called before the first frame update
    private Camera targetCamera;
    void Start()
    {
        targetCamera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        //convert targetCamera space coords to world space coords...
        
    }
}
