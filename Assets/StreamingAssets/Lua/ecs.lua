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

local function unbind(table, key)
    rawset(table, key, table[key])
    getmetatable(table)[key] = nil

    local binds = table.bind____
    if binds[key] then
        binds[key][tag] = nil
    end
end

local function bindable(init)
    local mt
    mt = {
        bind____ = {},

        __index = function(table, key)
            return mt[key]
        end,

        __newindex = function(table, key, value)
            local v_old = mt[key]
            if v_old == value then
                return
            end
            mt[key] = value
            local slots = mt.bind____[key]
            if slots then
                for _, v in ipairs(slots) do
                    v(init, value, v_old)
                end
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

local function bind(table, key, func)
    local temp = table[key]
    rawset(table, key, nil)
    table[key] = temp

    local binds = table.bind____
    binds[key] = binds[key] or {}
    local bind = binds[key]
    bind[#bind+1] = func
    return #bind
end

local maxBitCount = 63 -- 最大实体数
local maxBit = (1 << maxBitCount) - 1

local ecs = {}

local entities = {}	-- all Entities, eid -> entity
local entityID = 0
ecs.entities = entities

ecs.total = 0

local cache = {}

function ecs.getCache()
    return cache
end

-- 创建实体
function ecs.newEntity()
    entityID = entityID + 1
    ecs.total = ecs.total + 1
    
    local e = { _eid = entityID, _bit = 0, _bit2 = 0 }
    -- -- 组件添加或删除时执行
    -- bind(e, "_bit", function(t, val, old)
    --     cache[old] = cache[old] or {}
    --     cache[old][t] = nil
    --     if next(cache[old]) == nil then
    --         cache[old] = nil
    --     end

    --     if val ~= 0 and val ~= nil then
    --         cache[val] = cache[val] or {}
    --         cache[val][t] = t
    --     end
    -- end)

	entities[entityID] = e
	return entityID
end

-- 删除实体
function ecs.deleteEntity(eid)
	local e = assert(entities[eid])
	-- local typeinfo = etypes[e._bit]
    -- for i, v in pairs(e.bind____) do
    --     unbind(e, i)
    -- end

    for i, v in pairs(cache) do
        if e._bit >= i and e._bit | i == e._bit then
            v[eid] = nil
        end
    end
    
    local b = 1
    while e._bit > 0 do
        if e._bit & 1 == 1 then
            ecs.removeComponent2(eid, b)
        end

        e._bit = e._bit >> 1

        b = b + 1
    end
    e._eid = 0
    entities[eid] = nil
    
    ecs.total = ecs.total - 1
end

function ecs.cacheDE(bit)

end

-- ctype: component type
local components = { _typeIDCounter = 0 }

-- 注册组件
function ecs.registerComponent(newtype, _requireBit, _new, _del)

	local typeid = components._typeIDCounter + 1
	assert(typeid <= maxBitCount)
	components._typeIDCounter = typeid
	components[newtype] = typeid
	components[typeid] = {requireBit = _requireBit, new = _new, del = _del}

	-- components[typeid] = { new = cnew, del = cdel }
end

function ecs.getComponentID(ctype)
    return components[ctype]
end

function ecs.getComponent(ctype)
    return components[components[ctype]]
end

-- 添加组件
function ecs.addComponent(eid, ctype, ...)
    local e = assert(entities[eid])

    local typeid = components[ctype]
    local c = components[typeid]

    assert(e._bit >= c.requireBit and e._bit | c.requireBit == e._bit, ctype .. " requireBit: " .. c.requireBit)

    if c.new ~= nil then
        c.new(e, ...)
    end

    e._bit = e._bit | 2 ^ (typeid - 1)

    -- if type(e[ctype]) ~= "table" then
    --     bind(e, ctype, function(t, val, old)
    --         print(ctype .. " changed:", "new:", val, "old:", old)
    --     end)
    -- end
end

function ecs.applyEntity(eid)
    local e = assert(entities[eid])

    for i, v in pairs(cache) do
        if e._bit2 >= i and e._bit2 | i == e._bit2 then
            v[eid] = nil
        end
    end

    for i, v in pairs(cache) do
        if e._bit >= i and e._bit | i == e._bit then
            v[eid] = e
        end
    end

    e._bit2 = e._bit

    return e
end

-- -- 获取组件
-- function ecs.getComponent(eid, type)
--     local e = assert(entities[eid])
--     return e[type]
-- end

-- 删除组件
function ecs.removeComponent(eid, ctype)
    local e = assert(entities[eid])
    local typeid = components[ctype]
    if components[typeid].del ~= nil then
        components[typeid].del(e)
    end
    e._bit = e._bit & ~(1 << (typeid - 1))
end

function ecs.removeComponent2(eid, cid)
    local e = assert(entities[eid])
    if components[cid].del ~= nil then
        components[cid].del(e)
    end
    e._bit = e._bit & ~(1 << (cid - 1))
end

function ecs.allOf(...)
    local f = { ... }
    local bit = 0
    for i, v in ipairs(f) do
        bit = bit | 2 ^ (components[v] - 1)
    end
    return bit
end

-- function ecs.allOf(bit)
--     local str = ""
--     local i
--     while bit > 0 do

--     end
-- end

-- -- 获取匹配的实体
-- function ecs.getMatchedEntity(bit)
    -- local res = {}

    -- for i, v in pairs(cache) do
    --     if i >= bit and i | bit == i then
    --         for j, v2 in pairs(v) do
    --             table.insert(res, j)
    --         end
    --     end
    -- end

    -- return res

--     return cache[bit]
-- end

local systems = {}

function ecs.registerMultipleSystem(newtype, func, bit)

    assert(systems[newtype] == nil, "already exist system: " .. newtype)
    assert(not (bit == nil and bit <= 0), "bit must > 0")

    cache[bit] = cache[bit] or {}

	systems[newtype] = {
        MatchedBit = bit,
        matchedEntity = cache[bit],
        execute = func
    }
end

function ecs.displayMultipleSystem(newtype)
    local n = 0
    for _, v in pairs(cache[systems[newtype].MatchedBit]) do
        n = n + 1
    end
    return n
end

function ecs.registerSingleSystem(newtype, func, bit)

	assert(systems[newtype] == nil, "already exist system: " .. newtype)

	systems[newtype] = {
        MatchedBit = bit or 0,
        execute = func
    }
end

function ecs.processMultipleSystem(stype)
    local system = systems[stype]
    for _, v2 in pairs(system.matchedEntity) do
        system.execute(v2)
    end
end

function ecs.processSingleSystem(stype, e, ...)
    local system = systems[stype]
    if e._bit >= system.MatchedBit and e._bit | system.MatchedBit == e._bit then
        system.execute(e, ...)
    -- else
    --     print(e._bit, system.MatchedBit, stype)
    end
end

return ecs