-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

utils = require "LUtils"
require "LCollider"
-- local cs_coroutine = (require 'cs_coroutine')

-- wolai = setmetatable({5}, {
-- 	__call = function(n)
-- 		if wolai[1] ~= n then
-- 			print("bian le!", wolai[1], n)
-- 			wolai[1] = n
-- 		end
-- 		return wolai[1]
-- 	end
-- })

local maxBitCount = 63 -- 最大实体数
local maxBit = (1 << maxBitCount) - 1

local cache = {}

function utils.getCache()
	return cache
end

local components = { _typeIDCounter = 0 }

-- 注册组件
function utils.registerComponent(newtype, func)

	local typeid = components._typeIDCounter + 1
	assert(typeid <= maxBitCount)
	components._typeIDCounter = typeid
	components[newtype] = typeid
	components[typeid] = func

	-- components[typeid] = { new = cnew, del = cdel }
end

-- 添加组件
function utils.addComponent(object, ctype, ...)
    local typeid = components[ctype]

    components[typeid](object, ...)

    object._bit = object._bit | 2 ^ (typeid - 1)
end

function utils.newLObject()
	local this = { _bit = 0 }
    -- 组件添加或删除时执行
    bind(this, "_bit", function(t, val, old)
        cache[old] = cache[old] or {}
        cache[old][t] = nil
        if next(cache[old]) == nil then
            cache[old] = nil
        end

        if val ~= 0 and val ~= nil then
            cache[val] = cache[val] or {}
            cache[val][t] = t
        end
    end)
	return this
end

-- 删除实体
function utils.deleteLObject(object)
    for i, v in pairs(object.bind____) do
        unbind(object, i)
    end
    object._bit = 0
    
	utils.destroyObject()
end

function utils.allOf(...)
    local f = { ... }
    local bit = 0
    for i, v in ipairs(f) do
		bit = bit | 2 ^ (v - 1)
    end
    return bit
end

function utils.getComponentID(ctype)
    return components[ctype]
end

-- 获取匹配的实体
function utils.getMatchedEntity(bit)
    local res = {}

    for i, v in pairs(cache) do
        if i >= bit and i | bit == i then
            for j, v2 in pairs(v) do
                table.insert(res, j)
            end
        end
    end

    return res
end

local systems = { _typeIDCounter = 0 }

function utils.registerSystem(newtype, bit, func)

    local typeid = systems._typeIDCounter + 1
	-- assert(typeid <= maxBitCount)
	systems._typeIDCounter = typeid
	systems[newtype] = typeid
    
	systems[typeid] = {
        MatchedBit = bit,
        matchedEntity = {},
        execute = func
    }

	-- components[typeid] = { new = cnew, del = cdel }
end

utils.registerComponent("DataBase", function(this, id, a, s)
	this.database = utils.getIDData(id)
	this.id = id
	this.palette = 1
	this.action = a
	this.state = s
	this.delayCounter = 0

	this.direction = CS.UnityEngine.Vector3(1, -1, 1)
	this.root = this
	this.parent = this
	this.children = {}
	this.speed = 1
	this.timeLine = 0
	this.localTimeLine = 0
end)

utils.registerComponent("Render", function(this)
	this.rotation = 0
	this.rotation_velocity = 0

	this.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
	this.pic_offset_object_id = this.pic_offset_object:GetInstanceID()
	CS.LuaUtil.AddGameObjectID(this.pic_offset_object_id, this.pic_offset_object)
	-- self.pic_offset_object.transform:SetParent(self.gameObject.transform)
	this.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
	this.pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	-- self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3.one
	this.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)

	this.audioSource = this.pic_offset_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
	this.audioSource.playOnAwake = false

	this.pic_object = CS.UnityEngine.GameObject("pic")
	this.pic_object_id = this.pic_object:GetInstanceID()
	CS.LuaUtil.AddGameObjectID(this.pic_object_id, this.pic_object)
	this.pic_object.transform:SetParent(this.pic_offset_object.transform)
	this.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	this.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
	this.spriteRenderer = this.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	this.spriteRenderer.material = this.database.palettes[1]
