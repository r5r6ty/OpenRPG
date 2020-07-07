-- local utils = require "LUtils"

local ecs = require "ecs"

-- 注册系统
-- 渲染sprite
ecs.registerMultipleSystem("SpriteRenderSystem", function(self)

    local pos_x, pos_y, pos_z = CS.LuaUtil.GetPos(self.physics_object_id)
    local r_pos_x, r_pos_y, r_pos_z = CS.LuaUtil.GetPos(self.root.physics_object_id)
    CS.LuaUtil.SetPos(self.pic_offset_object_id, pos_x, pos_y + pos_z, r_pos_z)

    self.rotation = self.rotation + self.rotation_velocity * self.speed

    local rrr_x, rrr_y, rrr_z = CS.LuaUtil.GetEulerAngles(self.physics_object_id)
    local rrr_length = utils.GetVector3Module(rrr_x, rrr_y, rrr_z)
    -- if (self.root == self and self.direction.x == 1) or (self.root ~= self and self.root.direction.x * self.direction.x == 1) then
    --     if rrr_length > 0 then
    --         CS.LuaUtil.SetRotationByEuler(self.pic_offset_object_id, 0, 0, 360 - rrr_y + self.rotation)
    --     else
    --         CS.LuaUtil.SetRotationByEuler(self.pic_offset_object_id, 0, 0, 0 + self.rotation)
    --     end
    -- else
    --     if rrr_length > 0 then
    --         CS.LuaUtil.SetRotationByEuler(self.pic_offset_object_id, 0, 180, rrr_y + 180 + self.rotation)
    --     else
    --         CS.LuaUtil.SetRotationByEuler(self.pic_offset_object_id, 0, 180, 0 + self.rotation)
    --     end
    -- end


    CS.LuaUtil.SetRotationByEuler(self.pic_offset_object_id, 0, rrr_y, self.rotation)
end, ecs.allOf("Active", "DataBase", "SpriteRenderer", "Physics"))

-- 渲染spine
ecs.registerMultipleSystem("SpineRenderSystem", function(self)

    local pos_x, pos_y, pos_z = CS.LuaUtil.GetPos(self.physics_object_id)
    local r_pos_x, r_pos_y, r_pos_z = CS.LuaUtil.GetPos(self.root.physics_object_id)
    CS.LuaUtil.SetPos(self.spine_offset_object_id, pos_x, pos_y + pos_z, r_pos_z)
end, ecs.allOf("Active", "DataBase", "SpineRenderer", "Physics"))

-- 渲染line
ecs.registerMultipleSystem("LineRenderSystem", function(self)
    
end, ecs.allOf("Active", "DataBase", "LineRenderer", "Physics"))

-- 动画1
ecs.registerMultipleSystem("AnimationSystem1", function(self)
    local frameDeltaTime = 1 / 60
    local maxFrameSkip = 4
    
    self.accumulatedTime = CS.UnityEngine.Time.deltaTime
    local frames = 0
    while self.accumulatedTime >= frameDeltaTime do
        frames = frames + 1
        if frames > maxFrameSkip then
            break
        end
        self.accumulatedTime = self.accumulatedTime - frameDeltaTime
    end

    if frames > 0 then
        local c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
        if c == nil then
            self.timeLine = self.timeLine - self.runtimeSkeletonAnimation.AnimationState:GetCurrent(0).Animation.Duration
            self.delayCounter = 0
            self.localTimeLine = 0
            c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
        end

        if self.timeLine >= c * frameDeltaTime then

            local f = self.database.animations[self.action].eventQueue[c]
            self.delayCounter = self.delayCounter + 1
            self.localTimeLine = 0
            if f ~= nil then
                for _, v in ipairs(f) do
                    -- self.database:invokeEvent(v.category, self, v)
                    ecs.processSingleSystem(v.category, self, v)
                end
            end
        end

        self.timeLine = self.timeLine + frames * frameDeltaTime * self.speed
        self.localTimeLine = self.timeLine + frames * frameDeltaTime * self.speed

        self.runtimeSkeletonAnimation:Update(frames * frameDeltaTime * self.speed)
        self.requiresNewMesh = true
    end

end, ecs.allOf("Active", "DataBase", "Animation", "SpineRenderer"))

ecs.registerMultipleSystem("SpineLateUpdate", function(self)

    if self.requiresNewMesh then
        self.runtimeSkeletonAnimation:LateUpdate()
        self.requiresNewMesh = false
    end

end, ecs.allOf("Active", "DataBase", "Animation", "SpineRenderer"))

-- 动画2
ecs.registerMultipleSystem("AnimationSystem2", function(self)
    -- if c < self.database.animations[self.action].delay then
    -- self.timeLine = self.timeLine + CS.UnityEngine.Time.deltaTime * self.speed
    -- self.localTimeLine = self.localTimeLine + CS.UnityEngine.Time.deltaTime * self.speed
    -- else
    -- 	self.delayCounter = 0
    -- 	self.timeLine = 0
    -- end
end, ecs.allOf("Active", "DataBase", "Animation"))

