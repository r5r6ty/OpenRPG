LMap = require "LMap"
utils = require "LUtils"
require "LObject_Gun"
require "LUIObject"

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

local _update
local _fixedUpdate

local luaBehaviour = nil

local console = nil

local LObject_bit
local UI_bit

-- local nata = require "nata"
local fangorn = require("fangorn")
local forest

local pool

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

    forest = fangorn.forest.new()
    forest:definebranch("DB", {}, function(id, idx)
        local self = {}
        self.database = utils.getIDData(id)
        self.id = id

        self.team = 0

        self.root = idx
        self.parent = idx
        self.children = {}

        self.rotation = 0
        self.rotation_velocity = 0

        self.direction = {x = 1, y = -1, z = 1}
        return self
    end)
    forest:definebranch("Physics", {}, function(x, y, z, vx, vy, vz)
        local self = {}
        self.physics_object = CS.UnityEngine.GameObject("physics")
        -- self.physics_object.transform:SetParent(self.gameObject.transform)
        self.physics_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
        self.physics_object.transform.position = CS.UnityEngine.Vector3(x, y, z)
        -- self.physics_object.transform.localPosition = CS.UnityEngine.Vector3.zero
        -- self.physics_object.transform.localScale = CS.UnityEngine.Vector3.one

        self.rigidbody = self.physics_object:AddComponent(typeof(CS.UnityEngine.Rigidbody))
        -- self.rigidbody.useGravity = false
        self.rigidbody.isKinematic = true
        -- self.rigidbody.detectCollisions = false
        self.rigidbody.freezeRotation = true

        self.rigidbody_id = self.rigidbody:GetInstanceID()
        CS.LuaUtil.AddID2(self.rigidbody_id, self.rigidbody)




        -- self.velocity = {x = vx, y = vy, z = vz}
        self.velocity = CS.UnityEngine.Vector3(vx, vy, vz)
        return self
    end)
    forest:definebranch("Render", {"DB", "Physics"}, function()
        local self = {}
    	self.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
    	self.pic_offset_object_id = self.pic_offset_object:GetInstanceID()
    	CS.LuaUtil.AddGameObjectID(self.pic_offset_object_id, self.pic_offset_object)
    	-- self.pic_offset_object.transform:SetParent(self.gameObject.transform)
    	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
    	self.pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3.zero
    	-- self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3.one
    	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)

    	self.audioSource = self.pic_offset_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
    	self.audioSource.playOnAwake = false

    	self.pic_object = CS.UnityEngine.GameObject("pic")
    	self.pic_object_id = self.pic_object:GetInstanceID()
    	CS.LuaUtil.AddGameObjectID(self.pic_object_id, self.pic_object)
    	self.pic_object.transform:SetParent(self.pic_offset_object.transform)
    	self.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
    	self.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
    	self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
    	-- self.spriteRenderer.material = self.database.palettes[1]
        return self
    end)
    forest:definebranch("Animation", {"DB"}, function(a)
        local self = {}
    	self.action = a
        self.delayCounter = 0
    	self.speed = 1
    	self.timeLine = 0
    	self.localTimeLine = 0
        return self
    end)

    local e = forest:growent()
    forest:growbranch2(e, "Render", {9, forest:getidx(e)}, {1 + 0.2 + 2, 0.32 + 1, -2.7 + 0, 0, 0, 0})
    forest:growbranch2(e, "Animation", nil, {"body_idle_front"})

    -- dump(e, "e", 2)
end

function update()

    -- player:input()
    -- player:judgeCommand()

    forest:each2("Animation", function(e, Animation, DB)
		-- if self.action ~= nil then
        local c = DB.database.animations[Animation.action].keyframes[Animation.delayCounter + 1]


        if c == nil then
            Animation.delayCounter = 0
            Animation.timeLine = 0
            Animation.localTimeLine = 0
            c = DB.database.animations[Animation.action].keyframes[Animation.delayCounter + 1]
        end

        -- if self.kind == 5 and self.state ~= "cursor" then
        -- 	print(self.delayCounter, self.timeLine)
        -- end
        if Animation.timeLine >= c * (1 / 60) then

            local f = DB.database.animations[Animation.action].eventQueue[c]
            Animation.delayCounter = Animation.delayCounter + 1
            Animation.localTimeLine = 0
            if f ~= nil then
                for i, v in ipairs(f) do
                    -- DB.database:invokeEvent(v.category, self, v)
                end
            end

        end
    -- end

    -- if c < self.database.animations[self.action].delay then
    Animation.timeLine = Animation.timeLine + CS.UnityEngine.Time.deltaTime * Animation.speed
    Animation.localTimeLine = Animation.localTimeLine + CS.UnityEngine.Time.deltaTime * Animation.speed
    -- else
    -- 	self.delayCounter = 0
    -- 	self.timeLine = 0
    -- end
    end)

    forest:each2("Render", function(e, Render, DB, Physics)
        local root = forest:gete(DB.root)
        -- dump(DB, "DB", 1)
        -- dump(Physics, "Physics", 1)
        -- dump(Render, "Render", 1)
		local pos = Physics.physics_object.transform.position
		CS.LuaUtil.SetPos(Render.pic_offset_object_id, pos.x, pos.y + pos.z, root.Physics.physics_object.transform.position.z)

		DB.rotation = DB.rotation + DB.rotation_velocity

		local rrr = Physics.physics_object.transform.eulerAngles
		if (root == e and DB.direction.x == 1) or (root ~= e and root.DB.direction.x * DB.direction.x == 1) then
			if rrr.magnitude > 0 then
				CS.LuaUtil.SetRotationEuler(Render.pic_offset_object_id, 0, 0, 360 - rrr.y + DB.rotation)
			else
				CS.LuaUtil.SetRotationEuler(Render.pic_offset_object_id, 0, 0, 0 + DB.rotation)
			end
		else
			if rrr.magnitude > 0 then
				CS.LuaUtil.SetRotationEuler(Render.pic_offset_object_id, 0, 180, rrr.y + 180 + DB.rotation)
			else
				CS.LuaUtil.SetRotationEuler(Render.pic_offset_object_id, 0, 180, 0 + DB.rotation)
			end
		end 
    end)

end

function lateupdate()
    -- player:followCharacter()
end

function fixedupdate()

    -- player:resetCommands()
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

    utils.display()
    -- utils.displayObjectsInfo()
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
