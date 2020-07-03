--[[
	TODO

	Range / select beginning and end part of slider.



]]

local slider = {}
slider.__index = slider

slider._version = "0.2.1"

-- aliases
local lm = love.mouse


--------------------------------
--------local functions---------
--------------------------------

local function clamp(n, low, high)
	return math.max(math.min(n, high), low)
end

-- also found in jjutils
-- do I really need this or can I just put it in inBounds
local function rectanglePointCollision(x,y,rx,ry,w,h)
	return 	x >= rx
		and x <= rx + w
		and y >= ry
		and y <= ry + h
end
local function map(n, start1, stop1, start2, stop2, Clamp)
	local mapped = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2
	if not Clamp then
		return mapped
	end
	if start2 < stop2 then
		return clamp(mapped, start2, stop2)
	else
		return clamp(mapped, stop2, start2)
	end
end


--------------------------------
----------Constructors----------
--------------------------------
-- if you desire custom segment locations, (array) segments to designate where they will be 0-1.
-- example: {0, 0.1, 0.9, 1} puts segments at the start, 10% in, 90% in and at the end.
function slider:newHorizontalSlider(x, y, width, height, segments)
	if not segments then
		local segments = {}
		for i = 0, width do
			table.insert(segments, i/width)
		end
	end
	local default = {
		direction = "horizontal",
		x = x,
		y = y,
		width = width,
		height = height,
		hoverBuffer = 2, -- distance away from bar to say you're hovering.
		segments = segments,
		knobImage = nil,
		knobOnHover = false, -- if false, it will always show.
		knobScale = {1,1},
		fillColor = {0.7, 0.1, 0.1, 1},
		fill = 0, -- percent 0-1
		baseColor = {0.65,0.65,0.65,0.7},
		baseImage = nil,
		minKnobColor = {1,1,1,1},
		maxKnobColor = {1,1,1,1},
		maxKnob = false,
		knobOffset = {0, 0},
		lockCursor = true,
		range = {1, 1},
		triggerMouse = {1},
		triggerKeyboard = {},
		requireSelfClick = true, -- require press to happen in this button, then release in this button.
		origPress = false, -- if mousepress was originally over this slider
		slideFunc = function() end,
	}
	return setmetatable(default, slider)
end

-- if you desire custom segment locations, (array) segments to designate where they will be 0-1.
-- example: {0, 0.1, 0.9, 1} puts segments at the start, 10% in, 90% in and at the end.
function slider:newVerticleSlider(x, y, width, height, segments)
	if not segments then
		local segments = {}
		for i = 0, width do
			table.insert(segments, i/width)
		end
	end
	local default = {
		direction = "verticle",
		x = x,
		y = y,
		width = width,
		height = height,
		hoverBuffer = 3, -- distance away from bar to say you're hovering.
		segments = segments,
		knobImage = nil,
		knobOnHover = false, -- if false, it will always show.
		knobScale = {1,1},
		fillColor = {0.7, 0.1, 0.1, 1},
		fill = 0, -- percent 0-1
		baseColor = {},
		baseImage = nil,
		minKnobColor = {1,1,1,1},
		maxKnobColor = {1,1,1,1},
		maxKnob = false,
		knobOffset = {0, 0},
		lockCursor = true,
		range = {1, 1},
		triggerMouse = {1},
		triggerKeyboard = {},
		requireSelfClick = true, -- require press to happen in this button, then release in this button.
		origPress = false, -- if mousepress was originally over this slider
		slideFunc = function() end,
	}
	return setmetatable(default, slider)
end




--------------------------------
--------main functions----------
--------------------------------

function slider:update(dt)
	local mx, my = lm.getPosition()
	if self:inBounds(mx, my) then
		if self:keyPressed(b) then
			-- click in slider
			if self.lockCursor then
				-- keep cursor in bounds
				-- consider making this part reference a separate variable.
				if self.direction == "horizontal" then
					lm.setPosition(
						clamp(mx, self.x+1, self.x + self.width-1),
						self.y + self.height/2
					)
				else
					lm.setPosition(
						self.x + self.width/2,
						clamp(my, self.y, self.y + self.height-1)
					)
				end
			end
			if self.requireSelfClick and self.origPress or not self.requireSelfClick then
				self:slide()
			end
		end
	end
end

