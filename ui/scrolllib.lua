
--[[

	terms: 
		Scrollbar: an inclusive term that encompases both the Thumb and the Trough.
		Thumb: The part on the bar on the right or bottom of screen showing 
				where you are in the page and how much you are viewing.
		Trough: The part of the scrollbar that is not occupied by the thumb.
		Viewport: The window that displays the content.

]]

local lg = love.graphics

local scroll = {
	__version = "0.5.501"
}
scroll.__index = scroll
scroll.font = lg.newFont(16)


------------------------------------------------------------------------
--------------------------Local functions-------------------------------
------------------------------------------------------------------------

local function BoundCheck(x, y, bx, by, bw, bh)
	return x > bx and
		x < bx + bw and
		y > by and
		y < by + bh
end

local function inRange(num, mn, mx)
	return (num >= mn and num <= mx) or (num <= mn and num >= mx)
end

------------------------------------------------------------------------
---------------------------Constructors---------------------------------
------------------------------------------------------------------------


function scroll.newViewport(x, y, width, height, align)
	return setmetatable(
	{
		x = x, 
		y = y, 
		width = width,
		height = height,
		contents = {
			font = scroll.font,
			lineBuffer = 5,
		},
		yScroll = 0,
		xScroll = 0,
		scrollLock = true, -- prevent user from scrolling past beginning/end of contents
		-- need to have 3 modes.  Disabled, bottom of viewport is bottom of content, top of viewport is bottom of content
		bottomBuffer = 5,
		topBuffer = 5,
		leftBuffer = 5,
		rightBuffer = 5,
		align = align or "left",
		thumbClickLocation = nil
	}, scroll)
end

function scroll:newScrollbar(x, y, width, height)
	self.scrollbar = {
		x = x, 
		y = y,
		width = width,
		height = height,
		troughMode = 0, -- 0 to page up/down in relative direction, 1 to jump to location
		smoothTroughScroll = 0.25, -- Time it takes to finish scroll. if > 0, requires thumbScroll(dt) in update. 
		troughHoldThreshold = 0.35, -- WIP Set to high number to effectively disable
	}
end

-- function scroll:setStencil(callback)

-- end

------------------------------------------------------------------------
------------------------------Methods-----------------------------------
------------------------------------------------------------------------

----------------------
--- Navigation methods
----------------------

function scroll:clampScroll(pos)
	-- returns clamped value. Does not set self.yScroll
	if pos > 0 then
		return 0
	elseif math.abs(pos) + self.height > self:getContentHeight() then
		if self:getViewportHeightPercent() == 1 then
			return 0
		else
			return -(self:getContentHeight() - self.height + (self.bottomBuffer - self.topBuffer))
		end
	end
	return pos
end
function scroll:setScrollY(pos)
	-- sets scroll position
	self.yScroll = self:clampScroll(pos)
end
function scroll:setDestination(npos)
	-- sets destination.  For use with smoothTroughScroll.
	self.scrollbar.destination = self:clampScroll(npos)
	self.scrollbar.begin = self.yScroll
	self.scrollbar.moveTimer = self.scrollbar.smoothTroughScroll
	self.scrollbar.clickTime = love.timer.getTime()
end
function scroll:pageUp()
	local npos = self.yScroll - self:getViewportHeightPercent() * -self:getContentHeight()
	if self.scrollbar.smoothTroughScroll == 0 then
		self:setScrollY(npos)
	else
		self:setDestination(npos)
	end
end
function scroll:pageDown()
	local npos = self.yScroll - self:getViewportHeightPercent() * self:getContentHeight()
	if self.scrollbar.smoothTroughScroll == 0 then
		self:setScrollY(npos)
	else
		self:setDestination(npos)
	end
end

----------------------
------ Content methods
----------------------

-- function scroll:write(text, font, color)
-- 	local last = #self.contents.textArray
-- 	self.contents.textArray[last] = self.contents.textArray[last] .. text
-- end
function scroll:print(text, font, color)
	-- Add line of text.  Similar to print()
	if not self.contents.textArray then self.contents.textArray = {} end
	table.insert(self.contents.textArray, {text = text, font = font, color = color})
end


