using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeFlocker : MonoBehaviour
{

    struct BoidData{
        public Vector3 position;
        public Vector3 velocity;
        public Vector4 individualData;
    };

    [SerializeField] int numFish = 8192; //this should be more than enough?
    [SerializeField] ComputeShader computeShader;
    [SerializeField] Mesh mesh;
    [SerializeField] Material material;

    [Header("Boid Simulation Settings")]
    [SerializeField] float maxSpeed = 0.3f;
    [SerializeField] float separationRange = 0.6f;
    [SerializeField] float separationWeight = 1.0f;
    [SerializeField] float cohesionRange = 1.0f;
    [SerializeField] float cohesionWeight = 1.0f;
    [SerializeField] float alignmentRange = 1.0f;
    [SerializeField] float alignmentWeight = 1.0f;
    [SerializeField] float sdfWeight = 1.0f;
    [SerializeField] Texture2D fishSDF;
    //[SerializeField] 


    ComputeBuffer boidBuffer;
    ComputeBuffer outputDataBuffer;

    //public RenderTexture rt;
    // Start is called before the first frame update
    void OnEnable()
    {
        //                                                  float3 position, float3 vector, float4 individualData
        boidBuffer = new ComputeBuffer(numFish, sizeof(float) * 3 * 2 + sizeof(float) * 4);
        //                                                            float3 position
        outputDataBuffer = new ComputeBuffer(numFish, sizeof(float) * 3 * 3);
        InitializeBoids();
    }

    void UpdateFunctionOnGPU(){
        //draw stuff
        computeShader.SetBuffer(0, "_Boids", boidBuffer);
        computeShader.SetBuffer(0, "_Output", outputDataBuffer);
        computeShader.SetFloat("_TimeStep", Time.deltaTime);

        ///////////////////////  Boid Settings /////////////////////////////
        computeShader.SetFloat("_MaxSpeed", maxSpeed);
        //set separation properties to shader
        //thanks, copilot for writing out the rest 5 lines for me
        /*
        computeShader.SetFloat("_SeparationRange", separationRange);
        computeShader.SetFloat("_SeparationWeight", separationWeight);
        computeShader.SetFloat("_CohesionRange", cohesionRange);
        computeShader.SetFloat("_CohesionWeight", cohesionWeight);
        computeShader.SetFloat("_AlignmentRange", alignmentRange);
        computeShader.SetFloat("_AlignmentWeight", alignmentWeight);*/
        computeShader.SetVector("_SACWeight", new Vector4(separationWeight, alignmentWeight, cohesionWeight));
        computeShader.SetVector("_SACRange", new Vector4(separationRange, alignmentRange, cohesionRange));
        computeShader.SetTexture(0, "_SDF", fishSDF);
        computeShader.SetFloat("_SDFWeight", sdfWeight);

        //send the minimum and maximum bounds of the simulation
        Vector3 boxMin = transform.position - transform.localScale / 2;
        Vector3 boxMax = transform.position + transform.localScale / 2;
        computeShader.SetVector("_BoxMin", new Vector4(boxMin.x, boxMin.y, boxMin.z, 0.0f));
        computeShader.SetVector("_BoxMax", new Vector4(boxMax.x, boxMax.y, boxMax.z, 0.0f));

        

        int groups = Mathf.CeilToInt(numFish / 64f);
        computeShader.Dispatch(0, groups, 1, 1);

        material.SetBuffer("_Boids", outputDataBuffer);
        var bounds = new Bounds(Vector3.zero, Vector3.one * 256);
        Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, numFish);
    }

    void OnDisable(){
        boidBuffer.Release();
        boidBuffer = null;

        outputDataBuffer.Release();
        outputDataBuffer = null;
    }

    // Update is called once per frame
    void Update()
    {
        UpdateFunctionOnGPU();
    }

    void InitializeBoids(){
        BoidData[] initValue = new BoidData[numFish];
        for(int i = 0; i < numFish; i++){
            initValue[i].individualData = new Vector3(Random.Range(1, 5), Random.Range(0.2f, 0.7f), Random.Range(0.0f, 1.0f));
            initValue[i].position = Random.insideUnitSphere * 3f;
            initValue[i].velocity = Random.onUnitSphere * maxSpeed;
        }
        boidBuffer.SetData(initValue);
        //boidBuffer.SetCounterValue()
    }

    void OnDrawGizmosSelected(){
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube(transform.position, transform.localScale);
    }
}
