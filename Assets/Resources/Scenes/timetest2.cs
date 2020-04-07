using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class timetest2 : MonoBehaviour
{
    public string name;
    float lastTime;
    public Animation a;

    public Object ooo;

    public float ratio;
    public float frameRate;
    // Start is called before the first frame update

    public NewBehaviourScript nbs;
    void Start()
    {
        AnimationClip clip = new AnimationClip();
        clip.legacy = true;
        clip.wrapMode = WrapMode.Loop;

        //AnimationCurve curve = new AnimationCurve();
        //curve.AddKey(0, 0);
        //curve.AddKey(1, 0);
        //clip.SetCurve("", typeof(Transform), "localPosition.x", curve);



        a.AddClip(clip, "test_animation");

        //a["test_animation"].clip.frameRate = frameRate;

        a["test_animation"].speed = ratio;
        

        AnimationEvent ae = new AnimationEvent();
        //ae.objectReferenceParameter = ooo;
        ae.functionName = "";
        //ae.intParameter = 1;
        ae.time = 1.0f;
        ae.messageOptions = SendMessageOptions.DontRequireReceiver;
        a["test_animation"].clip.AddEvent(ae);

        ae = new AnimationEvent();
        //ae.objectReferenceParameter = ooo;
        ae.functionName = "aab";
        //ae.intParameter = 1;
        ae.time = 0.5f;
        ae.messageOptions = SendMessageOptions.DontRequireReceiver;
        a["test_animation"].clip.AddEvent(ae);

        ae = new AnimationEvent();
        //ae.objectReferenceParameter = ooo;
        ae.functionName = "";
        //ae.intParameter = 1;
        ae.time = 0.0f;
        ae.messageOptions = SendMessageOptions.DontRequireReceiver;
        a["test_animation"].clip.AddEvent(ae);

        a.Play("test_animation");


        //a["New Animation"].clip.frameRate = frameRate;

        //a["New Animation"].speed = ratio;

        //AnimationEvent ae = new AnimationEvent();
        //ae.objectReferenceParameter = ooo;
        //ae.functionName = "aab";
        ////ae.intParameter = 1;
        //ae.time = 1.0f;
        ////ae.messageOptions = SendMessageOptions.DontRequireReceiver;
        //a["New Animation"].clip.AddEvent(ae);

        //ae = new AnimationEvent();
        //ae.objectReferenceParameter = ooo;
        //ae.functionName = "aab";
        ////ae.intParameter = 1;
        //ae.time = 0.5f;
        ////ae.messageOptions = SendMessageOptions.DontRequireReceiver;
        //a["New Animation"].clip.AddEvent(ae);

    }

    // Update is called once per frame
    void Update()
    {
        //if(nbs.ret != 0)
        //{
        //    aab();
        //    nbs.ret = 0;
        //}
    }

    public void aab()
    {
        float deltaTime = Time.realtimeSinceStartup - lastTime;

        print(deltaTime + " " + name);

        lastTime = Time.realtimeSinceStartup;

    }
}
