
local button = {}
button.__index = button
button._version = "0.9.9"

local ORIGIN = {x = 0, y = 0}

local lg = love.graphics
local uiRoot = (...):gsub('%.[^%.]*%.[^%.]+$', '')
local common = require(uiRoot..".common")
local geometry = require(uiRoot..".geometry")
local Set = require(uiRoot..".Set")

-------------------------------------------
-------------Local Functions---------------
-------------------------------------------

local function getDefault()
	local self = {
		rotation = 0,
		parent = ORIGIN,
		visible = true,
		requireSelfClick = true, -- require press to happen in this button, then release in this button.
		hoverTime = 0,
		hoverFuncTime = 1,
		disabled = false,
		default = true, -- if not pressed and not hovering
		pressed = false,
		hovered = false,
		selected = false,
		triggerMouse = {1}, triggerKeyboard = {}, -- array of buttons to detect isDown

		pressTime = 0,
		heldTriggerTime = 1,
		held = false,
	}
	self.prompt = common.newVarSet()
	self.prompt.offset = {0,0}
	self.prompt.position = nil
	self.prompt.hoverTime = 1
	self.prompt.prompting = false
	self.prompt.lockToWindow = true
	common.standardButton(self)
	return self
end

--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------

function button.newPolygonButton(x, y, vertices, extra)
	assert(type(vertices) == "table", "Parameter #3 requires table of vertices.")

	local self = getDefault()
	self.shape = lg.polygon
	self.vertices = vertices
	self.x, self.y = x, y
	self = common.merge(self, extra)

	local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
	local xt, yt = {}, {}
	for i = 1, #vertices, 2 do
		if vertices[i]   < minx then minx = vertices[i] end
		if vertices[i]   > maxx then maxx = vertices[i] end
		if vertices[i+1] < miny then miny = vertices[i+1] end
		if vertices[i+1] > maxy then maxy = vertices[i+1] end

		table.insert(xt, vertices[i])
		table.insert(yt, vertices[i+1])

	end
	self.w, self.h = math.abs(maxx - minx), math.abs(maxy - miny)
	-- self.centerx, self.centery = common.average(xt), common.average(yt) --? Why did I use average?
	self.centerx, self.centery = minx + (maxx - minx)/2, miny + (maxy - miny)/2

	return setmetatable(self, button)
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
	local self = getDefault()
	self.centerx, self.centery = 0, 0
	self.x, self.y, self.radius = x, y, radius
	self.angle1, self.angle2 = angle1, angle2
	self.shape = lg.arc
	self.arctype = "pie"
	self.textOrientation = "angled"
	self = common.merge(self, extra)

	return setmetatable(self, button)
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
	if self.disabled then return end

	self:onUpdate(dt)

	local mx, my = love.mouse.getPosition()
	if self:inBounds(mx, my) then
		local press, _ = self:anyIsDown()
		self.pressed = press and self.requireSelfClick and self.origPress
		if not self.hovered then
			self.onEnter()
			self.hovered = true
		end
		self.hoverTime = self.hoverTime + dt
		if self.hoverTime > self.hoverFuncTime then
			self.hover()
		end

		if self.pressed then
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

		self.prompting = self.hoverTime > self.prompt.hoverTime
	elseif self.hovered then
		self.onExit()
		self.hovered = false
		self.hoverTime = 0
		self.pressed = false
		self.prompting = false
		if self.held then
			self:onHoldStop()
			self.held = false
		end
	end
end

function button:draw()
	if not self.visible then return false end

	lg.push("all")
	lg.translate(self.x + self.parent.x, self.y + self.parent.y)

	local state = common.getState(self)
	-- draw
	lg.setColor(state.color)
	local im = state.image
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
		lg.setColor(state.outlineColor)
		lg.setLineWidth(state.outlineWidth)
		self.shape("line", unpack(shapePack[self.shape]))
	end

	-- rectangle for text background
	lg.setColor( state.textBackgroundColor )
	local txt =  state.text
	local tbb =  state.textBackgroundBuffer
	local tr  =  state.textRotation

	lg.translate(state.textXOffset, state.textYOffset)
	local tw, th = state.font:getWidth(txt), state.font:getHeight(txt)
	local txtx, txty = self.centerx + state.textXOffset,
		self.centery + state.textYOffset
	if self.shape == lg.arc then
		if self.textOrientation == "angled" then
			tr = self:getCenterAngle()
			txtx, txty = geometry.vector(tr, self.radius/1.5)
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
	lg.setColor(state.textColor)
	lg.setFont(state.font)
	lg.print(txt, txtx, txty, tr, 1, 1,
		math.floor(state.font:getWidth(txt)/2), math.floor(state.font:getHeight()/2))

	lg.pop()
