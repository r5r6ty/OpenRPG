-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

local json = require "json"
local utils = require 'LUtils'
-- require "LAI"

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

-- ¶ÁÈ¡imagesÖÐµÄpic
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
	return self.DBSheets[name].lines
end


LCastleDBCharacter = {characters = nil, AI = nil, texture2D = nil, sprites = nil, audioClips = nil, palettes = nil, animations = nil, characters_state = nil, FBcontorller = nil, animationClips = nil}
setmetatable(LCastleDBCharacter, castleDB)
LCastleDBCharacter.__index = LCastleDBCharacter
function LCastleDBCharacter:new(path, file)
	local self = {}
	self = castleDB:new(path, file)
	setmetatable(self, LCastleDBCharacter)

	self.characters = nil
	self.AI = nil
	self.texture2D = nil
	self.sprites = nil
	self.audioClips = nil
	self.palettes = nil

	self.animations = nil
	self.characters_state = nil
	self.FBcontorller = nil
	self.animationClips = nil
	return self
end

function LCastleDBCharacter:readDBLite()
	local str = utils.openFileText(self.DBPath .. self.DBFile)
    self.DBData = json.decode(str)
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


	self.characters = {}
	for i, v in ipairs(self:getLines("actions")) do
		self.characters[v.name] = v.frames
	end

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
				if currentFrame.category == "Sprite" then
					if self.animations[v.name].eventQueue[delayC] == nil then
						self.animations[v.name].eventQueue[delayC] = {}
					end

					-- print(v.name, delayC)

					table.insert(self.animations[v.name].eventQueue[delayC], 1, currentFrame)

					table.insert(self.animations[v.name].keyframes, delayC)

					delayC = delayC + currentFrame.wait
				-- elseif currentFrame.category == "Object" then
				-- 	if self.animations[v.name].eventQueue[delayC] == nil then
				-- 		self.animations[v.name].eventQueue[delayC] = {}
				-- 	end
				-- 	table.insert(self.animations[v.name].eventQueue[delayC], 1, currentFrame)
				elseif currentFrame.category == "Act" or currentFrame.category == "Object" or currentFrame.category == "Trigger" then
					for j = 0, currentFrame.wait - 1, 1 do
						if self.animations[v.name].eventQueue[delayC + j] == nil then
							self.animations[v.name].eventQueue[delayC + j] = {}
						end
						table.insert(self.animations[v.name].eventQueue[delayC + j], 1, currentFrame)
					end
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

	self.FBcontorller = {}

	self.characters_state = {}
	for i, v in ipairs(self:getLines("states")) do
		self.characters_state[v.name] = v.animations

		local p = utils.split(v.name, "_")

		if self.FBcontorller[p[1]] == nil then
			self.FBcontorller[p[1]] = {}
		end

		if p[2] == "front" and self.FBcontorller[p[1]].front == nil then
			self.FBcontorller[p[1]].front = v.name

			print("front", v.name)
		elseif  p[2] == "back" and self.FBcontorller[p[1]].back == nil  then
			self.FBcontorller[p[1]].back = v.name

			print("back", v.name)
		end

	end

	-- self.AI = LAI:new(self)

	self.audioClips = self:createAudioClips()
	self.texture2Ds, self.sprites = self:createSprites()
	self.palettes = self:createPalettes()
end

function LCastleDBCharacter:createAudioClips()
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
function LCastleDBCharacter:createSprites()
	--~     for i, v in pairs(texture2D) do
	--~         if pics[i] == nil then
	--~             pics[i] = CS.UnityEngine.Sprite.Create(v, CS.UnityEngine.Rect(0, 0, v.width, v.height), CS.UnityEngine.Vector2(0, 1))
	--~         end
	--~ 	end
		local p = utils.split(self.DBFile, ".")
	
		local data = utils.openFileBytes(self.DBPath .. p[1] .. ".png")

		if data ~= nil then
		
			local texture2D = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
			texture2D.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
			texture2D.filterMode = CS.UnityEngine.FilterMode.Point
		
			-- texture2D:LoadImage(data)
			CS.UnityEngine.ImageConversion.LoadImage(texture2D, data)
		
			local str = utils.openFileText(self.DBPath .. p[1] .. ".json")
		
			local spriteData = json.decode(str)
		
			local pics = {}
			for i, v in ipairs(spriteData) do
				if pics[v.id] == nil then
					pics[v.id] = CS.UnityEngine.Sprite.Create(texture2D, CS.UnityEngine.Rect(v.x, v.y, v.w, v.h), CS.UnityEngine.Vector2(0, 1))
				end
			end
		
			return texture2D, pics
		else
			return nil, {}
		end
	end

	
-- ?????
function LCastleDBCharacter:createPalettes()
	local palettes = {}
	for i, v in ipairs(self:getLines("palettes")) do

		local texture = CS.UnityEngine.Texture2D(256, 1, CS.UnityEngine.TextureFormat.RGBA32, false, false)
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
			if r ~= nil and g ~= nil and b ~=nil then
				if count == 0 then
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
	end
	return palettes
end



LCastleDBCharacter_new = {characters2 = nil, animations = nil}
setmetatable(LCastleDBCharacter_new, LCastleDBCharacter)
LCastleDBCharacter_new.__index = LCastleDBCharacter_new
function LCastleDBCharacter_new:new(path, file)
	local self = {}
	self = LCastleDBCharacter:new(path, file)
	setmetatable(self, LCastleDBCharacter_new)

	self.characters2 = nil
	self.animations = nil
	return self
end

function LCastleDBCharacter_new:readDBLite()
	local str = utils.openFileText(self.DBPath .. self.DBFile)
    self.DBData = json.decode(str)
end

function LCastleDBCharacter_new:readDB()
	local str = utils.openFileText(self.DBPath .. self.DBFile)

    self.DBData = json.decode(str)

	self.DBSheets = {}
    for i, v in ipairs(self.DBData["sheets"]) do
        if self.DBSheets[v.name] == nil then
            self.DBSheets[v.name] = v
        end
	end
	print(self.DBPath .. self.DBFile .. ": json read!")


	self.characters = {}
	self.characters2 = {}
	for i, v in ipairs(self:getLines("actions")) do
		self.characters[v.name] = v.frames
		if v.animations ~= nil then
			self.characters2[v.name] = v.animations
		end
	end

	self.AI = LAI:new(self)

	self.audioClips = self:createAudioClips()
	self.texture2Ds, self.sprites = self:createSprites()
	self.palettes = self:createPalettes()
end