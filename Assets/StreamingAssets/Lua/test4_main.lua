
local utils = require "LUtils"

local runtimeSkeletonAnimation = nil
local bone = nil

function start()

    local bytes = utils.openFileBytes(CS.UnityEngine.Application.dataPath .. "/Resources/Scenes/girl/girl.png")

    local texture = CS.UnityEngine.Texture2D(0, 0, CS.UnityEngine.TextureFormat.RGBA32, false, false)
    texture.filterMode = CS.UnityEngine.FilterMode.Point
    CS.UnityEngine.ImageConversion.LoadImage(texture, bytes) -- 这个怎么不行了？
    -- texture:LoadImage(bytes) --- Texture2d  成员方法无法使用，为什么？为什么又能使用了？

    -- local p = CS.UnityEngine.GameObject("wa")
    -- local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(0, 0, texture.width, texture.height), CS.UnityEngine.Vector2(0, 1))

    -- local unityobject_child = CS.UnityEngine.GameObject("wa")
    -- unityobject_child.transform.parent = p.transform
    -- -- unityobject_child.transform.localPosition = CS.UnityEngine.Vector3(rects[i - 1].x * texture.width / 100, -rects[i - 1].y * texture.height / 100, 0)
    -- local sr = unityobject_child:AddComponent(typeof(CS.UnityEngine.SpriteRenderer))
    -- sr.sprite = sprite

    texture.name = "girl"
    -- texture:Apply()

	local texs = {}
	table.insert(texs, texture)
    
    local material = CS.UnityEngine.Material(CS.UnityEngine.Shader.Find("Spine/Skeleton"))
    
    local runtimeAtlasAsset = CS.Spine.Unity.AtlasAsset.CreateRuntimeInstance(CS.UnityEngine.TextAsset(utils.openFileText(CS.UnityEngine.Application.dataPath .. "/Resources/Scenes/girl/girl.atlas.txt")), texs, material, true)
    local runtimeSkeletonDataAsset = CS.Spine.Unity.SkeletonDataAsset.CreateRuntimeInstance(CS.UnityEngine.TextAsset(utils.openFileText(CS.UnityEngine.Application.dataPath .. "/Resources/Scenes/girl/girl.json")), runtimeAtlasAsset, true)
    runtimeSkeletonDataAsset:GetSkeletonData(false)

    runtimeSkeletonAnimation = CS.Spine.Unity.SkeletonAnimation.NewSkeletonAnimationGameObject(runtimeSkeletonDataAsset)

    bone = runtimeSkeletonAnimation.Skeleton:FindBone("crosshair")

    print(bone.Data.Name, bone.ScaleX, bone.ScaleY)

    -- Extra Stuff
    runtimeSkeletonAnimation:Initialize(false)
    --runtimeSkeletonAnimation.Skeleton.SetSkin("base");
    runtimeSkeletonAnimation.Skeleton:SetSlotsToSetupPose()
    runtimeSkeletonAnimation.AnimationState:SetAnimation(0, "aimR", true)
    runtimeSkeletonAnimation:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).sortingOrder = 10
    runtimeSkeletonAnimation.transform:Translate(CS.UnityEngine.Vector3.down * 2)
end

function update()
    local mousePosition = CS.UnityEngine.Input.mousePosition
    local worldMousePosition = CS.UnityEngine.Camera.main:ScreenToWorldPoint(mousePosition)
    local skeletonSpacePoint = runtimeSkeletonAnimation.transform:InverseTransformPoint(worldMousePosition)
    if  runtimeSkeletonAnimation.Skeleton.FlipX then
        skeletonSpacePoint.x = skeletonSpacePoint.x * -1
    end

    CS.Spine.Unity.SkeletonExtensions.SetPosition(bone, skeletonSpacePoint)
end

function lateupdate()

end

function fixedupdate()

end

function ongui()

end

function ondestroy()
    print("lua destroy")
end