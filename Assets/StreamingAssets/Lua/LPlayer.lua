utils = require "LUtils"
-- local cs_coroutine = (require 'cs_coroutine')


LSystem = {preObject = nil, object = nil, keys = nil, keysDownCount = nil, commands = nil, kaiwaButton = nil, commands_sort = nil, dialogueBox = nil, testnum = nil}
LSystem.__index = LSystem
function LSystem:new(o)
	local self = {}
	setmetatable(self, LSystem)
	

	self.preObject = nil
	self.object = o
	self.UIObject = nil


	self.keys = {}
	self.keysDownCount = 0


	-- 创建按键映射
	self:createKey("U", {CS.UnityEngine.KeyCode.W}) -- 上
	self:createKey("D", {CS.UnityEngine.KeyCode.S}) -- 下
	self:createKey("B", {CS.UnityEngine.KeyCode.A}) -- 左
	self:createKey("F", {CS.UnityEngine.KeyCode.D}) -- 右

	self:createKey("UB", {CS.UnityEngine.KeyCode.W, CS.UnityEngine.KeyCode.A}) -- 左上
	self:createKey("UF", {CS.UnityEngine.KeyCode.W, CS.UnityEngine.KeyCode.D}) -- 右上
	self:createKey("DB", {CS.UnityEngine.KeyCode.S, CS.UnityEngine.KeyCode.A}) -- 左下
	self:createKey("DF", {CS.UnityEngine.KeyCode.S, CS.UnityEngine.KeyCode.D}) -- 右下

	self:createKey("e", {CS.UnityEngine.KeyCode.E}) -- 互动键
	self:createKey("q", {CS.UnityEngine.KeyCode.Q}) -- test

	-- 定义冲突键
	self.keys["U"].antiKey = self.keys["D"] -- 上下对冲
	self.keys["D"].antiKey = self.keys["U"] -- 上下对冲
	self.keys["B"].antiKey = self.keys["F"] -- 左右对冲
	self.keys["F"].antiKey = self.keys["B"] -- 左右对冲

	self.keys["UB"].antiKey = self.keys["DF"] -- 左上右下对冲
	self.keys["UF"].antiKey = self.keys["DB"] -- 右上左下对冲
	self.keys["DB"].antiKey = self.keys["UF"] -- 左上右下对冲
	self.keys["DF"].antiKey = self.keys["UB"] -- 右上左下对冲

	-- 定义反向键
	self.keys["B"].reverseKey = self.keys["F"] -- 左右互反
	self.keys["F"].reverseKey = self.keys["B"] -- 左右互反

	self.keys["UB"].reverseKey = self.keys["UF"] -- 左上右上互反
	self.keys["UF"].reverseKey = self.keys["UB"] -- 左上右上互反
	self.keys["DB"].reverseKey = self.keys["DF"] -- 左下右下互反
	self.keys["DF"].reverseKey = self.keys["DB"] -- 左下右下互反
	
	self.commands = {}
	self.commands_sort = {}

	self.kaiwaButton = nil
	self.dialogueBox = nil

	self.testnum = 0

	return self
end

-- 切换角色
function LSystem:ChangeCharacter(obj)
	self.preObject = self.object
	self.object = obj
	self:createCommand(self.object.database:getLines("commands"))

	for i, v in pairs(self.commands) do
	-- if v ~= nil then
		table.insert(self.commands_sort, {key = v.level, value = v})
	-- end
	end

	table.sort(self.commands_sort, function(a, b) -- level低的招式放后面
		if a.key ~= nil and b.key ~= nil then
			return a.key > b.key
		end
	end)
end

-- 创建按键映射
function LSystem:createKey(id, k)
	local key = {}
	key.id = id
	key.keys = {}
	for i, v in ipairs(k) do
		table.insert(key.keys, v)
	end
	key.antiKey = nil
	key.reverseKey = nil
	key.count = 0
	key.state = 0

	self.keys[id] = key
end

