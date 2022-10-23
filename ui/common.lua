local common = {
	_VERSION = "0.0.6"
}

common.__index = common
local lg = love.graphics

common.angles = {
	left = 0,
	right = math.pi,
	bottom = math.pi/2*3,
	top = math.pi/2
}

function common.dist(x1, y1, x2, y2, squared)
	local dx = x1 - x2
	local dy = y1 - y2
	local s = dx * dx + dy * dy
	return squared and s or math.sqrt(s)
end

function common.angle(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1)
end

function common.vector(angle, magnitude)
	return math.cos(angle) * magnitude, math.sin(angle) * magnitude
end

function common.map(n, start1, stop1, start2, stop2, Clamp)
	local mapped = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2
	if not Clamp then return mapped end
	if start2 < stop2 then
		return common.clamp(mapped, start2, stop2)
	else
		return common.clamp(mapped, stop2, start2)
	end
end

function common.inRange(num, mn, mx) -- do I want to require mn before mx?
	return (num >= mn and num <= mx) or (num <= mn and num >= mx)
end

function common.clamp(num, low, high)
	if num < low then return low end
	if num > high then return high end
	return num
end

function common.formatImage( image )
	-- assert(image, "Required image not passed.")
	if type(image) == "string" then
		return lg.newImage(image)
	elseif pcall(function() image:typeOf("Drawable") end) then
		return image
	elseif not image then return nil
	else
		error("Parameter passed not valid.  Must be either path to drawable, or drawable type.")
	end
end

function common.inside(tab, var)
	for k,v in pairs(tab) do
		if v == var then
			return true
		end
	end
	return false
end

function common.uncapitalize(str)
	return string.lower(str:sub(1, 1))..str:sub(2, string.len(str))
end

function common.formatVariable(var, ...)
	local l = ...
	local s = ""

	s = (common.inside(l, "pressed") and "Pressed") or (common.inside(l, "hover") and s.."Hover" or s) or s
	s = common.inside(l, "selected") and s.."Selected" or s

	-- format capitalization
	s = s..var:gsub("^%l", string.upper)
	s = s:gsub("^%l", string.lower)

	return common.uncapitalize(s)
end

-- iterates through similar vars and formats variable name
function common.simVarIter(main)
	local t = {"", "hover", "pressed", "selected", "hoverSelected", "pressedSelected"}
	local i = 0
	return function()
		i = i + 1
		if i <= #t then return common.uncapitalize(t[i]..main) end
	end
end

function common.merge(default, extra)
	if not extra then return default end
	for k,v in pairs(extra) do
		default[k] = v
	end
	return default
end

function common.sum(tab)
	local t = 0
	for k,v in pairs(tab) do
		t = t + v
	end
	return t
end

function common.average(tab)
	return common.sum(tab) / #tab
end

function common.pointInRect(x, y, bx, by, bw, bh)
	return  x > bx
		and	x < bx + bw
		and	y > by
		and	y < by + bh
end

function common.between(a1, a2, target)
	local min = math.min(a1, a2)
	local max = math.max(a1,a2)
	local diff = max - min
	local mid = max - diff/2

	local dot = math.cos(mid)*math.cos(target) + math.sin(mid)*math.sin(target)
	local angle = math.acos(dot)

	return angle <= diff/2
end

return common