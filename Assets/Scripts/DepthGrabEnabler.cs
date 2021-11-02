using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class DepthGrabEnabler : MonoBehaviour
{
    // Start is called before the first frame update
    private Camera targetCamera;
    void OnEnable()
    {
        this.targetCamera = GetComponent<Camera>();
        targetCamera.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
