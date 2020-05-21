local LMap = require "LMap"
local utils = require "LUtils"
require "LObject_Gun"
require "LUIObject"

require "LPlayer"

local readCharacterData

local k1, k2, k3 = nil
local curve = nil

local moveSpeed = 32
local camera = nil

local zoom = 1
local dataTable = nil

local mychar = nil

local system = nil

local lastTime = CS.UnityEngine.Time.realtimeSinceStartup

local _update
local _fixedUpdate

local luaBehaviour = nil

local console = nil

local LObject_bit
local UI_bit

local ecs = require "ecs"

function start()

    console = CS.ConsoleTestWindows.ConsoleWindow()
    if console:Initialize() then
        console:SetTitle("OpenRPG Debug Window")
        CS.TestConsole.Start2()
    end

    print("lua start...")
    print("injected object", LMainCamera)
    print("injected object", LCanvas)

    -- CS.UnityEngine.Screen.SetResolution(1920, 1080, false)
    -- CS.UnityEngine.Screen.SetResolution(640, 360, false)

    LMainCamera:GetComponent(typeof(CS.UnityEngine.Experimental.Rendering.Universal.PixelPerfectCamera)).enabled = false

    camera = LMainCamera:GetComponent(typeof(CS.UnityEngine.Camera))
    camera.orthographicSize = CS.UnityEngine.Screen.height / 1 / 100 / zoom
    utils.CAMERA = camera
    
    -- utils.LUABEHAVIOUR = self:GetComponent(typeof(CS.XLuaTest.LuaBehaviour))

    utils.setLCanvas(LCanvas)
    utils.loadfont2()
    -- 
