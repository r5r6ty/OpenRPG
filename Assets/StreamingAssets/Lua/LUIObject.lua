

LUIObject = {UI_object = nil,
			rectTransform = nil,

			image_object = nil,
			image = nil,

			button_object = nil,
			button = nil,

			text_object = nil,
			text = nil,

			database = nil,
			id = nil,
			palette = nil,
			action = nil,
			delayCounter = nil,
			parent = nil,
			children = nil,
			root = nil,
			speed = nil,
			timeLine = nil,
			localTimeLine = nil,
			state = nil,
			direction = nil,
			velocity = nil}
LUIObject.__index = LUIObject
function LUIObject:new(parent, db, id, a, f, s, x, y, z, vx, vy, vz, k)
	local self = {}
	setmetatable(self, LUIObject)

	self.database = db
	self.id = id
	self.action = a
	self.frame = f
	self.delayCounter = 0

	self.root = self
	self.parent = self
	self.children = {}
	self.speed = 1
	self.timeLine = 0
	self.localTimeLine = 0
	self.state = s

	self.kind = k

	self.direction = CS.UnityEngine.Vector3(1, -1, 1)

	self.velocity = CS.UnityEngine.Vector3(vx, vy, vz)


	self.UI_object = CS.UnityEngine.GameObject("UI")
	self.UI_object.transform.localPosition = CS.UnityEngine.Vector3.zero
	self.UI_object.transform.localScale = CS.UnityEngine.Vector3.one -- CS.UnityEngine.Vector3(3, 3, 3) -- 

    self.rectTransform = self.UI_object:AddComponent(typeof(CS.UnityEngine.RectTransform))


	if parent == nil then
        self.rectTransform:SetParent(utils.getLCanvas().transform)
    else
		-- self.UI_object.transform:SetParent(p.transform)
		self.rectTransform:SetParent(parent.rectTransform)
	end
	
	self.rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
    -- self.rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
    self.rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
    self.rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
	self.rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

	if self.kind == 1 then
		self.image_object = CS.UnityEngine.GameObject("image")
		self.image_object.transform:SetParent(self.UI_object.transform)
		self.image_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		self.image_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		local rectTransform = self.image_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		self.image = self.image_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
		self.image.sprite = nil
		self.image.material = self.database.palettes_ui[1]
	elseif self.kind == 2 then
		self.text_object = CS.UnityEngine.GameObject("text")
		self.text_object.transform:SetParent(self.UI_object.transform)
		self.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		self.text_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		local rectTransform = self.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		self.text = self.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
		self.text.font = utils.getFont()
		self.text.fontSize = 12
		self.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

		-- self.text.material = self.database.palettes_ui[1]
	elseif self.kind == 3 then
		self.button_object = CS.UnityEngine.GameObject("button")
		self.button_object.transform:SetParent(self.UI_object.transform)
		self.button_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		self.button_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		local rectTransform = self.button_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		-- rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
		-- rectTransform.sizeDelta = CS.UnityEngine.Vector2(w, h)
		rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		self.image = self.button_object:AddComponent(typeof(CS.UnityEngine.UI.Image))
		self.image.sprite = nil
		self.image.material = self.database.palettes_ui[1]

		self.button = self.button_object:AddComponent(typeof(CS.UnityEngine.UI.Button))

		self:setButtonColor(127, 127, 127, 255, 240, 199, 50, 255, 191, 0, 0, 255)

		self.text_object = CS.UnityEngine.GameObject("text")
		self.text_object.transform:SetParent(self.button_object.transform)
		self.text_object.transform.localPosition = CS.UnityEngine.Vector3.zero
		self.text_object.transform.localScale = CS.UnityEngine.Vector3.one
	
		local rectTransform = self.text_object:AddComponent(typeof(CS.UnityEngine.RectTransform))
		rectTransform.anchoredPosition = CS.UnityEngine.Vector2(0, -15)
		rectTransform.sizeDelta = CS.UnityEngine.Vector2(100, 12)
		rectTransform.anchorMin = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.anchorMax = CS.UnityEngine.Vector2(0.5, 0.5)
		rectTransform.pivot = CS.UnityEngine.Vector2(0.5, 0.5)

		self.text = self.text_object:AddComponent(typeof(CS.UnityEngine.UI.Text))
		self.text.font = utils.getFont()
		self.text.fontSize = 12
		self.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter

		-- self.text.material = self.database.palettes_ui[1]

		-- utils.addEvent("OnClick", function(this, value)
		-- 	if this.image.rectTransform.anchoredPosition.x <= self.image.rectTransform.anchoredPosition.x then
		-- 		print("wocao")
		-- 	end
		-- end)

		-- self.button.onClick:AddListener(function()
		-- 	print("wocao")
		-- end)
	end

	return self