end)
utils.registerComponent("UI", function(this, parent, kind)
	if kind == 1 then
		this.image_object = CS.UnityEngine.GameObject("image")
		-- this.image_object.transform:SetParent(this.UI_object.transform)
		this.image_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		this.image_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		-- local rectTransform = this.image_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		this.image = this.image_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
		this.image.sprite = nil
		this.image.material = this.database.palettes_ui[1]

		this.image.raycastTarget = false

		this.UI_object = this.image_object
	elseif kind == 2 then
		this.text_object = CS.UnityEngine.GameObject("text")
		this.text_object.transform:SetParent(this.UI_object.transform)
		this.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		this.text_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		-- local rectTransform = this.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		this.text = this.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
		this.text.font = utils.getFont()
		this.text.fontSize = 12
		this.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

		-- this.text.material = this.database.palettes_ui[1]
	elseif kind == 3 then
		this.button_object = CS.UnityEngine.GameObject("button")
		this.button_object.transform:SetParent(this.UI_object.transform)
		this.button_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		this.button_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		-- local rectTransform = this.button_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		this.image = this.button_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
		this.image.sprite = nil
		this.image.material = this.database.palettes_ui[1]

		this.button = this.button_object:AddComponent(typeof(CS.UnityEngine.UI.Button))

		utils.setButtonColor(this, 127, 127, 127, 255, 240, 199, 50, 255, 191, 0, 0, 255)

		this.text_object = CS.UnityEngine.GameObject("text")
		this.text_object.transform:SetParent(this.button_object.transform)
		this.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		this.text_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		-- local rectTransform = this.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(0, -15)
		-- rectTransform.sizeDelta = CS.UnityEngine.Vector2(100, 12)
		-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		this.text = this.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
		this.text.font = utils.getFont()
		this.text.fontSize = 12
		this.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

		-- this.text.material = this.database.palettes_ui[1]

		-- utils.addEvent("OnClick", function(this, value)
		-- 	if this.image.rectTransform.anchoredPosition.x <= this.image.rectTransform.anchoredPosition.x then
		-- 		print("wocao")
		-- 	end
		-- end)

		-- this.button.onClick:AddListener(function()
		-- 	print("wocao")
		-- end)
		
	end

	if parent == nil then
		this.UI_object.transform:SetParent(utils.getLCanvas().transform)
	else
		-- this.UI_object.transform:SetParent(p.transform)
		this.UI_object.transform:SetParent(parent.rectTransform)

		this.team = parent.team
		if this.image ~= nil then
			this.image.material = parent.image.material
		end
	end

	this.rectTransform = this.UI_object:GetComponent(typeof(CS.UnityEngine.RectTransform))
	-- this.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
	-- this.rectTransform.sizeDelta = CS.UnityEngine.Vector2(0, 0)
	-- this.rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
	-- this.rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
	-- this.rectTransform.pivot = CS.UnityEngine.Vector2(0, 1)
end)
utils.registerComponent("Physical", function(this, parent, x, y, z, vx, vy, vz)
	this.team = 0
	this.velocity = CS.UnityEngine.Vector3(vx, vy, vz)

	-- 	self.animation:AddClip(_v, _v.name)
	-- end
	-- self.animation.animatePhysics = true

	this.physics_object = CS.UnityEngine.GameObject("physics")
	-- self.physics_object.transform:SetParent(self.gameObject.transform)
	this.physics_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
	this.physics_object.transform.position = CS.UnityEngine.Vector3(x, y, z)
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

	this.rigidbody = this.physics_object:AddComponent(typeof(CS.UnityEngine.Rigidbody))
	-- self.rigidbody.useGravity = false
	this.rigidbody.isKinematic = true
	-- self.rigidbody.detectCollisions = false
	this.rigidbody.freezeRotation = true

	this.rigidbody_id = this.rigidbody:GetInstanceID()
	CS.LuaUtil.AddID2(this.rigidbody_id, this.rigidbody)

	-- this.vvvX = nil
	-- this.vvvY = nil
	-- this.accvvvX = nil
	-- this.accvvvY = nil
	-- this.accvvvZ = nil

	
	-- self.isWall = false
	-- self.isCeiling = false
	this.isOnGround = -1
	-- self.isElse = 1
	-- self.elseArray = {}

	this.attckArray = {}
	this.bodyArray = {}
	this.bodyArray_InstanceID = {}

	-- if self.kind == 3 then -- 非人物体暂定-20层
	-- 	self.spriteRenderer.sortingOrder = 20
	-- end

	this.atk_object = CS.UnityEngine.GameObject("atk")
	this.atk_object.transform:SetParent(this.physics_object.transform)
	this.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	this.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

	this.bdy_object = CS.UnityEngine.GameObject("bdy[16]")
	this.bdy_object.transform:SetParent(this.physics_object.transform)
	this.bdy_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	this.bdy_object.transform.localScale = CS.UnityEngine.Vector3.one
	this.bdy_object.layer = 16 -- bdy的layer暂定16

	utils.SetParentAndRoot(this, parent)

	this.oriPos2 = this.physics_object.transform.position
	this.oriPos = this.rigidbody.position
end)
utils.registerComponent("Control", function(this, c, ai)
	this.controller = c
	this.AI = ai
end)
utils.registerComponent("Target", function(this, t)
	this.target = t
end)
utils.registerComponent("Active", function(this)
	-- this.sleep = false
end)

