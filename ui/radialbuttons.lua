local dial = {}
dial.__index = dial
dial._version = "0.3.6"

local button = {}
button.__index = button

local lg = love.graphics

local mXCache, mYCache

-----------------------------------------------
---------------LOCAL FUNCTIONS-----------------
-----------------------------------------------

local function getDefault()
	return {
		font = lg.newFont(12), 
		expandDistance = 15, -- split from pie
		arctype = "pie",

		-- not hovering
		textColor = {1,1,1,1},
		textBackgroundColor = {0,0,0,0},
		textBackgroundBuffer = 1,
		color = {0.6, 0.6, 0.6, 0.5},
		borderColor = {1,1,1,1},
		borderWidth = 2,

		-- not hovering
		hoverTextColor = {1,1,1,1},
		hoverTextBackgroundColor = {0,0,0,0},
		hoverTextBackgroundBuffer = 1,
		hoverColor = {0.7, 0.6, 0.6, 0.5},
		hoverBorderColor = {1,1,1,1},
		hoverBorderWidth = 2,

		-- not hovering
		pressedTextColor = {1,1,1,1},
		pressedTextBackgroundColor = {0,0,0,0},
		pressedTextBackgroundBuffer = 1,
		pressedColor = {0.6, 0.6, 0.6, 0.5},
		pressedBorderColor = {1,1,1,1},
		pressedBorderWidth = 2,

		-- not hovering
		selectedTextColor = {1,1,1,1},
		selectedTextBackgroundColor = {0,0,0,0},
		selectedTextBackgroundBuffer = 1,
		selectedColor = {0.6, 0.6, 0.6, 0.5},
		selectedBorderColor = {1,1,1,1},
		selectedBorderWidth = 2,

		-- not hovering
		hoverSelectedTextColor = {1,1,1,1},
		hoverSelectedTextBackgroundColor = {0,0,0,0},
		hoverSelectedTextBackgroundBuffer = 1,
		hoverSelectedColor = {0.6, 0.6, 0.6, 0.5},
		hoverSelectedBorderColor = {1,1,1,1},
		hoverSelectedBorderWidth = 2,

		-- not hovering
		pressedSelectedTextColor = {1,1,1,1},
		pressedSelectedTextBackgroundColor = {0,0,0,0},
		pressedSelectedTextBackgroundBuffer = 1,
		pressedSelectedColor = {0.6, 0.6, 0.6, 0.5},
		pressedSelectedBorderColor = {1,1,1,1},
		pressedSelectedBorderWidth = 2,

		triggerMouse = {1}, triggerKeyboard = {},
		isSelected = false, selectable = true, isPressed = false, isHovering = false,
		hoverTime = 0, hoverFuncTime = 1, hoverPromptTime = 1, isPrompting = false,
		visible = true, origPress = false, requireSelfClick = true,
		textOrientation = "angled"
	}
end

local function distance(x1, y1, x2, y2, squared)
	local dx = x1 - x2
	local dy = y1 - y2
	local s = dx * dx + dy * dy
	return squared and s or math.sqrt(s)
end

local function angle(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1)
end

local function vector(angle, magnitude)
	return math.cos(angle) * magnitude, math.sin(angle) * magnitude
end

local function inside(tab, var)
	for k,v in pairs(tab) do
		if v == var then
			return true
		end
	end
	return false
end

local function uncapitalize(str)
	return string.lower(str:sub(1, 1))..str:sub(2, string.len(str))
end

local function formatVariable(var, ...)
	local l = ...
	local s = ""
	s = (inside(l, "pressed") and "Pressed") or (inside(l, "hover") and s.."Hover" or s) or s
	s = inside(l, "selected") and s.."Selected" or s

	-- format capitalization
	s = s..var:gsub("^%l", string.upper)
	s = s:gsub("^%l", string.lower)

	return uncapitalize(s)
end

-- iterates through similar vars and formats variable name
local function simVarIter(main)
	local t = {"", "hover", "pressed", "selected", "hoverSelected", "pressedSelected"}
	local i = 0
	return function()
		i = i + 1
		if i <= #t then return uncapitalize(t[i]..main) end
	end
