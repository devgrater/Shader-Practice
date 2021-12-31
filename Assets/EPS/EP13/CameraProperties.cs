using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraProperties : MonoBehaviour
{
    // Start is called before the first frame update
    private Camera camera;
    void Start()
    {
        camera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        //convert camera space coords to world space coords...
        
    }
}
