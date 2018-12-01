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

require "engine.class"
local Tilemap = require "engine.tilemaps.Tilemap"
local RoomsLoader = require "engine.generator.map.RoomsLoader"

--- Generate map-like data from a heightmap fractal
-- @classmod engine.tilemaps.Heightmap
module(..., package.seeall, class.inherit(Tilemap))

function _M:init(mapscript, rooms_list)
	self.mapscript = mapscript
	if type(rooms_list) == "string" then rooms_list = {rooms_list} end

	self.rooms = {}
	for _, file in ipairs(rooms_list) do
		table.insert(self.rooms, mapscript:loadRoom(file))
	end

	self.room_next_id = 1
end

function _M:generateRoom(temp_symbol, account_for_border)
	local mapscript = self.mapscript
	local roomdef = rng.table(self.rooms)
	local id = tostring(self)..":"..self.room_next_id
	local room = mapscript:roomGen(roomdef, id, mapscript.lev, mapscript.old_lev)
	if not room then
		print("Tilemap.Rooms failed to generate room")
		return nil
	end

	self.room_next_id = self.room_next_id + 1

	if account_for_border == nil then account_for_border = false end

	local tm = Tilemap.new({room.w - (account_for_border and 2 or 0), room.h - (account_for_border and 2 or 0)}, temp_symbol or '⍓')
	room.temp_symbol = temp_symbol
	mapscript.rooms_registers[id] = room
	mapscript.rooms_positions[id] = account_for_border and self:point(0, 0) or self:point(1, 1)

	tm.mergedAt = function(self, x, y)
		mapscript.rooms_positions[id] = mapscript.rooms_positions[id] + self:point(x - 1, y - 1)
	end

	print('------------------------------exits')
	table.print(room.exits)
	print('------------------------------')

	return tm
end