end

local function merge(default, user)
	-- user will over write default.
	if not user then return default end
	for k,v in pairs(user) do
		default[k] = v
	end
	return default
end


-----------------------------------------------
----------------CONSTRUCTORS-------------------
-----------------------------------------------

function dial.new(x, y, radius, options)
	-- this mostly is for singular positioning.
	options = options or {}
	options.x, options.y, options.radius = x, y, radius
	options.positionType = "center"
	options.buttons = {}
	return setmetatable(options, dial)
end

function button.new(dial, angle1, angle2, options)
	-- pass dial object, and angles
	-- it is possible to have overlapping arc buttons if desired.
	local self = merge(getDefault(), options)
	self.angle1, self.angle2 = angle1, angle2
	self.dial = dial

	local meta = setmetatable(self, button)
	table.insert(dial.buttons, meta)

	return meta
end


-----------------------------------------------
----------------MAIN FUNCTIONS-----------------
-----------------------------------------------


-- for button updating.  Typically called through it's dial update function
function button:update(dt)
	if self:inBounds() then
		-- print("HERE")
		local press, key = self:keyPressed()
		self.isPressed = (press and self.requireSelfClick and self.origPress) and true or false
		if self.isHovering == false then
			self.onEnter()
			self.isHovering = true
		end
		if self.hoverTime > self.hoverFuncTime then
			self.hover()
		end
		self.hoverTime = self.hoverTime + dt
		self.isPrompting = self.hoverTime > self.hoverPromptTime and true or false
	elseif self.isHovering == true then
		self.onExit()
		self.isHovering = false
		self.hoverTime = 0
		self.isPressed = false
		self.isPrompting = false
	end
end

function button:draw()
	lg.push()
	local fV = formatVariable

	if self.visible then
		local v = {}
		if self.isHovering then table.insert(v, "hover") end
		if self.isPressed then table.insert(v, "pressed") end
		if self.selected then table.insert(v, "selected") end

		local x, y = self.dial:getCenter()
		local radius = self.dial.radius

		-- draw 
		lg.setColor(self[fV("color", v)])
		local im = self[fV("image", v)]
		if im then
			error("Dial image implimentation incomplete.")
		else
			lg.arc("fill", x, y, radius, self.angle1, self.angle2)
		end

		lg.setColor(self[fV("borderColor", v)])
		lg.setLineWidth(self[fV("borderWidth", v)])
		lg.arc("line", self.arctype, x, y, radius, self.angle1, self.angle2)

		-- rectangle for text background
		lg.setColor( self[fV("textBackgroundColor", v)] )
		local txt =  self[fV("text", v)]
		local tbb =  self[fV("textBackgroundBuffer", v)]

		-- txtx, txty = x + w/2 - tw/2  + self.textXOffset,
		-- 	y + h/2 - th/2 + self.textYOffset
		-- lg.rectangle("fill",
		-- 	txtx - tbb,	txty - tbb,
		-- 	tw  + tbb*2, th + tbb*2
		-- )

		lg.setColor(self[fV("textColor", v)])
		lg.setFont(self.font)


		local midAngle = self.angle2 - (self.angle2 - self.angle1)/2
		local txtx, txty = vector(midAngle, self.dial.radius/1.5)
		local tw, th = self.font:getWidth(txt), self.font:getHeight(txt)

		local halfpi = math.pi/2
		if midAngle > halfpi and midAngle <= halfpi*3 then
			midAngle = midAngle + -math.pi
		end

		if self.textOrientation == "horizontal" then
			midAngle = 0
		end

		lg.print(
			txt, txtx + x, txty + y,
			midAngle, 1, 1, tw/2, th/2
		)
	end

	lg.pop()
end

function dial:update(dt)
	mXCache, mYCache = love.mouse.getPosition()
	self.mouseAngleCache = angle(mXCache, mYCache, self:getCenter())
	self.mouseDistanceCache = distance(mXCache, mYCache, self:getCenter())
	for k, button in ipairs(self.buttons) do
		button:update(dt)
	end
end

