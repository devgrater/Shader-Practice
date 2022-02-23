using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IKHandSystem : MonoBehaviour
{
    [System.Serializable]
    public struct handSegment{
        [SerializeField] int handLength;
        [SerializeField] bool isConstrained;
        //If this value is assigned, use this prefab instead of the default prefab.
        [SerializeField] GameObject specialPrefab; 
    }
    [Header("Hand Info")]
    [Tooltip("The default prefab to instantiate when generated.")]
    [SerializeField] private GameObject defaultPrefab;

    // Start is called before the first frame update
    [SerializeField] public handSegment[] segmentDetails;
    private List<IKHandInfo> instantiatedIKs;


    void InitializeIKSystem(){
        for(int i = 0; i < segmentDetails.Length; i++){

        }
    }

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}

public sealed class IKHandInfo : IJointables
{
    private Vector3 basePosition;
    private Vector3 forwardDirection;
    private float length;
    private GameObject bindedRenderObject;
    public IKHandInfo(float length, GameObject bindedObject){
        this.length = length;
        this.bindedRenderObject = bindedObject;
    }

    void RotateTowards(Vector3 targetPoint){
        Vector3 targetVector = targetPoint - GetJointBase();
        forwardDirection = targetVector;
        targetVector = targetVector.normalized * -length;

        targetVector = targetVector + targetPoint;
        basePosition = targetVector;
        
    }

    public Vector3 GetJointBase(){
        return basePosition;
    }

    public Vector3 GetJointEnd(){
        return basePosition + forwardDirection * length;
    }

}
