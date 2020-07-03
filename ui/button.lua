
local button = {}
button.__index = button
button._version = "0.3.7"


-- run at bottom of main update function
-------------------------------------------
-------------Local Functions---------------
-------------------------------------------

local lg = love.graphics

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


--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------


--
function button.newRectangleButton(l,t,w,h)
	local b = {
		shape = lg.rectangle, font = lg.getFont(), 
		x= l or 0, y= t or 0, w= w or 0, h = h or 0, rotation = 0, textScale = 1, roundedCornersRadius = 0,
		fitText = false, fitHoverText = true, visible = true, 
		requireSelfClick = true, -- require press to happen in this button, then release in this button.
		

		-- not isHovering
		text = "", 
		textColor = {1,1,1,1},
		textBackgroundColor = {0,0,0,0},
		textBackgroundBuffer = 1,
		textXOffset = 0,
		textYOffset = 0,
		image = nil, --  not selected; not hovered; not pressed
		color = {1,1,1,1},
		outlineColor = {0,0,0,0},
		outlineWidth = 0,
		-- isHovering

		hoverText = "", 
		hoverTextColor = {1,1,1,1},
		hoverTextBackgroundColor = {0,0,0,0},
		hoverTextBackgroundBuffer = 1,
		hoverImage = nil, -- not selected; hovered; not pressed
		hoverColor = {0.8,0.8,0.8,1},
		hoverOutlineColor = {0,0,0,0}, 
		hoverOutlineWidth = 1,
		isHovering = false,

		-- isHovering prompt
		hoverPromptText = "",
		promptTextColor = {1,1,1,1},
		promptTextBackgroundColor = {0,0,0,0},
		promptTextBackgroundBuffer = 1,
		promptColor = {0,0,0,0}, 
		promptOutlineColor = {0,0,0,0},
		promptOutlineWidth = 1,
		promptXBuffer = 2, -- this is the extra space around prompt text
		promptYBuffer = 2, -- this is the extra space around prompt text
		hoverTime = 0,
		hoverFuncTime = 1,
		hoverPromptTime = 1,
		isPrompting = false,
		lockPromptToWindow = true,

		-- pressed
		pressedText = "",
		pressedTextColor = {1,1,1,1},
		pressedTextBackgroundColor = {0,0,0,0},
		pressedTextBackgroundBuffer = 1,
		pressedImage = nil, -- not selected; hovered; pressed
		pressedColor = {0.7,0.7,0.7,1},
		pressedOutlineColor = {0,0,0,0},
		pressedOutlineWidth = 1,
		isPressed = false, 

		-- selected 
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

		-- selected and hovered
		hoverSelectedText = "",
		hoverSelectedTextColor = {1,1,1,1},
		hoverSelectedTextBackgroundColor = {0,0,0,0},
		hoverSelectedTextBackgroundBuffer = 1,
		hoverSelectedImage = nil, -- selected; hovered; not pressed
		hoverSelectedColor = {0.8,0.8,0.8,1},
		hoverSelectedOutlineColor = {0,0,0,0},
		hoverSelectedOutlineWidth = 1,

		-- selected and pressed
		pressedSelectedText = "",
		pressedSelectedTextColor = {1,1,1,1},
		pressedSelectedTextBackgroundColor = {0,0,0,0},
		pressedSelectedTextBackgroundBuffer = 1,
		pressedSelectedImage = nil, -- selected; hovered; pressed
		pressedSelectedColor = {0.7,0.7,0.7,1},
		pressedSelectedOutlineColor = {0,0,0,0},
		pressedSelectedOutlineWidth = 1,

		triggerMouse = {1}, triggerKeyboard = {}, -- array of buttons to detect isDown
		onPress = function() end, onHoldPress = function() end,
		hover = function() end, onEnter = function() end, onExit = function() end,
		onRelease = function() end
	}

	return setmetatable(b, button)
end

-- Circle button functionality not yet implemented
function button.newCircleButton(x,y,r)
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
	end
end

