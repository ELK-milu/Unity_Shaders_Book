using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed;
    private Vector3 currentPosition;
    void Start()
    {
        currentPosition = transform.position;
    }
    void Update()
    {
        float inputX = Input.GetAxis("Horizontal");
        float inputY = Input.GetAxis("Vertical");

        currentPosition += new Vector3(inputX,0 , inputY) * moveSpeed * Time.deltaTime;
        transform.position = currentPosition;
    }
}