-- 状态更新
ecs.registerMultipleSystem("StateUpdateSystem", function(self)
    if self.state ~= nil then
        local st = self.database.characters_state[self.state]
        for _, v in ipairs(st.update) do
            if v.func == nil or v.func(self) then
                for __, v2 in ipairs(v.test) do
                    -- self.database:invokeEvent(v2.category, self, v2.json)
                    ecs.processSingleSystem(v2.category, self, v2.json)
                end
            end
        end
    end
end, ecs.allOf("Active", "DataBase", "State"))

-- 状态定时更新
ecs.registerMultipleSystem("StateFxiedUpdateSystem", function(self)
    local st = self.database.characters_state["global"]
    for _, v in ipairs(st.fixedUpdate) do
        if v.func == nil or v.func(self) then
            for __, v2 in ipairs(v.test) do
                -- self.database:invokeEvent(v2.category, self, v2.json)
                ecs.processSingleSystem(v2.category, self, v2.json)
            end
        end
    end
    if self.state ~= nil and self.state ~= "global" then
        st = self.database.characters_state[self.state]
        for _, v in ipairs(st.fixedUpdate) do
            if v.func == nil or v.func(self) then
                for __, v2 in ipairs(v.test) do
                    -- self.database:invokeEvent(v2.category, self, v2.json)
                    ecs.processSingleSystem(v2.category, self, v2.json)
                end
            end
        end
    end
end, ecs.allOf("Active", "DataBase", "State"))

-- 碰撞盒
ecs.registerMultipleSystem("BDYSystem", function(self)
    local f = 0
    for _, v in pairs(self.bodyArray) do
        self.isOnGround = v:BDYFixedUpdate()

        -- if self.isOnGround ~= -1 then

        --     if self.kind ~= 99 then
        --         self.velocity.y = -0.01
        --     end
        -- end
        f = f + 1
    end
    if f == 0 then
        local dt = CS.UnityEngine.Time.deltaTime * self.speed
        CS.LuaUtil.RigidbodyMovePosition(self.rigidbody, self.velocity.x * dt, self.velocity.y * dt, self.velocity.z * dt)
    end
    -- self.isOnGround = -1
    -- local dt = CS.UnityEngine.Time.deltaTime * self.speed
    -- local length = utils.GetVector3Module(self.velocity.x * dt, self.velocity.y * dt, self.velocity.z * dt) -- 射线的长度
    -- local dx = self.velocity.x * dt / length -- 方向
    -- local dy = self.velocity.y * dt / length -- 方向
    -- local dz = self.velocity.z * dt / length -- 方向

    -- local ishit, hitinfo = CS.LuaUtil.RigidbodySweepTest(self.rigidbody, dx, dy, dz, length)
    -- if ishit then
    --     local hx, hy, hz = CS.LuaUtil.RaycastHitGetPoint(hitinfo)
    --     local x, y, z = CS.LuaUtil.RigidbodyClosestPointOnBounds(self.rigidbody, hx, hy, hz)
    --     CS.LuaUtil.RigidbodyMovePosition(self.rigidbody, hx - x, hy - y, hz - z)
    --     local up, down, left, right, above, under = false, false, false, false, false, false
    --     local go = hitinfo.collider.attachedRigidbody.gameObject
    --     if go.name == "test" then -- 如果是地图块
    --         local name = utils.split(hitinfo.collider.name, ",")
    --         local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit
    --         if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
    --             up = true
    --         end
    --         if num & 2 == 2 then --位操作
    --             down = true
    --         end
    --         if num & 4 == 4 then --位操作
    --             left = true
    --         end
    --         if num & 8 == 8 then --位操作
    --             right = true
    --         end
    --         if num & 16 == 16 then --位操作
    --             above = true
    --         end
    --         if num & 32 == 32 then --位操作
    --             under = true
    --         end

    --         if up or down or left or right or above or under then
    --             if above or under then
    --                 self.isOnGround = 1
    --                 self.velocity.y = 0
    --             end
    --         end
    --     end
    -- else
    --     local dt = CS.UnityEngine.Time.deltaTime * self.speed
    --     CS.LuaUtil.RigidbodyMovePosition(self.rigidbody, self.velocity.x * dt, self.velocity.y * dt, self.velocity.z * dt)
    -- end

    if self.isOnGround ~= -1 then
        ecs.processSingleSystem("Ground", self)
    else
        ecs.processSingleSystem("Flying", self)
    end
end, ecs.allOf("Active", "Physics", "BDY"))

-- -- 物理
-- ecs.registerMultipleSystem("PhysicsSystem", function(self)
-- end, ecs.allOf("Active", "Physics"))

