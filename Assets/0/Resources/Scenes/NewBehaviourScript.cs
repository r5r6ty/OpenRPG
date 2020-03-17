using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript : MonoBehaviour
{
    [HideInInspector]
    public int ret = 0;
    public XLuaTest.LuaBehaviour lu;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void test(int i, string s)
    {
        ret = i;
    }
}
