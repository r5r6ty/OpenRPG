require "LObject"

LObject_Gun = {
	ammo = nil,
	ammoMax = nil
	}
setmetatable(LObject_Gun, LObject)
LObject_Gun.__index = LObject_Gun
function LObject_Gun:new(parent, db, id, a, f, s, x, y, z, vx, vy, vz, k)
	local self = {}
	self = LObject:new(parent, db, id, a, f, s, x, y, z, vx, vy, vz, k)
	setmetatable(self, LObject_Gun)

	self.ammo = 30
	self.ammoMax = 30

	-- print("---test---")
    -- local fun = assert(load("function ttt(this) return this.ammo < this.ammoMax end return ttt", "test", "t", self))()
	-- print(fun(self))

	-- local fun2 = assert(load("function ttt(this) return this.ammo == this.ammoMax end return ttt", "test", "t", self))()	
	-- print(fun2(self))

	-- print(fun(self))

    -- print("----------")
	return self
end