function slider:draw()
	lg.setColor(self.baseColor)
	lg.rectangle("fill", self.x, self.y, self.width, self.height)

	lg.setColor(self.fillColor)
	if self.direction == "horizontal" then
		lg.rectangle("fill", self.x, self.y, self.width * self:getFill(), self.height)
		if self.knobImage then
			if self.knobOnHover and self:inBounds(lm.getPosition()) or not self.knobOnHover then
				lg.setColor(1,1,1,1)
				lg.draw(
					self.knobImage, 
					self.x + self.width*self:getFill(), 
					self.y + self.height/2, 
					0, 
					self.knobScale[1], 
					self.knobScale[2], 
					self.knobImage:getWidth()/2, self.knobImage:getHeight()/2
				)
			end
		end
	else
		lg.rectangle("fill", self.x, self.y, self.width, self.height * self:getFill())
		if self.knobImage then
			if self.knobOnHover and self:inBounds(lm.getPosition()) or not self.knobOnHover then
				lg.setColor(1,1,1,1)
				lg.draw(
					self.knobImage, 
					self.x + self.width/2, 
					self.y + self.height*self:getFill(), 
					0, 
					self.knobScale[1], 
					self.knobScale[2], 
					self.knobImage:getWidth()/2, self.knobImage:getHeight()/2
				)
			end
		end
	end

end

-- if not passed, it will check if it is down.
function slider:keyPressed(key)
	for i = 1, #self.triggerMouse do
		if key and key == self.triggerMouse[i] or not key and love.mouse.isDown(self.triggerMouse[i]) then
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

function slider:mousepressed(x, y, b, isTouch, presses)
	if self:inBounds(x,y) then
		if self:keyPressed(b) then
			self.origPress = true
		end
	end
end
function slider:mousereleased(x, y, b, isTouch, presses)
	self.origPress = false
end


function slider:slide()
	local mx, my = lm.getPosition()
	if self.direction == "horizontal" then
		self.fill = map(mx - self.x, 0, self.width, 0, 1, true)
	else
		self.fill = map(my - self.y, 0, self.height, 0, 1, true)
	end
	self.slideFunc()
end

--------------------------------
---------Get functions----------
--------------------------------s

function slider:inBounds(mx, my)
	return rectanglePointCollision(
		mx, my, 
		self.x - self.hoverBuffer, self.y - self.hoverBuffer, 
		self.width + self.hoverBuffer*2, self.height + self.hoverBuffer*2
	)
end

function slider:getVariable(name, ...)
	return self[name]
end

function slider:getPosition()
	return self.x, self.y
end
function slider:getDimensions()
	return self.width, self.height
end

-- get value from range
function slider:getValue()
	if self.direction == "horizontal" then
		return map(self.fill, self.x, self.x + self.width, self.range[1], self.range[2], true)
	else
		return map(self.fill, self.y, self.y + self.height, self.range[1], self.range[2], true)
	end
end

-- get fill percent 0-1
function slider:getFill()
	return self.fill
end
--------------------------------
---------Set functions----------
--------------------------------

function slider:setVariable(name, value)
	name = type(name) == "string" and {name} or name
	value = type(value) == "string" and {value} or value
	assert(#name == #value, "Number of names must equal number of values.")
	local key = name[1]
	for i = 2, #name do
		key = key[name[2]]
	end
end

function slider:setPosition(x,y)
	self.x, self.y = x, y
end

-- what should happen when slide() action is taken
function slider:setSlideFunction(func)
	assert(type(func) == "function", "Need to pass function.")
	self.slideFunc = func
end

-- range(optional) is to fill based on position in range
-- if range is true, pass a number to fill based on that numbers position in the range.
function slider:setFill(fill, range)
	self.fill = range and fill / (self.range[2] - self.range[1]) or fill -- didn't finish this.  If range, then set fill percent to it's place in range
end

-- pass either a path or drawable image
function slider:setKnobImage(image)
	assert(image, "Required image not passed.")
	if type(image) == "string" then
		self:setKnobImage(lg.newImage(image))
	elseif pcall(function() image:typeOf("Drawable") end) then
		self.knobImage = image
	else
		error("Parameter passed not valid.  Must be either path to drawable, or drawable type.")
	end
end

function slider:setKnobHover(bool)
	self.knobOnHover = bool
end

function slider:setKnobScale(scalex, scaley)
	self.knobScale = type(scalex) == "table" and scalex or {scalex, scaley}
end

function slider:lockCursor(bool)
	assert(bool == nil or type(bool) == "boolean", "Parameter expects boolean or nil to toggle.")
	self.lockCursor = bool ~= nil and bool or not self.lockCursor
end

function slider:setRange(min, max)
	self.range = {min, max}
end

-- set the thickness
function slider:setThickness(pixels)
	if self.direction == "horizontal" then
		self.height = pixels
	else
		self.width = pixels
	end
end

function slider:setFillColor(col, g, b, a)
	self.fillColor = type(col) == "table" and col or {col,g,b,a}
end

function slider:setBaseColor(col, g, b, a)
	self.baseColor = type(col) == "table" and col or {col,g,b,a}
end

-- param 1 is "mouse" or "keyboard"
-- param 2 is {key1, key2} using key constants
function slider:setTrigger(mork, keys)
	assert(mork == "mouse" or mork == "keyboard", "First parameter invalid.  Valid options are \"mouse\" or \"keyboard\"")
	if mork == "mouse" then
		self.triggerMouse = keys
	else
		self.triggerKeyboard = keys
	end
end

return slider