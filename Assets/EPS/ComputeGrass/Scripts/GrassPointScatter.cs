using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

[ExecuteAlways]
public class GrassPointScatter : MonoBehaviour
{
    [SerializeField] private float planeSizeX = 10;
    [SerializeField] private float planeSizeZ = 10;
    private int calculatedCount = 100;
    private int cacheCount = -1;
    [SerializeField] private int density = 5; //5 grass per unit

    List<Vector4> allGrassPos;
    List<Vector4>[] cellPosWSsList;
    private ComputeBuffer argsBuffer;
    private ComputeBuffer allInstancesPosWSBuffer;
    private ComputeBuffer visibleInstancesOnlyPosWSIDBuffer;
    private ComputeBuffer dataProcessingBuffer;
    private ComputeBuffer grassAdditionalDataBuffer;

    [SerializeField] private Mesh grassMesh;
    private Mesh cachedGrassMesh;
    [SerializeField] private Material instancedMaterial;
    [SerializeField] private Texture grassInfluenceRT;
    [SerializeField] private Camera grassRTCamera;
    //block size: 1m per block.
    [SerializeField] private float blockSize = 4;
    [SerializeField] private ComputeShader compute;

    private Camera _targetCamera;
    private Plane[] cameraFrustumPlanes = new Plane[6];
    private List<int> visibleCellIDList = new List<int>();

    [SerializeField] private GameObject meshToMatch;
    [SerializeField] private Texture heightMap;
    [SerializeField] private Texture colorMap;
    [SerializeField] private float heightMapHeight;
    [SerializeField] private float baseOffset;
    [SerializeField] private float baseHeight;

    [SerializeField] private RenderTexture colorInfo;
    [SerializeField] private RenderTexture heightInfo;

    private bool setInitialPos = true;

    private float cullRange = 200;


    private int cellCountX;
    private int cellCountZ;
    private Vector3 origin;

    // Start is called before the first frame update
    void OnEnable()
    {
        //RecalculateGrassCount();
        //if (ScatterGrass())
        //    UpdateAllBuffers();
        //test
        Reset();
        ScatterGrass(true);
        UpdateAllBuffers();
        //
    }

    public GameObject GetMatchedMesh()
    {
        return meshToMatch;
    }


    // Update is called once per frame
    void LateUpdate()
    {
        if (!compute) return; //dont do it if you don't have enough info!
        RecalculateGrassCount();
        if (ScatterGrass())
            UpdateAllBuffers();
        UpdateParameters();
        CullWithCompute();

        BatchRenderGrass();

    }


    public void FullReset()
    {
        Reset();
        ScatterGrass(true);
        UpdateAllBuffers();
    }

    private void Reset()
    {
        ReleaseAllBuffers();
        if (meshToMatch)
        {
            //do something with the mesh...
            Collider collider = meshToMatch.GetComponent<Collider>();
            Bounds b = collider.bounds;
            origin = b.center;
            origin.y = b.max.y;
            planeSizeX = b.extents.x;
            planeSizeZ = b.extents.z;
        }
        else
        {
            origin = transform.position;
        }

        _targetCamera = Camera.main;
        if (!Application.isPlaying)
        {
            SceneView latest = UnityEditor.SceneView.lastActiveSceneView;
            if (latest != null && latest != null)
            {
                cullRange = 1000;
                _targetCamera = UnityEditor.SceneView.lastActiveSceneView.camera;
            }
        }
    }

    void OnDisable()
    {
        ReleaseAllBuffers();
    }

    void ReleaseAllBuffers()
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

        if (grassAdditionalDataBuffer != null)
            grassAdditionalDataBuffer.Release();
        grassAdditionalDataBuffer = null;

