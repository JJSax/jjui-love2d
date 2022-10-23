
local button = {}
button.__index = button
button._version = "0.9.2"

local ORIGIN = {x = 0, y = 0}

local lg = love.graphics
local common = require((...):gsub('%.[^%.]*%.[^%.]+$', '')..".common")

-------------------------------------------
-------------Local Functions---------------
-------------------------------------------

local function getDefault()
	return {
		font = lg.getFont(), rotation = 0,
		fitText = false, fitHoverText = true, visible = true,
		requireSelfClick = true, -- require press to happen in this button, then release in this button.
		parent = ORIGIN,
		triggerMouse = {1}, triggerKeyboard = {}, -- array of buttons to detect isDown

		-- Keep in mind, you cannot be pressed while not being hovered.
		-- Variables for when the button is not hovered, or selected.
		text = "", -- text to print
		textRotation = 0,
		textColor = {1,1,1,1}, -- Color of text
		textBackgroundColor = {0,0,0,0}, -- Color of box behind text
		textBackgroundBuffer = 1, -- Buffer in pixels for surrounding highlight.
		textXOffset = 0, -- Horizontal text offset within button.  Note, doesn't have to be inside button.
		textYOffset = 0, -- Vertical offset within button
		image = nil, -- Image to draw, has to be lg.newImage, not path to image.  You can use formatImage.
		color = {1,1,1,1}, -- Color of main button area.
		outlineColor = {0,0,0,0}, -- Color of outline draw.
		outlineWidth = 0, -- Width of outline

		-- Button state while hovered, but not selected.
		hoverText = "",
		hoverTextRotation = 0,
		hoverTextColor = {1,1,1,1},
		hoverTextBackgroundColor = {0,0,0,0},
		hoverTextBackgroundBuffer = 1,
		hoverImage = nil, -- not selected; hovered; not pressed
		hoverColor = {0.8,0.8,0.8,1},
		hoverOutlineColor = {0,0,0,0},
		hoverOutlineWidth = 1,
		isHovering = false,
		 -- additional hover variable
		hoverTime = 0,
		hoverFuncTime = 1,

		-- Button state while pressed but not selected,
		 -- AKA trigger mouse/keyboard held while hovering over the button not yet triggered.
		pressedText = "",
		pressedTextRotation = 0,
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
		selectedTextRotation = 0,
		selectedTextColor = {1,1,1,1},
		selectedTextBackgroundColor = {0,0,0,0},
		selectedTextBackgroundBuffer = 1,
		selectedImage = nil, -- selected; not hovered; not pressed
		selectedColor = {1,1,1,1},
		selectedOutlineColor = {0,0,0,0},
		selectedOutlineWidth = 1,
		selected = false,

		-- Button state selected and hovered, not pressed
		hoverSelectedText = "",
		hoverSelectedTextRotation = 0,
		hoverSelectedTextColor = {1,1,1,1},
		hoverSelectedTextBackgroundColor = {0,0,0,0},
		hoverSelectedTextBackgroundBuffer = 1,
		hoverSelectedImage = nil, -- selected; hovered; not pressed
		hoverSelectedColor = {0.8,0.8,0.8,1},
		hoverSelectedOutlineColor = {0,0,0,0},
		hoverSelectedOutlineWidth = 1,

		-- Button state selected and pressed
		pressedSelectedText = "",
		pressedSelectedTextRotation = 0,
		pressedSelectedTextColor = {1,1,1,1},
		pressedSelectedTextBackgroundColor = {0,0,0,0},
		pressedSelectedTextBackgroundBuffer = 1,
		pressedSelectedImage = nil, -- selected; hovered; pressed
		pressedSelectedColor = {0.7,0.7,0.7,1},
		pressedSelectedOutlineColor = {0,0,0,0},
		pressedSelectedOutlineWidth = 1,

		-- Prompting
		promptText = "",
		promptFont = lg.getFont(),
		promptTextColor = {1,1,1,1},
		promptColor = {0,0,0,0},
		promptOutlineColor = {0,0,0,0},
		promptOutlineWidth = 1,
		promptGap = {2, 2}, -- this is the extra space around prompt text
		promptOffset = {0, 0},
		promptPosition = nil,
		hoverPromptTime = 1,
		isPrompting = false,
		lockPromptToWindow = true,

		pressTime = 0,
		heldTriggerTime = 1,
		held = false,
	}
