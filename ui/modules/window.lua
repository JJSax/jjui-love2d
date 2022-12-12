

--[[
	window = window.new(x, y, w, h)

	function love.update(dt)

	end

	function love.draw()

	end

]]

local lg = love.graphics

local uiRoot = (...):gsub('%.[^%.]*%.[^%.]+$', '')
local common = require(uiRoot..".common")
local geometry = require(uiRoot..".geometry")

local window = {_VERSION = "0.0.5"}
window.__index = window

local expectMap = {
	x = "number",
	y = "number",
	width = "number",
	height = "number",
	title = "string",
	hasFocus = "boolean",
	fullscreen = "boolean",
	resizable = "boolean",
	borderless = "boolean",
	centered = "boolean",
	minwidth = "number",
	minheight = "number"
}

function window.new(input, ...)
	if type(input) ~= "table" then
		local varargs = {...}
		input = {x = input, y = varargs[1], width = varargs[2], height = varargs[3]}
	end

	local self = {
		x = input[1] or 0,
		y = input[2] or 0,
		width = input[3] or 600,
		height = input[4] or 500,
		title = "New Window",
		hasFocus = false,
		fullscreen = false,
		backgroundColor = {0, 0, 0, 1},
		borderColor = {0.35, 0.35, 0.5, 1},
		borderWidth = 3
	}
	for k, v in pairs(input) do
		if expectMap[k] then
			common.expect(v, expectMap[k], k)
		end
		self[k] = v
	end

	common.assert(self.width > 0, "Window width cannot be negative.")
	common.assert(self.height > 0, "Window height cannot be negative.")

	self.content = {
		left = 0, top = 0, -- top of contents, not view
		right = self.width, bottom = self.height
	}

	return setmetatable(self, window)
end

function window:update(dt) end
function window:drawHorizontal() end

function window:requestAttention() end

function window:hasFocus() return self.hasFocus end

function window:getX() return self.x end
function window:getY() return self.y end
function window:getPosition() return self.x, self.y end

-- setPosition
	function window:setX(x)
		common.expect(x, "number", 1)
		self.x = x
	end
	function window:setY(y)
		common.expect(y, "number", 1)
		self.y = y
	end
	function window:setPosition(x, y)
		common.expect(x, "number", 1)
		common.expect(y, "number", 2)
		self.x, self.y = x, y
	end
--

function window:getWidth() return self.width end
function window:getHeight() return self.height end
function window:getDimensions() return self.width, self.height end

function window:getTitle() return self.title end
function window:setTitle(title)
	common.expect(title, "string", 1)
	self.title = title
end

function window:setMode(width, height, flags)
	--@ number width - Window width.
	--@ number height - Window height.
	--@ table flags - Table with the window properties:
		-- boolean fullscreen
		-- Fullscreen (true), or windowed (false).

		-- FullscreenType fullscreentype
		-- The type of fullscreen mode used.

		-- boolean resizable
		-- True if the window is resizable in windowed mode, false otherwise.

		-- boolean borderless
		-- True if the window is borderless in windowed mode, false otherwise.

		-- boolean centered
		-- True if the window is centered in windowed mode, false otherwise.

		-- number minwidth
		-- The minimum width of the window, if it's resizable.

		-- number minheight
		-- The minimum height of the window, if it's resizable.

	self.width = width
	self.height = height
	self.flags = common.merge(self, flags)
	--! will have to adjust the thumb size and all that...

end

function window:getContentWidth() return self.content.right end
function window:getContentHeight() return self.content.bottom end
function window:getContentDimensions() return self.content.right, self.content.bottom end


function window:keypressed(key) end
function window:keyreleased(key) end
function window:mousepressed(x, y, button, istouch, presses)
	x, y = lg.inverseTransformPoint
end
function window:mousereleased(x, y, button, istouch, presses)
	x, y = lg.inverseTransformPoint
end
function window:mousemoved(x, y, dx, dy, istouch)
	x, y = lg.inverseTransformPoint(x, y)
end
function window:wheelmoved(x, y) end
function window:textinput(text) end


function window:getHorizontalThumb()
	--? return both position and dimensions
	local contentW = common.min(self.content.x, 0) + self.content.right
end
function window:getHorizontalThumbPosition()

end
function window:getHorizontalThumbDimensions()

end

function window:drawHorizontalBar()

	lg.setColor(0.2,0.2,0.2)
	lg.rectangle("fill", 0, self.height - 10, self.width, 10)
	lg.setColor(0.4, 0.4, 0.4)
	lg.rectangle("fill", 0, self.height - 10, self.width * (self.width / self.content.right), 10)

end -- default draw

return window


-- love.graphics.getDPIScale -- Gets the DPI scale factor of the window.
-- love.graphics.getDimensions -- Gets the width and height of the window.
-- love.graphics.getHeight -- Gets the height in pixels of the window.
-- love.graphics.getPixelDimensions -- Gets the width and height in pixels of the window.
-- love.graphics.getPixelHeight -- Gets the height in pixels of the window.
-- love.graphics.getPixelWidth -- Gets the width in pixels of the window.
-- love.graphics.getWidth -- Gets the width in pixels of the window.