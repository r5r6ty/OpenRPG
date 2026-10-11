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

        public Injection[] injections;

        internal static LuaEnv luaEnv = new LuaEnv(); // all lua behaviour shared one luaenv only!
        internal static float lastGCTime = 0;
        internal const float GCInterval = 1;// 1 second

        private Action luaStart;
        private Action luaUpdate;
        private Action luaLateUpdate;
        private Action luaFixedUpdate;
        private Action luaOnDestroy;
        private Action luaOnGui;
        private Action luaOnDrawGizmos;

        // 教程中是私有的，不过为了在lua脚本里能拿到这个变量所以改成了共有的
        public LuaTable scriptEnv;

        // 取一段脚本的原始字节：先查 GameLoader 预载的字节缓存，桌面端再落盘读文件。
        // 存字节不存 text：lua 源文件按字节喂给 lua，编码由文件本身决定，不会被 UTF-8 解码弄坏。
        internal static byte[] LoadScriptBytes(string name)
        {
            byte[] cached = LuaManager.Instance.GetScriptBytes(name);
            if (cached != null)
            {
                return cached;
            }
#if !UNITY_WEBGL
            string path = GameLoader.Getluapath() + name.Replace('.', '/') + ".lua";
            if (File.Exists(path))
            {
                return File.ReadAllBytes(path);
            }
#endif
            return null;
        }

        private byte[] CustomLoaderMethod(ref string fileName)
        {
            byte[] code = LoadScriptBytes(fileName);
#if UNITY_WEBGL
            if (code == null)
            {
                Debug.LogError("CustomLoader: WebGL 下找不到未预载的脚本：" + fileName);
            }
#else
            if (code != null)
            {
                // 和文件加载器对齐路径（xLua 拿它当 chunk 名）
                fileName = GameLoader.Getluapath() + fileName.Replace('.', '/') + ".lua";
            }
#endif
            return code;
        }

        // AddLoader 只要加一次，加多了每条 require 都会白走一遍全部 loader
        internal static bool loaderAdded = false;

        void Awake()
        {
            if (!loaderAdded)
            {
                LuaEnv.CustomLoader method = CustomLoaderMethod; // 自定义加载方法
                luaEnv.AddLoader(method); // 添加自定义装载机Loader
                loaderAdded = true;
            }

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

            // 通过gameobject的名字来获取对应的lua脚本
            // 为了能够给gameobject挂上想要的lua，必须在awake之前就让他知道要哪个lua脚本，目前用gameobject的name取
            // Instantiate 出来的物体名字带 " (Clone)" 后缀，剥掉再查
            string objName = gameObject.name.ToLower();
            if (objName.EndsWith("(clone)"))
            {
                objName = objName.Substring(0, objName.Length - "(clone)".Length).Trim();
            }
            byte[] code = LoadScriptBytes(objName);
            if (code == null)
            {
                Debug.LogError("LuaBehaviour: 找不到物体 " + gameObject.name + " 对应的 lua 脚本（" + objName + "）");
                return;
            }
            luaEnv.DoString(code, gameObject.name, scriptEnv);

            Action luaAwake = scriptEnv.Get<Action>("awake");
            scriptEnv.Get("start", out luaStart);
            scriptEnv.Get("update", out luaUpdate);
            scriptEnv.Get("lateupdate", out luaLateUpdate);
            scriptEnv.Get("fixedupdate", out luaFixedUpdate);
            scriptEnv.Get("ondestroy", out luaOnDestroy);
            scriptEnv.Get("ongui", out luaOnGui);
            scriptEnv.Get("onDrawGizmos", out luaOnDrawGizmos);

            if (luaAwake != null)
            {
                luaAwake();
            }
        }

        // Use this for initialization
        void Start()
        {
            _lastInterval = Time.realtimeSinceStartup;
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

        void LateUpdate()
        {
            if (luaLateUpdate != null)
            {
                luaLateUpdate();
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
            luaStart = null;
            luaUpdate = null;
            luaLateUpdate = null;
            luaFixedUpdate = null;
            luaOnDestroy = null;
            luaOnGui = null;
            luaOnDrawGizmos = null;
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
    }
}
