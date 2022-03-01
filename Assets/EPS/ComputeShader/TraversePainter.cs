using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TraversePainter : MonoBehaviour
{
    [SerializeField] private Camera targetCamera;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        //raycast...
        if(Input.GetButtonDown("Fire1")){
            PaintAtPosition();
        }
    }

    void PaintAtPosition(){
        //cast a ray:
        Vector3 mousePos = Input.mousePosition;
        //Debug.Log(mousePos);
        Ray targetRay = targetCamera.ScreenPointToRay(mousePos);
    }

    [MenuItem("GameObject/Setup Paint Canvas")]
    static void BeginPaint(){

    }

}
