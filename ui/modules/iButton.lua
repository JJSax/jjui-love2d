
-- Immediate mode button


local button = {}
button.__index = button

local lg = love.graphics
local outlineColor = {0.6, 0.6, 0.6, 1}
local textColor = {1,1,1,1}
local mousepressed = false
local uiRoot = (...):gsub('%.[^%.]*%.[^%.]+$', '')
local common = require(uiRoot..".common")
local geometry = require(uiRoot..".geometry")

local function setColor(...)
	local args = {...}
	if type(args[1]) == "table" then
		assert(#args[1] == 3 or #args[1] == 4, "Invalid Color Passed")
		return {args[1][1], args[1][2], args[1][3], args[1][4] or 1}
	elseif type(args[1] == "number") then
		assert(args[1] and args[2] and args[3])
		return {args[1], args[2], args[3], args[4] or 1}
	end
	error("Invalid Color Passed")
end
function button.setOutlineColor(...) outlineColor = setColor(...) end
function button.setTextColor(...) textColor = setColor(...) end

function button.getOutlineColor() return unpack(outlineColor) end
function button.getTextColor() return unpack(textColor) end

local xmap = {
	center = function(w) return lg.getWidth()/2 - w/2 end,
	right = function(w) return lg.getWidth() - w end
}
local drawCache = love.draw
--? will have to consider if this will break some things on other projects
function love.draw() drawCache() mousepressed = love.mouse.isDown(1) end
function button.rect(input)
	local x, y, w, h = unpack(input)

	if xmap[x] then x = xmap[x](w) end
	assert(x and y and w and h, "Drawing a button requires an position and dimensions")
	input = input or {}

	if input.relative then
		-- relative to window size
		w = common.clamp(lg.getWidth() * w, input.minWidth or -math.huge, input.maxWidth or math.huge)
		h = common.clamp(lg.getHeight() * h, input.minHeight or -math.huge, input.maxHeight or math.huge)
	end

	lg.push("all")
	local mx, my = love.mouse.getPosition()
	local click = not mousepressed and love.mouse.isDown(1) == true

	if input.image then
		if input.quad then
			local _, _, qw, qh = input.quad:getViewport()
			lg.draw(input.image, input.quad, x, y, 0, w/qw, h/qh)
		else
			local iw, ih = input.image:getDimensions()
			lg.draw(input.image, x, y, 0, w/iw, h/ih)
		end
	else
		lg.rectangle("fill", x, y, w, h)
		lg.setColor(outlineColor)
		lg.rectangle("line", x, y, w, h)
	end

	if input.text then
		local font = lg.getFont()
		lg.setColor(textColor)
		lg.print(input.text,
			math.floor(x + w/2 - font:getWidth(input.text)/2),
			math.floor(y + h/2 - font:getHeight(input.text)/2)
		)
	end

	local pressed = false
	if geometry.pointInRect(mx, my, x, y, w, h) then
		local shade = input.shading or 0.25
		shade = mousepressed and shade * 1.75 or shade
		if click then
			pressed = true
		end
		lg.setColor(0, 0, 0, shade)
		lg.rectangle("fill", x, y, w, h)
	end
	lg.pop()
	return pressed
end

return button