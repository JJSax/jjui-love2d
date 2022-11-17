
local unpack = table.unpack or unpack -- future proof for lua version 5.2+

local lg = love.graphics
local uiRoot = (...):gsub('%.[^%.]+$', '')
local common = require(uiRoot..".common")
local geometry = require(uiRoot..".geometry")

local min = common.min
local max = common.max

local graphics = {
	_VERSION = "0.0.4",
	stack = {},
	stackLimit = 20, -- how deep the stack limit is
	transform = {x = 0, y = 0},
	dimensions = {width = lg.getWidth(), height = lg.getHeight()}
}

--[[
	consider
	coordinates system. Transform, rotation, scaling, shear?
]]

local function checkStack()
	common.assert(#graphics.stack > 0,
		"Attempt to draw outside a window stack.  \nCall graphics.push() and pass a ui window.")
end

local function getLastStack() return graphics.stack[#graphics.stack] end

-- each needs to
-- calculate left/right/top/bottom
-- set last stack area to proper new area
-- if inside area then draw it

function graphics.arc(...) end
function graphics.circle(...)

	--! I must be careful that I'm not making window.contents dimensions convuluted.
	-- if x < 0, then getting the dimensions will have to be abs(x) + width
	-- If I adjust for that here, then I can avoid that.
	-- May have to change x/y values here so the viewing area doesn't shift

	local input = {...}
	local mode, x, y, r, segments = unpack(input)
	local content = getLastStack().content
	local left, top, right, bottom = x - r, y - r, x + r, y + r --! will have to adjust to window transform
	content.left = min(content.left, left)
	content.right = max(content.right, right)
	content.top = min(content.top, top)
	content.bottom = min(content.bottom, bottom)
	--! if inside scissor then draw...
	local last = getLastStack()
	-- lg.translate(last.x, last.y)
	lg.circle(...)
end
-- function graphics.clear(...) end
-- function graphics.discard(...) end
-- function graphics.draw(...) end
-- function graphics.drawInstanced(...) end
-- function graphics.drawLayer(...) end
-- function graphics.ellipse(...) end
-- function graphics.flushBatch(...) end
-- function graphics.line(...) end
-- function graphics.points(...) end
-- function graphics.polygon(...) end
-- function graphics.print(...) end
-- function graphics.printf(...) end
function graphics.rectangle(...)
	local input = {...}
	local mode, x, y, w, h = unpack(input)
	local lStack = getLastStack()
	local content = lStack.content
	content.left = min(content.left, x)
	content.right = max(content.right, x + w - lStack.width)
	content.top = min(content.top, y)
	content.bottom = max(content.bottom, y + h - lStack.height)
	lg.rectangle(...)
end
function graphics.stencil(...) end

-- function graphics.translate()

-- end


local function getTrueX(window, x)
	x = x or 0
	if window.parent then return getTrueX(window.parent, x + window.x) end
	return x + window.x
end
local function getTrueY(window, y)
	y = y or 0
	if window.parent then return getTrueY(window.parent, y + window.y) end
	return y + window.y
end
local function getTrueR(window, r)

end
local function getTrueB(window, b)

end

function graphics.setScissor(x, y, w, h)
	--https://github.com/love2d/love/blob/8e7fd10b6fd9b6dce6d61d728271019c28a7213e/src/modules/graphics/Graphics.cpp#L830
	--@x,y,w,h for custom scissor inside window not related to the window itself

	-- scissor with respect for transform


	--! ATTEMPT 3
	local stl = graphics.stack[#graphics.stack-1]
	local last = getLastStack()
	--! Negative x, y draw operations still show outside window
	local lx, ly = lg.transformPoint(0, 0)
	local lw, lh = last.width, last.height
	if not stl then
		stl = {x = 0, y = 0, width = lg.getWidth(), height = lg.getHeight()}
	end
	local l, t, r, b = geometry.rectangleOverlapArea(stl.x, stl.y, stl.width, stl.height, lx, ly, lw, lh)
	lg.setScissor(l, t, r - l, b - t)

	--! ATTEMPT 2
		-- local lx, ly, lw, lh = 0, 0, lg.getWidth(), lg.getHeight()
		-- for i, v in ipairs(graphics.stack) do
		-- 	lx, ly, lw, lh = geometry.rectangleOverlapArea(lx, ly, lw, lh, lx + v.x, ly + v.y, v.width - v.x, v.height - v.y)
		-- 	-- lx, ly = lx + v.x, ly + v.y
		-- 	-- lw, lh = lw - v.x, lh - v.y
		-- 	if lx == false then -- scissor has no area
		-- 		lg.setScissor(0,0,0,0)
		-- 		return false -- returning false so user can skip drawing.
		-- 	end
		-- end
		-- if not x then
		-- 	local last = getLastStack()
		-- 	local lx, ly = lg.inverseTransformPoint(lx, ly)
		-- 	lg.setScissor(lx + last.x, ly + last.y, lw - lx, lh - ly)
		-- 	return true
		-- end

		-- lx, ly, lw, lh = geometry.rectangleOverlapArea(x, y, w, h, lx, ly, lw, lh)
		-- if lx == false then
		-- 	lg.setScissor(0,0,0,0) -- scissor has no area
		-- 	return false
		-- end
		-- lw, lh = lw - x, ly - y
		-- lg.setScissor(lx, ly, lw, lh)
		-- return true

	--! ATTEMPT 1
		-- local lx, ly, lw, lh = 0, 0, lg.getWidth(), lg.getHeight()
		-- for i, v in ipairs(graphics.stack) do
		-- 	lx, ly, lw, lh = geometry.rectangleOverlapArea(lx + v.x, ly + v.y, v.width + v.x, v.height + v.y, lx, ly, lw, lh)
		-- 	lw, lh = lw - v.x, lh - v.y
		-- 	if lx == false then -- scissor has no area
		-- 		lg.setScissor(0,0,0,0)
		-- 		return false -- returning false so user can skip drawing.
		-- 	end
		-- end
		-- if not x then
		-- 	local lx, ly = lg.inverseTransformPoint(lx, ly)
		-- 	lg.setScissor(lx, ly, lw, lh)
		-- 	return true
		-- end

		-- lx, ly, lw, lh = geometry.rectangleOverlapArea(x, y, w, h, lx, ly, lw, lh)
		-- if lx == false then
		-- 	lg.setScissor(0,0,0,0) -- scissor has no area
		-- 	return false
		-- end
		-- lw, lh = lw - x, ly - y
		-- lg.setScissor(lx, ly, lw, lh)
		-- return true
	--

end


function graphics.push(window)
	common.expect(window, "table", 1)
	common.assert(#graphics.stack < graphics.stackLimit, "Maximum ui stack depth reached (more pushes than pops?)", 3)

	table.insert(graphics.stack, window)
	if #graphics.stack > 1 then
		window.parent = graphics.stack[#graphics.stack - 1]
	end
	lg.push("all")
	lg.translate(window.x, window.y)
	lg.setColor(window.backgroundColor)
	lg.rectangle("fill", 0, 0, window.width, window.height)
	-- lg.setScissor(0, 0, window.width, window.height)
	graphics.setScissor()
end

function graphics.pop()
	common.assert(#graphics.stack > 0, "Minimum ui stack depth reached (more pops than pushes?)", 3)
	graphics.stack[#graphics.stack].parent = nil
	table.remove(graphics.stack)
	lg.pop()
end

for k, v in pairs(lg) do
	if not graphics[k] then
		graphics[k] = v
	end
end

return graphics
