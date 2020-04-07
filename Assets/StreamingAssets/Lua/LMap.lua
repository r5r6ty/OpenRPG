-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

require "LCastleDB"
require "LTileRoom"
local utils = require "LUtils"

local tool2_castleDB = {}            -- Public namespace

-- Private functions
local loadTile
local loadLevel
local loadLiker
local dpdp
local table_maxn
local table_minn
local loadTileSet
local comp
local ruileJudge
local crateRoom
local outlineMap
local fillMap

local castleDBInstance = nil

local dataBase = {data = nil,
                  textures = {}, -- texture2Ds
                  blocksTiles = {}, -- sprites
                  linkersTiles = {}, -- sprites
                  markersTiles = {}, -- sprites
                  levels = {},
				--   tiles = {}, -- sprites
				  tileSets = {}}

local gameMap = {}

-- 数据库new
function tool2_castleDB.new(path, file)
    castleDBInstance = LCastleDBMap:new(path, file)
    castleDBInstance:readDB()

--    local str = ""
--    for j = 1, hhh, 1 do
--        for i = 1, www, 1 do
--            str = str .. tt[i + (j - 1) * www]
--        end
--        str = str .. "\n"
--    end
--    print(str)

    loadTile(castleDBInstance:getLines("block"), dataBase.blocksTiles)
    loadTile(castleDBInstance:getLines("link"), dataBase.linkersTiles)
    loadTile(castleDBInstance:getLines("marker"), dataBase.markersTiles, true)

	loadTileSet()

	loadLevel()

--~ 	tiletiletile()
end

-- 读取tool2_castleDB的tile(数据，sprite存入的table)
-- 格式：
function loadTile(data, tiles, flag)
    flag = flag or false
    for i, v in ipairs(data) do
		local ff = v["icon"]["file"]
        if dataBase.textures[ff] == nil then
            dataBase.textures[ff] = utils.LoadImageToTexture2DByPath(castleDBInstance.DBPath .. ff)
        end
        -- 用texture生成sprite
        local s = utils.CreateSprite(dataBase.textures[ff], v["icon"]["x"], v["icon"]["y"], v["icon"]["size"])
        if flag then
            tiles[v["id"]] = {tileSort = v["sort"], sprite = s} -- 插入sort权重和sprite，用名字查找
        else
            table.insert(tiles, {tileSort = v["sort"], sprite = s}) -- 插入sort权重和sprite，用下标调用
			tiles[v["id"]] = #tiles - 1 -- 设置以名字查找序号方法，方便实用
        end
    end
end

