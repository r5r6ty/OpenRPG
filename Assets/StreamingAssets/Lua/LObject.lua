-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

utils = require "LUtils"
require "LCollider"
-- local cs_coroutine = (require 'cs_coroutine')

LObject = {database = nil,
			id = nil,
			palette = nil,
			action = nil,
			nextAction = nil,
			frame = nil,
			delay = nil,
			delayCounter = nil,
			nextDelayCounter = nil,

			kind = nil,

			direction = nil,
			directionBuff = nil,

			velocity = nil,

			rigidbody = nil,
			rigidbody_id = nil,
			audioSource =nil,

			vvvX = nil,
			vvvY = nil,
			accvvvX = nil,
			accvvvY = nil,
			accvvvZ = nil,

			vars = nil,
			functions = nil,
			eventQueue = nil,
			eventManager = nil,

			parent = nil,
			children = nil,
			root = nil,
			animation = nil,
			speed = nil,
			timeLine = nil,
			localTimeLine = nil,
			state = nil,
			target = nil,
			controller = nil,

			oriPos = nil,
			oriPos2 = nil,
			deubg_object = nil,
			physics_object = nil,
			-- isWall = nil,
			isOnGround = nil,
			-- isCeiling = nil,
			-- isElse = nil,
			-- elseArray = nil,
		
			spriteRenderer = nil,
		
			attckArray = nil,
			bodyArray = nil,
			bodyArray_InstanceID = nil,
		
			pic_offset_object = nil,
			pic_offset_object_id = nil,
			pic_object = nil,
			pic_object_id = nil,
			atk_object = nil,
			bdy_object = nil,
			lineRenderer = nil,
		
			AI = nil,
			catchedObjects = nil,

			sleep = nil,
			rotation = nil,
			rotation_velocity = nil,

			team = nil,

			hp = nil,
			mp = nil,
			hpMax = nil,
			mpMax = nil,

			level = nil
			}
