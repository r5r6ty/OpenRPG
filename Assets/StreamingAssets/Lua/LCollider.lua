local ecs = require "ecs"

LCollider = {LObject = nil, collider_object = nil, gameObject = nil, id = nil, collider = nil, filter = nil, isDefence = nil, layers = nil, isRayCast = nil}
LCollider.__index = LCollider
function LCollider:new(l, go, id)
	local self = {}
	setmetatable(self, LCollider)

	self.LObject = l
	self.gameObject = go
	self.id = id
	self.filter = nil

	-- self.collider = self.gameObject:AddComponent(typeof(CS.UnityEngine.BoxCollider))

	self.offset = nil
	self.size = nil

	self.isDefence = nil

	self.layers = nil

	self.isRayCast = 0

    return self
end

-- 设置collider
function LCollider:setCollider()
end

--~ function LCollider:reverseCollider(dir)
--~ 	self.offset = self.offset * dir
--~ 	self.collider.offset = self.offset
--~ end

function LCollider:deleteCollider()
	CS.UnityEngine.Object.Destroy(self.collider_object)
	self.collider_object = nil
	self.collider = nil
	CS.LuaUtil.RemoveColliderID(self.collider_id)
	self.collider_id = nil
end

LColliderBDY = {bounciness = nil, isHit = nil, hitObject = nil, hitObjects = nil, queryTriggerInteraction = nil, isBDY = nil}
setmetatable(LColliderBDY, LCollider)
LColliderBDY.__index = LColliderBDY
function LColliderBDY:new(l, go, id)
	local self = {}
	self = LCollider:new(l, go, id)
	setmetatable(self, LColliderBDY)

    self.collider_object = CS.UnityEngine.GameObject("18")
	self.collider_object.transform:SetParent(self.gameObject.transform, false)
	self.collider_object.layer = 18

	self.collider = self.collider_object:AddComponent(typeof(CS.UnityEngine.BoxCollider))
	self.collider_id = self.collider:GetInstanceID()
	CS.LuaUtil.AddColliderID(self.collider_id, self.collider)

	self.bounciness = 0
	self.isHit = -1
	self.hitObject = nil

	self.hitObjecgts = {}

	self.queryTriggerInteraction = CS.UnityEngine.QueryTriggerInteraction.UseGlobal

	self.isBDY = false
	return self
end

-- 设置collider
function LCollider:setCollider(dir, x, y, width, height, depth, flags, layers, bounciness, attackFlags, layer)
	self.offset = CS.UnityEngine.Vector3((x + width / 2) / 100, 0, (y + height / 2) / 100)
	if depth ~= nil then
		self.size = CS.UnityEngine.Vector3(depth / 100, width / 100, height / 100)
	else
		self.size = CS.UnityEngine.Vector3(width / 100, width / 100, height / 100)
	end
	self.collider.center = self.offset-- * dir
	self.collider.size = self.size

	-- 自身碰撞设定
	if not (flags == nil or flags == 0) then
		if flags & 1 == 1 then
			self.collider_object.layer = layer
			self.collider_object.name = tostring(layer)

			self.isBDY = true
		else
			self.collider_object.layer = 17
			self.collider_object.name = "17"

			self.isBDY = false
		end

		if flags & 2 == 2 then
			self.collider.isTrigger = false
		else
			self.collider.isTrigger = true
		end
	else
		self.collider_object.layer = 18
		self.collider_object.name = "18"

		self.isBDY = false
	end

	-- 对他碰撞判定
	attackFlags = attackFlags or 0

	self.filter = 0 | 65535

	if attackFlags & 1 == 1 and attackFlags & 2 == 2 then
		self.queryTriggerInteraction = CS.UnityEngine.QueryTriggerInteraction.Collide
		self.filter = self.filter | 1 << 17
		self.filter = self.filter | 1 << 16
	elseif attackFlags & 1 == 1 then
		self.queryTriggerInteraction = CS.UnityEngine.QueryTriggerInteraction.Collide
		self.filter = self.filter | 1 << 16
	elseif attackFlags & 2 == 2 then
		self.queryTriggerInteraction = CS.UnityEngine.QueryTriggerInteraction.Ignore
		self.filter = self.filter | 1 << 17
		self.filter = self.filter | 1 << 16
	end

	self.layers = layers
	if layers ~= nil then
		for s in string.gmatch(layers, "%d+") do
			self.filter = self.filter & ~(1 << tonumber(s))
		end
	end

	if attackFlags == 0 then
		self.filter = -1
	end

	-- if flag & 2 == 2 then
	-- 	self.collider.isTrigger = true
	-- else
	-- 	self.collider.isTrigger = false
	-- end
	-- if flags & 8 == 8 then
	-- 	self.isDefence = true
	-- else
	-- 	self.isDefence = false
	-- end

	self.bounciness = bounciness or 0

	if width == 1 and height == 1 then
		self.isRayCast = 2
		-- self:deleteCollider()
		-- self.collider.enabled = false
	else
		self.isRayCast = 0
	end
end

-- -- 检测碰撞物，如果发生碰撞则进行位移
-- function LColliderBDY:BDYFixedUpdate2D(velocity, weight)
-- 	local isGround = 1
-- 	local isCeiling = false
-- 	local isWall = false
-- 	local isElse = 1
-- 	local elseArray = {}

-- 	-- 检测和什么碰，2d碰撞范围一般比实际要大，因为AABB要大一点，为了精确碰撞，需要自己实现
-- 	local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider, self.filter) -- 这个函数其实Collider2D.OverlapCollider，用来手动检测碰撞，这边因为lua的缘故封装了一下

-- 	local objectTable = {}

-- 	-- 最终位移坐标
-- 	local finalOffset_x = 0
-- 	local finalOffset_y = 0
-- 	for p, k in pairs(contactColliders) do
-- 		if self.collider.bounds:Intersects(k.bounds) then

-- 			local up, down, left, right = false, false, false, false

-- 			local go = k.attachedRigidbody.gameObject
-- 			local object2 = utils.getObject(go:GetInstanceID())
-- 			if go.name == "test" then -- 如果是地图块
-- 				local name = utils.split(k.name, ",")
-- 				local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit

-- 				if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
-- 					up = true
-- 				end
-- 				if num & 2 == 2 then --位操作
-- 					down = true
-- 				end
-- 				if num & 4 == 4 then --位操作
-- 					left = true
-- 				end
-- 				if num & 8 == 8 then --位操作
-- 					right = true
-- 				end
-- 			elseif go.name ~= "test" and object2 ~= nil and self.collider.attachedRigidbody.gameObject ~= go then -- 是游戏object，则只允许左右进行碰撞

-- 				local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

-- 				if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
-- 					left = true
-- 					right = true
-- 				end
-- 			else
-- 				-- return 1, false, false, 1, elseArray
-- 			end

-- 			if up or down or left or right then

-- 				local menseki = utils.getBoundsIntersectsArea(self.collider.bounds, k.bounds)
-- 				if menseki.magnitude > 0 then -- 无视多少面积设置

-- 					-- 算2个collider之间距离，主要是为了法线
-- 					local cd2d = self.collider:Distance(k)

-- 	--~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
-- 	--~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
-- 					local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
-- 	--~ 				CS.UnityEngine.Debug.DrawLine(a, a + normal, CS.UnityEngine.Color.red)
-- 	--~ 				CS.UnityEngine.Debug.DrawLine(b, b + normal, CS.UnityEngine.Color.yellow)

-- 					-- 做碰撞法线与行进方向的点积
-- 					-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- 没用到，有需要可以自己看情况加

-- 					local offset_x = 0
-- 					local offset_y = 0

-- 					-- 左移，右移
-- 					if self.collider.bounds.center.x < k.bounds.center.x then
-- 						if left and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- 如果碰撞朝向与行进方向相反，则求出位移坐标
-- 							offset_x = -menseki.x
-- 						end
-- 					else
-- 						if right and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(1, 0)) <= 0 then
-- 							offset_x = menseki.x
-- 						end
-- 					end
-- 					-- 上移，下移
-- 					if self.collider.bounds.center.y > k.bounds.center.y then
-- 						if up and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(0, 1)) <= 0 then
-- 							offset_y = menseki.y
-- 						end
-- 					else
-- 						if down and CS.UnityEngine.Vector2.Dot(velocity.normalized, CS.UnityEngine.Vector2(0, -1)) <= 0 then
-- 							offset_y = -menseki.y
-- 						end
-- 					end

-- 					if (up or down) and (left or right) then -- 如果同时满足上下和左右方向同时存在的情况，则根据碰撞方向来筛选掉另一个轴的位移
-- 						offset_x = offset_x * math.abs(normal.x)
-- 						offset_y = offset_y * math.abs(normal.y)
-- 					end

