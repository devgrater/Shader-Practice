using System.Collections;
using System.Collections.Generic;
using UnityEngine;

///Find a way to draw debug info
public class VCloudVolume : MonoBehaviour
{
    // Start is called before the first frame update
    public Color gizmoColor = Color.cyan;
    void OnDrawGizmosSelected()
    {
        Gizmos.color = gizmoColor;
        Gizmos.DrawWireCube(transform.position, transform.localScale);
    }
}