-- 检测按键状态
function LSystem:input()
	for i, v in pairs(self.keys) do
		if self:isKeyDown(v.keys) then
			if v.id ~= "a" and v.id ~= "b" and v.id ~= "c" and v.id ~= "j" and v.id ~= "e" then
				for i2, v2 in pairs(self.keys) do -- 如果有一个键按下，其他键都算放开
					if v2.id ~= v.id and v2.id ~= "a" and v2.id ~= "b" and v2.id ~= "c" and v2.id ~= "j" and v2.id ~= "e" then
						if v2.count == 0 then -- 如果之前没按，现在就是没按
							v2.state = 0
						elseif v2.count == 1 then -- 如果之前刚按下，现在就是刚放开
							v2.state = 3
						elseif v.count > 1 then -- 如果之前是按住，现在就是刚放开
							v2.state = 3
						end

						v2.count = 0
					end
				end
			end

			if v.count == 0 then -- 如果之前没按，现在就是刚按下
				v.state = 1
			elseif v.count == 1 then -- 如果之前刚按下，现在就是按住
				v.state = 2
			elseif v.count > 1 then -- 如果之前是按住，现在就是按住
				v.state = 2
			end

			v.count = v.count + 1
			if v.antiKey ~= nil then
				if self:isKey(v.antiKey.keys) then
					v.count = 0
					v.antiKey.count = 0

					if v.count == 0 then -- 如果之前没按，现在就是没按
						v.state = 0
					elseif v.count == 1 then -- 如果之前刚按下，现在就是刚放开
						v.state = 3
					elseif v.count > 1 then -- 如果之前是按住，现在就是刚放开
						v.state = 3
					end
					if v.antiKey.count == 0 then -- 如果之前没按，现在就是没按
						v.antiKey.state = 0
					elseif v.antiKey.count == 1 then -- 如果之前刚按下，现在就是刚放开
						v.antiKey.state = 3
					elseif v.antiKey.count > 1 then -- 如果之前是按住，现在就是刚放开
						v.antiKey.state = 3
					end
				end
			end
			
		elseif self:isKey(v.keys) then
			if v.count == 0 then -- 如果之前没按，现在就是刚按下
				v.state = 1
			elseif v.count == 1 then -- 如果之前刚按下，现在就是按住
				v.state = 2
			elseif v.count > 1 then -- 如果之前是按住，现在就是按住
				v.state = 2
			end

			v.count = v.count + 1
			if v.antiKey ~= nil then
				if self:isKey(v.antiKey.keys) then
					v.count = 0
					v.antiKey.count = 0

					if v.count == 0 then -- 如果之前没按，现在就是没按
						v.state = 0
					elseif v.count == 1 then -- 如果之前刚按下，现在就是刚放开
						v.state = 3
					elseif v.count > 1 then -- 如果之前是按住，现在就是刚放开
						v.state = 3
					end
					if v.antiKey.count == 0 then -- 如果之前没按，现在就是没按
						v.antiKey.state = 0
					elseif v.antiKey.count == 1 then -- 如果之前刚按下，现在就是刚放开
						v.antiKey.state = 3
					elseif v.antiKey.count > 1 then -- 如果之前是按住，现在就是刚放开
						v.antiKey.state = 3
					end
				end
			end
		elseif self:isKeyUp(v.keys) then
			if v.id ~= "a" and v.id ~= "b" and v.id ~= "c" and v.id ~= "j" and v.id ~= "e" then
				for i2, v2 in pairs(self.keys) do -- 如果有一个键放开，其他键都算放开
					if v2.id ~= v.id and v2.id ~= "a" and v2.id ~= "b" and v2.id ~= "c" and v2.id ~= "j" and v2.id ~= "e" then
						if v2.count == 0 then -- 如果之前没按，现在就是没按
							v2.state = 0
						elseif v2.count == 1 then -- 如果之前刚按下，现在就是刚放开
							v2.state = 3
						elseif v.count > 1 then -- 如果之前是按住，现在就是刚放开
							v2.state = 3
						end

						v2.count = 0
					end
				end
			end

			if v.count == 0 then -- 如果之前没按，现在就是没按
				v.state = 0
			elseif v.count == 1 then -- 如果之前刚按下，现在就是刚放开
				v.state = 3
			elseif v.count > 1 then -- 如果之前是按住，现在就是刚放开
				v.state = 3
			end

			v.count = 0
		else
			v.state = 0
			v.count = 0
		end
	end