end

--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------

function button.newPolygonButton(x, y, vertices, extra)
	assert(type(vertices) == "table", "Parameter #3 requires table of vertices.")

	local properties = getDefault()
	properties.shape = lg.polygon
	properties.vertices = vertices
	properties.x, properties.y = x, y
	properties = common.merge(properties, extra)

	local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
	local xt, yt = {}, {}
	for i = 1, #vertices, 2 do
		if vertices[i] < minx then minx = vertices[i] end
		if vertices[i] > maxx then maxx = vertices[i] end
		if vertices[i+1] < miny then miny = vertices[i+1] end
		if vertices[i+1] > maxy then maxy = vertices[i+1] end

		table.insert(xt, vertices[i])
		table.insert(yt, vertices[i+1])

	end
	properties.w, properties.h = math.abs(maxx - minx), math.abs(maxy - miny)
	properties.centerx, properties.centery = common.average(xt), common.average(yt)

	return setmetatable(properties, button)
end

--
function button.newRectangleButton(l, t, w, h, extra)
	return button.newPolygonButton(
		l, t,
		{0, 0, w, 0,
		w, h, 0, h},
		extra
	)
end

function button.newArcButton(x, y, radius, angle1, angle2, extra)
	local properties = getDefault()
	properties.centerx, properties.centery = 0, 0
	properties.x, properties.y, properties.radius = x, y, radius
	properties.angle1, properties.angle2 = angle1, angle2
	properties.shape = lg.arc
	properties.arctype = "pie"
	properties.textOrientation = "angled"
	properties = common.merge(properties, extra)

	return setmetatable(properties, button)
end

function button.newAngleButton(x, y, radius, startAngle, addAngle, extra)
	return button.newArcButton(x, y, radius, startAngle, startAngle + addAngle, extra)
end


function button.newCircleButton(x, y, r, extra)
	return button.newArcButton(x, y, r, 0, 0, {shape = lg.circle})
end

--------------------------------------------
--------------Main Functions----------------
--Run these in their respective love loops--
--------------------------------------------
function button:update(dt)
	self:onUpdate(dt)
	local mx, my = love.mouse.getPosition()
	if self:inBounds(mx, my) then
		local press, _ = self:anyIsDown()
		self.isPressed = press and self.requireSelfClick and self.origPress
		if not self.isHovering then
			self.onEnter()
			self.isHovering = true
		end
		if self.hoverTime > self.hoverFuncTime then
			self.hover()
		end
		self.hoverTime = self.hoverTime + dt

		if self.isPressed then
			self.pressTime = self.pressTime + dt
			if self.pressTime > self.heldTriggerTime then
				if not self.held then
					self.held = true
					self:onholdStart()
				end
				self:onHold()
			end
		else
			if self.held then
				self:onHoldStop()
				self.held = false
			end
		end

		self.isPrompting = self.hoverTime > self.hoverPromptTime
	elseif self.isHovering then
		self.onExit()
		self.isHovering = false
		self.hoverTime = 0
		self.isPressed = false
		self.isPrompting = false
		if self.held then
			self:onHoldStop()
			self.held = false
		end
	end
end

