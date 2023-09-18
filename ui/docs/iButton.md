# iButton

## What is it?
iButton stands for [immediate mode](https://www.wikiwand.com/en/Immediate_mode_(computer_graphics)).  Essentially, it is an in-line button.  It draws and returns if it was clicked or not for the user to work with.

## How to use it?
This module is designed to be very easy to use.

Start by requiring the module with either
```lua
local iButton = require("jjui-love2d.ui")
```
or
```lua
local iButton = require("jjui-love2d.ui.modules.iButton")
```

Both options' path may differ in your project.  Adjust accordingly.

Then you draw the button.  You will pass in the sizing and data while checking if it was clicked.  As of the time of writing this, the only shape of button you can make is the most common type; A rectangle.

The way you call it generally follows this pattern.

```lua
-- Note brackets are important
rect{x, y, w, h, text = "hello world"}
```
or
```lua
rect({x = 0, y = 0, w = 100, h = 50, text = "Second Button"})
```

```lua
function love.draw()
	if iButton.rect{20, 20, 100, 50, text = "hello world"} then
		print("Button was clicked!")
	end
end
```
It's as simple as that!  There are some important variables that I will outline here.

## Important variables
These variables are passed in two ways.  The first was to keep the style consistent with Love2d's color setting.

- outlineColor
- textColor

Both of these can be accessed via special functions that you'll be familiar with, as love2d uses a similar method.

```lua
iButton.setOutlineColor(r,g,b[,a]) -- sets the outline color of the button.
iButton.setTextColor(r,g,b[,a]) -- sets the text color of the button

iButton.getOutlineColor() -- gets the outline color of the button.
iButton.getTextColor() -- gets the text color of the button
```

The rest of the important variables will be passed to the button as it's drawn.

- text - String: The text that will be printed
- relative - Boolean: If size is relative to window size
- minWidth - The minimum width of the button
- maxWidth - The maximum width of the button
- minHeight - The minimum heigh of the button
- maxHeight - The maximum heigh of the button
- shading - The amount that the button will be shaded when using the button
- image - The image to be drawn
- quad - The quad to draw

## Extra details
First, this is still a work in progress, expect changes.<br/><br/>
Second, images/quads will be scaled to the size of the button.