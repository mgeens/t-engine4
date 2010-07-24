-- ToME - Tales of Middle-Earth
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

local Talents = require "engine.interface.ActorTalents"

newEntity{
	define_as = "BASE_HEAVY_ARMOR",
	slot = "BODY",
	type = "armor", subtype="heavy", image = resolvers.image_material("mail", "metal"),
	add_name = " (#ARMOR#)",
	display = "[", color=colors.SLATE,
	require = { talent = { Talents.T_HEAVY_ARMOUR_TRAINING }, },
	encumber = 17,
	rarity = 5,
	metallic = true,
	desc = [[A suit of armour made of mail.]],
	egos = "/data/general/objects/egos/armor.lua", egos_chance = { prefix=resolvers.mbonus(40, 5), suffix=resolvers.mbonus(40, 5) },
}

newEntity{ base = "BASE_HEAVY_ARMOR",
	name = "iron mail armour",
	level_range = {1, 10},
	require = { stat = { str=14 }, },
	cost = 20,
	material_level = 1,
	wielder = {
		combat_def = 2,
		combat_armor = 4,
		fatigue = 12,
	},
}

newEntity{ base = "BASE_HEAVY_ARMOR",
	name = "steel mail armour",
	level_range = {10, 20},
	require = { stat = { str=20 }, },
	cost = 25,
	material_level = 2,
	wielder = {
		combat_def = 2,
		combat_armor = 6,
		fatigue = 14,
	},
}

newEntity{ base = "BASE_HEAVY_ARMOR",
	name = "dwarven-steel mail armour",
	level_range = {20, 30},
	require = { stat = { str=28 }, },
	cost = 30,
	material_level = 3,
	wielder = {
		combat_def = 3,
		combat_armor = 8,
		fatigue = 16,
	},
}

newEntity{ base = "BASE_HEAVY_ARMOR",
	name = "galvorn mail armour",
	level_range = {30, 40},
	cost = 40,
	material_level = 4,
	require = { stat = { str=38 }, },
	wielder = {
		combat_def = 4,
		combat_armor = 8,
		fatigue = 16,
	},
}

newEntity{ base = "BASE_HEAVY_ARMOR",
	name = "mithril mail armour",
	level_range = {40, 50},
	require = { stat = { str=48 }, },
	cost = 50,
	material_level = 5,
	wielder = {
		combat_def = 5,
		combat_armor = 10,
		fatigue = 16,
	},
}