-- 读取level
function loadLevel()
    for index, value in ipairs(castleDBInstance:getLines("levelData")) do
		local tab = value
		local aaa = tab["blocks"]
		local bbb = tab["linkers"]
		local ccc = tab["markers"]
		local www = tab["width"]
		local hhh = tab["height"]
		local tileSize = tab["props"]["tileSize"]
		local tt = utils.Base64DecodeToArray_TileMode(aaa)
		local tt2 = utils.Base64DecodeToArray_TileMode(bbb)
		local tt3 = {}
		for i, v in ipairs(ccc) do
			tt3[i] = {id = v.kind, x = v.x, y = v.y, width = v.width, height = v.height}
		end

		local temp = {}
		-- 临时做一个处理linker的处理connectors
		for i_y = 0, hhh - 1 do
			for i_x = 0, www - 1 do
				if tt2[i_x + i_y * www + 1] ~= 0 then
					if temp[i_x + 1] == nil then
						temp[i_x + 1] = {}
					end
					temp[i_x + 1][i_y + 1] = tt2[i_x + i_y * www + 1]
				end
			end
		end

		-- 深搜一下把相邻的同类型的linker归类到一个类型连接器里放到数组connectors里
		local id = 1
		local conn = {}
		for p, a in pairs(temp) do
			for k, b in pairs(temp[p]) do
				local t = {}
				local dt = {}
				local r = dpdp(temp, p, k, temp[p][k], t, dt)
				if r ~= 0 then
					local c = {index = id, kind = r, isConnected = false, width = 0, height = 0, position = t, dPosition = dt}

					local w2, h2 = table_maxn(c.position)
					local w1, h1 = table_minn(c.position)
					c.width = w2 - w1 + 1
					c.height = -(h1 - h2) + 1

					table.insert(conn, c)
					id = id + 1
				end
			end
		end

	--    print("count:" .. #conn)
	--    for f, g in pairs(conn) do
	--        print(#g.position)
	--    end

		local level = {name = tab["level"], width = www, height = hhh, size = tileSize, blocks = tt, linkers = tt2, markers = tt3, connectors = conn}
		table.insert(dataBase.levels, level)
	end
end

function dpdp(t1, x, y, value, t2, t3)
    if t1[x] ~= nil then
        if t1[x][y] ~= nil then
        else
            return 0
        end
    else
        return 0
    end

	if t1[x][y] ~= 1 and t1[x][y] ~= 2 and t1[x][y] ~= 3 and t1[x][y] ~= 4 then

		if t1[x][y] ~= 0 and t1[x][y] == value then
			table.insert(t3, {x = x - 1, y = y - 1})
			t1[x][y] = 0
		elseif t1[x][y] ~= 0 and t1[x][y] - 4 == value then
			table.insert(t3, {x = x - 1, y = y - 1})
			t1[x][y] = 0
		else
			return 0
		end

	else

		if t1[x][y] ~= 0 and t1[x][y] == value then
			table.insert(t2, {x = x - 1, y = y - 1})
			t1[x][y] = 0
		elseif t1[x][y] ~= 0 and t1[x][y] + 4 == value then
			table.insert(t2, {x = x - 1, y = y - 1})
			t1[x][y] = 0
		else
			return 0
		end

	end
    dpdp(t1, x + 0, y + 1, value, t2, t3)
    dpdp(t1, x + 0, y - 1, value, t2, t3)
    dpdp(t1, x + 1, y + 0, value, t2, t3)
    dpdp(t1, x - 1, y + 0, value, t2, t3)
    return value
end

-- 取最大xy
function table_maxn(t)
    local mn_x = nil
    local mn_y = nil
    for k, v in pairs(t) do
        if mn_x == nil then
            mn_x = v.x
        end
        if mn_y == nil then
            mn_y = v.y
        end
        if mn_x < v.x then
            mn_x = v.x
        end
        if mn_y < v.y then
            mn_y = v.y
        end
    end
    return mn_x, mn_y
end

-- 取最小xy
function table_minn(t)
    local mn_x = nil
    local mn_y = nil
    for k, v in pairs(t) do
        if mn_x == nil then
            mn_x = v.x
        end
        if mn_y == nil then
            mn_y = v.y
        end
        if mn_x > v.x then
            mn_x = v.x
        end
        if mn_y > v.y then
            mn_y = v.y
        end
    end
    return mn_x, mn_y
end

-- 读取tile规则
function loadTileSet(index)
    for index, value in ipairs(castleDBInstance:getLines("tileSet")) do
		local da = value
		local data = value["layers"]
		for i, v in ipairs(data) do
			if v["active"] == true then
				-- 读取texture和sprite
				-- local ff = v["tile"]["file"]
				-- if dataBase.textures[ff] == nil then
				-- 	dataBase.textures[ff] = utils.LoadImageToTexture2DByPath(castleDBInstance.DBPath .. ff)
				-- end
				-- local s = utils.CreateSprite(dataBase.textures[ff], v["tile"]["x"], v["tile"]["y"], v["tile"]["size"])
				-- table.insert(dataBase.tiles, s)
				-- table.insert(dataBase.tiles, s)

				local s = castleDBInstance.sprites[v["tile2"]]

				local sa = {}
				for i2, v2 in ipairs(v["tiles"]) do
					-- local s2 = utils.CreateSprite(dataBase.textures[ff], v2["tile"]["x"], v2["tile"]["y"], v2["tile"]["size"])
					-- table.insert(dataBase.tiles, s2)
					-- table.insert(sa, s2)
					table.insert(sa, castleDBInstance.sprites[v2["tile2"]])
				end

				local sa_wall = {}
				-- for i2, v2 in ipairs(v["walls"]) do
				-- 	local s2 = utils.CreateSprite(dataBase.textures[ff], v2["tile"]["x"], v2["tile"]["y"], v2["tile"]["size"])
				-- 	table.insert(dataBase.tiles, s2)
				-- 	table.insert(sa_wall, s2)
				-- end

				local wall_s = nil
				-- if v["walls"] ~= nil then
				-- 	wall_s = utils.CreateSprite(dataBase.textures[ff], v["walls"]["x"], v["walls"]["y"], v["walls"]["size"])
				-- end
				if v["walls2"] ~= nil then
					wall_s = castleDBInstance.sprites[v["walls2"]]
				end

				-- 读取tile规则
				local tt = utils.Base64DecodeToArray_Ground(v["data"]["data"])
	--~ 			for g = 1, #tt, 1 do
	--~ 				print(tt[g])
	--~ 			end

				local r = nil
				if tt[5] == 5 then
					r = "Fixed"
				elseif tt[5] == 10 then
					r = "Mirror X"
				elseif tt[5] == 11 then
					r = "Mirror Y"
				else
					r = "Rotated"
				end

				for i = 1, #tt, 1 do
					if i ~= 5 then
						if tt[i] ~= 0 then
							if tt[i] ~= 5 then
								tt[i] = true
							else
								tt[i] = false
							end
						else
							tt[i] = nil
						end
					else
						tt[i] = nil
					end
				end


				local g = {}
				-- 生成规则grid
				for i = -1, 1, 1 do
					g[i] = {}
					for j = -1, 1, 1 do
						local p = tt[(i + 1) + (j + 1) * 3 + 1]
						if p == true then
							p = {}
							if #v["rules"] > 0 then
								for k, r in ipairs(v["rules"]) do
									if r["x"] == i and r["y"] == j then
										table.insert(p, dataBase.blocksTiles[r["block"]])
									end
								end
							end
							if #p == 0 then
								table.insert(p, dataBase.blocksTiles[da["tileType"]])
							end
						end
						g[i][j] = p
					end
				end

	--~ 			print(v["name"])
	--~ 			for p, a in pairs(g) do
	--~ 				for k, b in pairs(g[p]) do
	--~ 					print(p .. "," .. k .. ":", g[p][k])
	--~ 				end
	--~ 			end
				local tab = {name = v["name"], tileType = da["tileType"], rule = r, gird = g, sprite = s, spriteArray = sa, walls = wall_s, size = 16} -- v["tile"]["size"]
				table.insert(dataBase.tileSets, tab)
			end
		end
	end
end

function tool2_castleDB.show(index, x, y)
    local level = dataBase.levels[index]
    local unityobject = CS.UnityEngine.GameObject("test")
    show2(level, unityobject, "blocks", dataBase.blocksTiles, level.blocks, x, y)
    show2(level, unityobject, "linkers", dataBase.linkersTiles, level.linkers, x, y)

    local m = CS.UnityEngine.GameObject("markers")
    m.transform.parent = unityobject.transform
    for i, v in ipairs(level.markers) do
        for i_y = 0, v.height - 1, 1 do
            for i_x = 0, v.width - 1, 1 do
                local m_child = CS.UnityEngine.GameObject("block" .. v.x + x .. "," .. v.y + y .. "[" .. v.id .. "]")
                m_child.transform.parent = m.transform
                m_child.transform.localPosition = CS.UnityEngine.Vector3((v.x + i_x + x) * level.size / 100, -(v.y - i_y + y) * level.size / 100, 0)
                local sr = m_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
                sr.sprite = dataBase.markersTiles[v.id]
            end
        end
    end
end

function show2(level, p, name, tiles, tiletile, x, y)
    local unityobject = CS.UnityEngine.GameObject(name)
    unityobject.transform.parent = p.transform
    for i_y = 0, level.height - 1, 1 do
        for i_x = 0, level.width - 1, 1 do
            local num = tiletile[i_x + i_y * level.width + 1]
            local unityobject_child = CS.UnityEngine.GameObject("block" .. i_x + x .. "," .. i_y + y .. "[" .. num .. "]")
            unityobject_child.transform.parent = unityobject.transform
            unityobject_child.transform.localPosition = CS.UnityEngine.Vector3((i_x + x) * level.size / 100, -(i_y + y) * level.size / 100, 0)
            local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
            sr.sprite = tiles[num + 1]
            if num == 0 then
                sr.enabled = false
            end
        end
    end
end

function tool2_castleDB.createRoom(map, index, x, y)
    local level = dataBase.levels[index]
    local table_linkers = {}

    local temp = {}
    for i = x, x + level.width - 1, 1 do
        map[i] = {}
        temp[i] = {}
        for j = y, y + level.height - 1, 1 do
            local num = (i + j *level.width) + 1
            map[i][j] = level.blocks[num]
            temp[i][j] = level.linkers[num]
        end
    end

    for j = y, y + level.height - 1, 1 do
        for i = x, x + level.width - 1, 1 do
            if temp[i][j] ~= 0 then
                local p = temp[i][j]
                local t = {kind = p, pos = {}}
                local k = i
                local l = j
                while temp[k][l] ~= nil and temp[k][l] == p do
                    while temp[k][l] ~= nil and temp[k][l] == p do
                        table.insert(t.pos, {x = k, y = l})
                        temp[k][l] = 0
--                        l = l + 1
                    end
--                    k = k + 1
                end
                table.insert(table_linkers, t)
            end
        end
    end

--    local str = ""
--    for j = y, y + level.height - 1, 1 do
--        for i = x, x + level.width - 1, 1 do
--            str = str .. map[i][j].block
--        end
--        str = str .. "\n"
--    end
--    print(str)
    return { x = x, y = y, w = level.width, h = level.height, map = map, linkers = table_linkers }
end

function tool2_castleDB.linkRoom(room, index)
    local temp_room = tool2_castleDB.createRoom({}, index, 0, 0)

    local r = CS.Tools.Instance:RandomRangeInt(1, #temp_room.linkers + 1)
    local t_x = temp_room.linkers[r].pos[1].x
    local t_y = temp_room.linkers[r].pos[1].y

--    for i = x, x + level.width - 1, 1 do
--        for j = y, y + level.height - 1, 1 do

--        end
--    end

    local r2 = CS.Tools.Instance:RandomRangeInt(1, #room.linkers + 1)
    local count = 0
    while room.linkers[r2].kind ~= temp_room.linkers[r].kind and count < 100 do
        r2 = CS.Tools.Instance:RandomRangeInt(1, #room.linkers + 1)
        count = count + 1
    end
    local kkk = 0
    if room.linkers[r2].kind ~= temp_room.linkers[r].kind then
        return false, nil
    else
        kkk = room.linkers[r2].kind
    end
    local x = room.linkers[r2].pos[1].x
    local y = room.linkers[r2].pos[1].y
    local offsetx = 0
    if kkk == 2 then
        offsetx = (CS.Tools.Instance:RandomRangeInt(0, 1) - 0.5) / 0.5
    elseif kkk == 4 then
        offsetx = (CS.Tools.Instance:RandomRangeInt(0, 1) - 0.5) / 0.5
    end

    local x2 = x + offsetx - t_x
    local y2 = y - t_y
    for i = x2, x2 + temp_room.w - 1, 1 do
        for j = y2, y2 + temp_room.h - 1, 1 do
            if room.map[i] ~= nil then
                if room.map[i][j] ~= nil then
                    return false, nil
                end
            end
        end
    end
--    for i, z in pairs(room.map) do
--        for j, v in pairs(room.map[i]) do
--            print(i, j)
--        end
--    end

    local room2 = tool2_castleDB.createRoom(room.map, index, x2, y2)
    tool2_castleDB.show(index, x2, y2)



--    for a, b in ipairs(room.linkers) do
--        if b.kind == 2 then
--            local x = b.pos[1].x
--            local y = b.pos[1].y
--            tool2_castleDB.createRoom(index, x + 1, y)
--            tool2_castleDB.show(index, x + 1, y)
--        end
--    end
    return true, room2
end

-- 生成关卡（测试中）
function tool2_castleDB.gen()
	local test = dataBase.levels[CS.Tools.Instance:RandomRangeInt(1, #dataBase.levels + 1)]
    local room = tileRoom:new(0, 0, test, gameMap, test.name .. "mainhouse")

	local decorations = {}
--  local room2 = nil
-- 	local room3 = nil
-- 	local x = nil
-- 	local y = nil
--     x, y, room2 = room:link(1, dataBase.levels[3], gameMap, "test1")
-- 	room:close(gameMap)
-- 	x, y, room3 = room2:link(1, dataBase.levels[2], gameMap, "test2")
-- 	room2:close(gameMap)
-- 	room3:close(gameMap)
	local t = crateRoom(room, 10)
	for i = 1, #t, 1 do
		t[i]:close(gameMap)
		local d = tool2_castleDB.drawBackGround(t[i].map, 0, 0, 2, "door", 5, 7)
		for i, v in ipairs(d) do
			table.insert(decorations, v)
		end
		local d2 = tool2_castleDB.drawBackGround(t[i].map, 0, 0, 2, "gate", 4, 6)
		for i, v in ipairs(d2) do
			table.insert(decorations, v)
		end
	end

--~ 	outlineMap(gameMap)
--~ 	outlineMap(gameMap)
--~ 	outlineMap(gameMap)
--~ 	outlineMap(gameMap)
--~ 	outlineMap(gameMap)
	fillMap(gameMap)

--~ 	-- 可视化gameMap
--~     local p = CS.UnityEngine.GameObject("test")
--~     local unityobject = CS.UnityEngine.GameObject("blocks")
--~     unityobject.transform.parent = p.transform
--~     for p, a in pairs(gameMap) do
--~         for k, b in pairs(gameMap[p]) do
--~             local unityobject_child = CS.UnityEngine.GameObject("block" .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]")
--~             unityobject_child.transform.parent = unityobject.transform
--~             unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * 16 / 100, -k * 16 / 100, 0)
--~             local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
--~             sr.sprite = dataBase.blocksTiles[gameMap[p][k] + 1].sprite
--~ --            if gameMap[p][k] == 0 then
--~ --                sr.enabled = false
--~ --            end
--~         end
--~     end
	tool2_castleDB.drawMap(gameMap, 0, 0, 2)

	return decorations
end

function tool2_castleDB.gen2(x, y, scale)
	local test = dataBase.levels[1]
	local room = tileRoom:new(0, 0, test, gameMap, test.name .. "mainhouse")
	room:close(gameMap)
	fillMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	outlineMap(gameMap)
	tool2_castleDB.drawMap(gameMap, x, y, scale)
	local decorations = tool2_castleDB.drawBackGround(room.map, x, y, scale, "door", 5, 7)
	return decorations
end

function tool2_castleDB.gen3(x, y, scale)
	local test = dataBase.levels[2]
	local room = tileRoom:new(0, 0, test, gameMap, test.name .. "mainhouse2")
	room:close(gameMap)
	fillMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	-- outlineMap(gameMap)
	tool2_castleDB.drawMap(gameMap, x, y, scale)
	local decorations = tool2_castleDB.drawBackGround(room.map, x, y, scale, "door", 5, 7)
	return decorations
end

function tool2_castleDB.drawBackGround(map, x, y, scale, n, w, h)
--~     local p = CS.UnityEngine.GameObject("test")
--~     local unityobject = CS.UnityEngine.GameObject("blocks")
--~     unityobject.transform.parent = p.transform
--~ 	local sortArray = {}

	local decorations = {}
    for p, a in pairs(map) do
        for k, b in pairs(map[p]) do
			if (map[p][k] == 1 or map[p][k] == 2) and (map[p][k - 1] ~= nil and (map[p][k - 1] == 0 or map[p][k - 1] == 4)) then -- 先判断地面上的东西
				local decoration = tool2_castleDB.judgeBackGround(map, p, k - 1, w, h)
--~ 				print(decoration)
				if decoration ~= nil then
--~ 					for q, c in pairs(decoration) do
--~ 						for l, d in pairs(decoration[q]) do
--~ 								map[q][l] = nil

--~ 								if sortArray[10] == nil then
--~ 									local sortObject = CS.UnityEngine.GameObject("Sort " .. 10)
--~ 									sortObject.transform.parent = unityobject.transform
--~ 									sortArray[10] = sortObject
--~ 								end

--~ 								ts = dataBase.tileSets[1]
--~ 								n = ts.name

--~ 								local unityobject_child = CS.UnityEngine.GameObject("background" .. q .. "," .. l .. "[" .. gameMap[q][l] .. "]" .. n)
--~ 								unityobject_child.transform.parent = sortArray[10].transform
--~ 								unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(q * ts.size / 100, -l * ts.size / 100, 0)
--~ 								local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
--~ 								sr.sprite = ts.spriteArray[CS.Tools.Instance:RandomRangeInt(1, #ts.spriteArray + 1)]
--~ 								sr.sortingOrder = -10

--~ 						end
--~ 					end
					print(n, x + p * 0.2 * scale, y + -(k - 1 + 1) * 0.2 * scale, decoration)
					table.insert(decorations, {name = n, dx = x + p * 0.2 * scale, dy = y + -(k - 1 + 1) * 0.2 * scale, width = decoration})
				end
			end
		end
	end
--~ 	p.transform.position = CS.UnityEngine.Vector3(x, y, 0)
--~ 	p.transform.localScale = CS.UnityEngine.Vector3(scale, scale, 1)
	return decorations
end

function tool2_castleDB.judgeBackGround(map, p, k, width, height)
--~ 	local decoration = {}
	local b = false
	local i = 0
	while true do
		for j = 0, height - 1, 1 do
			if map[p + i] ~= nil then
				if map[p + i][k - j] ~= nil and (map[p + i][k - j] == 0 or map[p + i][k - j] == 4) and (map[p + i][k + 1] == 1 or map[p + i][k + 1] == 2) then
--~ 					if decoration[p + i] == nil then
--~ 						decoration[p + i] = {}
--~ 					end
--~ 					decoration[p + i][k - j] = 999
				else
--~ 					print("gaga")
--~ 					i = i - 1
					b = true
					break
				end
			else
--~ 				print("gaga")
				b = true
				break
			end
		end
		if b then
			break
		end
		i = i + 1
	end
	if i >= width - 1 then
		local bw = i
		for i = 0, bw - 1, 1 do
			for j = 0, height - 1, 1 do
				map[p + i][k - j] = nil
			end
		end
		return bw
	else
		return nil
	end
end

-- 渲染gameMap2D
function tool2_castleDB.drawMap(gameMap, x, y, scale)
	-- 渲染gameMap
    local p = CS.UnityEngine.GameObject("test")
    local unityobject = CS.UnityEngine.GameObject("blocks")
	unityobject.transform.parent = p.transform
	


	local sortArray = {}
    for p, a in pairs(gameMap) do
        for k, b in pairs(gameMap[p]) do
			if gameMap[p][k] == 0 or gameMap[p][k] == 2 or gameMap[p][k] == 4 then -- 生成背景
				if sortArray[10] == nil then
					local sortObject = CS.UnityEngine.GameObject("Sort " .. 10)
					sortObject.transform.parent = unityobject.transform
					-- sortObject.transform.localPosition = CS.UnityEngine.Vector3(0, 0, 10 / 100)
					sortArray[10] = sortObject
				end

				ts = dataBase.tileSets[1]
				n = ts.name

				-- local unityobject_child = CS.UnityEngine.GameObject("background" .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]" .. n)
				-- unityobject_child.transform.parent = sortArray[10].transform

				-- -- local posX = p * ts.size / 100
				-- -- local posY = -k * ts.size / 100
				-- -- local posZ = 0
				-- local posX = p * ts.size / 100
				-- local posY = 0
				-- local posZ = -k * ts.size / 100

				-- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(posX, posY, posZ)
				-- local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
				-- sr.sprite = ts.spriteArray[CS.Tools.Instance:RandomRangeInt(1, #ts.spriteArray + 1)]
				-- sr.material = castleDBInstance.palettes[1]
				-- sr.sortingOrder = -10

				local unityobject_child = tool2_castleDB.createMapObject(sortArray[10].transform, "background", p, k, gameMap, n, ts, ts.spriteArray[CS.Tools.Instance:RandomRangeInt(1, #ts.spriteArray + 1)], -10, "background")

				unityobject_child.layer = 1
				local bit = tool2_castleDB.judgeColliderType3D(gameMap, p, k)

				unityobject_child.name = unityobject_child.name .. "," .. bit
				if bit > 0 then
					-- local boxCollider = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider))
					-- boxCollider.center = CS.UnityEngine.Vector3(boxCollider.center.x, boxCollider.center.y + ts.size / 100 / 2, boxCollider.center.z) --  - ts.size / 100
					-- boxCollider.size = CS.UnityEngine.Vector3(ts.size / 100, ts.size / 100, ts.size / 100)

					-- local deubg_object = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
					-- deubg_object.name = "debug"
					-- deubg_object.transform:SetParent(boxCollider.transform)
					-- deubg_object.transform.localScale = CS.UnityEngine.Vector3(0.16, 0.16, 0.16)
					-- deubg_object.transform.position = boxCollider.bounds.center
					-- deubg_object:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).material = utils.DEBUG3D

					-- CS.UnityEngine.GameObject.Destroy(deubg_object:GetComponent(typeof(CS.UnityEngine.BoxCollider)))
				end
			end
			if gameMap[p][k] ~= 0 then -- 生成碰撞场景
				local ts = nil
				for i = 1, #dataBase.tileSets, 1 do
					if ruileJudge(p, k, gameMap, dataBase.tileSets[i].gird, dataBase.blocksTiles[dataBase.tileSets[i].tileType]) == true then
						ts = dataBase.tileSets[i]
						break
					end
				end
				local n = nil
				if ts == nil then
					ts = dataBase.tileSets[1]
					n = "no tile matched"
					print(n)
				else
					n = ts.name
				end

				local s = dataBase.blocksTiles[gameMap[p][k] + 1].tileSort
				if sortArray[s] == nil then
					local sortObject = CS.UnityEngine.GameObject("Sort " .. s)
					sortObject.transform.parent = unityobject.transform
					sortArray[s] = sortObject
				end

				if gameMap[p][k] == 4 and gameMap[p][k - 1] == 2 then -- 如果梯子上面一个格子是平台,在梯子上面延伸一个梯子
					local unityobject_child = CS.UnityEngine.GameObject("block" .. p .. "," .. k - 1 .. "[" .. gameMap[p][k] .. "]" .. n)
					unityobject_child.transform.parent = sortArray[s].transform
					unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, -(k - 1) * ts.size / 100, 0)
					local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
					sr.sprite = ts.sprite
					sr.material = castleDBInstance.palettes[1]
					sr.sortingOrder = -s

					unityobject_child.layer = gameMap[p][k]
					unityobject_child.name = unityobject_child.name .. "," .. 0

					local boxCollider2D = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
					boxCollider2D.size = CS.UnityEngine.Vector2(20 / 100, 20 / 100)

					for i = 1, #dataBase.tileSets, 1 do
						if ruileJudge(p, k + 1, gameMap, dataBase.tileSets[i].gird, dataBase.blocksTiles[dataBase.tileSets[i].tileType]) == true then
							ts = dataBase.tileSets[i]
							break
						end
					end
					if ts == nil then
						ts = dataBase.tileSets[1]
						n = "no tile matched"
						print(n)
					else
						n = ts.name
					end
				end

				if ts.walls ~= nil then

					if sortArray[10] == nil then
						local sortObject = CS.UnityEngine.GameObject("Sort " .. 10)
						sortObject.transform.parent = unityobject.transform
						-- sortObject.transform.localPosition = CS.UnityEngine.Vector3(0, 0, 10 / 100)
						sortArray[10] = sortObject
					end

					-- local unityobject_child2 = CS.UnityEngine.GameObject("wall" .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]" .. n)
					-- unityobject_child2.transform.parent = sortArray[10].transform
					-- -- unityobject_child2.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, -k * ts.size / 100, 0)
					-- local sr2 = unityobject_child2:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
					-- sr2.sprite = ts.walls
					-- sr2.material = castleDBInstance.palettes[1]
					-- sr2.sortingOrder = -10

					
					-- local spriteLowerBound = sr2.bounds.size.y * 0.5
					-- local floorHeight = -0.16
					-- local posX = p * ts.size / 100
					-- local posY = -k * ts.size / 100
					-- local posZ = (posY + floorHeight) * utils.Tan30
					-- unityobject_child2.transform.localPosition = CS.UnityEngine.Vector3(posX, posY, posZ * 2)

					local unityobject_child2 = tool2_castleDB.createMapObject(sortArray[10].transform, "wall", p, k, gameMap, n, ts, ts.walls, -10, "wall")

					unityobject_child2.layer = 0
					unityobject_child2.name = unityobject_child2.name .. "," .. 0

				end

				-- local unityobject_child = CS.UnityEngine.GameObject("block" .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]" .. n .. ",")
				-- unityobject_child.transform.parent = sortArray[s].transform
				-- -- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, -(k - 1) * ts.size / 100, 0)
				-- local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
				-- sr.sprite = ts.sprite
				-- sr.material = castleDBInstance.palettes[1]
				-- sr.sortingOrder = -s

				-- local spriteLowerBound = sr.bounds.size.y * 0.5
				-- local floorHeight = -0.16 - 0.08
				
				-- local g = k + 1
				-- while gameMap[p][g] ~= nil and gameMap[p][g] ~= 0 do
				-- 	floorHeight = floorHeight - 0.16
				-- 	g = g + 1
				-- end

				-- local posX = p * ts.size / 100
				-- local posY = -(k - 1) * ts.size / 100
				-- local posZ = (posY + floorHeight) * utils.Tan30
				-- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(posX, posY, posZ * 2)

				local unityobject_child = tool2_castleDB.createMapObject(sortArray[s].transform, "block", p, k, gameMap, n, ts, ts.sprite, -s, "block")

				unityobject_child.layer = gameMap[p][k]
				if gameMap[p][k] ~= 4 then -- 梯子加碰撞，但不碰
					local bit = nil
					if gameMap[p][k] == 2 then
						bit = 1
					else
						-- 这里要给不同朝向的地板放上不同的collider，0000四个bit位组合来表示朝向，放在名字最后
						bit = tool2_castleDB.judgeColliderType(gameMap, p, k)
					end
					unityobject_child.name = unityobject_child.name .. "," .. bit
					if bit > 0 then


						-- local body = CS.UnityEngine.GameObject("body[" .. n .. "]")
						-- body.transform.parent = unityobject_child.transform
						-- body.transform.localPosition = CS.UnityEngine.Vector3.zero
						-- body.transform.position = CS.UnityEngine.Vector3(body.transform.position.x, 0, 0)
						-- local boxCollider2D = body:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
						-- boxCollider2D.offset = CS.UnityEngine.Vector2(boxCollider2D.offset.x + 0.08, boxCollider2D.offset.y - ts.size / 100 - 0.08)
						-- boxCollider2D.size = CS.UnityEngine.Vector2(ts.size / 100, ts.size / 100)

						local boxCollider = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider))
						boxCollider.center = CS.UnityEngine.Vector3(boxCollider.center.x, boxCollider.center.y + ts.size / 100 * 10 / 2, boxCollider.center.z) --  - ts.size / 100
						boxCollider.size = CS.UnityEngine.Vector3(ts.size / 100, ts.size / 100 * 10, ts.size / 100)

						-- local deubg_object = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
						-- deubg_object.name = "debug"
						-- deubg_object.transform:SetParent(boxCollider.transform)
						-- deubg_object.transform.localScale = CS.UnityEngine.Vector3(0.16, 0.16 * 10, 0.16)
						-- deubg_object.transform.position = boxCollider.bounds.center
						-- deubg_object:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).material = utils.DEBUG3D

						-- CS.UnityEngine.GameObject.Destroy(deubg_object:GetComponent(typeof(CS.UnityEngine.BoxCollider)))

						-- boxCollider2D.usedByComposite = true
						-- local boxCollider2D2 = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
						-- boxCollider2D2.size = CS.UnityEngine.Vector2(ts.size / 100, ts.size / 100)
						-- boxCollider2D2.isTrigger = true

					end
				else
					local boxCollider2D = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
					boxCollider2D.size = CS.UnityEngine.Vector2(ts.size / 100, ts.size / 100)
					unityobject_child.name = unityobject_child.name .. "," .. 0
				end
			end
        end
    end


	-- p.transform.position = CS.UnityEngine.Vector3(x, y, 0)
	-- -- local compositeCollider2D = p:AddComponent(typeof(CS.UnityEngine.CompositeCollider2D))
	-- -- compositeCollider2D.geometryType = CS.UnityEngine.CompositeCollider2D.GeometryType.Polygons
	-- -- compositeCollider2D.isTrigger = true
	-- -- local rigidbody2D = p:GetComponent(typeof(CS.UnityEngine.Rigidbody2D))
	-- local rigidbody2D = p:AddComponent(typeof(CS.UnityEngine.Rigidbody2D))
	-- rigidbody2D.bodyType = CS.UnityEngine.RigidbodyType2D.Static

	local rigidbody = p:AddComponent(typeof(CS.UnityEngine.Rigidbody))
	-- rigidbody.useGravity = false
	rigidbody.isKinematic = true
	-- -- rigidbody.detectCollisions = false
	-- -- rigidbody.freezeRotation = true
	rigidbody.constraints = CS.UnityEngine.RigidbodyConstraints.FreezeAll

	local boxCollider_p = unityobject:AddComponent(typeof(CS.UnityEngine.BoxCollider))

	local b = 0
	b = b | 1
	b = b | 2
	b = b | 4
	b = b | 8
	b = b ~ 63
	boxCollider_p.name = boxCollider_p.name .. "[0]" .. "," .. b

	boxCollider_p.center = CS.UnityEngine.Vector3(0, 0.16 / 2, 0) --  - ts.size / 100
	boxCollider_p.size = CS.UnityEngine.Vector3(100, 0.16, 100)

	p.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)

end

function tool2_castleDB.createMapObject(parent, name, p, k, gameMap, n, ts, sprite, sort, flag)
	local unityobject_child = CS.UnityEngine.GameObject(name .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]" .. n)
	unityobject_child.transform.parent = parent
	-- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, -k * ts.size / 100, 0)

	if flag == "block" then
		unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, ts.size / 100, -k * ts.size / 100)
	elseif flag == "wall" then
		unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, 0, -k * ts.size / 100)
	elseif flag == "background" then
		unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, 0, -k * ts.size / 100)
	end



	local pic_offset_object = CS.UnityEngine.GameObject("pic_offset")
	pic_offset_object.transform:SetParent(unityobject_child.transform)
	pic_offset_object.transform.localPosition = CS.UnityEngine.Vector3(-ts.size / 100 / 2 , ts.size / 100, 0)

	local pic_object = CS.UnityEngine.GameObject("pic")
	pic_object.transform:SetParent(pic_offset_object.transform)
	local pos = pic_offset_object.transform.position
	pic_object.transform.position = CS.UnityEngine.Vector3(pos.x , pos.y + pos.z, pos.z)

	if flag == "background" then
		pic_object.transform.position = CS.UnityEngine.Vector3(pos.x , pos.y + pos.z, 10)
	end

	-- pic_object.transform.localPosition = CS.UnityEngine.Vector3.zero

	local sr2 = pic_object:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
	sr2.sprite = sprite
	sr2.material = castleDBInstance.palettes[1]
	sr2.sortingOrder = sort

	-- if flag == "block" or flag == "background" then
		-- local boxCollider2D = CS.UnityEngine.GameObject("boxCollider2D")
		-- boxCollider2D.transform:SetParent(unityobject_child.transform)
		-- boxCollider2D.transform.position = CS.UnityEngine.Vector3(pos.x , pos.y + pos.z, 0)
		-- local pic_BoxCollider = boxCollider2D:AddComponent(typeof(CS.UnityEngine.BoxCollider2D))
		-- pic_BoxCollider.center = CS.UnityEngine.Vector2(pic_BoxCollider.center.x + ts.size / 100 / 2, pic_BoxCollider.center.y + ts.size / 100 / 2)
		-- pic_BoxCollider.size = CS.UnityEngine.Vector2(ts.size / 100, ts.size / 100)
		-- pic_BoxCollider.isTrigger = true
	-- end

	-- 这个是在图的地方画个碰撞盒
	-- if flag == "block" then
	-- 	local boxCollider3D = CS.UnityEngine.GameObject("boxCollider3D")
	-- 	boxCollider3D.transform:SetParent(unityobject_child.transform)
	-- 	boxCollider3D.transform.position = CS.UnityEngine.Vector3(unityobject_child.transform.position.x , unityobject_child.transform.position.y + unityobject_child.transform.position.z, 0)
	-- 	boxCollider3D.layer = gameMap[p][k]
	-- 	local pic_BoxCollider = boxCollider3D:AddComponent(typeof(CS.UnityEngine.BoxCollider))
	-- 	pic_BoxCollider.center = CS.UnityEngine.Vector3(pic_BoxCollider.center.x, pic_BoxCollider.center.y + ts.size / 100 / 2, pic_BoxCollider.center.z)
	-- 	pic_BoxCollider.size = CS.UnityEngine.Vector3(ts.size / 100, ts.size / 100, ts.size / 100)
	-- 	-- pic_BoxCollider.isTrigger = true
	-- end

	
	-- local spriteLowerBound = sr2.bounds.size.y * 0.5
	-- local floorHeight = -0.16

	-- local posX, posY = nil
	-- if flag then
	-- 	local g = k + 1
	-- 	while gameMap[p][g] ~= nil and gameMap[p][g] ~= 0 do
	-- 		floorHeight = floorHeight - 0.16
	-- 		g = g + 1
	-- 	end

	-- 	posX = p * ts.size / 100
	-- 	posY = -(k - 1) * ts.size / 100
	-- else
	-- 	posX = p * ts.size / 100
	-- 	posY = -k * ts.size / 100
	-- end

	-- local posZ = (posY + floorHeight) * utils.Tan30
	-- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(posX, posY, posZ * 2)

	return unityobject_child
