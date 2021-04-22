local ui = {_version = "0.0.3"}
local HERE = ...
local MODULES = HERE..".modules"

-- local availableModules = love.filesystem.getDirectoryItems(HERE.."/modules")

-- local function validate(module)
-- 	for k,v in pairs(availableModules) do
-- 		if module == v or module..".lua" == v then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

-- function ui.loadModule(module)
-- 	assert(validate(module), "Module not found.  Enter name as found in the ui/modules folder, excluding file extension.")
-- 	ui[module] = require(module..".lua")
-- end

ui.modules = {}
ui.modules.button = require(MODULES..".button")
ui.modules.dial, ui.modules.arc = require(MODULES..".radialbuttons")()
ui.modules.scroll = require(MODULES..".scrolllib")
ui.modules.slider = require(MODULES..".slider")
ui.modules.set = require(MODULES..".uisets")

ui.newRectangleButton = ui.modules.button.newRectangleButton
ui.newCircleButton = ui.modules.button.newCircleButton
ui.newDial = ui.modules.dial.new
ui.newArcButton = ui.modules.arc.new
ui.newScrollViewport = ui.modules.scroll.newViewport
ui.newHorizontalSlider = ui.modules.slider.newHorizontalSlider
ui.newVerticalSlider = ui.modules.slider.newVerticalSlider
ui.newSet = ui.modules.set.new

return ui
