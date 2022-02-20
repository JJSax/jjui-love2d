--[[
	* require this file to make a new toast type.
	* user defines callback animate (think love.update)
	* 	make animate return true if still animating
	*		false if animation finished.
	* user defines callback show (think love.draw)
	*	gets passed toast information

	@After requiring toast, set self.startVars table. i.e.
	toast = require "toast"
	toast:setStartingVars {
		x = 10, -- Can be a function or number.
		y = 10
	}
	-- @ This is for information shared between all toasts.
		-- @ One example of this is coordinates or alpha for self:show()
]]

--[[
	TODO
	Add pre-made toast types
	Consider how this library should fit into jjui/init.lua
	Consider how to allow stacked toasts.
		If you want multiple to happen at once, I want user to define how to handle.
]]


local toast = {_version = "0.1.1"}
toast.__index = toast
toast.queue = {}

function toast:reset()
	assert(not self.startingVars["startVars"], "Cannot use 'startVars' as a toast variable name")
	assert(not self.startingVars["queue"], "Cannot use 'queue' as a toast variable name")
	for k,v in pairs(self.startingVars) do
		self[k] = type(v) == "function" and v() or v
	end
end

function toast:setStartingVars(tab)
	self.startingVars = tab
	self:reset()
end

-- @ This is triggered when a new toast is started.
function toast:onStart() end

-- @ This adds a new toast to the queue.
function toast:trigger(info)
	assert(type(info) == "table", "Parameter 1 [info] type required \"table\"")
	table.insert(self.queue, info)
end

function toast:update(dt)
	if #self.queue > 0 then
		-- @ animate defined by user
		if not self:animate(dt) then
			table.remove(self.queue, 1)
			self:reset()
			self:onStart()
		end
	end
end

function toast:draw()
	if #self.queue > 0 then
		self:show(self.queue[1])
	end
end

-- @ This returns the library.
-- @ This is so you only need to update one thing; the rest is handled here
return setmetatable({}, toast)