function scroll:setDraw(f, width, height)
	-- set a draw function to be drawn.  This will prevent text or images saved from rendering.
	-- f is the draw callback, width and height are required so the library will know content height.
	assert(width and height, "Both width and height are required to set draw operation.")
	if f then
		local can = lg.newCanvas(width, height)
		lg.setCanvas(can)
		f()
		lg.setCanvas()
		self.contents.drawWidth = nil
		self.contents.drawHeight = nil
		self.contents.image = lg.newImage(can:newImageData())
	else
		self.contents.drawWidth = width
		self.contents.drawHeight = height
		self.contents.image = "function"
	end
end

function scroll:setTextColor(r,g,b,a) -- I don't think this will work any more.
	if type(r) == "table" then
		assert(#r >= 3 and #r <= 4, "Passed color array incorrect.  expected format {r,g,b[, a]}")
		r,g,b,a = unpack(r)
	end
	if not a then a = 1 end
	self.contents.textColor = {r,g,b,a}
end


----------------------
----- Viewport methods
----------------------

function scroll:setViewport(x, y, width, height) 
	-- sets viewport x, y, width, and height
	self.x, self.y = x or self.x, y or self.y
	self.width, self.height = width or self.width, height or self.height
end
function scroll:getViewportPosition()
	return self.x, self.y
end
function scroll:getViewport()
	-- gets viewport x, y, width, and height
	return self.x, self.y, self.width, self.height
end
function scroll:getViewportHeightPercent() 
	-- return 0-1 of how much viewport shows of content height
	local theight = self:getContentHeight()
	return self.height / self:getContentHeight() < 1 and self.height / self:getContentHeight() or 1
end

----------------------
---- Scrollbar methods
----------------------

function scroll:setScrollbarPosition(x,y)
	self.scrollbar.x, self.scrollbar.y = x,y
end
function scroll:setScrollbar(x, y, width, height)
	self.scrollbar.x, self.scrollbar = x, y
	self.scrollbar.width, self.scrollbar.height = width, height
end
function scroll:getScrollbar()
	return self.scrollbar.x, self.scrollbar.y, self.scrollbar.width, self.scrollbar.height
end
function scroll:getScrollPercent() 
	-- return 0-1 of position of how far down viewport is scrolled
	return math.abs(self.yScroll / self:getContentHeight())
end
function scroll:getBarClickPercent(x, y)
	-- returns 0-1 percent of where the scrollbar was clicked.
	if self:checkInBounds(x, y) == "trough" then
		return math.abs((y - self.scrollbar.y) / self.scrollbar.height)
	end
end

----------------------
------- Trough methods
----------------------

function scroll:troughClick(x, y, button)
	-- put in mousepressed
	-- when clicking the scrollbar this will will follow what is set in self.scrollbar.troughMode
	-- sets destination, whether immediately jumping, or smoothly transitioning.
	if BoundCheck(x, y, self:getScrollbar()) and not BoundCheck(x, y, self:getThumb()) then
		local npos
		if self.scrollbar.troughMode == 1 then
			-- instant jump mode
			npos = -(self:getContentHeight() * self:getBarClickPercent(x, y)) + (
				self:getViewportHeightPercent()/2*self:getContentHeight()
			)
			self:setDestination(npos)
			if  self.scrollbar.smoothTroughScroll <= 0 then
				self:setScrollY(npos)
			end
		else
			-- page scroll mode
			local dir = self:getScrollPercent() > self:getBarClickPercent(x, y) and -1 or 1
			if dir == 1 then self:pageDown() 
			else self:pageUp() 
			end
		end
	end
end
function scroll:troughUpdate(dt)
	-- updates for smoothTroughScroll
	if self.scrollbar.destination then
		-- smooth scrolling
		local sb = self.scrollbar
		local dest = sb.destination
		local dir = self.yScroll < dest and 1 or -1
		local speed = (math.abs(sb.begin - dest) / sb.smoothTroughScroll * dt) * 
			(1 + math.sin( sb.moveTimer/sb.smoothTroughScroll*(math.pi*2)-1 ))
		local new = self.yScroll + speed * dir

		sb.moveTimer = sb.moveTimer and sb.moveTimer - dt
		if not inRange(new, sb.begin, dest) then
			new = dest
			sb.destination = nil
			sb.begin = nil
		end
		self:setScrollY( new )
	end
end

----------------------
-------- Thumb methods
----------------------

function scroll:getThumb()
	-- get x, y, width, height of the thumb
	local s = self.scrollbar
	return s.x, self.scrollbar.y + self.scrollbar.height * self:getScrollPercent(), 
		s.width, s.height * self:getViewportHeightPercent()
end
function scroll:getThumbPosition()
	return self.scrollbar.x, self.scrollbar.y + self.scrollbar.height * self:getScrollPercent()
end
function scroll:getThumbDimensions()
	return self.scrollbar.width, self.scrollbar.height * self:getViewportHeightPercent()
end
function scroll:inThumbBounds(x, y)
	-- returns if x,y is inside thumb perimiter
	return BoundCheck(x, y, self:getThumb())
end
function scroll:thumbScroll(dt)
	-- put in update
	-- requires thumbClick and thumbRelease
	if self.thumbClickLocation then
		local mx, my = love.mouse.getPosition()
		local ylev = (
			math.abs(my - self.scrollbar.y / self.scrollbar.height) 
			- self.scrollbar.y - self.thumbClickLocation[2]
		)
		local npos = -(self:getContentHeight() * (ylev / self.scrollbar.height))

		self:setScrollY(npos)
	end
end
function scroll:thumbClick(x, y, button)
	-- put in love.mousepressed
	if button == 1 and self:inThumbBounds(x, y) then
		local tx, ty = self:getThumbPosition()
		self.thumbClickLocation = {x - tx, y - ty}
	end
end
function scroll:thumbRelease(x, y, button)
	-- put in love.mousereleased
	self.thumbClickLocation = nil
	self.scrollbar.clickTime = nil
end

----------------------
------ General methods
----------------------

function scroll:checkInBounds(x,y)
	if BoundCheck(x, y, self:getViewport()) then
		return "viewport"
	elseif self.scrollbar and BoundCheck(x, y, self:getScrollbar()) then
		return "trough"
	end
	return false
end

function scroll:getTextDimensions(textArray)
	-- gets dimensions of text in the array element passed, considering text wrapping and font.
	local font = textArray.font or self.font
	local width, lines = font:getWrap(textArray.text, self.width)
	local height = #lines*font:getHeight()
	return width, height
end

function scroll:refreshContentHeight()
	-- WIP unused
	-- meant to set a variable to prevent loops
	if self.contents.image == "function" then
		return self.contents.drawHeight
	elseif self.contents.image then
		return self.contents.image:getHeight() + self.topBuffer + self.bottomBuffer
	elseif self.contents.textArray then
		local height = 0
		for k,v in pairs(self.contents.textArray) do
			local dimx, dimy = self:getTextDimensions(v)
			height = height + dimy
		end
		return height + (lines * self.contents.lineBuffer) + self.topBuffer + self.bottomBuffer
	else
		return 0
	end
end

function scroll:getContentHeight() 
	-- gets how high the contents to be drawn in the viewport is
	if self.contents.image == "function" then
		return self.contents.drawHeight
	elseif self.contents.image then
		return self.contents.image:getHeight() + self.topBuffer + self.bottomBuffer
	elseif self.contents.textArray then
		local height = 0
		for k,v in pairs(self.contents.textArray) do
			local dimx, dimy = self:getTextDimensions(v)
			height = height + dimy
		end
		return height + (#self.contents.textArray * self.contents.lineBuffer) + self.topBuffer + self.bottomBuffer
	else
		return 0
	end
end

function scroll:scrollbarUpdate(dt)
	self:troughUpdate(dt)
	self:thumbScroll(dt)
end

function scroll:draw(f, width, height)

	lg.push()
	lg.setScissor(self:getViewport())
	lg.translate(self.xScroll + self.x, self.yScroll + self.y)
	lg.setColor(1,1,1,1)
	if type(f) == "function" then
		f()
	elseif self.contents.image then

		-- set with scroll:setDraw(f)
		-- this draws the image set in bounds.
		lg.draw(self.contents.image, self.leftBuffer, self.topBuffer)

	elseif self.contents.textArray then
		-- meant to be a shortcut way to draw simple text
		local prevFont = lg.getFont() -- courtesy font reset

		local height = self.topBuffer
		for k,v in ipairs(self.contents.textArray) do
			lg.setFont(v.font or self.font)
			lg.printf(
				v.text,
				self.leftBuffer,
				height,
				self.width - self.leftBuffer - self.rightBuffer,
				self.align
			)
			local w, h = self:getTextDimensions(v)
			height = height + h + self.contents.lineBuffer
		end

		lg.setFont(prevFont) -- courtesy font reset
	end

	lg.setScissor()
	lg.pop()

end


return scroll