-- 					-- 留下最小位移坐标
-- 					if velocity.x > 0 then
-- 						if offset_x < finalOffset_x then
-- 							finalOffset_x = offset_x
-- 						end
-- 					else
-- 						if offset_x > finalOffset_x then
-- 							finalOffset_x = offset_x
-- 						end
-- 					end

-- 					if velocity.y > 0 then
-- 						if offset_y < finalOffset_y then
-- 							finalOffset_y = offset_y
-- 						end
-- 					else
-- 						if offset_y > finalOffset_y then
-- 							finalOffset_y = offset_y
-- 						end
-- 					end

-- 					if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
-- 						local rate = weight / object2["weight"] / 2
-- 						if rate > 1 then
-- 							rate = 1
-- 						end
-- 						local vOffset = (object2.velocity.x - velocity.x) * rate
-- 	--~ 					object2.velocity.x = object2.velocity.x - vOffset
-- 						-- print(object2)
-- 						object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
-- 					end

-- 					if go.name == "test" then -- 判断是不是撞到地面，这样写不好，以后再优化
-- 						if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
-- 							isWall = true
-- 						end
-- 						if finalOffset_y > 0 then
-- 							local id = string.match(k.name, "%[(%d+)%]")

-- 							if id then
-- 								isGround = isGround | 1 << tonumber(id)
-- 							end

-- 						elseif finalOffset_y < 0 then
-- 							isCeiling = true
-- 						end
-- 					end
-- 				end
-- 			else
-- 				local id = string.match(k.name, "%[(%d+)%]")
-- 				if id then
-- 					isElse = isElse | 1 << tonumber(id)
-- 				end
-- 				if elseArray[id] == nil then
-- 					elseArray[id] = {}
-- 				end
-- 				elseArray[id][k:GetInstanceID()] = k
-- 			end
-- 		end
-- 	end

-- 	-- 更新自身位置
-- 	self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector2(finalOffset_x, finalOffset_y)

-- 	return isGround, isCeiling, isWall, isElse, elseArray
-- end

