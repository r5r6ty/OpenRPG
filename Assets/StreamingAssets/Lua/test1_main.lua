package.path = CS.UnityEngine.Application.dataPath .. "/StreamingAssets/Lua/utils/pngLua-master/?.lua"

require "LCastleDB"
local utils = require 'LUtils'
local json = require "json"


require 'png'

function Stream:__init(param) -- VXP4stream4zBk
    local str = ""
    if (param.inputF ~= nil) then
		str = param.inputF
    end
    if (param.input ~= nil) then
		str = param.input
    end

    for i = 1, #str, 1 do
		self.data[i] = str:byte(i, i)
    end
end

function printProg(line, totalLine)
	print(line .. " of " .. totalLine)
end

function start()

	local data = castleDB:new(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/Resource/data/", "data.cdb")
	data:readDB()
	for i, v in ipairs(data:getLines("data")) do
		local p = utils.split(v.file, "/")
		local cdb = LCastleDBMap:new(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/Resource/data/" .. p[1] .. "/", p[2])
		cdb:readDB()
		cdb:readIMG()

--~ 	createSpriteAtlas()

		createSpriteAtlas2(cdb)
	end

	local cdb = LCastleDBMap:new(CS.UnityEngine.Application.dataPath .. "/StreamingAssets/Resource/", "data2.cdb")
	cdb:readDB()
	cdb:readIMG()

--~ 	createSpriteAtlas()

	createSpriteAtlas2(cdb)


end

function sortGT(a, b)
--~     return a.tex.width * a.tex.height > b.tex.width * b.tex.height
    return a.tex.height > b.tex.height
end

function sortGT2(a, b)
--~     return a.tex.width * a.tex.height > b.tex.width * b.tex.height
    return a.y < b.y
end

-- 4S.img<STXM<F,Wv3Itexture2D
function loadImageToTexture2D_R8(b64str)
	local temp = utils.split(b64str, ",")
	temp = temp[#temp]
	local mod4 = #temp % 4
	if mod4 > 0 then
		for i = 1, 4 - mod4, 1 do
			temp = temp .. "="
		end
	end

	local bytes = CS.System.Convert.FromBase64String(temp)


	local str = Stream({inputF = bytes})
	if str:readChars(8) ~= "\137\080\078\071\013\010\026\010" then error 'Not a PNG' end
	local ihdr = {}
	local plte = {}
	local idat = {}
	local num = 1
	while true do
		ch = Chunk(str)
		if ch.name == "IHDR" then ihdr = IHDR(ch) end
		if ch.name == "PLTE" then plte = PLTE(ch) end
		if ch.name == "IDAT" then idat[num] = IDAT(ch) num = num+1 end
		if ch.name == "IEND" then break end
	end
	local dataStr = ""
	for k,v in pairs(idat) do dataStr = dataStr .. v.data end
	local output = {}
	deflate.inflate_zlib {input = dataStr, output = function(byte) output[#output+1] = string.char(byte) end, disable_crc = true}
	imStr = Stream({input = table.concat(output)})

	local height = ihdr.height
	local length = ihdr.width
	local colorType = ihdr.colorType
	local depth = ihdr.bitDepth
	local stream = imStr

	-- print(depth, colorType, ihdr.width, ihdr.height)
	if depth ~= 8 or colorType ~= 3 then
		return nil
	end

	local pixels = {}
	for i2 = 1, height, 1 do
		bpp = math.floor(depth/8) * bitFromColorType(colorType)
		bpl = bpp*length
		filterType = stream:readByte()
		stream:seek(-1)
		stream:writeByte(0)
		local startLoc = stream.position

--~ 	print(filterType)

		if filterType ~= 0 then
			print(filterType)
		end
		if filterType == 0 then
			for i = 1, length, 1 do
				local bps = math.floor(depth/8)
				local grey = stream:readInt(bps)
--~ 				print(i2, grey)
--~ 				pixels[(i2 - 1) + (i - 1) * length] = grey
				table.insert(pixels, grey)
--~ 				print(#pixels, grey)
			end
		end
		if filterType == 1 then
			for i = 1, length do
				for j = 1, bpp do
					local curByte = stream:readByte()
					stream:seek(-(bpp+1))
					local lastByte = 0
					if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
					stream:seek(bpp-1)
					stream:writeByte((curByte + lastByte) % 256)
				end
				stream:seek(-bpp)
--~ 				self.pixels[i] = Pixel(stream, depth, colorType, palette)
				local bps = math.floor(depth/8)
				local grey = stream:readInt(bps)
				table.insert(pixels, grey)
			end
		end
		if filterType == 2 then
			for i = 1, length do
				for j = 1, bpp do
					local curByte = stream:readByte()
					stream:seek(-(bpl+2))
					local lastByte = stream:readByte() or 0
					stream:seek(bpl)
					stream:writeByte((curByte + lastByte) % 256)
				end
				stream:seek(-bpp)
--~ 				self.pixels[i] = Pixel(stream, depth, colorType, palette)
				local bps = math.floor(depth/8)
				local grey = stream:readInt(bps)
				table.insert(pixels, grey)
			end
		end
		if filterType == 3 then
			for i = 1, length do
				for j = 1, bpp do
					local curByte = stream:readByte()
					stream:seek(-(bpp+1))
					local lastByte = 0
					if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
					stream:seek(-(bpl)+bpp-2)
					local priByte = stream:readByte() or 0
					stream:seek(bpl)
					stream:writeByte((curByte + math.floor((lastByte+priByte)/2)) % 256)
				end
				stream:seek(-bpp)
--~ 				self.pixels[i] = Pixel(stream, depth, colorType, palette)
				local bps = math.floor(depth/8)
				local grey = stream:readInt(bps)
				table.insert(pixels, grey)
			end
		end
		if filterType == 4 then
			for i = 1, length do
				for j = 1, bpp do
					local curByte = stream:readByte()
					stream:seek(-(bpp+1))
					local lastByte = 0
					if stream.position >= startLoc then lastByte = stream:readByte() or 0 else stream:readByte() end
					stream:seek(-(bpl + 2 - bpp))
					local priByte = stream:readByte() or 0
					stream:seek(-(bpp+1))
					local lastPriByte = 0
					if stream.position >= startLoc - (length * bpp + 1) then lastPriByte = stream:readByte() or 0 else stream:readByte() end
					stream:seek(bpl + bpp)
					stream:writeByte((curByte + _PaethPredict(lastByte, priByte, lastPriByte)) % 256)
				end
				stream:seek(-bpp)
--~ 				self.pixels[i] = Pixel(stream, depth, colorType, palette)
				local bps = math.floor(depth/8)
				local grey = stream:readInt(bps)
				table.insert(pixels, grey)
			end
		end
	end

	-- <STXM<F,
	local texture = CS.UnityEngine.Texture2D(length, height, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	texture.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
	texture.filterMode = CS.UnityEngine.FilterMode.Point
--~ 	CS.UnityEngine.ImageConversion.LoadImage(texture, bytes) -- Ub8vTuC42;PPAK#?
--~ 	texture:LoadImage(bytes) --- Texture2d  3IT17=7(N^7(J9SC#,N*J2C4#?N*J2C4SVD\J9SCAK#?
--~ 	print(texture.format, texture.graphicsFormat)

	for j3 = 0, height - 1, 1 do
		for i3 = 0, length - 1, 1 do
			local num = (i3 + j3 * length) + 1
--~ 			print(i3, j3, num)
			texture:SetPixel(i3, height - j3 - 1, CS.UnityEngine.Color(pixels[num] / 255, 0, 0))
		end
	end

--~     for p, a in ipairs(pixels) do
--~         for k, b in ipairs(pixels[p]) do
--~ 			local color = pixels[k][p]
--~ 			print(k, p, color)
--~ 			texture:SetPixel(k - 1, p - 1, CS.UnityEngine.Color(color / 255, color / 255, color / 255))
--~ 		end
--~ 	end
	texture:Apply()
	return texture
end

function bitFromColorType(colorType)
	if colorType == 0 then return 1 end
	if colorType == 2 then return 3 end
	if colorType == 3 then return 1 end
	if colorType == 4 then return 2 end
	if colorType == 6 then return 4 end
	error 'Invalid colortype'
end

--Stolen right from w3.
function _PaethPredict(a, b, c)
	local p = a + b - c
	local varA = math.abs(p - a)
	local varB = math.abs(p - b)
	local varC = math.abs(p - c)
	if varA <= varB and varA <= varC then return a end
	if varB <= varC then return b end
	return c
end

function createSpriteAtlas()

	local textures = {}
	for i, v in pairs(charactersDB.IMGData) do


	    local t = utils.loadImageToTexture2D(v)

		table.insert(textures, {id = i, x = 0, y = 0, tex = t})
	end

	table.sort(textures, sortGT)


	local bigTexWidth = 0
	local bigTexHeight = 0
	for i, v in ipairs(textures) do
--~ 		print(v.tex.width, v.tex.height)

		bigTexWidth = bigTexWidth + v.tex.width
		bigTexHeight = bigTexHeight + v.tex.height
	end

	bigTexWidth = math.floor(bigTexWidth / 2 + 0.5)
	bigTexHeight = math.floor(bigTexHeight / 2 + 0.5)

	local bigTex = {}


	local points = {}
	table.insert(points, {x = 0, y = 0})


	local maxX = 0
	local maxY = 0

--~ 	local c = 0
	for i2, v2 in ipairs(textures) do
		local r = false
		for i3, v3 in ipairs(points) do
			if v3.x + v2.tex.width - 1 < bigTexWidth and compare(bigTex, v3.x, v3.y, v2.tex.width, v2.tex.height) then

				for i = v3.x, v3.x + v2.tex.width - 1, 1 do
					if bigTex[i] == nil then
						bigTex[i] = {}
					end
					for j = v3.y, v3.y + (v2.tex.height - 1), 1 do
--~ 						bigTex[i][j] = CS.UnityEngine.Color.red
						bigTex[i][j] = v2.tex:GetPixel(i - v3.x, j - v3.y)
--~ 						print(i, j, i - v3.x, j - v3.y, bigTex[i][j])
					end
				end

				if v3.x + v2.tex.width > maxX then
					maxX = v3.x + v2.tex.width
				end
				if v3.y + v2.tex.height > maxY then
					maxY = v3.y + v2.tex.height
				end

--~ 				print(v3.x, v3.y)

				local t1x = v3.x + v2.tex.width
				local t1y = v3.y
				local t2x = v3.x
				local t2y = v3.y + v2.tex.height
				table.remove(points, i3)



				table.insert(points, {x = t1x, y = t1y}) -- SRIO=G

				table.insert(points, {x = t2x, y = t2y}) -- WsOB=G

				table.sort(points, sortGT2)
--~ 				print(v3.x)

				r = true
				break
			else
--~ 				print(v3.x + v2.tex.width - 1 < bigTexWidth, compare(bigTex, v3.x, v3.y, v2.tex.width, v2.tex.height))
			end
		end
--~ 		print(r)
--~ 		c = c + 1
--~ 		if c == 2 then
--~ 			break
--~ 		end
	end



	local texture = CS.UnityEngine.Texture2D(maxX, maxY, CS.UnityEngine.TextureFormat.R8, false, false)
	texture.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
	texture.filterMode = CS.UnityEngine.FilterMode.Point

    for p, a in pairs(bigTex) do
        for k, b in pairs(bigTex[p]) do
			texture:SetPixel(p, k, bigTex[p][k])
--~ 			print(p, k, bigTex[p][k])
		end
	end
	texture:Apply()


	local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(0, 0, texture.width, texture.height), CS.UnityEngine.Vector2(0, 1))

	local unityobject_child = CS.UnityEngine.GameObject("test")
	local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	sr.sprite = sprite


--~ 	local byte = texture:EncodeToPNG()

--~ 	local file = io.open(filePath .. "wocao.png", "w")
--~ 	file:write(byte)
--~ 	file:close()

end

function createSpriteAtlas2(db)
	local textures = {}
	local textureNames = {}
	for i, v in pairs(db.IMGData) do
	    local t = loadImageToTexture2D_R8(v) -- utils.loadImageToTexture2D(v)

		if t ~= nil then
			table.insert(textures, t)
			table.insert(textureNames, {id = i, x = nil, y = nil, w = nil, h = nil})
--~ 			break
		end

	end

	local rects = {}
	local texture = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
	texture.wrapMode = CS.UnityEngine.TextureWrapMode.Clamp
	texture.filterMode = CS.UnityEngine.FilterMode.Point
	rects = texture:PackTextures(textures, 0)



	texture:Apply()

--~ 	local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(0, 0, texture.width, texture.height), CS.UnityEngine.Vector2(0, 1))

--~ 	local unityobject_child = CS.UnityEngine.GameObject("test")
--~ 	local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
--~ 	sr.sprite = sprite

	local p2 = utils.split(db.DBFile, ".")
	local atlas = string.format("\n%s\nsize: %d,%d\nformat: RGBA8888\nfilter: Linear,Linear\nrepeat: none",p2[1] .. ".png", texture.width, texture.height)

	local ske = {}
	local count = 0
	local spine = db:getLines("spines")
	if spine ~= nil then
		for i, v in ipairs(spine) do
			ske[v.name] = {}
			for i2, v2 in ipairs(v.sprites) do
				ske[v.name][v2.sprite] = v2.name
			end
			count = count + 1
		end
	end

	local p = CS.UnityEngine.GameObject(db.DBFile)
	for i = 1, #textures, 1 do



		local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(rects[i - 1].x * texture.width, rects[i - 1].y * texture.height, rects[i - 1].width * texture.width, rects[i - 1].height * texture.height), CS.UnityEngine.Vector2(0, 1))

		local unityobject_child = CS.UnityEngine.GameObject(textureNames[i].id)
		unityobject_child.transform.parent = p.transform
		unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(rects[i - 1].x * texture.width / 100, -rects[i - 1].y * texture.height / 100, 0)
		local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
		sr.sprite = sprite


		textureNames[i].x = math.floor(rects[i - 1].x * texture.width)
		textureNames[i].y = math.floor(rects[i - 1].y * texture.height)
		textureNames[i].w = math.floor(rects[i - 1].width * texture.width)
		textureNames[i].h = math.floor(rects[i - 1].height * texture.height)

		for j, k in pairs(ske) do
			if k[textureNames[i].id] ~= nil then
				atlas = atlas .. "\n" .. string.format("%s\n  rotate: false\n  xy: %d, %d\n  size: %d, %d\n  orig: %d, %d\n  offset: 0, 0\n  index: -1", k[textureNames[i].id], textureNames[i].x, texture.width - textureNames[i].h - textureNames[i].y, textureNames[i].w, textureNames[i].h, textureNames[i].w, textureNames[i].h)
			end
		end
	end

--~ 	local byte = texture:EncodeToPNG()

--~ 	local file = io.open(filePath .. "wocao.png", "w")
--~ 	file:write(byte)
--~ 	file:close()

	
	CS.System.IO.File.WriteAllBytes(db.DBPath .. p2[1] .. ".png", CS.UnityEngine.ImageConversion.EncodeToPNG(texture))

	CS.System.IO.File.WriteAllBytes(db.DBPath .. p2[1] .. ".json", json.encode(textureNames))
	if count > 0 then
		CS.System.IO.File.WriteAllBytes(db.DBPath .. p2[1] .. ".atlas", atlas)
	end

	print("completed!")
end

function compare(bigTex, x, y, w, h)
	for i = x, x + w - 1, 1 do
        for j = y, y + (h - 1), 1 do
			if bigTex[i] == nil or bigTex[i][j] == nil then

			else
				return false
			end
		end
	end
	return true
end
