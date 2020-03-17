-- Tencent is pleased to support the open source community by making xLua available.
-- Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
-- Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
-- http://opensource.org/licenses/MIT
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

local utils = require "LUtils"

--~ -- 构造体linker
--~ local linker = {kind = 0, pos = {}}
-- 类的声明，这里声明了类名还有属性，并且给出了属性的初始值
tileRoom = {name = nil, x = 0, y = 0, width = 0, height = 0, linkers = nil, map = nil}
-- 设置元表的索引，想模拟类的话，这步操作很关键
tileRoom.__index = tileRoom
-- 构造方法new
function tileRoom:new(x, y, level, map, n)
    local self = {}  --初始化self，如果没有这句，那么类所建立的对象如果有一个改变，其他对象都会改变
    setmetatable(self, tileRoom)  --将self的元表设定为Class
    self.x = x
    self.y = y
    self.width = level.width
    self.height = level.height
    self.name = n
	self.linkers = {}
	self.map = {}

	-- 把room的信息写入map中
    for i = x, x + level.width - 1, 1 do
        if map[i] == nil then
            map[i] = {}
        end
		self.map[i] = {}
        for j = y, y + level.height - 1, 1 do
            local num = ((i - x) + (j - y) * level.width) + 1
			-- 如果要生成的房间的位置上没有或者是墙壁，才生成房间
			if map[i][j] == nil or map[i][j] == 0  then
				map[i][j] = level.blocks[num]
			end
			self.map[i][j] = level.blocks[num]
        end
    end

	-- 深拷贝level中的连接点，把连接点坐标加上房间坐标得到实际坐标
	if #level.connectors > 0 then
		print(#level.connectors)
		self.linkers = utils.deep_copy(level.connectors)
		for i = 1, #self.linkers, 1 do
			for j = 1, #self.linkers[i].position, 1 do
				self.linkers[i].position[j].x = self.linkers[i].position[j].x + self.x
				self.linkers[i].position[j].y = self.linkers[i].position[j].y + self.y
			end
			for j = 1, #self.linkers[i].dPosition, 1 do
				self.linkers[i].dPosition[j].x = self.linkers[i].dPosition[j].x + self.x
				self.linkers[i].dPosition[j].y = self.linkers[i].dPosition[j].y + self.y
			end
		end
	end
--    print("new", self.linkers, level.connectors)
    return self  --返回自身
end

-- 连接房间（哪个连接点，房间预设，大地图）
function tileRoom:link(linkIndex, level, map, n)
	if #self.linkers == 0 then
		return nil, nil, nil
	end
	-- 自己room的连接点暂时选择为第1个
    local myLinker = self.linkers[linkIndex]
    local ml_x = myLinker.position[1].x
    local ml_y = myLinker.position[1].y
	-- 深拷贝level的连接点放入临时
    local temp = utils.deep_copy(level.connectors)
    local num = CS.Tools.Instance:RandomRangeInt(1, #temp + 1)
    local linker = temp[num]
	local x2 = nil
	local y2 = nil
	-- print("temp: " .. #temp)

	-- 如果临时中有连接点，随机拿一个来judge
    while #temp > 0 do
		-- 如果连接点不满足以下条件，则判断为可以生成连接，否则remove这个连接点
		if myLinker.kind ~= linker.kind or myLinker.isConnected ~= linker.isConnected then -- or myLinker.width ~= linker.width or myLinker.height ~= linker.height -- 宽度，高度暂时不考虑
			table.remove(temp, num)
			num = CS.Tools.Instance:RandomRangeInt(1, #temp + 1)
			linker = temp[num]
		else
			-- 如果判断为可以生成连接，则进入judge循环

			-- 深拷贝level
			local tempLevel = utils.deep_copy(level)
			local ip = {}
			for a = 1, #tempLevel.connectors, 1 do
				for b = 1, #tempLevel.connectors[a].position, 1 do
					local x = tempLevel.connectors[a].position[b].x
					local y = tempLevel.connectors[a].position[b].y
					-- 将当前以外的连接处全部封上，当前链接的点放入数组
					if tempLevel.connectors[a].index ~= linker.index then
						tempLevel.blocks[(x + y * tempLevel.width) + 1] = 1
					else
						table.insert(ip, {cx = x, cy = y})
					end
				end
			end

			local f = false
			local n = CS.Tools.Instance:RandomRangeInt(1, #linker.position + 1)
			while #linker.position > 0 do
				x2, y2 = self:judge(n, linker, ml_x, ml_y, tempLevel, map, ip)
				-- judge结果为没有坐标，则remove这个连接点的其中一个坐标点，否则break
				if x2 == nil or y2 == nil then
					table.remove(linker.position, n)
					n = CS.Tools.Instance:RandomRangeInt(1, #linker.position + 1)
				else
					f = true
					break
				end
			end
			-- 如果找到了可以创建房间的点，则break，否则remove这个连接点
			if f == false then
				table.remove(temp, num)
				num = CS.Tools.Instance:RandomRangeInt(1, #temp + 1)
				linker = temp[num]
			else
				break
			end

		end
    end
--    print("new", temp, level.connectors)
    if #temp <= 0 then
        return nil, nil, nil
    end

	-- 创建房间
	local r = self:new(x2, y2, level, map, n)
	-- print("created room name: ".. n .. ", x2: " .. x2 .. ", y2: " .. y2)

	-- 连接处设置为已连接
    myLinker.isConnected = true
	r.linkers[linker.index].isConnected = true

    return x2, y2, r
end

-- 判定房间是否能被生成，返回房间左上角的坐标
function tileRoom:judge(n, linker, ml_x, ml_y, level, map, ignorePoint)
    local l_x = linker.position[n].x
    local l_y = linker.position[n].y
    -- print("type " .. myLinker.kind .. "," .. linker.kind)
    local x2 = ml_x - l_x
    local y2 = ml_y - l_y
	-- print(ml_x .. "," .. ml_y .. " - " .. l_x .. "," .. l_y)
    -- print(x2, y2)

	local count = 0
    for i = x2, x2 + level.width - 1, 1 do
        for j = y2, y2 + level.height - 1, 1 do
            if map[i] ~= nil then
                if map[i][j] ~= nil then
					-- 房间和map有不同的方块的话就判断为失败

					if map[i][j] ~= level.blocks[((i - x2) + (j - y2) * level.width) + 1] then
						-- print(i, j, map[i][j], level.blocks[((i - x2) + (j - y2) * level.width) + 1], i - x2, j - y2)
						-- print("gen map failed0")

						-- 当前连接处的点不做判断，直接+1
						local b = false
						for f = 1, #ignorePoint, 1 do
							if i - x2 == ignorePoint[f].cx and j - y2 == ignorePoint[f].cy then
								b = true
								break
							end
						end
						if b == false then
							return nil, nil
						else
							count = count + 1
						end
					else
						count = count + 1
					end
                end
            end
        end
    end
	-- 如果房间完全重叠则判断为失败
	if count == #level.blocks then
		-- print("gen map failed1")
		return nil, nil
	end
	-- print("gen map successful")
	return x2, y2
end

-- 封闭链接点
function tileRoom:close(map)
	-- 如果连接点没有被连接，则设置为1（墙壁）
    for i = 1, #self.linkers, 1 do
        if self.linkers[i].isConnected == false then
            for j = 1, #self.linkers[i].position, 1 do
				local x = self.linkers[i].position[j].x
				local y = self.linkers[i].position[j].y
				map[x][y] = 1
				self.map[x][y] = 1
            end
            for j = 1, #self.linkers[i].dPosition, 1 do
				local x = self.linkers[i].dPosition[j].x
				local y = self.linkers[i].dPosition[j].y
				map[x][y] = 0
				self.map[x][y] = 0
            end
        end
    end
end
