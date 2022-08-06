using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomMove : MonoBehaviour
{
    // Start is called before the first frame update
    Vector3 basePos;
    Vector3 baseForward;
    float time_elapsed = 0;
    [SerializeField] float amplitudeX = 1;
    [SerializeField] float amplitudeY = 1;
    [SerializeField] float timeScale = 2;
    void Start()
    {
        basePos = transform.position;
        baseForward = transform.forward;
    }

    // Update is called once per frame
    void Update()
    {
        time_elapsed += Time.deltaTime;
        Vector3 offset = new Vector3();
        offset += Mathf.Cos(time_elapsed * timeScale) * Vector3.right * amplitudeX;
        offset += Mathf.Sin(time_elapsed * timeScale) * Vector3.up * amplitudeY;
        transform.position = basePos + offset;

        Vector3 forwardOffset = new Vector3();
        forwardOffset -= Mathf.Cos(time_elapsed * timeScale) * Vector3.right * 0.4f;
        forwardOffset -= Mathf.Sin(time_elapsed * timeScale) * Vector3.up * 0.4f;
        forwardOffset.z = 0.01f;

        transform.forward = (baseForward + forwardOffset).normalized;
    }
}
