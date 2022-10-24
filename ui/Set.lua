local Set = {}
Set.__index = Set

function Set.new(start)
	local self = setmetatable({}, Set)
	for k, v in ipairs(start or {}) do
		self[v] = true
	end
	return self
end

function Set:add(key)
	if key == nil then return end
	self[key] = true
end

function Set:remove(key)
	if key == nil then return end
	self[key] = nil
end
-- colors.__add(a, b)
function Set:size()
	local s = 0
	for k,v in pairs(self) do s = s + 1 end
	return s
end

-- common keys function
-- different keys function


return Set