-- function LObject(parent, db, id, a, f, s, x, y, z, vx, vy, vz, k)
-- 	local self = {}
-- 	-- setmetatable(self, LObject)

--     self.database = db
-- 	self.id = id
-- 	self.action = a
-- 	self.frame = f
-- 	self.delayCounter = 0

-- 	self.root = self
-- 	self.parent = self
-- 	self.children = {}
-- 	self.speed = 1
-- 	self.timeLine = 0
-- 	self.localTimeLine = 0
-- 	self.state = s
-- 	self.controller = nil
-- 	self.sleep = false

-- 	self.team = 0

-- 	self.rotation = 0
-- 	self.rotation_velocity = 0

-- 	-- for _i, _v in ipairs(self.database:getLines("vars")) do
-- 	-- 	self[_v.name] = _v.default
-- 	-- 	-- print(_v.name, self[_v.name])
-- 	-- end

-- 	-- self.functions = {}
-- 	-- for _i, _v in ipairs(self.database:getLines("functions")) do
-- 	-- 	self.functions[_v.name] = _v.value
-- 	-- end

-- 	-- self["parent"] = parent

-- 	-- if k ~= 5 then
-- 	-- 	self["story"] = self.database:getLines("story")
-- 	-- end

-- 	self.direction = CS.UnityEngine.Vector3(1, -1, 1)
-- 	-- self.directionBuff = CS.UnityEngine.Vector3(1, -1, 1)

-- 	self.velocity = CS.UnityEngine.Vector3(vx, vy, vz)

-- 	self.kind = k

	
-- 	self.AI = false
-- 	self.target = nil


-- 	if self.kind == 1 or self.kind == 2 or self.kind == 3 then
-- 		if self.kind == 1 then
-- 			self.image_object = CS.UnityEngine.GameObject("image")
-- 			-- self.image_object.transform:SetParent(self.UI_object.transform)
-- 			self.image_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 			self.image_object.transform.localScale = CS.UnityEngine.Vector3.one
		
-- 			-- local rectTransform = self.image_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
-- 			-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
-- 			-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
-- 			-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

-- 			self.image = self.image_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
-- 			self.image.sprite = nil
-- 			self.image.material = self.database.palettes_ui[1]

-- 			self.image.raycastTarget = false

-- 			self.UI_object = self.image_object
-- 		elseif self.kind == 2 then
-- 			self.text_object = CS.UnityEngine.GameObject("text")
-- 			self.text_object.transform:SetParent(self.UI_object.transform)
-- 			self.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 			self.text_object.transform.localScale = CS.UnityEngine.Vector3.one
		
-- 			-- local rectTransform = self.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
-- 			-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
-- 			-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
-- 			-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

-- 			self.text = self.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
-- 			self.text.font = utils.getFont()
-- 			self.text.fontSize = 12
-- 			self.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

-- 			-- self.text.material = self.database.palettes_ui[1]
-- 		elseif self.kind == 3 then
-- 			self.button_object = CS.UnityEngine.GameObject("button")
-- 			self.button_object.transform:SetParent(self.UI_object.transform)
-- 			self.button_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 			self.button_object.transform.localScale = CS.UnityEngine.Vector3.one
		
-- 			-- local rectTransform = self.button_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
-- 			-- -- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
-- 			-- -- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
-- 			-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

-- 			self.image = self.button_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
-- 			self.image.sprite = nil
-- 			self.image.material = self.database.palettes_ui[1]

-- 			self.button = self.button_object:AddComponent(typeof(CS.UnityEngine.UI.Button))

-- 			utils.setButtonColor(self, 127, 127, 127, 255, 240, 199, 50, 255, 191, 0, 0, 255)

