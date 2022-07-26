using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(ExponentialHeightFogRenderer), PostProcessEvent.AfterStack, "Custom/Exponential Height Fog")]
public sealed class ExponentialHeightFog : PostProcessEffectSettings
{
    //Settings Here.

    public FloatParameter fogStartHeight = new FloatParameter { value = 0.0f };
    public FloatParameter fogGradient = new FloatParameter { value = 2.0f };
    public ColorParameter fogColor = new ColorParameter { value = new Color(0.5f, 0.5f, 0.5f) };
}


public sealed class ExponentialHeightFogRenderer : PostProcessEffectRenderer<ExponentialHeightFog>
{
    public override void Render(PostProcessRenderContext context)
    {
        var cmd = context.command;
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/ExponentialHeightFog"));
        


        cmd.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
