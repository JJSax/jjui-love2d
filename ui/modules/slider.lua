
local slider = {}
slider.__index = slider
slider._version = "0.3.7"

-- aliases
local lm = love.mouse
local lg = love.graphics
local ORIGIN = {x = 0, y = 0}

local common = require((...):gsub('%.[^%.]*%.[^%.]+$', '')..".common")


--------------------------------
--------local functions---------
--------------------------------



--------------------------------
----------Constructors----------
--------------------------------

function slider.new(x1, y1, angle, length, width, segments)
	-- slider at any angle

	-- segments not implimented yet.
	-- if you desire custom segment locations, (array) segments to designate where they will be 0-1.
	-- example: {0, 0.1, 0.9, 1} puts segments at the start, 10% in, 90% in and at the end.

	-- local quickAngles = {
	-- 	left = 0,
	-- 	right = math.pi,
	-- 	bottom = math.pi/2*3,
	-- 	top = math.pi/2
	-- }
	angle = common.angles[angle] or angle -- simplify common angles

	local b = {common.vector(angle, length)}

	local default = {
		parent = ORIGIN,
		a = {x = x1, y = y1},
		b = {x = b[1] + x1, y = b[2] + y1},
		angle = angle, length = length,
		width = width or 5, -- how wide the slider is.

		-- if the bar is horizontal, the hoverPerpendicularBuffer is amount above or below
		-- -- and the hoverParallelBuffer is left and right
		hoverPerpendicularBuffer = 5,
		hoverParallelBuffer = 5,
		-- segments = segments,
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
	return setmetatable(default, slider)
end

--------------------------------
--------main functions----------
--------------------------------

function slider:update(dt)
	if self.requireSelfClick and self.origPress or not self.requireSelfClick then
		if self:anyIsDown() then
			self:slide(lm.getPosition())
		end
	end
end

function slider:draw()
	lg.setColor(self.baseColor)
	lg.setLineWidth(self.width)

	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y

	lg.line(ax, ay, bx, by)

	lg.setColor(self.fillColor)

	local bx, by = common.vector(common.angle(ax, ay, bx, by), self.fill * self.length)
	bx, by = bx + ax, by + ay
	lg.line(ax, ay, bx, by)

	if self.knobImage then
		if self.knobOnHover and self:inBounds(lm.getPosition()) or not self.knobOnHover then
			lg.setColor(1,1,1,1)
			lg.draw(
				self.knobImage,
				bx, by, 0, self.knobScale[1], self.knobScale[2],
				self.knobImage:getWidth()/2, self.knobImage:getHeight()/2
			)
		end
	end
end

function slider:keypressed(key, scancode, isRepeat)
	if self:inBounds(lm.getPosition()) then
		if common.inside(self.triggerKeyboard, key) then
			self.origPress = true
		end
	end
end
function slider:keyreleased(key, scancode, isRepeat)
	self.origPress = false
end

function slider:mousepressed(x, y, b, isTouch, presses)
	if self:inBounds(x,y) then
		if common.inside(self.triggerMouse, b) then
			self.origPress = true
		end
	end
end
function slider:mousereleased(x, y, b, isTouch, presses)
	self.origPress = false
end

-- following 3 function return true if any valid key is pressed.
function slider:mouseIsDown()
	for k,v in ipairs(self.triggerMouse) do
		if lm.isDown(v) then return true end
	end
	return false
end
function slider:keyIsDown()
	for k,v in ipairs(self.triggerKeyboard) do
		if love.keyboard.isDown(v) then return true end
	end
	return false
end
function slider:anyIsDown()
	return self:mouseIsDown() or self:keyIsDown()
end

------------------------------------------------------------------------
------------------------------Methods-----------------------------------
------------------------------------------------------------------------


function slider:slide(mx, my)
	-- local nx, ny = self:nearestPointToLine(mx, my)
	self.fill = self:pointFill(mx, my)
	self:callback()
end

function slider:nearestPointToLine(px, py) -- for geometric line.

	-- returns a point on the infinite line nearest px, py
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	local a_p = {px - ax, py - ay}
	local a_b = {bx - ax, by - ay}
	local atb2 = a_b[1]^2 + a_b[2]^2 -- same as distance
	local atp_dot_atb = a_p[1] * a_b[1] + a_p[2] * a_b[2]
	local t = atp_dot_atb / atb2

	return ax + a_b[1] * t, ay + a_b[2] * t
end

function slider:distanceToLine(px, py) -- geometric line
	local nx, ny = self:nearestPointToLine(px, py)
	return common.dist(nx, ny, px, py)
end

function slider:pointFill(px, py)
	-- point px, py to fill percent 0-1 from point
	-- gets the fill level of px, py on slider.
	local ax, ay, bx, by = self.a.x + self.parent.x, self.a.y + self.parent.y,
		self.b.x + self.parent.x, self.b.y + self.parent.y
	local npx, npy = self:nearestPointToLine(px, py)
	local a_b = common.dist(ax, ay, bx, by, false)
	local a_p = common.dist(ax, ay, npx, npy, false)
	local a_np = common.dist(ax, ay, npx, npy, false)
	local b_np = common.dist(bx, by, npx, npy, false)

	if a_np < a_b and b_np < a_b then return a_p / a_b end -- percent 0-1
	if a_np < b_np then return self.clampFill and 0 or -(a_p / a_b) end
	if b_np < a_np then return self.clampFill and 1 or a_p / a_b end
end
--------------------------------
---------Get functions----------
--------------------------------

function slider:inBounds(mx, my)
	local npx, npy = self:nearestPointToLine(mx, my)
	local np_a = common.dist(npx, npy, self.a.x + self.parent.x, self.a.y + self.parent.y, false)
	local np_b = common.dist(npx, npy, self.b.x + self.parent.x, self.b.y + self.parent.y, false)

	return self:distanceToLine(mx, my) <= self.hoverPerpendicularBuffer + self.width and
		np_b < self.hoverParallelBuffer + self.length and np_a < self.hoverParallelBuffer + self.length
end

-- if not passed, it will check if it is down.
function slider:keyIsDown(key)
	for i = 1, #self.triggerMouse do
		if key and key == self.triggerMouse[i] or not key and lm.isDown(self.triggerMouse[i]) then
			return true, self.triggerMouse[i]
		end
	end
	for i = 1, #self.triggerKeyboard do
		if key and key == self.triggerKeyboard[i] or not key and love.keyboard.isDown(self.triggerKeyboard[i]) then
			return true, self.triggerKeyboard[i]
		end
	end
	return false
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
	self.fill = range and common.map(fill, self.range[1], self.range[2],
		0, 1, self.clampFill) or fill
	-- didn't finish this.  If range, then set fill percent to it's place in range
end

function slider:addFill(fill)
	self.fill = common.clamp(self.fill + fill, 0, 1)
end

function slider:setPosition(x, y)
	local b = {common.vector(self.angle, self.length)}
	self.a = {x = x + self.parent.x, y = y + self.parent.y}
	self.b = {x = b[1] + x + self.parent.x, y = b[2] + y + self.parent.y}
end

function slider:setLength(len)
	self.length = len
	local b = {common.vector(self.angle, len)}
	self.b = {x = b[1] + self.a.x, y = b[2] + self.a.y}
end

function slider:setAngle(angle)
	self.angle = angle
	local b = {common.vector(self.angle, self.length)}
	self.b = {x = b[1] + self.a.x + self.parent.x, y = b[2] + self.a.y + self.parent.y}
end

function slider:addAngle(angle)
	self:setAngle(self.angle + angle)
end

function slider:callback() end

return slider