end

-- 当按键刚按下
function LSystem:isKeyDown(keys)
	local c = 0
	for i = 1, #keys, 1 do
		if CS.UnityEngine.Input.GetKeyDown(keys[i]) then
			c = c + 1
		end
	end
	if c == #keys then
		return true
	end
	return false
end

-- 当按键按住
function LSystem:isKey(keys)
	local c = 0
	for i = 1, #keys, 1 do
		if CS.UnityEngine.Input.GetKey(keys[i]) then
		-- if CS.UnityEngine.Event.current.keyCode == keys[i] and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
			c = c + 1
		end
	end
	if c == #keys then
		return true
	end
	return false
end

-- 当按键弹起
function LSystem:isKeyUp(keys)
	local c = 0
	for i = 1, #keys, 1 do
		if CS.UnityEngine.Input.GetKeyUp(keys[i]) then
		-- if CS.UnityEngine.Event.current.keyCode == keys[i] and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyUp then
		c = c + 1
		end
	end
	if c == #keys then
		return true
	end
	return false
end

-- 有任何键按下？
function LSystem:isAnyKeyDown(key)
	for i, v in pairs(self.keys) do
		if v ~= key then
			if v.count > 0 then
				return true
			end
		else
			print("LSystem:isAnyKeyDown   wa!!!!!!!!!!!!!!!!!!!")
		end
	end
	return false
end

-- debug显示按键状态
function LSystem:displayKeys()
	for i, v in pairs(self.keys) do
		CS.UnityEngine.GUILayout.Label(v.id .. ": " .. v.count .. "," .. v.state)
	end
end


-- 互动系统测试中
function LSystem:systemInput(obj)

	-- if dialogueBox == nil then
		if obj.isElse & (1 << 16) == 1 << 16 then
			if kaiwaButton == nil then
				kaiwaButton = utils.createObject(nil, 999, "Interact_display", 0, 0, 0, 0, 0, 5)
			end
			-- if self.keys["e"].state == 1 then -- 刚按下

				local b = false
				for i, v in pairs(obj.elseArray) do
					if i == "16" then
						for i2, v2 in pairs(v) do
							local go = v2.attachedRigidbody.gameObject
							local obj = utils.getObject(go:GetInstanceID())
							if obj.kind == 0 then
								-- dialogueBox = utils.createObject(nil, 999, "dialogueBox_test", 0, 0, 0, 0, 0, 5)
								-- dialogueBox.vars["dt"] = obj.database:getLines("story")[1].text[self.testnum].dialogue

								-- dialogueBox = utils.createObject(nil, 999, "optionBox_test", 0, 0, 0, 0, 0, 5)

								-- dialogueBox = utils.createObject(nil, 999, "trade_test222", 0, 0, 0, 0, 0, 5)
		
								-- if kaiwaButton ~= nil then
								-- 	utils.destroyObject(kaiwaButton.gameObject:GetInstanceID())
								-- 	kaiwaButton = nil
								-- end

								-- self.object = kaiwaButton

								-- self:createCommand(self.object.database:getLines("commands"))

								-- for i, v in pairs(self.commands) do
								-- 	-- if v ~= nil then
								-- 		table.insert(self.commands_sort, {key = v.level, value = v})
								-- 	-- end
								-- end
							
								-- table.sort(self.commands_sort, function(a, b) -- level低的招式放后面
								-- 	if a.key ~= nil and b.key ~= nil then
								-- 		return a.key > b.key
								-- 	end
								-- end)

								-- self:ChangeCharacter(dialogueBox)

								-- utils.PLAYER.object["aite"] = obj
								-- print(obj.kind)

								-- print(utils.PLAYER.object["aite"]["story"][1]["text"][1]["dialogue"])

								b = true
								break
							end
						end
					end
					if b then
						break
					end
				end
			-- end
		else
			if kaiwaButton ~= nil then
				utils.destroyObject(kaiwaButton.gameObject:GetInstanceID())
				kaiwaButton = nil
			end
			utils.PLAYER.object["aite"] = nil
		end
	-- else
		-- if obj.isElse & (1 << 16) == 1 << 16 then
			-- if self.keys["D"].state == 1 then -- 刚按下
			-- 	dialogueBox.vars["choose_test2"] = dialogueBox.vars["choose_test2"] + 1
			-- 	if dialogueBox.vars["choose_test2"] > 3 then
			-- 		dialogueBox.vars["choose_test2"] = 1
			-- 	end
			-- 	-- dialogueBox.vars["choose_test2"] = self.testnum -- dialogueBox.vars["parent"].database:getLines("story")[1].text[self.testnum].dialogue
			-- elseif self.keys["U"].state == 1 then
			-- 	dialogueBox.vars["choose_test2"] = dialogueBox.vars["choose_test2"] - 1
			-- 	if dialogueBox.vars["choose_test2"] < 1 then
			-- 		dialogueBox.vars["choose_test2"] = 3
			-- 	end
			-- 	-- dialogueBox.vars["choose_test2"] = self.testnum -- dialogueBox.vars["parent"].database:getLines("story")[1].text[self.testnum].dialogue
			-- end


			-- if self.keys["e"].state == 1 then -- 刚按下
				-- utils.destroyObject(dialogueBox.gameObject:GetInstanceID())
				-- dialogueBox = nil
				-- self.object.vars["interact"] = false

				-- self:ChangeCharacter(self.preObject)
			-- end
		-- else
		-- 	utils.destroyObject(dialogueBox.gameObject:GetInstanceID())
		-- 	dialogueBox = nil
		-- 	self.object.vars["ttt"]["aite"] = nil
		-- end
	-- end