end

-- 0没有collider，0001=1上，0011=3上下，0111=7上下左，1111=上下左右，0101=5上下，1010=10左右, 010000=16前，100000=32后
function tool2_castleDB.judgeColliderType(map, p, k)
	local b = 0

	if map[p + 0][k - 1] == 1 then
		b = b | 1
	end
	if map[p + 0][k + 1] == 1 then
		b = b | 2
	end
	if map[p - 1] ~= nil and map[p - 1][k + 0] == 1 then
		b = b | 4
	end
	if map[p + 1] ~= nil and map[p + 1][k + 0] == 1 then
		b = b | 8
	end

	b = b | 16
	b = b | 32

	-- b = b ~ 15 -- 取反
	b = b ~ 63
	return b
end

function tool2_castleDB.judgeColliderType3D(map, p, k)
	local b = 0

	-- if map[p + 0][k - 1] == 0 then
	-- 	b = b | 1
	-- end
	-- if map[p + 0][k + 1] == 0 then
	-- 	b = b | 2
	-- end
	-- if map[p - 1] ~= nil and map[p - 1][k + 0] == 0 then
	-- 	b = b | 4
	-- end
	-- if map[p + 1] ~= nil and map[p + 1][k + 0] == 0 then
	-- 	b = b | 8
	-- end
	b = b | 1
	b = b | 2
	b = b | 4
	b = b | 8

	-- b = b | 16
	-- b = b | 32

	b = b ~ 63
	return b
