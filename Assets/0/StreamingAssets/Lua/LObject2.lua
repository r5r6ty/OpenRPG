-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

utils = require "LUtils"
require "LCollider"
-- local cs_coroutine = (require 'cs_coroutine')

-- 每物理帧调用 执行事件
function LObject:runEvent()

	self.action = self.nextAction
	self.delayCounter = self.nextDelayCounter

	if self.delayCounter < self.database.animations[self.action].delay then
		local f = self.database.animations[self.action].eventQueue[self.delayCounter]
		-- self.delayCounter = self.delayCounter + 1
		self.nextDelayCounter = self.delayCounter + 1
		if f ~= nil then
			for i, v in ipairs(f) do
				self:invokeEvent("on" .. v.category, v)
			end
		end
	else
		-- self.delayCounter = 0
		self.nextDelayCounter = 0
	end
end

function LObject:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	setmetatable(self, LObject)
	self.eventQueue = {}
	self.eventManager = {}

    self.database = db
	self.id = id
	self.action = a
	self.nextAction = self.action
	self.frame = f
	self.delay = 0
	self.delayCounter = 0
	self.nextDelayCounter = self.delayCounter

	self.parent = nil
	self.root = nil
	self.animation = nil
	self.speed = 1

	for _i, _v in ipairs(self.database:getLines("vars")) do
		self[_v.name] = _v.default
		-- print(_v.name, self[_v.name])
	end

	-- self.functions = {}
	-- for _i, _v in ipairs(self.database:getLines("functions")) do
	-- 	self.functions[_v.name] = _v.value
	-- end

	self["parent"] = parent

	if k ~= 5 then
		self["story"] = self.database:getLines("story")
	end

	self.direction = CS.UnityEngine.Vector2(1, -1)
	self.directionBuff = CS.UnityEngine.Vector2(1, -1)

	self.velocity = CS.UnityEngine.Vector2(vx, vy)

	self.gameObject = go

	self.kind = k
	
	self.gameObject:AddComponent(typeof(CS.GameAnimation)).luaBehaviour = utils.LUABEHAVIOUR

	self.animation = self.gameObject:AddComponent(typeof(CS.UnityEngine.Animation))
	for _i, _v in pairs(self.database.animationClips) do
		
		self.animation:AddClip(_v, _v.name)
	end
	-- self.animation.animatePhysics = true

	self.audioSource = self.gameObject:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.rigidbody = self.gameObject:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
	self.rigidbody.bodyType = CS.UnityEngine.RigidbodyType2D.Kinematic
	-- self.rigidbody.collisionDetectionMode = CS.UnityEngine.CollisionDetectionMode2D.Continuous
	-- self.rigidbody.sleepMode = CS.UnityEngine.RigidbodySleepMode2D.NeverSleep
	-- self.rigidbody.interpolation = CS.UnityEngine.RigidbodyInterpolation2D.Interpolate
	self.rigidbody.constraints = CS.UnityEngine.RigidbodyConstraints2D.FreezeRotation
	self.rigidbody.gravityScale = 0
	-- self.rigidbody.useAutoMass = true

	self.vvvX = nil
	self.vvvY = nil
	self.accvvvX = nil
	self.accvvvY = nil

	-- self:frameLoop() -- 先执行帧

	-- self.animation:Play(self.action)
	-- self.functions = CS.Tools.Instance:GetAnimationState(self.animation, self.action)
	self.frame = 0
	return self
end

-- 添加事件
function LObject:addEvent(eventName, action)
	if not self.eventManager[eventName] then
		self.eventManager[eventName] = Delegate()
	end
	self.eventManager[eventName].add(action)
end

-- 移除事件
function LObject:removeEvent(eventName, action)
	self.eventManager[eventName].delete(action)
end

-- 移除所有事件
function LObject:removeAllEvent()
	self.eventManager = {}
end

-- 触发事件
function LObject:invokeEvent(eventName, ...)
	if self.eventManager[eventName] then
		self.eventManager[eventName].invoke(...)
	end
end

function LObject:getVar(n)
	return self[n]
end

-- 读取frame
function LObject:frameLoop()
end

