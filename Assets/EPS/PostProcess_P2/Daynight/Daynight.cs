using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(DaynightRenderer), PostProcessEvent.AfterStack, "Custom/Daynight")]
public sealed class Daynight : PostProcessEffectSettings
{
    //Settings Here.

    [Range(0, 1)]public FloatParameter timeOfDay = new FloatParameter { value = 0.5f };
    [Range(0, 4)]public FloatParameter daylightContribution = new FloatParameter { value = 0.5f };
    public Vector3Parameter levels = new Vector3Parameter { value = new Vector3(0.0f, 0.5f, 1.0f) };
    public ColorParameter shadowColor = new ColorParameter { value = new Color(0.5f, 0.5f, 0.5f, 0.5f) };
    public ColorParameter brightColor = new ColorParameter { value = new Color(0.5f, 0.5f, 0.5f, 0.5f) };
}


public sealed class DaynightRenderer : PostProcessEffectRenderer<Daynight>
{
    private RenderTexture previousFrameResult;
    public override void Render(PostProcessRenderContext context)
    {   
        var cmd = context.command;
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/Daynight"));
        //cmd.BeginSample("VHSEffect");
        sheet.properties.SetFloat("_TimeOfDay", settings.timeOfDay);
        sheet.properties.SetFloat("_DaylightContribution", settings.daylightContribution);
        sheet.properties.SetVector("_ShadowColor", settings.shadowColor);
        sheet.properties.SetVector("_LightColor", settings.brightColor);
        sheet.properties.SetVector("_Levels", settings.levels);

        cmd.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
