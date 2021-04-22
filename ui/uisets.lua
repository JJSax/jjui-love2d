
local uiSet = {}
uiSet.__index = uiSet
uiSet._version = "0.0.15"

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

--------------------------------------------
-------------Common Functions---------------
--------------------------------------------

function uiSet:add(object)
	table.insert(self.objects, object)
end

---------------------
----Set Functions----
---------------------

return uiSet
