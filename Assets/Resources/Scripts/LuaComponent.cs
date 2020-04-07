using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using XLua;
using System;

namespace XLuaTest
{
    public class LuaComponent : MonoBehaviour
    {
        //Lua表
        public LuaTable scriptEnv;
        public string method;

        public Action luaStart;
        public Action luaUpdate;
        //private Action luaLateUpdate;
        public Action luaFixedUpdate;
        public Action luaOnDestroy;


        void Start()
        {
            if (luaStart != null)
            {
                luaStart();
            }
        }

        //void Start()
        //{
        //    scriptEnv.Get("start", out luaStart);
        //    scriptEnv.Get("update", out luaUpdate);
        //    //scriptEnv.Get("lateupdate", out luaLateUpdate);
        //    scriptEnv.Get("fixedupdate", out luaFixedUpdate);
        //    scriptEnv.Get("ondestroy", out luaOnDestroy);

        //    scriptEnv.Get("bOnCollisionEnter", out luaBOnCollisionEnter);
        //    scriptEnv.Get("bOnCollisionStay", out luaBOnCollisionStay);
        //    scriptEnv.Get("bOnCollisionExit", out luaBOnCollisionExit);

        //    if (luaStart != null)
        //    {
        //        luaStart();
        //    }
        //}

        // Start is called before the first frame update
        void Update()
        {
            if (luaUpdate != null)
            {
                luaUpdate();
            }
        }

        //void LateUpdate()
        //{
        //    if (luaLateUpdate != null)
        //    {
        //        luaLateUpdate();
        //    }
        //}

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
            luaFixedUpdate = null;
            luaUpdate = null;
            luaStart = null;
            scriptEnv.Dispose();
        }
    }
}