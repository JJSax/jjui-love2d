
local slider = {}
slider.__index = slider
slider._version = "0.3.9"

-- aliases
local lm = love.mouse
local lg = love.graphics
local ORIGIN = {x = 0, y = 0}

local uiRoot = (...):gsub('%.[^%.]*%.[^%.]+$', '')
local common = require(uiRoot..".common")
local geometry = require(uiRoot..".geometry")


--------------------------------
--------local functions---------
--------------------------------

local function func()

end

--------------------------------
----------Constructors----------
--------------------------------

function slider.new(x1, y1, angle, length, extra)
	-- if you desire custom segment locations, (array) segments to designate where they will be 0-1.
	-- example: {0.2, "", 0.9, ""} puts will look like ->  --|-----|-
	-- slider.new(150, 50, "left", 200, {width = 5, segments = {
	-- 	{0.2, "intro"}, {0.5, "start"}, {1, "end"}
	-- }})
	-- the beginning of the segment is implied to start at 0

	common.assert(x1, "requires x value to be passed", 3)
	common.assert(y1, "requires y value to be passed", 3)
	common.assert(angle, "requires angle value to be passed", 3)
	common.assert(length, "requires length value to be passed", 3)

	extra = extra or {}
	extra.segments = extra.segments or {{1, ""}}
	local seg = extra.segments
	common.assert(type(seg) == "table", "Param: segments expects table.  Got: "..type(seg), 3)
	for i, v in ipairs(seg) do
		common.assert(type(v[1]) == "number", "Expected format of segments: {0.2, \"test\"}", 3)
		common.assert(v[1] >= 0, "All segment valus must be greater than 0", 3)
		common.assert(v[1] <= 1, "All segment valus must be less than 1", 3)
	end
	common.assert(seg[#seg][1] == 1, "Last segment required to end at 1", 3)

	angle = geometry.angles[angle] or angle -- simplify common angles
	local b = {geometry.vector(angle, length)}
	local self = {
		parent = ORIGIN,
		a = {x = x1, y = y1},
		b = {x = b[1] + x1, y = b[2] + y1},
		angle = angle, length = length,
		width = extra.width or 5, -- how wide the slider is.
		segments = extra.segments or {},
		segmentGap = 2,

		-- if the bar is horizontal, the hoverPerpendicularBuffer is amount above or below
		-- -- and the hoverParallelBuffer is left and right
		hoverPerpendicularBuffer = 5,
		hoverParallelBuffer = 5,
		hoverExpand = 3, --The amount the width should bulge when hovered


		knobImage = nil,
		knobOnHover = false, -- if false, it will always show. If you don't want a knob, don't make one.
		knobScale = {1,1},
		fillColor = {0.7, 0.1, 0.1, 1}, -- part of the slider not filled
		fill = 0, -- percent [0-1] of the bar that is filled.
		clampFill = true, -- prevent fill level from going out of range.
		baseColor = {0.65,0.65,0.65,0.7}, -- fill portion of the slider
		-- knobOffset = {0, 0}, -- WIP
		range = {0, 1},
		triggerMouse = {1, 2},
		triggerKeyboard = {},
		requireSelfClick = true, -- require press to happen in this slider, then release in this slider.

		-- Internal variables
		origPress = false, -- if mousepress was originally over this slider
	}
	return setmetatable(self, slider)
end

--------------------------------
--------main functions----------
--------------------------------

function slider:update(dt)
	if not (self.requireSelfClick and self.origPress or not self.requireSelfClick) then return end
	if self:anyIsDown() then
		self:slide(lm.getPosition())
	end
end

function slider:draw()
	lg.setColor(self.baseColor)
	lg.setLineWidth(self.width)
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	local last = 0 -- from this fill level to next
	local lastPoint = {ax, ay}
	local mx, my = lm.getPosition()
	local onSegment, hLastPoint, hNext, seg
	for i, v in ipairs(self.segments) do
		local len = (self.length - self.segmentGap * i) * (v[1] - last)
		local next = {geometry.vector2(lastPoint[1], lastPoint[2], self.angle, len)}
		lg.push("all")
		if geometry.pointOnLine(
			mx, my, lastPoint[1], lastPoint[2], next[1], next[2], self.width
		) then
			onSegment = i
		end

		lg.setLineWidth(self.width + (onSegment == i and self.hoverExpand or 0))
		lg.line(lastPoint[1], lastPoint[2], next[1], next[2])
		if onSegment == i then
			hLastPoint = lastPoint
			hNext = next
			seg = v
		end
		lg.pop()

		last = v[1]
		lastPoint = {geometry.vector2(next[1], next[2], self.angle, self.segmentGap)}
	end

	lg.setColor(self.fillColor)
	local bx, by = geometry.vector(geometry.angle(ax, ay, bx, by), self.fill * self.length)
	bx, by = bx + ax, by + ay
	lg.line(ax, ay, bx, by)

	if onSegment then -- draw segment text if hovered
		lg.push("all")
		lg.setColor(seg.textColor or {1,1,1,1})
		local font = seg.font or lg.getFont()
		lg.setFont(font)
		local midx, midy = geometry.midPoint(hLastPoint[1], hLastPoint[2], hNext[1], hNext[2])
		local perpendicular = -math.pi/2
		local angle = self.angle
		if self.a.x > self.b.x then
			perpendicular = perpendicular + math.pi
			angle = self.angle + math.pi
		end
		local tx, ty = geometry.vector2(midx, midy, self.angle + perpendicular, font:getHeight())
		lg.print(seg[2], tx, ty, angle,
			1, 1, font:getWidth(seg[2])/2,  font:getHeight()/2
		)
		lg.pop()
	end

	if not self.knobImage then return end
	if self.knobOnHover and self:inBounds(lm.getPosition()) or not self.knobOnHover then
		lg.setColor(1,1,1,1)
		lg.draw(
			self.knobImage,
			bx, by, 0, self.knobScale[1], self.knobScale[2],
			self.knobImage:getWidth()/2, self.knobImage:getHeight()/2
		)
	end
end

function slider:keypressed(key, scancode, isRepeat)
	if not self:inBounds(lm.getPosition()) then return false end
	if common.inside(self.triggerKeyboard, key) then
		self.origPress = true
	end
end
function slider:keyreleased(key, scancode, isRepeat)
	self.origPress = false
end

function slider:mousepressed(x, y, b, isTouch, presses)
	if not self:inBounds(x,y) then return false end
	if common.inside(self.triggerMouse, b) then
		self.origPress = true
	end
end
function slider:mousereleased(x, y, b, isTouch, presses)
	self.origPress = false
end

-- following 3 function return true if any valid key is pressed.
function slider:mouseIsDown()
	return lm.isDown(self.triggerMouse)
end
function slider:keyIsDown()
	return love.keyboard.isDown(self.triggerKeyboard)
end
function slider:anyIsDown()
	return self:mouseIsDown() or self:keyIsDown()
end

------------------------------------------------------------------------
------------------------------Methods-----------------------------------
------------------------------------------------------------------------


function slider:slide(mx, my)
	common.assert(type(mx) == "number", "Param1 requires type number", 3)
	common.assert(type(my) == "number", "Param2 requires type number", 3)
	self.fill = self:pointFill(mx, my)
	self:callback()
end

function slider:nearestPointToLine(px, py) -- for geometric line.
	-- returns a point on the infinite line nearest px, py
	common.assert(type(px) == "number", "Param1 requires type number", 3)
	common.assert(type(py) == "number", "Param2 requires type number", 3)
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	return geometry.nearestPointToLine(px, py, ax, ay, bx, by)
end

function slider:distanceToLine(px, py) -- geometric line
	common.assert(type(px) == "number", "Param1 requires type number", 3)
	common.assert(type(py) == "number", "Param2 requires type number", 3)
	-- local nx, ny = self:nearestPointToLine(px, py)
	return geometry.dist(px, py, self:nearestPointToLine(px, py))
end

function slider:pointFill(px, py)
	-- point px, py to fill percent 0-1 from point
	-- gets the fill level of px, py on slider.
	common.assert(type(px) == "number", "Param1 requires type number", 3)
	common.assert(type(py) == "number", "Param2 requires type number", 3)
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	local npx, npy = self:nearestPointToLine(px, py)
	local a_b = geometry.dist(ax, ay, bx, by, false)
	local a_p = geometry.dist(ax, ay, npx, npy, false)
	local a_np = geometry.dist(ax, ay, npx, npy, false)
	local b_np = geometry.dist(bx, by, npx, npy, false)

	if a_np < a_b and b_np < a_b then return a_p / a_b end -- percent 0-1
	if a_np < b_np then return self.clampFill and 0 or -(a_p / a_b) end
	if b_np < a_np then return self.clampFill and 1 or a_p / a_b end
end
--------------------------------
---------Get functions----------
--------------------------------

function slider:inBounds(mx, my)
	common.assert(type(mx) == "number", "Param1 requires type number", 3)
	common.assert(type(my) == "number", "Param2 requires type number", 3)
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	local kx, ky = geometry.vector(geometry.angle(ax, ay, bx, by), self.fill * self.length)
	kx, ky = kx + ax, ky + ay

	return geometry.pointOnLine(mx, my, ax, ay, bx, by, self.hoverPerpendicularBuffer + self.width)
		or geometry.pointOnLine(mx, my, ax, ay, kx, ky, self.hoverPerpendicularBuffer + self.width)
end

-- get value from range
function slider:getValue()
	return common.map(self.fill, 0, 1, self.range[1], self.range[2], true)
end

--------------------------------
---------Set functions----------
--------------------------------

-- range(optional) is to fill based on position in range
-- if range is true, pass a number to fill based on that numbers position in the range.
function slider:setFill(fill, range)
	common.assert(type(fill) == "number", "Param1 requires type number", 3)
	self.fill = range and common.map(fill, self.range[1], self.range[2],
		0, 1, self.clampFill) or fill
	-- didn't finish this.  If range, then set fill percent to it's place in range
end

function slider:addFill(fill)
	common.assert(type(fill) == "number", "Param1 requires type number", 3)
	self.fill = common.clamp(self.fill + fill, 0, 1)
end

function slider:setPosition(x, y)
	common.assert(type(x) == "number", "Param1 requires type number", 3)
	common.assert(type(y) == "number", "Param2 requires type number", 3)
	local b = {geometry.vector(self.angle, self.length)}
	self.a = {x = x + self.parent.x, y = y + self.parent.y}
	self.b = {x = b[1] + x + self.parent.x, y = b[2] + y + self.parent.y}
end

function slider:setLength(len)
	common.assert(type(len) == "number", "Param1 requires type number", 3)
	self.length = len
	local b = {geometry.vector(self.angle, len)}
	self.b = {x = b[1] + self.a.x, y = b[2] + self.a.y}
end

function slider:setAngle(angle)
	common.assert(type(angle) == "number", "Param1 requires type number", 3)
	self.angle = angle
	local b = {geometry.vector(self.angle, self.length)}
	self.b = {x = b[1] + self.a.x + self.parent.x, y = b[2] + self.a.y + self.parent.y}
end

function slider:addAngle(angle)
	common.assert(type(angle) == "number", "Param1 requires type number", 3)
	self:setAngle(self.angle + angle)
end

function slider:callback() end

return slider
