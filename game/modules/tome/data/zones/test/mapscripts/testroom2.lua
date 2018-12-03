-- ToME - Tales of Maj'Eyal
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

-- Merge them all
local tm = Tilemap.new(self.mapsize, '#')
-- tm:carveArea(';', tm:point(1, 1), tm:point(4, 4))

-- self.data.greater_vaults_list = {"32-chambers"}
local room_factory = Rooms.new(self, "random_room")

local rooms = {}
for i = 1, 15 do
	local proom = room_factory:generateRoom()
	local pos = tm:findRandomArea(nil, tm.data_size, proom.data_w, proom.data_h, '#', 1)
	if pos then
		tm:merge(pos, proom:build())
		rooms[#rooms+1] = proom
	end
end

local up_stairs = true
for i = 1, 3 do
	local pond = Heightmap.new(1.6, {up_left=0, down_left=0, up_right=0, down_right=0, middle=1}):make(15, 15, {' ', ';', ';', 'T', '=', '=', up_stairs and '<' or ';'})
	local pos = tm:findRandomArea(nil, tm.data_size, pond.data_w, pond.data_h, '#', 1)
	if pos then
		tm:merge(pos, pond)
		rooms[#rooms+1] = pond
		up_stairs = false
	end
end

rooms = tm:sortListCenter(rooms)

for i, room in ipairs(rooms) do
	if i > 1 then
		local proom = rooms[i-1]
		local pos1, kind1 = proom:findRandomClosestExit(7, room:centerPoint(), nil, {'.', ' ', ';'})
		local pos2, kind2 = room:findRandomClosestExit(7, proom:centerPoint(), nil, {'.', ' ', ';'})
		if pos1 and pos2 then
			tm:tunnelAStar(pos1, pos2, '.', {'#','⍓'}, nil, {erraticness=5})
			if kind1 == 'open' and rng.percent(40) then tm:put(pos1, '+') end
			if kind2 == 'open' and rng.percent(40) then tm:put(pos2, '+') end
		end

	end
	-- tm:carveArea(string.char(string.byte('0')+i-1), room.merged_pos, room.merged_pos + room.data_size - 1)
end

self:setEntrance(tm:locateTile('<'))
self:setExit(rooms[#rooms]:centerPoint()) tm:put(rooms[#rooms]:centerPoint(), '>')

tm:printResult()


-- print('---==============---')
-- local noise = Noise.new(nil, 0.5, 2, 3, 6):make(80, 50, {'T', 'T', '=', '=', '=', ';', ';'})
-- noise:printResult()
-- print('---==============---')
-- print('---==============---')
-- local pond = Heightmap.new(1.9, {up_left=0, down_left=0, up_right=0, down_right=0, middle=1}):make(30, 30, {';', 'T', '=', '=', ';'})
-- pond:printResult()
-- print('---==============---')
-- print('---==============---')
-- local maze = Maze.new():makeSimple(31, 31, '.', {'#','T'}, true)
-- maze:printResult()
-- print('---==============---')

-- DGDGDGDG: make at least Tilemap handlers for BSP, roomer (single room), roomers and correctly handle up/down stairs

return tm
