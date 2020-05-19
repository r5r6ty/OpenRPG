using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test20200518 : MonoBehaviour
{
    public GameObject wolai;

    // Start is called before the first frame update
    void Start()
    {
        wolai = new GameObject("wocao");

        //Destroy(wolai);


    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void LateUpdate()
    {
        print(wolai);
    }
}
