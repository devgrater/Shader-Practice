using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(VHSRenderer), PostProcessEvent.AfterStack, "Custom/VHS Effect")]
public sealed class VHS : PostProcessEffectSettings
{
    //Settings Here.
    
    public BoolParameter useScreenResolution = new BoolParameter { value = true };
    public IntParameter scanlineCount = new IntParameter { value = 720 };
    
    
    public IntParameter screenWidth = new IntParameter { value = 480 };
    //that means, 100/480 uv offset
    public IntParameter chromaAberrationDistance = new IntParameter { value = 1 };
    
}


public sealed class VHSRenderer : PostProcessEffectRenderer<VHS>
{
    private RenderTexture previousFrameResult;
    public override void Render(PostProcessRenderContext context)
    {   
        var cmd = context.command;
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/VHS Effect"));
        //cmd.BeginSample("VHSEffect");

        //var sheet = context.propertySheets.Get("Hidden/PostProcessing/PostProcessVC");
        if(settings.useScreenResolution){
            //settings.
            sheet.properties.SetFloat("_ScanlineCount", context.height);
            sheet.properties.SetFloat("_ChromaAberrationDistance", settings.chromaAberrationDistance / ((float)context.width));
        }
        else{
            sheet.properties.SetFloat("_ScanlineCount", settings.scanlineCount);
            sheet.properties.SetFloat("_ChromaAberrationDistance", settings.chromaAberrationDistance / ((float)settings.screenWidth));
        }
        
        if(previousFrameResult != null){
            //interleave these two
            //test if the dimensions are the same, but only after this frame ends.
            //pass the previous frame info to the shader.
            sheet.properties.SetTexture("_PreviousFrame", previousFrameResult);


            if(previousFrameResult.width == context.width && previousFrameResult.height == context.height){
                //do nothing.
            }
            else{
                previousFrameResult.Release();
                previousFrameResult = new RenderTexture(context.width, context.height, 0);
            }
            
        }
        else{
            previousFrameResult = new RenderTexture(context.width, context.height, 0);
        }
        //pass this onto the 


        cmd.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
        cmd.Blit(context.source, previousFrameResult);
        //blit the result to a buffer
        
        //cmd.EndSample("VHSEffect");
        //context.command.EndSample();
    }
}
