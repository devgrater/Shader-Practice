using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SkyboxController : MonoBehaviour
{
    [Header("基本设置")]
    [LabelOverride("天空材质球")]  
    [SerializeField] private Material skyboxMat;  
    [Header("昼夜调整")]
    [LabelOverride("时间")]  
    [Range(0, 24000)][SerializeField] private int timeOfDay;
    [LabelOverride("天体轨迹旋转(还没做！)")]
    [Range(0, 360)][SerializeField] private int sunPathRotation;
    [Header("颜色调整 - 综合")]
    [LabelOverride("天空渐变 - 清晨")]  
    public Gradient duskGradient = new Gradient();
    [LabelOverride("天空渐变 - 正午")]   
    public Gradient noonGradient = new Gradient();
    [LabelOverride("天空渐变 - 傍晚")]  
    public Gradient dawnGradient = new Gradient();
    [LabelOverride("天空渐变 - 深夜")]  
    public Gradient nightGradient = new Gradient();
    private Texture2D gradientMap;

    [Header("颜色调整 - 太阳")]
    [LabelOverride("太阳颜色")]   
    [SerializeField] private Color sunColor;

    [LabelOverride("太阳缩放")]   
    [Tooltip("数字越大 太阳越小")]
    [Range(1, 128)][SerializeField] private float sunSize = 100;
    [LabelOverride("太阳亮度")]
    [Range(1, 64)] [SerializeField] private float sunStrength = 64;
    [LabelOverride("太阳晕染")]
    [Range(0, 1)] [SerializeField] private float sunSheen = 0.7f;

    [Header("颜色调整 - 月亮")]
    [LabelOverride("月亮颜色")] 
    [SerializeField] private Color moonColor;
    [LabelOverride("月亮缩放")]   
    [Tooltip("数字越大 月亮越小")]
    [Range(1, 128)][SerializeField] private float moonSize = 60;
    [LabelOverride("月亮亮度")]
    [Range(1, 64)] [SerializeField] private float moonStrength = 40;
    [LabelOverride("月亮晕染")]
    [Range(0, 1)] [SerializeField] private float moonSheen = 0.4f;

    [Header("颜色调整 - 星星")]
    [LabelOverride("星星缩放")]
    [SerializeField][Range(32, 128)] private float starSize = 64;
    [LabelOverride("星星亮度")]
    [Range(0, 8)] [SerializeField] private float starStrength = 2;
    [LabelOverride("红星颜色")]
    [ColorUsage(true, true)] [SerializeField] private Color starSpectraRed = new Color(3.0f, 0.0f, 0.0f);
    [LabelOverride("蓝星颜色")]
    [ColorUsage(true, true)] [SerializeField] private Color starSpectraBlue = new Color(0.0f, 0.0f, 3.0f);

    [Header("颜色调整 - 云层")]
    [LabelOverride("云层透明度")]
    [SerializeField] [Range(0, 1)] private float cloudOpacity = 1.0f;
    [LabelOverride("云层可见度")]
    [Range(0, 1)] [SerializeField] private float cloudVisibility = 1.0f;
    [LabelOverride("云层柔边")]
    [Range(0, 1)] [SerializeField] private float cloudSoftness = 1.0f;


    [Header("天空素材")]
    [LabelOverride("云层、星空材质")]   //R-高层云 G-地平线云 B-星空
    [Tooltip("R-高层云 G-星空 B-噪声")]
    [SerializeField] private Texture2D clouds;

    [SerializeField] private Light sunLight;
    [SerializeField] private Light moonLight;


    // Start is called before the first frame update
    void Start()
    {
        RecomputeGradientMap();
        //directionalLight = GetComponent<Light>();
    }

    void RecomputeGradientMap()
    {
        //no mip
        gradientMap = new Texture2D(512, 8, TextureFormat.ARGB32, false);
        for(int i = 0; i < 512; i++){
            gradientMap.SetPixel(i, 0, nightGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 1, nightGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 2, duskGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 3, noonGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 4, noonGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 5, noonGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 6, dawnGradient.Evaluate(i / 512.0f));
            gradientMap.SetPixel(i, 7, nightGradient.Evaluate(i / 512.0f));
        }
        gradientMap.Apply();
        gradientMap.filterMode = FilterMode.Bilinear;
        gradientMap.wrapMode = TextureWrapMode.Clamp;
    }

    // Update is called once per frame
    void Update()
    {
        if(!Application.isPlaying){
            // The script is executing inside the editor
            RecomputeGradientMap();
        }
        UpdateMaterialParams();
        //UpdateDirectionalLight();
    }

    void UpdateDirectionalLight()
    {
        float normalizedTimeOfDay = (timeOfDay % 24000.0f) / 24000.0f;
        float xRotation = -(normalizedTimeOfDay) * Mathf.PI * 2;

       //// float angleRotation = sunPathRotation / 720.0f * Mathf.PI;
        //float cosX = Mathf.Cos(angleRotation);
        //float sinX = Mathf.Sin(angleRotation);
        //Quaternion sunRot = new Quaternion(cosX, 0.0f, -sinX,  xRotation);
        //transform.rotation = sunRot;
        transform.eulerAngles = new Vector3( normalizedTimeOfDay * 360.0f, 0.0f, 0.0f);
    }

    void UpdateMaterialParams()
    {
        skyboxMat.SetTexture("_ColorRamp", gradientMap);
        skyboxMat.SetVector("_SunControl", new Vector4(sunSize, sunStrength, sunSheen, 0.0f));
        skyboxMat.SetVector("_MoonControl", new Vector4(moonSize, moonStrength, moonSheen, 0.0f));
        skyboxMat.SetVector("_StarControl", new Vector4(starSize, starStrength, 0.0f, 0.0f));
        skyboxMat.SetVector("_CloudControl", new Vector4(cloudOpacity, cloudVisibility, cloudSoftness, 0.0f));
        skyboxMat.SetVector("_SunDir", sunLight.transform.forward.normalized);
        skyboxMat.SetVector("_MoonDir", moonLight.transform.forward.normalized);
        skyboxMat.SetColor("_SunColor", sunColor * (sunLight.enabled ? 1.0f : 0.0f));
        skyboxMat.SetColor("_MoonColor", moonColor * (moonLight.enabled ? 1.0f : 0.0f));
        skyboxMat.SetColor("_StarRed", starSpectraRed);
        skyboxMat.SetColor("_StarBlue", starSpectraBlue);

        /*skyboxMat.SetFloat("_SunSize", sunSize);
        skyboxMat.SetFloat("_SunStrength", sunStrength);
        skyboxMat.SetFloat("_SunSheen", sunSheen);
        
        skyboxMat.SetFloat("_MoonSize", moonSize);
        skyboxMat.SetFloat("_MoonStrength", moonStrength);
        skyboxMat.SetFloat("_MoonSheen", moonSheen);*/
        skyboxMat.SetTexture("_CloudsTex", clouds);
        skyboxMat.SetFloat("_TimeOfDay", (timeOfDay % 24000.0f) / 24000.0f);
        /*postProcessMat.SetTexture("_GradientMap", gradientMap);*/
        sunLight.color = sunColor;
        moonLight.color = moonColor;
        //Shader.SetGlobalTexture("_ColorRamp", gradientMap);

    }

    public Texture2D GetColorRamp()
    {
        return gradientMap;
    }
    
    public float GetTimeOfDay()
    {
        return (timeOfDay % 24000.0f) / 24000.0f;
    }

    public void SetupExternalMaterialParams(Material mat)
    {
        mat.SetVector("_SunControl", new Vector4(sunSize, sunStrength, sunSheen, 0.0f));
        mat.SetVector("_MoonControl", new Vector4(moonSize, moonStrength, moonSheen, 0.0f));
        mat.SetVector("_SunDir", sunLight.transform.forward.normalized);
        mat.SetVector("_MoonDir", moonLight.transform.forward.normalized);
        mat.SetColor("_SunColor", sunColor * (sunLight.enabled ? 1.0f : 0.0f));
        mat.SetColor("_MoonColor", moonColor * (moonLight.enabled ? 1.0f : 0.0f));
        mat.SetFloat("_TimeOfDay", (timeOfDay % 24000.0f) / 24000.0f);
        mat.SetTexture("_ColorRamp", gradientMap);
    }

    [ContextMenu("重新设置天体")]
    private void SetupSun()
    {
        GameObject sun = new GameObject("Sun");
        sunLight = sun.AddComponent<Light>();
        sunLight.type = LightType.Directional;
        sun.transform.SetParent(this.transform);

        GameObject moon = new GameObject("Moon");
        moonLight = moon.AddComponent<Light>();
        moonLight.type = LightType.Directional;
        moon.transform.SetParent(this.transform);
    }


    private void Reset()
    {
        //COMPONENT...
        SetupSun();


    }
}