function button:draw()
	lg.push()
		
	if self.visible then
		if self.isHovering then
			if self.isPressed then
				if self.selected then
					-- draw pressed selected
					lg.setColor(self.pressedSelectedColor)
					if self.pressedSelectedImage then
						lg.draw(self.pressedSelectedImage,self.x, self.y, self.rotation, self.w/self.pressedSelectedImage:getWidth(), self.h/self.pressedSelectedImage:getHeight())
					else
						self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					end
					lg.setColor(self.pressedSelectedOutlineColor)
					lg.setLineWidth(self.pressedSelectedOutlineWidth)
					self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					lg.setColor(self.pressedSelectedTextBackgroundColor)
					lg.rectangle("fill",
						self.x+self.w/2 - self.font:getWidth(self.pressedSelectedText)/2 + self.textXOffset - self.pressedSelectedTextBackgroundBuffer,
						self.y+self.h/2 - self.font:getHeight(self.pressedSelectedText)/2 + self.textYOffset - self.pressedSelectedTextBackgroundBuffer,
						self.font:getWidth(self.pressedSelectedText)+self.pressedSelectedTextBackgroundBuffer*2,
						self.font:getHeight(self.pressedSelectedText)+self.pressedSelectedTextBackgroundBuffer*2
					)
					lg.setColor(self.pressedSelectedTextColor)
					lg.setFont(self.font)
					lg.print(self.pressedSelectedText, self.x+self.w/2 - self.font:getWidth(self.pressedSelectedText)/2 + self.textXOffset, 
						self.y + self.h/2- self.font:getHeight(self.pressedSelectedText)/2 + self.textYOffset)
				else
					-- draw pressed not selected
					lg.setColor(self.pressedColor)
					if self.pressedImage then
						lg.draw(self.pressedImage,self.x, self.y, self.rotation, self.w/self.hoverImage:getWidth(), self.h/self.hoverImage:getHeight())
					else
						self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					end
					lg.setColor(self.pressedOutlineColor)
					lg.setLineWidth(self.pressedOutlineWidth)
					self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					lg.setColor(self.pressedTextBackgroundColor)
					lg.rectangle("fill",
						self.x+self.w/2 - self.font:getWidth(self.pressedText)/2 + self.textXOffset - self.pressedTextBackgroundBuffer,
						self.y+self.h/2 - self.font:getHeight(self.pressedText)/2 + self.textYOffset - self.pressedTextBackgroundBuffer,
						self.font:getWidth(self.pressedText)+self.pressedTextBackgroundBuffer*2,
						self.font:getHeight(self.pressedText)+self.pressedTextBackgroundBuffer*2
					)
					lg.setColor(self.pressedTextColor)
					lg.setFont(self.font)
					lg.print(self.pressedText, self.x+self.w/2 - self.font:getWidth(self.pressedText)/2 + self.textXOffset, 
						self.y + self.h/2- self.font:getHeight(self.pressedText)/2 + self.textYOffset)
				end
			else
				if self.selected then
					lg.setColor(self.hoverSelectedColor)
					if self.hoverSelectedImage then
						lg.draw(self.hoverSelectedImage,self.x, self.y, self.rotation, self.w/self.hoverSelectedImage:getWidth(), self.h/self.hoverSelectedImage:getHeight())
					else
						self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					end
					lg.setColor(self.hoverSelectedOutlineColor)
					lg.setLineWidth(self.hoverSelectedOutlineWidth)
					self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					lg.setColor(self.hoverSelectedTextBackgroundColor)
					lg.rectangle("fill",
						self.x+self.w/2 - self.font:getWidth(self.hoverSelectedText)/2 + self.textXOffset - self.hoverSelectedTextBackgroundBuffer,
						self.y+self.h/2 - self.font:getHeight(self.hoverSelectedText)/2 + self.textYOffset - self.hoverSelectedTextBackgroundBuffer,
						self.font:getWidth(self.hoverSelectedText)+self.hoverSelectedTextBackgroundBuffer*2,
						self.font:getHeight(self.hoverSelectedText)+self.hoverSelectedTextBackgroundBuffer*2
					)
					lg.setColor(self.hoverSelectedTextColor)
					lg.setFont(self.font)
					lg.print(self.hoverSelectedText, self.x+self.w/2 - self.font:getWidth(self.hoverSelectedText)/2 + self.textXOffset, 
						self.y + self.h/2- self.font:getHeight(self.hoverSelectedText)/2 + self.textYOffset)
				else
					lg.setColor(self.hoverColor)
					if self.hoverImage then
						lg.draw(self.hoverImage,self.x, self.y, self.rotation, self.w/self.hoverImage:getWidth(), self.h/self.hoverImage:getHeight())
					else
						self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					end
					lg.setColor(self.hoverOutlineColor)
					lg.setLineWidth(self.hoverOutlineWidth)
					self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
					lg.setColor(self.hoverTextBackgroundColor)
					lg.rectangle("fill",
						self.x+self.w/2 - self.font:getWidth(self.hoverText)/2 + self.textXOffset - self.hoverTextBackgroundBuffer,
						self.y+self.h/2 - self.font:getHeight(self.hoverText)/2 + self.textYOffset - self.hoverTextBackgroundBuffer,
						self.font:getWidth(self.hoverText)+self.hoverTextBackgroundBuffer*2,
						self.font:getHeight(self.hoverText)+self.hoverTextBackgroundBuffer*2
					)
					lg.setColor(self.hoverTextColor)
					lg.setFont(self.font)
					lg.print(self.hoverText, self.x+self.w/2 - self.font:getWidth(self.hoverText)/2 + self.textXOffset, 
						self.y + self.h/2- self.font:getHeight(self.hoverText)/2 + self.textYOffset)
				end

			end
			if self.isPrompting then
				self:prompt()
			end
		else
			if self.selected then
				lg.setColor(self.selectedColor)
				if self.selectedImage then
					lg.draw(self.selectedImage,self.x, self.y, self.rotation, self.w/self.selectedImage:getWidth(), self.h/self.selectedImage:getHeight())
				else
					self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
				end
				lg.setColor(self.selectedOutlineColor)
				lg.setLineWidth(self.selectedOutlineWidth)
				self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
				lg.setColor(self.selectedTextBackgroundColor)
				lg.rectangle("fill",
					self.x+self.w/2 - self.font:getWidth(self.selectedText)/2 + self.textXOffset - self.selectedTextBackgroundBuffer,
					self.y+self.h/2 - self.font:getHeight(self.selectedText)/2 + self.textYOffset - self.selectedTextBackgroundBuffer,
					self.font:getWidth(self.selectedText)+self.selectedTextBackgroundBuffer*2,
					self.font:getHeight(self.selectedText)+self.selectedTextBackgroundBuffer*2
				)
				lg.setColor(self.selectedTextColor)
				lg.setFont(self.font)
				lg.print(self.selectedText, self.x+self.w/2 - self.font:getWidth(self.selectedText)/2 + self.textXOffset, 
					self.y + self.h/2- self.font:getHeight(self.selectedText)/2 + self.textYOffset)
			else
				lg.setColor(self.color)
				if self.image then
					lg.draw(self.image,self.x, self.y, self.rotation, self.w/self.image:getWidth(), self.h/self.image:getHeight())
				else
					self.shape("fill", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
				end
				lg.setColor(self.outlineColor)
				lg.setLineWidth(self.outlineWidth)
				self.shape("line", self.x, self.y, self.w, self.h, self.roundedCornersRadius, self.roundedCornersRadius)
				lg.setColor(self.textBackgroundColor)
				lg.rectangle("fill",
					self.x+self.w/2 - self.font:getWidth(self.text)/2 + self.textXOffset - self.textBackgroundBuffer,
					self.y+self.h/2 - self.font:getHeight(self.text)/2 + self.textYOffset - self.textBackgroundBuffer,
					self.font:getWidth(self.text)+self.textBackgroundBuffer*2,
					self.font:getHeight(self.text)+self.textBackgroundBuffer*2
				)
				lg.setColor(self.textColor)
				lg.setFont(self.font)
				lg.print(self.text, self.x+self.w/2 - self.font:getWidth(self.text)/2 + self.textXOffset, 
					self.y + self.h/2- self.font:getHeight(self.text)/2 + self.textYOffset)
			end
		end
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
	local mx, my = love.mouse.getPosition()
	if self:inBounds(x,y) then
		if self:keyPressed(key) then
			self.origPress = true
			self:onPress()
		end
	end
end
function button:keyreleased(key, istouch, presses)
	local mx, my = love.mouse.getPosition()
	if self:inBounds(x,y) then
		if self.requireSelfClick and self.origPress or not self.requireSelfClick then
			if self:keyPressed(key) then
				self:onRelease()
			end
		end
	end
	self.origPress = false
end

-- draws popup message  Put in love's draw loop above other buttons it may overlap
function button:prompt()
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


-- Returns if x,y position is inside boundary of button
function button:inBounds(x,y)
	return x > self.x and
		x < self.x + self.w and
		y > self.y and
		y < self.y + self.h
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
	argargs (...) for the following functions can be use like...
	false/nil will only set the main variable (the first one under if input == true)
	true will set all button states to that variable
	table of variable strings to set those variables
		-- i.e. button:setText example
		button:setText("this is a test button!", {"selectedText", "pressedSelectedText", "hoverSelectedText"})
]]
function button:setText(text, ...)
	local input = ...
	if input == true then 
		self.text = text
		self.hoverText = text
		self.pressedText = text
		self.selectedText = text
		self.pressedSelectedText = text 
		self.hoverSelectedText = text
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
		self.textColor = col
		self.hoverTextColor = col
		self.pressedTextColor = col
		self.selectedTextColor = col
		self.hoverSelectedTextColor = col
		self.pressedSelectedTextColor = col
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
		self.textBackgroundColor = col
		self.hoverTextBackgroundColor = col
		self.pressedTextBackgroundColor = col
		self.selectedTextBackgroundColor = col
		self.hoverSelectedTextBackgroundColor = col
		self.pressedSelectedTextBackgroundColor = col
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
		self.textBackgroundBuffer = buffer
		self.hoverTextBackgroundBuffer = buffer
		self.pressedTextBackgroundBuffer = buffer
		self.selectedTextBackgroundBuffer = buffer
		self.hoverSelectedTextBackgroundBuffer = buffer
		self.pressedSelectedTextBackgroundBuffer = buffer
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
		self.image = formatImage( image )
		self.hoverImage = self.image
		self.pressedImage = self.image
		self.selectedImage = self.image
		self.hoverSelectedImage = self.image
		self.pressedSelectedImage = self.image
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
		self.color = col
		self.hoverColor = col
		self.pressedColor = col
		self.selectedColor = col
		self.hoverSelectedColor = col
		self.pressedSelectedColor = col
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
		self.outlineColor = col
		self.hoverOutlineColor = col
		self.pressedOutlineColor = col
		self.selectedOutlineColor = col
		self.hoverSelectedOutlineColor = col
		self.pressedSelectedOutlineColor = col
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
		self.outlineWidth = w
		self.pressedOutlineWidth = w
		self.pressedOutlineWidth = w 
		self.selectedOutlineWidth = w
		self.hoverSelectedOutlineWidth = w
		self.pressedSelectedOutlineWidth = w
	elseif not input then
		self.outlineWidth = w
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = w
		end
	end
