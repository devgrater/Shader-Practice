using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    float _pitch, _yaw = 0.0f;
    public float speed = 5.3f;
    public float sprintMultiplier = 1.5f;

    bool assumingControl = true;

    // Start is called before the first frame update
    void Start()
    {
        setLockMode(true);
    }

    // Update is called once per frame
    void Update()
    {   
        if(assumingControl){
            _pitch += Input.GetAxisRaw("Mouse X");
            _yaw -= Input.GetAxisRaw("Mouse Y");
            
            transform.eulerAngles = new Vector3(_yaw, _pitch, 0.0f);
            float actualSpeed = Input.GetButton("Fire3")? speed * sprintMultiplier : speed;
            
            transform.position += transform.forward * Input.GetAxisRaw("Vertical") * actualSpeed * Time.deltaTime;
            transform.position += transform.right * Input.GetAxisRaw("Horizontal") * actualSpeed * Time.deltaTime;
            transform.position += transform.up * Input.GetAxisRaw("RealVertical") * actualSpeed * Time.deltaTime;
        }


        if(Input.GetKeyDown(KeyCode.Escape)){
            assumingControl = !assumingControl;
            setLockMode(assumingControl);
        }
    }
    //True: Locked, False: Unlocked
    void setLockMode(bool lockMode){
        Cursor.visible = !lockMode;
        Cursor.lockState = lockMode? CursorLockMode.Confined : CursorLockMode.None;
    }
}