        if (dataProcessingBuffer != null)
            dataProcessingBuffer.Release();
        dataProcessingBuffer = null;
    }

    void RecalculateGrassCount()
    {
        calculatedCount = Mathf.CeilToInt(planeSizeX * planeSizeZ * Mathf.Max(density, 1.0f));
    }

    bool ScatterGrass(bool force = false)
    {
        if (calculatedCount == cacheCount && !force)
            return false;
        //how many blocks are there?

        //in the original example, he had to calculate the min and max bound.
        //but we know the min and max bounds already, so we can calculate directly.
        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        cellCountX = Mathf.CeilToInt((maxX - minX) / blockSize);
        cellCountZ = Mathf.CeilToInt((maxZ - minZ) / blockSize);

        cellPosWSsList = new List<Vector4>[cellCountX * cellCountZ]; //flatten 2D array
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            cellPosWSsList[i] = new List<Vector4>();
        }

        //create scatter:
        allGrassPos = new List<Vector4>();
        for (int i = 0; i < calculatedCount; i++)
        {
            Vector4 pos = Vector3.zero;

            pos.x = UnityEngine.Random.Range(-1f, 1f) * planeSizeX;
            pos.z = UnityEngine.Random.Range(-1f, 1f) * planeSizeZ;
            pos += new Vector4(origin.x, origin.y, origin.z, 0.0f);

            int xID = Mathf.Min(cellCountX - 1, Mathf.FloorToInt(Mathf.InverseLerp(minX, maxX, pos.x) * cellCountX)); //use min to force within 0~[cellCountX-1]  
            int zID = Mathf.Min(cellCountZ - 1, Mathf.FloorToInt(Mathf.InverseLerp(minZ, maxZ, pos.z) * cellCountZ)); //use min to force within 0~[cellCountZ-1]


            allGrassPos.Add(new Vector4(pos.x, pos.y, pos.z, Random.Range(0, 1)));
            cellPosWSsList[xID + zID * cellCountX].Add(pos);
        }

        //for the compute buffer...
        int offset = 0;
        Vector4[] allGrassPosWSSortedByCell = new Vector4[allGrassPos.Count];
        Vector4[] allGrassColorData = new Vector4[allGrassPos.Count];
        for (int i = 0; i < cellPosWSsList.Length; i++)
        {
            for (int j = 0; j < cellPosWSsList[i].Count; j++)
            {
                allGrassPosWSSortedByCell[offset] = cellPosWSsList[i][j];
                allGrassColorData[offset] = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);
                offset++;
            }
        }

        cacheCount = calculatedCount;
        UpdateComputeBuffer(allGrassPosWSSortedByCell, allGrassColorData);
        return true;
    }

    void BatchRenderGrass()
    {
        //draw mesh instanced:
        Bounds renderBound = new Bounds();
        renderBound.SetMinMax(origin - new Vector3(planeSizeX, -baseOffset, planeSizeZ), origin + new Vector3(planeSizeX, heightMapHeight, planeSizeZ));
        
        if(grassInfluenceRT && grassRTCamera)
        {
            instancedMaterial.SetTexture("_GrassInfluence", grassInfluenceRT);

            float minX, maxX, minZ, maxZ;
            GetCameraBounds(out minX, out maxX, out minZ, out maxZ);
            instancedMaterial.SetVector("_InfluenceBounds",
                new Vector4(minX, maxX, minZ, maxZ)
            );
        }

        instancedMaterial.SetBuffer("_VisibleInstanceOnlyTransformIDBuffer", visibleInstancesOnlyPosWSIDBuffer);
        Graphics.DrawMeshInstancedIndirect(GetGrassMeshCache(), 0, instancedMaterial, renderBound, argsBuffer, 0, null, UnityEngine.Rendering.ShadowCastingMode.Off);
    }


    ////////////////////////////////////////////////////////////////
    //                  HELPER FUNCTION                           //
    ////////////////////////////////////////////////////////////////

    void UpdateParameters()
    {
        if (!Application.isPlaying)
        {
            compute.SetTexture(0, "_HeightMap", GetHeightInfoTexture());
            compute.SetVector("_HeightControl", new Vector4(baseOffset, heightMapHeight));
            compute.SetTexture(0, "_SplatMap", GetColorInfoTexture());
        }
        else
        {
            if (heightMap)
            {
                compute.SetTexture(0, "_HeightMap", heightMap);
                compute.SetVector("_HeightControl", new Vector4(baseOffset, heightMapHeight));
            }
            if (colorMap)
            {
                compute.SetTexture(0, "_SplatMap", colorMap);
            }
        }

        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        compute.SetVector("_GrassBounds", new Vector4(minX, maxX, minZ, maxZ));
        instancedMaterial.SetVector("_GrassBounds", new Vector4(minX, maxX, minZ, maxZ));
    }

    void CullWithCompute()
    {

        Matrix4x4 v = _targetCamera.worldToCameraMatrix;
        Matrix4x4 p = _targetCamera.projectionMatrix;
        Matrix4x4 vp = p * v;

        visibleInstancesOnlyPosWSIDBuffer.SetCounterValue(0);

        //set once only
        compute.SetMatrix("_VPMatrix", vp);
        compute.SetFloat("_MaxDrawDistance", cullRange);
        //first split into batches:
        //int batchCount = Mathf.CeilToInt(calculatedCount / 64.0f);
        //Copypasta
        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        visibleCellIDList.Clear();

        float cameraOriginalFarPlane = _targetCamera.farClipPlane;
        _targetCamera.farClipPlane = cullRange;//allow drawDistance control    
        GeometryUtility.CalculateFrustumPlanes(_targetCamera, cameraFrustumPlanes);//Ordering: [0] = Left, [1] = Right, [2] = Down, [3] = Up, [4] = Near, [5] = Far
        _targetCamera.farClipPlane = cameraOriginalFarPlane;

        for (int i = 0; i < cellPosWSsList.Length; i++)
        {

            //create cell bound
            Vector3 centerPosWS = new Vector3(i % cellCountX + 0.5f, origin.y, i / cellCountX + 0.5f);
            centerPosWS.x = Mathf.Lerp(minX, maxX, centerPosWS.x / cellCountX);
            centerPosWS.z = Mathf.Lerp(minZ, maxZ, centerPosWS.z / cellCountZ);
            float height = (baseOffset + heightMapHeight);
            //centerPosWS.y = origin.y + height;

            Vector3 sizeWS = new Vector3(blockSize, height * 2, blockSize);//new Vector3(Mathf.Abs(maxX - minX) / cellCountX, 0, Mathf.Abs(maxZ - minZ) / cellCountZ);
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

    public void GetGrassBounds(out float minX, out float maxX, out float minZ, out float maxZ)
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

    void UpdateComputeBuffer(Vector4[] sortedGrassPos, Vector4[] allGrassColorData)
    {

        if (allInstancesPosWSBuffer != null)
            allInstancesPosWSBuffer.Release();
        allInstancesPosWSBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(float) * 4); //xyz - pos, w - height
        allInstancesPosWSBuffer.SetData(sortedGrassPos);

        if (visibleInstancesOnlyPosWSIDBuffer != null)
            visibleInstancesOnlyPosWSIDBuffer.Release();
        visibleInstancesOnlyPosWSIDBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(uint), ComputeBufferType.Append); //uint only, per visible grass

        if (grassAdditionalDataBuffer != null)
            grassAdditionalDataBuffer.Release();
        grassAdditionalDataBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(float) * 4); //uint only, per visible grass
        grassAdditionalDataBuffer.SetData(allGrassColorData);

        if (dataProcessingBuffer != null)
            dataProcessingBuffer.Release();
        dataProcessingBuffer = new ComputeBuffer(allGrassPos.Count, sizeof(uint));
        

        compute.SetBuffer(0, "_AllInstancesPosWSBuffer", allInstancesPosWSBuffer);
        compute.SetBuffer(0, "_VisibleInstancesOnlyPosWSIDBuffer", visibleInstancesOnlyPosWSIDBuffer);
        compute.SetBuffer(0, "_AllInstancesColorDataBuffer", grassAdditionalDataBuffer);
        compute.SetBuffer(0, "_DataProcessingBuffer", dataProcessingBuffer);
        compute.SetInt("_IsEditorMode", Application.isPlaying ? 0 : 1);
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
        instancedMaterial.SetBuffer("_ColorDataBuffer", grassAdditionalDataBuffer);

        //instancedMaterial.SetBuffer("VisibleIDBuffer", ...);
        //lookup the visible positions using the given ids.
    }

    ////////////////////////////////////////////////////////////////
    //                  CONTROL FROM SCRIPTS                      //
    ////////////////////////////////////////////////////////////////
    public void SetDimensions(float psx, float psz)
    {
        this.planeSizeX = psx;
        this.planeSizeZ = psz;
    }

    public float GetPlaneSizeX()
    {
        return this.planeSizeX;
    }

    public float GetPlaneSizeZ()
    {
        return this.planeSizeZ;

    }

    public void AttachToMesh(GameObject gameObject)
    {
        this.meshToMatch = gameObject;
    }

    public void SetComputeShader(ComputeShader cs)
    {
        this.compute = cs; 
    }

    public void GenerateStarterTexture()
    {
        
        RenderTexture heightInfoTexture = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32);
        
        heightInfo = heightInfoTexture;
    }


    public RenderTexture GetColorInfoTexture(bool forceReset = false)
    {
        if (!colorInfo || forceReset)
        {
            RenderTexture colorInfoTexture = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32);
            colorInfo = colorInfoTexture;
        }
        return colorInfo;
    }

    public RenderTexture RTFromTexture(Texture2D input)
    {
        RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
        Graphics.Blit(input, rt);
        return rt;
    }

    public RenderTexture GetHeightInfoTexture(bool forceReset = false)
    {
        if (!heightInfo || forceReset)
        {
            //Blit heightmap:
            Shader s = Shader.Find("Hidden/BlitHeightMap");
            Material m = new Material(s);
            RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
            m.SetTexture("_TargetTex", heightMap);
            Graphics.Blit(heightMap, rt, m);

            RenderTexture heightInfoTexture = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32);

            Graphics.CopyTexture(rt, heightInfoTexture);
            heightInfo = heightInfoTexture;
            //rt.Release();
        }
        
        return heightInfo;
    }

    public Vector2 ConvertToUVSpace(Vector3 input)
    {
        float minX, maxX, minZ, maxZ;
        GetGrassBounds(out minX, out maxX, out minZ, out maxZ);
        float uvx = (input.x - minX) / (maxX - minX);
        float uvz = (input.z - minZ) / (maxZ - minZ);
        return new Vector2(uvx, uvz);
    }

    public void SetBase(Vector3 pos)
    {
        //calculate difference
        baseOffset = pos.y - origin.y;
    }

    public void SetHeight(Vector3 pos)
    {
        baseHeight = pos.y - origin.y;
    }

    public Vector3 GetOrigin()
    {
        return this.origin;
    }

    public void SetTextures(RenderTexture cif, RenderTexture hif)
    {
        colorInfo = cif;
        heightInfo = hif;
    }

    public void ApplyTextures(Texture2D colorTex, Texture2D heightTex)
    {
        colorMap = colorTex;
        heightMap = heightTex;
    }




}

