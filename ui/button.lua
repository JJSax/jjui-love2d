
local button = {}
button.__index = button
button._version = "0.6.11"

local default = {
	font = lg.getFont(), rotation = 0,
	fitText = false, fitHoverText = true, visible = true, 
	requireSelfClick = true, -- require press to happen in this button, then release in this button.
	
	-- Keep in mind, you cannot be pressed while not being hovered.
	-- Variables for when the button is not hovered, or selected.
	text = "", -- text to print
	textColor = {1,1,1,1}, -- color of text
	textBackgroundColor = {0,0,0,0}, -- DOUBLE CHECK highlight color of text?
	textBackgroundBuffer = 1, -- Buffer in pixels for surrounding highlight.
	textXOffset = 0, -- Horizontal text offset within button.  Note, doesn't have to be inside button.
	textYOffset = 0, -- Vertical offset within button	
	image = nil, -- Image to draw, has to be lg.newImage, not path to image.  You can use formatImage.
	color = {1,1,1,1}, -- color of main button area.
	outlineColor = {0,0,0,0}, -- Color of outline draw.
	outlineWidth = 0, -- Width of outline
	-- isHovering

	-- Button state while hovered, but not selected.
	hoverText = "", 
	hoverTextColor = {1,1,1,1},
	hoverTextBackgroundColor = {0,0,0,0},
	hoverTextBackgroundBuffer = 1,
	hoverImage = nil, -- not selected; hovered; not pressed
	hoverColor = {0.8,0.8,0.8,1},
	hoverOutlineColor = {0,0,0,0}, 
	hoverOutlineWidth = 1,
	isHovering = false,
	 -- additional hover variables
	promptOffsetX = 0, promptOffsetY = 0,
	hoverTime = 0,
	hoverFuncTime = 1,
	hoverPromptTime = 1,
	isPrompting = false,
	lockPromptToWindow = true,

	-- Button state while pressed but not selected, 
	 -- AKA trigger mouse/keyboard held while hovering over the button not yet triggered.
	pressedText = "",
	pressedTextColor = {1,1,1,1},
	pressedTextBackgroundColor = {0,0,0,0},
	pressedTextBackgroundBuffer = 1,
	pressedImage = nil, -- not selected; hovered; pressed
	pressedColor = {0.7,0.7,0.7,1},
	pressedOutlineColor = {0,0,0,0},
	pressedOutlineWidth = 1,
	isPressed = false, 

	-- Button state selected, not pressed.
	selectedText = "",
	selectedTextColor = {1,1,1,1},
	selectedTextBackgroundColor = {0,0,0,0},
	selectedTextBackgroundBuffer = 1,
	selectedImage = nil, -- selected; not hovered; not pressed
	selectedColor = {1,1,1,1},
	selectedOutlineColor = {0,0,0,0},
	selectedOutlineWidth = 1,
	selected = false,
	selectable = true,
	-- selectable refers to if it can be selected despite if it is visible.  Usually will == visible

	-- Button state selected and hovered, not pressed
	hoverSelectedText = "",
	hoverSelectedTextColor = {1,1,1,1},
	hoverSelectedTextBackgroundColor = {0,0,0,0},
	hoverSelectedTextBackgroundBuffer = 1,
	hoverSelectedImage = nil, -- selected; hovered; not pressed
	hoverSelectedColor = {0.8,0.8,0.8,1},
	hoverSelectedOutlineColor = {0,0,0,0},
	hoverSelectedOutlineWidth = 1,

	-- Button state selected and pressed
	pressedSelectedText = "",
	pressedSelectedTextColor = {1,1,1,1},
	pressedSelectedTextBackgroundColor = {0,0,0,0},
	pressedSelectedTextBackgroundBuffer = 1,
	pressedSelectedImage = nil, -- selected; hovered; pressed
	pressedSelectedColor = {0.7,0.7,0.7,1},
	pressedSelectedOutlineColor = {0,0,0,0},
	pressedSelectedOutlineWidth = 1,

	-- 
	hoverPromptText = "",
	promptFont = lg.getFont(),
	promptTextColor = {1,1,1,1},
	promptTextBackgroundColor = {0,0,0,0},
	promptTextBackgroundBuffer = 1,
	promptColor = {0,0,0,0}, 
	promptOutlineColor = {0,0,0,0},
	promptOutlineWidth = 1,
	promptXBuffer = 2, -- this is the extra space around prompt text
	promptYBuffer = 2, -- this is the extra space around prompt text

	triggerMouse = {1}, triggerKeyboard = {}, -- array of buttons to detect isDown
}

-- run at bottom of main update function
-------------------------------------------
-------------Local Functions---------------
-------------------------------------------

local lg = love.graphics

local function clone(tab)
  local ret = {}
  for k, v in pairs(tab) do ret[k] = v end
  return ret
end

local function dist(x1, y1, x2, y2, squared)
  local dx = x1 - x2
  local dy = y1 - y2
  local s = dx * dx + dy * dy
  return squared and s or math.sqrt(s)
end

-- return image from string path or passed drawable
local function formatImage( image )
	assert(image, "Required image not passed.")
	if type(image) == "string" then
		return lg.newImage(image)
	elseif pcall(function() image:typeOf("Drawable") end) then
		return image
	else
		error("Parameter passed not valid.  Must be either path to drawable, or drawable type.")
	end
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

local function merge(default, extra)
	if not extra then return default end
	for k,v in pairs(extra) do
		default[k] = v
	end
	return default
end

--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------


--
function button.newRectangleButton(l,t,w,h,extra)
	local properties = clone(default)
	properties.shape = lg.rectangle
	properties.x, properties.y, properties.w, properties.h = l, t, w, h
	properties.roundedCornersRadius = 0
	properties = merge(properties, extra)

	return setmetatable(properties, button)
