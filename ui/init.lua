local ui = {_version = "0.0.7"}
local HERE = ...
local MODULES = HERE..".modules"

ui.graphics = require(HERE..".graphics")

ui.modules = {}
ui.modules.button = require(MODULES..".button")
ui.modules.dial = require(MODULES..".dial")
ui.modules.scroll = require(MODULES..".scrolllib")
ui.modules.slider = require(MODULES..".slider")
ui.modules.set = require(MODULES..".uisets")
ui.modules.textbox = require(MODULES..".textbox")
ui.modules.radio = require(HERE..".radialSet")
ui.modules.window = require(MODULES..".window")

ui.newRectangleButton = ui.modules.button.newRectangleButton
ui.newPolygonButton = ui.modules.button.newPolygonButton
ui.newCircleButton = ui.modules.button.newCircleButton
ui.newArcButton = ui.modules.button.newArcButton
ui.newAngleButton = ui.modules.button.newAngleButton

ui.newDial = ui.modules.dial.new
ui.newWindow = ui.modules.window.new
ui.newScrollViewport = ui.modules.scroll.newViewport
ui.newSlider = ui.modules.slider.new
ui.newTextbox = ui.modules.textbox.new
ui.newRadialSet = ui.modules.radio.new

ui.newSet = ui.modules.set.new

return ui

--https://en.wikipedia.org/wiki/Graphical_widget
