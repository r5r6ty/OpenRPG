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
			audioSource =nil,

			vvvX = nil,
			vvvY = nil,
			accvvvX = nil,
			accvvvY = nil,

			vars = nil,
			functions = nil,
			eventQueue = nil,
			eventManager = nil,

			parent = nil,
			root = nil,
			animation = nil,
			speed = nil
			}
LObject.__index = LObject
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

	-- self["parent"] = parent

	if k ~= 5 then
		self["story"] = self.database:getLines("story")
	end

	self.direction = CS.UnityEngine.Vector2(1, -1)
	self.directionBuff = CS.UnityEngine.Vector2(1, -1)

	self.velocity = CS.UnityEngine.Vector2(vx, vy)

	self.gameObject = go

	self.kind = k

	self.animation = self.gameObject:AddComponent(typeof(CS.UnityEngine.Animation))
	for _i, _v in pairs(self.database.animationClips) do
		self.animation:AddClip(_v, _v.name)
	end
	

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

	self:frameLoop() -- 先执行帧
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

-- 每物理帧调用 执行事件
function LObject:runEvent()
	if self.delayCounter < self.delay then
		local f = self.eventQueue[self.delayCounter]
		self.delayCounter = self.delayCounter + 1
		if f ~= nil then
			for i, v in ipairs(f) do
				self:invokeEvent("on" .. v.category, v)
			end
		end
	else
		self.delayCounter = 0
	end
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

------------------------------------------------------------------------------

LCharacterObject = {
			isWall = nil,
			isOnGround = nil,
			isCeiling = nil,
			isElse = nil,
			elseArray = nil,

			spriteRenderer = nil,

			attckArray = nil,
			bodyArray = nil,
			bodyArray_InstanceID = nil,

			pic_object = nil,
			atk_object = nil,
			bdy_object = nil,

			vvvX = nil,
			vvvY = nil,
			accvvvX = nil,
			accvvvY = nil,

			AI = nil,
			target = nil,
			catchedObjects = nil,

			children = nil
			}
