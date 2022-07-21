using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrassController : MonoBehaviour
{

    [SerializeField] private Material instancedMaterial;
    [SerializeField] private Texture grassInfluenceRT;
    [SerializeField] private Camera grassRTCamera;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        instancedMaterial.SetTexture("_GrassInfluence", grassInfluenceRT);
        Vector3 cameraBounds = grassRTCamera.transform.position;

        float camSize = grassRTCamera.orthographicSize;
        instancedMaterial.SetVector("_InfluenceBounds",
            new Vector4(cameraBounds.x - camSize,
                        cameraBounds.x + camSize,
                        cameraBounds.z - camSize,
                        cameraBounds.z + camSize)
        );
    }
}