-- 每物理帧调用 更新坐标
function LObject:runFrame()
	if self.directionBuff.x ~= self.direction.x then
		if self.direction.x == -1 then
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
		else
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
		end
		self.directionBuff.x = self.direction.x
	end
	
	if self.vvvX ~= nil then
		self.velocity.x = self.vvvX * self.direction.x
	end
	if self.vvvY ~= nil then
		self.velocity.y = self.vvvY * self.direction.y
	end

	if self.accvvvX ~= nil then
		self.velocity.x = self.velocity.x + self.accvvvX * self.direction.x
	end
	if self.accvvvY ~= nil then
		self.velocity.y = self.velocity.y + self.accvvvY * self.direction.y
	end
	self.accvvvX = nil
	self.accvvvY = nil

	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
end

-- 显示信息
function LObject:displayInfo()
end

function LObject:playAnimationEvent(clip, frame)
	local f = self.database.animations[clip].eventQueue[frame]
	if f ~= nil then
		for i, v in ipairs(f) do
			self:invokeEvent("on" .. v.category, v)
		end
	end

	-- if clip == "body_run_front" then
	-- 	self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(0.5, 0) * CS.UnityEngine.Time.deltaTime
	-- end
end

function LObject:runEvent2()
	
	-- if self.animation.isPlaying == true then

	-- 	-- if self.frame >= self.functions.time then
	-- 	-- 	self.delayCounter = self.delayCounter + 1
	-- 	-- end

	-- 	-- print(CS.Tools.Instance:GetAnimationState(self.animation, "body_run_front").time)
	-- 	-- self.frame = self.frame + CS.UnityEngine.Time.deltaTime * self.functions.speed

	-- 	if self.functions.time >= self.delayCounter * (1 / 60) then
	-- 		print(self.delayCounter)
	-- 		self.delayCounter = self.delayCounter + 1
	-- 	end
	-- end

	local c = self.database.animations[self.action].keyframes[self.delayCounter + 1]


	if c == nil then
		self.delayCounter = 0
		self.frame = 0
		c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
	end

	if self.frame >= c * (1 / 60) then

		local f = self.database.animations[self.action].eventQueue[c]
		self.delayCounter = self.delayCounter + 1
		if f ~= nil then
			for i, v in ipairs(f) do
				self:invokeEvent("on" .. v.category, v)
			end
		end

	end

	-- if c < self.database.animations[self.action].delay then
		self.frame = self.frame + CS.UnityEngine.Time.deltaTime * self.speed
	-- else
	-- 	self.delayCounter = 0
	-- 	self.frame = 0
	-- end


end
------------------------------------------------------------------------------

-- 读取frame
function LCharacterObject:frameLoop()
	self.delayCounter = 0
end

