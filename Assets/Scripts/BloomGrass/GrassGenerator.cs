using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassGenerator : MonoBehaviour
{

    public GameObject[] generateObj;
    public float step = 3;
    public int RangeX = 10;
    public int RangeY = 10;

    // Start is called before the first frame update
    void Start()
    {
        for (int i = 0; i < RangeX; i++) 
        { 
            for (int j = 0; j < RangeY; j++)
            {
                GameObject go = Instantiate(generateObj[Random.Range(0, generateObj.Length)]) as GameObject;
                go.transform.position = transform.position + new Vector3(i * step, 0, j * step);
                go.transform.SetParent(transform);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
