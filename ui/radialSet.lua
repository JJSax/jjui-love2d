
--[[

	--@How to use
	--* require ui
	local ui = require("ui") -- this requires the init.lua file at root
	--* create buttons with included button library
	local b1 = ui.newRectangleButton(0,  5, 100, 25)
	local b2 = ui.newRectangleButton(0, 35, 100, 25)
	local b3 = ui.newRectangleButton(0, 65, 100, 25)
	radio = ui.newRadialSet() --* create set.
	--* alternate method
	-- ui.newRadialSet(b1, b2, b3)
	local font12 = lg.newFont(12)
	for i, v in ipairs({b1, b2, b3}) do
		--* make buttons look like you want them to
		v:setVar("text", "Not Selected", true)
		v:setVar("text", "Selected", {{"default", true}, {"hovered", true}, {"pressed", true}})
		v:setVar("font", font12, true)

		--* Set the button to togglable.  Can be in onPress or onRelease
		function v:onPress()
			v:toggle()
		end
		-- add button if not already added when making the set with alternate method.
		radio:add(v)
	end

]]

local radial = {_VERSION = "0.1.1"}
radial.__index = radial

local uiRoot = (...):gsub('%.[^%.]+$', '')
local common = require(uiRoot..".common")

local function setToggle(self)
	local radio = self
	for i, v in ipairs(self.buttons) do
		function v:_OnToggle()
			if #radio.buttons > 1 and radio.selected and radio.selected ~= i then
				radio.buttons[radio.selected].selected = false
			end
			radio.selected = i
		end
	end
end

function radial.new(...)
	local self = setmetatable({}, radial)

	self.buttons = {...}
	self.selected = nil

	for i, v in ipairs(self.buttons) do
		setToggle(self)
	end
	return self
end

function radial:add(...)
	local object = {...}
	for i, v in ipairs(object) do
		table.insert(self.buttons, v)
	end
	setToggle(self)
end

local function remove(self, i)
	table.remove(self.buttons, i)
	if self.selected == i then
		self.selected = nil
		return true
	end
	if self.selected and self.selected >= i then
		self.selected = self.selected-1
	end
	return true
end
function radial:remove(...)
	for i, v in ipairs({...}) do
		if type(v) == "number" then
			common.assert(v <= #self.buttons, "Attempt to remove a non-existent button.", 3)
			remove(self, v)
		else
			common.expect(v, "table", 1)
			for si, sv in ipairs(self.buttons) do
				if v == sv then
					remove(self, si)
					break
				end
			end
		end
	end
	setToggle(self)
end

local loveFunc = {
	"update", "draw", "keypressed", "keyreleased", "mousepressed",
	"mousereleased", "mousemoved", "wheelmoved", "textinput"
}

for i, fName in ipairs(loveFunc) do
	radial[fName] = function(self, ...)
		for i, v in ipairs(self.buttons) do
			if v[fName] then
				v[fName](v, ...)
			end
		end
	end
end


return radial