-- 			self.text_object = CS.UnityEngine.GameObject("text")
-- 			self.text_object.transform:SetParent(self.button_object.transform)
-- 			self.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 			self.text_object.transform.localScale = CS.UnityEngine.Vector3.one
		
-- 			-- local rectTransform = self.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
-- 			-- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(0, -15)
-- 			-- rectTransform.sizeDelta = CS.UnityEngine.Vector2(100, 12)
-- 			-- rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
-- 			-- rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

-- 			self.text = self.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
-- 			self.text.font = utils.getFont()
-- 			self.text.fontSize = 12
-- 			self.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

-- 			-- self.text.material = self.database.palettes_ui[1]

-- 			-- utils.addEvent("OnClick", function(this, value)
-- 			-- 	if this.image.rectTransform.anchoredPosition.x <= self.image.rectTransform.anchoredPosition.x then
-- 			-- 		print("wocao")
-- 			-- 	end
-- 			-- end)

-- 			-- self.button.onClick:AddListener(function()
-- 			-- 	print("wocao")
-- 			-- end)
			
-- 		end

-- 		if parent == nil then
-- 			self.UI_object.transform:SetParent(utils.getLCanvas().transform)
-- 		else
-- 			-- self.UI_object.transform:SetParent(p.transform)
-- 			self.UI_object.transform:SetParent(parent.rectTransform)
	
-- 			self.team = parent.team
-- 			if self.image ~= nil then
-- 				self.image.material = parent.image.material
-- 			end
-- 		end

-- 		self.rectTransform = self.UI_object:GetComponent(typeof(CS.UnityEngine.RectTransform))
-- 		-- self.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
-- 		-- self.rectTransform.sizeDelta = CS.UnityEngine.Vector2(0, 0)
-- 		-- self.rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
-- 		-- self.rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
-- 		-- self.rectTransform.pivot = CS.UnityEngine.Vector2(0, 1)
-- 		return self
-- 	end
	
-- 	-- self.gameObject:AddComponent(typeof(CS.GameAnimation)).luaBehaviour = utils.LUABEHAVIOUR


		
-- 	-- 	self.animation:AddClip(_v, _v.name)
-- 	-- end
-- 	-- self.animation.animatePhysics = true

-- 	self.physics_object = CS.UnityEngine.GameObject("physics")
-- 	-- self.physics_object.transform:SetParent(self.gameObject.transform)
-- 	self.physics_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
-- 	self.physics_object.transform.position = CS.UnityEngine.Vector3(x, y, z)
-- 	-- self.physics_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	-- self.physics_object.transform.localScale = CS.UnityEngine.Vector3.one

-- 	-- self.rigidbody = self.gameObject:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
-- 	-- self.rigidbody.bodyType = CS.UnityEngine.RigidbodyType2D.Kinematic
-- 	-- -- self.rigidbody.collisionDetectionMode = CS.UnityEngine.CollisionDetectionMode2D.Continuous
-- 	-- -- self.rigidbody.sleepMode = CS.UnityEngine.RigidbodySleepMode2D.NeverSleep
-- 	-- -- self.rigidbody.interpolation = CS.UnityEngine.RigidbodyInterpolation2D.Interpolate
-- 	-- self.rigidbody.constraints = CS.UnityEngine.RigidbodyConstraints2D.FreezeRotation
-- 	-- self.rigidbody.gravityScale = 0
-- 	-- -- self.rigidbody.useAutoMass = true

-- 	self.rigidbody = self.physics_object:AddComponent(typeof(CS.UnityEngine.Rigidbody))
-- 	-- self.rigidbody.useGravity = false
-- 	self.rigidbody.isKinematic = true
-- 	-- self.rigidbody.detectCollisions = false
-- 	self.rigidbody.freezeRotation = true

-- 	self.rigidbody_id = self.rigidbody:GetInstanceID()
-- 	CS.LuaUtil.AddID2(self.rigidbody_id, self.rigidbody)

-- 	self.vvvX = nil
-- 	self.vvvY = nil
-- 	self.accvvvX = nil
-- 	self.accvvvY = nil
-- 	self.accvvvZ = nil

	
-- 	-- self.isWall = false
-- 	-- self.isCeiling = false
-- 	self.isOnGround = -1
-- 	-- self.isElse = 1
-- 	-- self.elseArray = {}

-- 	self.attckArray = {}
-- 	self.bodyArray = {}
-- 	self.bodyArray_InstanceID = {}