function LColliderBDY:BDYFixedUpdate()
	local isGround = -1
	local isWall_leftright = -1
	local isWall_updown = -1

	if self.isRayCast ~= 0 then
		-- assert(self.collider == false, "self.collider must be nil with raycast")
		local velocity_x = self.LObject.velocity.x * CS.UnityEngine.Time.deltaTime * self.LObject.speed
		local velocity_z = self.LObject.velocity.z * CS.UnityEngine.Time.deltaTime * self.LObject.speed
		local velocity_y = self.LObject.velocity.y * CS.UnityEngine.Time.deltaTime * self.LObject.speed

		local rx, ry, rz = CS.LuaUtil.RigidbodyGetPosition(self.LObject.rigidbody)

		-- local offset = CS.UnityEngine.Vector3(rx - self.LObject.oriPos.x, ry - self.LObject.oriPos.y, rz - self.LObject.oriPos.z)

		local length = utils.GetVector3Module(velocity_x, velocity_y, velocity_z) -- 射线的长度
		local dx = velocity_x / length -- 方向
		local dy = velocity_y / length -- 方向
		local dz = velocity_z / length -- 方向

		-- local oriPos = CS.UnityEngine.Vector3(self.LObject.oriPos.x, self.LObject.oriPos.y, self.LObject.oriPos.z)

		-- CS.LuaUtil.DrawLine(rx, ry, rz, 0, 0, 0, 1, 0, 0, 1)
		CS.LuaUtil.DrawLine(rx, ry, rz, rx + velocity_x, ry + velocity_y, rz + velocity_z, 0, 0, 1, 1)
		-- CS.LuaUtil.DrawLine(rx + velocity_x, ry + velocity_y, rz + velocity_z, 0, 0, 0, 0, 1, 0, 1)
	
		-- CS.LuaUtil.DrawLine(rx, ry + rz, rz, 0, 0, 0, 1, 0, 0, 1)
		CS.LuaUtil.DrawLine(rx, ry + rz, rz, rx + velocity_x, ry + velocity_y + rz + velocity_z, rz + velocity_z, 0, 0, 1, 1)
		-- CS.LuaUtil.DrawLine(rx + velocity_x, ry + velocity_y + rz + velocity_z, rz + velocity_z, 0, 0, 0, 0, 1, 0, 1)
	

		-- local hitinfo = CS.Tools.Instance:PhysicsRaycast(rxyz, direction, length, 1048575)
		self.hitObjects = CS.LuaUtil.PhysicsRaycastAll(rx, ry, rz, dx, dy, dz, length, 1048575)
		-- local hitinfos = CS.Tools.Instance:PhysicsRaycastAll(CS.UnityEngine.Vector3(rx, ry, rz), CS.UnityEngine.Vector3(dx, dy, dz), length, 1048575)

		-- 最终位移坐标
		local finalOffset_x = velocity_x
		local finalOffset_z = velocity_z
		local finalOffset_y = velocity_y
		if self.isRayCast == 1 then
			for i = 0, self.hitObjects.Length - 1, 1 do
				local k = self.hitObjects[i].collider
				if k ~= nil and k.attachedRigidbody ~= self.collider.attachedRigidbody then
					-- print(k.name)
					local up, down, left, right, above, under = false, false, false, false, false, false
					local go = k.attachedRigidbody.gameObject
					if go.name == "test" then -- 如果是地图块
						local name = utils.split(k.name, ",")
						local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit

						if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
							up = true
						end
						if num & 2 == 2 then --位操作
							down = true
						end
						if num & 4 == 4 then --位操作
							left = true
						end
						if num & 8 == 8 then --位操作
							right = true
						end
						if num & 16 == 16 then --位操作
							above = true
						end
						if num & 32 == 32 then --位操作
							under = true
						end

						self.hitObject = object
						self.isHit = 1
					elseif go.name ~= "test" then
						local object2 = utils.getObject(go:GetInstanceID())
						if object2 == nil then
							print("what1!?")
							self.hitObject = nil
							self.isHit = -1
						else
							if self.LObject.team ~= object2.team then
							-- local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

							-- if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
								up = true
								down = true
								left = true
								right = true
							-- end
							-- above = true
							-- under = true

								self.hitObject = object
								self.isHit = 16

								-- print(object2.state)
							else
								self.hitObject = nil
								self.isHit = -1
							end
						end

						-- local iId = hitinfo.collider.attachedRigidbody.gameObject:GetInstanceID()
						-- local object = utils.getObject(iId)

						-- local LC = object.bodyArray_InstanceID[hitinfo.collider:GetInstanceID()]
						-- if LC ~= nil and LC.isDefence then

						-- 	self.hitObject = object
						-- 	self.isHit = 1
						-- else

						-- 	self.hitObject = object
						-- 	self.isHit = 16
						-- end
					else
						print(go.name)
						self.hitObject = nil
						self.isHit = -1
						-- return 1, false, false, 1, elseArray
					end

					if up or down or left or right or above or under then
						local mmm_x, mmm_y, mmm_z = CS.LuaUtil.RaycastHitGetPoint(hitinfos[i])
						local m_x = math.abs(mmm_x - rx)
						local m_y = math.abs(mmm_y - ry)
						local m_z = math.abs(mmm_z - rz)

						local offset_x = nil
						local offset_z = nil
						local offset_y = nil
						if (left or right) and (up or down) then
							if m_x > m_y then
								m_x = 0
							else
								m_y = 0
							end
						end
						if velocity_x > 0 then
							offset_x = velocity_x - m_x
						else
							offset_x = velocity_x + m_x
						end

						if velocity_y > 0 then
							offset_y = velocity_y - m_y
						else
							offset_y = velocity_y + m_y
						end

						if velocity_z > 0 then
							offset_z = velocity_z - m_z
						else
							offset_z = velocity_z + m_z
						end
						-- 留下最小位移坐标
						if left or right then
							if velocity_x > 0 then
								if offset_x < finalOffset_x then
									finalOffset_x = offset_x
								end
							else
								if offset_x > finalOffset_x then
									finalOffset_x = offset_x
								end
							end

							isWall_leftright = 1

						end

						if up or down then

							if velocity_y > 0 then
								if offset_y < finalOffset_y then
									finalOffset_y = offset_y
								end
							else
								if offset_y > finalOffset_y then
									finalOffset_y = offset_y
								end
							end

							isWall_updown = 1

						end

						if (left or right) and (up or down) then
							if m_x > m_y then
								isWall_leftright = -1
							else
								isWall_updown = -1
							end
						end

						if above or under then

							if velocity_z > 0 then
								if offset_z < finalOffset_z then
									finalOffset_z = offset_z
								end
							else
								if offset_z > finalOffset_z then
									finalOffset_z = offset_z
								end
							end

							if isGround == -1 and m_z > 0 then
								isGround = 1 << tonumber(0)
							end
						end
						break
					end
				else
					self.hitObject = nil
					self.isHit = -1
				end
			end
			if self.hitObjects.Length == 0 then
				self.hitObject = nil
				self.isHit = -1
			end

			if self.bounciness > 0 then
				if isWall_leftright == 1 then
					self.LObject.velocity.x = -self.LObject.velocity.x * self.bounciness
				end
				if isWall_updown == 1 then
					self.LObject.velocity.y = -self.LObject.velocity.y * self.bounciness
				end
				if isGround == 1 then
					self.LObject.velocity.z = -self.LObject.velocity.z * self.bounciness
				end
				if isWall_leftright == 1 or isWall_updown == 1 or isGround == 1 then
					self.LObject.rotation_velocity = (CS.Tools.Instance:RandomRangeInt(0, 2) * 2 - 1) * self.LObject.rotation_velocity * self.bounciness
				end
			end
		elseif self.isRayCast == 2 then
			for i = 0, self.hitObjects.Length - 1, 1 do
				local k = self.hitObjects[i].collider
				if k ~= nil and k.attachedRigidbody ~= self.collider.attachedRigidbody then
					local go = k.attachedRigidbody.gameObject
					if go.name == "test" then -- 如果是地图块
						self.hitObject = nil
						self.isHit = 1
						local dis = self.hitObjects[i].distance
						finalOffset_x = dx * dis
						finalOffset_y = dy * dis
						finalOffset_z = dz * dis

						local nx, ny, nz =  CS.LuaUtil.RaycastHitGetNormal(self.hitObjects[i])
						local ddx, ddy, ddz = CS.LuaUtil.Vector3Reflect(dx, dy, dz, nx, ny, nz)
						
						local len = utils.GetVector3Module(self.LObject.velocity.x, self.LObject.velocity.y, self.LObject.velocity.z)
						self.LObject.velocity.x = ddx * len * self.bounciness
						self.LObject.velocity.y = ddy * len * self.bounciness
						self.LObject.velocity.z = ddz * len * self.bounciness
						break
					elseif go.name ~= "test" then
						local object2 = utils.getObject(go:GetInstanceID())
						if object2 == nil then
							print("what2!?")
							self.hitObject = nil
							self.isHit = -1
						else
							if self.LObject.team ~= object2.team or (self.LObject.team == object2.team and object2._bit | 1 ~= object2._bit) then
								self.hitObject = object2
								self.isHit = 16
								local dis = self.hitObjects[i].distance
								finalOffset_x = dx * dis
								finalOffset_y = dy * dis
								finalOffset_z = dz * dis

								local nx, ny, nz =  CS.LuaUtil.RaycastHitGetNormal(self.hitObjects[i])
								local ddx, ddy, ddz = CS.LuaUtil.Vector3Reflect(dx, dy, dz, nx, ny, nz)
								
								local len = utils.GetVector3Module(self.LObject.velocity.x, self.LObject.velocity.y, self.LObject.velocity.z)
								self.LObject.velocity.x = ddx * len * self.bounciness
								self.LObject.velocity.y = ddy * len * self.bounciness
								self.LObject.velocity.z = ddz * len * self.bounciness


								if object2._bit | 1 ~= object2._bit then
									ecs.addComponent(object2._eid, "Active")
									ecs.applyEntity(object2._eid)

									object2.velocity.x = object2.velocity.x - self.LObject.velocity.x
									object2.velocity.y = object2.velocity.y - self.LObject.velocity.y
									object2.velocity.z = object2.velocity.z - self.LObject.velocity.z
									object2.rotation_velocity = 0
								else
									object2.velocity.x = object2.velocity.x - self.LObject.velocity.x / 10
									object2.velocity.y = object2.velocity.y - self.LObject.velocity.y / 10
									object2.velocity.z = object2.velocity.z - self.LObject.velocity.z / 10
								end
								break
							else
								self.hitObject = nil
								self.isHit = -1
							end
						end
					else
						self.hitObject = nil
						self.isHit = -1
					end
				end
			end
			if self.hitObjects.Length == 0 then
				self.hitObject = nil
				self.isHit = -1
			end
		end

		local dt = 1
		CS.LuaUtil.RigidbodyMovePosition(self.collider.attachedRigidbody, finalOffset_x * dt, finalOffset_y * dt, finalOffset_z * dt)
	else

		local velocity_x = self.LObject.velocity.x * CS.UnityEngine.Time.deltaTime * self.LObject.speed
		local velocity_y = self.LObject.velocity.y * CS.UnityEngine.Time.deltaTime * self.LObject.speed
		local velocity_z = self.LObject.velocity.z * CS.UnityEngine.Time.deltaTime * self.LObject.speed
		

		-- local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider.bounds.center + velocity, self.collider.bounds.extents, self.LObject.physics_object.transform.rotation, self.filter.layerMask.value)
		local cx, cy, cz = CS.LuaUtil.GetColliderBoundsCenter(self.collider_id)
		local ex, ey, ez = CS.LuaUtil.GetColliderBoundsExtents(self.collider_id)
		local rx, ry, rz, rw = CS.LuaUtil.GetRotation(self.LObject.physics_object_id)
		self.hitObjects = CS.LuaUtil.PhysicsOverlapBox(cx + velocity_x, cy + velocity_y, cz + velocity_z, ex, ey, ez, rx, ry, rz, rw, self.filter)

		-- local contactColliders = CS.Tools.Instance:PhysicsOverlapBoxNonAlloc(self.collider.bounds.center + velocity, self.collider.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

		-- local contactColliders = CS.LuaUtil.PhysicsBoxCastNonAlloc(self.collider.bounds.center, self.collider.bounds.extents, velocity.normalized, self.gameObject.transform.rotation, velocity.magnitude, self.filter.layerMask.value)

		-- 最终位移坐标
		local finalOffset_x = velocity_x
		local finalOffset_y = velocity_y
		local finalOffset_z = velocity_z
		for i = 0, self.hitObjects.Length - 1, 1 do
			local k = self.hitObjects[i]
			if k ~= nil and k.attachedRigidbody ~= self.collider.attachedRigidbody then
				-- print(k.name)
				local up, down, left, right, above, under = false, false, false, false, false, false

				local go = k.attachedRigidbody.gameObject

				if go.name == "test" then -- 如果是地图块
					local name = utils.split(k.name, ",")
					local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit


					if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
						up = true
					end
					if num & 2 == 2 then --位操作
						down = true
					end
					if num & 4 == 4 then --位操作
						left = true
					end
					if num & 8 == 8 then --位操作
						right = true
					end
					if num & 16 == 16 then --位操作
						above = true
					end
					if num & 32 == 32 then --位操作
						under = true
					end
				elseif go.name ~= "test" then -- and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go -- 是游戏object，则只允许左右进行碰撞
					local object2 = utils.getObject(go:GetInstanceID())
					if object2 == nil then
					else
						if self.LObject.team ~= object2.team then
						-- local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

						-- if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
							up = true
							down = true
							left = true
							right = true
						-- end
						-- above = true
						-- under = true
						end

						if self.bounciness == 999 then
							if self.LObject.team ~= object2.team or (self.LObject.team == object2.team and object2._bit | 1 ~= object2._bit) then
								if type(self.hitObject) ~= "table" then
									self.hitObject = {}
								end

								if self.hitObject[k:GetInstanceID()] == nil then

									-- print("asdasd")

									self.hitObject[k:GetInstanceID()] = true
									-- self.isHit = 16

									local rcx, rcy, rcz = CS.LuaUtil.GetColliderBoundsCenter(k:GetInstanceID())

									local xx =  (rcx + 0) - cx
									local yy =  (rcy + 5) - cy
									local zz =  (rcz + 0) - cz
									local length = utils.GetVector3Module(xx, yy, zz) -- 射线的长度
									local dx = xx / length -- 方向
									local dy = yy / length -- 方向
									local dz = zz / length -- 方向

									-- print(object2.state, dx)
				
				
									if object2._bit | 1 ~= object2._bit then
										ecs.addComponent(object2._eid, "Active")
										ecs.applyEntity(object2._eid)
				
										object2.velocity.x = object2.velocity.x + dx * 10
										object2.velocity.z = object2.velocity.z + dz * 10
										object2.velocity.y = object2.velocity.y + dy * 5

										-- object2.velocity.x = object2.velocity.x + xx
										-- object2.velocity.z = object2.velocity.z + zz
										-- object2.velocity.y = object2.velocity.y + yy
										object2.rotation_velocity = 0
									else
										object2.velocity.x = object2.velocity.x + dx * 10 / 10
										object2.velocity.z = object2.velocity.z + dz * 10 / 10
										object2.velocity.y = object2.velocity.y + dy * 5 / 10

										-- object2.velocity.x = object2.velocity.x + xx / 10
										-- object2.velocity.z = object2.velocity.z + zz / 10
										-- object2.velocity.y = object2.velocity.y + yy / 10
									end
								end
							end
						end
					end
				else
					-- return 1, false, false, 1, elseArray
				end

				if (up or down or left or right or above or under) and self.bounciness ~= 999 then
						
					local m_x, m_y, m_z = utils.getBoundsIntersectsArea222(cx, cy, cz, ex, ey, ez, velocity_x, velocity_y, velocity_z, k:GetInstanceID())
					if utils.GetVector3Module(m_x, m_y, m_z) > 0 then
				
						local offset_x = nil
						local offset_y = nil
						local offset_z = nil

						if (left or right) and (up or down) then
							if m_x > m_y then
								m_x = 0
							else
								m_y = 0
							end
						end

						if velocity_x > 0 then
							offset_x = velocity_x - m_x
						else
							offset_x = velocity_x + m_x
						end

						if velocity_y > 0 then
							offset_y = velocity_y - m_y
						else
							offset_y = velocity_y + m_y
						end

						if velocity_z > 0 then
							offset_z = velocity_z - m_z
						else
							offset_z = velocity_z + m_z
						end

						-- 留下最小位移坐标
						if left or right then
							if velocity_x > 0 then
								if offset_x < finalOffset_x then
									finalOffset_x = offset_x
								end
							else
								if offset_x > finalOffset_x then
									finalOffset_x = offset_x
								end
							end

							isWall_leftright = 1

						end

						if up or down then

							if velocity_y > 0 then
								if offset_y < finalOffset_y then
									finalOffset_y = offset_y
								end
							else
								if offset_y > finalOffset_y then
									finalOffset_y = offset_y
								end
							end

							isWall_updown = 1

						end

						if (left or right) and (up or down) then
							if m_x > m_y then
								isWall_leftright = -1
							else
								isWall_updown = -1
							end
						end

						if above or under then

							if velocity_z > 0 then
								if offset_z < finalOffset_z then
									finalOffset_z = offset_z
								end
							else
								if offset_z > finalOffset_z then
									finalOffset_z = offset_z
								end
							end

							if isGround == -1 and m_z > 0 then
								isGround = 1 << tonumber(0)
							end
						end
					end
				end
			end
		end
		-- 更新自身位置
		-- self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, finalOffset_y, finalOffset_z)

		local dt = 1
		CS.LuaUtil.RigidbodyMovePosition(self.collider.attachedRigidbody, finalOffset_x * dt, finalOffset_y * dt, finalOffset_z * dt)

		-- if self.bounciness > 0 then
		-- 	if isWall_leftright == 1 then
		-- 		self.LObject.velocity.x = -self.LObject.velocity.x * self.bounciness
		-- 	end
		-- 	if isWall_updown == 1 then
		-- 		self.LObject.velocity.y = -self.LObject.velocity.y * self.bounciness
		-- 	end
		-- 	if isGround == 1 then
		-- 		self.LObject.velocity.z = -self.LObject.velocity.z * self.bounciness
		-- 	end
		-- 	if isWall_leftright == 1 or isWall_updown == 1 or isGround == 1 then
		-- 		self.LObject.rotation_velocity = (CS.Tools.Instance:RandomRangeInt(0, 2) * 2 - 1) * self.LObject.rotation_velocity * self.bounciness
		-- 	end
		-- end
	end
	return isGround
