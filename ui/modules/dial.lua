
local path = (...) and (...):gsub('%.dial$', '.button')
local slashPath = path:gsub("%.", "/")..".lua"
local Button
if love.filesystem.getInfo(slashPath) then
	Button = require(path)
else
	error(
[[jjui radial dial requires jjui button module.
Please visit github.com/JJSax/jjui-love2d and put button.lua at
]]..slashPath)
end
-- path, slashPath = nil, nil -- cleanup
collectgarbage("collect")

local dial = {}
dial.__index = dial
dial._version = "0.4.2"

local lg = love.graphics
local ORIGIN = {x = 0, y = 0}

local common = require((...):gsub('%.[^%.]*%.[^%.]+$', '')..".common")
-----------------------------------------------
---------------LOCAL FUNCTIONS-----------------
-----------------------------------------------



-----------------------------------------------
----------------CONSTRUCTORS-------------------
-----------------------------------------------

function dial.new(x, y, radius, options)
	-- this mostly is for singular positioning.
	options = options or {}
	options.x, options.y, options.radius = x, y, radius
	options.positionType = "center"
	options.buttons = {}
	options.parent = ORIGIN
	return setmetatable(options, dial)
end

function dial:newArcButton(angle1, angle2, options)

	local default = {
		outlineColor = {1,1,1,1},
		hoverOutlineColor = {1,1,1,1},
		pressedOutlineColor = {1,1,1,1},
		selectedOutlineColor = {1,1,1,1},
		hoverSelectedOutlineColor = {1,1,1,1},
		pressedSelectedOutlineColor = {1,1,1,1}
	}

	options = options or {}
	options.dial = self
	options.parent = self
	options = common.merge(default, options)

	table.insert(self.buttons, Button.newArcButton(0, 0, self.radius, angle1, angle2, options))
	return self.buttons[#self.buttons]
end

function dial:newAngleButton(angle, addAngle, options)
	return self:newArcButton(angle, angle + addAngle, options)
end

function dial:newWeightedButton(weight, options)
	assert(self.pie, "Requires dial.pie to be true.")
	assert(type(weight) == "number", "Param 1 needs to be of type number.")

	options = options or {}
	options.weight = weight

	local totalWeight = weight
	for k,v in ipairs(self.buttons) do
		totalWeight = totalWeight + v.weight
	end

	local dAngle = self.angle2 - self.angle1
	local curAngle = self.angle1

	local this = self:newArcButton(0, 0, options)

	for k,v in pairs(self.buttons) do
	-- print(self.angle1, self.angle2, dAngle, weight / totalWeight)
		v.angle1 = curAngle
		v.angle2 = curAngle + dAngle * (v.weight / totalWeight)
		curAngle = v.angle2
	end

	return this
end

-----------------------------------------------
----------------MAIN FUNCTIONS-----------------
-----------------------------------------------

function dial:update(dt)
	for k, button in ipairs(self.buttons) do
		button:update(dt)
	end
end

function dial:draw()
	for k, button in ipairs(self.buttons) do
		button:draw()
	end
end

function dial:mousepressed(x, y, key)
	for k, button in ipairs(self.buttons) do
		button:mousepressed(x, y, key)
	end
end
function dial:mousereleased(x, y, key)
	for k, button in ipairs(self.buttons) do
		button:mousereleased(x, y, key)
	end
end

function dial:keypressed(key)
	for k, button in ipairs(self.buttons) do
		button:keypressed(key)
	end
end
function dial:keyreleased(key)
	for k, button in ipairs(self.buttons) do
		button:keyreleased(key)
	end
end


-----------------------------------------------
---------------COMMON FUNCTIONS----------------
-----------------------------------------------

function dial:getCenter()
	if self.positionType == "center" then
		return self.x + self.parent.x, self.y + self.parent.y
	elseif self.positionType == "top left" then
		return self.x + self.parent.x + self.radius, self.y + self.parent.y + self.radius
	end
end

return dial
