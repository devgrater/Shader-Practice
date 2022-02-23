using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IKTarget : MonoBehaviour, IJointTarget
{
    // Start is called before the first frame update
    public Vector3 GetJointTarget(){
        return transform.position;
    }
}
