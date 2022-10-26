
-- create radial set
-- add buttons
-- this only allows one to be selected at a time

local radial = {}
radial.__index = radial

function radial.new(...)
	local input = {...}
	local self = setmetatable({}, radial)

	self.buttons = {...}

	local radio = self
	for i, v in ipairs(self.buttons) do
		function v:_OnToggle()
			for i, v in ipairs(radio.buttons) do
				if v ~= self then
					v.selected = false
				end
			end
		end
	end

	return self
end

function radial:add(...)
	local radio = self
	local object = {...}
	for i, v in ipairs(object) do
		table.insert(self.buttons, v)
		function v:_OnToggle()
			for i, v in ipairs(radio.buttons) do
				if v ~= self then
					v.selected = false
				end
			end
		end
	end
end

function radial:remove(...)
	local object = {...}
	for i, v in ipairs(object) do
		for si, sv in ipairs(self.buttons) do
			if v == sv then
				table.remove(self.buttons, si)
				break
			end
		end
	end
end

local loveFunc = {
	"update", "draw", "keypressed","keyreleased","mousepressed",
	"mousereleased","mousemoved","wheelmoved","textinput"
}

for i, fName in ipairs(loveFunc) do
	radial[fName] = function(self, ...)
		for i, v in ipairs(self.buttons) do
			v[fName](v, ...)
		end
	end
end


return radial