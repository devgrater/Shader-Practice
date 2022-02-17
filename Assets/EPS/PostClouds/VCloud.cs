using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(VCloudRenderer), PostProcessEvent.AfterStack, "Custom/Volumetric Clouds")]
public class VCloud : PostProcessEffectSettings
{
    //add in settings here...
    //and with default values, hopefully
    public Shader shader;
    
}

public sealed class VCloudRenderer : PostProcessEffectRenderer<VCloud>
{
    public override void Render(PostProcessRenderContext context)
    {   
        /*
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/PostProcessVC")); //put in your shader code here..
        Matrix4x4 viewMat = context.camera.worldToCameraMatrix;
        Matrix4x4 projMat = GL.GetGPUProjectionMatrix(context.camera.projectionMatrix, false);
        Matrix4x4 viewProjMat = (projMat * viewMat);
        sheet.properties.SetMatrix("_ViewProjInv", viewProjMat.inverse);
        /*
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(context.camera.projectionMatrix, false);
        sheet.properties.SetMatrix(Shader.PropertyToID("_InverseProjectionMatrix"), projectionMatrix.inverse);
        sheet.properties.SetMatrix(Shader.PropertyToID("_InverseViewMatrix"), context.camera.cameraToWorldMatrix);
        
        //reconstruct world coordinates:
        sheet.properties.SetVector(Shader.PropertyToID("_VolumeMin"), new Vector4(0, 0, 0, 0));
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);*/

        
        //throw new System.NotImplementedException();
    }
}