LObject.__index = LObject
function LObject:new(parent, db, id, a, f, s, x, y, z, vx, vy, vz, k)
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

	self.root = self
	self.parent = self
	self.children = {}
	self.animation = nil
	self.speed = 1
	self.timeLine = 0
	self.localTimeLine = 0
	self.state = s
	self.target = nil
	self.controller = nil
	self.sleep = false

	self.team = 0

	self.rotation = 0
	self.rotation_velocity = 0

	-- for _i, _v in ipairs(self.database:getLines("vars")) do
	-- 	self[_v.name] = _v.default
	-- 	-- print(_v.name, self[_v.name])
	-- end

	-- self.functions = {}
	-- for _i, _v in ipairs(self.database:getLines("functions")) do
	-- 	self.functions[_v.name] = _v.value
	-- end

	-- self["parent"] = parent

	-- if k ~= 5 then
	-- 	self["story"] = self.database:getLines("story")
	-- end

	self.direction = CS.UnityEngine.Vector3(1, -1, 1)
	-- self.directionBuff = CS.UnityEngine.Vector3(1, -1, 1)

	self.velocity = CS.UnityEngine.Vector3(vx, vy, vz)

	self.kind = k
	
	-- self.gameObject:AddComponent(typeof(CS.GameAnimation)).luaBehaviour = utils.LUABEHAVIOUR

	-- self.animation = self.gameObject:AddComponent(typeof(CS.UnityEngine.Animation))
	-- for _i, _v in pairs(self.database.animationClips) do
		
	-- 	self.animation:AddClip(_v, _v.name)
	-- end
	-- self.animation.animatePhysics = true

	self.physics_object = CS.UnityEngine.GameObject("physics")
	-- self.physics_object.transform:SetParent(self.gameObject.transform)
	self.physics_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
	self.physics_object.transform.position = CS.UnityEngine.Vector3(x, y, z)
	-- self.physics_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.physics_object.transform.localScale = CS.UnityEngine.Vector3.one

	-- self.rigidbody = self.gameObject:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
	-- self.rigidbody.bodyType = CS.UnityEngine.RigidbodyType2D.Kinematic
	-- -- self.rigidbody.collisionDetectionMode = CS.UnityEngine.CollisionDetectionMode2D.Continuous
	-- -- self.rigidbody.sleepMode = CS.UnityEngine.RigidbodySleepMode2D.NeverSleep
	-- -- self.rigidbody.interpolation = CS.UnityEngine.RigidbodyInterpolation2D.Interpolate
	-- self.rigidbody.constraints = CS.UnityEngine.RigidbodyConstraints2D.FreezeRotation
	-- self.rigidbody.gravityScale = 0
	-- -- self.rigidbody.useAutoMass = true

	self.rigidbody = self.physics_object:AddComponent(typeof(CS.UnityEngine.Rigidbody))
	-- self.rigidbody.useGravity = false
	self.rigidbody.isKinematic = true
	-- self.rigidbody.detectCollisions = false
	self.rigidbody.freezeRotation = true

	self.rigidbody_id = self.rigidbody:GetInstanceID()
	CS.LuaUtil.AddID2(self.rigidbody_id, self.rigidbody)

	self.vvvX = nil
	self.vvvY = nil
	self.accvvvX = nil
	self.accvvvY = nil
	self.accvvvZ = nil

	
	-- self.isWall = false
	-- self.isCeiling = false
	self.isOnGround = -1
	-- self.isElse = 1
	-- self.elseArray = {}

	self.attckArray = {}
	self.bodyArray = {}
	self.bodyArray_InstanceID = {}

	self.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
	self.pic_offset_object_id = self.pic_offset_object:GetInstanceID()
	CS.LuaUtil.AddID(self.pic_offset_object_id, self.pic_offset_object)
	-- self.pic_offset_object.transform:SetParent(self.gameObject.transform)
	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
	self.pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)

	self.audioSource = self.pic_offset_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.pic_object = CS.UnityEngine.GameObject("pic")
	self.pic_object_id = self.pic_object:GetInstanceID()
	CS.LuaUtil.AddID(self.pic_object_id, self.pic_object)
	self.pic_object.transform:SetParent(self.pic_offset_object.transform)
	self.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	self.spriteRenderer.material = self.database.palettes[1]

	-- if self.kind == 3 then -- 非人物体暂定-20层
	-- 	self.spriteRenderer.sortingOrder = 20
	-- end

	self.audioSource = self.physics_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
	self.audioSource.playOnAwake = false

	self.atk_object = CS.UnityEngine.GameObject("atk")
	self.atk_object.transform:SetParent(self.physics_object.transform)
	self.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

	self.bdy_object = CS.UnityEngine.GameObject("bdy[16]")
	self.bdy_object.transform:SetParent(self.physics_object.transform)
	self.bdy_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.bdy_object.transform.localScale = CS.UnityEngine.Vector3.one
	self.bdy_object.layer = 16 -- bdy的layer暂定16

	-- self.bdy_object_test = CS.UnityEngine.GameObject("bdy[16]_test")
	-- self.bdy_object_test.transform:SetParent(self.gameObject.transform)
	-- self.bdy_object_test.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.bdy_object_test.transform.localScale = CS.UnityEngine.Vector3.one
	-- self.bdy_object_test.layer = 16 -- bdy的layer暂定16

	-- self.deubg_object = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
	-- self.deubg_object.name = "debug"
	-- self.deubg_object.transform:SetParent(self.bdy_object.transform)
	-- if self.kind ~= 5 then
	-- 	self.deubg_object.transform.localScale = CS.UnityEngine.Vector3.zero
	-- else
	-- 	self.deubg_object.transform.localScale = CS.UnityEngine.Vector3(0.16 / 5, 1, 0.16 / 5)
	-- end
	-- self.deubg_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.deubg_object:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).material = utils.DEBUG3D

	-- CS.UnityEngine.GameObject.Destroy(self.deubg_object:GetComponent(typeof(CS.UnityEngine.BoxCollider)))

	self.lineRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
	-- self.lineRenderer.enabled = false
	self.lineRenderer.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	self.lineRenderer.startWidth = 0.01
	self.lineRenderer.endWidth = 0.02
	-- self.lineRenderer.startColor = color
	-- self.lineRenderer.endColor = color
	self.lineRenderer.numCapVertices = 90
	self.lineRenderer.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

	self:SetParentAndRoot(parent)

	self.AI = false
	self.target = nil

	self.catchedObjects = {}

	self.children = {}

	self.hp = 500
	self.hpMax = self.hp
	self.mp = 500
	self.mpMax = self.mp

	self.level = 1

	self.oriPos2 = self.physics_object.transform.position
	self.oriPos = self.rigidbody.position
	return self
end

-- -- 添加事件
-- function LObject:addEvent(eventName, action)
-- 	if not self.eventManager[eventName] then
-- 		self.eventManager[eventName] = Delegate()
-- 	end
-- 	self.eventManager[eventName].add(action)
-- end

-- -- 移除事件
-- function LObject:removeEvent(eventName, action)
-- 	self.eventManager[eventName].delete(action)
-- end

-- -- 移除所有事件
-- function LObject:removeAllEvent()
-- 	self.eventManager = {}
-- end

