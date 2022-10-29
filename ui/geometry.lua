
local geometry = {_VERSION = "0.0.5"}
local uiRoot = (...):gsub('%.[^%.]+$', '')
local common = require(uiRoot..".common")

local min, max = common.min, common.max

geometry.angles = {
	left = 0,
	right = math.pi,
	bottom = math.pi/2*3,
	top = math.pi/2
}

function geometry.dist(x1, y1, x2, y2, squared)
	local dx = x1 - x2
	local dy = y1 - y2
	local s = dx * dx + dy * dy
	return squared and s or math.sqrt(s)
end

function geometry.angle(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1)
end

function geometry.vector(angle, magnitude)
	return math.cos(angle) * magnitude, math.sin(angle) * magnitude
end

function geometry.vector2(x, y, angle, magnitude)
	local vx, vy = geometry.vector(angle, magnitude)
	return x + vx, y + vy
end

function geometry.between(a1, a2, target)

	--@ a1/a2 is first/second angle
	--@ target is the angle to target point
	--* Returns true if target angle is between a1 and a2

	local min = min(a1, a2)
	local max = max(a1,a2)
	local diff = max - min
	local mid = max - diff/2

	local dot = math.cos(mid)*math.cos(target) + math.sin(mid)*math.sin(target)
	local angle = math.acos(dot)

	return angle <= diff/2
end

---- rectangle geometry

function geometry.checkRectangleOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    -- if rectangle has area 0, no overlap
    if w1 == 0 or h1 == 0 or w2 == 0 or h2 == 0 then return false end

    -- If one rectangle is on left side of other
    if x1 + w1 < x2 or x2 + w2 < x1 then return false end

    -- If one rectangle is above other
    if y1 + h1 < y2 or y2 + h2 < y1 then return false end

    return true
end

function geometry.rectangleOverlapArea(x1, y1, w1, h1, x2, y2, w2, h2)
	--! May have issues if width or height is negative
	if not geometry.checkRectangleOverlap(x1, y1, w1, h1, x2, y2, w2, h2) then return false end

	local x, y = max(x1, x2), max(y1, y2)
	local w, h = min(x1 + w1, x2 + w2), min(y1 + h1, y2 + h2)
	return x, y, w, h
end

function geometry.pointInRect(x, y, bx, by, bw, bh)
	return  x > bx
	   and	x < bx + bw
	   and	y > by
	   and	y < by + bh
end

 ---- Line Geometry

function geometry.midPoint(ax, ay, bx, by)
	local dist = geometry.dist(ax, ay, bx, by)/2
	local angle = geometry.angle(ax, ay, bx, by)
	return geometry.vector2(ax, ay, angle, dist)
end

function geometry.nearestPointToLine(px, py, ax, ay, bx, by) -- for geometric line.
	-- returns a point on the infinite line nearest px, py
	common.assert(type(px) == "number", "Param1 requires type number", 3)
	common.assert(type(py) == "number", "Param2 requires type number", 3)
	local a_p = {px - ax, py - ay}
	local a_b = {bx - ax, by - ay}
	local atb2 = a_b[1]^2 + a_b[2]^2 -- same as distance
	local atp_dot_atb = a_p[1] * a_b[1] + a_p[2] * a_b[2]
	local t = atp_dot_atb / atb2

	return ax + a_b[1] * t, ay + a_b[2] * t
end

function geometry.distanceToLine(px, py, nearestX, nearestY) -- geometric line
	--@px, py is point to check from line nearestX, nearestY

	common.assert(type(px) == "number", "Param1 requires type number", 3)
	common.assert(type(py) == "number", "Param2 requires type number", 3)
	-- local nearestX, nearestY = self:nearestPointToLine(px, py)
	return geometry.dist(nearestX, nearestY, px, py)
end

function geometry.pointOnLine(mx, my, ax, ay, bx, by, pBuff)
	common.assert(type(mx) == "number", "Param1 requires type number", 3)
	common.assert(type(my) == "number", "Param2 requires type number", 3)

	local npx, npy = geometry.nearestPointToLine(mx, my, ax, ay, bx, by) -- Make this be passed in
	local a_b = geometry.dist(ax, ay, bx, by)
	local np_a = geometry.dist(npx, npy, ax, ay, false)
	local np_b = geometry.dist(npx, npy, bx, by, false)

	local pointBetweenA_B = np_b < pBuff + a_b and np_a < pBuff + a_b

	return geometry.dist(mx, my, npx, npy) <= pBuff	and pointBetweenA_B
end

return geometry