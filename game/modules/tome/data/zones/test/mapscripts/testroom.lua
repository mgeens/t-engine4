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
tm:carveArea(';', tm:point(1, 1), tm:point(4, 4))

self.data.greater_vaults_list = {"32-chambers"}
local proom = Rooms.new(self, "greater_vault"):generateRoom()
tm:merge(12, 5, proom)

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
