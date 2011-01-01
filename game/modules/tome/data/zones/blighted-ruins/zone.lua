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
	name = "Blighted Ruins",
	level_range = {1, 8},
	level_scheme = "player",
	max_level = 8,
	decay = {300, 800},
	-- 8 levels but actors gain one level every 2 levels
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + math.floor((zone.max_level - level.level) / 2) + rng.range(-1,2) end,
	level_adjust_level = function(zone, level) return zone.base_level + math.floor((zone.max_level - level.level) / 2) end,
	width = 50, height = 50,
--	all_remembered = true,
--	all_lited = true,
	persistent = "zone",
	ambient_music = "Dark Secrets.ogg",
	no_worldport = true,
	generator =  {
		map = {
			class = "engine.generator.map.Roomer",
			force_last_stair = true,
			nb_rooms = 10,
			rooms = {"random_room", {"money_vault",5}, {"lesser_vault",8}},
			lesser_vaults_list = {"circle","amon-sul-crypt","rat-nest","skeleton-mage-cabal"},
			lite_room_chance = 100,
			['.'] = "FLOOR",
			['#'] = "WALL",
			up = "UP",
			down = "DOWN",
			door = "DOOR",
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {20, 30},
			filters = { {max_ood=2}, },
			guardian = "HALF_BONE_GIANT", guardian_level = 1,
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {6, 9},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {6, 9},
		},
	},
	levels =
	{
		[1] = {
			generator = { map = {
				up = "UP_WILDERNESS",
			}, },
		},
		[8] = {
			no_level_connectivity = true,
			generator = { map = {
				class = "engine.generator.map.Static",
				map = "zones/blighted-ruins-last",
			}, },
		},
	},
	on_enter = function(_, _, newzone)
		if newzone and not game.zone.created_lore then
			local levels = {2,3,4,5,6,7}
			game.zone.created_lore = {}
			for i = 1, 4 do
				local lev = rng.tableRemove(levels)
				game.zone.created_lore[lev] = i
				print("Lore "..i.." on level "..lev)
			end
		end
	end,
	post_process = function(level)
		-- Put lore near the up stairs
		if game.zone.created_lore and game.zone.created_lore[level.level] then
			-- Place a lore note on the level
			game:placeRandomLoreObject("NOTE"..game.zone.created_lore[level.level])
		end
	end,
}
