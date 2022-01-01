using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class LightProperty : MonoBehaviour
{
    // Start is called before the first frame update

    [Range(0, 8)][SerializeField] private int pcssIteration;
    
    [Range(0.0f, 2.0f)][SerializeField] private float lightSize;
    private Camera mainCamera;
    void Start()
    {
        
        mainCamera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        if(!mainCamera){ mainCamera = GetComponent<Camera>(); }
        Shader.SetGlobalVector("_cst_NearFar", new Vector4(mainCamera.nearClipPlane, mainCamera.farClipPlane, 0, 0));
        Shader.SetGlobalVector("_cst_LightDir", transform.forward);
        Matrix4x4 worldToScreen = mainCamera.projectionMatrix * mainCamera.worldToCameraMatrix;
        Shader.SetGlobalMatrix("_cst_WorldToCamera", (worldToScreen));
        Shader.SetGlobalFloat("_PCSSSampleDistance", lightSize);
        Shader.SetGlobalFloat("_PCSSIteration", pcssIteration);
    }
}
