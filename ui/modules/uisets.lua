
local uiSet = {}
uiSet.__index = uiSet
uiSet._version = "0.0.3"

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
		objects = {}
	}, uiSet)
end

--------------------------------------------
--------------Main Functions----------------
--Run these in their respective love loops--
--------------------------------------------

function uiSet:update(dt)
	for k, v in pairs(self.objects) do
		v:update(dt)
	end
end

function uiSet:draw()
	for k, v in pairs(self.objects) do
		v:draw()
	end
end

function uiSet:mousepressed(x, y, button)
	for k, v in pairs(self.objects) do
		v:mousepressed(x, y, button)
	end
end

function uiSet:mousereleased(x, y, button)
	for k, v in pairs(self.objects) do
		v:mousereleased(x, y, button)
	end
end

function uiSet:keypressed(key, scancode, isRepeat)
	for k, v in pairs(self.objects) do
		if v.keypressed then
			v:keypressed(key, scancode, isRepeat)
		end
	end
end

function uiSet:keyreleased(key, scancode, isRepeat)
	for k, v in pairs(self.objects) do
		if v.keyreleased then
			v:keyreleased(key, scancode, isRepeat)
		end
	end
end

function uiSet:wheelmoved(x, y)
	for k,v in pairs(self.objects) do
		if v.wheelmoved then
			v:wheelmoved(x, y)
		end
	end
end

--------------------------------------------
-------------Common Functions---------------
--------------------------------------------

function uiSet:add(...)
	local object = {...}
	for i = 1, #object do
		table.insert(self.objects, object[i])
	end
end

---------------------
----Set Functions----
---------------------

return uiSet
