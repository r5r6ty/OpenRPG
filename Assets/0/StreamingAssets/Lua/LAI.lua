local utils = require "LUtils"

LAI = {db = nil, strategys = nil, commands = nil}
LAI.__index = LAI
function LAI:new(db)
	local self = {}
	setmetatable(self, LAI)
	
	self.db = db
	self.strategys = {}

	self:createStrategys()

	

    return self
end

function LAI:createStrategys()
	local commands = {}
	for i, v in ipairs(self.db:getLines("commands")) do
		commands[v.name] = {action = v.action, frame = v.frame, level = v.level, mp = v.mp}
	end
	for i, v in ipairs(self.db:getLines("AI")) do
		if v.active then
			local c = commands[v.command]
			local strategy = {}
			strategy.name = v.command
			strategy.action = c.action
			strategy.frame = c.frame
			strategy.level = c.level
			strategy.mp = c.mp
			strategy.distanceA, strategy.distanceB = utils.getRangeAB(v.distanceRange)
			strategy.probability = v.probability
			strategy.active = v.active
			strategy.canTurnAround = v.canTurnAround

			self.strategys[strategy.name] = strategy
		end
	end
end

function LAI:judgeAI(o)
	local temp = {}
	if o.target ~= nil and o["HP"] > 0 then
		for i, v in pairs(self.strategys) do
			if o["MP"] >= v.mp then
				local r = CS.Tools.Instance:RandomRangeInt(1, 101)
				if r <= v.probability * 100 then
					local pos = o.target.gameObject.transform.position - o.gameObject.transform.position
					
					local dx = o.direction.x
					local r = false
					if v.canTurnAround then
						if dx == 1 then
							r = (pos.x >= v.distanceA / 100 * dx and pos.x <= v.distanceB / 100 * dx) or (pos.x <= v.distanceA / 100 * -dx and pos.x >= v.distanceB / 100 * -dx)
						else
							r = (pos.x <= v.distanceA / 100 * dx and pos.x >= v.distanceB / 100 * dx) or (pos.x >= v.distanceA / 100 * -dx and pos.x <= v.distanceB / 100 * -dx)
						end
					else
						if dx == 1 then
							r = pos.x >= v.distanceA / 100 * dx and pos.x <= v.distanceB / 100 * dx
						else
							r = pos.x <= v.distanceA / 100 * dx and pos.x >= v.distanceB / 100 * dx
						end
					end
					if r then
						-- print(d)
						-- print(pos.x , v.distanceA / 100 , pos.x , v.distanceB / 100)

						if v.canTurnAround then
							if (pos.x < 0 and dx == 1) or (pos.x > 0 and dx == -1) then
								dx = dx * -1
							end
						end
						-- o:InvokeEvent("onCommand", 0, 1, {level = v.level, name = v.name, direction = dx, action = v.action, frame = v.frame, mp = v.mp})
						table.insert(temp, {level = v.level, name = v.name, direction = dx, action = v.action, frame = v.frame, mp = v.mp})
					end
				end
			end
		end
	else
		-- print("wawa")
	end
	return temp
end
