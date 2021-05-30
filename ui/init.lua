local ui = {_version = "0.0.33"}
local HERE = ...
local MODULES = HERE..".modules"

ui.modules = {}
ui.modules.button = require(MODULES..".button")
ui.modules.dial, ui.modules.arc = require(MODULES..".radialbuttons")()
ui.modules.scroll = require(MODULES..".scrolllib")
ui.modules.slider = require(MODULES..".slider")
ui.modules.set = require(MODULES..".uisets")

ui.newRectangleButton = ui.modules.button.newRectangleButton
ui.newPolygonButton = ui.modules.button.newPolygonButton
ui.newCircleButton = ui.modules.button.newCircleButton
ui.newDial = ui.modules.dial.new
ui.newArcButton = ui.modules.arc.new
ui.newScrollViewport = ui.modules.scroll.newViewport
ui.newSlider = ui.modules.slider.new
ui.newSet = ui.modules.set.new

return ui