end

LUITest = {UI = nil, eventManager = nil}
LUITest.__index = LUITest
function LUITest:new(x, y, w, h, b)
	local self = {}
    setmetatable(self, LUITest)
	self.eventManager = {}
	
	self.UI = LUIButton:new(nil, x, y, w, h, nil, b)
	self.UI:setOnClickFunction(function()
		self:InvokeEvent("onPush", nil)
	end)

    return self
end

-- 添加事件
function LUITest:addEvent(eventName, action)
	if not self.eventManager[eventName] then
		self.eventManager[eventName] = Delegate()
	end
	self.eventManager[eventName].add(action)
end

-- 移除事件
function LUITest:removeEvent(eventName, action)
	self.eventManager[eventName].delete(action)
end

-- 移除所有事件
function LUITest:removeAllEvent()
	self.eventManager = {}
end

-- 触发事件
function LUITest:InvokeEvent(eventName, ...)
	if self.eventManager[eventName] then
		self.eventManager[eventName].invoke(...)
	end
end

LPlayer = {camera = nil}
setmetatable(LPlayer, LSystem)
LPlayer.__index = LPlayer
function LPlayer:new(o, c)
	local self = {}
	self = LSystem:new(o)
	setmetatable(self, LPlayer)

	self.camera = c


	self:createKey("a", {CS.UnityEngine.KeyCode.Mouse0}) -- 攻击键
	self:createKey("b", {CS.UnityEngine.KeyCode.Mouse1}) -- 攻击键
	self:createKey("c", {CS.UnityEngine.KeyCode.Mouse2}) -- 攻击键

	self:createKey("j", {CS.UnityEngine.KeyCode.Space}) -- 跳跃键

	self:createCommand(self.object.database:getLines("commands"))

	for i, v in pairs(self.commands) do
		-- if v ~= nil then
			table.insert(self.commands_sort, {key = v.level, value = v})
		-- end
	end

	table.sort(self.commands_sort, function(a, b) -- level低的招式放后面
		if a.key ~= nil and b.key ~= nil then
			return a.key > b.key
		end
	end)

	-- local uuu = LUITest:new(100, -100, 200, 100, "button")
	-- uuu:addEvent("onPush", function(value)
	-- 	-- CS.UnityEngine.GameObject.Destroy(uuu.UI.gameObject)
	-- 	uuu.UI.gameObject:SetActive(false)
	-- 	for i = 1, #self.object["story"], 1 do
	-- 		local fff = LUITest:new(50, -50 + (i - 1) * -12, 200, 12, self.object["story"][i].dialogue)
	-- 	end
	-- end)

	-- local uuu2 = LUITest:new(300, -100, 200, 100, "button")
	-- uuu2:addEvent("onPush", function(value)
	-- 	uuu.UI.gameObject:SetActive(true)
	-- end)

	-- self.dialogueBox = utils.createObject(nil, 999, "newTestTestTest", 0, 0, 0, 0, 0, 5)


    return self
