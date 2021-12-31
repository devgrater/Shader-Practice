using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LazyMove : MonoBehaviour
{

    [SerializeField] private float movementSpeed = 10;
    private Vector3 euler = new Vector3();
    private Vector3 inputAxis = new Vector3();
    private bool mouseLocked = false;
    void Start()
    {

        //SetMouseLocked(true);
        euler = transform.eulerAngles;
    }

    // Update is called once per frame
    void Update()
    {
        //pitch and yaw:
        if(mouseLocked){
            euler.y += Input.GetAxisRaw("Mouse X");
            euler.x -= Input.GetAxisRaw("Mouse Y");
            transform.eulerAngles = euler;
        }
        CheckMouseLockedState();
        CheckMovementInput();
    }

    void CheckMovementInput(){
        inputAxis.x = Input.GetAxisRaw("Horizontal");
        inputAxis.y = Input.GetAxisRaw("Vertical");
        inputAxis.z = Input.GetAxisRaw("Zenith");
        inputAxis = inputAxis.normalized;

        //move...
        Vector3 moveDirection = 
            transform.forward * inputAxis.y + 
            transform.right * inputAxis.x   +
            transform.up * inputAxis.z;
        transform.position += moveDirection * movementSpeed * Time.deltaTime;
    }

    void CheckMouseLockedState(){
        if(Input.GetButtonDown("Cancel")){
            //well, unlock mouse
            SetMouseLocked(false);
        }
        else if(Input.GetButtonDown("Fire1")){
            //lock mouse
            SetMouseLocked(true);
        }
    }

    void SetMouseLocked(bool locked){
        Cursor.visible = locked;
        Cursor.lockState = locked? CursorLockMode.Locked : CursorLockMode.None;
        mouseLocked = locked;
    }
}