function button:draw()
	if not self.visible then return false end
	lg.push("all")
	local fV = common.formatVariable
	local v = {}
	if self.isHovering then table.insert(v, "hover") end
	if self.isPressed then table.insert(v, "pressed") end
	if self.selected then table.insert(v, "selected") end

	local x, y = self.x + self.parent.x, self.y + self.parent.y
	lg.translate(x, y)

	-- draw
	lg.setColor(self[fV("color", v)])
	local im = self[fV("image", v)]
	if im then
		local w, h = self.w or self.radius * 2, self.h or self.radius * 2
		lg.draw(im, 0, 0, self.rotation,
			w/im:getWidth(), h/im:getHeight(),
			self.radius and im:getWidth()/2, self.radius and im:getHeight()/2
		)
	else
		local shapePack = {
			[lg.polygon] = {self.vertices},
			[lg.circle] = {0,0, self.radius},
			[lg.arc] = {0, 0, self.radius, self.angle1, self.angle2}
		}
		self.shape("fill", unpack(shapePack[self.shape]))
		lg.setColor(self[fV("outlineColor", v)])
		lg.setLineWidth(self[fV("outlineWidth", v)])
		self.shape("line", unpack(shapePack[self.shape]))
	end

	-- rectangle for text background
	lg.setColor( self[fV("textBackgroundColor", v)] )
	local txt =  self[fV("text", v)]
	local tbb =  self[fV("textBackgroundBuffer", v)]
	local tr  =  self[fV("textRotation", v)]

	lg.translate(self.textXOffset, self.textYOffset)
	local tw, th = self.font:getWidth(txt), self.font:getHeight(txt)
	local txtx, txty = self.centerx + self.textXOffset,
		self.centery + self.textYOffset
	if self.shape == lg.arc then
		if self.textOrientation == "angled" then
			tr = self:getCenterAngle()
			txtx, txty = common.vector(tr, self.radius/1.5)
			local halfpi = math.pi/2
			if tr > halfpi and tr <= halfpi*3 then
				tr = tr + -math.pi
			end
		end
	end
	lg.rectangle("fill",
		txtx - tbb - tw/2,	txty - tbb - th/2,
		tw + tbb*2, th + tbb*2
	)
	lg.setColor(self[fV("textColor", v)])
	lg.setFont(self.font)
	lg.print(txt, txtx, txty, tr, 1, 1,
		math.floor(self.font:getWidth(txt)/2), math.floor(self.font:getHeight()/2))


	lg.pop()
end

function button:mousepressed(x, y, key, istouch, presses)
	if self:inBounds(x,y) then
		if common.inside(self.triggerMouse, key) then
			self.origPress = true
			self:onPress(x, y, key, istouch, presses)
		end
	end
end
function button:mousereleased(x, y, key, istouch, presses)
	if self:inBounds(x,y) then
		if self.requireSelfClick and self.origPress or not self.requireSelfClick then
			if common.inside(self.triggerMouse, key) then
				self:onRelease(x, y, key, istouch, presses)
			end
		end
	end
	self.origPress = false
end
function button:mouseIsDown()
	for k,v in ipairs(self.triggerMouse) do
		if love.mouse.isDown(v) then
			return true
		end
	end
	return false
end

function button:keypressed(key, istouch, presses)
	if not self:inBounds(love.mouse.getPosition()) then return end
	if common.inside(self.triggerKeyboard, key) then
		self.origPress = true
		local x, y = love.mouse.getPosition()
		self:onPress(x, y, key, istouch, presses)
	end
end
function button:keyreleased(key, istouch, presses)
	if self:inBounds(love.mouse.getPosition()) then
		if self.requireSelfClick and self.origPress or not self.requireSelfClick then
			if common.inside(self.triggerKeyboard, key) then
				local x, y = love.mouse.getPosition()
				self:onRelease(x, y, key, istouch, presses)
			end
		end
	end
	self.origPress = false
end
function button:keyIsDown()
	for k,v in ipairs(self.triggerKeyboard) do
		if love.keyboard.isDown(v) then
			return true
		end
	end
	return false
end

-- draws popup message  Put in love's draw loop after other buttons it may overlap
function button:prompt()
	if not self.isPrompting then return false end

	local buffX, buffY = unpack(self.promptGap)
	local font = self.promptFont
	local text = self.promptText
	local mx, my = love.mouse.getPosition()
	mx, my = mx + self.promptOffset[1], my + self.promptOffset[2]
	local pW, pY = font:getWidth (text) + buffX * 2,
				   font:getHeight(text) + buffY * 2

	if self.lockPromptToWindow then
		mx = common.clamp(mx, 0, lg.getWidth() - font:getWidth(text))
		my = common.clamp(my, 0, lg.getHeight() - font:getHeight())
	end
	local rectX, rectY = mx - buffX, my - buffY

	if self.promptPosition then
		rectX, rectY = unpack(self.promptPosition)
	end

	lg.setColor(self.promptColor)
	lg.rectangle("fill", rectX, rectY, pW, pY)
	lg.setColor(self.promptOutlineColor)
	lg.setLineWidth(self.promptOutlineWidth)
	lg.rectangle("line", rectX, rectY, pW, pY)
	lg.setColor(self.promptTextColor)
	lg.setFont(font)
	lg.print(text, rectX + buffX, rectY + buffY)
	return true
end


