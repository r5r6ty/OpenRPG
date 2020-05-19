function utils.setButtonColor(self, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
    local cb = self.button.colors
    cb.normalColor = CS.UnityEngine.Color(r1 / 255, g1 / 255, b1 / 255, a1 / 255)
    cb.highlightedColor = CS.UnityEngine.Color(r2 / 255, g2 / 255, b2 / 255, a2 / 255)
    cb.selectedColor = CS.UnityEngine.Color(r3 / 255, g3 / 255, b3 / 255, a3 / 255)
    self.button.colors = cb
end

function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then return false end
    local pos, arr = 0, {}
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function trim(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = split(debug.traceback("", 2), "\n")
    -- print("dump from: " .. trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

-- ????
function addEvent(eventManager, eventName, action)
	if not eventManager[eventName] then
		eventManager[eventName] = Delegate()
	end
	eventManager[eventName].add(action)
end

-- ????
function removeEvent(eventManager, eventName, action)
	eventManager[eventName].delete(action)
end

-- ??????
function removeAllEvent(eventManager)
	eventManager = {}
end

-- ????
function invokeEvent(eventManager, eventName, ...)
	if eventManager[eventName] then
		eventManager[eventName].invoke(...)
	end
end

function unbind(table, key, func)
    local binds = table.bind____
	local _bind = binds[key]
	removeEvent(_bind, "OnChange", func)
	
	if next(_bind) == nil then
		rawset(table, key, table[key])
		getmetatable(table)[key] = nil
	end
end

function bindable(init)
    local mt
    mt = {
        bind____ = {},

		__index = function(table, key)
			-- assert(mt[key] ~= nil, "__index: value: " .. key .." not exist")
            return mt[key]
        end,

		__newindex = function(table, key, value)
            local v_old = mt[key]
            if v_old == value then
                return
            end
			mt[key] = value
			if mt.bind____[key] then
				invokeEvent(mt.bind____[key], "OnChange", table, value)
			end
        end,

        __gc = function()
            for i, v in pairs(mt.bind____) do
                unbind(init, i)
            end
        end
    }
    setmetatable(init, mt)
    return init
end

function bind(table, key, func)
    local binds = table.bind____
    binds[key] = binds[key] or {}
	local _bind = binds[key]

	addEvent(_bind, "OnChange", func)
	
	local temp = table[key]
	rawset(table, key, nil)
	table[key] = temp
end