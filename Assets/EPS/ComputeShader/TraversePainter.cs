using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TraversePainter : MonoBehaviour
{
    [SerializeField] private Camera targetCamera;
    [SerializeField] private Collider targetCollider;
    [SerializeField] private GameObject targetQuad;
    [SerializeField] private GameObject paintBrushHead;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        //raycast...
        //if(Input.GetButtonDown("Fire1")){
        PaintAtPosition();
        //}
    }

    void PaintAtPosition(){
        //cast a ray:
        Vector3 mousePos = Input.mousePosition;
        //Debug.Log(mousePos);
        Ray targetRay = targetCamera.ScreenPointToRay(mousePos);
        //shoot the ray!
        RaycastHit hitResult;
        if(Physics.Raycast(targetRay, out hitResult, 9999.0f)){
            if(hitResult.collider == GetComponent<Collider>()){
                //execute next step:
                Vector2 hitUV = hitResult.textureCoord;
                SetBrushHeadPos(hitUV);
            }
        }
    }

    void SetBrushHeadPos(Vector2 uv){
        if(paintBrushHead){
            uv.x = (uv.x - 0.5f);
            uv.y = (uv.y - 0.5f);
            //set the position relative... to the camera.
            Vector3 headPos = paintBrushHead.transform.position;
            if(targetQuad != null){
                float size = targetQuad.transform.localScale.x;
                Vector3 camPos = targetQuad.transform.position;
                //use the xy coordinates of this one.
                Vector3 brushPos = new Vector3(camPos.x, camPos.y, headPos.z);
                brushPos.x += uv.x * size;
                brushPos.y += uv.y * size;
                paintBrushHead.transform.position = brushPos;
            }
        }
    }


    void SaveRT(){

    }
    /*
    [MenuItem("GameObject/Setup Paint Canvas")]
    static void BeginPaint(){

    }*/

}