end

function LColliderBDY:Test()
	local velocity_x = self.LObject.velocity.x * CS.UnityEngine.Time.deltaTime * self.LObject.speed
	local velocity_y = self.LObject.velocity.y * CS.UnityEngine.Time.deltaTime * self.LObject.speed
	local velocity_z = self.LObject.velocity.z * CS.UnityEngine.Time.deltaTime * self.LObject.speed

	local cx, cy, cz = CS.LuaUtil.GetColliderBoundsCenter(self.collider_id)
	local ex, ey, ez = CS.LuaUtil.GetColliderBoundsExtents(self.collider_id)
	

	if self.isRayCast == 0 then
		local rx, ry, rz, rw = CS.LuaUtil.GetRotation(self.LObject.physics_object_id)
		self.hitObjects = CS.LuaUtil.PhysicsOverlapBox(cx + velocity_x, cy + velocity_y, cz + velocity_z, ex, ey, ez, rx, ry, rz, rw, self.filter, self.queryTriggerInteraction)

	else
		local rx, ry, rz = CS.LuaUtil.RigidbodyGetPosition(self.LObject.rigidbody)
		local length = utils.GetVector3Module(velocity_x, velocity_y, velocity_z) -- 射线的长度
		local dx = velocity_x / length -- 方向
		local dy = velocity_y / length -- 方向
		local dz = velocity_z / length -- 方向

		CS.LuaUtil.DrawLine(rx, ry, rz, rx + velocity_x, ry + velocity_y, rz + velocity_z, 0, 0, 1, 1)
		-- CS.LuaUtil.DrawLine(rx, ry + rz, rz, rx + velocity_x, ry + velocity_y + rz + velocity_z, rz + velocity_z, 0, 0, 1, 1)

		self.hitObjects = CS.LuaUtil.PhysicsRaycastAll(rx, ry, rz, dx, dy, dz, length, self.filter, self.queryTriggerInteraction)
	end
end

function LColliderBDY:Test2()
	local isGround = -1
	local isWall_leftright = -1
	local isWall_updown = -1

	local velocity_x = self.LObject.velocity.x * CS.UnityEngine.Time.deltaTime * self.LObject.speed
	local velocity_y = self.LObject.velocity.y * CS.UnityEngine.Time.deltaTime * self.LObject.speed
	local velocity_z = self.LObject.velocity.z * CS.UnityEngine.Time.deltaTime * self.LObject.speed

	local cx, cy, cz = CS.LuaUtil.GetColliderBoundsCenter(self.collider_id)
	local ex, ey, ez = CS.LuaUtil.GetColliderBoundsExtents(self.collider_id)

	-- 最终位移坐标
	local finalOffset_x = velocity_x
	local finalOffset_y = velocity_y
	local finalOffset_z = velocity_z
	for i = 0, self.hitObjects.Length - 1, 1 do
		local k = self.hitObjects[i]
		if k ~= nil and k.attachedRigidbody ~= self.collider.attachedRigidbody then
			-- print(k.name)
			local up, down, left, right, above, under = false, false, false, false, false, false

			local go = k.attachedRigidbody.gameObject

			if go.name == "test" then -- 如果是地图块
				local name = utils.split(k.name, ",")
				local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit


				if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
					up = true
				end
				if num & 2 == 2 then --位操作
					down = true
				end
				if num & 4 == 4 then --位操作
					left = true
				end
				if num & 8 == 8 then --位操作
					right = true
				end
				if num & 16 == 16 then --位操作
					above = true
				end
				if num & 32 == 32 then --位操作
					under = true
				end
			elseif go.name ~= "test" then -- and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go -- 是游戏object，则只允许左右进行碰撞
				local object2 = utils.getObject(go:GetInstanceID())
				if object2 == nil then
				else
					-- if self.LObject.team ~= object2.team then
					-- local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

					-- if not string.find(LC.layers, string.match(self.collider.name, "%[(%d+)%]")) then
						up = true
						down = true
						left = true
						right = true
					-- end
					-- above = true
					-- under = true

						-- print(self.LObject.state)
					-- end
				end
			else
				-- return 1, false, false, 1, elseArray
			end

			if (up or down or left or right or above or under) then
					
				local m_x, m_y, m_z = utils.getBoundsIntersectsArea222(cx, cy, cz, ex, ey, ez, velocity_x, velocity_y, velocity_z, k:GetInstanceID())
				if utils.GetVector3Module(m_x, m_y, m_z) > 0 then
			
					local offset_x = nil
					local offset_y = nil
					local offset_z = nil

					if (left or right) and (up or down) then
						if m_x > m_y then
							m_x = 0
						else
							m_y = 0
						end
					end

					if velocity_x > 0 then
						offset_x = velocity_x - m_x
					else
						offset_x = velocity_x + m_x
					end

					if velocity_y > 0 then
						offset_y = velocity_y - m_y
					else
						offset_y = velocity_y + m_y
					end

					if velocity_z > 0 then
						offset_z = velocity_z - m_z
					else
						offset_z = velocity_z + m_z
					end

					-- 留下最小位移坐标
					if left or right then
						if velocity_x > 0 then
							if offset_x < finalOffset_x then
								finalOffset_x = offset_x
							end
						else
							if offset_x > finalOffset_x then
								finalOffset_x = offset_x
							end
						end

						isWall_leftright = 1

					end

					if up or down then

						if velocity_y > 0 then
							if offset_y < finalOffset_y then
								finalOffset_y = offset_y
							end
						else
							if offset_y > finalOffset_y then
								finalOffset_y = offset_y
							end
						end

						isWall_updown = 1

					end

					if (left or right) and (up or down) then
						if m_x > m_y then
							isWall_leftright = -1
						else
							isWall_updown = -1
						end
					end

					if above or under then

						if velocity_z > 0 then
							if offset_z < finalOffset_z then
								finalOffset_z = offset_z
							end
						else
							if offset_z > finalOffset_z then
								finalOffset_z = offset_z
							end
						end

						if isGround == -1 and m_z > 0 then
							isGround = 1 << tonumber(0)
						end
					end
				end
			end
		end
	end

	if self.bounciness > 0 then
		if isWall_leftright == 1 then
			self.LObject.velocity.x = -self.LObject.velocity.x * self.bounciness
		end
		if isWall_updown == 1 then
			self.LObject.velocity.y = -self.LObject.velocity.y * self.bounciness
		end
		if isGround == 1 then
			self.LObject.velocity.z = -self.LObject.velocity.z * self.bounciness
		end
		if isWall_leftright == 1 or isWall_updown == 1 or isGround == 1 then
			self.LObject.rotation_velocity = (CS.Tools.Instance:RandomRangeInt(0, 2) * 2 - 1) * self.LObject.rotation_velocity * self.bounciness
		end
	end

	return isGround, finalOffset_x, finalOffset_y, finalOffset_z