end

-- Circle button functionality not yet implemented
function button.newCircleButton(x,y,r,extra)
	local properties = clone(default)
	properties.shape, properties.x, properties.y, properties.radius = lg.circle, x, y, r
	properties = merge(properties, extra)
	return setmetatable(properties, button)
end

--------------------------------------------
--------------Main Functions----------------
--Run these in their respective love loops--
--------------------------------------------
function button:update(dt)
	local mx, my = love.mouse.getPosition()
	if self:inBounds(mx, my) then
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

		local x, y, w, h = self.x, self.y, self.w, self.h

		-- draw 
		lg.setColor(self[fV("color", v)])
		local im = self[fV("image", v)]
		if im then
			if self.shape == lg.rectangle then
				lg.draw(im, x, y, self.rotation, w/im:getWidth(), h/im:getHeight())
			else
				lg.draw(im, x, y, self.rotation, 
					(self.radius*2)/im:getWidth(),(self.radius*2)/im:getHeight(),
					im:getWidth()/2, im:getHeight()/2
				)
			end
		else
			self.shape("fill", 
				x, y, 
				w and w or self.radius, h and h or self.roundedCornersRadius, 
				self.roundedCornersRadius, self.roundedCornersRadius
			)
		end
		lg.setColor(self[fV("outlineColor", v)])
		lg.setLineWidth(self[fV("outlineWidth", v)])
		self.shape("line", 
			x, y, 
			w and w or self.radius, h and h or self.roundedCornersRadius, 
			self.roundedCornersRadius, self.roundedCornersRadius
		)
		-- rectangle for text background
		lg.setColor( self[fV("textBackgroundColor", v)] )
		local txt =  self[fV("text", v)]
		local tbb =  self[fV("textBackgroundBuffer", v)]
		local txtx, txty
		local tw, th = self.font:getWidth(txt), self.font:getHeight(txt)
		if self.shape == lg.rectangle then
			txtx, txty = x + w/2 - tw/2  + self.textXOffset,
				y + h/2 - th/2 + self.textYOffset
			lg.rectangle("fill",
				txtx - tbb,	txty - tbb,
				tw  + tbb*2, th + tbb*2
			)
		else
			txtx, txty = x - tw/2 + self.textXOffset,
				y - th/2 + self.textYOffset
			lg.rectangle("fill", 
				txtx - tbb,	txty - tbb,
				tw  + tbb*2, th + tbb*2
			)
		end
		lg.setColor(self[fV("textColor", v)])
		lg.setFont(self.font)
		lg.print(txt, txtx, txty)
	end

	lg.pop()
end

function button:mousepressed(x, y, key, istouch, presses)
	if self:inBounds(x,y) then
		if self:keyPressed(key) then
			self.origPress = true
			self:onPress()
		end
	end
end
function button:mousereleased(x, y, key, istouch, presses)
	if self:inBounds(x,y) then
		if self.requireSelfClick and self.origPress or not self.requireSelfClick then
			if self:keyPressed(key) then
				self:onRelease()
			end
		end
	end
	self.origPress = false
end

function button:keypressed(key, istouch, presses)
	if self:inBounds(love.mouse.getPosition()) then
		if self:keyPressed(key) then
			self.origPress = true
			self:onPress()
		end
	end
end
function button:keyreleased(key, istouch, presses)
	if self:inBounds(love.mouse.getPosition()) then
		if self.requireSelfClick and self.origPress or not self.requireSelfClick then
			if self:keyPressed(key) then
				self:onRelease()
			end
		end
	end
	self.origPress = false
end

-- draws popup message  Put in love's draw loop after other buttons it may overlap
function button:prompt()
	if not self.isPrompting then return false end
	lg.push()

	local mx, my = love.mouse.getPosition()
	local pW, pY = self.font:getWidth(self.hoverPromptText) + self.promptXBuffer * 2, 
		self.font:getHeight(self.hoverPromptText) + self.promptYBuffer * 2

	-- these two lines slightly buggy.  fix it
	if self.lockPromptToWindow then
		if mx + pW > lg.getWidth() then mx = lg.getWidth() - pW end
		if my - pY/2 < 0 then my = pY/2 end
	end
	lg.setColor(self.promptColor)
	lg.rectangle("fill", mx, my-self.font:getHeight(self.hoverPromptText), pW,pY)
	lg.setColor(self.promptOutlineColor)
	lg.setLineWidth(self.promptOutlineWidth)
	lg.rectangle("line", mx, my-self.font:getHeight(self.hoverPromptText), pW, pY)
	lg.setColor(self.promptTextColor)
	lg.print(self.hoverPromptText, mx + self.promptXBuffer, my- self.font:getHeight()/2)

	lg.pop()
end


--------------------------------------------
-------------Common Functions---------------
--------------------------------------------
function button:onRelease() end
function button:onPress() end
function button:onHoldPress() end
function button:hover() end
function button:onEnter() end
function button:onExit() end

-- Returns if x,y position is inside boundary of button
function button:inBounds(x,y)
	return self.shape == lg.rectangle and
		x > self.x and
		x < self.x + self.w and
		y > self.y and
		y < self.y + self.h or

		self.shape == lg.circle and 
		dist(x, y, self.x, self.y) <= self.radius
end

-- if key not passed, it will check if it is down.
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

-- Toggles if the button is considered selected or not.  
-- If you want the button to have a toggled on/off state, run this inside it's onPress or onRelease functions
function button:toggle(bool)
	self.selected = bool and bool or not self.selected
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
-- function to clone button

return button