-- -- 触发事件
-- function LObject:invokeEvent(eventName, ...)
-- 	if self.eventManager[eventName] then
-- 		self.eventManager[eventName].invoke(...)
-- 	end
-- end

-- 显示信息
function LObject:displayInfo()

	if self.kind == 0 and self.root == self then
		local a = utils.CAMERA:WorldToScreenPoint(CS.UnityEngine.Vector3(self.pic_offset_object.transform.position.x, self.pic_offset_object.transform.position.y, 0))

		-- local b = utils.CAMERA:WorldToScreenPoint(CS.UnityEngine.Vector3(0, self.pic_offset_object.transform.position.z, 0))

		utils.drawHPMP(a.x, -a.y + CS.UnityEngine.Screen.height - 75, self.hp / self.hpMax)
	end
end

-- function LObject:playAnimationEvent(clip, frame)
-- 	local f = self.database.animations[clip].eventQueue[frame]
-- 	if f ~= nil then
-- 		for i, v in ipairs(f) do
-- 			self:invokeEvent(v.category, v)
-- 		end
-- 	end

-- 	-- if clip == "body_run_front" then
-- 	-- 	self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(0.5, 0) * CS.UnityEngine.Time.deltaTime
-- 	-- end
-- end

function LObject:update()
	
	if self.sleep == false then
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

		if self.action ~= nil then
			local c = self.database.animations[self.action].keyframes[self.delayCounter + 1]


			if c == nil then
				self.delayCounter = 0
				self.timeLine = 0
				self.localTimeLine = 0
				c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
			end

			-- if self.kind == 5 and self.state ~= "cursor" then
			-- 	print(self.delayCounter, self.timeLine)
			-- end
			if self.timeLine >= c * (1 / 60) then

				local f = self.database.animations[self.action].eventQueue[c]
				self.delayCounter = self.delayCounter + 1
				self.localTimeLine = 0
				if f ~= nil then
					for i, v in ipairs(f) do
						self.database:invokeEvent(v.category, self, v)
					end
				end

			end
		end

		self:runStateUpdate()

		-- if c < self.database.animations[self.action].delay then
		self.timeLine = self.timeLine + CS.UnityEngine.Time.deltaTime * self.speed
		self.localTimeLine = self.localTimeLine + CS.UnityEngine.Time.deltaTime * self.speed
		-- else
		-- 	self.delayCounter = 0
		-- 	self.timeLine = 0
		-- end

		-- local x = "timeLine + 5"
		-- local func = assert(load("return " .. x, "trigger", "t", self))

		-- local y = func()
		
		-- self:runState()

		-- if self.state == "weapon_shoot_HK416c" then
		-- 	print(self.timeLine, self.localTimeLine, self.delayCounter)
		-- end

		-- if self.parent == self then
		-- 	-- local spriteLowerBound = self.spriteRenderer.bounds.size.y * 0.5
		-- 	local floorHeight = 0
		-- 	local posX = self.gameObject.transform.position.x
		-- 	local posY = self.gameObject.transform.position.y
		-- 	local posZ = (posY + floorHeight) * utils.Tan30
		-- 	self.gameObject.transform.position = CS.UnityEngine.Vector3(posX, posY, posZ)
		-- end
		
		-- local pos = self.physics_object.transform.position
		-- self.pic_offset_object.transform.position = CS.UnityEngine.Vector3(pos.x , pos.y + pos.z, self.root.physics_object.transform.position.z)
		local pos = self.physics_object.transform.position
		CS.LuaUtil.SetPos(self.pic_offset_object_id, pos.x, pos.y + pos.z, self.root.physics_object.transform.position.z)

		-- if self.parent == self then
		-- 	local pos2 = self.pic_offset_object.transform.position
		-- 	local pos3 = self.root.physics_object.transform.position.z
		-- 	CS.LuaUtil.SetLocalPos(self.pic_offset_object_id, pos2.x, pos2.y, 0)
		-- end

		self.rotation = self.rotation + self.rotation_velocity

		local rrr = self.physics_object.transform.eulerAngles
		if (self.root == self and self.direction.x == 1) or (self.root ~= self and self.root.direction.x * self.direction.x == 1) then
			if rrr.magnitude > 0 then
				CS.LuaUtil.SetRotationEuler(self.pic_offset_object_id, 0, 0, 360 - rrr.y + self.rotation)
			else
				CS.LuaUtil.SetRotationEuler(self.pic_offset_object_id, 0, 0, 0 + self.rotation)
			end
		else
			if rrr.magnitude > 0 then
				CS.LuaUtil.SetRotationEuler(self.pic_offset_object_id, 0, 180, rrr.y + 180 + self.rotation)
			else
				CS.LuaUtil.SetRotationEuler(self.pic_offset_object_id, 0, 180, 0 + self.rotation)
			end
		end

		-- local pos2 = self.gameObject.transform.position
		-- self.bdy_object_test.transform.position = CS.UnityEngine.Vector3(pos2.x , pos2.y + pos2.z, 0)
	end
