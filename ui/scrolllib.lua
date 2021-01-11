local lg = love.graphics


local scroll = {}
scroll.__index = scroll
scroll._version = "0.4.0"

scroll.font = lg.newFont(16)

function scroll:checkInBounds(x,y)
	if x > self.x and
	x < self.x + self.width and
	y > self.y and
	y < self.y + self.height then
		return "viewport"
	elseif self.scrollbar and x > self.scrollbar.x and
	x < self.scrollbar.x + self.scrollbar.width and
	y > self.scrollbar.y and
	y < self.scrollbar.y + self.scrollbar.height then
		return "scrollbar"
	end
	return false
end

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
		align = align or "left"
	}, scroll)
end

function scroll:newScrollbar(x, y, width, height)
	self.scrollbar = {
		x = x, 
		y = y,
		width = width,
		height = height,
	}
end

function scroll:setScrollY(pos)
	-- assert(self.scrollbar, "Requires setting scrollbar with scroll:newScrollbar(x,y,width,height)")
	self.yScroll = pos
	if self.scrollLock then
		if self.yScroll > 0 then
			self.yScroll = 0
		elseif math.abs(self.yScroll) + self.height > self:getContentHeight() then
			self.yScroll = -(self:getContentHeight() - self.height + (self.bottomBuffer - self.topBuffer))
				-- scrolly = (#wrappedtext * font16:getHeight("f") - textbox.height + 10) * -1
			if self:getViewportHeightPercent() == 1 then
				self.yScroll = 0
			end
		end
	end
end

function scroll:setViewportPosition(x, y) -- sets location of viewport
	self.x, self.y = x, y
end
function scroll:setScrollbarPosition(x,y)
	self.scrollbar.x, self.scrollbar.y = x,y
end


function scroll:setViewportDimensions(width, height)
	self.width, self.height = width, height
end
function scroll:setScrollbarDimensions(width, height)
	self.scrollbar.width, self.scrollbar.height = width, height
end

function scroll:setWindow(x, y, width, height) -- combines setViewport Position and Dimensions
	self.x, self.y = x, y
	self.width, self.height = width, height
end
function scroll:setScrollbar(x, y, width, height)
	self.scrollbar.x, self.scrollbar = x, y
	self.scrollbar.width, self.scrollbar.height = width, height
end

function scroll:setFont(font) -- string font
	self.contents.font = lg.newFont(font)
end

function scroll:setTextColor(r,g,b,a)
	if type(r) == "table" then
		assert(#r >= 3 and #r <= 4, "Passed color array incorrect.  expected format {r,g,b[, a]}")
		r,g,b,a = unpack(r)
	end
	if not a then a = 1 end
	self.contents.textColor = {r,g,b,a}
end

-- sets text to be wrapped in window.
function scroll:setText(text)
	self.contents.textWidth, self.contents.textArray = self.contents.font:getWrap(text, self.width-self.leftBuffer-self.rightBuffer)
end

function scroll:setDraw(f, width, height)
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

function scroll:getViewportPosition()
	return self.x, self.y
end

function scroll:getContentHeight() -- gets how high the contents to be drawn in the viewport is
	if self.contents.image == "function" then
		return self.contents.drawHeight
	elseif self.contents.image then
		return self.contents.image:getHeight() + self.topBuffer + self.bottomBuffer
	elseif self.contents.textArray then
		local lines = #self.contents.textArray
		return self.font:getHeight(" ") * lines + (lines * self.contents.lineBuffer) + self.topBuffer + self.bottomBuffer
	else
		return 0
	end
end

function scroll:getViewportHeightPercent() -- return 0-1 of how much viewport shows of content height
	local theight = self:getContentHeight()
	return self.height / self:getContentHeight() < 1 and self.height / self:getContentHeight() or 1
end

function scroll:getScrollPercent() -- return 0-1 of position of how far down viewport is scrolled
	return math.abs(self.yScroll / self:getContentHeight())
end

function scroll:getBarClickPercent(x, y)
	if self:checkInBounds(x, y) == "scrollbar" then
		return math.abs(y - self.scrollbar.y / self.scrollbar.height)
	end
end

function scroll:getViewport()
	return self.x, self.y, self.width, self.height
end

function scroll:getThumbPosition()
	return self.scrollbar.x, self.scrollbar.y + self.scrollbar.height * self:getScrollPercent()
end

function scroll:getThumbDimensions()
	return self.scrollbar.width, self.scrollbar.height * self:getViewportHeightPercent()
end

function scroll:getScrollbarLocation()
	return self.scrollbar.x, self.scrollbar.y, self.scrollbar.width, self.scrollbar.height
end

function scroll:getScrollY()
	return self.yScroll
end

function scroll:getText()
	local t = ""
	for i = 1, #self.contents.textArray do
		t = t..self.contents.textArray[i]
	end
	return t
end


-- main functions

function scroll:draw(f, width, height)

	lg.push()
	lg.setScissor(self:getViewport())
	lg.translate(self.xScroll + self.x, self.yScroll + self.y)
	if type(f) == "function" then
		f()
	elseif self.contents.image then

		-- set with scroll:setDraw(f)
		-- this draws the image set in bounds.
		lg.setColor(1,1,1,1)
		lg.draw(self.contents.image, self.leftBuffer, self.topBuffer)

	elseif self.contents.textArray then
		-- meant to be a shortcut way to draw simple text
		local prevFont = lg.getFont() -- courtesy font reset

		lg.setFont(self.contents.font)
		lg.setColor(self.contents.textColor or {1,1,1,1})
		for i = 1, #self.contents.textArray do
			lg.printf(
				self.contents.textArray[i], 
				self.leftBuffer, 
				self.topBuffer + self.contents.lineBuffer * i + self.font:getHeight(self.contents.textArray[i]) * (i-1),
				self.width - self.leftBuffer - self.rightBuffer,
				self.align
			)
		end

		lg.setFont(prevFont) -- courtesy font reset
	end

	lg.setScissor()
	lg.pop()

end


return scroll
