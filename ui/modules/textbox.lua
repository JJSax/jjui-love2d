local lg = love.graphics

local textbox = {}
textbox.__index = textbox
textbox._version = "0.0.35"
textbox.font = lg.newFont(14)


--[[
fair reference https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_input_test

Bugs: [
]

todo:
add text margin to the left and right
	var name padding/margin/buffer
add text alias, so "test" would look like "****"
add placeholder text.  aka the text that shows when the field is blank
valid input chars regex option


Features Implemented

-add new cursor graphic when hovering over text, like hovering over this text makes an 'I' cursor
-add caret visibility control.  Move text based on caret position.
-add selection functionality
	Double click for word
	Triple click for all
	ctrl + a
	ctrl + shift + left/right

--]]

-------------------------------------------
-------------Local Functions---------------
-------------------------------------------

	local function clamp(n, low, high)
		return math.max(math.min(n, high), low)
	end

	local function slice(str, i, j)
		return str:sub(i+1, j) -- +1 to prevent copying if not selecting anything.
	end

	local function minmaxCaret(i, j)
		local temp
		if i > j then
			temp = j
			j = i
			i = temp
		end
		return i, j
	end

	local function replace(str, i, j, new)
		i, j = minmaxCaret(i, j)
		local finish = str:sub(j, #str)
		return str:sub(1, i-1) .. new .. finish
	end

	local function replaceChar(str, pos, r)
		return str:sub(1, pos-1) .. r .. str:sub(pos+1)
	end

	local function insert(str, pos, text)
		local finish = str:sub(pos+1, #str)
		return str:sub(1, pos) .. text .. finish
	end

	local function stripLast(str)
		while str:sub(#str, #str) == " " do
			-- admitting pattern defeat.  It won this battle, but I will win the war.
			str = replaceChar(str, #str, "")
		end
		local lastSpace = str:match(".*%s()")
		if not lastSpace then return "" end
		-- str = str:match("%s+$") or str
		-- str = str:match("(.-)%s(%S+)$") or ""
		return str:sub(1, lastSpace-1)
	end

	local function bisect(self, pos)
		return	self.text:sub(1, pos),
				self.text:sub(pos+1, #self.text)
	end

	local function percShiftLeft(self)
		if self:getAbsCaretPos() - self.x < self.width * self.midShiftPerc then
			self.textOffset = self.textOffset - (
				(self:getAbsCaretPos() - self.x) - (self.width * self.midShiftPerc)
			)
		end
	end

	local function percShiftRight(self)
		if self:getAbsCaretPos() - self.x > self.width * (1-self.midShiftPerc) then
			local left = bisect(self, self.caretPosition[2])
			self.textOffset = -self.font:getWidth(left) + self.width * (1-self.midShiftPerc)
		end
	end



--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------

function textbox.new(x, y, width, height, extra)
	local default = {
		x = x, y = y, width = width, height = height,

		text = "",
		textAliasChar = nil, -- make all characters appear as this character.
		textColor = {1,1,1,1},
		textOffset = 0, -- x offset meant for use with cursor.
		font = textbox.font,
		selected = true, -- if textbox is selected and ready to accept input
		selectedColor = {0.4, 0.4, 1, 0.1},

		cursor = love.mouse.getSystemCursor("ibeam"),
		caretPosition = {0, 0}, -- table for start and end of selected area
		cursorBlink = true,
		midShiftPerc = 0.3, -- when backspacing, will keep the cursor here to show some of previous text.
		caretBlinkTimer = 0.45,
		caretBlinkReset = 0.45,
		caretWidth = 1,
		caretColor = {1, 0.7, 0},
		selectionHighlight = {0.3569, 0.3643, 0.4726, 0.75},

		backgroundColor = {0,0,0,1},
		textColor = {1,1,1,1},
		outlineColor = {0.7, 0.7, 0.7},
		outlineWidth = 1,
		hoverColor = {1,1,1,0.1}, -- when hovering over this is the indicator.
		resetTextRepeat = love.keyboard.hasKeyRepeat(),

		textInputCallback = function() end,

		callback = function() end,
		callbackTrigger = "return"
	}
	return setmetatable(default, textbox)
end

--------------------------------------------
--------------Main Functions----------------
--Run these in their respective love loops--
--------------------------------------------

function textbox:textinput(t)
	if love.keyboard.isDown("lctrl", "rctrl") then return end -- ctrl is used for paste/copy
	if self.selected then
		if self.caretPosition[1] ~= self.caretPosition[2] then
			self.text = replace(self.text, self.caretPosition[1]+1, self.caretPosition[2]+1, t)
			self:setCaretPos(math.min(self.caretPosition[1], self.caretPosition[2])+1)
		else
			self.text = insert(self.text, self.caretPosition[1], t)
			self:setCaretPos(1, true)

			-- this will show some remaining text to the right.  Not sure if I want
			-- percShiftRight(self)
			-- self:closeRightGap()
		end
		self:textInputCallback(t)
		return true
	end
	return false
end

-- function textbox:keypressed(key)
-- 	if love.keyboard.isDown("lctrl", "rctrl") then

-- 	end
-- end
function textbox:keypressed(key)
	-- todo clean this whole function up as it is not good code.
	if key == "backspace" then
		if not self:removeSelection() then
			if love.keyboard.isDown("lctrl", "rctrl") then
				local start, finish = bisect(self, self.caretPosition[1])
				start = stripLast(start)

				self:setCaretPos(#start)
				self.text = start .. finish
			else
				if self.caretPosition[1] > 0 then -- to fix extreme lag issue when backspacing from start
					self.text = replaceChar(self.text, self.caretPosition[1], "")
					self:setCaretPos(self.caretPosition[1]-1)
				end
				-- self.text = string.sub(self.text, 1,string.len(self.text)-1) or ""
			end
		end
		self.caretBlinkTimer = 0
		-- set text offset
		percShiftLeft(self)
		if self:getAbsCaretPos() < self.x then -- shift to the right when caret is left of box
			self.textOffset = -self.font:getWidth(self.text:sub(1, self.caretPosition[1]))
		end
		self:closeRightGap()
		self:closeLeftGap()
		self:textInputCallback()
	elseif key == "delete" then
		if not self:removeSelection() then
			if love.keyboard.isDown("lctrl", "rctrl") then
				local start, finish = bisect(self, self.caretPosition[1])
				local trim = finish:sub(finish:match('^%s*()'), #finish) -- trim leading spaces
				self.text = start .. trim:sub(trim:find(" ") or #trim+1, #trim)
			else
				self.text = replaceChar(self.text, self.caretPosition[1]+1, "")
			end
			if self:getAbsCaretPos() > self.x + self.width then -- shift to the left
				self.textOffset = -self.font:getWidth(self.text:sub(1, self.caretPosition[1])) + self.width
			end
		end
		self.caretBlinkTimer = 0
		percShiftRight(self)
		self:closeRightGap()
		-- self:closeLeftGap()
		self:textInputCallback()
	elseif key == "left" then
		if love.keyboard.isDown("lctrl", "rctrl") then
			local start = self.text:sub(1, self.caretPosition[1])
			self:setCaretPos(start:match("^.*().%s") or 0)
		else
			self:setCaretPos( math.max(self.caretPosition[1]-1, 0) )
		end
		self.caretBlinkTimer = 0
		percShiftLeft(self)
		-- self:closeRightGap()
		self:closeLeftGap()
	elseif key == "right" then
		if love.keyboard.isDown("lctrl", "rctrl") then
			local finish = self.text:sub(self.caretPosition[2]+1, #self.text)
			self:setCaretPos(finish:find(" ") or #self.text, true)
		else
			self:setCaretPos(math.min(self.caretPosition[2]+1, #self.text))
		end
		self.caretBlinkTimer = 0
		percShiftRight(self)
		self:closeRightGap()
		-- self:closeLeftGap()
	elseif key == "home" then
		self:setCaretPos(0)
	elseif key == "end" then
		self:setCaretPos(#self.text)
	elseif key == self.callbackTrigger then
		if self.callback then self:callback(self.text) end



	elseif love.keyboard.isDown("lctrl", "rctrl") and self.selected then
		if key == "c" then
			-- copy to clipboard
			love.system.setClipboardText(slice(self.text, unpack(self.caretPosition)))
		elseif key == "v" then
			-- paste from clipboard
			-- todo: delete selected area
			self.text = insert(self.text, self.caretPosition[1], love.system.getClipboardText())
		elseif key == "a" then
			-- select all text
			self.caretPosition[1], self.caretPosition[2] = 0, #self.text+1
		elseif key == "z" then
			-- undo
		elseif key == "y" then
			-- redo
		end
	elseif love.keyboard.isDown("lshift", "rshift") then
		-- for selecting text
	end
end
function textbox:keyreleased(key) end

function textbox:mousepressed(x, y, button)
	if not self:inBounds(x, y) then
		self.selected = false
		love.keyboard.setKeyRepeat(self.resetTextRepeat)
		return false
	end
	self.selected = true
	self.resetTextRepeat = love.keyboard.hasKeyRepeat()
	if not self.selected then return false end

	self.selecting = true
	self:setCaretPos(self:getClickCharacter(x, y))
	-- self:selectionStart(self:getClickCharacter(x, y))
	self.caretBlinkTimer = 0 -- to instantly see your click took
	love.keyboard.setKeyRepeat(true)
	if not self.lastClick then
		self.lastClick = {
			timer = 0.5,
			pos = self:getClickCharacter(x, y),
			count = 1
		}
	elseif self:getClickCharacter(x, y) == self.lastClick.pos then
		self.lastClick.count = self.lastClick.count + 1
		self.lastClick.timer = 0.5
	end
end
function textbox:mousereleased(x, y, button)
	self.selecting = false
	if not self:inBounds(x,y) then return false end
	if not self.lastClick then return false end
	if self.lastClick.count == 2 then
		-- select word
		local _, s, e = self:wordAtPos(self.lastClick.pos)
		self.caretPosition = {s, e}
	elseif self.lastClick.count == 3 then
		self.caretPosition[1], self.caretPosition[2] = 0, #self.text
		self.lastClick.count = 0
	end
end

function textbox:update(dt)
	if self.selected then
		self.caretBlinkTimer = self.caretBlinkTimer + dt
		if self.caretBlinkTimer > math.abs(self.caretBlinkReset) then
			self.caretBlinkTimer = -self.caretBlinkReset
		end
	end
	if self.lastClick then
		self.lastClick.timer = self.lastClick.timer - dt
		if self.lastClick.timer < 0 then
			self.lastClick = nil
		end
	end
	if self:inBounds(love.mouse.getPosition()) then
		if not self.cursorCache then
			-- for some reason this gets called twice before self.cursorCache ~= nil
			self.cursorCache = love.mouse.getCursor()
			love.mouse.setCursor(self.cursor)
		end
		if self.selecting then
			if love.mouse.isDown(1) then --not self.lastClick then
				local char = self:getClickCharacter(love.mouse.getPosition())
				-- print(char)
				self:selectionEnd(self:getClickCharacter(love.mouse.getPosition()))
			end
		end
	else
		if self.cursorCache then
			love.mouse.setCursor() -- consider user defined cursor caching solution
			self.cursorCache = nil
		end
	end
end

function textbox:draw()
	lg.setColor(1,1,1)
	lg.print(self.text:sub(unpack(self.caretPosition)), 0, 16) -- Only for testing

	lg.setLineWidth(self.outlineWidth)
	lg.push()
	lg.setColor(self.backgroundColor)
	lg.rectangle("fill", self.x, self.y, self.width, self.height)
	lg.setColor(self.outlineColor)
	lg.rectangle("line", self.x, self.y, self.width, self.height)
	lg.setColor(self.hoverColor)
	if self:inBounds(love.mouse.getPosition()) then
		lg.rectangle("fill", self.x, self.y, self.width, self.height)
		lg.setColor(self.textColor)
	end



	lg.setScissor(self.x, self.y, self.width, self.height)
	local text = self.textAliasChar and string.rep(self.textAliasChar, self.text:len()) or
		self.text
	local textX = self.x + self.textOffset
	local textY = self.y + self.height/2 - self.font:getHeight()/2
	if self.selected then -- draw caret
		if self.caretBlinkTimer > 0 then
			local textWidth = self.font:getWidth(text)
			local caretX = self:getAbsCaretPos(2)
			lg.setLineWidth(self.caretWidth)
			lg.setColor(self.caretColor)
			lg.line(caretX, textY, caretX, textY + self.font:getHeight())
		end
	end
	lg.translate(self.textOffset, 0)
	lg.setFont(self.font)
	lg.setColor(self.textColor)
	lg.print(text, self.x, textY)
	lg.setScissor()
	lg.pop()

	if self.caretPosition[1] ~= self.caretPosition[2] then
		lg.setColor(self.selectionHighlight)
		local mn, mx = math.min(self.caretPosition[1], self.caretPosition[2]),
			math.max(self.caretPosition[1], self.caretPosition[2])

		-- local caretX = self.x + self.font:getWidth(self.text:sub(1, self.caretPosition[1]))
		lg.origin()
		lg.rectangle("fill",
			self:getAbsCharPos(mn), textY,
			self:getAbsCharPos(mx) - self:getAbsCharPos(mn), self.font:getHeight()
		)

		-- lg.rectangle("fill",
		-- 	self:getAbsCaretPos(1), textY,
		-- 	self:textWidth(mn, mx), self.font:getHeight()
		-- )

	end


end

--------------------------------------------
-------------Common Functions---------------
--------------------------------------------

function textbox:inBounds(x, y)
	return	x > self.x and
			x < self.x + self.width and
			y > self.y and
			y < self.y + self.height
end

function textbox:closeRightGap()
	if self.font:getWidth(self:getAbsText()) > self.width then
		if self.caretPosition[2] == #self.text or
			self.font:getWidth(self:getAbsText()) + self.textOffset < self.width
		then
			self.textOffset = self.width - self.font:getWidth(self:getAbsText())
		end
	else
		self.textOffset = 0
	end
end

function textbox:closeLeftGap()
	if self.textOffset > 0 then
		self.textOffset = 0
	end
end

function textbox:getAbsCharPos(char)
	return self.x + self.font:getWidth(self:getAbsText():sub(1, char)) + self.textOffset
end

function textbox:getAbsCaretPos(index)
	return self.x + self.font:getWidth(self.text:sub(1, self.caretPosition[index or 1])) + self.textOffset
end

function textbox:setCaretPos(p, relative)
	-- eventually will change when selection is done.
	-- will either put it to the right of second position if p is positive and left of 1 otherwise.
	if relative then p = self.caretPosition[1] + p end
	-- local change = p - self.caretPosition[1]
	p = clamp(p, 0, #self.text)
	self.caretPosition = {p, p}

	local absCursorPos = self:getAbsCaretPos()
	if absCursorPos < self.x then -- shift to the right
		self.textOffset = -self.font:getWidth(self:getAbsText():sub(1, self.caretPosition[1]))
	elseif absCursorPos > self.x + self.width then -- shift to the left
		self.textOffset = -self.font:getWidth(self:getAbsText():sub(1, self.caretPosition[1])) + self.width
	end
end

function textbox:selectionStart(char)
	self.caretPosition[1] = clamp(char, 0, #self.text)
end

function textbox:selectionEnd(char)
	self.caretPosition[2] = clamp(char, 0, #self.text)
end

function textbox:getClickCharacter(x, y)
	-- adjust for which side of center of character x is at for better accuracty.
	if self:inBounds(x, y) then
		x = x - self.textOffset
		local width, char = 0, 0
		local text = self:getAbsText()
		for i in string.gmatch(text, ".") do -- for each character
			local charWidth = self.font:getWidth(i) -- for left/right side of char accuracy
			width = width + charWidth -- add width of character
			char = char + 1 -- increment char
			if x - self.x < width then
				if x - self.x < width - charWidth / 2 then
					-- click left side of char
					return char - 1
				end
				-- click right side of char
				return char
			end
		end
		return #self.text
	end
end

function textbox:textWidth(i, j)
	if not i then return self.font:getWidth(self.text) end
	return self.font:getWidth(self.text:sub(i, j))
end

function textbox:getSelectedText()
	local cp = self.caretPosition
	return self.text:sub(cp[1], cp[2]), cp[1], cp[2]
end

function textbox:wordAtPos(pos)
	local start, finish = bisect(self, pos)
	local prefix = start:match("(%w-)$")
	local suffix = finish:match("(%w*)")
	return prefix..suffix, pos - #prefix, pos + #suffix
end

function textbox:removeSelection()
	self.caretPosition[1], self.caretPosition[2] = minmaxCaret(self.caretPosition[1], self.caretPosition[2])
	if self.caretPosition[1] == self.caretPosition[2] then return false end
	local start = self.text:sub(1, self.caretPosition[1])
	local finish = self.text:sub(self.caretPosition[2]+1, #self.text)
	self.text = start .. finish
	self:setCaretPos(#start)
	return true
end

function textbox:getAbsText()
	if not self.textAliasChar then return self.text end
	return string.rep(self.textAliasChar, self.text:len())
end

---------------------
----Set Functions----
---------------------

return textbox
