-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

local json = require "json"
local utils = require 'LUtils'
require "LAI"
local ecs = require "ecs"

castleDB = {DBPath = nil, DBFile = nil, DBData = nil, IMGFile = nil, IMGData = nil, DBSheets = nil}
castleDB.__index = castleDB
function castleDB:new(path, file)
	local self = {}
	setmetatable(self, castleDB)

	self.DBPath = path
	self.DBFile = file
	self.IMGFile = nil
	self.DBData = nil
	self.IMGData = nil
	self.DBSheets = nil

	return self
end

function castleDB:readDB()

	local str = utils.openFileText(self.DBPath .. self.DBFile)

    self.DBData = json.decode(str)

	self.DBSheets = {}
    for i, v in ipairs(self.DBData["sheets"]) do
        if self.DBSheets[v.name] == nil then
            self.DBSheets[v.name] = v
        end
	end
	print(self.DBPath .. self.DBFile .. ": json read!")
end

function castleDB:writeDB()
	local data = json.encode(self.DBData)
	local file = io.open(self.DBPath .. self.DBFile, "w")
	file:write(data)
	file:close()

	print(self.DBPath .. self.DBFile .. ": json wrote!")
end

function castleDB:readIMG()
	local idx = string.match(self.DBFile, ".+()%.%w+$")
	if idx then
		self.IMGFile = string.sub(self.DBFile, 1, idx - 1) .. ".img"
	end

    local str = utils.openFileText(self.DBPath .. self.IMGFile)

    self.IMGData = json.decode(str)

	print(self.DBPath .. self.IMGFile .. ": json read!")
end

function castleDB:writeIMG()
	local data = json.encode(self.IMGData)
	local file = io.open(self.DBPath .. self.IMGFile, "w")
	file:write(data)
	file:close()

	print(self.DBPath .. self.IMGFile .. ": json wrote!")
end

-- 读取images中的pic
function castleDB:loadIMGToTexture2Ds()
	local result = {}
    for i, v in pairs(self.IMGData) do
        if result[i] == nil then
            result[i] = utils.loadImageToTexture2D(v)
        end
	end
	return result
end

function castleDB:getLines(name)
	if self.DBSheets[name] == nil then
		print("cannot find sheet called " .. name .. " in " .. self.DBFile .. "!")
		return nil
	end
	return self.DBSheets[name].lines
end

LCastleDBMap = {texture2Ds = nil, texture256 = nil, sprites = nil, audioClips = nil, palettes = nil}
setmetatable(LCastleDBMap, castleDB)
LCastleDBMap.__index = LCastleDBMap
function LCastleDBMap:new(path, file)
	local self = {}
	self = castleDB:new(path, file)
	setmetatable(self, LCastleDBMap)

	self.texture2D = nil
	self.texture256 = nil
	self.sprites = nil
	self.audioClips = nil
	self.palettes = nil
	return self
end

function LCastleDBMap:readDB()

	local str = utils.openFileText(self.DBPath .. self.DBFile)

    self.DBData = json.decode(str)

	self.DBSheets = {}
    for i, v in ipairs(self.DBData["sheets"]) do
        if self.DBSheets[v.name] == nil then
            self.DBSheets[v.name] = v
        end
	end
	print(self.DBPath .. self.DBFile .. ": json read!")

	self.audioClips = self:createAudioClips()
	self.texture2Ds, self.texture256, self.sprites = self:createSprites()
	self.palettes = self:createPalettes()
end

function LCastleDBMap:createAudioClips()
	local audioClips = {}
    for i, v in ipairs(self:getLines("sounds")) do
		local data = utils.openFileBytes(self.DBPath .. v.file)

		local bytes = {}

		for j = 1, #data, 1 do
			bytes[j] = tonumber(string.byte(data, j, j))
		end

		local audioClip = {}

		local pos = 1
		while not (bytes[pos] == 102 and bytes[pos + 1] == 109 and bytes[pos + 2] == 116) do -- ??fmt??
			pos = pos + 1
		end

		audioClip.ChannelCount = bytes[pos + 10] -- ????????1?????2
		audioClip.Frequency = utils.bytesToInt(bytes, pos + 12) -- ????

		local size = bytes[pos + 20] -- DATA????????
		local bit = bytes[pos + 22] -- PCM??

		while not (bytes[pos] == 100 and bytes[pos + 1] == 97 and bytes[pos + 2] == 116 and bytes[pos + 3] == 97) do -- ??data??
			pos = pos + 4
			local chunkSize = bytes[pos] + bytes[pos + 1] * 256 + bytes[pos + 2] * 65536 + bytes[pos + 3] * 16777216
			pos = pos + 4 + chunkSize
		end
		pos = pos + 8 -- ?????data???

		audioClip.SampleCount = utils.bytesToInt(bytes, pos - 4) / size -- ?data??4?byte?????????????????????????=????

		if audioClip.ChannelCount == 2 then -- ?????????
			audioClip.SampleCount = audioClip.SampleCount / 2
		end

		audioClip.LeftChannel = {}
		if audioClip.ChannelCount == 2 then
			audioClip.RightChannel = {}
		else
			audioClip.RightChannel = nil
		end

		local i = 1

		if bit == 16 then -- ???16???
			while i <= audioClip.SampleCount do
				audioClip.LeftChannel[i] = utils.bytesToFloat(bytes[pos], bytes[pos + 1])
				pos = pos + 2
				if audioClip.RightChannel ~= nil then
					audioClip.RightChannel[i] = utils.bytesToFloat(bytes[pos], bytes[pos + 1])
					pos = pos + 2
				end
				i = i + 1
			end
		else  -- ???8??? -- ??????
			while i <= audioClip.SampleCount do
				audioClip.LeftChannel[i] = 1 - (bytes[pos] / 128)
				pos = pos + 1
				if audioClip.RightChannel ~= nil then
					audioClip.RightChannel[i] = 1 - (bytes[pos] / 128)
					pos = pos + 1
				end
				i = i + 1
			end
		end

		local ac = CS.UnityEngine.AudioClip.Create(v.id, audioClip.SampleCount, audioClip.ChannelCount, audioClip.Frequency, false)
		ac:SetData(audioClip.LeftChannel, 0)

		if audioClips[v.id] == nil then
			audioClips[v.id] = ac
		end

		-- local test = CS.UnityEngine.GameObject(v.id)
		-- audioSource = test:AddComponent(typeof(CS.UnityEngine.AudioSource))
		-- audioSource.clip = audioClips[v.id]

		-- 	testtest[v.id] = audioSource
	end
	return audioClips
