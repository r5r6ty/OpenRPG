local ecs = require "ecs"

local id1
local es

local _update
local _fixedUpdate

-- local console

local world

-- local tiny = require("tiny")

-- function start()
--     local renderSystem = tiny.processingSystem()
--     renderSystem.filter = tiny.requireAll("name", "mass", "phrase")
--     function renderSystem:process(e, dt)
--         e.mass = e.mass + dt * 3

--     end

--     local physicalSystem = tiny.processingSystem()
--     physicalSystem.filter = tiny.requireAll("name", "mass", "phrase")
--     physicalSystem.interval = 1 / 50
--     function physicalSystem:process(e, dt)
--         e.mass = e.mass + dt * 3

--     end

--     world = tiny.world(renderSystem)

--     for i = 1, 10000, 1 do
--         local joe = {
--             name = "Joe",
--             phrase = "I'm a plumber.",
--             mass = 150,
--             hairColor = "brown"
--         }

--         world:add(joe)
--     end


-- end

-- function update()
--     world:update(1)
-- end

-- function fixedupdate()
-- end

function start()

    -- console = CS.ConsoleTestWindows.ConsoleWindow()
    -- if console:Initialize() then
    --     console:SetTitle("OpenRPG Debug Window")
    --     CS.TestConsole.Start2()
    -- end

    print("lua start...")
    -- print("injected object", LMainCamera)


    -- 注册组件
    ecs.registerComponent("Direction", function(self, i)
        self.x = i
    end, function(self)
        self.x = nil
    end)
    ecs.registerComponent("Mass", function(self, i)
        self.y = i
    end, function(self)
        self.y = nil
    end)
    ecs.registerComponent("Mass2", function(self, i)
        self.y = i
    end, function(self)
        self.y = nil
    end)

    ecs.registerComponent("Mass3", function(e)
        
    end)

    -- 注册系统
    ecs.registerSystem("RenderSystem", function(entity)
        entity.x = entity.x + 1
        -- print("RenderSystem", entity.x)
    end, ecs.allOf(ecs.getComponentID("Mass2")))
    
    ecs.registerSystem("ChangePositionSystem", function(entity)
        entity.y = entity.y + 1
        -- print("ChangePositionSystem", entity.y)
    end, ecs.allOf(ecs.getComponentID("Direction"), ecs.getComponentID("Mass2")))


    -- 创建系统集合
    _update = ecs.createSystems("RenderSystem")
    _fixedUpdate = ecs.createSystems("ChangePositionSystem")

    -- 创建一个实体
    for i = 1, 10000, 1 do
        local id1 = ecs.newEntity()
        ecs.addComponent(id1, "Direction", i)
        ecs.addComponent(id1, "Mass", i)
        ecs.addComponent(id1, "Mass2", i)
        ecs.applyEntity(id1)
    end
end

function update()
    for _, v in ipairs(_update) do
        -- if #v.matchedEntity == 0 then
        --     v.matchedEntity = ecs.getMatchedEntity(v.MatchedBit)
        -- end
        for _, v2 in ipairs(v.matchedEntity) do
            v.execute(v2)
        end
    end
end

function lateupdate()

end

function fixedupdate()
    for _, v in ipairs(_fixedUpdate) do
        -- if #v.matchedEntity == 0 then
        --     v.matchedEntity = ecs.getMatchedEntity(v.MatchedBit)
        -- end
        for _, v2 in ipairs(v.matchedEntity) do
            if v2._bit < 0 then
                
            end
            v.execute(v2)
        end
    end
end

function ongui()
	-- for i, v in pairs(ecs.entities) do
	-- 	CS.UnityEngine.GUILayout.Label(i .. " : " .. tostring(v._bit) .. ", " .. v.Position.x ..  v.Position.y ..  v.Position.z)
    -- end
    
    -- if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.KeypadEnter and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
    --     ecs.deleteComponent(id1, "Name")
    -- end
    
    if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.Q and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
        for i, v in pairs(ecs.entities) do
            -- ecs.deleteEntity(i)
            ecs.deleteComponent(i, "Mass2")
            ecs.applyEntity(i)
        end
    end
    
    if CS.UnityEngine.Event.current.keyCode == CS.UnityEngine.KeyCode.Z and CS.UnityEngine.Event.current.type == CS.UnityEngine.EventType.KeyDown then
        for i, v in pairs(ecs.entities) do
            -- ecs.deleteEntity(i)
            ecs.addComponent(i, "Mass2", i)
            ecs.applyEntity(i)
        end
	end
end

function ondestroy()
    print("lua destroy")
    -- console:Shutdown()
end