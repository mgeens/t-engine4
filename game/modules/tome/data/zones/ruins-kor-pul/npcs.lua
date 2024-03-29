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

if not currentZone.is_hideout then
	load("/data/general/npcs/rodent.lua", rarity(0))
	load("/data/general/npcs/vermin.lua", rarity(2))
	load("/data/general/npcs/molds.lua", rarity(1))
	load("/data/general/npcs/skeleton.lua", rarity(0))
	load("/data/general/npcs/snake.lua", rarity(2))

	load("/data/general/npcs/all.lua", rarity(4, 35))
else
	load("/data/general/npcs/rodent.lua", rarity(0))
	load("/data/general/npcs/vermin.lua", rarity(2))
	load("/data/general/npcs/molds.lua", rarity(1))
	load("/data/general/npcs/thieve.lua", rarity(0))
	load("/data/general/npcs/snake.lua", rarity(2))

	load("/data/general/npcs/all.lua", rarity(4, 35))
end

local Talents = require("engine.interface.ActorTalents")

-- The boss of Amon Sul, no "rarity" field means it will not be randomly generated
newEntity{ define_as = "SHADE",
	allow_infinite_dungeon = true,
	type = "undead", subtype = "skeleton", unique = true,
	name = "The Shade",
	display = "s", color=colors.VIOLET,
	shader = "unique_glow",
	desc = [[This skeleton looks nasty. There are red flames in its empty eye sockets. It wields a nasty sword and strides toward you, throwing spells.]],
	killer_message = "and left to rot",
	level_range = {7, nil}, exp_worth = 2,
	max_life = 150, life_rating = 15, fixed_rating = true,
	max_mana = 85,
	max_stamina = 85,
	rank = 4,
	tier1 = true,
	size_category = 3,
	undead = 1,
	infravision = 10,
	stats = { str=16, dex=12, cun=14, mag=25, con=16 },
	instakill_immune = 1,
	blind_immune = 1,
	cut_immune = 1,
	move_others=true,
	combat_spellcrit = -20,
	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	equipment = resolvers.equip{ {type="weapon", subtype="staff", defined="STAFF_KOR", random_art_replace={chance=75}, autoreq=true}, {type="armor", subtype="light", forbid_power_source={antimagic=true}, autoreq=true}, },
	resolvers.drops{chance=100, nb=3, {tome_drops="boss"} },

	resolvers.talents{
		[Talents.T_MANATHRUST]=3, [Talents.T_FREEZE]=3, [Talents.T_TIDAL_WAVE]=2,
		[Talents.T_WEAPONS_MASTERY]=2,
	},
	resolvers.inscriptions(1, {"shielding rune", "phase door rune"}),
	resolvers.inscriptions(1, {"manasurge rune"}),
	inc_damage = {all=-40},

	autolevel = "warriormage",
	resolvers.auto_equip_filters("Archmage"),
	auto_classes={{class="Archmage", start_level=12, level_rate=75}},

	ai = "tactical", ai_state = { talent_in=3, ai_move="move_astar", },
	ai_tactic = resolvers.tactic"melee",

	-- Override the recalculated AI tactics to avoid problematic kiting in the early game
	-- In this case safe_range being set while talent_in is above 1 still results in a lot of kiting, so we lower the safe range too
	low_level_tactics_override = {escape=0, safe_range=1},

	on_die = function(self, who)
		game.state:activateBackupGuardian("KOR_FURY", 3, 35, ".. yes I tell you! The old ruins of Kor'Pul are still haunted!")
		game.player:resolveSource():setQuestStatus("start-allied", engine.Quest.COMPLETED, "kor-pul")
	end,
}