function LCharacterObject:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	self = LObject:new(parent, db, id, a, f, go, vx, vy, k)
	setmetatable(self, LCharacterObject)

	-- self.maxHP = self.database[self.id].char.maxHP
	-- self.maxMP = self.database[self.id].char.maxMP
	-- self.HP = self.maxHP
	-- self.MP = self.maxMP

	-- self.HPRR = self.database[self.id].char.HPRecoveryRate
	-- self.MPRR = self.database[self.id].char.MPRecoveryRate

	-- self.maxFalling = self.database[self.id].char.maxFalling
	-- self.maxDefencing = self.database[self.id].char.maxDefencing
	-- self.fallingRR = self.database[self.id].char.fallingRecoveryRate
	-- self.defencingRR = self.database[self.id].char.defencingRecoveryRate

	-- self.falling = 1
	-- self.defencing = 1

	-- self.weight = self.database[self.id].char.weight

	self.isWall = false
	self.isCeiling = false
	self.isOnGround = 1
	self.isElse = 1
	self.elseArray = {}

	self.attckArray = {}
	self.bodyArray = {}
	self.bodyArray_InstanceID = {}

	self.pic_object = CS.UnityEngine.GameObject("pic")
	self.pic_object.transform:SetParent(self.gameObject.transform)
	self.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	self.spriteRenderer.material = self.database.palettes[1]

	if self.kind == 3 then -- 非人物体暂定-20层
		self.spriteRenderer.sortingOrder = 20
	end

	self.audioSource = self.gameObject:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.atk_object = CS.UnityEngine.GameObject("atk")
	self.atk_object.transform:SetParent(self.gameObject.transform)
	self.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

	self.bdy_object = CS.UnityEngine.GameObject("bdy[16]")
	self.bdy_object.transform:SetParent(self.gameObject.transform)
	self.bdy_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.bdy_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.bdy_object.layer = 16 -- bdy的layer暂定16

	self.AI = false
	self.target = nil

	self.catchedObjects = {}

	self.children = {}

	-- if self.kind ~= 3 and self.kind ~= 5 then
	-- 	self:addEvent("Flying", 0, 999999, nil)
	-- 	-- self:addEvent("Gravity", 0, 999999, nil)
	-- 	self:addEvent("HPMPFallingDefecing", 0, 999999, nil)
	-- 	self:addEvent("Friction", 0, 999999, nil)
	-- 	self:addEvent("FlipX", 0, 999999, nil)
	-- 	-- self:addEvent("Collision", 0, 999999, nil)

	-- 	self:addEvent("FindTarget", 0, 999999, nil) -- 搜敌
	-- 	-- self:addEvent("Dead", 0, 999999, nil) -- 搜敌
	-- end

	-- self:addEvent("UpdatePostion", 0, 999999, nil)

	self:addEvent("onSprite", function(value)
		-- print(value)
		self.spriteRenderer.sprite = self.database.sprites[value.sprite]
		self.pic_object.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, -value.y / 100, 0)
	end)

	self:addEvent("onTrigger", function(value)
		local mousePos = CS.UnityEngine.Input.mousePosition
		-- mousePos.z = v3.z
		local worldPos = CS.UnityEngine.Camera.main:ScreenToWorldPoint(mousePos)
        self.gameObject.transform.position = CS.UnityEngine.Vector3(worldPos.x, worldPos.y, 0)
	end)

	self:addEvent("onObject", function(value)
		if value.kind == 2 then

			if self.children[tostring(value.id)] ~= nil then

				local object = self.children[tostring(value.id)]

				if object.nextAction ~= value.clip then
					object.nextAction = value.clip
					-- object.frame = 0
					-- object:frameLoop()
				end

				if object.gameObject.transform.parent == nil or object.gameObject.transform.parent ~= self.gameObject.transform then
					
					print("setparent!")
					object.gameObject.transform:SetParent(self.gameObject.transform)
					object.parent = self
					if self.parent ~= nil then
						object.root = self.parent
					else
						object.root = self
					end
					object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
				end
				-- object.rigidbody.position = CS.UnityEngine.Vector2(parent.rigidbody.position.x + v.x / 100 * 2, parent.rigidbody.position.y + v.y / 100 * 2)

				local z = value.layer / 100
				if object.root.direction.x == -1 then
					z = -z
				end
				object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, z)

				-- object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, 0)

				object.spriteRenderer.sortingOrder = -value.layer
			end
		end
	end)

	self:addEvent("onAct", function(value)

		if value.kind == 5 or value.kind == 6 then

			if self.children[tostring(value.id)] ~= nil then
				local object = self.children[tostring(value.id)]
				local pos = utils.CURSOR.gameObject.transform.position
				-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))

				local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
				local deg = rad * CS.UnityEngine.Mathf.Rad2Deg

				if value.kind == 5 and deg >= 0 and deg <= 180 then
					-- if self.nextAction ~= value.clip then
					-- 	self.nextAction = value.clip
					-- 	self.nextDelayCounter = value.frame
					-- end
				elseif value.kind == 6 and deg < 0 and deg >= -180 then
					-- if self.nextAction ~= value.clip then
					-- 	self.nextAction = value.clip
					-- 	self.nextDelayCounter = value.frame
					-- end
				end

				-- if object.gameObject.transform.position.x - pos.x < 0 then
				-- 	self.direction.x = 1
				-- else
				-- 	self.direction.x = -1
				-- end

				if self.gameObject.transform.position.x - pos.x < 0 then
					self.direction.x = 1
				else
					self.direction.x = -1
				end

				local ea = self.gameObject.transform.eulerAngles
				if self.direction.x == -1 then
					self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
				else
					self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
				end
			end
		elseif value.kind == 4 then
			local pos = utils.CURSOR.gameObject.transform.position
			local rad = CS.UnityEngine.Mathf.Atan2(self.gameObject.transform.position.y - pos.y, self.gameObject.transform.position.x - pos.x)

			local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180

			local root = self.root
			if root ~= nil then

				if root.direction.x == -1 then
					deg = 360 - rad * CS.UnityEngine.Mathf.Rad2Deg
				end
				self.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, deg)
			end
		end
		
	end)

	-- self:frameLoop() -- 先执行帧
    return self
end

