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

local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_NPC_VAMPIRE",
	type = "undead", subtype = "vampire",
	display = "V", color=colors.WHITE,
	desc = [[These ancient cursed beings often take the form of a bat and attack their prey.]],

	combat = { dam=resolvers.levelup(resolvers.mbonus(30, 10), 1, 0.8), atk=10, apr=9, damtype=DamageType.DRAINLIFE, dammod={str=1.9} },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	drops = resolvers.drops{chance=20, nb=1, {} },

	autolevel = "warriormage",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_complex", talent_in=9, },
	stats = { str=12, dex=12, mag=12, con=12 },
	infravision = 10,
	life_regen = 3, life_rating = 14,
	size_category = 3,
	rank = 2,

	open_door = true,

	resolvers.inscriptions(1, "rune"),

	resolvers.sustains_at_birth(),

	resolvers.talents{
		[Talents.T_BLURRED_MORTALITY]={base=1, every=7, max=6},
		[Talents.T_VAMPIRIC_GIFT]={base=1, every=7, max=6},
	},

	resists = { [DamageType.COLD] = 80, [DamageType.NATURE] = 80, [DamageType.LIGHT] = -50,  },
	blind_immune = 1,
	confusion_immune = 1,
	see_invisible = 5,
	undead = 1,
--	free_action = 1,
--	sleep_immune = 1,
	not_power_source = {nature=true},
}

newEntity{ base = "BASE_NPC_VAMPIRE",
	name = "lesser vampire", color=colors.SLATE, image = "npc/lesser_vampire.png",
	desc=[[This vampire has only just begun its new life. It has not yet fathomed its newfound power, yet it still has a thirst for blood.]],
	level_range = {10, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(40,50),
	combat_armor = 7, combat_def = 6,

	resolvers.talents{
		[Talents.T_STUN]={base=1, every=7, max=5},
		[Talents.T_INVOKE_DARKNESS]={base=2, every=7, max=5},
	},
}

newEntity{ base = "BASE_NPC_VAMPIRE",
	name = "vampire", color=colors.SLATE, image = "npc/vampire.png",
	desc=[[It is a humanoid with an aura of power. You notice a sharp set of front teeth.]],
	level_range = {15, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(70,80),
	combat_armor = 9, combat_def = 6,

	resolvers.talents{
		[Talents.T_STUN]={base=1, every=7, max=5},
		[Talents.T_BLUR_SIGHT]={base=1, every=7, max=5},
		[Talents.T_ROTTING_DISEASE]={base=1, every=7, max=5},
		[Talents.T_CIRCLE_OF_DEATH]={base=1, every=7, max=6},
	},
}

newEntity{ base = "BASE_NPC_VAMPIRE",
	name = "master vampire", color=colors.GREEN, image = "npc/master_vampire.png",
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/master_vampire.png", display_h=2, display_y=-1}}},
	desc=[[It is a humanoid form dressed in robes. Power emanates from its chilling frame.]],
	level_range = {20, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(80,90),
	combat_armor = 10, combat_def = 8,
	ai = "dumb_talented_simple", ai_state = { talent_in=6, },
	resolvers.talents{
		[Talents.T_STUN]={base=1, every=7, max=5},
		[Talents.T_BLUR_SIGHT]={base=2, every=7, max=5},
		[Talents.T_PHANTASMAL_SHIELD]={base=1, every=7, max=5},
		[Talents.T_ROTTING_DISEASE]={base=2, every=7, max=5},
		[Talents.T_COLD_FLAMES]={base=1, every=7, max=6},
	},
}

newEntity{ base = "BASE_NPC_VAMPIRE",
	name = "elder vampire", color=colors.RED, image = "npc/elder_vampire.png",
	desc=[[A terrible robed undead figure, this creature has existed in its unlife for many centuries by stealing the life of others.
It can summon the very shades of its victims from beyond the grave to come enslaved to its aid.]],
	level_range = {25, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(90,100),
	combat_armor = 12, combat_def = 10,
	rank = 3,
	ai = "tactical", ai_state = { talent_in=4, },
	resolvers.inscriptions(1, "rune"),
	summon = {{type="undead", number=1, hasxp=false}, },
	resolvers.talents{
		[Talents.T_STUN]={base=2, every=7, max=6},
		[Talents.T_SUMMON]=1,
		[Talents.T_BLUR_SIGHT]={base=3, every=7, max=7},
		[Talents.T_PHANTASMAL_SHIELD]={base=2, every=7, max=6},
		[Talents.T_ROTTING_DISEASE]={base=3, every=7, max=7},
		[Talents.T_FORGERY_OF_HAZE]={base=2, every=7, max=5},
	},
	ingredient_on_death = "ELDER_VAMPIRE_BLOOD",
}

newEntity{ base = "BASE_NPC_VAMPIRE",
	name = "vampire lord", color=colors.BLUE, image = "npc/vampire_lord.png",
	desc=[[A foul wind chills your bones as this ghastly figure approaches.]],
	level_range = {30, nil}, exp_worth = 1,
	rarity = 4,
	max_life = resolvers.rngavg(100,120),
	combat_armor = 15, combat_def = 15,
	rank = 3,
	ai = "tactical", ai_state = { talent_in=3, },
	resolvers.inscriptions(1, "rune"),
	summon = {{type="undead", number=1, hasxp=false}, },
	resolvers.talents{
		[Talents.T_FORGERY_OF_HAZE]={base=2, every=7, max=6},
		[Talents.T_IMPENDING_DOOM]={base=2, every=7, max=6},
		[Talents.T_STUN]={base=4, every=7, max=8},
		[Talents.T_SUMMON]=1,
		[Talents.T_BLUR_SIGHT]={base=4, every=7, max=8},
		[Talents.T_PHANTASMAL_SHIELD]={base=5, every=7, max=8},
		[Talents.T_ROTTING_DISEASE]={base=5, every=7, max=8},
	},
	make_escort = {
		{type="undead", number=resolvers.mbonus(2, 2)},
	},
	ingredient_on_death = "VAMPIRE_LORD_FANG",
}