end
-- end of vararg functions

function button:setPosition(x,y)
	self.x, self.y = x or self.x, y or self.y
end
function button:setDimensions(w,h)
	self.w, self.h = w or self.w, h or self.h
end

-- set what happens when cursor enters/exits the boundaries of the button
function button:setOnEnter(func)
	self.onEnter = func
end
function button:setOnExit(func)
	self.onExit = func
end

-- sets what happens when cursor hovers over button for longer than self.hoverPromptTime.
function button:setHover(func)
	self.hover = func
end

-- sets what happens when you press/release the button
function button:setOnPress(func)
	self.onPress = func
end
function button:setOnRelease(func)
	self.onRelease = func
end
--sets if the original press needs to be inside the button boundary to trigger release
function button:setRequireSelfClick(bool)
	assert(type(bool) == boolean, "Boolean required.")
	self.requireSelfClick = bool
end

-- for custom draw functions
function button:setDraw(func)
	self.draw = func
end
-- for custom update functions
function button:setUpdate(func)
	self.update = func
end

-- sets what buttons can be used to click button
function button:setTriggerMouse(tab)
	self.triggerMouse = tab
end
function button:setTriggerKeyboard(tab)
	self.triggerKeyboard = tab
end

function button:setFont(font)
	self.font = lg.newFont(font)