end

-- function LColliderBDY:BDYFixedUpdate()

-- end

-- function LColliderBDY:BDYFixedUpdate2D3D(velocity, weight)
-- 	local isGround = nil
-- 	local isCeiling = false
-- 	local isWall = false
-- 	local isElse = 1
-- 	local elseArray = {}

-- 	-- local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider.bounds.center, self.collider.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

-- 	-- -- 最终位移坐标
-- 	-- local finalOffset_y = 0
-- 	-- for i = 0, contactColliders.Length - 1, 1 do
-- 	-- 	local k = contactColliders[i]
-- 	-- 	if k.attachedRigidbody ~= self.collider.attachedRigidbody then
-- 	-- 		-- print(k.name)
-- 	-- 		local above, under = false, false

-- 	-- 		local go = k.attachedRigidbody.gameObject
-- 	-- 		if go.name == "test" then -- 如果是地图块
-- 	-- 			local name = utils.split(k.name, ",")
-- 	-- 			local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit

-- 	-- 			if num & 16 == 16 then --位操作
-- 	-- 				above = true
-- 	-- 			end
-- 	-- 			if num & 32 == 32 then --位操作
-- 	-- 				under = true
-- 	-- 			end
-- 	-- 		else
-- 	-- 			-- return 1, false, false, 1, elseArray
-- 	-- 		end

-- 	-- 		if above or under then

-- 	-- 			local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider.bounds, k.bounds)
-- 	-- 			if menseki.magnitude > 0 then -- 无视多少面积设置

-- 	-- 				-- 算2个collider之间距离，主要是为了法线
-- 	-- 				-- local cd2d = self.collider:Distance(k)

-- 	-- -- ~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
-- 	-- -- ~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
-- 	-- 				-- local a = self.collider.gameObject.transform.position
-- 	-- 				-- local b = k.gameObject.transform.position
-- 	-- 				-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
-- 	-- 				-- local normal = -menseki.normalized
-- 	-- 				-- local c = a +  normal
-- 	-- 				-- local d = b +  normal
-- 	--  				-- CS.UnityEngine.Debug.DrawLine(a, c, CS.UnityEngine.Color.red)
-- 	-- 				-- CS.UnityEngine.Debug.DrawLine(b, d, CS.UnityEngine.Color.yellow)
-- 	-- 				-- print(normal)

-- 	-- 				-- 做碰撞法线与行进方向的点积
-- 	-- 				-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- 没用到，有需要可以自己看情况加

-- 	-- 				local offset_y = 0

-- 	-- 				local velo_nor2 = CS.UnityEngine.Vector2(velocity.x, velocity.y).normalized

-- 	-- 				if self.collider.bounds.center.y > k.bounds.center.y then
-- 	-- 					if above and CS.UnityEngine.Vector2.Dot(velo_nor2, CS.UnityEngine.Vector2(0, 1)) <= 0 then
-- 	-- 						offset_y = menseki.y
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if under and CS.UnityEngine.Vector2.Dot(velo_nor2, CS.UnityEngine.Vector2(0, -1)) <= 0 then
-- 	-- 						offset_y = -menseki.y
-- 	-- 					end
-- 	-- 				end

-- 	-- 				-- 留下最小位移坐标

-- 	-- 				if velocity.y > 0 then
-- 	-- 					if offset_y < finalOffset_y then
-- 	-- 						finalOffset_y = offset_y
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if offset_y > finalOffset_y then
-- 	-- 						finalOffset_y = offset_y
-- 	-- 					end
-- 	-- 				end


-- 	-- -- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
-- 	-- -- 					local rate = weight / object2["weight"] / 2
-- 	-- -- 					if rate > 1 then
-- 	-- -- 						rate = 1
-- 	-- -- 					end
-- 	-- -- 					local vOffset = (object2.velocity.x - velocity.x) * rate
-- 	-- -- --~ 					object2.velocity.x = object2.velocity.x - vOffset
-- 	-- -- 					-- print(object2)
-- 	-- -- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
-- 	-- -- 				end

-- 	-- 				if go.name == "test" then -- 判断是不是撞到地面，这样写不好，以后再优化
-- 	-- 					-- if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
-- 	-- 					-- 	isWall = true
-- 	-- 					-- end
-- 	-- 					if finalOffset_y > 0 then
-- 	-- 						local id = string.match(k.name, "%[(%d+)%]")

-- 	-- 						if id then
-- 	-- 							if isGround ~= nil then
-- 	-- 								isGround = isGround | 1 << tonumber(id)
-- 	-- 							else
-- 	-- 								isGround = 1 << tonumber(id)
-- 	-- 							end
-- 	-- 						end

-- 	-- 					-- elseif finalOffset_y < 0 then
-- 	-- 					-- 	isCeiling = true
-- 	-- 					end
-- 	-- 				end
-- 	-- 			end
-- 	-- 		else
-- 	-- 			local id = string.match(k.name, "%[(%d+)%]")
-- 	-- 			if id then
-- 	-- 				isElse = isElse | 1 << tonumber(id)
-- 	-- 			end
-- 	-- 			if elseArray[id] == nil then
-- 	-- 				elseArray[id] = {}
-- 	-- 			end
-- 	-- 			elseArray[id][k:GetInstanceID()] = k
-- 	-- 		end
-- 	-- 	end
-- 	-- end

-- 	-- -- 更新自身位置
-- 	-- -- self.collider.attachedRigidbody.position = self.collider.attachedRigidbody.position + CS.UnityEngine.Vector3(0, finalOffset_y, 0)

-- 	local contactColliders = CS.UnityEngine.Physics.OverlapBox(self.collider2.bounds.center, self.collider2.bounds.extents, self.gameObject.transform.rotation, self.filter.layerMask.value)

-- 	-- 最终位移坐标
-- 	local finalOffset_x = 0
-- 	local finalOffset_z = 0
-- 	for i = 0, contactColliders.Length - 1, 1 do
-- 		local k = contactColliders[i]
-- 		if k.attachedRigidbody ~= self.collider2.attachedRigidbody then
-- 			-- print(k.name)
-- 			local up, down, left, right = false, false, false, false

-- 			local go = k.attachedRigidbody.gameObject
-- 			local object2 = utils.getObject(go:GetInstanceID())
-- 			if go.name == "test" then -- 如果是地图块
-- 				local name = utils.split(k.transform.parent.name, ",")
-- 				local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit
-- 				if num ~= nil then
-- 					if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
-- 						up = true
-- 					end
-- 					if num & 2 == 2 then --位操作
-- 						down = true
-- 					end
-- 					if num & 4 == 4 then --位操作
-- 						left = true
-- 					end
-- 					if num & 8 == 8 then --位操作
-- 						right = true
-- 					end
-- 				end
-- 			-- elseif go.name ~= "test" and object2 ~= nil and not object2["isCatched"] and self.collider2.attachedRigidbody.gameObject ~= go then -- 是游戏object，则只允许左右进行碰撞

