-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

utils = require "LUtils"
require "LCollider"
-- local cs_coroutine = (require 'cs_coroutine')

Delegate = function()
    local data = {}
    local add = function(action) --添加事件
        data[tostring(action)] = action
    end
    local delete = function(action)  --移除事件
        data[tostring(action)] = nil
    end
	local invoke = function(...) --触发事件
		-- local r = nil
        for _, v in pairs(data) do
            if v then
                v(...)
            end
		end
		-- return r
    end
    return
    {
        add = add,
        delete = delete,
        invoke = invoke
    }
end

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

			gameObject = nil,

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
			state = nil,
			target = nil,
			controller = nil,

			oriPos = nil,
			deubg_object = nil,
			physics_object = nil,
			isWall = nil,
			isOnGround = nil,
			isCeiling = nil,
			isElse = nil,
			elseArray = nil,
		
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
		
			AI = nil,
			catchedObjects = nil,

			sleep = nil,
			rotation = nil,
			rotation_velocity = nil
			}
LObject.__index = LObject
function LObject:new(parent, db, id, a, f, go, vx, vy, vz, k)
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

	self.parent = self
	self.children = {}
	self.root = self
	self.animation = nil
	self.speed = 1
	self.timeLine = 0
	self.state = nil
	self.target = nil
	self.controller = nil
	self.sleep = false

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

	self.gameObject = go

	self.kind = k
	
	-- self.gameObject:AddComponent(typeof(CS.GameAnimation)).luaBehaviour = utils.LUABEHAVIOUR

	-- self.animation = self.gameObject:AddComponent(typeof(CS.UnityEngine.Animation))
	-- for _i, _v in pairs(self.database.animationClips) do
		
	-- 	self.animation:AddClip(_v, _v.name)
	-- end
	-- self.animation.animatePhysics = true

	self.physics_object = CS.UnityEngine.GameObject("physics")
	self.physics_object.transform:SetParent(self.gameObject.transform)
	self.physics_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.physics_object.transform.localScale = CS.UnityEngine.Vector3.one

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

	
	self.isWall = false
	self.isCeiling = false
	self.isOnGround = 1
	self.isElse = 1
	self.elseArray = {}

	self.attckArray = {}
	self.bodyArray = {}
	self.bodyArray_InstanceID = {}

	self.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
	self.pic_offset_object_id = self.pic_offset_object:GetInstanceID()
	CS.LuaUtil.AddID(self.pic_offset_object_id, self.pic_offset_object)
	self.pic_offset_object.transform:SetParent(self.gameObject.transform)
	self.pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3.one

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

	-- self.atk_object = CS.UnityEngine.GameObject("atk")
	-- self.atk_object.transform:SetParent(self.physics_object.transform)
	-- self.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

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

	self:addEvent("onFlying", function(value)
		if self.kind ~= 3 and self.kind ~= 5 and not self["isCatched"] then
			self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics.gravity * 2 / 60
			-- self.velocity.y = self.velocity.y + 0.5 * -9.81 * 2 / 60 / 3
		end
	end)

	self:addEvent("onGround", function(value)
		-- if self.isOnGround ~= 1 then
			local f = self.velocity * 0.2 -- 摩擦系数
			if self.velocity.x > 0 then
				self.velocity.x = self.velocity.x - f.x
				if self.velocity.x < 0 then
					self.velocity.x = 0
				end
			elseif self.velocity.x < 0 then
				self.velocity.x = self.velocity.x - f.x
				if self.velocity.x > 0 then
					self.velocity.x = 0
				end
			end

			if self.velocity.z > 0 then
				self.velocity.z = self.velocity.z - f.z
				if self.velocity.z < 0 then
					self.velocity.z = 0
				end
			elseif self.velocity.z < 0 then
				self.velocity.z = self.velocity.z - f.z
				if self.velocity.z > 0 then
					self.velocity.z = 0
				end
			end
		-- end
		if self.kind == 99 then
			if self.rotation > 0 then
				self.rotation_velocity = self.rotation_velocity / 2
			else
				self.rotation_velocity = self.rotation_velocity / 2
			end
			if self.velocity.magnitude <= 1 then
				self.sleep = true
			end
		end
	end)

	self:addEvent("onSprite", function(value)
		-- print(value)
		self.spriteRenderer.sprite = self.database.sprites[value.sprite]
		self.pic_object.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, -value.y / 100, 0)
	end)

	self:addEvent("onSound", function(value)
		self.audioSource.clip = self.database.audioClips[value.sfx]
		-- local r = math.random() / 2.5
		-- self.audioSource.pitch = 1 + r - 0.2
		self.audioSource:Play()
	end)

	self:addEvent("onBody", function(value)
		if self.bodyArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
			self.bodyArray[value.id] = LColliderBDY:new(self, self.bdy_object)
			self.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.bodyFlags, value.layers)
			-- self.bodyArray_InstanceID[self.bodyArray[value.id].collider2:GetInstanceID()] = self.bodyArray[value.id]
			self.bodyArray_InstanceID[self.bodyArray[value.id].collider:GetInstanceID()] = self.bodyArray[value.id]

			-- self.deubg_object.transform.localScale = CS.UnityEngine.Vector3(value.width / 100, value.height / 100, value.width / 100)
			-- self.deubg_object.transform.localPosition = CS.UnityEngine.Vector3((value.x + value.width / 2) / 100, -(value.y + value.height / 2) / 100, 0)
		else
			if self.bodyArray[value.id] ~= nil then
				if value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0 then
					local IID = self.bodyArray[value.id].collider:GetInstanceID()
					self.bodyArray[value.id]:deleteCollider()
					self.bodyArray[value.id] = nil
					self.bodyArray_InstanceID[IID] = nil
				else
					self.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.bodyFlags, value.layers)
				end
			end
		end
	end)
	-- self:addEvent("onAttack", function(value)
	-- 	if self.attckArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
	-- 		self.attckArray[value.id] = LColliderATK:new(self.atk_object, value.id)
	-- 		self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
	-- 													value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, false, value.var,
	-- 													value.action, value.frame)
	-- 	else
	-- 		if self.attckArray[value.id] ~= nil then
	-- 			if value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0 then
	-- 				self.attckArray[value.id]:deleteCollider()
	-- 				self.attckArray[value.id] = nil
	-- 			else
	-- 				self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
	-- 														value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, value.ignoreFlag, value.var,
	-- 														value.action, value.frame)
	-- 			end
	-- 		end
	-- 	end
	-- end)

	self:addEvent("onTrigger", function(value)
		local mousePos = CS.UnityEngine.Input.mousePosition
		-- mousePos.z = v3.z
		local worldPos = utils.CAMERA:ScreenToWorldPoint(mousePos)
		self.physics_object.transform.position = CS.UnityEngine.Vector3(worldPos.x, utils.PLAYER.object.physics_object.transform.position.y, worldPos.y - utils.PLAYER.object.physics_object.transform.position.y)
		-- local pos = CS.UnityEngine.Vector3(worldPos.x, 10, worldPos.y)
		-- local hitinfo = CS.Tools.Instance:PhysicsRaycast(pos, CS.UnityEngine.Vector3.down, 25, 15)
		-- if hitinfo ~= nil then
		-- 	local e = hitinfo.point
		-- 	self.gameObject.transform.position = e
		-- else
		-- 	local e = pos + CS.UnityEngine.VVector3.down * 25
		-- 	self.gameObject.transform.position = e
		-- end

		-- local mousePos = CS.UnityEngine.Input.mousePosition
		-- -- mousePos.z = v3.z
		-- local worldPos = utils.CAMERA:ScreenToWorldPoint(mousePos)
		-- -- self.gameObject.transform.position = CS.UnityEngine.Vector3(worldPos.x, 0, worldPos.y)
		-- local pos = CS.UnityEngine.Vector3(worldPos.x, utils.PLAYER.object.gameObject.transform.position.y, worldPos.y)

		-- self.gameObject.transform.position = pos


		-- local ray = CS.UnityEngine.Camera.main:ScreenPointToRay(CS.UnityEngine.Input.mousePosition)
		-- local result = CS.UnityEngine.Physics2D.GetRayIntersection(ray, 100)
		-- if result.collider ~= nil then
		-- 	local offset = (result.collider.bounds.center.y) - result.point.y
		-- 	local pos = CS.UnityEngine.Vector3(result.point.x, result.point.y, result.collider.transform.position.z)
		-- 	self.gameObject.transform.position = CS.UnityEngine.Vector3(pos.x, pos.y - pos.z, pos.z)
		-- else
		-- 	self.gameObject.transform.position = CS.UnityEngine.Vector3.zero
		-- end
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

				-- object.spriteRenderer.sortingOrder = -value.layer
			end
		end
	end)

	-- self:frameLoop() -- 先执行帧

	-- self.animation:Play(self.action)
	-- self.functions = CS.Tools.Instance:GetAnimationState(self.animation, self.action)

	self.oriPos = self.physics_object.transform.position
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
	if self.accvvvZ ~= nil then
		self.velocity.z = self.velocity.z + self.accvvvZ * self.direction.z
	end
	self.accvvvX = nil
	self.accvvvY = nil
	self.accvvvZ = nil

	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