-- 每物理帧调用 更新坐标
function LCharacterObject:runFrame()
	

	-- 	self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * CS.UnityEngine.Time.deltaTime
	
	-- 	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
	
	-- 	self:frameLoop()

	if self.directionBuff.x ~= self.direction.x then
		if self.direction.x == -1 then
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
		else
			self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
		end
		self.directionBuff.x = self.direction.x
	end
	
	if self.vvvX ~= nil then
		self.velocity.x = self.vvvX * self.direction.x
	end
	if self.vvvY ~= nil then
		self.velocity.y = self.vvvY * self.direction.y
	end

	if self.accvvvX ~= nil then
		self.velocity.x = self.velocity.x + self.accvvvX * self.direction.x
	end
	if self.accvvvY ~= nil then
		self.velocity.y = self.velocity.y + self.accvvvY * self.direction.y
	end
	self.accvvvX = nil
	self.accvvvY = nil



	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime

	self.elseArray = {}
	-- 碰撞检测
	local g = false
	for i, v in pairs(self.bodyArray) do
		local gg, cc, ww, ee, eeaa = v:BDYFixedUpdate(self.velocity, self:getVar("weight"))
		if gg ~= 1 then
			if g == false then
				self.isOnGround = gg
				self["isOnGround"] = self.isOnGround
				self.velocity.y = 0
				g = true
			end
		end
		self.isWall = ww
		if ww then
			self.velocity.x = 0
		end
		if cc then
			self.isCeiling = cc
			self.velocity.y = 0
		end
		self.isElse = ee

		for i2, v2 in pairs(eeaa) do
			if self.elseArray[i2] == nil then
				self.elseArray[i2] = {}
			end
			for i3, v3 in pairs(v2) do
				self.elseArray[i2][i3] = v3
			end
		end
	end
	if g == false then
		self.isOnGround = 1
		self["isOnGround"] = self.isOnGround
	end

	-- 攻击检测
	for i, v in pairs(self.attckArray) do
		v:ATKFixedUpdate(self.direction, self)
	end

	-- if self.isOnGround ~= 1 then
	-- 	self:invokeEvent("onGround", nil)
	-- else
	-- 	self:invokeEvent("onFlying", nil)
	-- end

	-- if self["HP"] > 0 then
	-- 	self:invokeEvent("onLive", nil)
	-- else
	-- 	-- self:invokeEvent("onDead", nil)
	-- end

	-- if self.isElse & (1 << 16) == 1 << 16 then
	-- 	if self["interact"] == nil then
	-- 		self:invokeEvent("onCommunicationEnter", nil)
	-- 	end
	-- else
	-- 	if self["interact"] ~= nil then
	-- 		self["interact"] = nil
	-- 		self:invokeEvent("onCommunicationExit", nil)
	-- 	end
	-- end
end

-- 显示信息
function LCharacterObject:displayInfo()
	if self.kind ~= 3 and self.kind ~= 5 then
		local xy = CS.UnityEngine.Camera.main:WorldToScreenPoint(self.gameObject.transform.position)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300, 200, 100), "c: " .. #self.catchedObjects)
		-- if self["velocityX"] ~= nil and self["velocityY"] ~= nil then
		-- 	CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300+ 20, 200, 100), "x: " .. math.floor(self["velocityX"] + 0.5) .. "y: " .. math.floor(self["velocityY"] + 0.5))
		-- end
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 20, 200, 100), "hp: " .. math.floor(self.HP + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 30, 200, 100), "mp: " .. math.floor(self.MP + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 40, 200, 100), "action: " .. self.action)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 50, 200, 100), "frame: " .. self.frame)
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 60, 200, 100), "g: " .. tostring(self.isOnGround))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 70, 200, 100), "w: " .. tostring(self.isWall))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 80, 200, 100), "c: " .. tostring(self.isCeiling))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 90, 200, 100), "e: " .. tostring(self.isElse))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 100, 200, 100), "f: " .. math.floor(self.falling + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 110, 200, 100), "d: " .. math.floor(self.defencing + 0.5))
		-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + 90, 200, 100), "i: " .. tostring(self["interact"])) -- "event: " .. #self.eventQueue

		-- local g = 0
		-- for i, v in pairs(self) do
		-- 	CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x, -xy.y + 300 + g * 10, 200, 100), i .. ": " .. tostring(v))
		-- 	g = g + 1
		-- end
		-- if self["kill"] > 1 then
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 100 + 25, 200, 100), self["kill"] .. " kills")
		-- else
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 100 + 25, 200, 100), self["kill"] .. " kill")

			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 120 + 25, 200, 100), self["HP"] .. " HP")
			-- CS.UnityEngine.GUI.Label(CS.UnityEngine.Rect(xy.x - 13, -xy.y + 315 - 140 + 25, 200, 100), self["MP"] .. " MP")
		-- end
		-- utils.drawHPMP(xy.x, -xy.y + 335 - 100 + 25, self["HP"] / self["maxHP"], self["MP"] / self["maxMP"], self["falling"] / self["maxFalling"], self["defencing"] / self["maxDefencing"])
	end
