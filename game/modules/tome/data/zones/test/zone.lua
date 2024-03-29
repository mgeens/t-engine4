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

return {
	name = "TestZone!",
	level_range = {1, 50},
	level_scheme = "player",
	max_level = 4,
	decay = {300, 800},
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
	width = 50, height = 50,
	all_remembered = true,
	all_lited = true,
	no_level_connectivity = true,
	
	nicer_tiler_overlay = "DungeonWallsGrass",
--	events_by_level = true,
--	_max_level_generation_count = 2,
	
	generator =  {
		map = {
-- [[
			class = "engine.generator.map.MapScript",
			['<'] = "UP", ['>'] = "DOWN",
			['.'] = "FLOOR", ['+'] = "DOOR", ['#'] = "WALL",
			['_'] = "FLOOR", ['O'] = "WALL", 
			[';'] = "GRASS", ['T'] = "TREE",
			['='] = "DEEP_WATER",
			-- mapscript = "!rooms_test",
			-- greater_vaults_list = {"portal-vault"},
			-- mapscript = "!bsp_islands",
			-- mapscript = "!cavernous_forest",
			-- mapscript = "!testroom2",
			mapscript = "!inner_outer",
--]]
--[[
			class = "engine.generator.map.Hexacle",
			up = "FLOOR",
			down = "FLOOR",
			['.'] = "FLOOR",
			['#'] = "WALL",
--]]
--[[
			class = "engine.generator.map.Building",
			max_block_w = 15, max_block_h = 15,
			max_building_w = 5, max_building_h = 5,
			floor = "BAMBOO_HUT_FLOOR",
			external_floor = "BAMBOO_HUT_FLOOR",
			wall = "BAMBOO_HUT_WALL",
			up = "FLAT_UP6",
			down = "FLAT_DOWN4",
			door = "BAMBOO_HUT_DOOR",
--]]
--[[
			class = "engine.generator.map.Forest",
			edge_entrances = {4,6},
			zoom = 4,
			sqrt_percent = 30,
			noise = "fbm_perlin",
			floor = {"JUNGLE_GRASS","JUNGLE_GRASS","JUNGLE_GRASS","JUNGLE_GRASS","JUNGLE_DIRT",},
			wall = "JUNGLE_TREE",
			up = "GRASS_UP4",
			down = "GRASS_DOWN6",
			door = "GRASS",
--]]
--[[
			class = "engine.generator.map.Roomer",
			nb_rooms = 10,
			edge_entrances = {4,6},
			rooms = {"forest_clearing"},
			['.'] = {"JUNGLE_GRASS","JUNGLE_GRASS","JUNGLE_GRASS","JUNGLE_DIRT","JUNGLE_DIRT",},
			['#'] = "JUNGLE_TREE",
			up = "JUNGLE_GRASS_UP4",
			down = "JUNGLE_GRASS_DOWN6",
			door = "JUNGLE_GRASS",
--]]
--[[
			class = "engine.generator.map.Roomer",
			nb_rooms = 10,
			edge_entrances = {4,6},
			rooms = {"forest_clearing"},
			required_rooms = {"greater_vault", "greater_vault", "greater_vault"}, -- triggers level generation failure
--			greater_vaults_list = {"portal-vault"},
			greater_vaults_list = {"test2", "test"},
			['.'] = {"GRASS"},
			['#'] = "TREE",
			up = "GRASS_UP4",
			down = "GRASS_DOWN6",
			door = "GRASS",
--]]
		},
		actor = {
			class = "engine.generator.actor.OnSpots",
			nb_npc = {0, 0},
			nb_spots = true, on_spot_chance = 90, spot_filters = {{type="spawn-spot"}},
		},
--[[
		object = {
			class = "engine.generator.object.Random",
			nb_object = {12, 16},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {20, 30},
		},
]]
	},
	post_process = function(level) -- testing level generation failure
		-- if level.level >=3 then level.force_recreate = true end
	end,
	
--[[
	post_process = function(level)
		local Map = require "engine.Map"
		level.background_particle = require("engine.Particles").new("starfield", 1, {width=Map.viewport.width, height=Map.viewport.height})
	end,

	background = function(level, x, y, nb_keyframes)
		local Map = require "engine.Map"
		level.background_particle.ps:toScreen(x, y, true, 1)
	end,
]]
}