end

-- 显示信息
-- function LObject:displayInfo()
-- end

-- function LObject:playAnimationEvent(clip, frame)
-- 	local f = self.database.animations[clip].eventQueue[frame]
-- 	if f ~= nil then
-- 		for i, v in ipairs(f) do
-- 			self:invokeEvent("on" .. v.category, v)
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
				c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
			end

			if self.timeLine >= c * (1 / 60) then

				local f = self.database.animations[self.action].eventQueue[c]
				self.delayCounter = self.delayCounter + 1
				if f ~= nil then
					for i, v in ipairs(f) do
						self:invokeEvent("on" .. v.category, v)
					end
				end

			end
		end

		-- if c < self.database.animations[self.action].delay then
		self.timeLine = self.timeLine + CS.UnityEngine.Time.deltaTime * self.speed
		-- else
		-- 	self.delayCounter = 0
		-- 	self.timeLine = 0
		-- end

		-- local x = "timeLine + 5"
		-- local func = assert(load("return " .. x, "trigger", "t", self))

		-- local y = func()

		local gl = self.database.characters_state["global"]
		for i, v in ipairs(gl.state) do
			if v.disable == false and (v.trigger == nil or assert(load("return " .. v.trigger, "trigger", "t", self))()) then
				if v.kind == "Command" then
					local cmd = utils.PLAYER.commands[v.command]
					if cmd.UIActive ~= nil then
						-- if self["HP"] > 0 and self["MP"] >= v.mp then
							self:changeState(v.stateChange)

							-- if cmd.UIActive == 1 then
							-- 	if self.direction.x == -1 then
							-- 		self.direction.x = 1
							-- 	end
							-- elseif cmd.UIActive == -1 then
							-- 	if self.direction.x == 1 then
							-- 		self.direction.x = -1
							-- 	end
							-- end

							-- self["MP"] = self["MP"] - v.mp
						-- end
					end
				end
			end
		end
		
		if self.state ~= nil then
			local st = self.database.characters_state[self.state]
			-- if st.animation ~= nil then
			-- 	self.action = st.animation
			-- 	self.delayCounter = 0
			-- 	self.timeLine = 0
			-- end
			for i, v in ipairs(st.state) do
				if v.disable == false and (v.trigger == nil or assert(load("return " .. v.trigger, "trigger", "t", self))()) then
					if v.kind == "ChangeState" then
						self:changeState(v.stateChange)
					elseif v.kind == "ChangeAnimation" then
						self:changeAnimation(v.animationChange)
					elseif v.kind == "TurnFront" then
						self.direction.z = 1
						self:changeAnimation(v.animationChange)
					elseif v.kind == "TurnBack" then
						self.direction.z = -1
						self:changeAnimation(v.animationChange)
					elseif v.kind == "TurnRight" then
						self.direction.x = 1

						-- local ea = self.physics_object.transform.eulerAngles
						-- if self.direction.x == -1 then
						-- 	self.physics_object.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
						-- else
						-- 	self.physics_object.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
						-- end
					elseif v.kind == "TurnLeft" then
						self.direction.x = -1

						-- local ea = self.physics_object.transform.eulerAngles
						-- if self.direction.x == -1 then
						-- 	self.physics_object.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, ea.z)
						-- else
						-- 	self.physics_object.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, ea.z)
						-- end
					elseif v.kind == "Child" then
						local object = self.children[v.id]
						if object ~= nil then
							-- local z = v.layer / 100
							-- if self.root.direction.x == -1 then
							-- 	z = -z
							-- end
							-- object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(v.x / 100, v.y / 100, z)

							if object.parent.direction.x == -1 then
								object.physics_object.transform.localPosition = CS.UnityEngine.Vector3(-v.x / 100, v.y / 100, 0)
							else
								object.physics_object.transform.localPosition = CS.UnityEngine.Vector3(v.x / 100, v.y / 100, 0)
							end

							object.spriteRenderer.sortingOrder = -v.layer * self.root.direction.z
						end
					elseif v.kind == "TurnToTarget" then
						local pos = self.root.target.physics_object.transform.position
						local rad = CS.UnityEngine.Mathf.Atan2(self.physics_object.transform.position.z - pos.z, self.physics_object.transform.position.x - pos.x)
			
						local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180
			
						local root = self.root
						if root ~= nil then
			
							-- if root.direction.x == -1 then
							-- 	deg = -(360 - rad * CS.UnityEngine.Mathf.Rad2Deg)
							-- end
							self.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, -deg, 0)
						end
					elseif v.kind == "MoveAC" then
						self.accvvvY = v.id
					elseif v.kind == "Move" then
						if v.x2 ~= nil then
							self.velocity.x = v.x2
						end
						if v.y2 ~= nil then
							self.velocity.y = v.y2
						end
						if v.z2 ~= nil then
							self.velocity.z = v.z2
						end
						-- self.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(v.x, v.y) * CS.UnityEngine.Time.deltaTime
						-- self.gameObject.transform.position = self.gameObject.transform.position + CS.UnityEngine.Vector3(v.x, v.y, 0) * CS.UnityEngine.Time.deltaTime
					elseif v.kind == "Object" then
						local d = self.root.direction.x
						
						for i = 1, v.amount, 1 do

							local r = nil
							if v.amount > 0 then
								r = CS.Tools.Instance:RandomRangeInt(0, 31) - 30 / 2
							else
								r = 0
							end

							local rot = nil
							local velocityyy = nil
							local offset = nil
							if v.x2 > 1 then
								offset = CS.Tools.Instance:RandomRangeInt(0, 16)
							else
								offset = 0
							end
							-- if d == -1 then
							-- 	rot = CS.UnityEngine.Vector3(0, 180, self.physics_object.transform.eulerAngles.z + r)
							-- elseif d == 1 then
							-- 	rot = CS.UnityEngine.Vector3(0, 0, self.physics_object.transform.eulerAngles.z + r)
							-- end

							local randomvector = CS.UnityEngine.Vector3(CS.Tools.Instance:RandomRangeFloat(0, 1), CS.Tools.Instance:RandomRangeFloat(0, 1), CS.Tools.Instance:RandomRangeFloat(0, 1)).normalized

							rot = CS.UnityEngine.Quaternion.AngleAxis(r, randomvector) * self.physics_object.transform.rotation 

							-- velocityyy = CS.UnityEngine.Quaternion.Euler(rot) * CS.UnityEngine.Vector3(v.x2 - offset, v.y2, 0)
							-- velocityyy.x = velocityyy.x + self.root.velocity.x
							-- velocityyy.y = velocityyy.y + self.root.velocity.y

							velocityyy = rot * CS.UnityEngine.Vector3(v.x2, v.y2, v.z2)
							
							-- local velocity = CS.UnityEngine.Vector2(0, 0)

							local pos = self.physics_object.transform.rotation * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

							local kk = nil
							if v.animationChange == "shell" then
								kk = 99
							else
								kk = 5
							end
							local object = utils.createObject(nil, tonumber(v.id), v.animationChange, 0, self.rigidbody.position.x + pos.x, self.rigidbody.position.y + pos.y, self.rigidbody.position.z + pos.z, velocityyy.x, velocityyy.y, velocityyy.z, kk)
							local lr = object.pic_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
							-- lr.enabled = false
							lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
							lr.startWidth = 0.01
							lr.endWidth = 0.02

							local rc = CS.Tools.Instance:RandomRangeInt(0, #v.colors) + 1
							local color = CS.Tools.Instance:ColorTryParseHtmlString("#" .. string.format("%X", v.colors[rc].color))

							lr.startColor = color
							lr.endColor = color
							lr.numCapVertices = 90
							lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

							object:changeState(v.stateChange)
							object.direction.x = d
							-- object.velocity.x = v.x2 * self.root.direction.x
							-- object.velocity.y = v.y2

							-- local ea = object.gameObject.transform.eulerAngles
							object.physics_object.transform.rotation = rot
							-- local tr = object.gameObject:AddComponent(typeof(CS.UnityEngine.TrailRenderer))
							-- tr.startWidth = 0.04
							-- tr.endWidth = 0.01
							-- tr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
							-- tr.numCapVertices = 90
							-- tr.startColor = CS.UnityEngine.Color.yellow
							-- tr.endColor = CS.UnityEngine.Color(1, 0.92, 0.016, 0)

							-- tr.material =  CS.UnityEngine.Material(utils.getShader())
						end
					elseif v.kind == "Destory" then
						utils.destroyObject(self.gameObject)
					elseif v.kind == "Collison" then
						if self.frame == 1 then
							utils.destroyObject(self.gameObject)
						else
							local s = nil
							local e = nil
							-- local lr = self.gameObject:GetComponent(typeof(CS.UnityEngine.LineRenderer))
							local lr = self.pic_object:GetComponent(typeof(CS.UnityEngine.LineRenderer))
							

							local length = (self.physics_object.transform.position - self.oriPos).magnitude -- 射线的长度
							local direction = self.physics_object.transform.position - self.oriPos -- 方向
							-- RaycastHit2D[] hitinfo;
							-- local hitinfo = CS.UnityEngine.Physics2D.RaycastAll(CS.UnityEngine.Vector2(self.oriPos.x, self.oriPos.y), CS.UnityEngine.Vector2(direction.x, direction.y), length) -- 在两个位置之间发起一条射线，然后通过这条射线去检测有没有发生碰撞

							-- local hitinfo = CS.Tools.Instance:PhysicsRaycastAll(self.oriPos, direction, length, 15)
							-- -- print(hitinfo.Length)

							local hitinfo = CS.Tools.Instance:PhysicsRaycast(self.oriPos, direction, length, 1048575)
							if hitinfo.collider ~= nil then
								s = self.oriPos
								e = hitinfo.point
								lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
								lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
								if hitinfo.collider.attachedRigidbody.gameObject.name ~= "test" then
									local iId = hitinfo.collider.attachedRigidbody.gameObject.transform.parent.gameObject:GetInstanceID()
									-- local object = utils.getObject(iId)
									local comp = hitinfo.collider.attachedRigidbody.gameObject.transform.parent.gameObject:GetComponent(typeof(CS.XLuaTest.LuaComponent))
									local object = comp.scriptEnv.MainObject

									local spd = direction * 40 / 100
									if object.accvvvX == nil then
										object.accvvvX = spd.x * object.direction.x
									else
										object.accvvvX = object.accvvvX + spd.x * object.direction.x
									end
									if object.accvvvY == nil then
										object.accvvvY = spd.y * object.direction.y
									else
										object.accvvvY = object.accvvvY + spd.y * object.direction.y
									end
									if object.accvvvZ == nil then
										object.accvvvZ = spd.z * object.direction.z
									else
										object.accvvvZ = object.accvvvZ + spd.z * object.direction.z
									end
								end
								self.frame = 1
							else
								s = self.oriPos
								e = self.physics_object.transform.position
								lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
								lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
							end
						end
					elseif v.kind == "Ray" then
						local pos = nil
						local hitinfo = nil
						local s = nil
						local e = nil

						local first = nil
						if self.physics_object.transform.childCount > 1 + 1 then
							first = self.physics_object.transform:GetChild(2)
						else
							first = CS.UnityEngine.GameObject("debug_1")
							first.transform.parent = self.physics_object.transform
						end
						if first ~= nil then
							local lr = nil
						
							if not first:TryGetComponent(typeof(CS.UnityEngine.LineRenderer), lr) then
								lr = first:AddComponent(typeof(CS.UnityEngine.LineRenderer))
		
								lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
								lr.startWidth = 0.02
								lr.endWidth = 0.02
		
								local color = CS.UnityEngine.Color.green
		
								lr.startColor = color
								lr.endColor = color
								lr.numCapVertices = 90
								lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY
		
								-- lr.useWorldSpace = false
							else
								lr = first:GetComponent(typeof(CS.UnityEngine.LineRenderer))
							end
		
							if lr ~= nil then
								local r = self.physics_object.transform.rotation
								-- local r = CS.UnityEngine.Quaternion.Euler(r2.x, r2.z, r2.y)
								pos = r * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0) --  -- 

								-- pos = CS.UnityEngine.Quaternion.Euler() * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)
		
								-- hitinfo = CS.Tools.Instance:PhysicsRaycastAll(pos + self.rigidbody.position, self.gameObject.transform.right, 25, 15)

								hitinfo = CS.Tools.Instance:PhysicsRaycast(pos + self.rigidbody.position, r * CS.UnityEngine.Vector3.right, 25, 1048575)
								-- local t_pos = self.root.target.gameObject.transform.position
								-- local offset = t_pos - (pos + self.rigidbody.position)
								-- hitinfo = CS.Tools.Instance:PhysicsRaycast(pos + self.rigidbody.position, offset.normalized, offset.magnitude, 15)
		
								if hitinfo.collider ~= nil then
									s = pos + self.rigidbody.position
									e = hitinfo.point
									lr:SetPosition(0, s)
									lr:SetPosition(1, e)
								else
									s = pos + self.rigidbody.position
									e = pos + self.rigidbody.position + r * CS.UnityEngine.Vector3.right * 25
									lr:SetPosition(0, s)
									lr:SetPosition(1, e)
								end
							end
						end

						local second = nil
						if self.physics_object.transform.childCount > 2 + 1 then
							second = self.physics_object.transform:GetChild(3)
						else
							second = CS.UnityEngine.GameObject("debug_2")
							second.transform.parent = self.physics_object.transform
						end
						if second ~= nil then
							local lr = nil
						
							if not second:TryGetComponent(typeof(CS.UnityEngine.LineRenderer), lr) then
								lr = second:AddComponent(typeof(CS.UnityEngine.LineRenderer))
		
								lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
								lr.startWidth = 0.02
								lr.endWidth = 0.02
		
								local color = CS.UnityEngine.Color.red
		
								lr.startColor = color
								color.a = 0
								lr.endColor = color
								lr.numCapVertices = 90
								lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY
		
								-- lr.useWorldSpace = false
							else
								lr = second:GetComponent(typeof(CS.UnityEngine.LineRenderer))
							end
		
							if lr ~= nil then
								lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
								lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
							end
						end
					elseif v.kind == "Rotation" then
						if self.rotation_velocity == 0 then
							self.rotation_velocity = v.y2
						end
					elseif v.kind == "Command" then
						local cmd = utils.PLAYER.commands[v.command]
						if cmd.UIActive ~= nil then
							-- if self["HP"] > 0 and self["MP"] >= v.mp then
								self:changeState(v.stateChange)
		
								-- if cmd.UIActive == 1 then
								-- 	if self.direction.x == -1 then
								-- 		self.direction.x = 1
								-- 	end
								-- elseif cmd.UIActive == -1 then
								-- 	if self.direction.x == 1 then
								-- 		self.direction.x = -1
								-- 	end
								-- end
		
								-- self["MP"] = self["MP"] - v.mp
							-- end
						end
					end
				end
			end
		end
		self.oriPos = self.physics_object.transform.position

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
		local posX = self.physics_object.transform.position.x
		local posY = self.physics_object.transform.position.y
		local posZ = self.physics_object.transform.position.z
		local posZ2 = self.root.physics_object.transform.position.z
		CS.LuaUtil.SetPos(self.pic_offset_object_id, posX, posY + posZ, posZ2)

		self.rotation = self.rotation + self.rotation_velocity

		local rrr = self.physics_object.transform.eulerAngles
		if rrr.magnitude > 0 then
			if self.root.direction.x == 1 then
				self.pic_offset_object.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, 360 - rrr.y + self.rotation)
			else
				self.pic_offset_object.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, rrr.y + 180 + self.rotation)
			end
		else
			if self.root.direction.x == 1 then
				self.pic_offset_object.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0 + self.rotation)
			else
				self.pic_offset_object.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, 0 + self.rotation)
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
	end
