LMap = require "LMap"
utils = require "LUtils"
require "LObject"
require "LObject2"
require "LPlayer"

local k1, k2, k3 = nil
local curve = nil

local moveSpeed = 32
local camera = nil

local zoom = 1
local dataTable = nil

local mychar = nil

local player = nil
local system = nil

local lastTime = CS.UnityEngine.Time.realtimeSinceStartup

local luaBehaviour = nil

function start()
	print("lua start...")
    print("injected object", LMainCamera)
    print("injected object", LCanvas)
    camera = LMainCamera:GetComponent(typeof(CS.UnityEngine.Camera))
    camera.orthographicSize = CS.UnityEngine.Screen.height / 1 / 100 / zoom
    utils.CAMERA = camera
    
    utils.LUABEHAVIOUR = self:GetComponent(typeof(CS.XLuaTest.LuaBehaviour))

    -- 读取CSV的Tile信息
--    dataTable = utils.LoadTilesFromCSV(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/1/Resource/" .. "tile_data.csv")

    utils.loadfont2() -- 载入字体

    readCharacterData() -- 载入角色数据


    -- 读取LMap的json的测试
    LMap.new(CS.UnityEngine.Application.dataPath .. "/0/StreamingAssets/Resource/", "data2.cdb")
    -- LMap.show(1, 0, 0)

	local ds = LMap.gen3(-40 * 0.2, 20 * 0.2, 2)

    -- LMap.gen()

    utils.CURSOR = utils.createObject(nil, 9, "cursor", 0, 0, 0, 0, 0, 0)

    local t = utils.CURSOR

    local f = {}

    for i = 100, 99, -1 do
        -- 生成测试用角色
        local p, sid = utils.createObject(nil, 9, "body_idle_front", 0, i - 100, 0, 0, 0, 0)
        mychar = p

        mychar.speed = (100 - i) / 100 + 1
        mychar:changeState("aim")
        mychar.target = t
        t = mychar

        mychar.children["0"] = utils.createObject(nil, 9, "aim_left_hand", 0, 0, 0, 0, 0, 0)
        mychar.children["0"]:SetParentAndRoot(mychar)

        mychar.children["0"]:changeState("aim_hand")


        mychar.children["1"] = utils.createObject(nil, 9, "aim_right_hand", 0, 0, 0, 0, 0, 0)
        mychar.children["1"]:SetParentAndRoot(mychar)

        mychar.children["1"]:changeState("aim_hand")


        mychar.children["1"].children["0"] = utils.createObject(nil, 9, "aim_weapon", 0, 0, 0, 0, 0, 0)
        mychar.children["1"].children["0"]:SetParentAndRoot(mychar.children["1"])
        mychar.children["1"].children["0"]:changeState("weapon_idle")

        -- CS.Tools.Instance:GetAnimationState(p.animation, "body_run_front").speed = (100 - i) / 100 + 1

        table.insert(f, mychar)
    end
    mychar = f[1]



    -- mychar = LObjectController:new(nil, 9, "aim_back", 0, 0, 0, 0, 0, 0)


    player = LPlayer:new(mychar, LMainCamera) -- LMainCamera:GetComponent(typeof(CS.UnityEngine.Camera))
	system = LSystem:new(nil)
	utils.setLSystem(system)


    utils.PLAYER = player
    
    mychar.controller = utils.PLAYER

    -- -- 测试动画

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

end

function update()
    -- -- 当按住鼠标右键的时候
    -- if CS.UnityEngine.Input.GetMouseButton(1) then
    --     -- 获取鼠标的x和y的值，乘以速度和Time.deltaTime是因为这个可以是运动起来更平滑
    --     local h = CS.UnityEngine.Input.GetAxis("Mouse X") * moveSpeed * CS.UnityEngine.Time.deltaTime;
    --     local v = CS.UnityEngine.Input.GetAxis("Mouse Y") * moveSpeed * CS.UnityEngine.Time.deltaTime;
    --     h = math.floor(h / 0.32 + 0.5) * 0.32
    --     v = math.floor(v / 0.32 + 0.5) * 0.32
    --     -- 设置当前摄像机移动
    --     -- 需要摄像机按照世界坐标移动，而不是按照它自身的坐标移动，所以加上Spance.World
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
	player:input()
	player:judgeCommand()

	if system ~= nil then
		-- system:input()
		-- if system.object ~= nil then
		-- 	system:judgeCommand()
		-- end
		-- system:systemInput(player.object)
    end

    -- local deltaTime = CS.UnityEngine.Time.realtimeSinceStartup - lastTime
    -- utils.runObjectsFrame()

    -- print(deltaTime)

    -- lastTime = CS.UnityEngine.Time.realtimeSinceStartup

    utils.runObjectsFrame2()
end

function lateupdate()
    player:followCharacter()
end

function fixedupdate()
    -- mychar:runState()

    utils.runObjectsFrame()
	-- if system.object ~= nil then
	-- 	system:resetCommands()
	-- end
    player:resetCommands()
    
    -- collectgarbage("collect")
end

function ongui()
--    if CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.mouseDrag then
--        local x = CS.UnityEngine.Input.GetAxis("Mouse X");
--        local y = CS.UnityEngine.Input.GetAxis("Mouse Y");
--        LMainCamera.transform:Translate(CS.UnityEngine.Vector3( -x, -y, 0) * CS.UnityEngine.Time.deltaTime);
--    end

	-- ceshi
	if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.KeypadEnter and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
        -- print(k1.inTangent, k1.outTangent, k1.inWeight, k1.outWeight, k1.weightedMode)
        -- print(k2.inTangent, k2.outTangent, k2.inWeight, k2.outWeight, k2.weightedMode)
        -- print(k3.inTangent, k3.outTangent, k3.inWeight, k3.outWeight, k3.weightedMode)

        local kkk = curve.keys[1]
        print(kkk.inTangent, kkk.outTangent, kkk.inWeight, kkk.outWeight, kkk.weightedMode)
	end
end

function ondestroy()
    print("lua destroy")
end

-- 读取角色数据库
function readCharacterData()
	local data = castleDB:new(utils.resourcePathDataPath, "data.cdb")
	data:readDB()
	for i, v in ipairs(data:getLines("data")) do
		local p = utils.split(v.file, "/")

		local cdb = nil
		if v.kind == 5 then
			cdb = LCastleDBCharacter_new:new(utils.resourcePathDataPath .. p[1] .. "/", p[2])
		else
			cdb = LCastleDBCharacter:new(utils.resourcePathDataPath .. p[1] .. "/", p[2])
		end
        cdb:readDB()

		-- local p2 = utils.split(p[2], ".")
        utils.setIDData(v.id, cdb) -- {name = p2[1], db = cdb, textrue2ds = t, pics = s, audioClips = ac, palettes = pal}
	end
end

function playanimationevent(go, ae)
    local object = utils.getObject(go:GetInstanceID())
    object:playAnimationEvent(ae.stringParameter, ae.intParameter)
end

function onAnimatorIK(layerIndex)
    print(layerIndex)
end