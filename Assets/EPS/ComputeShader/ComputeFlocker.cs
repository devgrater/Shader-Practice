using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeFlocker : MonoBehaviour
{

    [SerializeField, Range(10, 200)] int resolution = 32;
    [SerializeField] int numFish = 1024; //this should be more than enough?
    [SerializeField] ComputeShader computeShader;
    [SerializeField] Mesh mesh;
    [SerializeField] Material material;
    ComputeBuffer buffer;
    //public RenderTexture rt;
    // Start is called before the first frame update
    void OnEnable()
    {
        //                                                  float3 position, float3 vector
        buffer = new ComputeBuffer(32 * 32, 4 * 3 * 2);
        /*
        rt = new RenderTexture(256, 256, 24);
        rt.enableRandomWrite = true;
        rt.Create();
        computeShader.SetTexture(0, "Result", rt);
        //                         v how many 8x8 groups gets calculated*/


        computeShader.SetBuffer(0, "_Boids", buffer);
        computeShader.SetInt("_Resolution", resolution);
        int groups = Mathf.CeilToInt(resolution / 8f);
        computeShader.Dispatch(0, groups, groups, 1);
        //right now nothing updates, but thats fine.
    }

    void UpdateFunctionOnGPU(){
        //draw stuff
        material.SetBuffer("_Boids", buffer);
        
        var bounds = new Bounds(Vector3.zero, Vector3.one * 256);
        Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, buffer.count);
    }

    void OnDisable(){
        buffer.Release();
        buffer = null;
    }

    // Update is called once per frame
    void Update()
    {
        UpdateFunctionOnGPU();
    }
}