end
function tool2_castleDB.getColliderTypeWithString(str)
	local r = 0
    for i = #str, 1, -1 do
		if tonumber(string.sub(str, i, i)) ~= 0 then
			local p = 1 << (#str - i)
			r = r | p
		end
	end
	return r
end

-- 渲染gameMap3D
function tool2_castleDB.drawMap__(gameMap, x, y, scale)
	-- 渲染gameMap
    local p = CS.UnityEngine.GameObject("test")
    local unityobject = CS.UnityEngine.GameObject("blocks")
    unityobject.transform.parent = p.transform

	local sortArray = {}
    for p, a in pairs(gameMap) do
        for k, b in pairs(gameMap[p]) do
			if gameMap[p][k] ~= 0 then
				local ts = nil
				for i = 1, #dataBase.tileSets, 1 do
					if ruileJudge(p, k, gameMap, dataBase.tileSets[i].gird, dataBase.blocksTiles[dataBase.tileSets[i].tileType]) == true then
						ts = dataBase.tileSets[i]
						break
					end
				end
				local n = nil
				if ts == nil then
					ts = dataBase.tileSets[1]
					n = "no tile matched"
				else
					n = ts.name
				end

				local s = dataBase.blocksTiles[gameMap[p][k] + 1].tileSort
				if sortArray[s] == nil then
					local sortObject = CS.UnityEngine.GameObject("Sort " .. s)
					sortObject.transform.parent = unityobject.transform
					sortArray[s] = sortObject
				end

				local unityobject_child = CS.UnityEngine.GameObject("block" .. p .. "," .. k .. "[" .. gameMap[p][k] .. "]" .. n)
				unityobject_child.transform.parent = sortArray[s].transform
				unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(p * ts.size / 100, -k * ts.size / 100, 0)
				local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
				sr.sprite = ts.sprite
				sr.sortingOrder = -s

				local boxCollider3D = unityobject_child:AddComponent(typeof(CS.UnityEngine.BoxCollider))
				boxCollider3D.center = CS.UnityEngine.Vector3(0.1, -0.1, -s)
				boxCollider3D.size = CS.UnityEngine.Vector3(20 / 100, 20 / 100, 1)
			end
        end
    end

	p.transform.position = CS.UnityEngine.Vector3(x, y, 0)


	local rigidbody3D = p:AddComponent(typeof(CS.UnityEngine.Rigidbody))
	rigidbody3D.isKinematic = true
	p.transform.localScale = CS.UnityEngine.Vector3(scale, scale, 1)
end

function comp(a, bArray)
    for i, j in ipairs(bArray) do
		if a == j then
			return true
		end
	end
	return false
end

-- tile逻辑判断，写的很烂，以后或许会优化
function ruileJudge(p, k, map, gird, t)
	if map[p][k] ~= t then
		return false
	end
	for i = -1, 1, 1 do
		for j = -1, 1, 1 do
			if map[p + i] == nil then
				if gird[i][j] ~= nil and gird[i][j] ~= false then
					return false
				end
			else
				if map[p + i][k + j] == nil then
					if gird[i][j] ~= nil and gird[i][j] ~= false then
						return false
					end
				end
			end


			if gird[i] ~= nil and map[p + i] ~= nil then
				if gird[i][j] ~= nil and map[p + i][k + j] ~= nil then

					if map[p + i][k + j] == t and gird[i][j] == false then
						return false
					end
					if gird[i][j] ~= nil and gird[i][j] ~= false and comp(map[p + i][k + j], gird[i][j]) == false then
						return false
					end

				end
			end
		end
	end
	return true
end

-- 生成房间
function crateRoom(firstroom, num)
	local rooms = {}
	table.insert(rooms, firstroom)
	local c = 1
	-- local r = firstroom
	for i = 1, num, 1 do
		local x = nil
		local y = nil
		local r2 = nil
		local p = CS.Tools.Instance:RandomRangeInt(1, #rooms + 1)
		local l = CS.Tools.Instance:RandomRangeInt(1, #rooms[p].linkers + 1)
		local l2 = CS.Tools.Instance:RandomRangeInt(1, #dataBase.levels + 1)
		-- x, y, r2 = r:link(l, dataBase.levels[l2], gameMap, "test")
		x, y, r2 = rooms[p]:link(l, dataBase.levels[l2], gameMap, dataBase.levels[l2].name)
		while (x == nil or y == nil or r2 == nil) and c <= 100 do -- 尝试100次
			p = CS.Tools.Instance:RandomRangeInt(1, #rooms + 1)
			l = CS.Tools.Instance:RandomRangeInt(1, #rooms[p].linkers + 1)
			l2 = CS.Tools.Instance:RandomRangeInt(1, #dataBase.levels + 1)
			-- x, y, r2 = r:link(l, dataBase.levels[l2], gameMap, "test")
			x, y, r2 = rooms[p]:link(l, dataBase.levels[l2], gameMap, dataBase.levels[l2].name)
			c = c + 1
		end
		if r2 ~= nil then
			print("No." .. i)
			table.insert(rooms, r2)
			-- r = r2
		end
		c = 1
-- 		if c == 101 then
-- 			print("f")
-- 		end
	end
	return rooms
end

-- 描边地图
function outlineMap(map)
	local outline = {}

    for p, a in pairs(map) do
        for k, b in pairs(map[p]) do
			for i = -1, 1, 1 do
				for j = -1, 1, 1 do
					if map[p + i] == nil or map[p + i][k + j] == nil then
						table.insert(outline, {x = p + i, y = k + j})
					end
				end
			end
		end
	end

	for i = 1, #outline, 1 do
		if map[outline[i].x] == nil then
			map[outline[i].x] = {}
		end
		map[outline[i].x][outline[i].y] = 1
	end
end

-- 填充地图
function fillMap(map)
	local cArray = {}
	for p, a in pairs(map) do
        for k, b in pairs(map[p]) do
			table.insert(cArray, {x = p, y = k})
		end
	end

	local w2, h2 = table_maxn(cArray)
	local w1, h1 = table_minn(cArray)

	local width = w2 - w1 + 1
	local height = -(h1 - h2) + 1

    for i = w1, w1 + width - 1, 1 do
        for j = h1, h1 + height - 1, 1 do
			if map[i] == nil then
				map[i] = {}
			end
			if map[i][j] == nil then
				map[i][j] = 1
			end
		end
	end
end

return tool2_castleDB
