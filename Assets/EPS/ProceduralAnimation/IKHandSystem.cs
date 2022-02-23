using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IKHandSystem : MonoBehaviour
{
    [System.Serializable]
    public struct HandSegment{
        [SerializeField] public int handLength;
        [SerializeField] public bool isConstrained;
        //If this value is assigned, use this prefab instead of the default prefab.
        [SerializeField] public GameObject specialPrefab; 
    }
    [Header("Hand Info")]
    [Tooltip("The default prefab to instantiate when generated.")]
    [SerializeField] private GameObject defaultPrefab;

    // Start is called before the first frame update
    [SerializeField] private HandSegment[] segmentDetails;
    [SerializeField] private Transform targetTransform;
    private List<IKHandInfo> instantiatedIKs;


    void InitializeIKSystem(){
        //IKHandInfo previous = null;
        instantiatedIKs = new List<IKHandInfo>();
        for(int i = 0; i < segmentDetails.Length; i++){
            //create new ik game object

            HandSegment segment = segmentDetails[i];
            IKHandInfo handInfo = new IKHandInfo(segment.handLength);//worry about this later
            ///previous = handInfo;
            GameObject instantiated;
            if(segment.specialPrefab){
                instantiated = Instantiate(segment.specialPrefab);
            }
            else{
                instantiated = Instantiate(defaultPrefab);
            }
            handInfo.SetGameObject(instantiated);
            instantiatedIKs.Add(handInfo);
        }
    }

    void Start()
    {  
        InitializeIKSystem();
    }

    // Update is called once per frame
    void Update()
    {
        //for each of the hands...
        //target towards the next joint.
        if(instantiatedIKs.Count <= 0) return;
        Debug.Log(instantiatedIKs.Count);
        Vector3 previousHead = new Vector3(0, 0, 0);
        int i;
        for(i = instantiatedIKs.Count - 1; i >= 0; i--){
            IKHandInfo currentSegment = instantiatedIKs[i];
            if(i == instantiatedIKs.Count - 1){
                //this is the last segment in the hand system
                currentSegment.RotateTowards(targetTransform.position);
            }
            else{
                currentSegment.RotateTowards(previousHead);
            }
            previousHead = currentSegment.GetJointBase();
        }
        //Once everything is done,
        //we backwards propagate everything back to the origin.
        Vector3 backwardsPropagateVector = instantiatedIKs[0].GetJointBase() - transform.position;
        //Debug.Log(backwardsPropagateVector);
        for(i = 0; i < instantiatedIKs.Count; i++){
            IKHandInfo currentSegment = instantiatedIKs[i];
            currentSegment.ApplyConstraintOffset(backwardsPropagateVector);
            currentSegment.UpdateGameObject();
        }
    }


}

public sealed class IKHandInfo : IJointables
{
    private Vector3 basePosition;
    private Vector3 forwardDirection;
    private float length;
    private GameObject bindedRenderObject;
    public IKHandInfo(float length){
        this.length = length;
        //this.bindedRenderObject = bindedObject;
    }

    public IKHandInfo(IKHandSystem.HandSegment segment){
        this.length = segment.handLength;
        //this.bindedRenderObject = GameObject.Instantiate()
    }

    public void SetGameObject(GameObject instantiated){
        this.bindedRenderObject = instantiated;
    }

    public void UpdateGameObject(){
        if(bindedRenderObject){
            bindedRenderObject.transform.position = basePosition;
            bindedRenderObject.transform.forward = forwardDirection;
        }
    }

    public void RotateTowards(Vector3 targetPoint){
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

    public void ApplyConstraintOffset(Vector3 offset){
        basePosition -= offset;
    }

}