end

function LCharacterObject:SetParent()
end

function LCharacterObject:DetachChildren()
end

-- LObjectController = {database = nil, id = nil, action = nil, frame = nil, gameObject = nil, children = nil}
-- LObjectController.__index = LObjectController
-- function LObjectController:new(parent, id, a, f, x, y, dx, dy, k)
-- 	local self = {}
-- 	setmetatable(self, LObjectController)

-- 	self.database = utils.getIDData(id)
-- 	self.id = id
-- 	self.action = a
-- 	self.frame = f

-- 	self.children = {}

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		if self.children[v.object] == nil then
-- 			self.children[v.object] = utils.createObject(parent, id, v.animation, 0, x, y, dx, dy, k)
-- 		end
-- 	end

-- 	-- self:runState()

-- 	return self
-- end

-- function LObjectController:runState()

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		if v.kind2 == 1 then
-- 			local object = self.children[v.object]
-- 			local pos = utils.CURSOR.gameObject.transform.position
-- 			-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))

-- 			local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
-- 			local deg = rad * CS.UnityEngine.Mathf.Rad2Deg

-- 			local p = utils.split(self.action, "_")

-- 			if deg >= 0 and deg <= 180 then
-- 				self.action = self.database.FBcontorller[p[1]].front
-- 			elseif deg <= 0 and deg >= -180 then
-- 				self.action = self.database.FBcontorller[p[1]].back
-- 			end

-- 			local parent = nil
-- 			for i, v in ipairs(self.database.characters_state[self.action]) do
-- 				if v.parent ~= nil and v.parent ~= "" then
-- 					parent = self.children[v.parent]
-- 					break
-- 				end
-- 			end

-- 			if object.gameObject.transform.position.x - pos.x < 0 then
-- 				parent.direction.x = 1
-- 			else
-- 				parent.direction.x = -1
-- 			end

-- 			local ea = parent.gameObject.transform.eulerAngles
-- 			if parent.direction.x == -1 then
-- 				parent.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
-- 			else
-- 				parent.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
-- 			end
-- 			break
-- 		end
-- 	end

-- 	for i, v in ipairs(self.database.characters_state[self.action]) do
-- 		local object = self.children[v.object]
-- 		if object ~= nil then
-- 			if object.action ~= v.animation then
-- 				object.action = v.animation
-- 				object:frameLoop()
-- 			end



-- 			if v.parent ~= nil and v.parent ~= "" then
-- 				local parent = self.children[v.parent]
-- 				if parent ~= nil then
-- 					if object.gameObject.transform.parent == nil or object.gameObject.transform.parent ~= parent.gameObject.transform then
-- 						print("setparent!")
-- 						object.gameObject.transform:SetParent(parent.gameObject.transform)
-- 						object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
-- 					end
-- 					-- object.rigidbody.position = CS.UnityEngine.Vector2(parent.rigidbody.position.x + v.x / 100 * 2, parent.rigidbody.position.y + v.y / 100 * 2)
					
-- 					local z = v.layer / 100
-- 					if parent.direction.x == -1 then
-- 						z = -z
-- 					end
-- 					object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(v.x / 100, v.y / 100, z)

-- 					if v.kind == 1 then
-- 						local pos = utils.CURSOR.gameObject.transform.position
-- 						-- object.gameObject.transform:LookAt(CS.UnityEngine.Vector3(pos.x, pos.y, object.gameObject.transform.position.z), CS.UnityEngine.Vector3(0, 0, 1))
		
-- 						local rad = CS.UnityEngine.Mathf.Atan2(object.gameObject.transform.position.y - pos.y, object.gameObject.transform.position.x - pos.x)
		
-- 						local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180
-- 						if parent.direction.x == -1 then
-- 							deg = 360 - rad * CS.UnityEngine.Mathf.Rad2Deg
-- 						end
-- 						object.gameObject.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, deg)
-- 					end
-- 				end
-- 			else
-- 				-- object.rigidbody.position = CS.UnityEngine.Vector2(self.rigidbody.position.x + v.x / 100, self.rigidbody.position.y + v.y / 100)



-- 			end


-- 		end
-- 	end
-- end