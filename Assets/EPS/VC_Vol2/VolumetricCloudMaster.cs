using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode, RequireComponent(typeof(Camera)), ImageEffectAllowedInSceneView]
public class VolumetricCloudMaster : MonoBehaviour
{
    // Start is called before the first frame update
    [Header("Base Settings")]
    [SerializeField] private Camera targetCamera;
    [SerializeField] private Material postProcessMat;
    [Tooltip("The Box Volume to Hold the Clouds")]
    [SerializeField] private Transform boxVolume;

    [Header("Cloud Details")]
    [SerializeField] private Texture3D cloudVolume3d;
    [SerializeField] private Texture2D weatherMap;
    [SerializeField] private Texture2D blueNoise;

    [Header("Cloud Parameters")]
    [SerializeField][Range(0, 8)] private float densityMultiplier = 1.0f; //default values
    [SerializeField][Range(0, 4)] private float absorption = 1.2f;
    [SerializeField][Range(0, 1)] private float scale = 0.1f;
    [SerializeField][Range(0, 1)] private float weatherMapScale = 0.4f;
    [SerializeField][Range(0, 1)] private float heightMapOffset = 0.5f;
    [SerializeField][Range(0, 5)] private float blueNoiseStrength = 1.0f;
    
    [SerializeField][Range(0, 100)] private float marchDistance = 0.5f;
    

    
    void UpdateMaterialParams(){
        if(targetCamera == null){
            targetCamera = GetComponent<Camera>();
        }
        postProcessMat.SetFloat("_DensityMultiplier", densityMultiplier);
        postProcessMat.SetFloat("_Scale", scale);
        postProcessMat.SetFloat("_LightAbsorption", absorption);
        postProcessMat.SetFloat("_WeatherMapScale", weatherMapScale);
        postProcessMat.SetFloat("_HeightMapOffset", heightMapOffset);
        postProcessMat.SetFloat("_MarchDistance", marchDistance);
        postProcessMat.SetFloat("_BlueNoiseStrength", blueNoiseStrength);
        postProcessMat.SetTexture("_VolumeTex", cloudVolume3d);
        postProcessMat.SetTexture("_BlueNoise", blueNoise);
        postProcessMat.SetTexture("_WeatherMap", weatherMap);
        

        Matrix4x4 viewMat = targetCamera.worldToCameraMatrix;
        Matrix4x4 projMat = GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, false);
        Matrix4x4 viewProjMat = (projMat * viewMat);
        postProcessMat.SetMatrix("_ViewProjInv", viewProjMat.inverse);
        Vector3 boxMin = boxVolume.transform.position - boxVolume.localScale / 2;
        Vector3 boxMax = boxVolume.transform.position + boxVolume.localScale / 2;
        postProcessMat.SetVector("_VBoxMin", new Vector4(boxMin.x, boxMin.y, boxMin.z, 0.0f));
        postProcessMat.SetVector("_VBoxMax", new Vector4(boxMax.x, boxMax.y, boxMax.z, 0.0f));
        
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //regardless, you need to pass in some data...
        UpdateMaterialParams();
        Graphics.Blit(src, dest, postProcessMat);
    }
}