end


-- ????????????????sprite
function LCastleDBMap:createSprites()
	--~     for i, v in pairs(texture2D) do
	--~         if pics[i] == nil then
	--~             pics[i] = CS.UnityEngine.Sprite.Create(v, CS.UnityEngine.Rect(0, 0, v.width, v.height), CS.UnityEngine.Vector2(0, 1))
	--~         end
	--~ 	end
		local p = utils.split(self.DBFile, ".")
	
		local data = utils.openFileBytes(self.DBPath .. p[1] .. ".png")

		if data ~= nil then
		
			-- ???????????gamma?????linear????
			local texture2D = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
			-- local texture2D = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.Experimental.Rendering.DefaultFormat.HDR, CS.UnityEngine.Experimental.Rendering.TextureCreationFlags.None)
			-- local texture2D = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.Experimental.Rendering.GraphicsFormat.R8_UNorm, CS.UnityEngine.Experimental.Rendering.TextureCreationFlags.None)

			texture2D.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
			texture2D.filterMode = CS.UnityEngine.FilterMode.Point
			texture2D.name = p[1]
		
			-- texture2D:LoadImage(data)
			CS.UnityEngine.ImageConversion.LoadImage(texture2D, data)
		
			local str = utils.openFileText(self.DBPath .. p[1] .. ".json")
		
			local spriteData = json.decode(str)

			print(p[1] .. ".png", texture2D.format)
		
			local pics = {}
			for i, v in ipairs(spriteData) do
				if pics[v.id] == nil then
					pics[v.id] = CS.UnityEngine.Sprite.Create(texture2D, CS.UnityEngine.Rect(v.x, v.y, v.w, v.h), CS.UnityEngine.Vector2(0, 1))
				end
			end

			local texture256 = CS.UnityEngine.Texture2D(16, 16, CS.UnityEngine.TextureFormat.RGBA32, false, false)
			texture256.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
			texture256.filterMode = CS.UnityEngine.FilterMode.Point
			for i = 0, texture256.width - 1, 1 do
				for j = 0, texture256.height - 1, 1 do
					local color = j * 16 + i
					texture256:SetPixel(i, j, CS.UnityEngine.Color(color / 255, 0, 0))
					pics[tostring(color)] = CS.UnityEngine.Sprite.Create(texture256, CS.UnityEngine.Rect(i, j, 1, 1), CS.UnityEngine.Vector2(0, 1))
				end
			end
			texture256:Apply()
		
			return texture2D, texture256, pics
		else
			return nil, nil, {}
		end
	end

	
-- ?????
function LCastleDBMap:createPalettes()
	local palettes = {}
	local palettes_ui = {}
	for i, v in ipairs(self:getLines("palettes")) do

		if v.active then
			local texture = CS.UnityEngine.Texture2D(256, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
			-- local texture = CS.UnityEngine.Texture2D(256, 1, CS.UnityEngine.Experimental.Rendering.DefaultFormat.LDR, CS.UnityEngine.Experimental.Rendering.TextureCreationFlags.None)
			-- local texture = CS.UnityEngine.Texture2D(256, 1, CS.UnityEngine.Experimental.Rendering.GraphicsFormat.R8G8B8A8_UNorm, CS.UnityEngine.Experimental.Rendering.TextureCreationFlags.None)


			texture.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
			texture.filterMode = CS.UnityEngine.FilterMode.Point

			local count = 0
			-- local file = io.open(self.DBPath .. v.file, "r")
			-- for line in file:lines() do
			-- 	local r, g, b = string.match(line, "(%d+) (%d+) (%d+)")
			-- 		print(r, g, b)
			-- 	if r ~= nil and g ~= nil and b ~=nil then
			-- 		if count == 0 then
			-- 			texture:SetPixel(count, 0, CS.UnityEngine.Color(r / 255, g / 255, b / 255, 0))
			-- 		else
			-- 			texture:SetPixel(count, 0, CS.UnityEngine.Color(r / 255, g / 255, b / 255, 1))
			-- 		end
			-- 		count = count + 1
			-- 	end
			-- end
			-- io.close(file)


			local str = utils.openFileText(self.DBPath .. v.file)

			local p = utils.split(str, "\n")
			for i2, v2 in ipairs(p) do
				local r, g, b = string.match(v2, "(%d+) (%d+) (%d+)")
				if r ~= nil and g ~= nil and b ~= nil then
					if count == 0 or count == 255 then
						texture:SetPixel(count, 0, CS.UnityEngine.Color(r / 255, g / 255, b / 255, 0))
					else
						texture:SetPixel(count, 0, CS.UnityEngine.Color(r / 255, g / 255, b / 255, 1))
					end
					count = count + 1
				end
			end

			texture:Apply()

			-- local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(0, 0, texture.width, texture.height), CS.UnityEngine.Vector2(0, 1))

			local material = CS.UnityEngine.Material(utils.getShader())

			-- local unityobject_child = CS.UnityEngine.GameObject("testtt")
			-- local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
			-- sr.sprite = sprite
			-- local m = unityobject_child:GetComponent(typeof(CS.UnityEngine.Renderer)).material
			-- m.shader = shader
			-- m:SetTexture("_Palette", texture)
			material:SetTexture("_Palette", texture)

			table.insert(palettes, material)

			local material_ui = CS.UnityEngine.Material(utils.getUIShader())
			material_ui:SetTexture("_Palette", texture)
			table.insert(palettes_ui, material_ui)
		end
	end
	return palettes, palettes_ui
end


--------------------------------------------------------------------------------------------------

Delegate = function()
    local data = {}
    local add = function(action) --????
		data[tostring(action)] = action
    end
    local delete = function(action)  --????
        data[tostring(action)] = nil
    end
	local invoke = function(...) --????
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