function dial:draw()
	for k, button in ipairs(self.buttons) do
		button:draw()
	end
end

function button:mousepressed(x, y, key, istouch, presses)
	if self:getTriggerRequirements(key) then
		self.origPress = true
		self:onPress()
	end
end
function button:mousereleased(x, y, key, istouch, presses)
	if self:getTriggerRequirements(key) and self:getSelfClickRequirement() then
		self:onRelease()
	end
	self.origPress = false
end

-- can use mousepressed/released.  possibly need to rename pressed func
-- function button:keypressed(key)  
-- 	if self:getTriggerRequirements(key) then
-- 		self.origPress = true
-- 		self:onPress()
-- 	end
-- end
-- function button:keyreleased(key)
-- 	if self:getTriggerRequirements(key) then
-- 		self:onRelease()
-- 	end
-- 	self.origPress = false
-- end

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
function button:onRelease() end
function button:onPress() end
function button:onHoldPress() end
function button:hover() end
function button:onEnter() end
function button:onExit() end

function button:inBounds()
	local adjustedAngle = self.dial.mouseAngleCache + math.pi
	return adjustedAngle > self.angle1 and
		adjustedAngle <= self.angle2 and
		self.dial.mouseDistanceCache <= self.dial.radius
end

function dial:getCenter()
	if self.positionType == "center" then
		return self.x, self.y
	elseif self.positionType == "top left" then
		return self.x + self.radius, self.y + self.radius
	end
end


---------------------
----Set Functions----
---------------------

-- main set functions

--[[ 
	varargs (...) for the following functions can be use like...
	false/nil will only set the main variable (the first one under if input == true)
	true will set all button states to that variable
	table of variable strings to set those variables
		-- i.e. button:setText example
		button:setText("this is a test button!", {"selectedText", "pressedSelectedText", "hoverSelectedText"})
]]
function button:setText(text, ...)
	local input = ...
	if input == true then 
		for v in simVarIter("Text") do
			self[v] = text
		end
	elseif not input then
		self.text = text
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = text
		end
	end
end

function button:setTextColor(col, ...)
	local input = ...
	if input == true then
		for v in simVarIter("TextColor") do
			self[v] = col
		end
	elseif not input then
		self.textColor = col
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = col
		end
	end
end

function button:setTextBackgroundColor(col, ...)

	local input = ...
	if input == true then 
		for v in simVarIter("TextBackgroundColor") do
			self[v] = col
		end
	elseif not input then
		self.textBackgroundColor = col
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = col
		end
	end
end

function button:setTextBackgroundBuffer(buffer, ...)
	local input = ...
	if input == true then 
		for v in simVarIter("TextBackgroundBuffer") do
			self[v] = buffer
		end
	elseif not input then
		self.textBackgroundBuffer = buffer
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = buffer
		end
	end
end

function button:setImage(image, ...)
	local input = ...
	if input == true then 
		local im = formatImage(image)
		for v in simVarIter("Image") do
			self[v] = im
		end
	elseif not input then
		self.image = formatImage( image )
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = formatImage( image )
		end
	end
end

function button:setColor(col, ...)
	local input = ...
	if input == true then
		for v in simVarIter("Color") do
			self[v] = col
		end
	elseif not input then
		self.color = col
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = col
		end
	end
end

function button:setOutlineColor(col, ...)
	local input = ...
	if input == true then 
		for v in simVarIter("OutlineColor") do
			self[v] = col
		end
	elseif not input then
		self.outlineColor = col
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = col
		end
	end
end

function button:setOutlineWidth(w, ...)
	local input = ...
	if input == true then 
		for v in simVarIter("OutlineWidth") do
			self[v] = w
		end
	elseif not input then
		self.outlineWidth = w
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = w
		end
	end
end

-----------------------------------------------
----------------OTHER FUNCTIONS----------------
-----------------------------------------------

function button:getTriggerRequirements(key)
	return self:inBounds() and self:keyPressed(key)
end

function button:getSelfClickRequirement()
	return self.requireSelfClick and self.origPress or not self.requireSelfClick
end

function button:keyPressed(key)
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

return function() return dial, button end
