using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPointScatter : MonoBehaviour
{
    [SerializeField] private float planeSize = 10;
    private int calculatedCount = 100;
    private int cacheCount = -1;
    [SerializeField] private int density = 5; //5 grass per unit

    List<Vector3> cachedGrassPos;
    private ComputeBuffer argsBuffer;

    [SerializeField] private Mesh grassMesh;
    [SerializeField] private Material instancedMaterial;

    // Start is called before the first frame update
    void Start()
    {
        RecalculateGrassCount();
    }

    // Update is called once per frame
    void LateUpdate()
    {
        RecalculateGrassCount();
        if (ScatterGrass())
            UpdateComputeBuffer();
        SendToComputeShader();
    }

    void RecalculateGrassCount()
    {
        calculatedCount = Mathf.CeilToInt(planeSize * planeSize * density);
    }

    bool ScatterGrass()
    {
        if (calculatedCount == cacheCount)
            return false;
        //create scatter:
        cachedGrassPos = new List<Vector3>();
        for (int i = 0; i < calculatedCount; i++)
        {
            Vector3 pos = Vector3.zero;

            pos.x = UnityEngine.Random.Range(-1f, 1f) * planeSize;
            pos.z = UnityEngine.Random.Range(-1f, 1f) * planeSize;

            //transform to posWS in C#
            pos += transform.position;
            cachedGrassPos.Add(new Vector3(pos.x, pos.y, pos.z));
            //Pass data to compute shader?
        }
        cacheCount = calculatedCount;
        return true;
    }

    void RecreateArgsBuffer()
    {
        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        if (argsBuffer != null)
        {
            argsBuffer.Release();
        }
        Mesh mesh = GetGrassMeshCache();
        args[0] = (uint)mesh.GetIndexCount(0);
        args[1] = (uint)calculatedCount;
        args[2] = (uint)mesh.GetIndexStart(0);
        args[3] = (uint)mesh.GetBaseVertex(0);

        //copy to argsbuffer:
        //                                                                     ///KEEP THIS!///
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
    }

    void RecreateDataBuffer()
    {
        //                                                                            Vector3 3x float
        ComputeBuffer meshPropertiesBuffer = new ComputeBuffer(cachedGrassPos.Count, sizeof(float) * 3);
        meshPropertiesBuffer.SetData(cachedGrassPos);
        instancedMaterial.SetBuffer("positionBuffer", meshPropertiesBuffer);
    }

    void UpdateComputeBuffer()
    {
        RecreateArgsBuffer();
        RecreateDataBuffer();

    }
    void SendToComputeShader()
    {
        /*
         * Do something in compute
         */

        //draw mesh instanced:
        Bounds renderBound = new Bounds();
        renderBound.SetMinMax(transform.position - new Vector3(planeSize, 0, planeSize), transform.position + new Vector3(planeSize, 0, planeSize));
        
        Graphics.DrawMeshInstancedIndirect(GetGrassMeshCache(), 0, instancedMaterial, renderBound, argsBuffer);
        //Graphics.DrawMeshInstancedProcedural(GetGrassMeshCache(), 0, instancedMaterial, renderBound, calculatedCount);
    }

    private Mesh cachedGrassMesh;

    //GENERATES GRASS MESH//
    Mesh GetGrassMeshCache()
    {
        if (!cachedGrassMesh)
        {
            //if not exist, create a 3 vertices hardcode triangle grass mesh
            cachedGrassMesh = new Mesh();

            //single grass (vertices)
            Vector3[] verts = new Vector3[4];
            verts[0] = new Vector3(-0.05f, 0);
            verts[1] = new Vector3(+0.05f, 0);
            verts[2] = new Vector3(-0.05f, 1);
            verts[3] = new Vector3(+0.05f, 1);
            //single grass (Triangle index)
            int[] trinagles = new int[6] { 2, 1, 0, 2, 3, 1 }; //order to fit Cull Back in grass shader
            Vector2[] uvs = new Vector2[4];
            uvs[0] = new Vector2(0, 0);
            uvs[1] = new Vector2(1, 0);
            uvs[2] = new Vector2(0, 1);
            uvs[3] = new Vector2(1, 1);

            //cachedGrassMesh.normals = 

            cachedGrassMesh.SetVertices(verts);
            cachedGrassMesh.SetTriangles(trinagles, 0);
            cachedGrassMesh.SetUVs(0, uvs);
        }

        return cachedGrassMesh;
    }

    void OnDisable()
    {
        if (argsBuffer != null)
            argsBuffer.Release();
        argsBuffer = null;
    }
}
