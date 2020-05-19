
local p = 85

while p > 0 do
    if p & 1 == 1 then
        print()
    else
        print("fuck")
    end
    p = p >> 1
end