-- 攻击盒
ecs.registerMultipleSystem("ATKSystem", function(self)
    -- 攻击检测
    for _, v in pairs(self.attckArray) do
        v:ATKFixedUpdate()
    end

    -- if self.kind == 0 and self.root == self then
    -- 	dump(self, "", 1)
    -- 	self["HP"] = self["HP"] - 1
    -- 	if self.HP > 0 then
    -- 		self.database:invokeEvent("Live", self, nil)
    -- 	else
    -- 		self.database:invokeEvent("Dead", self, nil)
    -- 	end
    -- end
    self.oriPos.x, self.oriPos.y, self.oriPos.z = CS.LuaUtil.RigidbodyGetPosition(self.rigidbody)
end, ecs.allOf("Active", "Physics", "ATK"))

-- 休眠
ecs.registerMultipleSystem("SleepSystem", function(self)
    if utils.GetVector3Module(self.velocity.x, self.velocity.y, self.velocity.z) <= 0.3 then
        self.sleep = true
        ecs.removeComponent(self._eid, "Active")
        ecs.applyEntity(self._eid)
    end
end, ecs.allOf("Active", "DataBase", "Sleep"))

-- AI
ecs.registerMultipleSystem("JudgeAISystem", function(self)
    self.controller:judgeAI(self)
end, ecs.allOf("Active", "DataBase", "AI"))

-- AI
ecs.registerMultipleSystem("ResetAISystem", function(self)
    self.controller:resetCommands()
end, ecs.allOf("Active", "DataBase", "AI"))

-- Player
ecs.registerMultipleSystem("JudgePlayerSystem", function(self)
    self.controller:input()
    self.controller:judgeCommand()
end, ecs.allOf("Active", "DataBase", "Player"))

-- Player
ecs.registerMultipleSystem("FollowPlayerSystem", function(self)
    self.controller:followCharacter()
end, ecs.allOf("Active", "DataBase", "Player"))

-- Player
ecs.registerMultipleSystem("ResetPlayerSystem", function(self)
    self.controller:resetCommands()
end, ecs.allOf("Active", "DataBase", "Player"))

-- 子弹时间1
ecs.registerMultipleSystem("zidanshijianSystem", function(self, time)
    -- if self.team ~= nil and self.team == 1 and self == utils.PLAYER.object then

    -- elseif self.team ~= nil and self.team == 1 and self.root ~= nil and self.root == utils.PLAYER.object then

    -- else
        self.speed = time
        if self.audioSource ~= nil then
            self.audioSource.pitch = time
        end
    -- end
end, ecs.allOf("Active", "Animation"))


