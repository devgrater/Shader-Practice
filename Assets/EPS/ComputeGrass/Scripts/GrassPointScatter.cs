using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassPointScatter : MonoBehaviour
{
    [SerializeField] private float planeSize = 10;
    private int calculatedCount = 100;
    private int cacheCount = -1;
    [SerializeField] private int density = 5; //5 grass per unit

    List<Vector3> cachedGrassPos;
    List<Vector3>[] cellPosWSsList;
    private ComputeBuffer argsBuffer;
    private ComputeBuffer meshPropertiesBuffer;

    [SerializeField] private Mesh grassMesh;
    [SerializeField] private Material instancedMaterial;
    [SerializeField] private Texture grassInfluenceRT;
    [SerializeField] private Camera grassRTCamera;
    //block size: 1m per block.
    [SerializeField] private float blockSize = 2;

    [SerializeField] private ComputeShader compute;


    private int cellCountX;
    private int cellCountZ;

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
        calculatedCount = Mathf.CeilToInt(planeSize * planeSize * Mathf.Max(density, 1.0f));
    }

    bool ScatterGrass()
    {
        if (calculatedCount == cacheCount)
            return false;
        //how many blocks are there?

        //in the original example, he had to calculate the min and max bound.
        //but we know the min and max bounds already, so we can calculate directly.
        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        cellCountX = Mathf.CeilToInt((maxX - minX) / 4);
        cellCountZ = Mathf.CeilToInt((maxZ - minZ) / 4);

        cellPosWSsList = new List<Vector3>[cellCountX * cellCountZ]; //flatten 2D array
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            cellPosWSsList[i] = new List<Vector3>();
        }

        //create scatter:
        cachedGrassPos = new List<Vector3>();
        for (int i = 0; i < calculatedCount; i++)
        {
            Vector3 pos = Vector3.zero;

            pos.x = UnityEngine.Random.Range(-1f, 1f) * planeSize;
            pos.z = UnityEngine.Random.Range(-1f, 1f) * planeSize;

            int xID = Mathf.Min(cellCountX - 1, Mathf.FloorToInt(Mathf.InverseLerp(minX, maxX, pos.x) * cellCountX)); //use min to force within 0~[cellCountX-1]  
            int zID = Mathf.Min(cellCountZ - 1, Mathf.FloorToInt(Mathf.InverseLerp(minZ, maxZ, pos.z) * cellCountZ)); //use min to force within 0~[cellCountZ-1]

            pos += transform.position;
            cachedGrassPos.Add(new Vector3(pos.x, pos.y, pos.z));
            cellPosWSsList[xID + zID * cellCountX].Add(pos);
        }

        //for the compute buffer...
        int offset = 0;
        Vector3[] allGrassPosWSSortedByCell = new Vector3[cachedGrassPos.Count];
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            for (int j = 0; j < cellPosWSsList[i].Count; j++)
            {
                allGrassPosWSSortedByCell[offset] = cellPosWSsList[i][j];
                offset++;
            }
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
        if (meshPropertiesBuffer != null)
        {
            meshPropertiesBuffer.Release();
        }
        //                                                              Vector4 4x float - xyz - positions, w - height
        meshPropertiesBuffer = new ComputeBuffer(cachedGrassPos.Count, sizeof(float) * 3);
        meshPropertiesBuffer.SetData(cachedGrassPos);
        instancedMaterial.SetBuffer("_PositionBuffer", meshPropertiesBuffer);
        //instancedMaterial.SetBuffer("VisibleIDBuffer", ...);
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
        instancedMaterial.SetTexture("_GrassInfluence", grassInfluenceRT);
        Vector3 cameraBounds = grassRTCamera.transform.position;
        float minX, maxX, minZ, maxZ;
        GetCameraBounds(out minX, out maxX, out minZ, out maxZ);
        float camSize = grassRTCamera.orthographicSize;
        instancedMaterial.SetVector("_InfluenceBounds", 
            new Vector4(minX, maxX, minZ, maxZ)
        );

        

        Graphics.DrawMeshInstancedIndirect(GetGrassMeshCache(), 0, instancedMaterial, renderBound, argsBuffer);
        
        //Graphics.DrawMeshInstancedProcedural(GetGrassMeshCache(), 0, instancedMaterial, renderBound, calculatedCount);
    }

    private Mesh cachedGrassMesh;

    //GENERATES GRASS MESH//
    Mesh GetGrassMeshCache()
    {
        if (!cachedGrassMesh && !grassMesh)
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

        return grassMesh ? grassMesh : cachedGrassMesh;
    }

    void OnDisable()
    {
        if (argsBuffer != null)
            argsBuffer.Release();
        argsBuffer = null;

        if (meshPropertiesBuffer != null)
            meshPropertiesBuffer.Release();
        meshPropertiesBuffer = null;
    }

    private void GetCameraBounds(out float minX, out float maxX, out float minZ, out float maxZ)
    {
        float camSize = grassRTCamera.orthographicSize;
        Vector3 cameraBounds = grassRTCamera.transform.position;
        minX = cameraBounds.x - camSize;
        maxX = cameraBounds.x + camSize;
        minZ = cameraBounds.z - camSize;
        maxZ = cameraBounds.z + camSize;
    }

    private void GetGrassBounds(out float minX, out float maxX, out float minZ, out float maxZ)
    {
        float boundSize = planeSize;
        Vector3 origin = grassRTCamera.transform.position;
        minX = origin.x - boundSize;
        maxX = origin.x + boundSize;
        minZ = origin.z - boundSize;
        maxZ = origin.z + boundSize;
    }

}
