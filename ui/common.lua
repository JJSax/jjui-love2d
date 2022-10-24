local common = {
	_VERSION = "0.0.8"
}

common.__index = common
local lg = love.graphics

common.angles = {
	left = 0,
	right = math.pi,
	bottom = math.pi/2*3,
	top = math.pi/2
}

function common.assert(expect, msg, stack)
	if not expect then
		error(msg, stack)
	end
end

function common.dist(x1, y1, x2, y2, squared)
	local dx = x1 - x2
	local dy = y1 - y2
	local s = dx * dx + dy * dy
	return squared and s or math.sqrt(s)
end

function common.angle(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1)
end

function common.vector(angle, magnitude)
	return math.cos(angle) * magnitude, math.sin(angle) * magnitude
end

function common.map(n, start1, stop1, start2, stop2, Clamp)
	local mapped = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2
	if not Clamp then return mapped end
	if start2 < stop2 then
		return common.clamp(mapped, start2, stop2)
	end
	return common.clamp(mapped, stop2, start2)
end

function common.inRange(num, mn, mx) --? do I want to require mn before mx?
	return (num >= mn and num <= mx) or (num <= mn and num >= mx)
end

function common.clamp(num, low, high)
	if num < low then return low end
	if num > high then return high end
	return num
end

function common.formatImage( image )
	-- assert(image, "Required image not passed.")
	if type(image) == "string" then
		return lg.newImage(image)
	elseif pcall(function() image:typeOf("Drawable") end) then
		return image
	elseif not image then return nil
	else
		error("Parameter passed not valid.  Must be either path to drawable, or drawable type.")
	end
end

function common.inside(tab, var)
	for k,v in pairs(tab) do
		if v == var then return true end
	end
	return false
end

function common.uncapitalize(str)
	return str:gsub("^%u", string.lower)
end


function common.merge(default, extra)
	if not extra then return default end
	for k,v in pairs(extra) do
		default[k] = v
	end
	return default
end

function common.sum(tab)
	local t = 0
	for k,v in pairs(tab) do
		t = t + v
	end
	return t
end

function common.average(tab)
	return common.sum(tab) / #tab
end

function common.pointInRect(x, y, bx, by, bw, bh)
	return  x > bx
	and	x < bx + bw
	and	y > by
	and	y < by + bh
end

function common.between(a1, a2, target)

	--@ a1/a2 is first/second angle
	--@ target is the angle to target point
	--* Returns true if target angle is between a1 and a2

	local min = math.min(a1, a2)
	local max = math.max(a1,a2)
	local diff = max - min
	local mid = max - diff/2

	local dot = math.cos(mid)*math.cos(target) + math.sin(mid)*math.sin(target)
	local angle = math.acos(dot)

	return angle <= diff/2
end

function common.iterateAllStates(self)
	local t = {"disabled", "pressed", "hovered", "default"}
	local i = 0
	return function()
		i = i + 1
		if t[math.ceil(i/2)] then
			return self.state[t[math.ceil(i/2)]][i % 2 == 0]
		end
	end
end

common.font12 = lg.newFont(16)
function common.newVarSet()
	return {
		font = common.font12,
		text = "", -- text to print
		textRotation = 0,
		textColor = {1,1,1,1}, -- Color of text
		textBackgroundColor = {0,0,0,0}, -- Color of box behind text
		textBackgroundBuffer = 1, -- Buffer in pixels for surrounding highlight.
		textXOffset = 0, -- Horizontal text offset within button.  Note, doesn't have to be inside button.
		textYOffset = 0, -- Vertical offset within button
		image = nil, -- Image to draw, has to be lg.newImage, not path to image.  You can use formatImage.
		color = {0.5,0.5,0.6,1}, -- Color of main button area.
		outlineColor = {1,1,1,1}, -- Color of outline draw.
		outlineWidth = 1, -- Width of outline
	}
end

function common.standardButton(self)
	-- create state heirarchy

	self.state = self.state or {}
	for _, bType in ipairs{"disabled", "pressed", "hovered", "default"} do
		self.state[bType] = {}
		for i, v in ipairs({true, false}) do
			self.state[bType][v] = common.newVarSet()
		end
	end
	self.state["hovered"][true].color =  {0.4,0.4,0.5,1}
	self.state["hovered"][false].color = {0.4,0.4,0.5,1}
end

function common.getState(self)
	--https://makeitclear.com/insight/ux-ui-tips-a-guide-to-creating-buttons
	for _, bType in ipairs{"disabled", "pressed", "hovered", "default"} do
		if self[bType] then
			return self.state[bType][self.selected]
		end
	end
end

return common