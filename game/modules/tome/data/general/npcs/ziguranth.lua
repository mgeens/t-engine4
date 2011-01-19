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

-- last updated: 9:25 AM 2/5/2010

local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_NPC_ZIGURANTH",
	type = "humanoid", subtype = "human",
	display = "p", color=colors.UMBER,
	faction = "zigur",

	combat = { dam=resolvers.rngavg(5,12), atk=2, apr=6, physspeed=2 },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
	resolvers.drops{chance=20, nb=1, {} },
	infravision = 20,
	lite = 3,

	life_rating = 15,
	rank = 2,
	size_category = 3,

	open_door = true,

	resolvers.talents{ [Talents.T_HEAVY_ARMOUR_TRAINING]=1, },
	resolvers.inscriptions(1, "infusion"),

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_dmap", talent_in=3, },
	energy = { mod=1 },
	stats = { str=20, dex=15, mag=1, con=16, wil=19 },
}

newEntity{ base = "BASE_NPC_ZIGURANTH",
	name = "ziguranth warrior", color=colors.CRIMSON,
	desc = [[A ziguranth warrior, clad in heavy armour.]],
	subtype = "dwarf",
	level_range = {20, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(100,110),
	resolvers.equip{
		{type="weapon", subtype="waraxe", autoreq=true},
		{type="armor", subtype="shield", autoreq=true},
		{type="armor", subtype="heavy", autoreq=true},
	},
	combat_armor = 10, combat_def = 6,
	resolvers.talents{
		[Talents.T_RESOLVE]=4,
		[Talents.T_AURA_OF_SILENCE]=4,
		[Talents.T_WEAPON_COMBAT]=4,
		[Talents.T_WEAPONS_MASTERY]=4,
		[Talents.T_SHIELD_PUMMEL]=4,
		[Talents.T_RUSH]=4,
	},
}

newEntity{ base = "BASE_NPC_ZIGURANTH",
	name = "ziguranth summoner", color=colors.CRIMSON,
	desc = [[A ziguranth wilder, attuned to nature.]],
	subtype = "elf",
	level_range = {20, nil}, exp_worth = 1,
	rarity = 2,
	max_life = resolvers.rngavg(100,110),
	resolvers.equip{
		{type="weapon", subtype="waraxe", autoreq=true},
		{type="armor", subtype="shield", autoreq=true},
		{type="armor", subtype="heavy", autoreq=true},
	},
	combat_armor = 10, combat_def = 6, life_rating = 11,
	equilibrium_regen = -20,

	autolevel = "wildcaster",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_dmap", talent_in=1, },

	resolvers.talents{
		[Talents.T_RESOLVE]=4,
		[Talents.T_MANA_CLASH]=3,
		[Talents.T_RESILIENCE]=4,
		[Talents.T_RITCH_FLAMESPITTER]=4,
		[Talents.T_HYDRA]=4,
		[Talents.T_WAR_HOUND]=4,
		[Talents.T_MINOTAUR]=4,
		[Talents.T_FIRE_DRAKE]=4,
		[Talents.T_SPIDER]=4,
	},
}

newEntity{ base = "BASE_NPC_ZIGURANTH",
	name = "ziguranth wyrmic", color=colors.CRIMSON,
	desc = [[A ziguranth wilder, attuned to nature.]],
	level_range = {20, nil}, exp_worth = 1,
	rarity = 2,
	rank = 3,
	max_life = resolvers.rngavg(100,110),
	resolvers.equip{
		{type="weapon", subtype="battleaxe", autoreq=true},
		{type="armor", subtype="heavy", autoreq=true},
	},
	combat_armor = 10, combat_def = 6, life_rating = 14,
	equilibrium_regen = -20,

	autolevel = "warriorwill",
	ai_state = { ai_move="move_dmap", talent_in=2, },
	ai = "tactical",

	resolvers.talents{
		[Talents.T_RESOLVE]=4,
		[Talents.T_ANTIMAGIC_SHIELD]=3,
		[Talents.T_FIRE_BREATH]=4,
		[Talents.T_ICE_BREATH]=4,
		[Talents.T_LIGHTNING_BREATH]=4,
		[Talents.T_ICY_SKIN]=4,
		[Talents.T_LIGHTNING_SPEED]=4,
		[Talents.T_TORNADO]=4,
	},
}
