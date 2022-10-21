local ui = {_version = "0.0.5"}
local HERE = ...
local MODULES = HERE..".modules"

ui.modules = {}
ui.modules.button = require(MODULES..".button")
ui.modules.dial = require(MODULES..".dial")
ui.modules.scroll = require(MODULES..".scrolllib")
ui.modules.slider = require(MODULES..".slider")
ui.modules.set = require(MODULES..".uisets")
ui.modules.textbox = require(MODULES..".textbox")

ui.newRectangleButton = ui.modules.button.newRectangleButton
ui.newPolygonButton = ui.modules.button.newPolygonButton
ui.newCircleButton = ui.modules.button.newCircleButton
ui.newArcButton = ui.modules.button.newArcButton
ui.newAngleButton = ui.modules.button.newAngleButton

ui.newDial = ui.modules.dial.new
ui.newScrollViewport = ui.modules.scroll.newViewport
ui.newSlider = ui.modules.slider.new
ui.newTextbox = ui.modules.textbox.new

ui.newSet = ui.modules.set.new

return ui

--https://en.wikipedia.org/wiki/Graphical_widget