end

function button:mousepressed(x, y, key, istouch, presses)
	if not self:inBounds(x,y) then return false end
	if common.inside(self.triggerMouse, key) then
		self.origPress = true
		self:onPress(x, y, key, istouch, presses)
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
	return love.mouse.isDown(self.triggerMouse)
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
	return love.keyboard.isDown(self.triggerKeyboard)
end

-- draws popup message  Put in love's draw loop after other buttons it may overlap
function button:drawPrompt()
	if not self.prompting then return false end

	local buffX, buffY = self.prompt.textBackgroundBuffer, self.prompt.textBackgroundBuffer
	local font = self.prompt.font
	local text = self.prompt.text
	local mx, my = love.mouse.getPosition()
	mx, my = mx + self.prompt.offset[1], my + self.prompt.offset[2]
	local pW, pY = font:getWidth (text) + buffX * 2,
				   font:getHeight(text) + buffY * 2

	if self.lockPromptToWindow then
		mx = common.clamp(mx, 0, lg.getWidth() - font:getWidth(text))
		my = common.clamp(my, 0, lg.getHeight() - font:getHeight())
	end
	local rectX, rectY = mx - buffX, my - buffY

	if self.prompt.position then
		rectX, rectY = unpack(self.prompt.position)
	end

	lg.setColor(self.prompt.color)
	lg.rectangle("fill", rectX, rectY, pW, pY)
	lg.setColor(self.prompt.outlineColor)
	lg.setLineWidth(self.prompt.outlineWidth)
	lg.rectangle("line", rectX, rectY, pW, pY)
	lg.setColor(self.prompt.textColor)
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
function button:_OnToggle() end

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
		return geometry.dist(x, y, 0 + self.parent.x,0 + self.parent.y) <= self.radius
	elseif self.shape == lg.arc then
		local mx, my = love.mouse.getPosition()
		local mouseAngle = geometry.angle(mx, my, self.x + self.parent.x, self.y + self.parent.y)
		local dist = geometry.dist(x, y, 0 + self.parent.x, 0 + self.parent.y)
		return geometry.between(self.angle1, self.angle2, mouseAngle + math.pi) and dist <= self.radius
	end
end

-- if key not passed, it will check if it is down.
function button:anyIsDown()
	return self:keyIsDown() or self:mouseIsDown()
end

-- Toggles if the button is considered selected or not.
-- If you want the button to have a toggled on/off state,
	-- run this inside it's onPress or onRelease functions
function button:toggle(bool)
	self.selected = bool and bool or not self.selected
	self:_OnToggle()
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
	@param3 true will set all button states to that variable
	table of variable strings to set those variables
		-- i.e. button:setText example
		button:setVar("this is a test button!",
			{"selectedText", "pressedSelectedText", "hoverSelectedText"})
]]
local validVar = Set.new{
	"text", "textRotation", "textColor", "textBackgroundColor",
	"textXOffset", "textYOffset", "textBackgroundBuffer", "font",
	"image", "color", "outlineColor", "outlineWidth"
}
function button:setVar(var, value, ...)

	-- @Valid Var is case sensitive.
	-- @var is the variable name.  changing the state color would be "color"
	-- @value is what to set it to
	-- @param3 true will set all button states to that variable
	-- *This function is for a quick way to set multiple variables.

	common.assert(validVar[var],
		"Valid param1 not passed. valid options are\n"..
		table.concat( validVar, "\n"),
		3
	)

	local input = ...
	if input == true then
		for state in common.iterateAllStates(self) do
			state[var] = value
		end
	elseif not input then
		self.state.default[false][var] = value
	elseif type(input) == "table" then
		--* e.g. {{"default", false}, {"pressed", true}}
		if type(input[1]) ~= "table" then
			input = {input} -- single variable
		end
		for i, v in ipairs(input) do
			self.state[v[1]][v[2]][var] = value
		end
	end
end

function button:setImage(image, ...)
	self:setVar("image", common.formatImage(image), ...)
end

return button