newEntity{ base = "BASE_NPC_THIEF", define_as = "THE_POSSESSED",
	allow_infinite_dungeon = true,
	name = "The Possessed", color=colors.VIOLET,
	resolvers.nice_tile{image="invis.png", add_mos = {{image="npc/humanoid_human_the_possessed.png", display_h=2, display_y=-1}}},
	desc = [[He is the leader of a gang of bandits that killed the Shade of Kor'Pul, however it is obvious the Shade was merely displaced. It is now possessing the corpse of his killer.]],
	killer_message = "and used as a new host",
	level_range = {7, nil}, exp_worth = 2,
	unique = true,
	rank = 4,
	tier1 = true,
	combat_armor = 5, combat_def = 7,
	max_life = 150, life_rating = 15, fixed_rating = true,

	equipment = resolvers.equip{
		{type="weapon", subtype="dagger", defined="UNERRING_SCALPEL", random_art_replace={chance=75}, autoreq=true},
		{type="armor", subtype="light", forbid_power_source={antimagic=true}, autoreq=true},
	},
	resolvers.drops{chance=100, nb=3, {tome_drops="boss"} },

	instakill_immune = 1,

	make_escort = {
		{type="humanoid", subtype="human", name="thief", number=1},
	},
	resolvers.talents{
		[Talents.T_DUAL_STRIKE]={base=2, every=6, max=7},
		[Talents.T_LETHALITY]={base=3, every=6, max=6},
		[Talents.T_ARCANE_COMBAT]={base=3, every=5, max=7},
		[Talents.T_EARTHEN_MISSILES]={base=1, every=5, max=7},
	},

	autolevel = "rogue",
	auto_classes={{class="Arcane Blade", start_level=12, level_rate=75}},
	ai = "tactical", ai_state = { talent_in=2, ai_move="move_astar", },

	-- Override the recalculated AI tactics to avoid problematic kiting in the early game
	low_level_tactics_override = {escape=0, safe_range=1},
	
	on_die = function(self, who)
		game.state:activateBackupGuardian("KOR_FURY", 3, 35, ".. yes I tell you! The old ruins of Kor'Pul are still haunted!")
		game.player:resolveSource():setQuestStatus("start-allied", engine.Quest.COMPLETED, "kor-pul")
		game.player:resolveSource():setQuestStatus("start-allied", engine.Quest.COMPLETED, "kor-pul-invaded")
	end,
}
-- The boss of Amon Sul, no "rarity" field means it will not be randomly generated
newEntity{ define_as = "KOR_FURY",
	allow_infinite_dungeon = true,
	type = "undead", subtype = "ghost", unique = true,
	name = "Kor's Fury",
	display = "G", color=colors.VIOLET,
	desc = [[The Shade's colossal will keeps it anchored to this world, now as a vengeful, insane spirit.]],
	level_range = {38, nil}, exp_worth = 3,
	max_life = 250, life_rating = 20, fixed_rating = true,
	rank = 4,
	size_category = 3,
	infravision = 10,
	stats = { str=16, dex=12, cun=14, mag=25, con=16 },

	undead = 1,
	no_breath = 1,
	stone_immune = 1,
	confusion_immune = 1,
	fear_immune = 1,
	cut_immune = 1,
	teleport_immune = 0.5,
	disease_immune = 1,
	poison_immune = 1,
	stun_immune = 1,
	blind_immune = 1,
	see_invisible = 80,
	move_others=true,

	can_pass = {pass_wall=70},
	resists = {all = 35, [DamageType.LIGHT] = -70, [DamageType.DARKNESS] = 65},

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, NECK=1 },
	resolvers.equip{
		{type="weapon", subtype="staff", force_drop=true, tome_drops="boss", forbid_power_source={antimagic=true}, autoreq=true},
		{type="armor", subtype="light", forbid_power_source={antimagic=true}, autoreq=true},
		{type="jewelry", subtype="amulet", defined="VOX", random_art_replace={chance=75}, autoreq=true},
	},
	resolvers.drops{chance=100, nb=3, {tome_drops="boss"} },

	resolvers.talents{
		[Talents.T_MANATHRUST]={base=5, every=6, max=8},
		[Talents.T_FREEZE]={base=5, every=6, max=8},
		[Talents.T_TIDAL_WAVE]={base=5, every=6, max=8},
		[Talents.T_ICE_STORM]={base=5, every=6, max=8},
		[Talents.T_BURNING_HEX]={base=5, every=6, max=8},
		[Talents.T_EMPATHIC_HEX]={base=5, every=6, max=8},
		[Talents.T_CURSE_OF_DEATH]={base=5, every=6, max=8},
		[Talents.T_CURSE_OF_IMPOTENCE]={base=5, every=6, max=8},
		[Talents.T_VIRULENT_DISEASE]={base=5, every=6, max=8},
	},

	autolevel = "caster",
	auto_classes={{class="Archmage", start_level=39, level_rate=50},
		{class="Corruptor", start_level=39, level_rate=50}
	},
	ai = "tactical", ai_state = { ai_target="target_player_radius", ai_move="move_complex", sense_radius=50, talent_in=1, },
	ai_tactic = resolvers.tactic"ranged",
	resolvers.inscriptions(4, "rune"),
	resolvers.inscriptions(1, {"manasurge rune"}),
}