end

function button:setTextScale(scale)
	self.textScale = scale
end

-- offset that the text will draw from the center
function button:setTextOffset(x,y)
	self.textXOffset, self.textYOffset = x or self.textXOffset, y or self.textYOffset
end

function button:setRotation(r)
	self.rotation = r
end

function button:setRoundedCornerRadius(r)
	self.roundedCornersRadius = r
end

-- changes from one shape to another.  i.e. rectangle button to circle button.
-- function button:setShape(shape)
-- 	self.shape = shape
-- end

-- hovered 
function button:setHoverLineWidth(w)
	self.hoverOutlineWidth = w
end

function button:setHoverFuncTime(time)
	self.hoverFuncTime = time
end


-- pressed 
function button:setPressed(bool)
	self.isPressed = bool
end

-- selected
function button:setHoverSelectedOutlineWidth(w)
	self.hoverSelectedOutlineWidth = w
end

-- pressed and selected 
function button:setPressedSelectedOutlineWidth(w)
	self.pressedSelectedOutlineWidth = w
end

-- prompt 

function button:setPromptText(text)
	self.hoverPromptText = text
end

function button:setPromptTextBackgroundColor(col)
	self.promptTextBackgroundColor = col
end

function button:setPromptTextBackgroundBuffer(buffer)
	self.promptTextBackgroundBuffer = buffer
