require 'png'

function Stream:__init(param)
    local str = ""
    if (param.inputF ~= nil) then
	str = io.open(param.inputF, "rb"):read("*all")
    end
    if (param.input ~= nil) then
	str = param.input
    end

    for i=1,#str do
	self.data[i] = str:byte(i, i)
    end
end

function printProg(line, totalLine)
	print(line .. " of " .. totalLine)
end

img = pngImage("Example.png", printProg)
print("Width: " .. img.width)
print("Height: " .. img.height)
print("Depth: " .. img.depth)

print("Color of pixel (10, 10): " .. img:getPixel(10,10):format())
