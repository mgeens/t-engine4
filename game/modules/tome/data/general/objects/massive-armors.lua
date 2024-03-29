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

local Talents = require "engine.interface.ActorTalents"

-- Note:  The armor mastery talent scales this item type better than it does Mail
newEntity{
	define_as = "BASE_MASSIVE_ARMOR",
	slot = "BODY",
	type = "armor", subtype="massive",
	add_name = " (#ARMOR#)",
	display = "[", color=colors.SLATE, image = resolvers.image_material("plate", "metal"),
	moddable_tile = resolvers.moddable_tile("massive"),
	require = { flag = { "allow_wear_massive" }, },
	encumber = 17,
	rarity = 5,
	metallic = true,
	desc = [[A suit of armour made of metal plates.]],
	randart_able = "/data/general/objects/random-artifacts/generic.lua",
	egos = "/data/general/objects/egos/massive-armor.lua", egos_chance = { prefix=resolvers.mbonus(40, 5), suffix=resolvers.mbonus(40, 5) },
}

newEntity{ base = "BASE_MASSIVE_ARMOR",
	name = "iron plate armour", short_name = "iron",
	level_range = {1, 10},
	require = { stat = { str=22 }, },
	cost = 20,
	material_level = 1,
	wielder = {
		combat_armor = 7,
		fatigue = 22,
	},
}

newEntity{ base = "BASE_MASSIVE_ARMOR",
	name = "steel plate armour", short_name = "steel",
	level_range = {10, 20},
	require = { stat = { str=28 }, },
	cost = 25,
	material_level = 2,
	wielder = {
		combat_armor = 9,
		fatigue = 22,
	},
}

newEntity{ base = "BASE_MASSIVE_ARMOR",
	name = "dwarven-steel plate armour", short_name = "d.steel",
	level_range = {20, 30},
	require = { stat = { str=35 }, },
	cost = 30,
	material_level = 3,
	wielder = {
		combat_armor = 11,
		fatigue = 22,
	},
}

newEntity{ base = "BASE_MASSIVE_ARMOR",
	name = "stralite plate armour", short_name = "stralite",
	level_range = {30, 40},
	cost = 40,
	material_level = 4,
	require = { stat = { str=48 }, },
	wielder = {
		combat_armor = 13,
		fatigue = 22,
	},
}

newEntity{ base = "BASE_MASSIVE_ARMOR",
	name = "voratun plate armour", short_name = "voratun",
	level_range = {40, 50},
	require = { stat = { str=60 }, },
	cost = 50,
	material_level = 5,
	wielder = {
		combat_armor = 16,
		fatigue = 22,
	},
}