------------------------------------------------------------------------------------------------------------------------------------
ecs.registerSingleSystem("Live", function(this, value)
    -- self["HP"] = utils.toMaxvalue(self["HP"], self["maxHP"], self["HPRecoveryRate"])
    -- self["MP"] = utils.toMaxvalue(self["MP"], self["maxMP"], self["MPRecoveryRate"] + (self["MPRecoveryRate"] * (1 - self["HP"] / self["maxHP"])))
    -- self["falling"] = utils.toOne(self["falling"], self["maxFalling"], self["fallingRecoveryRate"])
    -- self["defencing"] = utils.toOne(self["defencing"], self["maxDefencing"], self["defencingRecoveryRate"])

    -- if self.target == nil then
    -- 	local temp = {}
    -- 	for i, v in pairs(utils.getObjects()) do
    -- 		if v ~= nil and v.kind == 0 and v ~= self and v["HP"] > 0 then
    -- 			table.insert(temp, v)
    -- 		end
    -- 	end
    -- 	self.target = temp[CS.Tools.Instance:RandomRangeInt(1, #temp + 1)]
    -- else
    -- 	if self.target["HP"] <= 0 then
    -- 		self.target = nil
    -- 	end
    -- end
end)
ecs.registerSingleSystem("Dead", function(this, value)
    utils.destroyObject(this.physics_object:GetInstanceID())
end)

ecs.registerSingleSystem("Flying", function(this, value)
    this.velocity.x = this.velocity.x + 0.5 * this.gravity.x * 2 / 60 * this.speed
    this.velocity.y = this.velocity.y + 0.5 * this.gravity.y * 2 / 60 * this.speed
    this.velocity.z = this.velocity.z + 0.5 * this.gravity.z * 2 / 60 * this.speed
    -- this.velocity.y = this.velocity.y + 0.5 * -9.81 * 2 / 60 / 3
end, ecs.allOf("Active", "Physics", "Gravity"))

ecs.registerSingleSystem("Ground", function(this, value)
    -- if this.isOnGround ~= 1 then
        local f_x = this.velocity.x * 0.2 -- 摩擦系数
        -- local f_y = this.velocity.y * 0.2 -- 摩擦系数
        local f_z = this.velocity.z * 0.2 -- 摩擦系数
        if this.velocity.x > 0 then
            this.velocity.x = this.velocity.x - f_x
            if this.velocity.x < 0 then
                this.velocity.x = 0
            end
        elseif this.velocity.x < 0 then
            this.velocity.x = this.velocity.x - f_x
            if this.velocity.x > 0 then
                this.velocity.x = 0
            end
        end

        if this.velocity.z > 0 then
            this.velocity.z = this.velocity.z - f_z
            if this.velocity.z < 0 then
                this.velocity.z = 0
            end
        elseif this.velocity.z < 0 then
            this.velocity.z = this.velocity.z - f_z
            if this.velocity.z > 0 then
                this.velocity.z = 0
            end
        end
    -- end
    -- if this.kind == 99 then
        -- if this.rotation > 0 then
        --     this.rotation_velocity = this.rotation_velocity / 2
        -- else
        --     this.rotation_velocity = this.rotation_velocity / 2
        -- end
    --     if this.velocity.magnitude <= 0.5 then
    --         this.sleep = true
    --     end
    -- end
end, ecs.allOf("Active", "SpineRenderer"))

ecs.registerSingleSystem("Sprite", function(this, value)
    if value.sprite == nil and value.id ~= nil then
        local ids = utils.split(value.id, ",")
        local c = this.spriteRenderer.material:GetTexture("_Palette"):GetPixel(tonumber(ids[CS.Tools.Instance:RandomRangeInt(1, #ids + 1)]), 0)
        this.trailRenderer.startColor = c
        this.trailRenderer.endColor = c
    else
        this.spriteRenderer.sprite = this.database.sprites[value.sprite]
        CS.LuaUtil.SetLocalPos(this.pic_object_id, value.x / 100, -value.y / 100, 0)
    end
end, ecs.allOf("Active", "DataBase", "SpriteRenderer"))

ecs.registerSingleSystem("Wait", function(this, value)
end, ecs.allOf("Active", "DataBase", "SpriteRenderer"))

ecs.registerSingleSystem("Image", function(this, value)
    if value.id == nil then
        this.image.sprite = this.database.sprites[value.sprite]
    else
        this.image.sprite = this.database.sprites[value.id]
    end

    local position = CS.UnityEngine.Vector2(0, 0)
    local size = CS.UnityEngine.Vector2(0, 0)
    local min = CS.UnityEngine.Vector2(0, 0)
    local max = CS.UnityEngine.Vector2(0, 0)
    local pivot = CS.UnityEngine.Vector2(0, 0)
    if value.horizontalAlignment == 0 then -- Left
        min.x = 0
        max.x = 0
        pivot.x = 0

        position.x = value.margin.left
        size.x = value.width
    elseif value.horizontalAlignment == 1 then -- Center
        min.x = 0.5
        max.x = 0.5
        pivot.x = 0.5

        position.x = value.x
        size.x = value.width
    elseif value.horizontalAlignment == 2 then -- Right
        min.x = 1
        max.x = 1
        pivot.x = 1

        position.x = -value.margin.right
        size.x = value.width
    elseif value.horizontalAlignment == 3 then -- Stretch
        min.x = 0
        max.x = 1
        pivot.x = 0.5

        position.x = value.margin.left
        size.x = position.x + value.margin.right
    end

    if value.verticalAlignment == 0 then -- Top
        min.y = 1
        max.y = 1
        pivot.y = 1

        position.y = -value.margin.top
        size.y = value.height
    elseif value.verticalAlignment == 1 then -- Center
        min.y = 0.5
        max.y = 0.5
        pivot.y = 0.5

        position.y = -value.y
        size.y = value.height
    elseif value.verticalAlignment == 2 then -- Bottom
        min.y = 0
        max.y = 0
        pivot.y = 0

        position.y = value.margin.bottom
        size.y = value.height
    elseif value.verticalAlignment == 3 then -- Stretch
        min.y = 0
        max.y = 1
        pivot.y = 0.5

        position.y = value.margin.bottom
        size.y = position.y + value.margin.top
    end

    this.rectTransform.anchorMin = min
    this.rectTransform.anchorMax = max

    this.rectTransform.pivot = pivot

    this.rectTransform.sizeDelta = size
    this.rectTransform.anchoredPosition = position

    -- this.rectTransform.offsetMin = position
    -- this.rectTransform.offsetMax = size

end, ecs.allOf("Active", "DataBase", "Image"))

ecs.registerSingleSystem("Text", function(this, value)
    this.text.text = value.text
    this.text.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
    this.text.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)
end)

ecs.registerSingleSystem("Button", function(this, value)
    this.image.sprite = this.database.sprites[value.sprite]
    this.image.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
    this.image.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)

    this.text.text = value.text
    -- this.text.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
    -- this.text.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)
end)

ecs.registerSingleSystem("Trace", function(this, value)
    -- local s = this.oriPos2
    -- local e = this.physics_object.transform.position
    -- this.lineRenderer:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
    -- this.lineRenderer:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))

    -- this.oriPos2 = this.physics_object.transform.position
end, ecs.allOf("Active", "DataBase", "LineRenderer"))

ecs.registerSingleSystem("Sound", function(this, value)
    this.audioSource.clip = this.database.audioClips[value.sfx]
    -- local r = math.random() / 2.5
    -- this.audioSource.pitch = 1 + r - 0.2
    this.audioSource:Play()
end, ecs.allOf("Active", "DataBase", "Sound"))

-- self:addEvent("Object", function(this, value)
-- 	if value.isWorldPosition then
-- 		utils.createObject(nil, this.id, value.action,value.frame, value.x, value.y, 0, 0, value.kind)
-- 	else
-- 		utils.createObject(nil, this.id, value.action, value.frame, this.rigidbody.position.x + value.x, this.rigidbody.position.y + value.y, 0, 0, value.kind)
-- 	end
-- end)

ecs.registerSingleSystem("Body", function(this, value)
    if this.bodyArray[value.id] == nil and not (value.width == 0 or value.height == 0) then
        this.bodyArray[value.id] = LColliderBDY:new(this, this.bdy_object, value.id)
        this.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.bodyFlags, value.layers, value.bounciness)
        -- this.bodyArray_InstanceID[this.bodyArray[value.id].collider2:GetInstanceID()] = this.bodyArray[value.id]
        this.bodyArray_InstanceID[this.bodyArray[value.id].collider:GetInstanceID()] = this.bodyArray[value.id]

        -- this.deubg_object.transform.localScale = CS.UnityEngine.Vector3(value.width / 100, value.height / 100, value.width / 100)
        -- this.deubg_object.transform.localPosition = CS.UnityEngine.Vector3((value.x + value.width / 2) / 100, -(value.y + value.height / 2) / 100, 0)
    else
        if this.bodyArray[value.id] ~= nil then
            if value.width == 0 or value.height == 0 then
                local IID = this.bodyArray[value.id].collider:GetInstanceID()
                this.bodyArray[value.id]:deleteCollider()
                this.bodyArray[value.id] = nil
                this.bodyArray_InstanceID[IID] = nil
            else
                -- this.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.bodyFlags, value.layers)
            end
        end
    end