setmetatable(LCharacterObject, LObject)
LCharacterObject.__index = LCharacterObject
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

	self:addEvent("onLive", function(value)
		self["HP"] = utils.toMaxvalue(self["HP"], self["maxHP"], self["HPRecoveryRate"])
		self["MP"] = utils.toMaxvalue(self["MP"], self["maxMP"], self["MPRecoveryRate"] + (self["MPRecoveryRate"] * (1 - self["HP"] / self["maxHP"])))
		self["falling"] = utils.toOne(self["falling"], self["maxFalling"], self["fallingRecoveryRate"])
		self["defencing"] = utils.toOne(self["defencing"], self["maxDefencing"], self["defencingRecoveryRate"])

		if self.target == nil then
			local temp = {}
			for i, v in pairs(utils.getObjects()) do
				if v ~= nil and v.kind == 0 and v ~= self and v["HP"] > 0 then
					table.insert(temp, v)
				end
			end
			self.target = temp[CS.Tools.Instance:RandomRangeInt(1, #temp + 1)]
		else
			if self.target["HP"] <= 0 then
				self.target = nil
			end
		end
	end)
	self:addEvent("onDead", function(value)
	end)
	self:addEvent("onFlying", function(value)
		-- if self.kind ~= 3 and self.kind ~= 5 and not self["isCatched"] then
		-- 	self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * 2/60
		-- end
	end)
	self:addEvent("onGround", function(value)
		-- if self.isOnGround ~= 1 then
			local f = self.velocity * CS.UnityEngine.Vector2(1, 0) * 0.20 -- 摩擦系数
			if self.velocity.x > 0 then
				self.velocity = self.velocity - f
				if self.velocity.x < 0 then
					self.velocity.x = 0
				end
			elseif self.velocity.x < 0 then
				self.velocity = self.velocity - f
				if self.velocity.x > 0 then
					self.velocity.x = 0
				end
			end
		-- end
	end)
	self:addEvent("onWall", function(value)
	end)
	self:addEvent("onMove", function(value)
		if value.compute == 0 then
			self.vvvX = value.directionX
			self.vvvY = value.directionY
		elseif value.compute == 1 then
			self.accvvvX = value.directionX
			self.accvvvY = value.directionY
		else
			if self.elseArray[value.layers] ~= nil then
				for i2, v2 in pairs(self.elseArray[value.layers]) do
						self.rigidbody.position = CS.UnityEngine.Vector2(v2.bounds.center.x, v2.bounds.center.y)
						-- self.rigidbody.position = CS.UnityEngine.Vector2(v2.transform.position.x, v2.transform.position.y)
						-- self.gameObject.transform.position = v2.transform.position
					break
				end
			end
		end
	end)
	self:addEvent("onSprite", function(value)
		-- print(value)
		self.spriteRenderer.sprite = self.database.sprites[value.pic]
		self.pic_object.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, -value.y / 100, 0)
	end)
	self:addEvent("onBody", function(value)
		if self.bodyArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
			self.bodyArray[value.id] = LColliderBDY:new(self.bdy_object, value.id)
			self.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.bodyFlags, value.layers)
			self.bodyArray_InstanceID[self.bodyArray[value.id].collider:GetInstanceID()] = self.bodyArray[value.id]
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
	self:addEvent("onAttack", function(value)
		if self.attckArray[value.id] == nil and not (value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0) then
			self.attckArray[value.id] = LColliderATK:new(self.atk_object, value.id)
			self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
														value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, false, value.var,
														value.action, value.frame)
		else
			if self.attckArray[value.id] ~= nil then
				if value.x == 0 or value.y == 0 or value.width == 0 or value.height == 0 then
					self.attckArray[value.id]:deleteCollider()
					self.attckArray[value.id] = nil
				else
					self.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.attackFlags,
															value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, value.ignoreFlag, value.var,
															value.action, value.frame)
				end
			end
		end
	end)
	self:addEvent("onSound", function(value)
		self.audioSource.clip = self.database.audioClips[value.sfx]
		local r = math.random() / 2.5
		self.audioSource.pitch = 1 + r - 0.2
		self.audioSource:Play()
	end)
	self:addEvent("onObject", function(value)
		if value.isWorldPosition then

			utils.createObject(nil, self.id, value.action,value.frame, value.x, value.y, 0, 0, value.kind)
		else
			utils.createObject(nil, self.id, value.action, value.frame, self.rigidbody.position.x + value.x, self.rigidbody.position.y + value.y, 0, 0, value.kind)
		end
	end)
	self:addEvent("onCommand", function(value)
		if value.actFlag == nil then
			if value.range == nil then

				if utils.PLAYER.object == self then

					local v = utils.PLAYER.commands[value.command]
					if v.UIActive ~= nil then
						if self["HP"] > 0 and self["MP"] >= v.mp then
							self.action = v.action
							self.frame = v.frame
							self:frameLoop()

							if v.UIActive == 1 then
								if self.direction.x == -1 then
									self.direction.x = 1
								end
							elseif v.UIActive == -1 then
								if self.direction.x == 1 then
									self.direction.x = -1
								end
							end

							self["MP"] = self["MP"] - v.mp
						end
					end
				else
					if self.AI then
						local temp = self.database.AI:judgeAI(self)
						for i, v in ipairs(temp) do
							if value.command == v.name then
								if self["HP"] > 0 and self["MP"] >= v.mp then
									self.action = v.action
									self.frame = v.frame
									self:frameLoop()
	
									if v.direction == 1 then
										if self.direction.x == -1 then
											self.direction.x = 1
										end
									elseif v.direction == -1 then
										if self.direction.x == 1 then
											self.direction.x = -1
										end
									end
	
									self["MP"] = self["MP"] - v.mp
								end
								break
							end
						end
					end
				end
			else
				if utils.PLAYER.object == self then

					local rA, rB = utils.getRangeAB(value.range)
					for i, vvv in pairs(utils.PLAYER.commands_sort) do -- command
						local v = vvv.value
						if v.UIActive ~= nil and v.level >= rA and v.level <= rB then
							
							if self["HP"] > 0 and self["MP"] >= v.mp then
								self.action = v.action
								self.frame = v.frame
								self:frameLoop()

								if v.UIActive == 1 then
									if self.direction.x == -1 then
										self.direction.x = 1
									end
								elseif v.UIActive == -1 then
									if self.direction.x == 1 then
										self.direction.x = -1
									end
								end

								self["MP"] = self["MP"] - v.mp
							end
							break
						end
					end
				else
					if self.AI then
						-- print("caca")
						local temp = self.database.AI:judgeAI(self)

						local rA, rB = utils.getRangeAB(value.range)
						for i, v in ipairs(temp) do
							if v.level >= rA and v.level <= rB then
								if self["HP"] > 0 and self["MP"] >= v.mp then
									self.action = v.action
									self.frame = v.frame
									self:frameLoop()
	
									if v.direction == 1 then
										if self.direction.x == -1 then
											self.direction.x = 1
										end
									elseif v.direction == -1 then
										if self.direction.x == 1 then
											self.direction.x = -1
										end
									end
	
									self["MP"] = self["MP"] - v.mp
								end
								break
							end
						end
						
					end
				end
			end
		else
		end
	end)
	self:addEvent("onWarp", function(value)
		-- if value.var == nil then

		-- end
		if value.operator == nil or value.var == nil or value.value == nil then
			self.action = value.action
			self.frame = value.frame
			self:frameLoop()
		else
			local res = 1
			if value.operator & 32 == 32 then
				if self[value.var] == value.value then
					res = res & 1
				else
					res = res & 0
				end
			end
			if value.operator & 64 == 64 then
				if self[value.var] ~= value.value then
					res = res & 1
				else
					res = res & 0
				end
			end
			if value.operator & 128 == 128 then
				if self[value.var] > value.value then
					res = res & 1
				else
					res = res & 0
				end
			end
			if value.operator & 256 == 256 then
				if self[value.var] < value.value then
					res = res & 1
				else
					res = res & 0
				end
			end

			if res == 1 then
				self.action = value.action
				self.frame = value.frame
				self:frameLoop()
			end
		end
	end)
	self:addEvent("onAct", function(value)
		if value.command == nil or value.command == "" then
			if (value.actFlag == 0 and self.isOnGround ~= 1 and self.velocity.y <= 0) or (value.actFlag == 1 and self.isWall) or (value.actFlag == 2 and self.isElse == 1 | 1 << tonumber(value.layers)) then
				self.action = value.action
				self.frame = value.frame
				self:frameLoop()
			end
		end
	end)
	self:addEvent("onEnd", function(value)
		utils.destroyObject(self.gameObject:GetInstanceID())
	end)
	self:addEvent("onInjured", function(value)
		local reactions = self.database:getLines("reactions")
		if #reactions > 0 and self.kind == 0 then
			local ttt = {}
			local round = math.floor(self["falling"] + 0.5)
			if self["HP"] <= 0 then
				round = 100
			end
			for i, v in pairs(reactions) do
				local rA, rB = utils.getRangeAB(v.fallingRange)
	 			-- print(round, rA, rB)

				
				local d = (value.dir * self.direction.x + 1) / 2 + 1
				-- print(self.direction.x, d)

				-- print(d)
				if round >= rA and round <= rB and v.direction & d == d then
					table.insert(ttt, {action = v.action, frame = v.frame})
					-- print(v.direction)
				end
			end
			if #ttt > 0 then
				
				-- local r = CS.Tools.Instance:RandomRangeInt(1, 101)
				-- if r >= 1 and r <= 80 then
				-- 	r = 1
				-- elseif r >= 81 and r <= 100 then
				-- 	r = 2
				-- end
				local r = CS.Tools.Instance:RandomRangeInt(1, #ttt + 1)
				-- print(#ttt, r)
				-- self:changeAction(ttt[r].action, ttt[r].frame)
				self.action = ttt[r].action
				self.frame = ttt[r].frame
				self:frameLoop()
				-- break
				-- print(self.action, self.frame)
			end
		end
	end)
	self:addEvent("onForce", function(value)
		if value.compute == 0 then
			self.velocity.x = 0
			self.velocity.y = 0
		end
		self.velocity.x = self.velocity.x + value.velocity.x
		if math.floor(self["falling"] + 0.5) >= 70 then
			self.velocity.y = self.velocity.y + value.velocity.y
		end
	end)
	self:addEvent("onHurt", function(value)
		local hhh = self[value.var]
		self[value.var] = self[value.var] - value.damage
		-- self["MP"] = self["MP"] - value.damage
		if self[value.var] <= 0 then
			self[value.var] = 0
			self["falling"] = self["maxFalling"]
			self["defencing"] = self["maxDefencing"]
		else
			self["falling"] = self["falling"] + value.fall
			self["defencing"] = self["defencing"] + value.defence
			if self["falling"] > self["maxFalling"] then
				self["falling"] = self["maxFalling"]
			end
			if self["defencing"] > self["maxDefencing"] then
				self["defencing"] = self["maxDefencing"]
			end
		end
		-- self.target = value.attacker -- 切换目标
		-- if hhh > 0 and self[value.var] == 0 then
		-- 	value.attacker["kill"] = value.attacker["kill"] + 1
		-- end
	end)
	self:addEvent("onCommunicationEnter", function(value)
		if utils.PLAYER.object == self then
			for i, v in pairs(self.elseArray) do
				if i == "16" then
					for i2, v2 in pairs(v) do
						local go = v2.attachedRigidbody.gameObject
						local obj = utils.getObject(go:GetInstanceID())
						if obj.kind == 0 then
							-- print(obj.gameObject.name)
							self["interact"] = obj

							-- local f = self.functions["onCommunication"]
							-- if f ~= nil then
							-- 	local ui = utils.createObject(nil, f.id, f.action, f.frame, 0, 0, 0, 0, 5)
							-- end

							utils.PLAYER.dialogueBox:invokeEvent("onOpen", {action = "new_story_using_actions", frame = 0})
							-- utils.PLAYER.dialogueBox:invokeEvent("onOpen", {action = "TestMenu", frame = 0})

							return
						end
					end
				end
			end
			if self["interact"] ~= nil then
				self["interact"] = nil
			end
		end
	end)
	self:addEvent("onCommunicationExit", function(value)
		utils.PLAYER.dialogueBox:invokeEvent("onBack", 0)
	end)

	self:frameLoop() -- 先执行帧
    return self
end

-- 删除预定
function LCharacterObject:frameLoop()
 	-- print("startloop")
	-- if self.delayCounter >= self.delay then
	-- 	self.delayCounter = 0
	-- end

	-- while self.delayCounter == 0 do
	local delayC = 0
	for i = self.frame + 1, #self.database.characters[self.action], 1 do
		-- if self.frame > #self.database[self.id][self.action].frames then
		-- 	self.frame = 1
		-- 	self:clearCollidersAndCommand()
		-- end
		
		local currentFrame = self.database.characters[self.action][i]

		if currentFrame.category == "Sprite" and currentFrame.wait > 0 then
			self:addEvent(currentFrame.category, delayC, 1, {sprite = self.database.sprites[currentFrame.pic], localPosition = CS.UnityEngine.Vector3(currentFrame.x / 100, -currentFrame.y / 100, 0)})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Move" then
			-- self.vvvX = currentFrame.directionX
			-- self.vvvY = currentFrame.directionY
			self:addEvent(currentFrame.category, delayC, 1, {velocityX = currentFrame.directionX, velocityY = currentFrame.directionY, compute = currentFrame.compute, layers = currentFrame.layers})
		elseif currentFrame.category == "Body" then
			self:addEvent(currentFrame.category, delayC, 1, {id = currentFrame.id, direction = self.direction, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height,
														bodyFlags = currentFrame.bodyFlags, layers = currentFrame.layers})
		elseif currentFrame.category == "Attack" then
			self:addEvent(currentFrame.category, delayC, 1, {id = currentFrame.id, direction = self.direction, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height,
														attackFlags = currentFrame.attackFlags, damage = currentFrame.damage, fall = currentFrame.fall, defence = currentFrame.defence,
														frequency = currentFrame.frequency, directionX = currentFrame.directionX, directionY = currentFrame.directionY, ignoreFlag = false, var = currentFrame.var,
														action = currentFrame.action, frame = currentFrame.frame})
		elseif currentFrame.category == "Sound" then
			self:addEvent(currentFrame.category, delayC, 1, {sfx = currentFrame.sfx})
		elseif currentFrame.category == "Object" then
			self:addEvent(currentFrame.category, delayC, 1, {x = currentFrame.x, y = currentFrame.y, action = currentFrame.action, frame = currentFrame.frame})
		elseif currentFrame.category == "Command" then
			local rA, rB = utils.getRangeAB(currentFrame.range)
			self:addEvent(currentFrame.category, delayC, currentFrame.wait, {command= currentFrame.command, rangeA = rA, rangeB = rB, actFlag = currentFrame.actFlag, layers = currentFrame.layers, active = false})
		elseif currentFrame.category == "Act" then
			self:addEvent(currentFrame.category, delayC, currentFrame.wait, {actFlag = currentFrame.actFlag, layers = currentFrame.layers, command = currentFrame.command, action = currentFrame.action, frame = currentFrame.frame})
		elseif currentFrame.category == "Warp" then

			self:addEvent(currentFrame.category, delayC - 1, 1, {action = currentFrame.action, frame = currentFrame.frame, operator = currentFrame.operator, var = currentFrame.var, value = currentFrame.value})

			
				-- self.vvvX = nil
				-- self.vvvY = nil
			-- if currentFrame.command == nil or currentFrame.fall == nil then
				-- break
			-- end
		elseif currentFrame.category == "End" then
			self:addEvent(currentFrame.category, delayC, 1, nil)
			break
		elseif currentFrame.category == "Set" then
			self:addEvent(currentFrame.category, delayC, 1, {operator = currentFrame.operator, var = currentFrame.var, value = currentFrame.value})
		elseif currentFrame.category == "Palette" then
			self:addEvent(currentFrame.category, delayC, currentFrame.wait, {value = currentFrame.value})
		elseif currentFrame.category == "Catch" then
			self:addEvent(currentFrame.category, delayC, currentFrame.wait, {x = currentFrame.x, y = currentFrame.y, action = currentFrame.action, frame = currentFrame.frame, velocityX = currentFrame.directionX, velocityY = currentFrame.directionY,
																damage = currentFrame.damage,  var = currentFrame.var})
		end
	end
	-- self.delayCounter = self.delayCounter + 1
end

-- 删除预定
function LCharacterObject:runFrame()

	-- self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * CS.UnityEngine.Time.deltaTime

	-- self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime

	-- self:frameLoop()

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

	-- if self.kind ~= 3 and self.kind ~= 5 and not self["isCatched"] then
	-- 	self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * 2/60
	-- end

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


end

-- 删除预定
function LCharacterObject:changeAction(a, f)
	-- self.action = a
	-- self.frame = f
	-- -- self:clearCollidersAndCommand()
	-- self:stopAllEvent()
	-- self:frameLoop()
	table.insert(self.NEXT, {action = a, frame = f})
end

-- 删除预定
function LCharacterObject:updatePic()
end

-- 删除预定
function LCharacterObject:clearCollidersAndCommand()
	for i, v in pairs(self.bodyArray) do
		v:deleteCollider()
		v = nil
	end
	self.bodyArray = {} -- 清空被攻击
	for i, v in pairs(self.attckArray) do
		v:deleteCollider()
		v = nil
	end
	self.attckArray = {} -- 清空攻击


	for i = #self.eventQueue, 1, -1 do -- 清空命令
		if self.eventQueue[i].category == "Command" then
			self.eventQueue[i].wait = 1
			self.eventQueue[i].waitCounter = 1
		end
	end
end

-- 加event来执行逻辑 删除预定
function LCharacterObject:addEvent222(c, d, w, e)
	local event = {}
	event.active = true
	event.isEnd = false
	event.category = c

	event.event = e
	event.temp = d
	event.delay = d
	event.wait = w
	-- local a = cs_coroutine.start(self.eventCoroutine, c, d, w, e, event)
	event.delayCount = 0
	event.waitCount = 0

	table.insert(self.eventQueue, event)
	return event
end

-- 停止所有event 删除预定
function LCharacterObject:stopAllEvent()
	for i = #self.eventQueue, 1, -1 do
		local v = self.eventQueue[i]
		if v.category ~= "Palette" and v.category ~= "Flying" and v.category ~= "Gravity" and v.category ~= "HPMPFallingDefecing" and v.category ~= "Friction" and v.category ~= "FlipX" and v.category ~= "UpdatePostion" and v.category ~= "Collision" and v.category ~= "FindTarget" and v.category ~= "Dead" then
			-- if v.coroutine ~= nil then
			-- 	cs_coroutine.stop(v.coroutine)
			-- end
			table.remove(self.eventQueue, i)
		end
	end
end

-- 删除预定
function LCharacterObject:runEvent222()
	for p, k in ipairs(self.eventQueue) do
	-- for iii = #self.eventQueue, 1, -1 do
	-- 	local k = self.eventQueue[iii]
		local A = true
		local B = true


		if k.delayCount < k.delay or not k.active then
			A = false
		end
		k.delayCount = k.delayCount + 1
		
		if A then

			local e = {}
			e.category = k.category
			e.event = k.event
			if k.waitCount >= k.wait then
				B = false
				k.isEnd = true
			end
			

			if B then

				if e.category == "Sprite" then
					self.spriteRenderer.sprite = e.event.sprite
					self.pic_object.transform.localPosition = e.event.localPosition
				elseif e.category == "Move" then
					if e.event.compute == 0 then
						self.vvvX = e.event.velocityX
						self.vvvY = e.event.velocityY
					elseif e.event.compute == 1 then
						self.accvvvX = e.event.velocityX
						self.accvvvY = e.event.velocityY
					else
						if self.elseArray[e.event.layers] ~= nil then
							for i2, v2 in pairs(self.elseArray[e.event.layers]) do
									self.rigidbody.position = CS.UnityEngine.Vector2(v2.bounds.center.x, v2.bounds.center.y)
		-- 							self.rigidbody.position = CS.UnityEngine.Vector2(v2.transform.position.x, v2.transform.position.y)
		-- 							self.gameObject.transform.position = v2.transform.position
								break
							end
						end
					end
				elseif e.category == "Body" then
					if self.bodyArray[e.event.id] == nil and not (e.event.x == 0 or e.event.y == 0 or e.event.width == 0 or e.event.height == 0) then
						self.bodyArray[e.event.id] = LColliderBDY:new(self.bdy_object, e.event.id)
						self.bodyArray[e.event.id]:setCollider(e.event.direction, e.event.x, e.event.y, e.event.width, e.event.height, e.event.bodyFlags, e.event.layers)
						self.bodyArray_InstanceID[self.bodyArray[e.event.id].collider:GetInstanceID()] = self.bodyArray[e.event.id]
					else
						if self.bodyArray[e.event.id] ~= nil then
							if e.event.x == 0 or e.event.y == 0 or e.event.width == 0 or e.event.height == 0 then
								local IID = self.bodyArray[e.event.id].collider:GetInstanceID()
								self.bodyArray[e.event.id]:deleteCollider()
								self.bodyArray[e.event.id] = nil
								self.bodyArray_InstanceID[IID] = nil
							else
								self.bodyArray[e.event.id]:setCollider(e.event.direction, e.event.x, e.event.y, e.event.width, e.event.height, e.event.bodyFlags, e.event.layers)
							end
						end
					end
				elseif e.category == "Attack" then
					if self.attckArray[e.event.id] == nil and not (e.event.x == 0 or e.event.y == 0 or e.event.width == 0 or e.event.height == 0) then
						self.attckArray[e.event.id] = LColliderATK:new(self.atk_object, e.event.id)
						self.attckArray[e.event.id]:setCollider(e.event.direction, e.event.x, e.event.y, e.event.width, e.event.height, e.event.attackFlags,
																	e.event.damage, e.event.fall, e.event.defence, e.event.frequency, e.event.directionX, e.event.directionY, e.event.ignoreFlag, e.event.var,
																	e.event.action, e.event.frame)
					else
						if self.attckArray[e.event.id] ~= nil then
							if e.event.x == 0 or e.event.y == 0 or e.event.width == 0 or e.event.height == 0 then
								self.attckArray[e.event.id]:deleteCollider()
								self.attckArray[e.event.id] = nil
							else
								self.attckArray[e.event.id]:setCollider(e.event.direction, e.event.x, e.event.y, e.event.width, e.event.height, e.event.attackFlags,
																		e.event.damage, e.event.fall, e.event.defence, e.event.frequency, e.event.directionX, e.event.directionY, e.event.ignoreFlag, e.event.var,
																		e.event.action, e.event.frame)
							end
						end
					end
				elseif e.category == "Sound" then
					self.audioSource.clip = self.database.audioClips[e.event.sfx]
					local r = math.random() / 2.5
					self.audioSource.pitch = 1 + r - 0.2
					self.audioSource:Play()
				elseif e.category == "Object" then
					if e.event.isWorldPosition then
		
						utils.createObject(nil, self.id, e.event.action, e.event.frame, e.event.x, e.event.y, 0, 0, e.event.kind)
					else
						utils.createObject(nil, self.id, e.event.action, e.event.frame, self.rigidbody.position.x + e.event.x, self.rigidbody.position.y + e.event.y, 0, 0, e.event.kind)
					end
				elseif e.category == "Command" then
					if e.event.actFlag ~= nil then
						if e.event.actFlag == 0 and self.isOnGround == 1 | 1 << tonumber(e.event.layers) then
							e.event.active = true
						elseif e.event.actFlag == 2 and self.isElse & (1 << tonumber(e.event.layers)) == 1 << tonumber(e.event.layers) then
							e.event.active = true	
						end
					else
						e.event.active = true
					end
				elseif e.category == "Act" then
					if e.event.command == nil or e.event.command == "" then
						if (e.event.actFlag == 0 and self.isOnGround ~= 1 and self.velocity.y <= 0) or (e.event.actFlag == 1 and self.isWall) or (e.event.actFlag == 2 and self.isElse == 1 | 1 << tonumber(e.event.layers)) then
							self:changeAction(e.event.action, e.event.frame)
							k.isEnd = true
							-- break
						end
					end
				elseif e.category == "Warp" then
					if e.event.operator == nil or e.event.var == nil or e.event.value == nil then
						self:changeAction(e.event.action, e.event.frame)
						-- break
					else
						local res = 1
						if e.event.operator & 32 == 32 then
							if self[e.event.var] == e.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if e.event.operator & 64 == 64 then
							if self[e.event.var] ~= e.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if e.event.operator & 128 == 128 then
							if self[e.event.var] > e.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if e.event.operator & 256 == 256 then
							if self[e.event.var] < e.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end

						if res == 1 then
							self:changeAction(e.event.action, e.event.frame)
							-- break
						end
					end
		
		
		
				elseif e.category == "Set" then
					if e.event.operator & 2 == 2 then
						self[e.event.var] = self[e.event.var] - e.event.value
					elseif e.event.operator & 16 == 16 then
						self[e.event.var] = e.event.value
					end
				elseif e.category == "Palette" then
					for i = #self.eventQueue, 1, -1 do
						local v = self.eventQueue[i]
						if v ~= k and v.category == "Palette"then
							-- if v.coroutine ~= nil then
							-- 	cs_coroutine.stop(v.coroutine)
							-- end
							-- table.remove(self.eventQueue, i)
							v.isEnd = true
						end
					end
					if e.event.value == nil then
						utils.setPalette(self, self.palette)
					else
						local vvv = tonumber(e.event.value)
						if vvv then
							utils.setPalette(self, vvv)
						else
							local t = CS.UnityEngine.Texture2D(256, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
							t.filterMode = CS.UnityEngine.FilterMode.Point
		
							local pixels = self.spriteRenderer.material:GetTexture("_Palette"):GetPixels()
							t:SetPixels(pixels)
							local colors = e.event.value
							for i2, v2 in ipairs(colors) do
								local r = pixels[v2.index].r - v2.color.r / 255
								local g = pixels[v2.index].g - v2.color.g / 255
								local b = pixels[v2.index].b - v2.color.b / 255
								local a = pixels[v2.index].a - v2.color.a / 255
								t:SetPixel(v2.index, 1, CS.UnityEngine.Color(pixels[v2.index].r - r * (k.waitCount / k.wait), pixels[v2.index].g - g * (k.waitCount / k.wait), pixels[v2.index].b - b * (k.waitCount / k.wait), pixels[v2.index].a - a * (k.waitCount / k.wait)))
							end
							t:Apply()
		
							self.spriteRenderer.material:SetTexture("_Palette", t)
						end
					end
				elseif e.category == "Catch" then
					-- for i = #self.eventQueue, 1, -1 do
					-- 	local v = self.eventQueue[i]
					-- 	if v ~= k and v.category == "Catch"then
					-- 		if v.coroutine ~= nil then
					-- 			cs_coroutine.stop(v.coroutine)
					-- 		end
					-- 		table.remove(self.eventQueue, i)
					-- 	end
					-- end
					if e.event.x == nil or e.event.y == nil then
		
						for i2, v2 in ipairs(self.catchedObjects) do
							-- for i3, v3 in ipairs(v2.eventQueue) do
							-- 	if not v3.active then
							-- 		v3.active = true
							-- 	end
							-- end
							v2["isCatched"] = false
		
							v2.velocity.x = self.velocity.x + e.event.velocityX * self.direction.x
							v2.velocity.y = self.velocity.y + e.event.velocityY * self.direction.y

							local hhh = v2[e.event.var]
							v2[e.event.var] = v2[e.event.var] - e.event.damage
							if v2[e.event.var] <= 0 then
								v2[e.event.var] = 0
								v2["falling"] = v2["maxFalling"]
							else
								v2["falling"] = v2["falling"] + v2["maxFalling"]
								if v2["falling"] > v2["maxFalling"] then
									v2["falling"] = v2["maxFalling"]
								end
							end
							v2.target = self -- 切换目标
							if hhh > 0 and v2[e.event.var] == 0 then
								self["kill"] = self["kill"] + 1
							end
		
							v2:changeAction(e.event.action, e.event.frame)
							-- k.isEnd = true
						end
						self.catchedObjects = {}
					else
						for i2, v2 in ipairs(self.catchedObjects) do	
							if v2["isCatched"] then

								v2.rigidbody.position = self.rigidbody.position + CS.UnityEngine.Vector2(self.direction.x * e.event.x / 100, -e.event.y / 100)
								-- for i3, v3 in ipairs(v2.eventQueue) do
								-- 	if v3.active then
								-- 		v3.active = false
								-- 	end
								-- end
		
								if self.direction.x == 1 then
									if v2.direction.x == 1 then
										v2.direction.x = -1
									end
								elseif self.direction.x == -1 then
									if v2.direction.x == -1 then
										v2.direction.x = 1
									end
								end
								if v2.directionBuff.x ~= v2.direction.x then
									if v2.direction.x == -1 then
										v2.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
									else
										v2.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
									end
									v2.directionBuff.x = v2.direction.x
								end

								v2:changeAction(e.event.action, e.event.frame)
							end
						end
					end
				elseif e.category == "End" then
					utils.destroyObject(self.gameObject:GetInstanceID())
					-- self:stopAllEvent()
				elseif e.category == "Hurt" then  -- 从这里开始和bd无关，是自定义event
					local hhh = self[e.event.var]
					self[e.event.var] = self[e.event.var] - e.event.damage
					-- self["MP"] = self["MP"] - e.event.damage
					if self[e.event.var] <= 0 then
						self[e.event.var] = 0
						self["falling"] = self["maxFalling"]
						self["defencing"] = self["maxDefencing"]
					else
						self["falling"] = self["falling"] + e.event.fall
						self["defencing"] = self["defencing"] + e.event.defence
						if self["falling"] > self["maxFalling"] then
							self["falling"] = self["maxFalling"]
						end
						if self["defencing"] > self["maxDefencing"] then
							self["defencing"] = self["maxDefencing"]
						end
					end
					self.target = e.event.attacker -- 切换目标
					if hhh > 0 and self[e.event.var] == 0 then
						e.event.attacker["kill"] = e.event.attacker["kill"] + 1
					end
				elseif e.category == "UpdatePostion" then
					self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
				-- elseif e.category == "HP" then
				-- 	self.HP = self.HP + e.event.damage
				-- elseif e.category == "MP" then
				-- 	self.MP = self.MP + e.event.damage
				-- elseif e.category == "Falling" then
				-- 	self.falling = self.falling + e.event.fall
				-- elseif e.category == "Defecing" then
				-- 	self.defencing = self.defencing + e.event.defence
				elseif e.category == "FlipX" then -- 反向操作
					if self.directionBuff.x ~= self.direction.x then
						if self.direction.x == -1 then
							self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 180, 0)
						else
							self.gameObject.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
						end
						self.directionBuff.x = self.direction.x
					end
				elseif e.category == "Gravity" then
					self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * 2/60
				elseif e.category == "Flying" then
					if (self.action == "standing" or self.action == "walking" or self.action == "running") and self.isOnGround == 1 and self.velocity.y < 0 then
						self:changeAction("jumping_flying", 0)
						-- break
					end
				elseif e.category == "HPMPFallingDefecing" then
					if self["HP"] > 0 then
						self["HP"] = utils.toMaxvalue(self["HP"], self["maxHP"], self["HPRecoveryRate"])
						self["MP"] = utils.toMaxvalue(self["MP"], self["maxMP"], self["MPRecoveryRate"] + (self["MPRecoveryRate"] * (1 - self["HP"] / self["maxHP"])))
					end
					self["falling"] = utils.toOne(self["falling"], self["maxFalling"], self["fallingRecoveryRate"])
					self["defencing"] = utils.toOne(self["defencing"], self["maxDefencing"], self["defencingRecoveryRate"])
				elseif e.category == "Friction" then
					if self.isOnGround ~= 1 then
						local f = self.velocity * CS.UnityEngine.Vector2(1, 0) * 0.20 -- 摩擦系数
						if self.velocity.x > 0 then
							self.velocity = self.velocity - f
							if self.velocity.x < 0 then
								self.velocity.x = 0
							end
						elseif self.velocity.x < 0 then
							self.velocity = self.velocity - f
							if self.velocity.x > 0 then
								self.velocity.x = 0
							end
						end
					end
				elseif e.category == "Input" then
					local bbb = false
					if self["HP"] > 0 then
						for i2, v2 in ipairs(self.eventQueue) do
			
							if v2.category == "Command" and v2.event.active and self["MP"] >= e.event.mp and not v2.event.isEnd then
			
								if (v2.event.rangeA ~= nil and v2.event.rangeB ~= nil and e.event.level ~= nil and e.event.level >= v2.event.rangeA and e.event.level <= v2.event.rangeB) or (v2.event.command ~= nil and v2.event.command == e.event.name) then
			
									if e.event.direction == 1 then
										if self.direction.x == -1 then
											self.direction.x = 1
										end
									elseif e.event.direction == -1 then
										if self.direction.x == 1 then
											self.direction.x = -1
										end
									end

									self["MP"] = self["MP"] - e.event.mp

									self:changeAction(e.event.action, e.event.frame)
									bbb = true
									break
								end
							end
						end
					end
					if bbb then
						break
					end
				elseif e.category == "Force" then
					if e.event.compute == 0 then
						self.velocity.x = 0
						self.velocity.y = 0
					end
					self.velocity.x = self.velocity.x + e.event.velocity.x
					if math.floor(self["falling"] + 0.5) >= 70 then
						self.velocity.y = self.velocity.y + e.event.velocity.y
					end
				elseif e.category == "Injured" then
					local reactions = self.database:getLines("reactions")
					if #reactions > 0 and self.kind == 0 then
						local ttt = {}
						local round = math.floor(self["falling"] + 0.5)
						if self["HP"] <= 0 then
							round = 100
						end
						for i, v in pairs(reactions) do
							local rA, rB = utils.getRangeAB(v.fallingRange)
				-- 				print(round, rA, rB)
		
							
							local d = (e.event.dir * self.direction.x + 1) / 2 + 1
							-- print(self.direction.x, d)
		
							-- print(d)
							if round >= rA and round <= rB and v.direction & d == d then
								table.insert(ttt, {action = v.action, frame = v.frame})
								-- print(v.direction)
							end
						end
						if #ttt > 0 then
							
				-- 						local r = CS.Tools.Instance:RandomRangeInt(1, 101)
				-- 						if r >= 1 and r <= 80 then
				-- 							r = 1
				-- 						elseif r >= 81 and r <= 100 then
				-- 							r = 2
				-- 						end
							local r = CS.Tools.Instance:RandomRangeInt(1, #ttt + 1)
				-- 							print(#ttt, r)
							self:changeAction(ttt[r].action, ttt[r].frame)
							-- break
						end
					end
				elseif e.category == "Collision" then
				elseif e.category == "FindTarget" then
					if self.target == nil then
						local temp = {}
						for i, v in pairs(utils.getObjects()) do
							if v ~= nil and v.kind == 0 and v ~= self and v["HP"] > 0 then
								table.insert(temp, v)
							end
						end
						self.target = temp[CS.Tools.Instance:RandomRangeInt(1, #temp + 1)]
					else
						if self.target["HP"] <= 0 then
							self.target = nil
						end
					end
				-- elseif e.category == "Dead" then
				-- 	if self["HP"] <= 0 then
				-- 		for i2, v2 in ipairs(self.eventQueue) do
				-- 			if (v2.category == "Sprite" and v2.temp == 70) then
				-- 				self:stopAllEvent()
		
				-- 				break
				-- 			end
				-- 		end
				-- 		for i3, v3 in pairs(self.bodyArray) do
				-- 			if v3.filter.layerMask.value & 65536 == 65536 then
				-- 				local lll = CS.UnityEngine.LayerMask()
				-- 				lll.value = v3.filter.layerMask.value & ~(1 << 16)
				-- 				v3.filter.layerMask = lll
				-- 				-- print(v3.filter.layerMask.value, 1 << 16)
				-- 			end
				-- 		end
				-- 	end
				end
			end
			k.waitCount = k.waitCount + 1
		end
		-- k.isEnd = true
	-- 		coroutine.yield(false)
	-- 		print(e.category, "a?")
	end

	for i = #self.eventQueue, 1, -1 do
		-- if self.eventQueue[i].coroutine == nil then
		-- 	table.remove(self.eventQueue, i)
		-- else
			if self.eventQueue[i].isEnd then
				-- cs_coroutine.stop(self.eventQueue[i].coroutine)
				table.remove(self.eventQueue, i)
			end
		-- end
	end

	if #self.NEXT > 0 then

		self.action = self.NEXT[#self.NEXT].action
		self.frame = self.NEXT[#self.NEXT].frame
		-- self:clearCollidersAndCommand()
		self:stopAllEvent()
		self:frameLoop()
		-- for i = 1, #self.NEXT, 1 do
		-- 	table.remove(self.NEXT, i)
		-- end
		self.NEXT = {}
	end

	-- 	local a =  CS.UnityEngine.Vector3(self.rigidbody.position.x, self.rigidbody.position.y, 0)
	-- 	local b =  CS.UnityEngine.Vector3(self.velocity.x, self.velocity.y, 0)
	-- 	CS.UnityEngine.Debug.DrawLine(a, a + b, CS.UnityEngine.Color.blue)
	
end

-- 读取frame
function LCharacterObject:frameLoop()
	self.eventQueue = {}
	self.delayCounter = 0
	local delayC = 0
	for i = self.frame, #self.database.characters[self.action] - 1, 1 do
		local currentFrame = self.database.characters[self.action][i + 1]
		if currentFrame.category == "Sprite" then
			if self.eventQueue[delayC] == nil then
				self.eventQueue[delayC] = {}
			end
			table.insert(self.eventQueue[delayC], 1, currentFrame)
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Sound" or currentFrame.category == "Move" or currentFrame.category == "Body" or currentFrame.category == "Attack" then
			if self.eventQueue[delayC] == nil then
				self.eventQueue[delayC] = {}
			end
			table.insert(self.eventQueue[delayC], 1, currentFrame)
		elseif currentFrame.category == "Command" or currentFrame.category == "Act" then
			for j = 0, currentFrame.wait - 1, 1 do
				if self.eventQueue[delayC + j] == nil then
					self.eventQueue[delayC + j] = {}
				end
				table.insert(self.eventQueue[delayC + j], 1, currentFrame)
			end
		elseif currentFrame.category == "Warp" or currentFrame.category == "End" then
			if self.eventQueue[delayC - 1] == nil then
				self.eventQueue[delayC - 1] = {}
			end
			table.insert(self.eventQueue[delayC - 1], 1, currentFrame)
		end
	end
	self.delay = delayC
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

	if self.isOnGround ~= 1 then
		self:invokeEvent("onGround", nil)
	else
		self:invokeEvent("onFlying", nil)
	end

	if self["HP"] > 0 then
		self:invokeEvent("onLive", nil)
	else
		-- self:invokeEvent("onDead", nil)
	end

	if self.isElse & (1 << 16) == 1 << 16 then
		if self["interact"] == nil then
			self:invokeEvent("onCommunicationEnter", nil)
		end
	else
		if self["interact"] ~= nil then
			self["interact"] = nil
			self:invokeEvent("onCommunicationExit", nil)
		end
	end
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

------------------------------------------------------------------------------

LObjectUI = {UIArray = nil, rectTransform = nil, UIStack = nil}
setmetatable(LObjectUI, LObject)
LObjectUI.__index = LObjectUI
function LObjectUI:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	self = LObject:new(parent, db, id, a, f, go, vx, vy, k)
	setmetatable(self, LObjectUI)

	-- if self["parent"] == nil or self["parent"].UI == nil then
	-- 	self.UI = LUICanvas:new(utils.getLCanvas())
	-- else
	-- 	self.UI = LUICanvas:new(self["parent"].UI.gameObject)
	-- end

	-- local data = nil
	-- for i = 1, #data, 1 do
	-- 	new(data[i].dialogue)
	-- 	func = (
	-- 		if keydown then
	-- 			new(data[i].text[1])
	-- 			func = (
	-- 				if keydown then
	-- 					text = data[i].text[1]
	-- 				end
	-- 			)
	-- 		end			
	-- 	)
	-- end

	-- self["ttt"]["player"] = utils.PLAYER

	self.UIArray = {}

	-- if parent == nil then
        self.gameObject.transform.parent = utils.getLCanvas().transform
    -- else
    --     self.gameObject.transform:SetParent(p.transform)
    -- end

	self.rectTransform = self.gameObject:AddComponent(typeof(CS.UnityEngine.RectTransform))
    self.rectTransform.anchoredPosition = CS.UnityEngine.Vector2.zero
    self.rectTransform.sizeDelta = CS.UnityEngine.Vector2.zero
    self.rectTransform.anchorMin = CS.UnityEngine.Vector2.zero
    self.rectTransform.anchorMax = CS.UnityEngine.Vector2.one
	self.rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)
	self.rectTransform.localScale = CS.UnityEngine.Vector3.one

	self:addEvent("onGroup", function(value)
		if self.UIArray["Group"] == nil then
			self.UIArray["Group"] = LUIGroup:new(self.gameObject, value.x, value.y, value.width, value.height)
		end
		-- self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
		-- self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
	end)
	self:addEvent("onButton", function(value)
		if self:UIStackPeek().UIParts[value.id] == nil then
			self:UIStackPeek().UIParts[value.id] = LUIButton:new(self:UIStackPeek().UI, value.id)
			self:UIStackPeek().UIParts[value.id]:setPosition(value.x, value.y)
			self:UIStackPeek().UIParts[value.id]:setSize(value.width, value.height)
			self:UIStackPeek().UIParts[value.id]:setText(value.text)
			self:UIStackPeek().UIParts[value.id]:setTextAnchor(value.textAnchor)
			if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
				CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self:UIStackPeek().UIParts[value.id].rectTransform.gameObject)
			end
			self:UIStackPeek().UIParts[value.id]:setOnClickFunction(function()
				
				-- print(phase.UIParts[ttt], ttt)
				self:UIStackPeek().UISelected = self:UIStackPeek().UIParts[value.id].gameObject
				if value.displayType == 2 then
					self:invokeEvent("onBack", value.json)
				end
			end)
		else
			self:UIStackPeek().UIParts[value.id]:setPosition(value.x, value.y)
			self:UIStackPeek().UIParts[value.id]:setSize(value.width, value.height)
			self:UIStackPeek().UIParts[value.id]:setText(value.text)
			self:UIStackPeek().UIParts[value.id]:setTextAnchor(value.textAnchor)
		end
	end)
	-- self:addEvent("props", function(value)
	-- 	for i = 1, #value, 1 then
	-- 		self.UIArray[1] = LUIButton:new(self.gameObject, value.x, value.y, value.width, value.height, self.database.sprites[value.pic], value.text)
	-- 	end
	-- end)
	self:addEvent("onEnd", function(value)
		self.eventQueue = {}
		self.delayCounter = 0
	end)

	-- if parent ~= nil and parent.kind == 0 then
	-- 	parent:addEvent("onCommunication", function(value)
	-- 		if value.wocao ~= nil then
	-- 			for i = 1, #value.wocao["story"], 1 do
	-- 				-- print(value.wocao["story"][i].dialogue)

	-- 				LUIButton:new(self.gameObject, 0, i * -12, 200, 12, nil, value.wocao["story"][i].dialogue)
	-- 			end
	-- 		end
	-- 	end)
	-- end

	self.UIStack = {}

	self:addEvent("onBack", function(value)
		if value == nil then
			-- self.eventQueue = {}
			-- self.delayCounter = 0
			self:UIStackPop()
		else
			-- self.eventQueue = {}
			-- self.delayCounter = 0
			while self:UIStackCount() > value do
				self:UIStackPop()
			end
		end
		if self:UIStackCount() > 0 then
		-- if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
			CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self:UIStackPeek().UISelected)
		-- end
		end
	end)
	self:addEvent("onOpen", function(value)
		self:frameLoop(value.action, value.frame)

		-- self.action = value.action
		-- self.frame = value.frame
		-- self:frameLoop()
	end)

	self:frameLoop(self.action, self.frame) -- 先执行帧
	-- self:frameLoop(self.action, self.frame) -- 先执行帧
	return self
end

function LObjectUI:UIStackCount()
	return #self.UIStack
end

function LObjectUI:UIStackPush(ui)
	table.insert(self.UIStack, ui)
	if self:UIStackCount() > 1 then
		self.UIStack[self:UIStackCount() - 1].rectTransform.gameObject:SetActive(false)
	end
end

function LObjectUI:UIStackPop()
	CS.UnityEngine.GameObject.Destroy(self:UIStackPeek().rectTransform.gameObject)
	table.remove(self.UIStack, #self.UIStack)
	if self:UIStackCount() > 0 then
		self:UIStackPeek().rectTransform.gameObject:SetActive(true)
	end
end

function LObjectUI:UIStackPeek()
	return self.UIStack[#self.UIStack]
end

-- 删除预定
function LObjectUI:frameLoop(a, f, d, id)
	local temp = {}
	local idC = id or 0 + f
	local delayC = d or 0
	for i = f + 1, #self.database.characters[a], 1 do

		local currentFrame = self.database.characters[a][i]
		
		-- if currentFrame.category == "Image" and currentFrame.wait > 0 then
			-- self:addEvent(currentFrame.category, delayC, currentFrame.wait, {id = currentFrame.id, sprite = self.database.sprites[currentFrame.pic],
			-- 												x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, color = currentFrame.layers,
			-- 												json = currentFrame.json})
			-- delayC = delayC + currentFrame.wait
			-- print("ddd", i, currentFrame.category)
		if currentFrame.category == "Image" then
			self:addEvent(currentFrame.category, delayC, 1, {sprite = self.database.sprites[currentFrame.pic], id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Text" then
			self:addEvent(currentFrame.category, delayC, 1, {id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, text = currentFrame.text, textAnchor = currentFrame.textAnchor, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Button" then
			self:addEvent(currentFrame.category, delayC, 1, {sprite = self.database.sprites[currentFrame.pic], id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height,
															text = currentFrame.text, textAnchor = currentFrame.textAnchor, command = currentFrame.command, action = currentFrame.action, frame = currentFrame.frame, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Group" then
			self:addEvent(currentFrame.category, delayC, 1, {id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height})
			delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Cursor" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {json = currentFrame.json})
		-- 	delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Control" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {json = currentFrame.json})
		-- 	delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Command" then
			self:addEvent(currentFrame.category, delayC, 1, {command = currentFrame.command, var = currentFrame.var, value = currentFrame.value, isUseVar = currentFrame.isUseVar, action = currentFrame.action, frame = currentFrame.frame})
			delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Move" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {velocityX = currentFrame.directionX, velocityY = currentFrame.directionY, compute = currentFrame.compute, layers = currentFrame.layers})
		-- elseif currentFrame.category == "Sound" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {sfx = currentFrame.sfx})
		elseif currentFrame.category == "Warp" then
			self:addEvent(currentFrame.category, delayC - 1, 1, {action = currentFrame.action, frame = currentFrame.frame, operator = currentFrame.operator, var = currentFrame.var, value = currentFrame.value})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Set" or currentFrame.category == "Plus" or currentFrame.category == "Subtract" or currentFrame.category == "Multiply" or currentFrame.category == "Divide" then
			self:addEvent(currentFrame.category, delayC, 1, {var = currentFrame.var, value = currentFrame.value, isUseVar = currentFrame.isUseVar})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Wait" then
			self:addEvent(currentFrame.category, delayC, 1, nil)
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "End" then

			self:addEvent(currentFrame.category, delayC - 1, 1, nil)
		elseif currentFrame.category == "Loop" then

			for k = 1, self:getValue(currentFrame.wait), 1 do
				idC = self:frameLoop(currentFrame.action, currentFrame.frame, delayC, idC)
			end
		end
		idC = idC + 1
	end
	return idC
end

-- 删除预定
function LObjectUI:runFrame222()
	
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

	if self.kind ~= 3 and self.kind ~= 5 and not self["isCatched"] then
		self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * 2/60
	end

	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
	-- self.UI.rectTransform.anchoredPosition = self.rigidbody.position

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


end

-- 删除预定
function LObjectUI:runEvent222()
	for p, k in ipairs(self.eventQueue) do
		local A = true
		local B = true


		if k.delayCount < k.delay or not k.active then
			A = false
		end
		k.delayCount = k.delayCount + 1
		
		if A then
			if k.waitCount >= k.wait then
				B = false
				k.isEnd = true
			end
			

			if B then

				if k.category == "Image" then
					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIImage:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), k.event.sprite)
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setSprite(k.event.sprite)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					end
				elseif k.category == "Text" then
					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIText:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setText(self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					end
				elseif k.category == "Button" then
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIButton:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), k.event.sprite, self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setColor(k.event.color.image.r, k.event.color.image.g, k.event.color.image.b, k.event.color.image.a)
						self.UIArray[k.event.id]:setTextColor(k.event.color.text.r, k.event.color.text.g, k.event.color.text.b, k.event.color.text.a)
						self.UIArray[k.event.id]:setButtonColor(k.event.color.button.normal.r, k.event.color.button.normal.g, k.event.color.button.normal.b, k.event.color.button.normal.a,
																k.event.color.button.selected.r, k.event.color.button.selected.g, k.event.color.button.selected.b, k.event.color.button.selected.a)

						-- self.UIArray[k.event.id]:setOnClickFunction(function()
						-- 	self:changeAction(k.event.action, k.event.frame)
						-- 	for i, v in pairs(self.UIArray) do
						-- 		if v.gameObject ~= nil then
						-- 			CS.UnityEngine.GameObject.Destroy(v.gameObject)
						-- 		end
						-- 	end
						-- 	self.UIArray = {}
						-- end)
						local s = utils.getLSystem()
						if s.commands[k.event.command].UIActive then
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end

						if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) then
							CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self.UIArray[k.event.id].gameObject)
						end
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setSprite(k.event.sprite)
						self.UIArray[k.event.id]:setText(self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.image.r, k.event.color.image.g, k.event.color.image.b, k.event.color.image.a)
						self.UIArray[k.event.id]:setTextColor(k.event.color.text.r, k.event.color.text.g, k.event.color.text.b, k.event.color.text.a)
						self.UIArray[k.event.id]:setButtonColor(k.event.color.button.normal.r, k.event.color.button.normal.g, k.event.color.button.normal.b, k.event.color.button.normal.a,
																k.event.color.button.selected.r, k.event.color.button.selected.g, k.event.color.button.selected.b, k.event.color.button.selected.a)

						local s = utils.getLSystem()
						if s.commands[k.event.command].UIActive then
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end

						if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject)then
							CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self.UIArray[k.event.id].gameObject)
						end
					end
				elseif k.category == "Group" then

					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIGroup:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height))
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
					end

				-- elseif k.category == "Cursor" then
					-- utils.createObject(nil, self.id, k.event.action, k.event.frame, 0, 0, 0, 0, 5)
				-- elseif k.category == "Control" then
					-- if utils.getLPlayer().keys[k.event.key].state == 3 then
					-- 	self.UIArray[4]:setPosition(self.UIArray[4].rectTransform.anchoredPosition.x, self.UIArray[4].rectTransform.anchoredPosition.y - 5)
					-- end
				elseif k.category == "Set" then
					self[k.event.var] = self:getValue(k.event.value)
				elseif k.category == "Plus" then
					self[k.event.var] = self[k.event.var] + self:getValue(k.event.value)
				elseif k.category == "Subtract" then
					self[k.event.var] = self[k.event.var] - self:getValue(k.event.value)
				elseif k.category == "Multiply" then
					self[k.event.var] = self[k.event.var] * self:getValue(k.event.value)
				elseif k.category == "Divide" then
					self[k.event.var] = self[k.event.var] / self:getValue(k.event.value)
				elseif k.category == "Move" then
					if k.event.compute == 0 then
						self.vvvX = k.event.velocityX
						self.vvvY = k.event.velocityY
					elseif k.event.compute == 1 then
						self.accvvvX = k.event.velocityX
						self.accvvvY = k.event.velocityY
					else
						if self.elseArray[k.event.layers] ~= nil then
							for i2, v2 in pairs(self.elseArray[k.event.layers]) do
									self.rigidbody.position = CS.UnityEngine.Vector2(v2.bounds.center.x, v2.bounds.center.y)
		-- 							self.rigidbody.position = CS.UnityEngine.Vector2(v2.transform.position.x, v2.transform.position.y)
		-- 							self.gameObject.transform.position = v2.transform.position
								break
							end
						end
					end
				elseif k.category == "Sound" then
					self.audioSource.clip = self.database.audioClips[k.event.sfx]
					local r = math.random() / 5
					self.audioSource.pitch = 1 + r - 0.1
					self.audioSource:Play()
				elseif k.category == "Warp" then
					if k.event.operator == nil or k.event.var == nil or k.event.value == nil then
						self:changeAction(k.event.action, k.event.frame)
						-- break
					else
						local res = 1
						if k.event.operator & 32 == 32 then
							if self[k.event.var] == k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if k.event.operator & 128 == 128 then
							if self[k.event.var] > k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if k.event.operator & 256 == 256 then
							if self[k.event.var] < k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end

						if res == 1 then
							self:changeAction(k.event.action, k.event.frame)
							-- break
						end
					end
				elseif k.category == "Command" then
					-- if e.event.actFlag ~= nil then
					-- 	if e.event.actFlag == 0 and self.isOnGround == 1 | 1 << tonumber(e.event.layers) then
					-- 		e.event.active = true
					-- 	elseif e.event.actFlag == 2 and self.isElse & (1 << tonumber(e.event.layers)) == 1 << tonumber(e.event.layers) then
					-- 		e.event.active = true	
					-- 	end
					-- else
					-- 	e.event.active = true
					-- end
					
					local s = utils.getLSystem()
					if s.commands[k.event.command].UIActive then
						if k.event.action == nil and k.event.frame == nil then
							-- if k.event.isUseVar then
							-- 	self[k.event.var] = self[k.event.var] + self:getValue(k.event.value)
							-- else
							-- 	self[k.event.var] = self[k.event.var] + k.event.value
							-- end

							-- print(self[k.event.var])

							-- self[k.event.var] = next(self.UIArray).

							local count = 1

							if k.event.command == "Down" then
								for i, v in pairs(self.UIArray) do
									if v ~= nil then
										count = count + i
									end
								end


								for i = self[k.event.var] + 1, count, 1 do
									if self.UIArray[i] ~= nil then
										self[k.event.var] = i
										break
									end
								end
							elseif k.event.command == "Up" then
								for i = self[k.event.var] - 1, 0, -1 do
									if self.UIArray[i] ~= nil then
										self[k.event.var] = i
										break
									end
								end
							end

						else
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end
					end
				elseif k.category == "Input" then
					-- local bbb = false
					-- if self["HP"] > 0 then
					-- 	for i2, v2 in ipairs(self.eventQueue) do
			
					-- 		if v2.category == "Command" and v2.event.active and self["MP"] >= e.event.mp and not v2.event.isEnd then
			
					-- 			if (v2.event.rangeA ~= nil and v2.event.rangeB ~= nil and e.event.level ~= nil and e.event.level >= v2.event.rangeA and e.event.level <= v2.event.rangeB) or (v2.event.command ~= nil and v2.event.command == e.event.name) then
			
					-- 				if e.event.direction == 1 then
					-- 					if self.direction.x == -1 then
					-- 						self.direction.x = 1
					-- 					end
					-- 				elseif e.event.direction == -1 then
					-- 					if self.direction.x == 1 then
					-- 						self.direction.x = -1
					-- 					end
					-- 				end

					-- 				self["MP"] = self["MP"] - e.event.mp

					-- 				self:changeAction(e.event.action, e.event.frame)
					-- 				bbb = true
					-- 				break
					-- 			end
					-- 		end
					-- 	end
					-- end
					-- if bbb then
					-- 	break
					-- end
				elseif k.category == "End" then
					utils.destroyObject(self.gameObject:GetInstanceID())
					-- self:stopAllEvent()
				end
			end
			k.waitCount = k.waitCount + 1
		end
		-- k.isEnd = true
	-- 		coroutine.yield(false)
	-- 		print(e.category, "a?")
	end

	for i = #self.eventQueue, 1, -1 do
		-- if self.eventQueue[i].coroutine == nil then
		-- 	table.remove(self.eventQueue, i)
		-- else
			if self.eventQueue[i].isEnd then
				-- cs_coroutine.stop(self.eventQueue[i].coroutine)
				table.remove(self.eventQueue, i)
			end
		-- end
	end

	if #self.NEXT > 0 then

		self.action = self.NEXT[#self.NEXT].action
		self.frame = self.NEXT[#self.NEXT].frame
		-- self:clearCollidersAndCommand()
		self:stopAllEvent()
		self:frameLoop(self.action, self.frame)
		-- for i = 1, #self.NEXT, 1 do
		-- 	table.remove(self.NEXT, i)
		-- end
		self.NEXT = {}
	end
end

-- 删除预定
function LObjectUI:changeAction(a, f)
	self.action = a
	self.frame = f
	-- self:clearCollidersAndCommand()
	self:stopAllEvent()
	self:frameLoop(self.action, self.frame)
	-- table.insert(self.NEXT, {action = a, frame = f})
end

-- 停止所有event -- 删除预定
function LObjectUI:stopAllEvent()
	for i = #self.eventQueue, 1, -1 do
		table.remove(self.eventQueue, i)
	end
end

function LObjectUI:idLoop(id)
	for i, v in pairs(self.UIArray) do
		if id == i then
			return false
		end
	end
	return true
end

function LObjectUI:createid(v)
	local id = v
	if id == nil then
		id = 0
	end
	while id < 65535 do
		local judge = self:idLoop(id)

		if judge then
			return id
		end

		id = id + 1
	end
	return nil
end

function LObjectUI:getValue(v)
	if type(v) == "string" then
		local rrr = string.match(v, "%%(.+)%%")
		if rrr ~= nil then
			if string.sub(rrr, 1, 1) == "#" then
				return self:getValue2(string.sub(rrr, 2, #rrr), true)
			else
				return self:getValue2(rrr, false)
			end
		else
			return v
		end



		-- local temp = {}
		-- for rrr in string.gmatch(v, "%b%%") do
		-- 	rrr = string.match(rrr, "%%(.+)%%")
		-- 	print(rrr)
		-- 	local result = nil
		-- 	if string.sub(rrr, 1, 1) == "#" then
		-- 		result = self:getValue2(string.sub(rrr, 2, #rrr), true)
		-- 	else
		-- 		result = self:getValue2(rrr, false)
		-- 	end
		-- 	table.insert(temp, {key = rrr, value = result})
		-- end

		-- if #temp > 0 then
		-- 	local ttt = utils.split(v, "%%")
		-- 	if #ttt > 1 then
		-- 		local count = 1
		-- 		local vvv = ""
		-- 		for i, v in ipairs(ttt) do
		-- 			-- if temp[count] ~= nil then
		-- 			-- 	print(v, temp[count].key, temp[count].value)
		-- 			-- end
					
		-- 			if temp[count] ~= nil and v == temp[count].key then
		-- 				vvv = vvv .. temp[count].value
		-- 				count = count + 1
		-- 			else
		-- 				vvv = vvv .. v
		-- 			end
		-- 		end
		-- 		return vvv
		-- 	else
		-- 		return temp[1].value
		-- 	end
		-- else
		-- 	return v
		-- end

		
		-- local str = ""
		-- for i, rrr in ipairs(ttt) do
		-- 	local result = nil
		-- 	print(rrr)
		-- 	if string.sub(rrr, 1, 1) == "#" then
		-- 		result = self:getValue2(string.sub(rrr, 2, #rrr), true)
		-- 	else
		-- 		result = self:getValue2(rrr, false)
		-- 	end
		-- 	str = str .. result
		-- end
		-- return str
	elseif type(v) == "table" then
		if #v > 1 then
			-- return string.format("字符串：%s\n整数：%d\n小数：%f\n十六进制数：%X","qweqwe",1,0.13,348)
			local str = ""
			for i, vvv in ipairs(v) do
				str = str .. self:getValue(vvv)
			end
			return str
		else
			local rrr = nil
			for i, vvv in pairs(v) do
				rrr = self:getValue(vvv)
				self[i] = rrr
			end
			return rrr
		end
	else
		return v
	end
end

function LObjectUI:getValue2(str, isLen)
	-- local result = nil
	-- local vvv = utils.split(str, ".")
	-- if vvv[1] == "self" then
	-- 	result = self["ttt"]
	-- elseif vvv[1] == "player" then
	-- 	result = utils.PLAYER.object["ttt"]
	-- end
	-- if result == nil then
	-- 	return nil
	-- end
	
	-- for i = 2, #vvv, 1 do
		
	-- 	local r = string.match(vvv[i], "%[(.+)%]")
	-- 	if r ~= nil then
	-- 		print(tonumber(self:getValue(r)))
	-- 		result = result[string.gsub(vvv[i], "%[(.+)%]", "")][tonumber(self:getValue(r))]
	-- 	else
	-- 		result = result[vvv[i]]
	-- 	end
	-- 	if result == nil then
	-- 		return nil
	-- 	end
	-- end
	-- if isLen then
	-- 	return #result
	-- else
	-- 	return result
	-- end


	local result = nil
	local temp = {}
	for s in string.gmatch(str, "%b[]") do
		table.insert(temp, string.match(s, "%[(.+)%]"))
	end
	if #temp > 0 then
		str = string.gsub(str, "%b[]", "[]")
	end
	local vvv = utils.split(str, ".")

	-- print(str)

	local t = 1
	for i = 1, #vvv, 1 do
		-- print(vvv[i], i ,#vvv)
		if vvv[i] == "self" then
			result = self
		elseif vvv[i] == "player" then
			result = utils.PLAYER.object
		elseif vvv[i] == "RANDOM" then
			result = CS.UnityEngine.Random.value
		else
			local r = string.match(vvv[i], "(.+)%[%]")
			if r ~= nil then
				-- print(r, tonumber(self:getValue(temp[t])), temp[t])
				result = result[r][tonumber(self:getValue(temp[t]))]
				t = t + 1
			else
				result = result[vvv[i]]
			end
			if result == nil then
				-- print(result, vvv[i])
				return nil
			end
		end
	end
	if isLen and result ~= nil then
		return #result
	else
		return result
	end
end

-- 每物理帧调用 执行事件
function LObjectUI:runEvent()
end

-- 读取frame
function LObjectUI:frameLoop(a, f, index, x, y, w, h)
	-- self.eventQueue = {}
	-- self.delayCount = 0
	-- local delayC = 0
	-- for i = self.frame, #self.database.characters[self.action] - 1, 1 do
	-- 	local currentFrame = self.database.characters[self.action][i + 1]
	-- 	if currentFrame.category == "Group" or currentFrame.category == "Button" then
	-- 		if self.eventQueue[delayC] == nil then
	-- 			self.eventQueue[delayC] = {}
	-- 		end
	-- 		table.insert(self.eventQueue[delayC], 1, currentFrame)
	-- 		delayC = delayC + currentFrame.wait
	-- 	elseif currentFrame.category == "Warp" or currentFrame.category == "End" then
	-- 		if self.eventQueue[delayC - 1] == nil then
	-- 			self.eventQueue[delayC - 1] = {}
	-- 		end
	-- 		table.insert(self.eventQueue[delayC - 1], 1, currentFrame)
	-- 	end
	-- end
	-- self.delay = delayC
	local idC = index or 0 + f
	if #self.database.characters[a] < 1 then
		return idC
	end
	x = x or 0
	y = y or 0
	w = w or 0
	h = h or 0
	local phase = nil
	if index == nil then
		phase = LPhase:new(self.rectTransform.gameObject, a, f)
		self:UIStackPush(phase)
	else
		phase = self:UIStackPeek()
	end

	for i = f + 1, #self.database.characters[a], 1 do
		local cf = self.database.characters[a][i]
		if cf.category == "Button" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIButton:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, nil, self:getValue(cf.text))
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
					CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(phase.UIParts[idC].gameObject)
				end
				local temp = {}
				if cf.json ~= nil and type(cf.json) == "table" then
					for i, vvv in pairs(cf.json) do
						rrr = self:getValue(vvv)
						temp[i] = rrr
					end
				end
				local ttt = idC
				phase.UIParts[idC]:setOnClickFunction(function()
					
					-- print(phase.UIParts[ttt], ttt)
					phase.UISelected = phase.UIParts[ttt].gameObject
					if cf.action == nil or cf.frame == nil then
						self:invokeEvent("onBack", cf.json)
					elseif cf.displayType == 2 and cf.action ~= nil and cf.frame ~= nil then
						idC = self:frameLoop(cf.action, cf.frame, idC)
					elseif cf.action ~= nil and cf.frame ~= nil then
						for i, vvv in pairs(temp) do
							self[i] = vvv
						end
						self:invokeEvent("onOpen", cf)
					end
				end)
			else
				phase.UIParts[idC]:setText(self:getValue(cf.text))
			end
			idC = idC + 1
		elseif cf.category == "Image" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIImage:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, cf.pic)
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				phase.UIParts[idC]:setColor(cf.color.r,cf.color.g, cf.color.b, cf.color.a)
			else
			end
			idC = idC + 1
		elseif cf.category == "Text" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIText:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, self:getValue(cf.text))
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				phase.UIParts[idC]:setTextAnchor(cf.textAnchor)
			else
			end
			idC = idC + 1
		elseif cf.category == "Loop" then
			local b = false
			local count = 1
			for j = 0, cf.json.col - 1, 1 do
				for k = 0, cf.json.row - 1, 1 do
					idC = self:frameLoop(cf.action, cf.frame, idC, cf.x + (cf.width + w) * k, cf.y + (cf.height + h) * -j)
					count = count + 1
					if count > self:getValue(cf.wait) then
						b = true
						break
					end
				end
				if b then
					break
				end
			end
		elseif cf.category == "Set" then
			if self:judge(cf.json) then
				self[cf.var] = self:getValue(cf.value)
			end
		elseif cf.category == "Plus" then
			if self:judge(cf.json) then
				self[cf.var] = self[cf.var] + self:getValue(cf.value)
			end
		elseif cf.category == "Object" then
			if self:judge(cf.json) then
				utils.PLAYER.object["interact"].action = "testkaiwa"
				utils.PLAYER.object["interact"].frame = 3
				utils.PLAYER.object["interact"]:frameLoop()
			end
		elseif cf.category == "Warp" then
			if self:judge(cf.json) then
				-- self:invokeEvent("onBack", nil)
				print(cf.json.action, cf.json.frame)
				idC = self:frameLoop(cf.json.action, cf.json.frame, idC)
				-- self:invokeEvent("onOpen", {action = cf.json.action, frame = cf.json.frame})
				break
			else
				if cf.action ~= nil and cf.frame ~= 0 then
					self:invokeEvent("onOpen", {action = cf.json.action, frame = cf.json.frame})
					break
				end
			end
		end
	end
	return idC
end

function LObjectUI:judge(json)
	if json ~= nil then
		for i, vvv in pairs(json) do
			if i ~= "action" and i ~= "frame" and i ~= "operator" then
				rrr = self:getValue(vvv)
				if json.operator == "==" then
					if self[i] == rrr then
						return true
					end
				elseif json.operator == "!=" then
					if self[i] ~= rrr then
						return true
					end
				elseif json.operator == "<" then
					if self[i] < rrr then
						return true
					end
				elseif json.operator == ">=" then
					if self[i] >= rrr then
						return true
					end
				else
					print("no opreator matched!!!!!!!!!!!!!!!!!!!")
					return false
				end
			end
		end
	else
		return true
	end
	return false
end

-- -- 读取frame
-- function LObjectUI:frameLoop()

-- 	local phase = LPhase:new(a, f)
-- 	local preb = CS.UnityEngine.Resources.Load("UIs/" .. self.action, typeof(CS.UnityEngine.GameObject))
-- 	if preb == nil then
-- 		return
-- 	end
-- 	phase.UI = CS.UnityEngine.GameObject.Instantiate(preb, self.rectTransform)
-- 	phase.animation = phase.UI:GetComponent(typeof(CS.UnityEngine.Animation))
-- 	-- phase.animation:Play(self.action)
-- 	self:UIStackPush(phase)

-- 	self.eventQueue = {}
-- 	self.delayCounter = 0
-- 	local delayC = 0
-- 	for i = self.frame, #self.database.characters[self.action] - 1, 1 do
-- 		local currentFrame = self.database.characters[self.action][i + 1]
-- 		if currentFrame.category == "Button" then
-- 			if self.eventQueue[delayC] == nil then
-- 				self.eventQueue[delayC] = {}
-- 			end
-- 			table.insert(self.eventQueue[delayC], 1, currentFrame)
-- 			delayC = delayC + currentFrame.wait
-- 		-- elseif currentFrame.category == "Sound" or currentFrame.category == "Move" or currentFrame.category == "Body" or currentFrame.category == "Attack" then
-- 		-- 	if self.eventQueue[delayC] == nil then
-- 		-- 		self.eventQueue[delayC] = {}
-- 		-- 	end
-- 		-- 	table.insert(self.eventQueue[delayC], 1, currentFrame)
-- 		-- elseif currentFrame.category == "Command" or currentFrame.category == "Act" then
-- 		-- 	for j = 0, currentFrame.wait - 1, 1 do
-- 		-- 		if self.eventQueue[delayC + j] == nil then
-- 		-- 			self.eventQueue[delayC + j] = {}
-- 		-- 		end
-- 		-- 		table.insert(self.eventQueue[delayC + j], 1, currentFrame)
-- 		-- 	end
-- 		elseif currentFrame.category == "End" then
-- 			if self.eventQueue[delayC - 1] == nil then
-- 				self.eventQueue[delayC - 1] = {}
-- 			end
-- 			table.insert(self.eventQueue[delayC - 1], 1, currentFrame)
-- 		end
-- 	end
-- 	self.delay = delayC
-- end















































function LObjectUI:new(parent, db, id, a, f, go, vx, vy, k)
	local self = {}
	self = LObject:new(parent, db, id, a, f, go, vx, vy, k)
	setmetatable(self, LObjectUI)

	-- if self["parent"] == nil or self["parent"].UI == nil then
	-- 	self.UI = LUICanvas:new(utils.getLCanvas())
	-- else
	-- 	self.UI = LUICanvas:new(self["parent"].UI.gameObject)
	-- end

	-- local data = nil
	-- for i = 1, #data, 1 do
	-- 	new(data[i].dialogue)
	-- 	func = (
	-- 		if keydown then
	-- 			new(data[i].text[1])
	-- 			func = (
	-- 				if keydown then
	-- 					text = data[i].text[1]
	-- 				end
	-- 			)
	-- 		end			
	-- 	)
	-- end

	-- self["ttt"]["player"] = utils.PLAYER

	self.UIArray = {}

	-- if parent == nil then
        self.gameObject.transform.parent = utils.getLCanvas().transform
    -- else
    --     self.gameObject.transform:SetParent(p.transform)
    -- end

	self.rectTransform = self.gameObject:AddComponent(typeof(CS.UnityEngine.RectTransform))
    self.rectTransform.anchoredPosition = CS.UnityEngine.Vector2.zero
    self.rectTransform.sizeDelta = CS.UnityEngine.Vector2.zero
    self.rectTransform.anchorMin = CS.UnityEngine.Vector2.zero
    self.rectTransform.anchorMax = CS.UnityEngine.Vector2.one
	self.rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)
	self.rectTransform.localScale = CS.UnityEngine.Vector3.one

	self:addEvent("onGroup", function(value)
		if self.UIArray["Group"] == nil then
			self.UIArray["Group"] = LUIGroup:new(self.gameObject, value.x, value.y, value.width, value.height)
		end
		-- self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
		-- self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
	end)
	self:addEvent("onButton", function(value)
		if self:UIStackPeek().UIParts[value.id] == nil then
			self:UIStackPeek().UIParts[value.id] = LUIButton:new(self:UIStackPeek().UI, value.id)
			self:UIStackPeek().UIParts[value.id]:setPosition(value.x, value.y)
			self:UIStackPeek().UIParts[value.id]:setSize(value.width, value.height)
			self:UIStackPeek().UIParts[value.id]:setText(value.text)
			self:UIStackPeek().UIParts[value.id]:setTextAnchor(value.textAnchor)
			if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
				CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self:UIStackPeek().UIParts[value.id].rectTransform.gameObject)
			end
			self:UIStackPeek().UIParts[value.id]:setOnClickFunction(function()
				
				-- print(phase.UIParts[ttt], ttt)
				self:UIStackPeek().UISelected = self:UIStackPeek().UIParts[value.id].gameObject
				if value.displayType == 2 then
					self:invokeEvent("onBack", value.json)
				end
			end)
		else
			self:UIStackPeek().UIParts[value.id]:setPosition(value.x, value.y)
			self:UIStackPeek().UIParts[value.id]:setSize(value.width, value.height)
			self:UIStackPeek().UIParts[value.id]:setText(value.text)
			self:UIStackPeek().UIParts[value.id]:setTextAnchor(value.textAnchor)
		end
	end)
	-- self:addEvent("props", function(value)
	-- 	for i = 1, #value, 1 then
	-- 		self.UIArray[1] = LUIButton:new(self.gameObject, value.x, value.y, value.width, value.height, self.database.sprites[value.pic], value.text)
	-- 	end
	-- end)
	self:addEvent("onEnd", function(value)
		self.eventQueue = {}
		self.delayCounter = 0
	end)

	-- if parent ~= nil and parent.kind == 0 then
	-- 	parent:addEvent("onCommunication", function(value)
	-- 		if value.wocao ~= nil then
	-- 			for i = 1, #value.wocao["story"], 1 do
	-- 				-- print(value.wocao["story"][i].dialogue)

	-- 				LUIButton:new(self.gameObject, 0, i * -12, 200, 12, nil, value.wocao["story"][i].dialogue)
	-- 			end
	-- 		end
	-- 	end)
	-- end

	self.UIStack = {}

	self:addEvent("onBack", function(value)
		if value == nil then
			-- self.eventQueue = {}
			-- self.delayCounter = 0
			self:UIStackPop()
		else
			-- self.eventQueue = {}
			-- self.delayCounter = 0
			while self:UIStackCount() > value do
				self:UIStackPop()
			end
		end
		if self:UIStackCount() > 0 then
		-- if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
			CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self:UIStackPeek().UISelected)
		-- end
		end
	end)
	self:addEvent("onOpen", function(value)
		self:frameLoop(value.action, value.frame)

		-- self.action = value.action
		-- self.frame = value.frame
		-- self:frameLoop()
	end)

	self:frameLoop(self.action, self.frame) -- 先执行帧
	-- self:frameLoop(self.action, self.frame) -- 先执行帧
	return self
end

function LObjectUI:UIStackCount()
	return #self.UIStack
end

function LObjectUI:UIStackPush(ui)
	table.insert(self.UIStack, ui)
	if self:UIStackCount() > 1 then
		self.UIStack[self:UIStackCount() - 1].rectTransform.gameObject:SetActive(false)
	end
end

function LObjectUI:UIStackPop()
	CS.UnityEngine.GameObject.Destroy(self:UIStackPeek().rectTransform.gameObject)
	table.remove(self.UIStack, #self.UIStack)
	if self:UIStackCount() > 0 then
		self:UIStackPeek().rectTransform.gameObject:SetActive(true)
	end
end

function LObjectUI:UIStackPeek()
	return self.UIStack[#self.UIStack]
end

-- 删除预定
function LObjectUI:frameLoop(a, f, d, id)
	local temp = {}
	local idC = id or 0 + f
	local delayC = d or 0
	for i = f + 1, #self.database.characters[a], 1 do

		local currentFrame = self.database.characters[a][i]
		
		-- if currentFrame.category == "Image" and currentFrame.wait > 0 then
			-- self:addEvent(currentFrame.category, delayC, currentFrame.wait, {id = currentFrame.id, sprite = self.database.sprites[currentFrame.pic],
			-- 												x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, color = currentFrame.layers,
			-- 												json = currentFrame.json})
			-- delayC = delayC + currentFrame.wait
			-- print("ddd", i, currentFrame.category)
		if currentFrame.category == "Image" then
			self:addEvent(currentFrame.category, delayC, 1, {sprite = self.database.sprites[currentFrame.pic], id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Text" then
			self:addEvent(currentFrame.category, delayC, 1, {id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height, text = currentFrame.text, textAnchor = currentFrame.textAnchor, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Button" then
			self:addEvent(currentFrame.category, delayC, 1, {sprite = self.database.sprites[currentFrame.pic], id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height,
															text = currentFrame.text, textAnchor = currentFrame.textAnchor, command = currentFrame.command, action = currentFrame.action, frame = currentFrame.frame, color = currentFrame.color})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Group" then
			self:addEvent(currentFrame.category, delayC, 1, {id = idC, parent = currentFrame.parent, x = currentFrame.x, y = currentFrame.y, width = currentFrame.width, height = currentFrame.height})
			delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Cursor" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {json = currentFrame.json})
		-- 	delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Control" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {json = currentFrame.json})
		-- 	delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Command" then
			self:addEvent(currentFrame.category, delayC, 1, {command = currentFrame.command, var = currentFrame.var, value = currentFrame.value, isUseVar = currentFrame.isUseVar, action = currentFrame.action, frame = currentFrame.frame})
			delayC = delayC + currentFrame.wait
		-- elseif currentFrame.category == "Move" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {velocityX = currentFrame.directionX, velocityY = currentFrame.directionY, compute = currentFrame.compute, layers = currentFrame.layers})
		-- elseif currentFrame.category == "Sound" then
		-- 	self:addEvent(currentFrame.category, delayC, 1, {sfx = currentFrame.sfx})
		elseif currentFrame.category == "Warp" then
			self:addEvent(currentFrame.category, delayC - 1, 1, {action = currentFrame.action, frame = currentFrame.frame, operator = currentFrame.operator, var = currentFrame.var, value = currentFrame.value})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Set" or currentFrame.category == "Plus" or currentFrame.category == "Subtract" or currentFrame.category == "Multiply" or currentFrame.category == "Divide" then
			self:addEvent(currentFrame.category, delayC, 1, {var = currentFrame.var, value = currentFrame.value, isUseVar = currentFrame.isUseVar})
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "Wait" then
			self:addEvent(currentFrame.category, delayC, 1, nil)
			delayC = delayC + currentFrame.wait
		elseif currentFrame.category == "End" then

			self:addEvent(currentFrame.category, delayC - 1, 1, nil)
		elseif currentFrame.category == "Loop" then

			for k = 1, self:getValue(currentFrame.wait), 1 do
				idC = self:frameLoop(currentFrame.action, currentFrame.frame, delayC, idC)
			end
		end
		idC = idC + 1
	end
	return idC
end

-- 删除预定
function LObjectUI:runFrame222()
	
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

	if self.kind ~= 3 and self.kind ~= 5 and not self["isCatched"] then
		self.velocity = self.velocity + 0.5 * CS.UnityEngine.Physics2D.gravity * 2/60
	end

	self["velocityX"] = self.velocity.x
	self["velocityY"] = self.velocity.y

	self.rigidbody.position = self.rigidbody.position + self.velocity * CS.UnityEngine.Time.deltaTime
	-- self.UI.rectTransform.anchoredPosition = self.rigidbody.position

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


end

-- 删除预定
function LObjectUI:runEvent222()
	for p, k in ipairs(self.eventQueue) do
		local A = true
		local B = true


		if k.delayCount < k.delay or not k.active then
			A = false
		end
		k.delayCount = k.delayCount + 1
		
		if A then
			if k.waitCount >= k.wait then
				B = false
				k.isEnd = true
			end
			

			if B then

				if k.category == "Image" then
					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIImage:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), k.event.sprite)
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setSprite(k.event.sprite)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					end
				elseif k.category == "Text" then
					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIText:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setText(self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.r, k.event.color.g, k.event.color.b, k.event.color.a)
					end
				elseif k.category == "Button" then
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIButton:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height), k.event.sprite, self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setColor(k.event.color.image.r, k.event.color.image.g, k.event.color.image.b, k.event.color.image.a)
						self.UIArray[k.event.id]:setTextColor(k.event.color.text.r, k.event.color.text.g, k.event.color.text.b, k.event.color.text.a)
						self.UIArray[k.event.id]:setButtonColor(k.event.color.button.normal.r, k.event.color.button.normal.g, k.event.color.button.normal.b, k.event.color.button.normal.a,
																k.event.color.button.selected.r, k.event.color.button.selected.g, k.event.color.button.selected.b, k.event.color.button.selected.a)

						-- self.UIArray[k.event.id]:setOnClickFunction(function()
						-- 	self:changeAction(k.event.action, k.event.frame)
						-- 	for i, v in pairs(self.UIArray) do
						-- 		if v.gameObject ~= nil then
						-- 			CS.UnityEngine.GameObject.Destroy(v.gameObject)
						-- 		end
						-- 	end
						-- 	self.UIArray = {}
						-- end)
						local s = utils.getLSystem()
						if s.commands[k.event.command].UIActive then
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end

						if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) then
							CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self.UIArray[k.event.id].gameObject)
						end
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setSprite(k.event.sprite)
						self.UIArray[k.event.id]:setText(self:getValue(k.event.text))
						self.UIArray[k.event.id]:setTextAnchor(k.event.textAnchor)
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
						self.UIArray[k.event.id]:setColor(k.event.color.image.r, k.event.color.image.g, k.event.color.image.b, k.event.color.image.a)
						self.UIArray[k.event.id]:setTextColor(k.event.color.text.r, k.event.color.text.g, k.event.color.text.b, k.event.color.text.a)
						self.UIArray[k.event.id]:setButtonColor(k.event.color.button.normal.r, k.event.color.button.normal.g, k.event.color.button.normal.b, k.event.color.button.normal.a,
																k.event.color.button.selected.r, k.event.color.button.selected.g, k.event.color.button.selected.b, k.event.color.button.selected.a)

						local s = utils.getLSystem()
						if s.commands[k.event.command].UIActive then
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end

						if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject)then
							CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(self.UIArray[k.event.id].gameObject)
						end
					end
				elseif k.category == "Group" then

					
					if self.UIArray[k.event.id] == nil then
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						self.UIArray[k.event.id] = LUIGroup:new(p, self:getValue(k.event.x), self:getValue(k.event.y), self:getValue(k.event.width), self:getValue(k.event.height))
					else
						local pid = self:getValue(k.event.parent)
						local p = self.UIArray[pid]
						if p ~= nil then
							p = self.UIArray[pid].gameObject
						end
						if p ~= nil and self.UIArray[k.event.id].gameObject.transform.parent ~= p.transform then
							self.UIArray[k.event.id]:setParent(p)
						end
						self.UIArray[k.event.id]:setPosition(self:getValue(k.event.x), self:getValue(k.event.y))
						self.UIArray[k.event.id]:setSize(self:getValue(k.event.width), self:getValue(k.event.height))
					end

				-- elseif k.category == "Cursor" then
					-- utils.createObject(nil, self.id, k.event.action, k.event.frame, 0, 0, 0, 0, 5)
				-- elseif k.category == "Control" then
					-- if utils.getLPlayer().keys[k.event.key].state == 3 then
					-- 	self.UIArray[4]:setPosition(self.UIArray[4].rectTransform.anchoredPosition.x, self.UIArray[4].rectTransform.anchoredPosition.y - 5)
					-- end
				elseif k.category == "Set" then
					self[k.event.var] = self:getValue(k.event.value)
				elseif k.category == "Plus" then
					self[k.event.var] = self[k.event.var] + self:getValue(k.event.value)
				elseif k.category == "Subtract" then
					self[k.event.var] = self[k.event.var] - self:getValue(k.event.value)
				elseif k.category == "Multiply" then
					self[k.event.var] = self[k.event.var] * self:getValue(k.event.value)
				elseif k.category == "Divide" then
					self[k.event.var] = self[k.event.var] / self:getValue(k.event.value)
				elseif k.category == "Move" then
					if k.event.compute == 0 then
						self.vvvX = k.event.velocityX
						self.vvvY = k.event.velocityY
					elseif k.event.compute == 1 then
						self.accvvvX = k.event.velocityX
						self.accvvvY = k.event.velocityY
					else
						if self.elseArray[k.event.layers] ~= nil then
							for i2, v2 in pairs(self.elseArray[k.event.layers]) do
									self.rigidbody.position = CS.UnityEngine.Vector2(v2.bounds.center.x, v2.bounds.center.y)
		-- 							self.rigidbody.position = CS.UnityEngine.Vector2(v2.transform.position.x, v2.transform.position.y)
		-- 							self.gameObject.transform.position = v2.transform.position
								break
							end
						end
					end
				elseif k.category == "Sound" then
					self.audioSource.clip = self.database.audioClips[k.event.sfx]
					local r = math.random() / 5
					self.audioSource.pitch = 1 + r - 0.1
					self.audioSource:Play()
				elseif k.category == "Warp" then
					if k.event.operator == nil or k.event.var == nil or k.event.value == nil then
						self:changeAction(k.event.action, k.event.frame)
						-- break
					else
						local res = 1
						if k.event.operator & 32 == 32 then
							if self[k.event.var] == k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if k.event.operator & 128 == 128 then
							if self[k.event.var] > k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end
						if k.event.operator & 256 == 256 then
							if self[k.event.var] < k.event.value then
								res = res & 1
							else
								res = res & 0
							end
						end

						if res == 1 then
							self:changeAction(k.event.action, k.event.frame)
							-- break
						end
					end
				elseif k.category == "Command" then
					-- if e.event.actFlag ~= nil then
					-- 	if e.event.actFlag == 0 and self.isOnGround == 1 | 1 << tonumber(e.event.layers) then
					-- 		e.event.active = true
					-- 	elseif e.event.actFlag == 2 and self.isElse & (1 << tonumber(e.event.layers)) == 1 << tonumber(e.event.layers) then
					-- 		e.event.active = true	
					-- 	end
					-- else
					-- 	e.event.active = true
					-- end
					
					local s = utils.getLSystem()
					if s.commands[k.event.command].UIActive then
						if k.event.action == nil and k.event.frame == nil then
							-- if k.event.isUseVar then
							-- 	self[k.event.var] = self[k.event.var] + self:getValue(k.event.value)
							-- else
							-- 	self[k.event.var] = self[k.event.var] + k.event.value
							-- end

							-- print(self[k.event.var])

							-- self[k.event.var] = next(self.UIArray).

							local count = 1

							if k.event.command == "Down" then
								for i, v in pairs(self.UIArray) do
									if v ~= nil then
										count = count + i
									end
								end


								for i = self[k.event.var] + 1, count, 1 do
									if self.UIArray[i] ~= nil then
										self[k.event.var] = i
										break
									end
								end
							elseif k.event.command == "Up" then
								for i = self[k.event.var] - 1, 0, -1 do
									if self.UIArray[i] ~= nil then
										self[k.event.var] = i
										break
									end
								end
							end

						else
							self:changeAction(k.event.action, k.event.frame)
							for i, v in pairs(self.UIArray) do
								if v.gameObject ~= nil then
									CS.UnityEngine.GameObject.Destroy(v.gameObject)
								end
							end
							self.UIArray = {}
						end
					end
				elseif k.category == "Input" then
					-- local bbb = false
					-- if self["HP"] > 0 then
					-- 	for i2, v2 in ipairs(self.eventQueue) do
			
					-- 		if v2.category == "Command" and v2.event.active and self["MP"] >= e.event.mp and not v2.event.isEnd then
			
					-- 			if (v2.event.rangeA ~= nil and v2.event.rangeB ~= nil and e.event.level ~= nil and e.event.level >= v2.event.rangeA and e.event.level <= v2.event.rangeB) or (v2.event.command ~= nil and v2.event.command == e.event.name) then
			
					-- 				if e.event.direction == 1 then
					-- 					if self.direction.x == -1 then
					-- 						self.direction.x = 1
					-- 					end
					-- 				elseif e.event.direction == -1 then
					-- 					if self.direction.x == 1 then
					-- 						self.direction.x = -1
					-- 					end
					-- 				end

					-- 				self["MP"] = self["MP"] - e.event.mp

					-- 				self:changeAction(e.event.action, e.event.frame)
					-- 				bbb = true
					-- 				break
					-- 			end
					-- 		end
					-- 	end
					-- end
					-- if bbb then
					-- 	break
					-- end
				elseif k.category == "End" then
					utils.destroyObject(self.gameObject:GetInstanceID())
					-- self:stopAllEvent()
				end
			end
			k.waitCount = k.waitCount + 1
		end
		-- k.isEnd = true
	-- 		coroutine.yield(false)
	-- 		print(e.category, "a?")
	end

	for i = #self.eventQueue, 1, -1 do
		-- if self.eventQueue[i].coroutine == nil then
		-- 	table.remove(self.eventQueue, i)
		-- else
			if self.eventQueue[i].isEnd then
				-- cs_coroutine.stop(self.eventQueue[i].coroutine)
				table.remove(self.eventQueue, i)
			end
		-- end
	end

	if #self.NEXT > 0 then

		self.action = self.NEXT[#self.NEXT].action
		self.frame = self.NEXT[#self.NEXT].frame
		-- self:clearCollidersAndCommand()
		self:stopAllEvent()
		self:frameLoop(self.action, self.frame)
		-- for i = 1, #self.NEXT, 1 do
		-- 	table.remove(self.NEXT, i)
		-- end
		self.NEXT = {}
	end
end

-- 删除预定
function LObjectUI:changeAction(a, f)
	self.action = a
	self.frame = f
	-- self:clearCollidersAndCommand()
	self:stopAllEvent()
	self:frameLoop(self.action, self.frame)
	-- table.insert(self.NEXT, {action = a, frame = f})
end

-- 停止所有event -- 删除预定
function LObjectUI:stopAllEvent()
	for i = #self.eventQueue, 1, -1 do
		table.remove(self.eventQueue, i)
	end
end

function LObjectUI:idLoop(id)
	for i, v in pairs(self.UIArray) do
		if id == i then
			return false
		end
	end
	return true
end

function LObjectUI:createid(v)
	local id = v
	if id == nil then
		id = 0
	end
	while id < 65535 do
		local judge = self:idLoop(id)

		if judge then
			return id
		end

		id = id + 1
	end
	return nil
end

function LObjectUI:getValue(v)
	if type(v) == "string" then
		local rrr = string.match(v, "%%(.+)%%")
		if rrr ~= nil then
			if string.sub(rrr, 1, 1) == "#" then
				return self:getValue2(string.sub(rrr, 2, #rrr), true)
			else
				return self:getValue2(rrr, false)
			end
		else
			return v
		end



		-- local temp = {}
		-- for rrr in string.gmatch(v, "%b%%") do
		-- 	rrr = string.match(rrr, "%%(.+)%%")
		-- 	print(rrr)
		-- 	local result = nil
		-- 	if string.sub(rrr, 1, 1) == "#" then
		-- 		result = self:getValue2(string.sub(rrr, 2, #rrr), true)
		-- 	else
		-- 		result = self:getValue2(rrr, false)
		-- 	end
		-- 	table.insert(temp, {key = rrr, value = result})
		-- end

		-- if #temp > 0 then
		-- 	local ttt = utils.split(v, "%%")
		-- 	if #ttt > 1 then
		-- 		local count = 1
		-- 		local vvv = ""
		-- 		for i, v in ipairs(ttt) do
		-- 			-- if temp[count] ~= nil then
		-- 			-- 	print(v, temp[count].key, temp[count].value)
		-- 			-- end
					
		-- 			if temp[count] ~= nil and v == temp[count].key then
		-- 				vvv = vvv .. temp[count].value
		-- 				count = count + 1
		-- 			else
		-- 				vvv = vvv .. v
		-- 			end
		-- 		end
		-- 		return vvv
		-- 	else
		-- 		return temp[1].value
		-- 	end
		-- else
		-- 	return v
		-- end

		
		-- local str = ""
		-- for i, rrr in ipairs(ttt) do
		-- 	local result = nil
		-- 	print(rrr)
		-- 	if string.sub(rrr, 1, 1) == "#" then
		-- 		result = self:getValue2(string.sub(rrr, 2, #rrr), true)
		-- 	else
		-- 		result = self:getValue2(rrr, false)
		-- 	end
		-- 	str = str .. result
		-- end
		-- return str
	elseif type(v) == "table" then
		if #v > 1 then
			-- return string.format("字符串：%s\n整数：%d\n小数：%f\n十六进制数：%X","qweqwe",1,0.13,348)
			local str = ""
			for i, vvv in ipairs(v) do
				str = str .. self:getValue(vvv)
			end
			return str
		else
			local rrr = nil
			for i, vvv in pairs(v) do
				rrr = self:getValue(vvv)
				self[i] = rrr
			end
			return rrr
		end
	else
		return v
	end
end

function LObjectUI:getValue2(str, isLen)
	-- local result = nil
	-- local vvv = utils.split(str, ".")
	-- if vvv[1] == "self" then
	-- 	result = self["ttt"]
	-- elseif vvv[1] == "player" then
	-- 	result = utils.PLAYER.object["ttt"]
	-- end
	-- if result == nil then
	-- 	return nil
	-- end
	
	-- for i = 2, #vvv, 1 do
		
	-- 	local r = string.match(vvv[i], "%[(.+)%]")
	-- 	if r ~= nil then
	-- 		print(tonumber(self:getValue(r)))
	-- 		result = result[string.gsub(vvv[i], "%[(.+)%]", "")][tonumber(self:getValue(r))]
	-- 	else
	-- 		result = result[vvv[i]]
	-- 	end
	-- 	if result == nil then
	-- 		return nil
	-- 	end
	-- end
	-- if isLen then
	-- 	return #result
	-- else
	-- 	return result
	-- end


	local result = nil
	local temp = {}
	for s in string.gmatch(str, "%b[]") do
		table.insert(temp, string.match(s, "%[(.+)%]"))
	end
	if #temp > 0 then
		str = string.gsub(str, "%b[]", "[]")
	end
	local vvv = utils.split(str, ".")

	-- print(str)

	local t = 1
	for i = 1, #vvv, 1 do
		-- print(vvv[i], i ,#vvv)
		if vvv[i] == "self" then
			result = self
		elseif vvv[i] == "player" then
			result = utils.PLAYER.object
		elseif vvv[i] == "RANDOM" then
			result = CS.UnityEngine.Random.value
		else
			local r = string.match(vvv[i], "(.+)%[%]")
			if r ~= nil then
				-- print(r, tonumber(self:getValue(temp[t])), temp[t])
				result = result[r][tonumber(self:getValue(temp[t]))]
				t = t + 1
			else
				result = result[vvv[i]]
			end
			if result == nil then
				-- print(result, vvv[i])
				return nil
			end
		end
	end
	if isLen and result ~= nil then
		return #result
	else
		return result
	end
end

-- 每物理帧调用 执行事件
function LObjectUI:runEvent()
end

-- 读取frame
function LObjectUI:frameLoop(a, f, index, x, y, w, h)
	-- self.eventQueue = {}
	-- self.delayCount = 0
	-- local delayC = 0
	-- for i = self.frame, #self.database.characters[self.action] - 1, 1 do
	-- 	local currentFrame = self.database.characters[self.action][i + 1]
	-- 	if currentFrame.category == "Group" or currentFrame.category == "Button" then
	-- 		if self.eventQueue[delayC] == nil then
	-- 			self.eventQueue[delayC] = {}
	-- 		end
	-- 		table.insert(self.eventQueue[delayC], 1, currentFrame)
	-- 		delayC = delayC + currentFrame.wait
	-- 	elseif currentFrame.category == "Warp" or currentFrame.category == "End" then
	-- 		if self.eventQueue[delayC - 1] == nil then
	-- 			self.eventQueue[delayC - 1] = {}
	-- 		end
	-- 		table.insert(self.eventQueue[delayC - 1], 1, currentFrame)
	-- 	end
	-- end
	-- self.delay = delayC
	local idC = index or 0 + f

	if self.database.characters[a] == nil then
		return idC
	end

	if #self.database.characters[a] < 1 then
		return idC
	end
	x = x or 0
	y = y or 0
	w = w or 0
	h = h or 0
	local phase = nil
	if index == nil then
		phase = LPhase:new(self.rectTransform.gameObject, a, f)
		self:UIStackPush(phase)
	else
		phase = self:UIStackPeek()
	end

	for i = f + 1, #self.database.characters[a], 1 do
		local cf = self.database.characters[a][i]
		if cf.category == "Button" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIButton:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, nil, self:getValue(cf.text))
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				if CS.Tools.Instance:IsNull(CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject) or not CS.UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.activeInHierarchy then
					CS.UnityEngine.EventSystems.EventSystem.current:SetSelectedGameObject(phase.UIParts[idC].gameObject)
				end
				local temp = {}
				if cf.json ~= nil and type(cf.json) == "table" then
					for i, vvv in pairs(cf.json) do
						rrr = self:getValue(vvv)
						temp[i] = rrr
					end
				end
				local ttt = idC
				phase.UIParts[idC]:setOnClickFunction(function()
					
					-- print(phase.UIParts[ttt], ttt)
					phase.UISelected = phase.UIParts[ttt].gameObject
					if cf.action == nil or cf.frame == nil then
						self:invokeEvent("onBack", cf.json)
					elseif cf.displayType == 2 and cf.action ~= nil and cf.frame ~= nil then
						idC = self:frameLoop(cf.action, cf.frame, idC)
					elseif cf.action ~= nil and cf.frame ~= nil then
						for i, vvv in pairs(temp) do
							self[i] = vvv
						end
						self:invokeEvent("onOpen", cf)
					end
				end)
			else
				phase.UIParts[idC]:setText(self:getValue(cf.text))
			end
			idC = idC + 1
		elseif cf.category == "Image" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIImage:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, cf.pic)
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				phase.UIParts[idC]:setColor(cf.color.r,cf.color.g, cf.color.b, cf.color.a)
			else
			end
			idC = idC + 1
		elseif cf.category == "Text" then
			if phase.UIParts[idC] == nil then
				phase.UIParts[idC] = LUIText:new(phase.rectTransform.gameObject, cf.x + x, cf.y + y, cf.width + w, cf.height + h, self:getValue(cf.text))
				phase.UIParts[idC].gameObject.name = phase.UIParts[idC].gameObject.name .. " " .. idC
				phase.UIParts[idC]:setTextAnchor(cf.textAnchor)
			else
			end
			idC = idC + 1
		elseif cf.category == "Loop" then
			local b = false
			local count = 1
			for j = 0, cf.json.col - 1, 1 do
				for k = 0, cf.json.row - 1, 1 do
					idC = self:frameLoop(cf.action, cf.frame, idC, cf.x + (cf.width + w) * k, cf.y + (cf.height + h) * -j)
					count = count + 1
					if count > self:getValue(cf.wait) then
						b = true
						break
					end
				end
				if b then
					break
				end
			end
		elseif cf.category == "Set" then
			if self:judge(cf.json) then
				self[cf.var] = self:getValue(cf.value)
			end
		elseif cf.category == "Plus" then
			if self:judge(cf.json) then
				self[cf.var] = self[cf.var] + self:getValue(cf.value)
			end
		elseif cf.category == "Object" then
			if self:judge(cf.json) then
				utils.PLAYER.object["interact"].action = "testkaiwa"
				utils.PLAYER.object["interact"].frame = 3
				utils.PLAYER.object["interact"]:frameLoop()
			end
		elseif cf.category == "Warp" then
			if self:judge(cf.json) then
				-- self:invokeEvent("onBack", nil)
				print(cf.json.action, cf.json.frame)
				idC = self:frameLoop(cf.json.action, cf.json.frame, idC)
				-- self:invokeEvent("onOpen", {action = cf.json.action, frame = cf.json.frame})
				break
			else
				if cf.action ~= nil and cf.frame ~= 0 then
					self:invokeEvent("onOpen", {action = cf.json.action, frame = cf.json.frame})
					break
				end
			end
		end
	end
	return idC
end

function LObjectUI:judge(json)
	if json ~= nil then
		for i, vvv in pairs(json) do
			if i ~= "action" and i ~= "frame" and i ~= "operator" then
				rrr = self:getValue(vvv)
				if json.operator == "==" then
					if self[i] == rrr then
						return true
					end
				elseif json.operator == "!=" then
					if self[i] ~= rrr then
						return true
					end
				elseif json.operator == "<" then
					if self[i] < rrr then
						return true
					end
				elseif json.operator == ">=" then
					if self[i] >= rrr then
						return true
					end
				else
					print("no opreator matched!!!!!!!!!!!!!!!!!!!")
					return false
				end
			end
		end
	else
		return true
	end
	return false
end