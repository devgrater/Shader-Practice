using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoRotate : MonoBehaviour
{
    // Start is called before the first frame update
    Vector3 rotation = new Vector3();
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        rotation.y += Time.deltaTime * 40;
        transform.eulerAngles = rotation;
    }
}
