using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameAnimation : MonoBehaviour
{
    public XLuaTest.LuaBehaviour luaBehaviour = null;
    public float test;
    //private AnimationEvent ae; 

    private float lastTime = 0;

    // Start is called before the first frame update
    void Start()
    {
        //ae = new AnimationEvent();
        //ae.functionName = "RunAnimationEvent";
        //ae.intParameter = 0;
        //ae.stringParameter = "body_run_front";
        //ae.time = 0 * (1 / 60);
    }

    // Update is called once per frame
    void Update()
    {
        //luaBehaviour.PlayAnimationEvent(gameObject, ae);
    }

    public void RunAnimationEvent(AnimationEvent ae)
    {
        //luaBehaviour.PlayAnimationEvent(gameObject, ae);

        float deltaTime = Time.realtimeSinceStartup - lastTime;

        print(ae.intParameter + "___" + deltaTime * 100);

        lastTime = Time.realtimeSinceStartup;
    }
}