end

function LUIObject:setButtonColor(r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
    local cb = self.button.colors
    cb.normalColor = CS.UnityEngine.Color(r1 / 255, g1 / 255, b1 / 255, a1 / 255)
    cb.highlightedColor = CS.UnityEngine.Color(r2 / 255, g2 / 255, b2 / 255, a2 / 255)
    cb.selectedColor = CS.UnityEngine.Color(r3 / 255, g3 / 255, b3 / 255, a3 / 255)
    self.button.colors = cb
end

-- 显示信息
function LUIObject:displayInfo()

end

function LUIObject:changeState(state)
	local animation = nil
	if state ~= nil then
		self.state = state
		animation = self.database.characters_state[self.state].animation
	end
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
		return true
	end
	return false
end

function LUIObject:changeAnimation(animation)
	if animation ~= nil then
		self.action = animation
		self.delayCounter = 0
		self.timeLine = 0
	end
end

function LUIObject:SetParentAndRoot(object)
	if object ~= nil and (self.physics_object.transform.parent == nil or self.physics_object.transform.parent ~= self.physics_object.transform) then

		self.physics_object.transform:SetParent(object.physics_object.transform)
		self.rigidbody.isKinematic = true
		self.parent = object
		if object.parent ~= nil then
			self.root = object.parent
		else
			self.root = object
		end
		self.physics_object.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)

		self.team = object.team
		self.spriteRenderer.material = object.spriteRenderer.material
	end
end

function LUIObject:update()
	if self.action ~= nil then
		local c = self.database.animations[self.action].keyframes[self.delayCounter + 1]

		if c == nil then
			self.delayCounter = 0
			self.timeLine = 0
			self.localTimeLine = 0
			c = self.database.animations[self.action].keyframes[self.delayCounter + 1]
		end

		if self.timeLine >= c * (1 / 60) then

			local f = self.database.animations[self.action].eventQueue[c]
			self.delayCounter = self.delayCounter + 1
			self.localTimeLine = 0
			if f ~= nil then
				for i, v in ipairs(f) do
					self.database:invokeEvent(v.category, self, v)
				end
			end

		end
	end

	self:runStateUpdate()

	self.timeLine = self.timeLine + CS.UnityEngine.Time.deltaTime * self.speed
	self.localTimeLine = self.localTimeLine + CS.UnityEngine.Time.deltaTime * self.speed
end

function LUIObject:fixedupdate()
	self:runStateFxiedUpdate()
end

function LUIObject:runStateUpdate()
	if self.state ~= nil then
		local st = self.database.characters_state[self.state]
		for i, v in ipairs(st.update) do
			if v.func == nil or v.func(self) then
				for j, v2 in ipairs(v.test) do
					self.database:invokeEvent(v2.category, self, v2.json)
				end
			end
		end
	end
end

function LUIObject:runStateFxiedUpdate()
	local st = self.database.characters_state["global"]
	-- for i, v in ipairs(st.fixedUpdate) do
	-- 	if v.func == nil or v.func(self) then
	-- 		for j, v2 in ipairs(v.test) do
	-- 			self.database:invokeEvent(v2.category, self, v2.json)
	-- 		end
	-- 	end
	-- end

	if self.state ~= nil and self.state ~= "global" then
		st = self.database.characters_state[self.state]
		for i, v in ipairs(st.fixedUpdate) do
			if v.func == nil or v.func(self) then
				for j, v2 in ipairs(v.test) do
					self.database:invokeEvent(v2.category, self, v2.json)
				end
			end
		end
	end
end