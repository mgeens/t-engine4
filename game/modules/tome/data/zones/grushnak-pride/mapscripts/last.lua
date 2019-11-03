-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
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

tm:fillAll()
-- rng.seed(2)

self:defineTile('"', "HARDWALL")
self:defineTile('>', "SLIME_TUNNELS", nil, nil, nil, {special="slimepit"})
self:defineTile(";", "UNDERGROUND_CREEP", nil, nil, nil, {special="slimepit"})
self:defineTile("s", "UNDERGROUND_CREEP", nil, {random_filter={special_rarity="slime_rarity"}}, nil, {special="slimepit"})
self:defineTile("S", "UNDERGROUND_CREEP", nil, {random_filter={special_rarity="slime_rarity", random_boss={force_classes={Oozemancer=true}, nb_classes=1, loot_quality="store", loot_quantity=1, no_loot_randart=true, ai_move="move_complex", rank=4}}}, nil, {special="slimepit"})

-- Make the barracks
local bsp
repeat
	tm.data = tm:makeData(tm.data_w, tm.data_h, '"')

	bsp = BSP.new(4, 4, 6):make(20, 39, '.', '#')
	tm:merge(2, 2, bsp)

	-- Remove a few rooms
	for _, room in ripairs(bsp.rooms) do
		if rng.percent(25) then
			bsp:removeRoom(room)
			local from, to = room:bounds()
			tm:carveArea('#', from, to)
		end
	end

	-- Connect them
	for _, edge in ipairs(bsp:mstEdges(3)) do
		local points = edge.points
		tm:put(rng.table(points), '+')
	end

-- Ensure enough size
until tm:eliminateByFloodfill{'#', '"', 'T'} >= 300

-- Start a WFC for the slime pit while we do the rest
local wfcglade
while true do
	wfcglade = WaveFunctionCollapse.new{
		mode="overlapping", async=true,
		sample=self:getFile("!glade.tmx", "samples"),
		size={16, 16},
		n=2, symmetry=8, periodic_out=false, periodic_in=false, has_foundation=false
	}

	-- Finish slimepit and check its size
	wfcglade:waitCompute()
	wfcglade:carveBorder('T', wfcglade:point(1, 1), wfcglade.data_size)
	if wfcglade:eliminateByFloodfill{'T'} >= 25 then
		-- Find a 3x3 zone of floor to place exit in the middle
		local exit = wfcglade:findRandomArea(nil, nil, 3, 3, ';')
		if exit then
			wfcglade:carveArea('s', exit, exit+2)
			wfcglade:put(exit+1, '>')
			break
		end
	end
end

-- Turn one of the slimes into a boss
local slimeboss = wfcglade:locateTile('s')
wfcglade:put(slimeboss, 'S')

-- Some more random slime
for i = 1, 12 do
	local slime = wfcglade:locateTile(';')
	wfcglade:put(slime, 's')
end

-- Extract the group for the pit
local slimegroup = wfcglade:findGroupsOf{';'}
if #slimegroup ~= 1 then return self:regenerate() end -- Sanity; shouldnt happen
slimegroup = slimegroup[1]

-- Merge pit, and put trees around
tm:carveArea('T', tm:point(23, 4), tm:point(23, 4) + 18)
tm:merge(24, 5, wfcglade, {'T', ';', '>', 's', 'S'})

-- Move the slimegroup to the target area, sort it to find the lower point and use it as tunnel start
slimegroup:translate(tm:point(24, 5) - 1)
slimegroup:sortPoints(function(a, b)
	if a.x == b.x then return a.y > b.y
	else return a.x > b.x end
end)
local slime_entry = slimegroup.list[1]

local bspgroup = tm:findGroupsOf{'.', '+'}
if #bspgroup ~= 1 then return self:regenerate() end -- Sanity; shouldnt happen
bspgroup = bspgroup[1]
bspgroup:sortPoints(function(a, b)
	if a.x == b.x then return a.y > b.y
	else return a.x > b.x end
end)
local bsp_exit = bspgroup.list[1]

-- Tunnel to barracks
tm:tunnel(bsp_exit, tm:point(slime_entry.x, bsp_exit.y), ';', {'T', '"', '#', ';'}, {}, {tunnel_random=0})
tm:tunnel(tm:point(slime_entry.x, bsp_exit.y), slime_entry, ';', {'T', '"', '#', ';'}, {}, {tunnel_random=0})

-- Entry
bspgroup:sortPoints(function(a, b)
	if a.x == b.x then return a.y < b.y
	else return a.x < b.x end
end)
local entry = bspgroup.list[1]
tm:put(entry, '<')

tm:printResult()

return tm