-- 	self.pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
-- 	self.pic_offset_object_id = self.pic_offset_object:GetInstanceID()
-- 	CS.LuaUtil.AddID(self.pic_offset_object_id, self.pic_offset_object)
-- 	-- self.pic_offset_object.transform:SetParent(self.gameObject.transform)
-- 	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)
-- 	self.pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	-- self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3.one
-- 	self.pic_offset_object.transform.localScale = CS.UnityEngine.Vector3(2, 2, 2)

-- 	self.audioSource = self.pic_offset_object:AddComponent(typeof(CS.UnityEngine.AudioSource))
-- 	self.audioSource.playOnAwake = false

-- 	self.pic_object = CS.UnityEngine.GameObject("pic")
-- 	self.pic_object_id = self.pic_object:GetInstanceID()
-- 	CS.LuaUtil.AddID(self.pic_object_id, self.pic_object)
-- 	self.pic_object.transform:SetParent(self.pic_offset_object.transform)
-- 	self.pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	self.pic_object.transform.localScale = CS.UnityEngine.Vector3.one
-- 	self.spriteRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
-- 	self.spriteRenderer.material = self.database.palettes[1]

-- 	-- if self.kind == 3 then -- 非人物体暂定-20层
-- 	-- 	self.spriteRenderer.sortingOrder = 20
-- 	-- end

-- 	self.atk_object = CS.UnityEngine.GameObject("atk")
-- 	self.atk_object.transform:SetParent(self.physics_object.transform)
-- 	self.atk_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	self.atk_object.transform.localScale = CS.UnityEngine.Vector3.one

-- 	self.bdy_object = CS.UnityEngine.GameObject("bdy[16]")
-- 	self.bdy_object.transform:SetParent(self.physics_object.transform)
-- 	self.bdy_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	self.bdy_object.transform.localScale = CS.UnityEngine.Vector3.one
-- 	self.bdy_object.layer = 16 -- bdy的layer暂定16

-- 	-- self.bdy_object_test = CS.UnityEngine.GameObject("bdy[16]_test")
-- 	-- self.bdy_object_test.transform:SetParent(self.gameObject.transform)
-- 	-- self.bdy_object_test.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	-- self.bdy_object_test.transform.localScale = CS.UnityEngine.Vector3.one
-- 	-- self.bdy_object_test.layer = 16 -- bdy的layer暂定16

-- 	-- self.deubg_object = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
-- 	-- self.deubg_object.name = "debug"
-- 	-- self.deubg_object.transform:SetParent(self.bdy_object.transform)
-- 	-- if self.kind ~= 5 then
-- 	-- 	self.deubg_object.transform.localScale = CS.UnityEngine.Vector3.zero
-- 	-- else
-- 	-- 	self.deubg_object.transform.localScale = CS.UnityEngine.Vector3(0.16 / 5, 1, 0.16 / 5)
-- 	-- end
-- 	-- self.deubg_object.transform.localPosition = CS.UnityEngine.Vector3.zero
-- 	-- self.deubg_object:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).material = utils.DEBUG3D

-- 	-- CS.UnityEngine.GameObject.Destroy(self.deubg_object:GetComponent(typeof(CS.UnityEngine.BoxCollider)))

-- 	self.lineRenderer = self.pic_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
-- 	-- self.lineRenderer.enabled = false
-- 	self.lineRenderer.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
-- 	self.lineRenderer.startWidth = 0.01
-- 	self.lineRenderer.endWidth = 0.02
-- 	-- self.lineRenderer.startColor = color
-- 	-- self.lineRenderer.endColor = color
-- 	self.lineRenderer.numCapVertices = 90
-- 	self.lineRenderer.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

-- 	utils.SetParentAndRoot(self, parent)

-- 	self.oriPos2 = self.physics_object.transform.position
-- 	self.oriPos = self.rigidbody.position
-- 	return self
-- end

-- -- 显示信息
-- function LObject:displayInfo()

-- 	if self.kind == 0 and self.root == self then
-- 		local a = utils.CAMERA:WorldToScreenPoint(CS.UnityEngine.Vector3(self.pic_offset_object.transform.position.x, self.pic_offset_object.transform.position.y, 0))

-- 		-- local b = utils.CAMERA:WorldToScreenPoint(CS.UnityEngine.Vector3(0, self.pic_offset_object.transform.position.z, 0))

-- 		utils.drawHPMP(a.x, -a.y + CS.UnityEngine.Screen.height - 75 / 2, self.HP / self.maxHP)
-- 	end
-- end

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