--    dataTable = utils.LoadTilesFromCSV(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/1/Resource/" .. "tile_data.csv")

    utils.loadfont2() -- TXHkWVLe

    readCharacterData() -- TXHk=GI+J}>]

    utils.createHPMP()

    -- CS.UnityEngine.Cursor.visible = false

    -- CS.UnityEngine.QualitySettings.vSyncCount = 0

    -- 生成地图

    -- 6AH!LMap5Djson5D2bJT
    LMap.new(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/Resource/", "data2.cdb")
    -- LMap.show(1, 0, 0)

    -- local ds = LMap.gen3(-40 * 0.2, 20 * 0.2, 2)
    local ds = LMap.gen3(0, 0, 2)

    -- LMap.gen()

    -- 生成角色
    -- utils.CURSOR = utils.createObject(nil, 9, "cursor", 0, "cursor", 0, 0, 0, 0, 0, 0, 5)


    -- local t = utils.CURSOR

    local f = {}

    local ppp = nil

    -- for i = 0, 0, 1 do
    --     local prostr = nil
    --     if i % 3 == 0 then
    --         prostr = "girl_with_gun1"
    --     elseif i % 3 == 1 then
    --         prostr = "girl_with_gun2_shield"
    --     elseif i % 3 == 2 then
    --         prostr = "girl_with_gun1"
    --     end
    --     local mychar, proto = utils.InstantiateFromDataBase(nil, 9, prostr, i * 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0, 1, i % 3 + 1)

    --     -- bind(mychar, "timeLine", function(val, old)
    --     --     print("timeLine changed:", "new:", val, "old:", old)
    --     -- end)

    --     -- mychar.timeLine = 999

    --     rawset(mychar, "controller", mychar.database.AI)
    --     rawset(mychar, "AI", true)

    --     -- mychar.speed = (100 - i) / 100

    --     -- mychar.spriteRenderer.material = mychar.database.palettes[i % 3 + 1]
    --     if i == 0 then
    --         mychar.team = 1

    --         rawset(mychar, "target", t)
    --         ppp = mychar
    --     else
    --         mychar.team = 2

    --         rawset(mychar, "target", ppp)
    --     end

    --     -- CS.Tools.Instance:GetAnimationState(p.animation, "body_run_front").speed = (100 - i) / 100 + 1

    --     table.insert(f, mychar)
    -- end
    -- mychar = f[1]

    -- local mychar = utils.NewLObject()

    -- utils.addComponent(mychar ,"DataBase", 9, "body_idle_front", "aim")
    -- utils.addComponent(mychar ,"SpriteRenderer")
    -- utils.addComponent(mychar ,"Physical", nil,  0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0)
    -- utils.addComponent(mychar ,"Control", nil, false)
    -- utils.addComponent(mychar ,"Target", nil)
    -- utils.addComponent(mychar ,"Sleep")

    -- IID = mychar.physics_object:GetInstanceID()
    -- utils.addObject(IID, bindable(mychar))


    -- player = LPlayer:new(mychar, LMainCamera) -- LMainCamera:GetComponent(typeof(CS.UnityEngine.Camera))
    -- -- system = LSystem:new(nil)
    -- -- utils.setLSystem(system)



    -- utils.PLAYER = player
    
    -- rawset(mychar, "controller", utils.PLAYER)
    -- mychar.AI = false

    -- -- 2bJT6/;-

    -- local unityobject_child = CS.UnityEngine.GameObject("test")
    -- local ani = unityobject_child:AddComponent(typeof(CS.UnityEngine.Animation))
    -- local clip = CS.UnityEngine.AnimationClip()
    -- clip.legacy = true

    -- curve = CS.UnityEngine.AnimationCurve()
    -- k1 = CS.UnityEngine.Keyframe(0.0, 0.0)
    -- -- k1.inTangent = 90
    -- -- k1.outTangent = -90
    -- -- k.inWeight = -1
    -- -- k.outWeight = -1
    -- -- k.weightedMode = CS.UnityEngine.WeightedMode.Both
    -- curve:AddKey(k1)
    -- k2 = CS.UnityEngine.Keyframe(1.0, 1.5)
    -- -- k2.inTangent = 90
    -- -- k2.outTangent = -90
    -- -- k.inWeight = -1
    -- -- k.outWeight = -1
    -- -- k.weightedMode = CS.UnityEngine.WeightedMode.Both
    -- curve:AddKey(k2)
    -- k3 = CS.UnityEngine.Keyframe(2.0, 0.0)
    -- -- k3.inTangent = 90
    -- -- k3.outTangent = -90
    -- -- k.inWeight = -1
    -- -- k.outWeight = -1
    -- -- k.weightedMode = CS.UnityEngine.WeightedMode.Both
    -- curve:AddKey(k3)

    -- -- curve:SmoothTangents(0, 0)
    -- -- curve:SmoothTangents(1, 0)
    -- -- curve:SmoothTangents(2, 0)
    
    -- clip:SetCurve("", typeof(CS.UnityEngine.Transform), "localPosition.x", curve)
    -- clip.wrapMode = CS.UnityEngine.WrapMode.Loop

    -- local ae = CS.UnityEngine.AnimationEvent()
    -- ae.functionName = "aaa"
    -- ae.time = 0.5
    -- clip:AddEvent(ae)

    -- ani:AddClip(clip, "standing")

    -- ani:Play("standing")
    
    -- luaBehaviour = self:GetComponent(typeof(CS.XLuaTest.LuaBehaviour))

    -- local t = luaBehaviour.scriptEnv

    -- print(t.moveSpeed)
    -- local ccc = utils.createObject(nil, 9, "cursor_test", 0, "cursor_test", 0, 0, 0, 0, 0, 0, 1)
    -- rawset(ccc, "controller", utils.PLAYER)

    -- utils.createUIObject(nil, 9, "UI_Test", 0, "UI_Test", 100, 0, 0, 0, 0, 0, 3)
    -- utils.createUIObject(nil, 9, "UI_Test", 0, "UI_Test", -100, 0, 0, 0, 0, 0, 3)


    -- local wepaon_table = {
    --                         {id = 9, animation = "UI_Test", data1 = "aim_weapon_HK416c", data2 = "weapon_idle_HK416c"},
    --                         {id = 9, animation = "UI_Test2", data1 = "aim_weapon", data2 = "weapon_idle"},
    --                         {id = 9, animation = "UI_Test3", data1 = "aim_weapon_J", data2 = "weapon_idle_J"}
    --                     }
    -- local weapons = utils.createUIObject(nil, 9, "UI_Test_Panel", 0, "UI_Test_Panel", 0, 50, 0, 0, 0, 0, 1)
    -- weapons.controller = utils.PLAYER

    -- for i, v in ipairs(wepaon_table) do
    --     local btn = utils.createUIObject(weapons, v.id, v.animation, 0, "UI_Button", (i - 2) * 100, 0, 0, 0, 0, 0, 3)

    --     btn.button.onClick:AddListener(function()
    --         utils.PLAYER.object.children["1"].children["0"]:changeState(v.data2)

    --         weapons.UI_object:SetActive(false)
    --         -- print(v.data1, v.data2)
    --         -- CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(phase.UIParts[idC].gameObject)
	-- 	end)
    -- end

    -- local ttt = utils.InstantiateFromDataBase(nil, 9, "UI_HP", 0, 0, 0, 0, 0, 0, nil, 1)

    -- bind(utils.PLAYER.object, "HP", function(this, value)
    --     local s = ttt.children["1"].rectTransform.sizeDelta
    --     s.x = utils.PLAYER.object.HP / utils.PLAYER.object.maxHP * 200
    --     ttt.children["1"].rectTransform.sizeDelta = s
    -- end)

    -- LObject_bit = utils.allOf(utils.getComponentID("Active"), utils.getComponentID("DataBase"), utils.getComponentID("SpriteRenderer"), utils.getComponentID("Physical"))
    -- UI_bit = utils.allOf(utils.getComponentID("Active"), utils.getComponentID("DataBase"), utils.getComponentID("UI"))

    -- 创建系统集合
    _update = {"JudgePlayerSystem", "AnimationSystem1", "StateUpdateSystem", "AnimationSystem2", "SpriteRenderSystem", "LineRenderSystem", "JudgeAISystem"}
    _fixedUpdate = {"StateFxiedUpdateSystem", "BDYSystem", "ATKSystem", "ResetAISystem", "ResetPlayerSystem", "SleepSystem"} -- , "PhysicsSystem"

    -- -- 创建一个实体
    -- for i = 1, 1, 1 do
    --     local id1 = ecs.newEntity()
    --     ecs.addComponent(id1, "Active")
    --     ecs.addComponent(id1, "DataBase", 9)
    --     ecs.addComponent(id1, "Image", nil)
    --     ecs.addComponent(id1, "Animation", "cursor_test")
    --     ecs.addComponent(id1, "State", "cursor_test")
    --     ecs.applyEntity(id1)
    -- end

    local ppp
    -- 创建一个实体
    for i = 1, 1, 1 do
        local id1 = ecs.newEntity()
        ecs.addComponent(id1, "Active")
        ecs.addComponent(id1, "DataBase", 9)
        ecs.addComponent(id1, "Children")
        ecs.addComponent(id1, "SpriteRenderer")
        ecs.addComponent(id1, "Animation", "body_idle_front")
        ecs.addComponent(id1, "State", "aim")
        ecs.addComponent(id1, "Physics", i + 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0)
        ecs.addComponent(id1, "BDY")
        ecs.addComponent(id1, "Gravity")

        utils.PLAYER = LPlayer:new(ecs.entities[id1], LMainCamera) -- LMainCamera:GetComponent(typeof(CS.UnityEngine.Camera))
        ecs.addComponent(id1, "Player")
        ppp = ecs.applyEntity(id1)


        local id2 = ecs.newEntity()
        ecs.addComponent(id2, "Active")
        ecs.addComponent(id2, "DataBase", 9)
        ecs.addComponent(id2, "SpriteRenderer")
        ecs.addComponent(id2, "Animation", "aim_right_hand")
        ecs.addComponent(id2, "State", "right_aim_hand")
        ecs.addComponent(id2, "Physics", i + 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0)
        ecs.addComponent(id2, "Parent", ppp, "1")
        local hand = ecs.applyEntity(id2)

        local id3 = ecs.newEntity()
        ecs.addComponent(id3, "Active")
        ecs.addComponent(id3, "DataBase", 9)
        ecs.addComponent(id3, "SpriteRenderer")
        ecs.addComponent(id3, "Animation", "aim_weapon_HK416c")
        ecs.addComponent(id3, "State", "weapon_idle_HK416c")
        ecs.addComponent(id3, "Physics", i + 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0)
        ecs.addComponent(id3, "Parent", hand, "0")
        ecs.applyEntity(id3)
    end

    -- 创建一个实体
    for i = 2, 2, 1 do
        local id1 = ecs.newEntity()
        ecs.addComponent(id1, "Active")
        ecs.addComponent(id1, "DataBase", 9)
        ecs.addComponent(id1, "SpriteRenderer")
        ecs.addComponent(id1, "Animation", "body_idle_front")
        ecs.addComponent(id1, "State", "aim")
        ecs.addComponent(id1, "Physics", i + 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0)
        ecs.addComponent(id1, "BDY")
        ecs.addComponent(id1, "AI")
        ecs.addComponent(id1, "Target", ppp)
        ecs.addComponent(id1, "Gravity")
        local eee = ecs.applyEntity(id1)

        ecs.addComponent(ppp._eid, "Target", eee)
        ecs.applyEntity(ppp._eid)
    end

    -- dump(ecs.getCache())
end

function update()
    -- -- 5104W!Js1jSR<|5DJ1:r
    -- if CS.UnityEngine.Input.GetMouseButton(1) then
    --     -- ;qH!Js1j5Dx:My5DV5#,3KRTKY6H:MTime.deltaTimeJGRrN*Ub8v?IRTJGTK6/Fp@48|F=;,
    --     local h = CS.UnityEngine.Input.GetAxis("Mouse X") * moveSpeed * CS.UnityEngine.Time.deltaTime;
    --     local v = CS.UnityEngine.Input.GetAxis("Mouse Y") * moveSpeed * CS.UnityEngine.Time.deltaTime;
    --     h = math.floor(h / 0.32 + 0.5) * 0.32
    --     v = math.floor(v / 0.32 + 0.5) * 0.32
    --     -- IhVC51G0IcOq;zRF6/
    --     -- PhR*IcOq;z04UUJ@=gWx1jRF6/#,6x2;JG04UUK|WTIm5DWx1jRF6/#,KyRT<SIOSpance.World
    --     LMainCamera.transform:Translate(-h, -v, 0, CS.UnityEngine.Space.World);
    -- end

    -- if CS.UnityEngine.Input.GetAxis("Mouse ScrollWheel") < 0 and zoom < 4 then
    --     zoom = zoom + 1
    --     camera.orthographicSize = CS.UnityEngine.Screen.height / 2 / 100 / zoom
    -- elseif CS.UnityEngine.Input.GetAxis("Mouse ScrollWheel") > 0 and zoom > 1 then
    --     zoom = zoom - 1
    --     camera.orthographicSize = CS.UnityEngine.Screen.height / 2 / 100 / zoom
    -- end

    -- player:followCharacter()
    -- player:input()
    -- player:judgeCommand()

    -- if system ~= nil then
        -- system:input()
        -- if system.object ~= nil then
        --     system:judgeCommand()
        -- end
        -- system:systemInput(player.object)
    -- end

    -- local deltaTime = CS.UnityEngine.Time.realtimeSinceStartup - lastTime
    -- utils.runObjectsFrame()

    -- print(deltaTime)

    -- lastTime = CS.UnityEngine.Time.realtimeSinceStartup

    -- utils.runObjectsUpdate()

    for _, v in ipairs(_update) do
        ecs.processMultipleSystem(v)
    end
end

function lateupdate()
    -- player:followCharacter()

    ecs.processMultipleSystem("FollowPlayerSystem")
end

function fixedupdate()
    -- mychar:runState()

    -- utils.runObjectsFixedupdate()
    -- if system.object ~= nil then
    --     system:resetCommands()
    -- end

    -- player:resetCommands()
    -- collectgarbage("collect")

    -- utils.UpdateBinding()
    for _, v in ipairs(_fixedUpdate) do
        ecs.processMultipleSystem(v)
    end
end

function ongui()
--    if CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.mouseDrag then
--        local x = CS.UnityEngine.Input.GetAxis("Mouse X");
--        local y = CS.UnityEngine.Input.GetAxis("Mouse Y");
--        LMainCamera.transform:Translate(CS.UnityEngine.Vector3( -x, -y, 0) * CS.UnityEngine.Time.deltaTime);
--    end

    -- ceshi
    -- if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.KeypadEnter and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
        -- print(k1.inTangent, k1.outTangent, k1.inWeight, k1.outWeight, k1.weightedMode)
        -- print(k2.inTangent, k2.outTangent, k2.inWeight, k2.outWeight, k2.weightedMode)
        -- print(k3.inTangent, k3.outTangent, k3.inWeight, k3.outWeight, k3.weightedMode)

    --     local kkk = curve.keys[1]
    --     print(kkk.inTangent, kkk.outTangent, kkk.inWeight, kkk.outWeight, kkk.weightedMode)
    -- end

	-- 热更新角色数据库
    if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.KeypadEnter and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
		readCharacterData()
		for i, v in pairs(utils.getObjects()) do
			v.database = utils.getIDData(v.id)
		end
	end

    -- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(10, CS.UnityEngine.Screen.height - 56, 200, 20), "LObjects: " .. ecs.total)
    -- utils.display()
    -- utils.displayObjectsInfo()

	for _, v in ipairs(_update) do
		CS.UnityEngine.GUILayout.Label(string.format("%s: %d", v, ecs.displayMultipleSystem(v)))
    end
    for _, v in ipairs(_fixedUpdate) do
		CS.UnityEngine.GUILayout.Label(string.format("%s: %d", v, ecs.displayMultipleSystem(v)))
	end
end

function ondestroy()
    print("lua destroy")
    console:Shutdown()
end

function readCharacterData()
    local data = castleDB:new(utils.resourcePathDataPath, "data.cdb")
    data:readDB()
    for i, v in ipairs(data:getLines("data")) do
        local p = utils.split(v.file, "/")

        local cdb = LCastleDBCharacter:new(utils.resourcePathDataPath .. p[1] .. "/", p[2])
        cdb:readDB()

        -- local p2 = utils.split(p[2], ".")
        utils.setIDData(v.id, cdb) -- {name = p2[1], db = cdb, textrue2ds = t, pics = s, audioClips = ac, palettes = pal}
    end
end