end

-- 摄像机跟随主角，比较简陋
function LPlayer:followCharacter()
	-- if self.object.kind == 0 then
		local charPos = self.object.physics_object.transform.position
		self.camera.transform.position = CS.UnityEngine.Vector3(charPos.x, charPos.y + charPos.z, self.camera.transform.position.z)
	-- end
end

-- 创建招式
function LSystem:createCommand(c)
	for i, v in ipairs(c) do
		if v.active then
			local command = {}
			command.name = v.name
			command.level = v.level
			command.cmds = self:createCMD(v.command)
			command.time = v.time
			command.action = v.action
			command.frame = v.frame
			command.count = 1
			command.timeCount = 0
			command.direction = 0
			command.mp = v.mp
			command.UIActive = nil -- test

			self.commands[command.name] = command
		end
	end
end

function LSystem:resetCommands()
	for i, vvv in pairs(self.commands_sort) do -- command
		local v = vvv.value
		v.UIActive = nil
	end
end

-- 创建招式出招方法
function LSystem:createCMD(c_str)
	local cmds = {}
	local c = utils.split(c_str, ",")
	for i, v in ipairs(c) do
		local cmd = {}
		cmd.kind = 0
		cmd.keys = {}
		local found = false
		-- 看看是什么按键
		local k = string.match(v, "(%a+)")
		for i2, v2 in pairs(self.keys) do
			if utils.isStringAContainB(k, v2.id) then
				table.insert(cmd.keys, self.keys[v2.id])
				found = true
				break
			end
		end
		-- 如果没找到，用+号分开看看
		if found == false then
			local str = utils.split(k, "+")
			for i = 1, #str, 1 do
				if self.keys[str[i]] ~= nil then
					table.insert(cmds.keys, self.keys[str[i]])
				end
			end
		end
		-- 特殊功能加上
		if string.find(v, "/") then -- 按住
			cmd.kind = 1
		elseif string.find(v, "~") then -- 放开
			cmd.kind = 2
		elseif string.find(v, ">") then -- 上一次按键和这一次按键之中不能掺杂其他的按键
			cmd.kind = 3
		end
		table.insert(cmds, cmd)
	end
	return cmds
end

-- debug显示command状态
function LSystem:displayCommands()
	for i, vvv in pairs(self.commands_sort) do
		local v = vvv.value
		CS.UnityEngine.GUILayout.Label(v.name .. ": " .. v.count .. " " .. tostring(v.UIActive))
	end
end

-- 判断这个阶段的招式中的按键是否在上个阶段已经包含
function LSystem:getIterateKeys(keysA, keysB)
	local iterate = {}
	for i, v in ipairs(keysA) do -- .keys
		for i2, v2 in ipairs(keysB) do
			-- print(v.id, v2.id)
			if v == v2 then
				-- print(v.id, v2.id)
				table.insert(iterate, v)
			end
		end
	end
	return iterate
end

