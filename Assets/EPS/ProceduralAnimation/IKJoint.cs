using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IKJoint : MonoBehaviour, IJointables, IJointTarget
{
    // Start is called before the first frame update
    [SerializeField] private float handLength;
    [SerializeField] private Transform ikTarget;

    public Color gizmoColor = Color.cyan;
    void OnDrawGizmosSelected()
    {
        Gizmos.color = gizmoColor;
        Gizmos.DrawLine(transform.position, transform.forward * handLength + transform.position);
        
    }

    // Update is called once per frame
    void Update()
    {
        //right now just sets the position towards the joint target.
        //transform.forward = ikTarget.position - GetJointBase();
        RotateTowards(ikTarget.position);
        
    }

    void RotateTowards(Vector3 targetPoint){
        Vector3 targetVector = targetPoint - GetJointBase();
        transform.forward = targetVector;
        targetVector = targetVector.normalized * -handLength;

        targetVector = targetVector + targetPoint;
        transform.position = targetVector;
        
    }

    public Vector3 GetJointBase(){
        return transform.position;
    }

    public Vector3 GetJointEnd(){
        return transform.position + transform.forward * handLength;
    }

    public Vector3 GetJointTarget(){
        return new Vector3(0, 0, 0);
        //return GetJointBase();
    }
}


public interface IJointables
{
    Vector3 GetJointBase();
    Vector3 GetJointEnd();
}

public interface IJointTarget
{
    Vector3 GetJointTarget();
}