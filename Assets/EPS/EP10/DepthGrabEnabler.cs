using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class DepthGrabEnabler : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] private DepthTextureMode depthTextureMode = DepthTextureMode.Depth;
    private Camera targetCamera;
    void OnEnable()
    {
        this.targetCamera = GetComponent<Camera>();
        targetCamera.depthTextureMode = depthTextureMode;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
