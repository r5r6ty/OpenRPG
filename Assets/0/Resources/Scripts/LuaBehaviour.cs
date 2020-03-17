/*
 * Tencent is pleased to support the open source community by making xLua available.
 * Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using XLua;
using System;
using System.IO;

namespace XLuaTest
{
    [System.Serializable]
    public class Injection
    {
        public string name;
        public GameObject value;
    }

    [LuaCallCSharp]
    public class LuaBehaviour : MonoBehaviour
    {
        //更新的时间间隔
        public float UpdateInterval = 0.5F;
        //最后的时间间隔
        private float _lastInterval;
        //帧[中间变量 辅助]
        private int _frames = 0;
        //当前的帧率
        private float _fps;
        private string mark = "";

        //public TextAsset luaScript;
        public Injection[] injections;

        internal static LuaEnv luaEnv = new LuaEnv(); // all lua behaviour shared one luaenv only!
        internal static float lastGCTime = 0;
        internal const float GCInterval = 1;// 1 second 

        private Action luaStart;
        private Action luaUpdate;
        private Action luaFixedUpdate;
        private Action luaOnDestroy;
        private Action luaOnGui;
        private Action luaOnDrawGizmos;

        //private Action<Collider2D> luaOnTriggerEnter2D;
        //private Action<Collider2D> luaOnTriggerExit2D;
        //private Action<Collider2D> luaOnTriggerStay2D;
        //private Action<Collision2D> luaOnCollisionEnter2D;
        //private Action<Collision2D> luaOnCollisionExit2D;
        //private Action<Collision2D> luaOnCollisionStay2D;

        //private Action<Collider> luaOnTriggerEnter;
        //private Action<Collider> luaOnTriggerExit;
        //private Action<Collider> luaOnTriggerStay;
        //private Action<Collision> luaOnCollisionEnter;
        //private Action<Collision> luaOnCollisionExit;
        //private Action<Collision> luaOnCollisionStay;

        private Action<GameObject, AnimationEvent> luaPlayAnimationEvent;

        //private Action<int> luaOnAnimatorIK;

        // 教程中是私有的，不过为了在lua脚本里能拿到这个变量所以改成了共有的，不知道能否这样做
        public LuaTable scriptEnv;

        private byte[] CustomLoaderMethod(ref string fileName)
        {
            // 找到指定文件
            fileName = GameLoader.Getluapath() + fileName.Replace('.', '/') + ".lua";
            print(fileName);
#if UNITY_EDITOR_WIN || UNITY_STANDALONE_WIN
            if (File.Exists(fileName))
            {
                return File.ReadAllBytes(fileName);
            }
            else
            {
                return null;
            }
#else
            WWW www = new WWW(fileName);
            while (!www.isDone)
            {
                if (www.error != null && www.error != "")
                {
                    print(www.error);
                    return null;
                }
            }
            return www.bytes;
#endif
        }

        void Awake()
        {
            LuaEnv.CustomLoader method = CustomLoaderMethod; // 自定义加载方法
            // 添加自定义装载机Loader  
            luaEnv.AddLoader(method);

            scriptEnv = luaEnv.NewTable();

            // 为每个脚本设置一个独立的环境，可一定程度上防止脚本间全局变量、函数冲突
            LuaTable meta = luaEnv.NewTable();
            meta.Set("__index", luaEnv.Global);
            scriptEnv.SetMetaTable(meta);
            meta.Dispose();

            scriptEnv.Set("self", this);
            if (injections != null)
            {
                foreach (var injection in injections)
                {
                    scriptEnv.Set(injection.name, injection.value);
                }
            }

            // 教程代码
            //luaEnv.DoString(luaScript.text, "LuaTestScript", scriptEnv);

            // 通过gameobject的名字来获取对应的lua脚本
            // 为了能够给gameobject挂上想要的lua，必须在awake之前就让他知道要哪个lua脚本，目前用gameobject的name取，不知道有没有更好的方法
            string scripts = LuaManager.Instance.GetScripts(gameObject.name.ToLower());
            luaEnv.DoString(scripts, gameObject.name, scriptEnv);

            //luaEnv.DoString(@"require('test')");

            Action luaAwake = scriptEnv.Get<Action>("awake");
            scriptEnv.Get("start", out luaStart);
            scriptEnv.Get("update", out luaUpdate);
            scriptEnv.Get("fixedupdate", out luaFixedUpdate);
            scriptEnv.Get("ondestroy", out luaOnDestroy);
            scriptEnv.Get("ongui", out luaOnGui);
            scriptEnv.Get("onDrawGizmos", out luaOnDrawGizmos);

            //scriptEnv.Get("onTriggerEnter2D", out luaOnTriggerEnter2D);
            //scriptEnv.Get("onTriggerExit2D", out luaOnTriggerExit2D);
            //scriptEnv.Get("onTriggerStay2D", out luaOnTriggerStay2D);
            //scriptEnv.Get("onCollisionEnter2D", out luaOnCollisionEnter2D);
            //scriptEnv.Get("onCollisionExit2D", out luaOnCollisionExit2D);
            //scriptEnv.Get("onCollisionEnter2D", out luaOnCollisionStay2D);

            //scriptEnv.Get("onTriggerEnter", out luaOnTriggerEnter);
            //scriptEnv.Get("onTriggerExit", out luaOnTriggerExit);
            //scriptEnv.Get("onTriggerStay", out luaOnTriggerStay);
            //scriptEnv.Get("onCollisionEnter", out luaOnCollisionEnter);
            //scriptEnv.Get("onCollisionExit", out luaOnCollisionExit);
            //scriptEnv.Get("onCollisionStay", out luaOnCollisionStay);

            scriptEnv.Get("playanimationevent", out luaPlayAnimationEvent);

            //scriptEnv.Get("onAnimatorIK", out luaOnAnimatorIK);

            if (luaAwake != null)
            {
                luaAwake();
            }
        }

        // Use this for initialization
        void Start()
        {
            UpdateInterval = Time.realtimeSinceStartup;
            _frames = 0;
            if (luaStart != null)
            {
                luaStart();
            }
        }

        // Update is called once per frame
        void Update()
        {
            _frames++;
            if (Time.realtimeSinceStartup > _lastInterval + UpdateInterval)
            {
                _fps = _frames / (Time.realtimeSinceStartup - _lastInterval);
                _frames = 0;
                _lastInterval = Time.realtimeSinceStartup;
            }
            if (luaUpdate != null)
            {
                luaUpdate();
            }
            if (Time.time - LuaBehaviour.lastGCTime > GCInterval)
            {
                luaEnv.Tick();
                if (mark == "")
                {
                    mark = "√";
                }
                else
                {
                    mark = "";
                }
                LuaBehaviour.lastGCTime = Time.time;
            }
        }

        void FixedUpdate()
        {
            if (luaFixedUpdate != null)
            {
                luaFixedUpdate();
            }
        }

        void OnDestroy()
        {
            if (luaOnDestroy != null)
            {
                luaOnDestroy();
            }
            luaOnDestroy = null;
            luaUpdate = null;
            luaStart = null;
            scriptEnv.Dispose();
            injections = null;
        }

        void OnGUI()
        {
            GUI.Label(new Rect(10, Screen.height - 40, 400, 20), "Lua Memory:" + luaEnv.Memroy + "Kb" + mark + ", FPS: " + _fps.ToString("f2"));
            if (luaOnGui != null)
            {
                luaOnGui();
            }
        }

        void OnDrawGizmos()
        {
            if (luaOnDrawGizmos != null)
            {
                luaOnDrawGizmos();
            }
        }

        //void OnTriggerEnter2D(Collider2D c)
        //{
        //    if (luaOnTriggerEnter2D != null)
        //    {
        //        luaOnTriggerEnter2D(c);
        //    }
        //}

        //void OnTriggerExit2D(Collider2D c)
        //{
        //    if (luaOnTriggerExit2D != null)
        //    {
        //        luaOnTriggerExit2D(c);
        //    }
        //}

        //void OnTriggerStay2D(Collider2D c)
        //{
        //    if (luaOnTriggerStay2D != null)
        //    {
        //        luaOnTriggerStay2D(c);
        //    }
        //}

        //void OnCollisionEnter2D(Collision2D c)
        //{
        //    if (luaOnCollisionEnter2D != null)
        //    {
        //        luaOnCollisionEnter2D(c);
        //    }
        //}

        //void OnCollisionExit2D(Collision2D c)
        //{
        //    if (luaOnCollisionExit2D != null)
        //    {
        //        luaOnCollisionExit2D(c);
        //    }
        //}

        //void OnCollisionStay2D(Collision2D c)
        //{
        //    if (luaOnCollisionStay2D != null)
        //    {
        //        luaOnCollisionStay2D(c);
        //    }
        //}

        //void OnTriggerEnter(Collider c)
        //{
        //    if (luaOnTriggerEnter != null)
        //    {
        //        luaOnTriggerEnter(c);
        //    }
        //}

        //void OnTriggerExit(Collider c)
        //{
        //    if (luaOnTriggerExit != null)
        //    {
        //        luaOnTriggerExit(c);
        //    }
        //}

        //void OnTriggerStay(Collider c)
        //{
        //    if (luaOnTriggerStay != null)
        //    {
        //        luaOnTriggerStay(c);
        //    }
        //}

        //void OnCollisionEnter(Collision c)
        //{
        //    if (luaOnCollisionEnter != null)
        //    {
        //        luaOnCollisionEnter(c);
        //    }
        //}

        //void OnCollisionExit(Collision c)
        //{
        //    if (luaOnCollisionExit != null)
        //    {
        //        luaOnCollisionExit(c);
        //    }
        //}

        //void OnCollisionStay(Collision c)
        //{
        //    if (luaOnCollisionStay != null)
        //    {
        //        luaOnCollisionStay(c);
        //    }
        //}

        public void PlayAnimationEvent(GameObject go, AnimationEvent ae)
        {
            if (luaPlayAnimationEvent != null)
            {
                luaPlayAnimationEvent(go, ae);
            }
        }


        //public void OnAnimatorIK(int layerIndex)
        //{
        //    if (luaOnAnimatorIK != null)
        //    {
        //        luaOnAnimatorIK(layerIndex);
        //    }
        //}
    }
}