end, ecs.allOf("Active", "BDY"))

ecs.registerSingleSystem("Attack", function(this, value)
    if this.attckArray[value.id] == nil and not (value.width == 0 or value.height == 0) then
        this.attckArray[value.id] = LColliderATK:new(this, this.atk_object, value.id)
        this.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.attackFlags,
                                                    value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, false, value.var,
                                                    value.action, value.frame)
    else
        if this.attckArray[value.id] ~= nil then
            if value.width == 0 or value.height == 0 then
                this.attckArray[value.id]:deleteCollider()
                this.attckArray[value.id] = nil
            else
                -- this.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.attackFlags,
                -- 										value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, value.ignoreFlag, value.var,
                -- 										value.action, value.frame)
            end
        end
    end
end, ecs.allOf("Active", "ATK"))

ecs.registerSingleSystem("Force", function(this, value)
    -- this.velocity.x = this.velocity.x + value.x
    -- this.velocity.y = this.velocity.y + value.y
    -- this.velocity.z = this.velocity.z + value.z
    local object = this.attckArray["0"].hitObject

    local spd = this.attckArray["0"].direction * 40 / 100

    object.velocity.x = object.velocity.x + spd.x
    object.velocity.y = object.velocity.y + spd.y
    object.velocity.z = object.velocity.z + spd.z
end)

ecs.registerSingleSystem("Hurt", function(this, value)
    this.HP = this.HP - value.damage
end)

-- self:addEvent("TurnRight", function(this, value)
-- 	if this.direction.x == -1 and this.target ~= nil and this.physics_object.transform.position.x - this.target.physics_object.transform.position.x < 0 then
-- 		this.direction.x = 1
-- 	end
-- 	if this.direction.x == 1 and this.target ~= nil and this.physics_object.transform.position.x - this.target.physics_object.transform.position.x >= 0 then
-- 		this.direction.x = -1
-- 	end
-- end)

ecs.registerSingleSystem("FlipX", function(this, value)
    this.direction.x = value.direction_x

    if this.direction.x == 1 then
        CS.LuaUtil.SetRotationByEuler(this.physics_object_id, 0, 0, 0)
    else
        CS.LuaUtil.SetRotationByEuler(this.physics_object_id, 0, 180, 0)
    end
end, ecs.allOf("Active", "DataBase", "Physics"))

