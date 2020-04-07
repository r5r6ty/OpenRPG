using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class testtime : MonoBehaviour
{
    float lastTime;
    public Animation a;
    public float ratio;
    public float frameRate;

    float ttt = 0;

    float Duration = 1.0f;

    private float _nowTime;
    private float _progressValue;

    private int _nowLoopCount;
    private float _backTime;

    private bool IsLoop = true;
    private int LoopCount = 3;

    public bool IsPause { get; private set; }

    private bool IsBack = false;

    private bool IsReversal = false;

    public float TimeOffset = 1;


    private int test_count = 0;

    // Start is called before the first frame update
    void Start()
    {
        //a["New Animation"].clip.frameRate = frameRate;

        //a["New Animation"].speed = ratio;
        lastTime = Time.realtimeSinceStartup;

        //AnimationEvent ae = new AnimationEvent();
        //ae.functionName = "aaa";
        //ae.time = 0.5f;
        //a["New Animation"].clip.AddEvent(ae);

        //StartCoroutine(Updater());
        Play();
    }

    public void Play()
    {
        this.reset();
        this.IsPause = false;
    }

    public void Pause(bool isPause)
    {
        this.IsPause = isPause;
    }

    private void reset()
    {
        _nowTime = 0;
        this.IsPause = true;
        _backTime = Duration / 2;
        setAnimationValue();
    }

    public void Stop()
    {
        print("Stop!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        _nowTime = Duration;
        setAnimationValue();
        this.IsPause = true;
        test_count = 0;
    }

    private float getNowTime()
    {
        if (IsReversal)
        {
            return Duration - _progressValue;
        }
        return _progressValue;
    }

    private void setAnimationValue()
    {
        if (IsBack)
        {
            if (_nowTime <= _backTime)
                _progressValue = _nowTime * 2;
            else
                _progressValue = Duration - ((_nowTime - _backTime) * 2);
        }
        else
        {
            _progressValue = _nowTime;
        }
        //_setter.Invoke(TweenInfo.Handler.GetProgress(getNowTime(), TweenInfo));
        //test();

        //ttt = getNowTime() - ttt;

        //print(ttt);

        //ttt = getNowTime();

        //print(getNowTime());
        print(test_count);
        test_count += 1;
    }

    // Update is called once per frame
    void Update()
    {

    }

    IEnumerator Updater()
    {
        while (true)
        {
            updateAnimation(Time.deltaTime * TimeOffset);
            yield return 0;
        }
    }

    private bool updateAnimation(float deltaTime)
    {
        if (this.IsPause) return false;
        setAnimationValue();
        //aaa();
        if (_nowTime >= Duration)
        {
            _nowLoopCount++;
            if (IsLoop)
            {
                if (LoopCount == -1 || _nowLoopCount < LoopCount)
                {
                    _nowTime = 0;
                    return true;
                }
            }
            //OnComplete?.Invoke();
            Stop();
        }
        else _nowTime += deltaTime;
        return true;
    }

    void test()
    {
        print(ttt);

        ttt += Time.deltaTime * 60;
    }

    void FixedUpdate()
    {
        //float deltaTime = Time.realtimeSinceStartup - lastTime;

        //print(deltaTime);

        //lastTime = Time.realtimeSinceStartup;

        float deltaTime = Time.deltaTime * TimeOffset;
        if (this.IsPause) return;
        setAnimationValue();
        //aaa();
        if (_nowTime >= Duration)
        {
            _nowLoopCount++;
            if (IsLoop)
            {
                if (LoopCount == -1 || _nowLoopCount < LoopCount)
                {
                    _nowTime = 0;
                    test_count = 0;
                    return;
                }
            }
            //OnComplete?.Invoke();
            Stop();
        }
        else _nowTime += deltaTime;
        return;
    }

    public void aaa()
    {
        float deltaTime = Time.realtimeSinceStartup - lastTime;

        print(deltaTime);

        lastTime = Time.realtimeSinceStartup;
    }
}
