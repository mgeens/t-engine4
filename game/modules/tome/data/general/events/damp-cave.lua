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

-- Find a random spot
local x, y = game.state:findEventGrid(level)
if not x then return false end

local id = "damp-cave-"..game.turn

print("[EVENT] Placing event", id, "at", x, y)

local changer = function(id)
	local npcs = mod.class.NPC:loadList{"/data/general/npcs/thieve.lua"}
	local objects = mod.class.Object:loadList("/data/general/objects/objects.lua")
	local terrains = mod.class.Grid:loadList("/data/general/grids/cave.lua")
	terrains.CAVE_LADDER_UP_WILDERNESS.change_level_shift_back = true
	terrains.CAVE_LADDER_UP_WILDERNESS.change_zone_auto_stairs = true
	terrains.CAVE_LADDER_UP_WILDERNESS.name = "ladder back to "..game.zone.name
	terrains.CAVE_LADDER_UP_WILDERNESS.change_zone = game.zone.short_name
	local zone = mod.class.Zone.new(id, {
		name = "Damp Cave",
		level_range = game.zone.actor_adjust_level and {math.floor(game.zone:actor_adjust_level(game.level, game.player)*1.05),
			math.ceil(game.zone:actor_adjust_level(game.level, game.player)*1.15)} or {game.zone.base_level, game.zone.base_level}, -- 5-15% higher actor levels
		__applied_difficulty = true, -- Difficulty already applied to parent zone
		level_scheme = "player",
		max_level = 1,
		actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
		width = 20, height = 20,
		ambient_music = "Swashing the buck.ogg",
		reload_lists = false,
		persistent = "zone",
		
		no_worldport = game.zone.no_worldport,
		min_material_level = util.getval(game.zone.min_material_level),
		max_material_level = util.getval(game.zone.max_material_level),
		generator =  {
			map = {
				class = "engine.generator.map.Cavern",
				zoom = 4,
				min_floor = 120,
				floor = "CAVEFLOOR",
				wall = "CAVEWALL",
				up = "CAVE_LADDER_UP_WILDERNESS",
				door = "CAVEFLOOR",
			},
			actor = {
				class = "mod.class.generator.actor.Random",
				nb_npc = {14, 14},
				guardian = {random_elite={life_rating=function(v) return v * 1.5 + 4 end, nb_rares=3}},
			},
			object = {
				class = "engine.generator.object.Random",
				filters = {{type="gem"}},
				nb_object = {6, 9},
			},
			trap = {
				class = "engine.generator.trap.Random",
				nb_trap = {6, 9},
			},
		},
		npc_list = npcs,
		grid_list = terrains,
		object_list = objects,
		trap_list = mod.class.Trap:loadList("/data/general/traps/natural_forest.lua"),
	})
	return zone
end

local g = game.level.map(x, y, engine.Map.TERRAIN):cloneFull()
g.name = "damp cave"
g.always_remember = true
g.display='>' g.color_r=0 g.color_g=0 g.color_b=255 g.notice = true
g.change_level=1 g.change_zone=id g.glow=true
g:removeAllMOs()
if engine.Map.tiles.nicer_tiles then
	g.add_displays = g.add_displays or {}
	g.add_displays[#g.add_displays+1] = mod.class.Grid.new{image="terrain/crystal_ladder_down.png", z=5}
end
g.nice_tiler = nil
g:altered()
g:initGlow()
g.real_change = changer
g.change_level_check = function(self)
	game:changeLevel(1, self.real_change(self.change_zone), {temporary_zone_shift=true, direct_switch=true})
	self.change_level_check = nil
	self.real_change = nil
	self.special_minimap = colors.VIOLET
	return true
end
game.zone:addEntity(game.level, g, "terrain", x, y)

return x, y