--------------------------------------------
-------------Common Functions---------------
--------------------------------------------
function button:onUpdate() end
function button:onRelease() end
function button:onPress() end
function button:hover() end
function button:onEnter() end
function button:onExit() end
function button:onholdStart() end
function button:onHold() end
function button:onHoldStop() end

-- Returns if x,y position is inside boundary of button
-- Adapted Polygon Collision from to Stack Overflow user Peter Gilmour
function button:inBounds(x,y)
	x, y = lg.inverseTransformPoint(x - self.x, y - self.y)
	if self.shape == lg.polygon then
		local vert = self.vertices
		local oddNodes = false
		local j = #vert-1
		for i = 1, #vert, 2 do
			if (vert[i+1] < y and vert[j+1] >= y or
			vert[j+1] < y and vert[i+1] >= y) then
				if (vert[i] + ( y - vert[i+1] ) / (vert[j+1] - vert[i+1] ) * (vert[j] - vert[i]) < x) then
					oddNodes = not oddNodes
				end
			end
			j = i
		end
		return oddNodes
	elseif self.shape == lg.circle then
		return common.dist(x, y, 0 + self.parent.x,0 + self.parent.y) <= self.radius
	elseif self.shape == lg.arc then
		local mx, my = love.mouse.getPosition()
		local mouseAngle = common.angle(mx, my, self.x + self.parent.x, self.y + self.parent.y)
		local dist = common.dist(x, y, 0 + self.parent.x, 0 + self.parent.y)
		return common.between(self.angle1, self.angle2, mouseAngle + math.pi) and dist <= self.radius
	end
end

-- if key not passed, it will check if it is down.
function button:anyIsDown(key)
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
-- If you want the button to have a toggled on/off state,
	-- run this inside it's onPress or onRelease functions
function button:toggle(bool)
	self.selected = bool and bool or not self.selected
end

function button:getCenterAngle()
	assert(self.shape == lg.arc, "getCenterAngle requires an arc button.")
	return self.angle2 - (self.angle2 - self.angle1)/2
end

---------------------
----Set Functions----
---------------------


-- main set functions

function button:setVertices(...)
	assert(self.shape == lg.polygon, "Button type is not a polygon.")
	local verts = {...}
	if type(verts[1]) == "table" then verts = verts[1] end
	assert(#verts % 2 == 0, "Number of vertices must be an even number.")
	self.vertices = verts
end


--[[
	varargs (...) for the following functions can be use like...
	false/nil will only set the main variable (the first one under if input == true)
	true will set all button states to that variable
	table of variable strings to set those variables
		-- i.e. button:setText example
		button:setText("this is a test button!",
			{"selectedText", "pressedSelectedText", "hoverSelectedText"})
]]
function button:setVar(var, value, ...)

	--[[
		Valid Var is case sensitive.
		This function is for a quick way to set multiple variables.
	]]

	local validVar = {
		"Text", "TextRotation", "TextColor", "TextBackgroundColor",
		"TextBackgroundBuffer", "Image", "Color", "OutlineColor",
		"OutlineWidth"
	}
	assert(common.inside(validVar, var),
		"Valid param1 not passed. valid options are\n"..
		table.concat( validVar, "\n")
	)

	local input = ...
	if input == true then
		for v in common.simVarIter(var) do
			self[v] = value
		end
	elseif not input then
		self[var] = value
	elseif type(input) == "table" then
		for k,v in pairs( input ) do
			self[v] = value
		end
	end
end

function button:setText(text, ...)
	self:setVar("Text", text, ...) end
function button:setTextRotation(rotation, ...)
	self:setVar("TextRotation", rotation, ...) end
function button:setTextColor(col, ...)
	self:setVar("TextColor", col, ...) end
function button:setTextBackgroundColor(col, ...)
	self:setVar("TextBackgroundColor", col, ...) end
function button:setTextBackgroundBuffer(buffer, ...)
	self:setVar("TextBackgroundBuffer", buffer, ...) end
function button:setImage(image, ...)
	self:setVar("Image", common.formatImage(image), ...) end
function button:setColor(col, ...)
	self:setVar("Color", col, ...) end
function button:setOutlineColor(col, ...)
	self:setVar("OutlineColor", col, ...) end
function button:setOutlineWidth(w, ...)
	self:setVar("OutlineWidth", w, ...) end


return button
