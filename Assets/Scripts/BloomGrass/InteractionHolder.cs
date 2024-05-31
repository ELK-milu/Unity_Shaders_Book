using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractionHolder : MonoBehaviour {
    [SerializeField]
    GameObject[] objects;
    Vector4[] positions = new Vector4[100];
    float[] radius = new float[100];
	
	// Update is called once per frame
	void Update () {

        for (int i = 0; i < objects.Length; i++)
        {
            positions[i] = objects[i].transform.position;          
            if(objects[i].GetComponent<InteractionRadius>() != null)
            {
               radius[i] = objects[i].GetComponent<InteractionRadius>().radius;
            }
            else
            {
                radius[i] = 0;
            }
        }
        Shader.SetGlobalFloat("_PositionArray", objects.Length);
        Shader.SetGlobalVectorArray("_Positions", positions);
        Shader.SetGlobalFloatArray("_RadiusArray", radius);
       
	}
}
