using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthReconstruct : MonoBehaviour
{
    [SerializeField] private Material postProcess;
    private Camera camera;

    private Transform m_cameraTransform;
    public Transform p_cameraTransform {
        get {
            if(m_cameraTransform == null){
                m_cameraTransform = transform;
            }
            return m_cameraTransform;
        }
    }

    void Awake(){
        camera = GetComponent<Camera>();
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(postProcess != null){
            float near = camera.nearClipPlane;
            float far = camera.farClipPlane;
            float fov = camera.fieldOfView;
            float aspect = camera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * aspect);
            //should compute a ray...

            //using this, we can compute screen width....
            float screenHalfWidth = halfHeight * aspect;
            Vector3 forwardDir = transform.forward * near;
            Vector3 upDir = transform.up * halfHeight;
            Vector3 rightDir = transform.right * screenHalfWidth;
            Vector3 rayCoordsTL = forwardDir + upDir + rightDir;
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
            //postProcess.SetFloat("_Near", camera.nearClipPlane);
            //postProcess.SetFloat("_Far", camera.farClipPlane);
            postProcess.SetMatrix("_FrustumCornersRay", frustumCorners);//and then just let the vertex shader interpolate
            Graphics.Blit(src, dest, postProcess);
        }
        else{
            Graphics.Blit(src, dest);
        }
    }
}
