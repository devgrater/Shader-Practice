using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoRotate : MonoBehaviour
{
    // Start is called before the first frame update
    Vector3 rotation = new Vector3();
    [SerializeField]Vector3 preserve;
    [SerializeField]float speed = 15;
    void Start()
    {
        preserve.x = transform.eulerAngles.x * preserve.x;
        preserve.y = transform.eulerAngles.y * preserve.y;
        preserve.z = transform.eulerAngles.z * preserve.z;
    }

    // Update is called once per frame
    void Update()
    {
        rotation.y += Time.deltaTime * speed;
        transform.eulerAngles = preserve + rotation;
    }
}
