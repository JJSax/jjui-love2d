
local uiSet = {}
uiSet.__index = uiSet
uiSet._version = "0.1.1"

-------------------------------------------
-------------Local Functions---------------
-------------------------------------------



--------------------------------------------
--------------Global Functions--------------
--------------------------------------------

--------------------------------------------
----------------Constructors----------------
--------------------------------------------

function uiSet.new()
	return setmetatable({
		objects = {},

		-- loopTypes for optimization
		-- Only have to check if the object has a function once when added.
		loopTypes = {
			update = {},
			draw = {},
			mousepressed = {},
			mousereleased = {},
			keypressed = {},
			keyreleased = {},
			wheelmoved = {},
			textinput = {},
			prompt = {}
		}
	}, uiSet)
end

--------------------------------------------
--------------Main Functions----------------
--Run these in their respective love loops--
--------------------------------------------

function uiSet:update(dt)
	for k,v in pairs(self.loopTypes.update) do
		k:update(dt)
	end
end

function uiSet:draw()
	for k,v in pairs(self.loopTypes.draw) do
		k:draw()
	end
end

function uiSet:mousepressed(x, y, button)
	for k,v in pairs(self.loopTypes.mousepressed) do
		k:mousepressed(x, y, button)
	end
end

function uiSet:mousereleased(x, y, button)
	for k,v in pairs(self.loopTypes.mousereleased) do
		k:mousereleased(x, y, button)
	end
end

function uiSet:keypressed(key, scancode, isRepeat)
	for k,v in pairs(self.loopTypes.keypressed) do
		k:keypressed(key, scancode, isRepeat)
	end
end

function uiSet:keyreleased(key, scancode, isRepeat)
	for k,v in pairs(self.loopTypes.keyreleased) do
		k:keyreleased(key, scancode, isRepeat)
	end
end

function uiSet:wheelmoved(x, y)
	for k,v in pairs(self.loopTypes.wheelmoved) do
		k:wheelmoved(x, y)
	end
end

function uiSet:textinput(t)
	for k,v in pairs(self.loopTypes.textinput) do
		k:textinput(t)
	end
end

function uiSet:prompt()
	for k,v in pairs(self.loopTypes.prompt) do
		k:drawPrompt()
	end
end

--------------------------------------------
-------------Common Functions---------------
--------------------------------------------

function uiSet:add(...)
	local object = {...}
	for i = 1, #object do
		table.insert(self.objects, object[i])
		for k,v in pairs(self.loopTypes) do
			if object[i][k] then
				self.loopTypes[k][object[i]] = true
			end
		end
	end
end

function uiSet:remove(...)
	-- pass object directly into function.  uiSet:remove(object1, object2)
	for k, object in pairs({...}) do
		for lType, v in pairs(self.loopTypes) do
			if object[lType] then
				self.loopTypes[lType][object] = nil
			end
		end
	end
end

---------------------
----Set Functions----
---------------------

return uiSet
