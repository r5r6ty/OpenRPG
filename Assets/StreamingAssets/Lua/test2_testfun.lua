
local a = nil
local b = nil
function start()
	print("lua start...")

end

function update()
    
end

function lateupdate()
   
end

function fixedupdate()
    -- print(a.groupsIBelongTo)
    -- print(b.groupsIBelongTo)
end

function ongui()

end

function ondestroy()
    print("lua destroy")
end

function bOnCollisionEnter(other, manifoldList)
    print("On Collision Enter " .. CS.BulletUnity.BPhysicsWorld.Get().frameCount)
end

function bOnCollisionStay(other, manifoldList)
end

function bOnCollisionExit(other)
end