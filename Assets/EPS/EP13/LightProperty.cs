using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class LightProperty : MonoBehaviour
{
    // Start is called before the first frame update

    [Range(0, 8)][SerializeField] private int PCFIteration;
    
    [Range(0.0f, 2.0f)][SerializeField] private float lightSize;
    private Camera mainCamera;
    private float timeElapsed;
    void Start()
    {
        
        mainCamera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        timeElapsed += Time.deltaTime;
        lightSize = Mathf.Sin(timeElapsed * 1.5f) * 0.8f + 1;
        if(!mainCamera){ mainCamera = GetComponent<Camera>(); }
        Shader.SetGlobalVector("_cst_NearFar", new Vector4(mainCamera.nearClipPlane, mainCamera.farClipPlane, 0, 0));
        Shader.SetGlobalVector("_cst_LightDir", transform.forward);
        Matrix4x4 worldToScreen = mainCamera.projectionMatrix * mainCamera.worldToCameraMatrix;
        Shader.SetGlobalMatrix("_cst_WorldToCamera", (worldToScreen));
        Shader.SetGlobalFloat("_PCFSampleDistance", lightSize);
        Shader.SetGlobalFloat("_PCFIteration", PCFIteration);
    }
}
