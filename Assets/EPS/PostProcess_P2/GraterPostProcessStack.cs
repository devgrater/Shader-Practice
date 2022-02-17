using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class GraterPostProcessStack : MonoBehaviour
{
    [SerializeField] private List<GraterPostProcessLayer> postProcess;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    
    void OnRenderImage(RenderTexture src, RenderTexture dest){

        if(postProcess.Count == 0){
            //if there is no post process at all, just do whatever you do before.
            Graphics.Blit(src, dest);
        }
        else if(postProcess.Count == 1){
            postProcess[0].OnRenderImage(src, dest);
        }
        else{
            //well, we need a few buffers to swap between.
            RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height);
            RenderTexture temp2 = RenderTexture.GetTemporary(src.width, src.height);
            bool isTempLastUsedRT = false;
            for(int i = 0; i < postProcess.Count; i++){
                GraterPostProcessLayer gppl = postProcess[i];
                if(isTempLastUsedRT){
                    isTempLastUsedRT = false;

                }
                else{
                    if(i == 1){

                    }
                    isTempLastUsedRT = true;
                
                }
            }
        }
        /*
        bool isTempLastUsedRT = false;
        for(int i = 1; i < postProcess.Count; i++){
            if(isTempLastUsedRT){
                isTempLastUsedRT = false;

            }
            else{
                isTempLastUsedRT = true;
                gppl.OnRenderImage()
            }
        }*/
    }
}