end

function LObject:changeAnimation(animation)
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
	end
end

function LObject:SetParentAndRoot(object)
	if self.physics_object.transform.parent == nil or self.physics_object.transform.parent ~= self.physics_object.transform then

		self.physics_object.transform:SetParent(object.physics_object.transform)
		self.rigidbody.isKinematic = true
		self.parent = object
		if object.parent ~= nil then
			self.root = object.parent
		else
			self.root = object
		end
		self.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
	end
end


function LObject:fixedupdate()

	if self.sleep == false then

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

		if self.kind == 5 then
			self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
			return
		end

		if self.root ~= self then
			return
		end

		-- local pos2 = self.rigidbody.position
		-- self.bdy_object_test.transform.position = CS.UnityEngine.Vector3(pos2.x, pos2.y + pos2.z, 0)
		
		-- print(self.velocity)
		-- self.elseArray = {}
		-- 碰撞检测

		for i, v in pairs(self.bodyArray) do
			self.isOnGround = v:BDYFixedUpdate()

			if self.isOnGround ~= -1 then

				if self.kind ~= 99 then
					self.velocity.y = -0.01
				end
			end

		end

		if self.isOnGround ~= -1 then
			self:invokeEvent("onGround", nil)
		else
			self:invokeEvent("onFlying", nil)
		end
	end
end