-- 			-- 	local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

-- 			-- 	if not string.find(LC.layers, string.match(self.collider2.name, "%[(%d+)%]")) then
-- 			-- 		up = true
-- 			-- 		down = true
-- 			-- 		left = true
-- 			-- 		right = true
-- 			-- 	end
-- 			-- else
-- 				-- return 1, false, false, 1, elseArray
-- 			end

-- 			if up or down or left or right then

-- 				local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider2.bounds, k.bounds)
-- 				if menseki.magnitude > 0 then -- 无视多少面积设置

-- 					-- 算2个collider之间距离，主要是为了法线
-- 					-- local cd2d = self.collider:Distance(k)

-- 	-- ~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
-- 	-- ~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
-- 					-- local a = self.collider.gameObject.transform.position
-- 					-- local b = k.gameObject.transform.position
-- 					-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
-- 					-- local normal = -menseki.normalized
-- 					-- local c = a +  normal
-- 					-- local d = b +  normal
-- 	 				-- CS.UnityEngine.Debug.DrawLine(a, c, CS.UnityEngine.Color.red)
-- 					-- CS.UnityEngine.Debug.DrawLine(b, d, CS.UnityEngine.Color.yellow)
-- 					-- print(normal)

-- 					-- 做碰撞法线与行进方向的点积
-- 					-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- 没用到，有需要可以自己看情况加

-- 					local offset_x = 0
-- 					local offset_z = 0

-- 					local velo_nor = CS.UnityEngine.Vector2(velocity.x, velocity.z).normalized

-- 					-- 左移，右移
-- 					if self.collider2.bounds.center.x < k.bounds.center.x then
-- 						if left and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- 如果碰撞朝向与行进方向相反，则求出位移坐标
-- 							offset_x = -menseki.x
-- 						end
-- 					else
-- 						if right and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(1, 0)) <= 0 then
-- 							offset_x = menseki.x
-- 						end
-- 					end
-- 					-- 上移，下移
-- 					if self.collider2.bounds.center.y > k.bounds.center.y then
-- 						if up and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, 1)) <= 0 then
-- 							-- offset_z = menseki.y - (self.collider2.bounds.center.z - k.bounds.center.z)
-- 							offset_z = menseki.y
-- 						end
-- 					else
-- 						if down and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, -1)) <= 0 then
-- 							-- offset_z = -(menseki.y + (self.collider2.bounds.center.z - k.bounds.center.z))
-- 							offset_z = -menseki.y
-- 						end
-- 					end

-- 					-- if (left or right) and (up or down) then
-- 					-- 	local a_x = math.abs(normal.x)
-- 					-- 	local a_z = math.abs(normal.y)
-- 					-- 	if a_x > a_z then
-- 					-- 		offset_x = 0
-- 					-- 	else
-- 					-- 		offset_z = 0
-- 					-- 	end
-- 					-- end

-- 					if (left or right) and (up or down) then
-- 						if menseki.x > menseki.y then
-- 							offset_x = 0
-- 						else
-- 							offset_z = 0
-- 						end
-- 					end


-- 					-- 留下最小位移坐标
-- 					if velocity.x > 0 then
-- 						if offset_x < finalOffset_x then
-- 							finalOffset_x = offset_x
-- 						end
-- 					else
-- 						if offset_x > finalOffset_x then
-- 							finalOffset_x = offset_x
-- 						end
-- 					end

-- 					if velocity.z > 0 then
-- 						if offset_z < finalOffset_z then
-- 							finalOffset_z = offset_z
-- 						end
-- 					else
-- 						if offset_z > finalOffset_z then
-- 							finalOffset_z = offset_z
-- 						end
-- 					end

-- 	-- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
-- 	-- 					local rate = weight / object2["weight"] / 2
-- 	-- 					if rate > 1 then
-- 	-- 						rate = 1
-- 	-- 					end
-- 	-- 					local vOffset = (object2.velocity.x - velocity.x) * rate
-- 	-- --~ 					object2.velocity.x = object2.velocity.x - vOffset
-- 	-- 					-- print(object2)
-- 	-- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
-- 	-- 				end

-- 					-- if go.name == "test" then -- 判断是不是撞到地面，这样写不好，以后再优化
-- 					-- 	-- if finalOffset_x ~= 0 and (normal.x == -1 or normal.x == 1) then
-- 					-- 	-- 	isWall = true
-- 					-- 	-- end
-- 					-- 	if finalOffset_y > 0 then
-- 					-- 		local id = string.match(k.name, "%[(%d+)%]")

-- 					-- 		if id then
-- 					-- 			if isGround ~= nil then
-- 					-- 				isGround = isGround | 1 << tonumber(id)
-- 					-- 			else
-- 					-- 				isGround = 1 << tonumber(id)
-- 					-- 			end
-- 					-- 		end

-- 					-- 	-- elseif finalOffset_y < 0 then
-- 					-- 	-- 	isCeiling = true
-- 					-- 	end
-- 					-- end
-- 				end
-- 			else
-- 				-- local id = string.match(k.name, "%[(%d+)%]")
-- 				-- if id then
-- 				-- 	isElse = isElse | 1 << tonumber(id)
-- 				-- end
-- 				-- if elseArray[id] == nil then
-- 				-- 	elseArray[id] = {}
-- 				-- end
-- 				-- elseArray[id][k:GetInstanceID()] = k
-- 			end
-- 		end
-- 	end

	
-- 	-- -- 检测和什么碰，2d碰撞范围一般比实际要大，因为AABB要大一点，为了精确碰撞，需要自己实现
-- 	-- local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider2, self.filter) -- 这个函数其实Collider2D.OverlapCollider，用来手动检测碰撞，这边因为lua的缘故封装了一下

-- 	-- -- 最终位移坐标
-- 	-- local finalOffset_x = 0
-- 	-- local finalOffset_z = 0
-- 	-- for p, k in pairs(contactColliders) do

-- 	-- 	if self.collider2.bounds:Intersects(k.bounds) then

-- 	-- 		local up, down, left, right = false, false, false, false

-- 	-- 		-- local go = k.attachedRigidbody.gameObject
-- 	-- 		local go = k.gameObject.transform.parent.gameObject
-- 	-- 		local object2 = utils.getObject(go:GetInstanceID())
-- 	-- 		-- if go.name == "test" then -- 如果是地图块
-- 	-- 		if string.find(go.name, "block") ~= nil then
-- 	-- 			-- print(go.name)
-- 	-- 			local name = utils.split(go.name, ",")
-- 	-- 			local num = tonumber(name[#name]) -- 地图块最后一个数字作为bit


-- 	-- 			if num & 1 == 1 then --位操作，算出这个方块朝哪个方向进行碰撞，一个方块可以有多个碰撞方向，这部分随意设计，只需要能知道这个collider的判定方向，用layermask什么都行
-- 	-- 				up = true
-- 	-- 			end
-- 	-- 			if num & 2 == 2 then --位操作
-- 	-- 				down = true
-- 	-- 			end
-- 	-- 			if num & 4 == 4 then --位操作
-- 	-- 				left = true
-- 	-- 			end
-- 	-- 			if num & 8 == 8 then --位操作
-- 	-- 				right = true
-- 	-- 			end
-- 	-- 			-- print("aaa")
-- 	-- 		elseif not string.find(go.name, "block") ~= nil and object2 ~= nil and not object2["isCatched"] and self.collider.attachedRigidbody.gameObject ~= go then -- 是游戏object，则只允许左右进行碰撞

-- 	-- 			-- local LC = object2.bodyArray_InstanceID[k:GetInstanceID()]

-- 	-- 			-- print(LC.layers)
-- 	-- 			-- if not string.find(LC.layers, string.match(self.collider2.name, "%[(%d+)%]")) then
-- 	-- 				up = true
-- 	-- 				down = true
-- 	-- 				left = true
-- 	-- 				right = true
-- 	-- 			-- end

-- 	-- 		else
-- 	-- 			-- return 1, false, false, 1, elseArray
-- 	-- 		end

-- 	-- 		if up or down or left or right then


-- 	-- 			local menseki, normal = utils.getBoundsIntersectsArea3D(self.collider2.bounds, k.bounds)
-- 	-- 			if menseki.magnitude > 0 then -- 无视多少面积设置

-- 	-- 				-- 算2个collider之间距离，主要是为了法线
-- 	-- 				-- local cd2d = self.collider2:Distance(k)

-- 	-- --~ 				local a =  CS.UnityEngine.Vector3(cd2d.pointA.x, cd2d.pointA.y, 0)
-- 	-- --~ 				local b =  CS.UnityEngine.Vector3(cd2d.pointB.x, cd2d.pointB.y, 0)
-- 	-- 				-- local normal =  -CS.UnityEngine.Vector3(cd2d.normal.x, cd2d.normal.y, 0)
-- 	-- --~ 				CS.UnityEngine.Debug.DrawLine(a, a + normal, CS.UnityEngine.Color.red)
-- 	-- --~ 				CS.UnityEngine.Debug.DrawLine(b, b + normal, CS.UnityEngine.Color.yellow)

-- 	-- 				-- 做碰撞法线与行进方向的点积
-- 	-- 				-- local projection = CS.UnityEngine.Vector2.Dot(velocity.normalized, normal) -- 没用到，有需要可以自己看情况加

-- 	-- 				local offset_x = 0
-- 	-- 				local offset_z = 0

-- 	-- 				local velo_nor = CS.UnityEngine.Vector2(velocity.x, velocity.z).normalized

-- 	-- 				-- 左移，右移
-- 	-- 				if self.collider2.bounds.center.x < k.bounds.center.x then
-- 	-- 					if left and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(-1, 0)) <= 0 then -- 如果碰撞朝向与行进方向相反，则求出位移坐标
-- 	-- 						offset_x = -menseki.x
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if right and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(1, 0)) <= 0 then
-- 	-- 						offset_x = menseki.x
-- 	-- 					end
-- 	-- 				end
-- 	-- 				-- 上移，下移
-- 	-- 				if self.collider2.bounds.center.y > k.bounds.center.y then
-- 	-- 					if up and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, 1)) <= 0 then
-- 	-- 						offset_z = menseki.y
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if down and CS.UnityEngine.Vector2.Dot(velo_nor, CS.UnityEngine.Vector2(0, -1)) <= 0 then
-- 	-- 						offset_z = -menseki.y
-- 	-- 					end
-- 	-- 				end