-- 判断出招
function LSystem:judgeCommand()
	for i, vvv in pairs(self.commands_sort) do -- command
		local v = vvv.value
		if v.count <= #v.cmds then
			local v2 = v.cmds[v.count]

	--~ 		print(v.name .. v.count)

			local success = false
			local rev = false
			local rok = 0
			local ok = 0
			for i3, v3 in ipairs(v2.keys) do -- keys
				local myKey = nil
				local myReverseKey = nil
				if v.direction == -1 and v3.reverseKey ~= nil then
					myKey = v3.reverseKey
					myReverseKey = v3
				else
					myKey = v3
					myReverseKey = v3.reverseKey
				end
 				-- print(v2.kind)
				if v3.reverseKey ~= nil then
					rev = true
				end
				if v2.kind == 0 then
					-- print(myKey.state)
					if myKey.state == 1 then -- 刚按下
						ok = ok + 1
					else
						if myReverseKey ~= nil and v.direction == 0 then
							if myReverseKey.state == 1 then -- 反向刚按下
								ok = ok + 1
								rok = rok - 1
							end
						end
					end
				elseif v2.kind == 1 then
					if myKey.state == 2 then -- 按住
						ok = ok + 1
					else
						if myReverseKey ~= nil and v.direction == 0 then
							if myReverseKey.state == 2 then -- 反向按住
								ok = ok + 1
								rok = rok - 1
							end
						end
					end
				elseif v2.kind == 2 then
					-- v.direction = self.object.direction.x
					-- if self.object.direction.x == -1 and v3.reverseKey ~= nil then
					-- 	myKey = v3.reverseKey
					-- 	myReverseKey = v3
					-- 	rev = true
					-- 	v.direction = -1
					-- end
					if myKey.state == 3 then -- 刚放开 -- myKey.state == 0 or 
						-- print(myKey.id)
						ok = ok + 1
						-- if rev then
						-- 	rok = rok - 1
						-- end
					else
						if myReverseKey ~= nil and v.direction == 0 then
							if myReverseKey.state == 3 then -- 反向刚放开
								ok = ok + 1
								rok = rok - 1
							end
						end
					end
				elseif v2.kind == 3 then -- 上一次按键和这一次按键之中不能掺杂其他的按键
					if myKey.state == 1 then
						ok = ok + 1
					else
						if myReverseKey ~= nil and v.direction == 0 then
							if myReverseKey.state == 1 then
								ok = ok + 1
								rok = rok - 1
							else
								for i3, v3 in pairs(self.keys) do
									if v3 ~= myReverseKey and (v3.state == 1 or v3.state == 2) then
										v.timeCount = v.time
									end
								end
							end
						else
							for i3, v3 in pairs(self.keys) do
								if v3 ~= myKey and (v3.state == 1 or v3.state == 2) then
									v.timeCount = v.time
								end
							end
						end
					end
				end
			end

			if ok >= #v2.keys then
				if v.direction == 0 and rev == true then
					if rok < 0 then
						v.direction = -1
					else
						v.direction = 1
					end
				end
				success = true
			else
				-- if v.cmds[v.count - 1] ~= nil then
				-- 	local iterate = LPlayer:getIterateKeys(v2.keys, v.cmds[v.count - 1].keys)
				-- 	local ok2 = 0

				-- 	print(#iterate)

				-- 	for i4, v4 in ipairs(iterate) do -- keys
				-- 		if v4.count > 0 then
				-- 			ok2 = ok2 + 1
				-- 		end

				-- 	end

				-- 	if ok2 < #iterate then
				-- 		v.count = 1
				-- 		v.timeCount = 0
				-- 		v.direction = 0
				-- 	end
				-- end
			end
			if success then
				v.count = v.count + 1
				v.timeCount = 0
			else
				if v.timeCount >= v.time then
					v.count = 1
					v.timeCount = 0
					v.direction = 0
				end
			end
			if v.count > 1 then
				v.timeCount = v.timeCount + 1
			end
		else
			-- if self.object.vars["interact"] == false then
			if self.object.kind ~= 5 then
				-- self.object:addEvent("Input", 0, 1, {level = v.level, name = v.name, direction = v.direction, action = v.action, frame = v.frame, mp = v.mp})
				-- self.object:InvokeEvent("onCommand", {action = v.action, frame = v.frame})
				v.UIActive = v.direction
			else
				v.UIActive = v.direction
			end
	--~ 			self.object:addEvent("Input", 1, {level = v.level, name = v.name, direction = v.direction, frame = v.frame})
			v.count = 1
			v.timeCount = 0
			v.direction = 0
		end
	end
end