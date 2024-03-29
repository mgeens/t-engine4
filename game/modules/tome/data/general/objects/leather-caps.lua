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

newEntity{
	define_as = "BASE_LEATHER_CAP",
	slot = "HEAD",
	type = "armor", subtype="head",
	add_name = " (#ARMOR#)",
	display = "]", color=colors.UMBER, image = resolvers.image_material("cap", "leather"),
	moddable_tile = resolvers.moddable_tile("leather_cap"),
	encumber = 2,
	rarity = 6,
	desc = [[A cap made of leather.]],
	randart_able = "/data/general/objects/random-artifacts/generic.lua",
	egos = "/data/general/objects/egos/helm.lua", egos_chance = { prefix=resolvers.mbonus(40, 5), suffix=resolvers.mbonus(40, 5) },
}

newEntity{ base = "BASE_LEATHER_CAP",
	name = "rough leather cap", short_name = "rough",
	level_range = {1, 20},
	cost = 2,
	material_level = 1,
	wielder = {
		combat_armor = 1,
		fatigue = 1,
	},
}

newEntity{ base = "BASE_LEATHER_CAP",
	name = "hardened leather cap", short_name = "hardened",
	level_range = {20, 40},
	cost = 4,
	material_level = 3,
	wielder = {
		combat_armor = 3,
		fatigue = 3,
	},
}

newEntity{ base = "BASE_LEATHER_CAP",
	name = "drakeskin leather cap", short_name = "drakeskin",
	level_range = {40, 50},
	cost = 7,
	material_level = 5,
	wielder = {
		combat_armor = 5,
		fatigue = 5,
	},
}
