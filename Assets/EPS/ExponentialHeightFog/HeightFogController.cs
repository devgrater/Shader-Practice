using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class HeightFogController : MonoBehaviour
{
    [SerializeField] private Material postProcess;
    [SerializeField] private SkyboxController skybox;
    [SerializeField] private float heightFalloff = 20.0f;
    [SerializeField] private float depthFalloff = 0.000003f;
    [SerializeField] private float density = 0.01f;
    [SerializeField] private float fogStartY = 0.0f;
    [SerializeField] private float fogStartZ = 0.0f;
    public Gradient fogGradient = new Gradient();
    private Texture2D gradientMap;
    private Camera targetCamera;

    private Transform m_targetCameraTransform;
    public Transform p_targetCameraTransform {
        get {
            if(m_targetCameraTransform == null){
                m_targetCameraTransform = transform;
            }
            return m_targetCameraTransform;
        }
    }

    void Awake(){
        targetCamera = GetComponent<Camera>();
        RecomputeGradientMap();
    }

    void RecomputeGradientMap()
    {
        //no mip
        gradientMap = new Texture2D(512, 1, TextureFormat.ARGB32, false);
        for (int i = 0; i < 512; i++)
        {
            gradientMap.SetPixel(i, 0, fogGradient.Evaluate(i / 512.0f));
        }
        gradientMap.Apply();
        gradientMap.filterMode = FilterMode.Bilinear;
        gradientMap.wrapMode = TextureWrapMode.Clamp;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if (!Application.isPlaying)
        {
            // The script is executing inside the editor
            RecomputeGradientMap();
        }
        if (postProcess != null && skybox){
            postProcess.SetTexture("_ColorRamp", skybox.GetColorRamp());
            postProcess.SetFloat("_TimeOfDay", skybox.GetTimeOfDay());
            postProcess.SetFloat("_Density", density);
            Vector4 fogDataBundle = new Vector4(depthFalloff, heightFalloff, fogStartY, fogStartZ);
            postProcess.SetVector("_Control", fogDataBundle);
            postProcess.SetTexture("_FogRamp", gradientMap);
            //have skb pass over some data:
            /*
            float near = targetCamera.nearClipPlane;
            float far = targetCamera.farClipPlane;
            float fov = targetCamera.fieldOfView;
            float aspect = targetCamera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            //should compute a ray...

            //using this, we can compute screen width....
            float screenHalfWidth = halfHeight * aspect;
            Vector3 forwardDir = transform.forward * near;
            Vector3 upDir = transform.up * halfHeight;
            Vector3 rightDir = transform.right * screenHalfWidth;
            Vector3 rayCoordsTL = forwardDir + upDir - rightDir;
            float scale = rayCoordsTL.magnitude / near;
            rayCoordsTL = rayCoordsTL.normalized * scale;
            
            Vector3 rayCoordsBR = (forwardDir - upDir + rightDir).normalized * scale;
            Vector3 rayCoordsBL = (forwardDir - upDir - rightDir).normalized * scale;
            Vector3 rayCoordsTR = (forwardDir + upDir + rightDir).normalized * scale;

            Matrix4x4 frustumCorners = Matrix4x4.identity;
            frustumCorners.SetRow(0, rayCoordsBL);
            frustumCorners.SetRow(1, rayCoordsBR);
            frustumCorners.SetRow(2, rayCoordsTR);
            frustumCorners.SetRow(3, rayCoordsTL);
            //postProcess.SetFloat("_Near", targetCamera.nearClipPlane);
            //postProcess.SetFloat("_Far", targetCamera.farClipPlane);
            postProcess.SetMatrix("_FrustumCornersRay", frustumCorners);//and then just let the vertex shader interpolate
            postProcess.SetColor("_FogColor", fogColor);
            postProcess.SetFloat("_FogDensity", fogDensity);
            postProcess.SetFloat("_FogStart", fogStart);
            postProcess.SetFloat("_FogEnd", fogEnd);*/
            Graphics.Blit(src, dest, postProcess);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