end

function LObject:changeState(state)
	local animation = nil
	if state ~= nil then
		self.state = state
		animation = self.database.characters_state[self.state].animation
	end
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
		return true
	end
	return false
end

function LObject:changeAnimation(animation)
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
	end
end

function LObject:SetParentAndRoot(object)
	if object ~= nil and (self.physics_object.transform.parent == nil or self.physics_object.transform.parent ~= self.physics_object.transform) then

		self.physics_object.transform:SetParent(object.physics_object.transform)
		self.rigidbody.isKinematic = true
		self.parent = object
		if object.parent ~= nil then
			self.root = object.parent
		else
			self.root = object
		end
		self.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)

		self.team = object.team
		self.spriteRenderer.material = object.spriteRenderer.material
	end
end


function LObject:fixedupdate()

	if self.sleep == false then
		self.oriPos = self.rigidbody.position
		-- self:runState()

		self:runStateFxiedUpdate()

		if self.accvvvX ~= nil then
			self.velocity.x = self.velocity.x + self.accvvvX * self.direction.x
		end
		if self.accvvvY ~= nil then
			self.velocity.y = self.velocity.y + self.accvvvY * self.direction.y
		end
		if self.accvvvZ ~= nil then
			self.velocity.z = self.velocity.z + self.accvvvZ * self.direction.z
		end
		self.accvvvX = nil
		self.accvvvY = nil
		self.accvvvZ = nil


		-- self.velocity = self.velocity + CS.UnityEngine.Physics.gravity * 0.01

		-- self.gameObject.transform.position = self.gameObject.transform.position + CS.UnityEngine.Vector3(self.velocity.x, self.velocity.y, self.velocity.z) * CS.UnityEngine.Time.deltaTime

		-- self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime

		-- CS.LuaUtil.SetPos2(self.rigidbody_id, self.rigidbody.position.x + self.velocity.x * CS.UnityEngine.Time.deltaTime, self.rigidbody.position.y + self.velocity.y * CS.UnityEngine.Time.deltaTime, self.rigidbody.position.z + self.velocity.z * CS.UnityEngine.Time.deltaTime)

		if self.root ~= self then
			return
		end

		-- local pos2 = self.rigidbody.position
		-- self.bdy_object_test.transform.position = CS.UnityEngine.Vector3(pos2.x, pos2.y + pos2.z, 0)
		
		-- print(self.velocity)
		-- self.elseArray = {}
		-- 碰撞检测

		local f = 0
		for i, v in pairs(self.bodyArray) do
			self.isOnGround = v:BDYFixedUpdate()

			if self.isOnGround ~= -1 then

				if self.kind ~= 99 then
					self.velocity.y = -0.01
				end
			end
			i = i
		end
		if f == 0 then
			self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
		end

		if self.isOnGround ~= -1 then
			self.database:invokeEvent("Ground", self, nil)
		else
			self.database:invokeEvent("Flying", self, nil)
		end

		-- 攻击检测
		for i, v in pairs(self.attckArray) do
			v:ATKFixedUpdate()
		end

		if self.hp > 0 then
			self.database:invokeEvent("Live", self, nil)
		else
			self.database:invokeEvent("Dead", self, nil)
		end
	end
end

function LObject:runStateUpdate()
	if self.state ~= nil then
		local st = self.database.characters_state[self.state]
		for i, v in ipairs(st.update) do
			if v.func == nil or v.func(self) then
				-- print(#v.test)
				for j, v2 in ipairs(v.test) do
					self.database:invokeEvent(v2.category, self, v2.json)
				end
			end
		end
	end
end

function LObject:runStateFxiedUpdate()
	local st = self.database.characters_state["global"]
	for i, v in ipairs(st.fixedUpdate) do
		if v.func == nil or v.func(self) then
			for j, v2 in ipairs(v.test) do
				self.database:invokeEvent(v2.category, self, v2.json)
			end
		end
	end

	if self.state ~= nil and self.state ~= "global" then
		st = self.database.characters_state[self.state]
		for i, v in ipairs(st.fixedUpdate) do
			if v.func == nil or v.func(self) then
				for j, v2 in ipairs(v.test) do
					self.database:invokeEvent(v2.category, self, v2.json)
				end
			end
		end
	end
end