ecs.registerSingleSystem("Mouse", function(this, value)
    local mousePos = CS.UnityEngine.Input.mousePosition
    -- mousePos.z = v3.z
    local worldPos = utils.CAMERA:ScreenToWorldPoint(mousePos)
    this.physics_object.transform.position = CS.UnityEngine.Vector3(worldPos.x, 0, worldPos.y - utils.PLAYER.object.physics_object.transform.position.y)
end)
-- this:frameLoop() -- ????

-- this.animation:Play(this.action)
-- this.functions = CS.Tools.Instance:GetAnimationState(this.animation, this.action)

ecs.registerSingleSystem("State", function(this, value)
    utils.changeState(this, value.state, value.spineAnimation)
end, ecs.allOf("Active", "Animation", "State", "SpineRenderer"))

ecs.registerSingleSystem("Aim", function(this, value)
    local mousePosition = CS.UnityEngine.Input.mousePosition
    local worldMousePosition = CS.UnityEngine.Camera.main:ScreenToWorldPoint(mousePosition)

    local skeletonSpacePoint = this.runtimeSkeletonAnimation.transform:InverseTransformPoint(worldMousePosition)

    skeletonSpacePoint.x = skeletonSpacePoint.x * 1 --this.runtimeSkeletonAnimation.Skeleton.ScaleX
    skeletonSpacePoint.y = skeletonSpacePoint.y * 1 --this.runtimeSkeletonAnimation.Skeleton.ScaleY

    this.bone:SetLocalPosition(skeletonSpacePoint)
end, ecs.allOf("Active", "Animation", "State", "SpineRenderer"))

ecs.registerSingleSystem("Animation", function(this, value)
    utils.changeAnimation(this, value.animation)
end, ecs.allOf("Active", "Animation"))

ecs.registerSingleSystem("Child", function(this, value)
    local object = this.children[value.id]
    if object ~= nil then
        if value.rotation ~= nil then
            object.rotation = value.rotation
        end

        -- if value.direction_x ~= nil then
        --     object.direction.x = value.direction_x
        -- end

        if value.animation ~= nil then
            utils.changeAnimation(object, value.animation)
        end

        -- local z = value.layer / 100
        -- if this.root.direction.x == -1 then
        -- 	z = -z
        -- end
        -- object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, z)

        CS.LuaUtil.SetLocalPos(object.physics_object_id, value.x / 100, value.y / 100, 0)

        object.spriteRenderer.sortingOrder = -(value.layer * this.root.direction.z - this.spriteRenderer.sortingOrder)
    end
end)

ecs.registerSingleSystem("MoveAC", function(this, value)
    this.accvvvY = value.id
end)

ecs.registerSingleSystem("Move", function(this, value)
    if value.x ~= nil then
        this.velocity.x = value.x
    end
    if value.y ~= nil then
        this.velocity.y = value.y
    end
    if value.z ~= nil then
        this.velocity.z = value.z
    end
    -- this.rigidbody.position = this.rigidbody.position + CS.UnityEngine.Vector2(v.x, v.y) * CS.UnityEngine.Time.deltaTime
    -- this.gameObject.transform.position = this.gameObject.transform.position + CS.UnityEngine.Vector3(v.x, v.y, 0) * CS.UnityEngine.Time.deltaTime
end, ecs.allOf("Active", "Physics"))

ecs.registerSingleSystem("Set", function(this, value)
    value.func(this)
end)

ecs.registerSingleSystem("TurnToTarget", function(this, value)
    if this.root.target ~= nil then
        local r_pos_x, r_pos_y, r_pos_z = CS.LuaUtil.GetPos(this.root.target.physics_object_id)
        -- 如果目标是指针，就要减去枪的高度
        if this.root.target.state == "cursor" then
            local object = this.children[value.id]
            if object ~= nil then
                local lopos_x, lopos_y, lopos_z = CS.LuaUtil.GetLocalPos(this.physics_object_id)
                r_pos_z = r_pos_z - lopos_y * 2 + value.y / 100 * 2
            end
        end
        local pos_x, pos_y, pos_z = CS.LuaUtil.GetPos(this.physics_object_id)
        local rad = CS.UnityEngine.Mathf.Atan2(pos_z - r_pos_z, pos_x - r_pos_x)

        local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180

        local root = this.root
        if root ~= nil then

            -- if root.direction.x == -1 then
            -- 	deg = -(360 - rad * CS.UnityEngine.Mathf.Rad2Deg)
            -- end
            CS.LuaUtil.SetLocalRotationByEuler(this.physics_object_id, 0, -deg, 0)
        end
    end
end, ecs.allOf("Active", "Physics"))

