-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2018 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org


-- This file implements Kruskals algorithm to find a minimum spanning tree in a graph of rooms


local unionfind = require "algorithms.unionfind"

local max_links = args.max_links or 3
local map = args.map
local rooms = args.rooms

if #rooms <= 1 then return true end -- Easy !

-----------------------------------------------------------
-- Small Edge class
-----------------------------------------------------------
local Edge_t
Edge_t = { __index = {
	hash = function(e)
		local s1, s2 = tostring(e.from), tostring(e.to)
		if s2 < s1 then s2, s1 = s1, s2 end
		return s1..":"..s2
	end,
} }
local function Edge(r1, r2)
	local c1, c2 = r1:centerPoint(), r2:centerPoint()
	return setmetatable({from=r1, to=r2, cost=core.fov.distance(c1.x, c1.y, c2.x, c2.y)}, Edge_t)
end
-----------------------------------------------------------


-- Generate all possible edges
local edges = {}
for i, room in ipairs(rooms) do
	local c = room:centerPoint()
	for j, proom in ipairs(rooms) do if proom ~= room then
		local e = Edge(room, proom)
		edges[e:hash()] = e
	end end
end
local sorted_edges = table.values(edges)
table.sort(sorted_edges, "cost")
-- print("===TOTAL EDGES / rooms", #edges, #rooms)
-- table.print(edges)

-- Find the MST graph
local uf = unionfind.create()
local mst = {}
for _, edge in ipairs(sorted_edges) do
	-- Skip this edge to avoid creating a cycle in MST
	if not uf:connected(edge.from, edge.to) then
		-- Include this edge
		uf:union(edge.from, edge.to)
		mst[edge:hash()] = edge
	end
end
-- table.print(mst)

-- Add some more randomly selected edges
local nb_adds = args.edges_surplus or 0
while nb_adds > 0 and next(edges) do
	local _, edge = next(edges)
	edges[edge:hash()] = nil
	mst[edge:hash()] = edge
	nb_adds = nb_adds - 1
end

-- Draw the paths
local full = true
for _, edge in pairs(mst) do
	local pos1, kind1 = edge.from:findRandomClosestExit(7, edge.to:centerPoint(), nil, args.exitable_chars or {'.', ';', '='})
	local pos2, kind2 = edge.to:findRandomClosestExit(7, edge.from:centerPoint(), nil, args.exitable_chars or {'.', ';', '='})
	if pos1 and pos2 then
		map:tunnelAStar(pos1, pos2, args.tunnel_char or '.', args.tunnel_through or {'#'}, args.tunnel_avoid or nil, {erraticness=args.erraticness or 5})
		if kind1 == 'open' then map:smartDoor(pos1, args.door_chance or 40, '+') end
		if kind2 == 'open' then map:smartDoor(pos2, args.door_chance or 40, '+') end
	else
		full = false
	end
end

return full
