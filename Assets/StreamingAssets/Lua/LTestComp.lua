
-- LTestComp = {
--     property1 = 100,
--     property2 = "helloWorld",
--     ppp = nil
-- }

-- LTestComp.__index = LTestComp
-- function LTestComp:new(ss)
--     local self = {}
--     setmetatable(self, LTestComp)

--     self.ppp = ss
--     print("aaaaaaaaaaaaaaaaaaaaaaa" .. self.ppp)

--     return self
-- end

-- function LTestComp:new(ss)
-- 	local o = {} 
--     setmetatable(o, self)
--     self.__index = self

--     self.ppp = ss
-- 	return o
-- end   


-- LTestComp = {}
-- LTestComp.self = LTestComp

-- function LTestComp:new(ss)
--     LTestComp.name = ss
--     return LTestComp
-- end

LTestComp = { name = "ascs"}
LTestComp.__index = LTestComp

wolai = {}

function LTestComp:new(ss)
    wolai.name = ss
    return wolai
end

function LTestComp:update()
    print(self)
end


function LTestComp:start()
	print("lua start...")

end

-- function LTestComp:update()
--     print(self)

-- end

-- function LTestComp:lateupdate()
   
-- end

function LTestComp:fixedupdate()
    -- print(a.groupsIBelongTo)
    -- print(b.groupsIBelongTo)
end



function LTestComp:ondestroy()
    print("lua destroy")
    print(self)
    print("lua destroy")
end

function LTestComp:bOnCollisionEnter(other, manifoldList)
    print("On Collision Enter " .. CS.BulletUnity.BPhysicsWorld.Get().frameCount)
end

function LTestComp:bOnCollisionStay(other, manifoldList)
end

function LTestComp:bOnCollisionExit(other)
end


