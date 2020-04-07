require "LTestComp"

local a = nil
local b = nil
function start()
	print("lua start...")
    print("injected object", LMainCamera)
    print("injected object", LCanvas)

    local world = CS.UnityEngine.GameObject("world")
    world:AddComponent(typeof(CS.BulletUnity.BPhysicsWorld))


    



    b = createbox(CS.BulletSharp.CollisionFlags.StaticObject, 0, 0, 0, "Ground")


    a = createbox(CS.BulletSharp.CollisionFlags.None, 0, 3, 0, "A")
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


function createbox(flg, x, y, z, name)
    local deubg_object = CS.UnityEngine.GameObject.CreatePrimitive(CS.UnityEngine.PrimitiveType.Cube)
    CS.UnityEngine.GameObject.Destroy(deubg_object:GetComponent(typeof(CS.UnityEngine.BoxCollider)))
    -- local deubg_object = CS.UnityEngine.GameObject("deubg_object")

    deubg_object.transform.position = CS.UnityEngine.Vector3(x, y, z)

    local bb = deubg_object:AddComponent(typeof(CS.BulletUnity.BBoxShape))
    bb.Extents = CS.UnityEngine.Vector3(0.5, 0.5, 0.5)
    local rigidbody = deubg_object:AddComponent(typeof(CS.BulletUnity.BRigidBody))
    rigidbody.collisionFlags = flg

    -- CS.LuaUtil.AddLuaComponent(deubg_object, "test2_testfun")
    -- local table = LTestComp:new(name)
    
    -- local LTestComp = {}
    -- LTestComp.self = LTestComp

    -- function LTestComp:new(ss)
    --     LTestComp.name = ss
    --     return LTestComp
    -- end

    -- function LTestComp:update()
    --     print(LTestComp.name)
    -- end


    CS.LuaUtil.AddLuaComponent(deubg_object, LTestComp:new(name))

    -- deubg_object:AddComponent(typeof(CS.BulletUnity.Primitives.BBox))

    rigidbody.groupsIBelongTo = 128
    rigidbody.collisionMask = 128
    return rigidbody
end