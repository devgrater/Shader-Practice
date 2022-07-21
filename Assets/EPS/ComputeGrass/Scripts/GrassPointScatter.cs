using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassPointScatter : MonoBehaviour
{
    [SerializeField] private float planeSizeX = 10;
    [SerializeField] private float planeSizeZ = 10;
    private int calculatedCount = 100;
    private int cacheCount = -1;
    [SerializeField] private int density = 5; //5 grass per unit

    List<Vector3> allGrassPos;
    List<Vector3>[] cellPosWSsList;
    private ComputeBuffer argsBuffer;
    private ComputeBuffer allInstancesPosWSBuffer;
    private ComputeBuffer visibleInstancesOnlyPosWSIDBuffer;

    [SerializeField] private Mesh grassMesh;
    private Mesh cachedGrassMesh;
    [SerializeField] private Material instancedMaterial;
    [SerializeField] private Texture grassInfluenceRT;
    [SerializeField] private Camera grassRTCamera;
    //block size: 1m per block.
    [SerializeField] private float blockSize = 4;
    [SerializeField] private ComputeShader compute;

    [SerializeField] private Camera playerCamera;
    private Plane[] cameraFrustumPlanes = new Plane[6];
    private List<int> visibleCellIDList = new List<int>();

    [SerializeField] private GameObject meshToMatch;



    private int cellCountX;
    private int cellCountZ;
    private Vector3 origin;

    // Start is called before the first frame update
    void OnEnable()
    {
        //RecalculateGrassCount();
        //if (ScatterGrass())
        //    UpdateAllBuffers();
        if (meshToMatch)
        {
            //do something with the mesh...
            Renderer meshRenderer = meshToMatch.GetComponent<Renderer>();
            Bounds b = meshRenderer.bounds;
            origin = b.center;
            origin.y = b.max.y;
            planeSizeX = b.extents.x;
            planeSizeZ = b.extents.z;
        }
        else
        {
            origin = transform.position;
        }
    }

    // Update is called once per frame
    void LateUpdate()
    {
        RecalculateGrassCount();
        if (ScatterGrass())
            UpdateAllBuffers();
        CullWithCompute();
        BatchRenderGrass();
    }

    void OnDisable()
    {
        if (argsBuffer != null)
            argsBuffer.Release();
        argsBuffer = null;

        if (allInstancesPosWSBuffer != null)
            allInstancesPosWSBuffer.Release();
        allInstancesPosWSBuffer = null;

        if (visibleInstancesOnlyPosWSIDBuffer != null)
            visibleInstancesOnlyPosWSIDBuffer.Release();
        visibleInstancesOnlyPosWSIDBuffer = null;
     }

    void RecalculateGrassCount()
    {
        calculatedCount = Mathf.CeilToInt(planeSizeX * planeSizeZ * Mathf.Max(density, 1.0f));
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
        cellCountX = Mathf.CeilToInt((maxX - minX) / blockSize);
        cellCountZ = Mathf.CeilToInt((maxZ - minZ) / blockSize);

        cellPosWSsList = new List<Vector3>[cellCountX * cellCountZ]; //flatten 2D array
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            cellPosWSsList[i] = new List<Vector3>();
        }

        //create scatter:
        allGrassPos = new List<Vector3>();
        for (int i = 0; i < calculatedCount; i++)
        {
            Vector3 pos = Vector3.zero;

            pos.x = UnityEngine.Random.Range(-1f, 1f) * planeSizeX;
            pos.z = UnityEngine.Random.Range(-1f, 1f) * planeSizeZ;
            pos += origin;

            int xID = Mathf.Min(cellCountX - 1, Mathf.FloorToInt(Mathf.InverseLerp(minX, maxX, pos.x) * cellCountX)); //use min to force within 0~[cellCountX-1]  
            int zID = Mathf.Min(cellCountZ - 1, Mathf.FloorToInt(Mathf.InverseLerp(minZ, maxZ, pos.z) * cellCountZ)); //use min to force within 0~[cellCountZ-1]

            
            allGrassPos.Add(new Vector3(pos.x, pos.y, pos.z));
            cellPosWSsList[xID + zID * cellCountX].Add(pos);
        }

        //for the compute buffer...
        int offset = 0;
        Vector3[] allGrassPosWSSortedByCell = new Vector3[allGrassPos.Count];
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            for (int j = 0; j < cellPosWSsList[i].Count; j++)
            {
                allGrassPosWSSortedByCell[offset] = cellPosWSsList[i][j];
                offset++;
            }
        }

        cacheCount = calculatedCount;
        UpdateComputeBuffer(allGrassPosWSSortedByCell);
        return true;
    }

    void BatchRenderGrass()
    {
        //draw mesh instanced:
        Bounds renderBound = new Bounds();
        renderBound.SetMinMax(origin - new Vector3(planeSizeX, 0, planeSizeZ), origin + new Vector3(planeSizeX, 0, planeSizeZ));
        instancedMaterial.SetTexture("_GrassInfluence", grassInfluenceRT);

        float minX, maxX, minZ, maxZ;
        GetCameraBounds(out minX, out maxX, out minZ, out maxZ);
        instancedMaterial.SetVector("_InfluenceBounds", 
            new Vector4(minX, maxX, minZ, maxZ)
        );
        instancedMaterial.SetBuffer("_VisibleInstanceOnlyTransformIDBuffer", visibleInstancesOnlyPosWSIDBuffer);
        Graphics.DrawMeshInstancedIndirect(GetGrassMeshCache(), 0, instancedMaterial, renderBound, argsBuffer);
    }


    ////////////////////////////////////////////////////////////////
    //                  HELPER FUNCTION                           //
    ////////////////////////////////////////////////////////////////

    void CullWithCompute()
    {
        
        Matrix4x4 v = playerCamera.worldToCameraMatrix;
        Matrix4x4 p = playerCamera.projectionMatrix;
        Matrix4x4 vp = p * v;

        visibleInstancesOnlyPosWSIDBuffer.SetCounterValue(0);

        //set once only
        compute.SetMatrix("_VPMatrix", vp);
        compute.SetFloat("_MaxDrawDistance", 100);
        //first split into batches:
        //int batchCount = Mathf.CeilToInt(calculatedCount / 64.0f);
        //Copypasta
        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        visibleCellIDList.Clear();

        float cameraOriginalFarPlane = playerCamera.farClipPlane;
        playerCamera.farClipPlane = 100;//allow drawDistance control    
        GeometryUtility.CalculateFrustumPlanes(playerCamera, cameraFrustumPlanes);//Ordering: [0] = Left, [1] = Right, [2] = Down, [3] = Up, [4] = Near, [5] = Far
        playerCamera.farClipPlane = cameraOriginalFarPlane;

        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
           
            //create cell bound
            Vector3 centerPosWS = new Vector3(i % cellCountX + 0.5f, 0, i / cellCountX + 0.5f);
            centerPosWS.x = Mathf.Lerp(minX, maxX, centerPosWS.x / cellCountX);
            centerPosWS.z = Mathf.Lerp(minZ, maxZ, centerPosWS.z / cellCountZ);
            Vector3 sizeWS = new Vector3(blockSize, 0, blockSize);//new Vector3(Mathf.Abs(maxX - minX) / cellCountX, 0, Mathf.Abs(maxZ - minZ) / cellCountZ);
            Bounds cellBound = new Bounds(centerPosWS, sizeWS);
            

            if (GeometryUtility.TestPlanesAABB(cameraFrustumPlanes, cellBound))
            {

                //Debug.DrawLine(centerPosWS, centerPosWS + new Vector3(0, 4, 0));
                visibleCellIDList.Add(i);
            }
        }


        bool shouldBatchDispatch = true;
        for (int i = 0; i < visibleCellIDList.Count; i++)
        {
            int targetCellFlattenID = visibleCellIDList[i];
            int memoryOffset = 0;
            for (int j = 0; j < targetCellFlattenID; j++)
            {
                memoryOffset += cellPosWSsList[j].Count;
            }
            compute.SetInt("_StartOffset", memoryOffset); //culling read data started at offseted pos, will start from cell's total offset in memory
            int jobLength = cellPosWSsList[targetCellFlattenID].Count;

            //============================================================================================
            //batch n dispatchs into 1 dispatch, if memory is continuous in allInstancesPosWSBuffer
            if (shouldBatchDispatch)
            {
                while ((i < visibleCellIDList.Count - 1) && //test this first to avoid out of bound access to visibleCellIDList
                        (visibleCellIDList[i + 1] == visibleCellIDList[i] + 1))
                {
                    //if memory is continuous, append them together into the same dispatch call
                    jobLength += cellPosWSsList[visibleCellIDList[i + 1]].Count;
                    i++;
                }
            }
            //============================================================================================

            compute.Dispatch(0, Mathf.CeilToInt(jobLength / 64f), 1, 1); //disaptch.X division number must match numthreads.x in compute shader (e.g. 64)
        }

        //batch based on whether a group is visible:

        //compute.Dispatch(0, batchCount, 1, 1);
        ComputeBuffer.CopyCount(visibleInstancesOnlyPosWSIDBuffer, argsBuffer, 4);
    }

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

    void GetCameraBounds(out float minX, out float maxX, out float minZ, out float maxZ)
    {
        float camSize = grassRTCamera.orthographicSize;
        Vector3 cameraBounds = grassRTCamera.transform.position;
        minX = cameraBounds.x - camSize;
        maxX = cameraBounds.x + camSize;
        minZ = cameraBounds.z - camSize;
        maxZ = cameraBounds.z + camSize;
    }

    void GetGrassBounds(out float minX, out float maxX, out float minZ, out float maxZ)
    {
        float boundSizeX = planeSizeX;
        //Vector3 origin = origin;
        minX = origin.x - planeSizeX;
        maxX = origin.x + planeSizeX;
        minZ = origin.z - planeSizeZ;
        maxZ = origin.z + planeSizeZ;
    }

    ////////////////////////////////////////////////////////////////
    //                  BUFFER CREATION                           //
    ////////////////////////////////////////////////////////////////
    void UpdateAllBuffers()
    {
        RecreateArgsBuffer();
        RecreateDataBuffer();
    }

    void UpdateComputeBuffer(Vector3[] sortedGrassPos)
    {

        if (allInstancesPosWSBuffer != null)
            allInstancesPosWSBuffer.Release();
        allInstancesPosWSBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(float) * 3); //float3 posWS only, per grass
        allInstancesPosWSBuffer.SetData(sortedGrassPos);

        if (visibleInstancesOnlyPosWSIDBuffer != null)
            visibleInstancesOnlyPosWSIDBuffer.Release();
        visibleInstancesOnlyPosWSIDBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(uint), ComputeBufferType.Append); //uint only, per visible grass

        compute.SetBuffer(0, "_AllInstancesPosWSBuffer", allInstancesPosWSBuffer);
        compute.SetBuffer(0, "_VisibleInstancesOnlyPosWSIDBuffer", visibleInstancesOnlyPosWSIDBuffer);
    }

    void RecreateArgsBuffer()
    {
        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        if (argsBuffer != null)
            argsBuffer.Release();
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
        instancedMaterial.SetBuffer("_PositionBuffer", allInstancesPosWSBuffer);

        //instancedMaterial.SetBuffer("VisibleIDBuffer", ...);
        //lookup the visible positions using the given ids.
    }



}
