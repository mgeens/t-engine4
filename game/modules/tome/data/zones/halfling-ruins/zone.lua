-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010 Nicolas Casalini
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
	name = "Ruined halfling complex",
	level_range = {10, 25},
	level_scheme = "player",
	max_level = 4,
	decay = {300, 800, only={object=true}},
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
	width = 50, height = 50,
	persistent = "zone",
--	all_remembered = true,
	all_lited = true,
	ambient_music = "Far away.ogg",
	min_material_level = 2,
	max_material_level = 3,
	generator =  {
		map = {
			class = "engine.generator.map.Roomer",
			nb_rooms = 10,
			rooms = {"random_room", {"money_vault",5}, {"lesser_vault",8}},
			lesser_vaults_list = {"circle","rat-nest","skeleton-mage-cabal"},
			lite_room_chance = 100,
			['.'] = "FLOOR",
			['#'] = "WALL",
			up = "UP",
			down = "DOWN",
			door = "DOOR",
			force_last_stair = true,
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {20, 30},
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {3, 6},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {6, 9},
		},
	},
	levels =
	{
		[1] = {
			day_night = true,
			generator = { map = {
				class = "engine.generator.map.Town",
				building_chance = 70,
				max_building_w = 8, max_building_h = 8,
				edge_entrances = {6,4},
				floor = "FLOOR",
				external_floor = "FLOOR",
				up = "FLAT_UP_WILDERNESS",
				wall = "WALL",
				down = "FLAT_DOWN4",
				door = "DOOR",

				nb_rooms = false,
				rooms = false,
			}, },
		},
		[4] = {
			generator = {
				map = {
					class = "engine.generator.map.Static",
					map = "zones/halfling-ruins-last",
				},
				actor = {
					area = {x1=0, x2=49, y1=0, y2=40},
				},
			},
		},
	},
	post_process = function(level)
		-- Place a lore note on each level
		game:placeRandomLoreObject("NOTE"..level.level)
	end,
	on_enter = function(lev, old_lev, newzone)
		if newzone then
			local p = game.party:findMember{main=true}
			local level = game.memory_levels["wilderness-1"]
			local spot = level:pickSpot{type="zone-pop", subtype="halfling-ruins"}
			p.wild_x = spot.x
			p.wild_y = spot.y
		end
	end,
}