ecs.registerSingleSystem("MoveToTarget", function(this, value)
    if this.target ~= nil then

        local r_pos_x, r_pos_y, r_pos_z = CS.LuaUtil.GetPos(this.target.physics_object_id)
        local pos_x, pos_y, pos_z = CS.LuaUtil.GetPos(this.physics_object_id)

        local x = r_pos_x - pos_x
        local y = r_pos_y - pos_y
        local z = r_pos_z - pos_z
        
		local length = utils.GetVector3Module(x, y, z) -- 射线的长度
		local dx = x / length -- 方向
		local dy = y / length -- 方向
        local dz = z / length -- 方向

        local length2 = utils.GetVector3Module(this.velocity.x, this.velocity.y, this.velocity.z) -- 射线的长度
		local dx2 = this.velocity.x / length2 -- 方向
		local dy2 = this.velocity.y / length2 -- 方向
        local dz2 = this.velocity.z / length2 -- 方向
        this.velocity.x = this.velocity.x - dx2 * value.speed * this.speed
        this.velocity.y = this.velocity.y - dy2 * value.speed * this.speed
        this.velocity.z = this.velocity.z - dz2 * value.speed * this.speed

        this.velocity.x = this.velocity.x + dx * value.speed * this.speed
        this.velocity.y = this.velocity.y + dy * value.speed * this.speed
        this.velocity.z = this.velocity.z + dz * value.speed * this.speed
    end
end, ecs.allOf("Active", "Physics", "Target"))

ecs.registerSingleSystem("Ray", function(this, value)
    local hitinfo = nil
    local s = nil
    local e = nil

    local first = nil
    if this.physics_object.transform.childCount > 1 + 1 then
        first = this.physics_object.transform:GetChild(2)
    else
        first = CS.UnityEngine.GameObject("debug_1")
        first.transform.parent = this.physics_object.transform
    end
    if first ~= nil then
        local flag, lr = first:TryGetComponent(typeof(CS.UnityEngine.LineRenderer))

        if not flag then
            lr = first:AddComponent(typeof(CS.UnityEngine.LineRenderer))

            lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
            lr.startWidth = 0.02
            lr.endWidth = 0.02

            -- local color = CS.UnityEngine.Color.green
            local color = CS.UnityEngine.Color.red

            lr.startColor = color
            color.a = 0
            lr.endColor = color
            lr.numCapVertices = 90
            lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

            -- lr.useWorldSpace = false
        end

        if lr ~= nil then
            local r = this.physics_object.transform.rotation
            -- local r = CS.UnityEngine.Quaternion.Euler(r2.x, r2.z, r2.y)
            -- pos = r * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

            -- pos = CS.UnityEngine.Quaternion.Euler() * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

            -- hitinfo = CS.Tools.Instance:PhysicsRaycastAll(pos + this.rigidbody.position, this.gameObject.transform.right, 25, 15)

            -- local gen = pos + this.physics_object.transform.position
            local gen = this.physics_object.transform:TransformPoint(CS.UnityEngine.Vector3(v.x / 100, -v.y / 100, 0))

            hitinfo = CS.Tools.Instance:PhysicsRaycast(gen, this.physics_object.transform.right, 25, 1048575)
            -- local t_pos = this.root.target.gameObject.transform.position
            -- local offset = t_pos - (pos + this.rigidbody.position)
            -- hitinfo = CS.Tools.Instance:PhysicsRaycast(pos + this.rigidbody.position, offset.normalized, offset.magnitude, 15)

            if hitinfo.collider ~= nil then
                s = gen
                e = hitinfo.point
                -- lr:SetPosition(0, s)
                -- lr:SetPosition(1, e)
                lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
                lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
            else
                s = gen
                e = gen + this.physics_object.transform.right * 25
                -- lr:SetPosition(0, s)
                -- lr:SetPosition(1, e)
                lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
                lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
            end
        end
    end

    -- local second = nil
    -- if this.physics_object.transform.childCount > 2 + 1 then
    -- 	second = this.physics_object.transform:GetChild(3)
    -- else
    -- 	second = CS.UnityEngine.GameObject("debug_2")
    -- 	second.transform.parent = this.physics_object.transform
    -- end
    -- if second ~= nil then
    -- 	local flag, lr = second:TryGetComponent(typeof(CS.UnityEngine.LineRenderer))

    -- 	if not flag then
    -- 		lr = second:AddComponent(typeof(CS.UnityEngine.LineRenderer))

    -- 		lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
    -- 		lr.startWidth = 0.02
    -- 		lr.endWidth = 0.02

    -- 		local color = CS.UnityEngine.Color.red

    -- 		lr.startColor = color
    -- 		color.a = 0
    -- 		lr.endColor = color
    -- 		lr.numCapVertices = 90
    -- 		lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

    -- 		-- lr.useWorldSpace = false
    -- 	end

    -- 	if lr ~= nil then
    -- 		lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
    -- 		lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
    -- 	end
    -- end
end)