end

function button:setPromptColor(col)
	self.promptColor = col
end

function button:setPromptOutlineColor(col)
	self.promptOutlineColor = col
end

function button:setPromptOutlineWidth(w)
	self.promptOutlineWidth = w
end

function button:setHoverPromptTime(t)
	self.hoverPromptTime = t
end

function button:setHoverTime(t)
	self.hoverTime = t
end

function button:setPrompting(bool)
	self.isPrompting = bool
end

function button:setPromptBuffer(x,y)
	self.promptXBuffer, self.promptYBuffer = x or 0, y or 0
end

function button:setPromptWindowLock(bool)
	self.lockPromptToWindow = bool
end





---------------------
----Get Functions----
---------------------

function button:get(variable)
	return self[variable]
end

-- main get functions

function button:getPosition()
	return self.x, self.y
end

function button:getDimensions()
	return self.w, self.h
end

function button:getFont()
	return self.font
end

function button:getRotation()
	return self.rotation
end

function button:getRoundedCornerRadius()
	return self.roundedCornersRadius
end

function button:getTextScale()
	return self.textScale
end

function button:getTriggerMouse()
	return self.triggerMouse
end

function button:getTriggerKeyboard()
	return self.triggerKeyboard
end

-- not hovered 

-- allStates is for pressed and hover text
function button:getText()
	return self.text
end

function button:getTextColor()
	return self.textColor
end

function button:getImage()
	return self.image
end

function button:getColor()
	return self.color
end

function button:getOutlineColor()
	return self.outlineColor
end

function button:getOutlineWidth()
	return self.outlineWidth
end

-- hovered 

function button:gethoverText()
	return self.hoverText
end

function button:gethoverTextColor()
	return self.hoverTextColor
end

function button:gethoverImage()
	return self.hoverImage
end

function button:getHoverColor()
	return self.hoverColor
end

function button:getHoverOutlineColor()
	return self.hoverOutlineColor
end

function button:getHoverLineWidth()
	return self.hoverOutlineWidth
end

function button:getIsHovering()
	return self.isHovering
end


-- prompt 
function button:getPromptText()
	return self.hoverPromptText
end

function button:getPromptTextColor()
	return self.promptTextColor
end

function button:getPromptColor()
	return self.promptColor
end

function button:getPromptOutlineColor()
	return self.promptOutlineColor
end

function button:getPromptOutlineWidth()
	return self.promptOutlineWidth
end

function button:getHoverPromptTime()
	return self.hoverPromptTime
end

function button:getHoverTime()
	return self.hoverTime
end

function button:getPrompting()
	return self.isPrompting
end

function button:getPromptBuffer()
	return self.promptXBuffer, self.promptYBuffer
end

function button:getPromptWindowLock()
	return self.lockPromptToWindow
end

-- pressed 

function button:getpressedText()
	return self.pressedText
end

function button:getOnPressImage()
	return self.pressedImage
end

function button:getPressedColor()
	return self.pressedColor
end

function button:getPressedOutlineColor()
	return self.pressedOutlineColor
end

function button:getPressedTextColor()
	return self.pressedTextColor
end

function button:getPressed()
	return self.isPressed
end

-- selected

function button:getSelectedText()
	return self.selectedText
end

function button:getSelectedTextColor()
	return self.selectedTextColor
end

function button:getSelectedImage()
	return self.selectedImage
end

function button:getSelectedColor()
	return self.selectedColor
end

function button:getSelectedOutlineColor()
	return self.selectedOutlineColor
end

function button:getSelected()
	return self.selected
end

-- function to clone button


---- return
return button