-- 	-- 				-- if (up or down) and (left or right) then -- 如果同时满足上下和左右方向同时存在的情况，则根据碰撞方向来筛选掉另一个轴的位移
-- 	-- 				-- 	offset_x = offset_x * math.abs(normal.x)
-- 	-- 				-- 	offset_z = offset_z * math.abs(normal.z)
-- 	-- 				-- end

-- 	-- 				if (left or right) and (up or down) then
-- 	-- 					local a_x = math.abs(normal.x)
-- 	-- 					local a_z = math.abs(normal.y)
-- 	-- 					if a_x < a_z then
-- 	-- 						offset_x = 0
-- 	-- 					else
-- 	-- 						offset_z = 0
-- 	-- 					end
-- 	-- 				end



-- 	-- 				-- 留下最小位移坐标
-- 	-- 				if velocity.x > 0 then
-- 	-- 					if offset_x < finalOffset_x then
-- 	-- 						finalOffset_x = offset_x
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if offset_x > finalOffset_x then
-- 	-- 						finalOffset_x = offset_x
-- 	-- 					end
-- 	-- 				end

-- 	-- 				if velocity.z > 0 then
-- 	-- 					if offset_z < finalOffset_z then
-- 	-- 						finalOffset_z = offset_z
-- 	-- 					end
-- 	-- 				else
-- 	-- 					if offset_z > finalOffset_z then
-- 	-- 						finalOffset_z = offset_z
-- 	-- 					end
-- 	-- 				end

-- 	-- 				-- print(finalOffset_x, finalOffset_z)

-- 	-- -- 				if velocity.x ~= 0 and object2 ~= nil and offset_x ~= 0 and object2.isWall == false then
-- 	-- -- 					local rate = weight / object2["weight"] / 2
-- 	-- -- 					if rate > 1 then
-- 	-- -- 						rate = 1
-- 	-- -- 					end
-- 	-- -- 					local vOffset = (object2.velocity.x - velocity.x) * rate
-- 	-- -- --~ 					object2.velocity.x = object2.velocity.x - vOffset
-- 	-- -- 					-- print(object2)
-- 	-- -- 					object2:invokeEvent("onForce", {velocity = CS.UnityEngine.Vector2(-vOffset, 0), compute = 1})
-- 	-- -- 				end
-- 	-- 			end
-- 	-- 		else
-- 	-- 			-- local id = string.match(k.name, "%[(%d+)%]")
-- 	-- 			-- if id then
-- 	-- 			-- 	isElse = isElse | 1 << tonumber(id)
-- 	-- 			-- end
-- 	-- 			-- if elseArray[id] == nil then
-- 	-- 			-- 	elseArray[id] = {}
-- 	-- 			-- end
-- 	-- 			-- elseArray[id][k:GetInstanceID()] = k
-- 	-- 		end
-- 	-- 	end
-- 	-- end

-- 	-- 更新自身位置
-- 	-- self.collider2.attachedRigidbody.position = self.collider2.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)
-- 	-- self.collider2.attachedRigidbody.position = self.collider2.attachedRigidbody.position + CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)

-- 	return isGround, isCeiling, isWall, isElse, elseArray, CS.UnityEngine.Vector3(finalOffset_x, 0, finalOffset_z)
-- end

LColliderATK = {damage = nil, frequency = nil, velocity = nil, fall = nil, defence = nil, ignoreObjects = nil, var = nil, isCatch = nil, action = nil, frame = nil, isHit = nil, hitObject = nil}
setmetatable(LColliderATK, LCollider)
LColliderATK.__index = LColliderATK
function LColliderATK:new(l, go, id)
	local self = {}
	self = LCollider:new(l, go, id)
	setmetatable(self, LColliderATK)

	self.frequency = nil
	self.damage = nil
	self.velocity = nil

	self.fall = nil
	self.defence = nil
	self.ignoreObjects = {}
	
	self.var = nil

	self.isCatch = nil
	self.action = nil
	self.frame = nil

	self.isHit = -1
	self.hitObject = nil
	return self
end

-- 设置collider
function LColliderATK:setCollider(dir, x, y, width, height, depth, flag, dmg, fal, def, f, dx, dy, ignoreFlag, v, action, frame)
	-- self.offset = CS.UnityEngine.Vector3((x + width / 2) / 100, -(y + height / 2) / 100, 0)
	-- if depth ~= nil then
	-- 	self.size = CS.UnityEngine.Vector3(depth / 100, height / 100, width / 100)
	-- else
	-- 	self.size = CS.UnityEngine.Vector3(width / 100, height / 100, width / 100)
	-- end
	-- self.collider.center = self.offset-- * dir
	-- self.collider.size = self.size

	self.filter = CS.UnityEngine.ContactFilter2D()
	self.filter.useLayerMask = true
	self.filter.useTriggers = true
	local lll = CS.UnityEngine.LayerMask()
	lll.value = lll.value | 1 << 16
	self.filter.layerMask = lll
	-- self.collider.isTrigger = true

	self.damage = dmg
	self.fall = fal
	self.defence = def
	self.frequency = f
	-- self.velocity = CS.UnityEngine.Vector2(dx, dy)

	if ignoreFlag then
		self.ignoreObjects = {}
	end

	self.var = v

	if flag then
		if flag & 1 == 1 then
			self.isDefence = true
		end
		if flag & 2 == 2 then
			self.isCatch = true
		end
	end
	self.action = action
	self.frame = frame

	if width == 1 and height == 1 then
		self.isRayCast = true
	end
end

