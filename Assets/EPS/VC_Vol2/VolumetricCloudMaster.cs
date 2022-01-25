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

    [Header("Weather Map")]
    [SerializeField] private Texture2D weatherMap;
    [SerializeField][Range(0, 1)] private float weatherMapScale = 0.4f;
    [SerializeField][Range(-1, 1)] private float weatherMapOffset = 0.0f;
    [SerializeField][Range(0, 1)] private float heightMapOffset = 0.5f;
    

    [Header("Rough Mask")]
    [SerializeField] private Texture3D cloudMask3d; //not yet used, soon (tm)
    [SerializeField][Range(0, 1)] private float cloudMaskScale = 0.1f;
    [SerializeField] private Vector4 cloudMaskWeight;

    [Header("Detail Mask")]
    [SerializeField] private Texture3D cloudDetail3d;
    [SerializeField][Range(0, 1)] private float cloudDetailScale = 0.1f;
    [SerializeField] private Vector4 cloudDetailWeight;

    [Header("Blue Noise Sampling")]
    [SerializeField] private Texture2D blueNoise;
    [SerializeField][Range(0, 5)] private float blueNoiseStrength = 1.0f;


    [Header("Cloud Parameters")]
    [SerializeField][Range(0, 8)] private float densityMultiplier = 1.0f; //default values
    [SerializeField][Range(0, 4)] private float absorption = 1.2f;
    
    [SerializeField] private Vector4 phaseParams;
    
    [SerializeField][Range(0, 100)] private float marchDistance = 0.5f;

    [Header("Cloud Colors")]
    [SerializeField][ColorUsage(true, true)] private Color midToneColor;
    [SerializeField][ColorUsage(true, true)] private Color lowToneColor;
    [SerializeField][Range(0, 2)] private float shadowPower = 0.5f;
    [SerializeField][Range(0, 2)] private float brightnessPower = 0.5f;
    [SerializeField][Range(0, 1)] private float shadowThreshold = 0.5f;

    [Header("Animations")]
    [SerializeField] private Vector4 baseMapAnimation;
    [SerializeField] private Vector4 weatherMapAnimation;
    [SerializeField] private Vector4 detailMapAnimation;
    

    
    void UpdateMaterialParams(){
        if(targetCamera == null){
            targetCamera = GetComponent<Camera>();
        }
        //////////////// USER PARAMETERS //////////////////
        postProcessMat.SetFloat("_DensityMultiplier", densityMultiplier);
        postProcessMat.SetFloat("_Scale", cloudDetailScale);
        postProcessMat.SetFloat("_LightAbsorption", absorption);
        postProcessMat.SetFloat("_WeatherMapScale", weatherMapScale);
        postProcessMat.SetFloat("_WeatherMapOffset", weatherMapOffset);
        postProcessMat.SetFloat("_HeightMapOffset", heightMapOffset);
        postProcessMat.SetFloat("_MarchDistance", marchDistance);
        postProcessMat.SetFloat("_BlueNoiseStrength", blueNoiseStrength);
        postProcessMat.SetFloat("_CloudMaskScale", cloudMaskScale);

        postProcessMat.SetFloat("_ShadowPower", shadowPower);
        postProcessMat.SetFloat("_ShadowThreshold", shadowThreshold);
        postProcessMat.SetFloat("_BrightnessPower", brightnessPower);

        ///////////////
        postProcessMat.SetVector("_CloudMaskWeight", cloudMaskWeight);
        postProcessMat.SetVector("_CloudDetailWeight", cloudDetailWeight);
        postProcessMat.SetVector("_ShadowColor", lowToneColor);
        postProcessMat.SetVector("_MidColor", midToneColor);
        postProcessMat.SetVector("_PhaseParams", phaseParams);

        //////////////// TEXTURES ///////////////////////////

        postProcessMat.SetTexture("_VolumeTex", cloudDetail3d);
        postProcessMat.SetTexture("_CloudMask", cloudMask3d);
        postProcessMat.SetTexture("_BlueNoise", blueNoise);
        postProcessMat.SetTexture("_WeatherMap", weatherMap);

        ////////////// ANIMATIONS //////////////////////
        postProcessMat.SetVector("_BaseMapAnim", baseMapAnimation);
        postProcessMat.SetVector("_WeatherMapAnim", weatherMapAnimation);
        postProcessMat.SetVector("_DetailMapAnim", detailMapAnimation);

        
        ////////////// AUTOMATIC //////////////////////////
        Vector3 boxMin = boxVolume.transform.position - boxVolume.localScale / 2;
        Vector3 boxMax = boxVolume.transform.position + boxVolume.localScale / 2;
        postProcessMat.SetVector("_VBoxMin", new Vector4(boxMin.x, boxMin.y, boxMin.z, 0.0f));
        postProcessMat.SetVector("_VBoxMax", new Vector4(boxMax.x, boxMax.y, boxMax.z, 0.0f));
        
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //regardless, you need to pass in some data...
        UpdateMaterialParams();
        //command buffer
        Graphics.Blit(src, dest, postProcessMat);
    }
}