LCastleDBCharacter = {
						palettes_ui = nil,
						characters = nil,
						AI = nil,
						animations = nil,
						characters_state = nil,
						vars = nil,
						animationClips = nil,
						prototypes = nil,
						-- eventManager = nil
						groups = nil,
						spines = nil
					}
setmetatable(LCastleDBCharacter, LCastleDBMap)
LCastleDBCharacter.__index = LCastleDBCharacter
function LCastleDBCharacter:new(path, file)
	local self = {}
	self = LCastleDBMap:new(path, file)
	setmetatable(self, LCastleDBCharacter)

	self.palettes_ui = nil
	self.characters = nil
	self.AI = nil

	self.animations = nil
	self.characters_state = nil
	self.vars = nil
	self.animationClips = nil
	self.prototypes = nil

	-- self.eventManager = {}

	self.groups = nil
	self.spines = nil
	return self
end

Rubbish = {}
Rubbish.CS = CS
Rubbish.print = print
Rubbish.utils = utils

Rubbish.getPosZ = function(id)
	local x, y, z = CS.LuaUtil.GetPos(id)
	return z
end

Rubbish.getPosX = function(id)
	local x, y, z = CS.LuaUtil.GetPos(id)
	return x
end

function LCastleDBCharacter:readDB()
	local str = utils.openFileText(self.DBPath .. self.DBFile)

    self.DBData = json.decode(str)

	self.DBSheets = {}
    for i, v in ipairs(self.DBData["sheets"]) do
        if self.DBSheets[v.name] == nil then
            self.DBSheets[v.name] = v
        end
	end
	print(self.DBPath .. self.DBFile .. ": json read!")


	-- self.characters = {}
	-- for i, v in ipairs(self:getLines("actions")) do
	-- 	self.characters[v.name] = v.frames
	-- end

	if self.DBSheets["animations"] ~= nil then
		self.animations = {}

		self.animationClips = {}
		for i, v in ipairs(self:getLines("animations")) do
			self.animations[v.name] = {}
			self.animations[v.name].eventQueue = {}
			
			self.animations[v.name].keyframes = {}

			local delayC = 0
			for j = 0, #v.clips - 1, 1 do
				local currentFrame = v.clips[j + 1]
				if currentFrame.category == "Sprite" or currentFrame.category == "Wait" or currentFrame.category == "Trace" or currentFrame.category == "Image" or currentFrame.category == "Text" or currentFrame.category == "Button" then
					if self.animations[v.name].eventQueue[delayC] == nil then
						self.animations[v.name].eventQueue[delayC] = {}
					end

					-- print(v.name, delayC)

					table.insert(self.animations[v.name].eventQueue[delayC], 1, currentFrame)

					table.insert(self.animations[v.name].keyframes, delayC)

					delayC = delayC + currentFrame.wait
				elseif currentFrame.category == "Sound" or currentFrame.category == "Body" or currentFrame.category == "Attack" or currentFrame.category == "Child" then
					if self.animations[v.name].eventQueue[delayC] == nil then
						self.animations[v.name].eventQueue[delayC] = {}
					end
					table.insert(self.animations[v.name].eventQueue[delayC], 1, currentFrame)
				-- elseif currentFrame.category == "Trigger" or currentFrame.category == "Body" or currentFrame.category == "Attack" then -- currentFrame.category == "Act" or currentFrame.category == "Object" or 
				-- 	for j = 0, currentFrame.wait - 1, 1 do
				-- 		if self.animations[v.name].eventQueue[delayC + j] == nil then
				-- 			self.animations[v.name].eventQueue[delayC + j] = {}
				-- 		end
				-- 		table.insert(self.animations[v.name].eventQueue[delayC + j], 1, currentFrame)
				-- 	end
				end
			end

			self.animations[v.name].delay = delayC
			table.insert(self.animations[v.name].keyframes, delayC)

			-- self.animationClips[v.name] = {}

			-- local clip = CS.UnityEngine.AnimationClip()
			-- clip.legacy = true
			-- clip.wrapMode = CS.UnityEngine.WrapMode.Loop
			-- clip.name = v.name

			-- local curve = CS.UnityEngine.AnimationCurve()
			-- for j = 0, self.animations[v.name].delay - 1, 1 do

			-- 	local ae = CS.UnityEngine.AnimationEvent()
			-- 	-- ae.objectReferenceParameter = ooo
			-- 	ae.functionName = "RunAnimationEvent"
			-- 	ae.intParameter = j
			-- 	ae.stringParameter = v.name
			-- 	ae.time = j * (1 / 60)
			-- 	-- ae.messageOptions = CS.UnityEngine.SendMessageOptions.DontRequireReceiver
			-- 	clip:AddEvent(ae)

			-- 	-- local kf = CS.UnityEngine.Keyframe(j * (1 / 60), 0)
			-- 	-- curve:AddKey(kf)
			-- end
			-- -- clip:SetCurve("", typeof(CS.UnityEngine.Transform), "localPosition.x", curve)
			-- -- clip:SetCurve("", typeof(CS.GameAnimation), "enabled", curve)

			-- self.animationClips[v.name] = clip
		end

	end

	self.prototypes = {}
	for i, v in ipairs(self:getLines("prototypes")) do
		if v.active then
			self.prototypes[v.name] = v.prototype
		end
	end

	self.groups = {}
	for _, v in ipairs(self:getLines("groups")) do
		if v.active then
			local vvv = {}
			local str = "function _new(%s) "
			str = str .. "local eid = ecs.newEntity() "
			for _, v2 in ipairs(v.group) do

				local vs = {}
				local j = 2
				while true do
					local cnew = ecs.getComponent(v2.component).new
					if cnew == nil then
						break
					end
					local vn = debug.getlocal(cnew, j)
					if vn == nil then
						break
					end
					j = j + 1
					table.insert(vs, vn)
				end
				local vv
				if #vs > 0 then
					if v2.value == nil then
						vv = table.concat(vs, ", ")
						table.insert(vvv, vv)
						vv = ", " .. vv
					else
						vv = ""
						for i in ipairs(vs) do
							if type(v2.value[i]) == "string" then
								vv = vv .. ", '" .. v2.value[i] .. "'"
							else
								vv = vv .. ", " .. v2.value[i]
							end
						end
					end
				else
					vv = ""
				end

				str = str .. "ecs.addComponent(eid, '" .. v2.component .."'" .. vv .. ") "
			end
			str = str .. "return ecs.applyEntity(eid) end return _new"
			local r = string.format(str, table.concat(vvv, ", "))
			-- print(r)
			self.groups[v.name] = assert(load(r, "_new", "t", {ecs = require "ecs"}))()
		end
	end

	self.vars = {}
	for i, v in ipairs(self:getLines("vars")) do
		if v.active then
			self.vars[v.name] = v.default
		end
	end

	self.characters_state = {}
	for i, v in ipairs(self:getLines("states")) do
		self.characters_state[v.name] = {}
		-- self.characters_state[v.name].state = v.state
		self.characters_state[v.name].animation = v.animation


		-- for j, v2 in ipairs(v.state) do
		-- 	if v2.trigger ~= nil then

		-- 		-- if self.characters_state[v.name][v2.trigger] == nil then
		-- 			-- v2.func = load("return " .. v2.trigger, "trigger", "t") -- , self
		-- 			v2.func = assert(load("function _trigger(this) return " .. v2.trigger .. " end return _trigger", "trigger", "t", Rubbish))()
		-- 		-- 	self.characters_state[v.name][v2.trigger] = v2.func
		-- 		-- else
		-- 		-- 	v2.func = self.characters_state[v.name][v2.trigger]
		-- 		-- end
		-- 	else
		-- 		v2.func = nil
		-- 	end
		-- end
		local update = {}
		self:setState(v.update, update)
		local fixedUpdate = {}
		self:setState(v.fixedUpdate, fixedUpdate)


		self.characters_state[v.name].update = update
		self.characters_state[v.name].fixedUpdate = fixedUpdate

		-- local p = utils.split(v.name, "_")

		-- if self.FBcontorller[p[1]] == nil then
		-- 	self.FBcontorller[p[1]] = {}
		-- end

		-- if p[2] == "front" and self.FBcontorller[p[1]].front == nil then
		-- 	self.FBcontorller[p[1]].front = v.name

		-- 	print("front", v.name)
		-- elseif  p[2] == "back" and self.FBcontorller[p[1]].back == nil  then
		-- 	self.FBcontorller[p[1]].back = v.name

		-- 	print("back", v.name)
		-- end
	end

	self.AI = LAI:new(self)

	self.audioClips = self:createAudioClips()
	self.texture2Ds, self.texture256, self.sprites = self:createSprites()
	self.palettes, self.palettes_ui = self:createPalettes()

	-- local p = utils.split(self.DBFile, ".")
	
	-- local data = utils.openFileBytes(self.DBPath .. p[1] .. ".png")

	local texs = {}
	table.insert(texs, self.texture2Ds)
	self.spines = {}
	for i, v in ipairs(self:getLines("spines")) do
		-- spine3.6是AtlasAsset，3.8不是
		local runtimeAtlasAsset = CS.Spine.Unity.AtlasAsset.CreateRuntimeInstance(CS.UnityEngine.TextAsset(utils.openFileText(self.DBPath .. v.atlas)), texs, self.palettes[1], true)

		self.spines[v.name] = CS.Spine.Unity.SkeletonDataAsset.CreateRuntimeInstance(CS.UnityEngine.TextAsset(utils.openFileText(self.DBPath .. v.skeleton)), runtimeAtlasAsset, true)
		self.spines[v.name]:GetSkeletonData(false)
		self.spines[v.name]:GetAnimationStateData().DefaultMix = 0.1
	end

	----------------------------------------------------------------------------------------------------------------------

	-- self:addEvent("Live", function(this, value)
	-- 	-- self["HP"] = utils.toMaxvalue(self["HP"], self["maxHP"], self["HPRecoveryRate"])
	-- 	-- self["MP"] = utils.toMaxvalue(self["MP"], self["maxMP"], self["MPRecoveryRate"] + (self["MPRecoveryRate"] * (1 - self["HP"] / self["maxHP"])))
	-- 	-- self["falling"] = utils.toOne(self["falling"], self["maxFalling"], self["fallingRecoveryRate"])
	-- 	-- self["defencing"] = utils.toOne(self["defencing"], self["maxDefencing"], self["defencingRecoveryRate"])

	-- 	-- if self.target == nil then
	-- 	-- 	local temp = {}
	-- 	-- 	for i, v in pairs(utils.getObjects()) do
	-- 	-- 		if v ~= nil and v.kind == 0 and v ~= self and v["HP"] > 0 then
	-- 	-- 			table.insert(temp, v)
	-- 	-- 		end
	-- 	-- 	end
	-- 	-- 	self.target = temp[CS.Tools.Instance:RandomRangeInt(1, #temp + 1)]
	-- 	-- else
	-- 	-- 	if self.target["HP"] <= 0 then
	-- 	-- 		self.target = nil
	-- 	-- 	end
	-- 	-- end
	-- end)
	-- self:addEvent("Dead", function(this, value)
	-- 	utils.destroyObject(this.physics_object:GetInstanceID())
	-- end)

	-- self:addEvent("Flying", function(this, value)
	-- 	if this.kind ~= 3 and this.kind ~= 5 then
	-- 		this.velocity = this.velocity + 0.5 * CS.UnityEngine.Physics.gravity * 2 / 60
	-- 		-- this.velocity.y = this.velocity.y + 0.5 * -9.81 * 2 / 60 / 3
	-- 	end
	-- end)

	-- self:addEvent("Ground", function(this, value)
	-- 	-- if this.isOnGround ~= 1 then
	-- 		local f = this.velocity * 0.2 -- ????
	-- 		if this.velocity.x > 0 then
	-- 			this.velocity.x = this.velocity.x - f.x
	-- 			if this.velocity.x < 0 then
	-- 				this.velocity.x = 0
	-- 			end
	-- 		elseif this.velocity.x < 0 then
	-- 			this.velocity.x = this.velocity.x - f.x
	-- 			if this.velocity.x > 0 then
	-- 				this.velocity.x = 0
	-- 			end
	-- 		end

	-- 		if this.velocity.z > 0 then
	-- 			this.velocity.z = this.velocity.z - f.z
	-- 			if this.velocity.z < 0 then
	-- 				this.velocity.z = 0
	-- 			end
	-- 		elseif this.velocity.z < 0 then
	-- 			this.velocity.z = this.velocity.z - f.z
	-- 			if this.velocity.z > 0 then
	-- 				this.velocity.z = 0
	-- 			end
	-- 		end
	-- 	-- end
	-- 	if this.kind == 99 then
	-- 		if this.rotation > 0 then
	-- 			this.rotation_velocity = this.rotation_velocity / 2
	-- 		else
	-- 			this.rotation_velocity = this.rotation_velocity / 2
	-- 		end
	-- 		if this.velocity.magnitude <= 0.5 then
	-- 			this.sleep = true
	-- 		end
	-- 	end
	-- end)

	-- self:addEvent("Sprite", function(this, value)
	-- 	-- print(value)
	-- 	this.spriteRenderer.sprite = this.database.sprites[value.sprite]
	-- 	this.pic_object.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, -value.y / 100, 0)
	-- end)

	-- self:addEvent("Image", function(this, value)
	-- 	if value.id == nil then
	-- 		this.image.sprite = this.database.sprites[value.sprite]
	-- 	else
	-- 		this.image.sprite = this.database.sprites[value.id]
	-- 	end

	-- 	local position = CS.UnityEngine.Vector2(0, 0)
	-- 	local size = CS.UnityEngine.Vector2(0, 0)
	-- 	local min = CS.UnityEngine.Vector2(0, 0)
	-- 	local max = CS.UnityEngine.Vector2(0, 0)
	-- 	local pivot = CS.UnityEngine.Vector2(0, 0)
	-- 	if value.horizontalAlignment == 0 then -- Left
	-- 		min.x = 0
	-- 		max.x = 0
	-- 		pivot.x = 0

	-- 		position.x = value.margin.left
	-- 		size.x = value.width
	-- 	elseif value.horizontalAlignment == 1 then -- Center
	-- 		min.x = 0.5
	-- 		max.x = 0.5
	-- 		pivot.x = 0.5

	-- 		position.x = value.x
	-- 		size.x = value.width
	-- 	elseif value.horizontalAlignment == 2 then -- Right
	-- 		min.x = 1
	-- 		max.x = 1
	-- 		pivot.x = 1

	-- 		position.x = -value.margin.right
	-- 		size.x = value.width
	-- 	elseif value.horizontalAlignment == 3 then -- Stretch
	-- 		min.x = 0
	-- 		max.x = 1
	-- 		pivot.x = 0.5

	-- 		position.x = value.margin.left
	-- 		size.x = position.x + value.margin.right
	-- 	end

	-- 	if value.verticalAlignment == 0 then -- Top
	-- 		min.y = 1
	-- 		max.y = 1
	-- 		pivot.y = 1

	-- 		position.y = -value.margin.top
	-- 		size.y = value.height
	-- 	elseif value.verticalAlignment == 1 then -- Center
	-- 		min.y = 0.5
	-- 		max.y = 0.5
	-- 		pivot.y = 0.5

	-- 		position.y = -value.y
	-- 		size.y = value.height
	-- 	elseif value.verticalAlignment == 2 then -- Bottom
	-- 		min.y = 0
	-- 		max.y = 0
	-- 		pivot.y = 0

	-- 		position.y = value.margin.bottom
	-- 		size.y = value.height
	-- 	elseif value.verticalAlignment == 3 then -- Stretch
	-- 		min.y = 0
	-- 		max.y = 1
	-- 		pivot.y = 0.5

	-- 		position.y = value.margin.bottom
	-- 		size.y = position.y + value.margin.top
	-- 	end

	-- 	this.rectTransform.anchorMin = min
	-- 	this.rectTransform.anchorMax = max

	-- 	this.rectTransform.pivot = pivot

	-- 	this.rectTransform.sizeDelta = size
	-- 	this.rectTransform.anchoredPosition = position

	-- 	-- this.rectTransform.offsetMin = position
	-- 	-- this.rectTransform.offsetMax = size

	-- end)

	-- self:addEvent("Text", function(this, value)
	-- 	this.text.text = value.text
	-- 	this.text.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
	-- 	this.text.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)
	-- end)

	-- self:addEvent("Button", function(this, value)
	-- 	this.image.sprite = this.database.sprites[value.sprite]
	-- 	this.image.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
	-- 	this.image.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)

	-- 	this.text.text = value.text
	-- 	-- this.text.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(value.x, -value.y)
	-- 	-- this.text.rectTransform.sizeDelta = CS.UnityEngine.Vector2(value.width, value.height)
	-- end)

	-- self:addEvent("Trace", function(this, value)
	-- 	local s = this.oriPos2
	-- 	local e = this.physics_object.transform.position
	-- 	this.lineRenderer:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
	-- 	this.lineRenderer:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))

	-- 	this.oriPos2 = this.physics_object.transform.position
	-- end)

	-- self:addEvent("Sound", function(this, value)
	-- 	this.audioSource.clip = this.database.audioClips[value.sfx]
	-- 	-- local r = math.random() / 2.5
	-- 	-- this.audioSource.pitch = 1 + r - 0.2
	-- 	this.audioSource:Play()
	-- end)

	-- -- self:addEvent("Object", function(this, value)
	-- -- 	if value.isWorldPosition then
	-- -- 		utils.createObject(nil, this.id, value.action,value.frame, value.x, value.y, 0, 0, value.kind)
	-- -- 	else
	-- -- 		utils.createObject(nil, this.id, value.action, value.frame, this.rigidbody.position.x + value.x, this.rigidbody.position.y + value.y, 0, 0, value.kind)
	-- -- 	end
	-- -- end)

	-- self:addEvent("Body", function(this, value)
	-- 	if this.bodyArray[value.id] == nil and not (value.width == 0 or value.height == 0) then
	-- 		this.bodyArray[value.id] = LColliderBDY:new(this, this.bdy_object, value.id)
	-- 		this.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.bodyFlags, value.layers)
	-- 		-- this.bodyArray_InstanceID[this.bodyArray[value.id].collider2:GetInstanceID()] = this.bodyArray[value.id]
	-- 		this.bodyArray_InstanceID[this.bodyArray[value.id].collider:GetInstanceID()] = this.bodyArray[value.id]

	-- 		-- this.deubg_object.transform.localScale = CS.UnityEngine.Vector3(value.width / 100, value.height / 100, value.width / 100)
	-- 		-- this.deubg_object.transform.localPosition = CS.UnityEngine.Vector3((value.x + value.width / 2) / 100, -(value.y + value.height / 2) / 100, 0)
	-- 	else
	-- 		if this.bodyArray[value.id] ~= nil then
	-- 			if value.width == 0 or value.height == 0 then
	-- 				local IID = this.bodyArray[value.id].collider:GetInstanceID()
	-- 				this.bodyArray[value.id]:deleteCollider()
	-- 				this.bodyArray[value.id] = nil
	-- 				this.bodyArray_InstanceID[IID] = nil
	-- 			else
	-- 				-- this.bodyArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.bodyFlags, value.layers)
	-- 			end
	-- 		end
	-- 	end
	-- end)

	-- self:addEvent("Attack", function(this, value)
	-- 	if this.attckArray[value.id] == nil and not (value.width == 0 or value.height == 0) then
	-- 		this.attckArray[value.id] = LColliderATK:new(this, this.atk_object, value.id)
	-- 		this.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.attackFlags,
	-- 													value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, false, value.var,
	-- 													value.action, value.frame)
	-- 	else
	-- 		if this.attckArray[value.id] ~= nil then
	-- 			if value.width == 0 or value.height == 0 then
	-- 				this.attckArray[value.id]:deleteCollider()
	-- 				this.attckArray[value.id] = nil
	-- 			else
	-- 				-- this.attckArray[value.id]:setCollider(value.direction, value.x, value.y, value.width, value.height, value.depth, value.attackFlags,
	-- 				-- 										value.damage, value.fall, value.defence, value.frequency, value.directionX, value.directionY, value.ignoreFlag, value.var,
	-- 				-- 										value.action, value.frame)
	-- 			end
	-- 		end
	-- 	end
	-- end)

	-- self:addEvent("Force", function(this, value)
	-- 	-- this.velocity.x = this.velocity.x + value.x
	-- 	-- this.velocity.y = this.velocity.y + value.y
	-- 	-- this.velocity.z = this.velocity.z + value.z
	-- 	local object = this.attckArray["0"].hitObject

	-- 	local spd = this.attckArray["0"].direction * 40 / 100

	-- 	object.velocity.x = object.velocity.x + spd.x
	-- 	object.velocity.y = object.velocity.y + spd.y
	-- 	object.velocity.z = object.velocity.z + spd.z
	-- end)

	-- self:addEvent("Hurt", function(this, value)
	-- 	this.HP = this.HP - value.damage
	-- end)

	-- -- self:addEvent("TurnRight", function(this, value)
	-- -- 	if this.direction.x == -1 and this.target ~= nil and this.physics_object.transform.position.x - this.target.physics_object.transform.position.x < 0 then
	-- -- 		this.direction.x = 1
	-- -- 	end
	-- -- 	if this.direction.x == 1 and this.target ~= nil and this.physics_object.transform.position.x - this.target.physics_object.transform.position.x >= 0 then
	-- -- 		this.direction.x = -1
	-- -- 	end
	-- -- end)

	-- self:addEvent("Mouse", function(this, value)
	-- 	local mousePos = CS.UnityEngine.Input.mousePosition
	-- 	-- mousePos.z = v3.z
	-- 	local worldPos = utils.CAMERA:ScreenToWorldPoint(mousePos)
	-- 	this.physics_object.transform.position = CS.UnityEngine.Vector3(worldPos.x, 0, worldPos.y - utils.PLAYER.object.physics_object.transform.position.y)
	-- end)
	-- -- this:frameLoop() -- ????

	-- -- this.animation:Play(this.action)
	-- -- this.functions = CS.Tools.Instance:GetAnimationState(this.animation, this.action)

	-- self:addEvent("State", function(this, value)
	-- 	utils.changeState(this, value.state)
	-- end)

	-- self:addEvent("Animation", function(this, value)
	-- 	utils.changeAnimation(this, value.animation)
	-- end)

	-- self:addEvent("Child", function(this, value)
	-- 	local object = this.children[value.id]
	-- 	if object ~= nil then
	-- 		if value.rotation ~= nil then
	-- 			object.rotation = value.rotation
	-- 		end

	-- 		if value.direction_x ~= nil then
	-- 			object.direction.x = value.direction_x
	-- 		end

	-- 		-- local z = value.layer / 100
	-- 		-- if this.root.direction.x == -1 then
	-- 		-- 	z = -z
	-- 		-- end
	-- 		-- object.gameObject.transform.localPosition = CS.UnityEngine.Vector3(value.x / 100, value.y / 100, z)

	-- 		object.physics_object.transform.localPosition = CS.UnityEngine.Vector3(this.direction.x * value.x / 100, value.y / 100, 0)

	-- 		object.spriteRenderer.sortingOrder = -(value.layer * this.root.direction.z - this.spriteRenderer.sortingOrder)
	-- 	end
	-- end)

	-- self:addEvent("MoveAC", function(this, value)
	-- 	this.accvvvY = value.id
	-- end)

	-- self:addEvent("Move", function(this, value)
	-- 	if value.x ~= nil then
	-- 		this.velocity.x = value.x
	-- 	end
	-- 	if value.y ~= nil then
	-- 		this.velocity.y = value.y
	-- 	end
	-- 	if value.z ~= nil then
	-- 		this.velocity.z = value.z
	-- 	end
	-- 	-- this.rigidbody.position = this.rigidbody.position + CS.UnityEngine.Vector2(v.x, v.y) * CS.UnityEngine.Time.deltaTime
	-- 	-- this.gameObject.transform.position = this.gameObject.transform.position + CS.UnityEngine.Vector3(v.x, v.y, 0) * CS.UnityEngine.Time.deltaTime
	-- end)

	-- self:addEvent("Set", function(this, value)
	-- 	value.func(this)
	-- end)

	-- self:addEvent("TurnToTarget", function(this, value)
	-- 	if this.root.target ~= nil then
	-- 		local pos = this.root.target.physics_object.transform.position
	-- 		if this.root.target.state == "cursor" then
	-- 			local object = this.children[value.id]
	-- 			if object ~= nil then
	-- 				pos.z = pos.z - this.physics_object.transform.localPosition.y * 2 + value.y / 100 * 2
	-- 			end
	-- 		end
	-- 		local rad = CS.UnityEngine.Mathf.Atan2(this.physics_object.transform.position.z - pos.z, this.physics_object.transform.position.x - pos.x)

	-- 		local deg = rad * CS.UnityEngine.Mathf.Rad2Deg + 180

	-- 		local root = this.root
	-- 		if root ~= nil then

	-- 			-- if root.direction.x == -1 then
	-- 			-- 	deg = -(360 - rad * CS.UnityEngine.Mathf.Rad2Deg)
	-- 			-- end
	-- 			this.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, -deg, 0)
	-- 		end
	-- 	end
	-- end)

	-- self:addEvent("Ray", function(this, value)
	-- 	local hitinfo = nil
	-- 	local s = nil
	-- 	local e = nil

	-- 	local first = nil
	-- 	if this.physics_object.transform.childCount > 1 + 1 then
	-- 		first = this.physics_object.transform:GetChild(2)
	-- 	else
	-- 		first = CS.UnityEngine.GameObject("debug_1")
	-- 		first.transform.parent = this.physics_object.transform
	-- 	end
	-- 	if first ~= nil then
	-- 		local flag, lr = first:TryGetComponent(typeof(CS.UnityEngine.LineRenderer))

	-- 		if not flag then
	-- 			lr = first:AddComponent(typeof(CS.UnityEngine.LineRenderer))

	-- 			lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	-- 			lr.startWidth = 0.02
	-- 			lr.endWidth = 0.02

	-- 			-- local color = CS.UnityEngine.Color.green
	-- 			local color = CS.UnityEngine.Color.red

	-- 			lr.startColor = color
	-- 			color.a = 0
	-- 			lr.endColor = color
	-- 			lr.numCapVertices = 90
	-- 			lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

	-- 			-- lr.useWorldSpace = false
	-- 		end

	-- 		if lr ~= nil then
	-- 			local r = this.physics_object.transform.rotation
	-- 			-- local r = CS.UnityEngine.Quaternion.Euler(r2.x, r2.z, r2.y)
	-- 			-- pos = r * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

	-- 			-- pos = CS.UnityEngine.Quaternion.Euler() * CS.UnityEngine.Vector3(v.x / 100 * 2, -v.y / 100 * 2, 0)

	-- 			-- hitinfo = CS.Tools.Instance:PhysicsRaycastAll(pos + this.rigidbody.position, this.gameObject.transform.right, 25, 15)

	-- 			-- local gen = pos + this.physics_object.transform.position
	-- 			local gen = this.physics_object.transform:TransformPoint(CS.UnityEngine.Vector3(v.x / 100, -v.y / 100, 0))

	-- 			hitinfo = CS.Tools.Instance:PhysicsRaycast(gen, this.physics_object.transform.right, 25, 1048575)
	-- 			-- local t_pos = this.root.target.gameObject.transform.position
	-- 			-- local offset = t_pos - (pos + this.rigidbody.position)
	-- 			-- hitinfo = CS.Tools.Instance:PhysicsRaycast(pos + this.rigidbody.position, offset.normalized, offset.magnitude, 15)

	-- 			if hitinfo.collider ~= nil then
	-- 				s = gen
	-- 				e = hitinfo.point
	-- 				-- lr:SetPosition(0, s)
	-- 				-- lr:SetPosition(1, e)
	-- 				lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
	-- 				lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
	-- 			else
	-- 				s = gen
	-- 				e = gen + this.physics_object.transform.right * 25
	-- 				-- lr:SetPosition(0, s)
	-- 				-- lr:SetPosition(1, e)
	-- 				lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
	-- 				lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
	-- 			end
	-- 		end
	-- 	end

	-- 	-- local second = nil
	-- 	-- if this.physics_object.transform.childCount > 2 + 1 then
	-- 	-- 	second = this.physics_object.transform:GetChild(3)
	-- 	-- else
	-- 	-- 	second = CS.UnityEngine.GameObject("debug_2")
	-- 	-- 	second.transform.parent = this.physics_object.transform
	-- 	-- end
	-- 	-- if second ~= nil then
	-- 	-- 	local flag, lr = second:TryGetComponent(typeof(CS.UnityEngine.LineRenderer))

	-- 	-- 	if not flag then
	-- 	-- 		lr = second:AddComponent(typeof(CS.UnityEngine.LineRenderer))

	-- 	-- 		lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	-- 	-- 		lr.startWidth = 0.02
	-- 	-- 		lr.endWidth = 0.02

	-- 	-- 		local color = CS.UnityEngine.Color.red

	-- 	-- 		lr.startColor = color
	-- 	-- 		color.a = 0
	-- 	-- 		lr.endColor = color
	-- 	-- 		lr.numCapVertices = 90
	-- 	-- 		lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

	-- 	-- 		-- lr.useWorldSpace = false
	-- 	-- 	end

	-- 	-- 	if lr ~= nil then
	-- 	-- 		lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
	-- 	-- 		lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
	-- 	-- 	end
	-- 	-- end
	-- end)

	-- self:addEvent("Object", function(this, value)

	-- 	local d = this.root.direction.x
		
	-- 	for i2 = 1, value.amount, 1 do

	-- 		local r = CS.Tools.Instance:RandomRangeInt(0, value.precise + 1) - value.precise / 2

	-- 		local rot = nil
	-- 		local velocityyy = nil
	-- 		local offset = nil
	-- 		-- if value.amount > 1 then
	-- 		-- 	offset = CS.Tools.Instance:RandomRangeInt(0, value.precise)
	-- 		-- else
	-- 			offset = 0
	-- 		-- end

	-- 		local randomvector = CS.UnityEngine.Vector3(0, CS.Tools.Instance:RandomRangeFloat(0, 1), CS.Tools.Instance:RandomRangeFloat(0, 1)).normalized

	-- 		rot = CS.UnityEngine.Quaternion.AngleAxis(r, randomvector) * this.physics_object.transform.rotation 

	-- 		velocityyy = rot * (CS.UnityEngine.Vector3(value.x2 - offset, value.y2, value.z2) * CS.Tools.Instance:RandomRangeFloat(0.9, 1))

	-- 		local pos = this.physics_object.transform.rotation * CS.UnityEngine.Vector3(value.x / 100 * 2, -value.y / 100 * 2, 0)

	-- 		local kk = nil
	-- 		if value.animation == "shell1" or value.animation == "shell2" then
	-- 			kk = 99
	-- 		else
	-- 			kk = 5
	-- 		end
	-- 		local object = utils.createObject(nil, tonumber(value.id), value.animation, 0, value.state, this.rigidbody.position.x + pos.x, this.rigidbody.position.y + pos.y, this.rigidbody.position.z + pos.z, velocityyy.x, velocityyy.y, velocityyy.z, kk)
	-- 		object.team = this.team
	-- 		-- local lr = object.pic_object:AddComponent(typeof(CS.UnityEngine.LineRenderer))
	-- 		-- -- lr.enabled = false
	-- 		-- lr.shadowCastingMode = CS.UnityEngine.Rendering.ShadowCastingMode.Off
	-- 		-- lr.startWidth = 0.01
	-- 		-- lr.endWidth = 0.02

	-- 		-- local rc = CS.Tools.Instance:RandomRangeInt(0, #v.colors) + 1
	-- 		-- local color = CS.Tools.Instance:ColorTryParseHtmlString("#" .. string.format("%X", v.colors[rc].color))

	-- 		-- lr.startColor = color
	-- 		-- lr.endColor = color
	-- 		-- lr.numCapVertices = 90
	-- 		-- lr.material = utils.LEGACYSHADERSPARTICLESALPHABLENDEDPREMULTIPLY

	-- 		object.direction.x = d

	-- 		object.physics_object.transform.rotation = rot

	-- 		-- object.rotation = rot.eulerAngles.z
			
	-- 	end
	-- end)

	-- self:addEvent("Rotation", function(this, value)
	-- 	if this.rotation_velocity == 0 then
	-- 		this.rotation_velocity = value.y2
	-- 	end
	-- end)

	-- self:addEvent("Destory", function(this, value)
	-- 	utils.destroyObject(this.physics_object:GetInstanceID())
	-- end)

	-- self:addEvent("OnClick", function(this, value)
	-- 	utils.invokeEvent("OnClick", this)
	-- end)
end

function LCastleDBCharacter:setState(from, to)
	local temp = {}
	for j, v2 in ipairs(from) do
		if v2.active then

			local _json = nil
			local _category = nil

			if v2.category == "Set" and type(v2.json) == "string" then
				_category = v2.category
				_json = {}
				_json.func = assert(load("function _set(this) " .. v2.json .. " end return _set", "set", "t", Rubbish))()
			else
				local s = nil
				if v2.json ~= nil then
					for k, v3 in pairs(v2.json) do
						local str = v3
						local p = ""
						if type(str) == "string" and string.sub(v3, 1, 1) == "-" then
							str = string.sub(v3, 2)
							p = "-"
						end
						if type(str) == "string" and tonumber(str) == nil and assert(load("return vars." .. str .." == true", "vars", "t", self))() then
							if s == nil then
								s = {}
							end
							s[k] = p .. "this." .. str
						end
					end
				end
				if s ~= nil then
					local value = "{"
					for k, v3 in pairs(v2.json) do
						if s[k] ~= nil then
							value = value .. k .. " = " .. s[k] .. ", "
						else
							value = value .. k .. " = " .. v3 .. ", "
						end
					end
					value = string.sub(value, 1, -3)
					value = value .. "}"
					-- print(value)
					_category = "Set"
					_json = {}
					_json.func = assert(load("function _set(this) " .. "this.database:invokeEvent('" .. v2.category .. "', this, " .. value .. ")" .. " end return _set", "set", "t", Rubbish))()
				else
					_category = v2.category
					_json = utils.deep_copy(v2.json)
				end
			end

			if tonumber(v2.trigger) then
				table.insert(temp[tonumber(v2.trigger)].test, {category = v2.category, json = _json})
			else
				local stateDef = {}
				stateDef.func = nil
				stateDef.test = {}

				if v2.trigger ~= nil and v2.trigger ~= "" then
					stateDef.func = assert(load("function _trigger(this) return " .. v2.trigger .. " end return _trigger", "trigger", "t", Rubbish))()
				end

				table.insert(stateDef.test, {category = _category, json = _json})

				table.insert(to, stateDef)
				temp[j - 1] = stateDef
			end
		end
	end
end

-- -- 添加事件
-- function LCastleDBCharacter:addEvent(eventName, action)
-- 	if not self.eventManager[eventName] then
-- 		self.eventManager[eventName] = Delegate()
-- 	end
-- 	self.eventManager[eventName].add(action)
-- end

-- -- 移除事件
-- function LCastleDBCharacter:removeEvent(eventName, action)
-- 	self.eventManager[eventName].delete(action)
-- end

-- -- 移除所有事件
-- function LCastleDBCharacter:removeAllEvent()
-- 	self.eventManager = {}
-- end

-- -- 触发事件
-- function LCastleDBCharacter:invokeEvent(eventName, ...)
-- 	if self.eventManager[eventName] then
-- 		self.eventManager[eventName].invoke(...)
-- 	end
-- end

---------------------------------------------------------------------------------------