-- 检测攻击
function LColliderATK:ATKFixedUpdate(dir, myObj)
	local ishit = false

	if self.frequency > 0 then -- 攻击间隔为0的时候，只对对象攻击一次
		for i, v in pairs(self.ignoreObjects) do
			v.count = v.count + 1
		end
	end

	local contactColliders = CS.Tools.Instance:Collider2DOverlapCollider(self.collider, self.filter)

	for p, k in pairs(contactColliders) do
		local iId = k.attachedRigidbody.gameObject:GetInstanceID()
		local object = utils.getObject(iId)
		if k.isTrigger and self.collider.bounds:Intersects(k.bounds) and object ~= myObj then -- 是trigger，相交，不是自己
			if self.ignoreObjects[iId] == nil or self.ignoreObjects[iId].count >= self.frequency then -- 如果不在忽视列表里，或计数已经超过攻击间隔
				if object ~= nil then

					local s = false


					local cd2d = self.collider:Distance(k)
					local sparkPosition = CS.UnityEngine.Vector2(cd2d.pointA.x + cd2d.pointB.x, cd2d.pointA.y + cd2d.pointB.y) / 2

					local menseki = utils.getBoundsIntersectsArea(self.collider.bounds, k.bounds)

					local LC = object.bodyArray_InstanceID[k:GetInstanceID()]

					if LC.isDefence and object.direction.x ~= dir.x and not self.isDefence then -- 对方防御状态且不是从背后攻击且这一击不是防御不可得的
						
						if object["defencing"] + self.defence >= 70 or object["HP"] - self.damage <= 0 then -- 如果这一击破防了或者对方死了
							if self.isCatch then
								-- object.vars["isCatched"] = true

								-- object.vars["defencing"] = object.vars["defencing"] + self.defence
								-- if object.vars["defencing"] > object.vars["maxDefencing"] then
								-- 	object.vars["defencing"] = object.vars["maxDefencing"]
								-- end
								-- table.insert(myObj.catchedObjects, object)

								-- object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_4", frame = 0, kind = 3})

								-- myObj:addEvent("Attack", 0, 1, {id = self.id, x = 0, y = 0, width = 0, height = 0})
								
								-- myObj:addEvent("Warp", 0, 1, {action = self.action, frame = self.frame})
								-- s = true
							else
								if object["falling"] + self.fall >= 70 then
									object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
								else
									object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
								end
								object:invokeEvent("onHurt", {damage = self.damage, fall = self.fall, defence = self.defence, attacker = myObj, var = self.var})
								object:invokeEvent("onForce", {velocity = self.velocity * dir, compute = 0})
								object:invokeEvent("onInjured", {dir = dir.x})
							end
						else
							object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 2, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_3", frame = 0, kind = 3})
							object:invokeEvent("onHurt", {damage = self.damage / 100, fall = 0, defence = self.defence, attacker = myObj, var = self.var})
							object:invokeEvent("onForce", {velocity = self.velocity * dir / 10, compute = 0})
						end
						
					else
						if self.isCatch then
							-- object.vars["isCatched"] = true

							-- table.insert(myObj.catchedObjects, object)

							-- object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_4", frame = 0, kind = 3})

							-- myObj:addEvent("Attack", 0, 1, {id = self.id, x = 0, y = 0, width = 0, height = 0})
							
							-- myObj:addEvent("Warp", 0, 1, {action = self.action, frame = self.frame})
							-- s = true
						else
							-- if object.vars["falling"] + self.fall >= 70 or object.vars["HP"] - self.damage <= 0 then
							-- 	object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
							-- else
							-- 	object:addEvent("Object", 0, 1, {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
							-- end

							-- object:addEvent("Hurt", 0, 1, {damage = self.damage, fall = self.fall, defence = 0, attacker = myObj, var = self.var})
							-- object:addEvent("Force", 0, 1, {velocity = self.velocity * dir, compute = 0})
							-- object:addEvent("Injured", 0, 1, {dir = dir.x})

							if object["falling"] + self.fall >= 70 or object["HP"] - self.damage <= 0 then
								object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark_b", frame = 0, kind = 3})
							else
								object:invokeEvent("onObject", {isWorldPosition = true, x = sparkPosition.x + math.random() * menseki.x / 2 - menseki.x / 4, y = sparkPosition.y + math.random() * menseki.x / 2 - menseki.y / 4, action = "spark", frame = 0, kind = 3})
							end

							object:invokeEvent("onHurt", {damage = self.damage, fall = self.fall, defence = 0, attacker = myObj, var = self.var})
							object:invokeEvent("onForce", {velocity = self.velocity * dir, compute = 0})
							object:invokeEvent("onInjured", {dir = dir.x})
						end
					end

					ishit = true

					if self.ignoreObjects[iId] == nil then
						self.ignoreObjects[iId] = {count = 0}
					else
						self.ignoreObjects[iId].count = 0
					end

					if s then
						break
					end
				end
			end
		end
	end


	return ishit
end


function LColliderATK:ATKFixedUpdate()
	-- self.isHit = -1
	-- local ishit = false

	-- if self.frequency > 0 then -- 攻击间隔为0的时候，只对对象攻击一次
	-- 	for i, v in pairs(self.ignoreObjects) do
	-- 		v.count = v.count + 1
	-- 	end
	-- end

	local rx, ry, rz = CS.LuaUtil.RigidbodyGetPosition(self.LObject.rigidbody)

	local offset = CS.UnityEngine.Vector3(rx - self.LObject.oriPos.x, ry - self.LObject.oriPos.y, rz - self.LObject.oriPos.z)

	-- print(offset)

	local length = offset.magnitude -- 射线的长度
	local direction = offset.normalized -- 方向
	-- RaycastHit2D[] hitinfo;
	-- local hitinfo = CS.UnityEngine.Physics2D.RaycastAll(CS.UnityEngine.Vector2(self.oriPos.x, self.oriPos.y), CS.UnityEngine.Vector2(direction.x, direction.y), length) -- 在两个位置之间发起一条射线，然后通过这条射线去检测有没有发生碰撞

	-- local hitinfo = CS.Tools.Instance:PhysicsRaycastAll(self.oriPos, direction, self.length, 15)
	-- -- print(hitinfo.Length)

	local oriPos = CS.UnityEngine.Vector3(self.LObject.oriPos.x, self.LObject.oriPos.y, self.LObject.oriPos.z)

	-- CS.UnityEngine.Debug.DrawLine(oriPos, CS.UnityEngine.zero, CS.UnityEngine.Color.red)
	-- CS.UnityEngine.Debug.DrawLine(CS.UnityEngine.Vector3(rx, ry, rz), CS.UnityEngine.zero, CS.UnityEngine.Color.green)

	local hitinfo = CS.Tools.Instance:PhysicsRaycast(oriPos, direction, length, 1048575)
	-- if lr.positionCount > 2 then
	-- 	lr.positionCount = 2
	-- end
	if hitinfo.collider ~= nil then
		-- s = self.oriPos
		-- e = hitinfo.point
		-- lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
		-- lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))
		if hitinfo.collider.attachedRigidbody.gameObject.name ~= "test" then

			local iId = hitinfo.collider.attachedRigidbody.gameObject:GetInstanceID()
			local object = utils.getObject(iId)

			local LC = object.bodyArray_InstanceID[hitinfo.collider:GetInstanceID()]
			if LC ~= nil and LC.isDefence then
				-- local l2 = self.physics_object.transform.position - hitinfo.point
				-- local l3 = CS.UnityEngine.Vector3.Reflect(l2, hitinfo.normal)

				-- self.physics_object.transform.rotation = CS.UnityEngine.Quaternion.FromToRotation(l2, l3)
				-- self.velocity = self.physics_object.transform.rotation * self.velocity
				-- self.physics_object.transform.position = hitinfo.point

				-- object:invokeEvent("Sound", {sfx = v.sfx})
				-- self.frame = self.frame + 1
				self.hitObject = object
				self.isHit = 1
			else


				-- local comp = hitinfo.collider.attachedRigidbody.gameObject.transform.parent.gameObject:GetComponent(typeof(CS.XLuaTest.LuaComponent))
				-- local object = comp.scriptEnv.MainObject

				-- local spd = direction * 40 / 100

				-- object:invokeEvent("Hurt", {damage = 1, fall = 0, defence = self.defence, attacker = self, var = self.var})
				-- object:invokeEvent("Force", {velocity = spd, compute = 0})
				-- local object = utils.createObject(nil, 9, "blood_effect", 0, hitinfo.point.x, hitinfo.point.y, hitinfo.point.z, 0, 0, 0, 5)
				-- object:changeState("fire_effect")
				-- self.frame = 3
				self.hitObject = object
				self.isHit = 16
			end
		else
			-- local l2 = self.physics_object.transform.position - hitinfo.point
			-- local l3 = CS.UnityEngine.Vector3.Reflect(l2, hitinfo.normal)
			-- -- local e2 = l3 + hitinfo.point

			-- -- lr.positionCount = 3
			-- -- lr:SetPosition(2, CS.UnityEngine.Vector3(e2.x, e2.y + e2.z, e2.z))
			-- self.physics_object.transform.rotation = CS.UnityEngine.Quaternion.FromToRotation(l2, l3)
			-- self.velocity = self.physics_object.transform.rotation * self.velocity
			-- self.physics_object.transform.position = hitinfo.point

			-- self.frame = self.frame + 1
			-- self.frame = 3
			self.hitObject = nil
			self.isHit = 0
		end
	else
		-- s = self.oriPos
		-- e = self.physics_object.transform.position
		-- lr:SetPosition(0, CS.UnityEngine.Vector3(s.x, s.y + s.z, s.z))
		-- lr:SetPosition(1, CS.UnityEngine.Vector3(e.x, e.y + e.z, e.z))

		self.hitObject = nil
		self.isHit = -1
	end
end