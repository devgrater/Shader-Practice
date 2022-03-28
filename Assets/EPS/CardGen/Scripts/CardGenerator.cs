using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CardGenerator : MonoBehaviour
{
    [SerializeField] private Mesh mesh; //generate cards based on the mesh:
    [SerializeField] private float scatterProbability;
    [Tooltip("The area per scatter point on the surface. The smaller this value, the denser the scatter.")]
    [SerializeField] private float areaPerScatter;

    private Mesh generatedCardMesh;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    [ContextMenu("Generate Cards")]
    void GenerateCards(){
        //create a few cards based on the mesh, randomly scatter them. 
        generatedCardMesh = new Mesh{ name = "MossCards" };
        //for each of the cards, if they have a surface area of ....
        //generate cards for them, randomly
        int[] indices = mesh.GetIndices(0);
        
        int triCount = indices.Length / 3;

        //for each of the triangles...
        
        
        for(int idx = 0; idx < indices.Length; idx+=3){
            int localOffsetA = indices[idx];
            int localOffsetB = indices[idx + 1];
            int localOffsetC = indices[idx + 2];

            Vector3 vA = mesh.vertices[localOffsetA];
            Vector3 vB = mesh.vertices[localOffsetB];
            Vector3 vC = mesh.vertices[localOffsetC];


            //get the points, and compute the surface area:
            float surfaceArea = ComputeTriangleSurfaceArea(vA, vB, vC);
            Debug.Log(surfaceArea);
        }

    }

    float ComputeTriangleSurfaceArea(Vector3 p1, Vector3 p2, Vector3 p3){
        //first lets have the two vectors.
        Vector3 dirA = p3 - p1;
        Vector3 dirB = p2 - p1;
        //cross to get the triangle normal:

        Vector3 triangleNormal = Vector3.Cross(dirA.normalized, dirB.normalized);
        Vector3 triangleTangent = Vector3.Cross(triangleNormal, dirA.normalized);
        //dot with triangle tangent:
        float height = Vector3.Dot(dirB, triangleTangent);
        return Vector3.Magnitude(dirA) * height * 0.5f;
    }

    /*
    float GetTriangleSurfaceArea(ref int[] tris, ref Vector3[] verts){

    }*/

}