ecs.registerSingleSystem("Object", function(this, value)
    local d = this.root.direction.x
    
    for i2 = 1, value.amount, 1 do

        local r = CS.Tools.Instance:RandomRangeInt(0, value.precise + 1) - value.precise / 2

        local rot = nil
        local velocityyy = nil
        local offset = nil
        if value.amount > 1 then
        	offset = CS.Tools.Instance:RandomRangeInt(0, value.x2 / 2)
        else
            offset = 0
        end

        local randomvector = CS.UnityEngine.Vector3(0, CS.Tools.Instance:RandomRangeFloat(0, 1), CS.Tools.Instance:RandomRangeFloat(0, 1)).normalized

        rot = CS.UnityEngine.Quaternion.AngleAxis(r, randomvector) * this.physics_object.transform.rotation 

        velocityyy = rot * (CS.UnityEngine.Vector3(value.x2 - offset, value.y2, value.z2) * CS.Tools.Instance:RandomRangeFloat(0.9, 1))

        local pos = this.physics_object.transform.rotation * CS.UnityEngine.Vector3(value.x / 100 * 2, -value.y / 100 * 2, 0)

        -- local kk = nil
        -- if value.animation == "shell1" or value.animation == "shell2" then
        --     kk = 99
        -- else
        --     kk = 5
        -- end
        -- local object = utils.createObject(nil, tonumber(value.id), value.animation, 0, value.state, this.rigidbody.position.x + pos.x, this.rigidbody.position.y + pos.y, this.rigidbody.position.z + pos.z, velocityyy.x, velocityyy.y, velocityyy.z, kk)

        -- local id2 = ecs.newEntity()
        -- ecs.addComponent(id2, "Active")
        -- ecs.addComponent(id2, "DataBase", 9)
        -- ecs.addComponent(id2, "SpriteRenderer")
        -- ecs.addComponent(id2, "Animation", "shell2")
        -- ecs.addComponent(id2, "State", "shell2")
        -- ecs.addComponent(id2, "Physics", this.rigidbody.position.x + pos.x, this.rigidbody.position.y + pos.y, this.rigidbody.position.z + pos.z, velocityyy.x, velocityyy.y, velocityyy.z)
        -- ecs.addComponent(id2, "BDY")
        -- ecs.addComponent(id2, "Sleep")
        -- local object = ecs.applyEntity(id2)
        local object = this.database.groups[value.animation](this.rigidbody.position.x + pos.x, this.rigidbody.position.y + pos.y, this.rigidbody.position.z + pos.z, velocityyy.x, velocityyy.y, velocityyy.z, this.team, this.root.target)
        object.spriteRenderer.material = this.spriteRenderer.material



        -- object.team = this.team
        -- local lr = object.pic_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
        -- -- lr.enabled = false
        -- lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
        -- lr.startWidth = 0.01
        -- lr.endWidth = 0.02

        -- local rc = CS.Tools.Instance:RandomRangeInt(0, #v.colors) + 1
        -- local color = CS.Tools.Instance:ColorTryParseHtmlString("#" .. string.format("%X", v.colors[rc].color))

        -- lr.startColor = color
        -- lr.endColor = color
        -- lr.numCapVertices = 90
        -- lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

        object.direction.x = d

        object.physics_object.transform.rotation = rot

        -- object.rotation = rot.eulerAngles.z
        
    end
end, ecs.allOf("Active", "DataBase"))

ecs.registerSingleSystem("Object2", function(this, value)
    local object = this.database.groups[value.animation](this.rigidbody.position.x + value.x, this.rigidbody.position.y + value.y, this.rigidbody.position.z + 0, value.x2, value.y2, value.z2, this.team, this.root.target)
    object.spriteRenderer.material = this.spriteRenderer.material
end, ecs.allOf("Active", "DataBase"))

ecs.registerSingleSystem("Rotation", function(this, value)
    if this.rotation_velocity == 0 then
        this.rotation_velocity = value.y2
    end
end, ecs.allOf("Active", "SpriteRenderer"))

ecs.registerSingleSystem("Destory", function(this, value)
    -- utils.destroyObject(this.physics_object:GetInstanceID())
    ecs.deleteEntity(this._eid)
end)

ecs.registerSingleSystem("OnClick", function(this, value)
    utils.invokeEvent("OnClick", this)
end)



------------------------------------------------------------------------------------------------------------------

-- ecs.registerSingleSystem("SetParentAndRoot", function (self, object)
-- 	if object ~= nil and (self.physics_object.transform.parent == nil or self.physics_object.transform.parent ~= self.physics_object.transform) then

-- 		self.physics_object.transform:SetParent(object.physics_object.transform)
-- 		self.rigidbody.isKinematic = true
-- 		self.parent = object
-- 		if object.parent ~= nil then
-- 			self.root = object.parent
-- 		else
-- 			self.root = object
-- 		end
-- 		self.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)

-- 		self.team = object.team
-- 		self.spriteRenderer.material = object.spriteRenderer.material
-- 	end
-- end)