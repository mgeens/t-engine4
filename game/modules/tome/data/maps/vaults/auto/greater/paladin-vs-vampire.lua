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

--paladins vs. vampires!

local Talents = require("engine.interface.ActorTalents")
setStatusAll{no_teleport=true}

roomCheck(function(room, zone, level, map)
	return resolvers.current_level >= 25 and zone.npc_list.__loaded_files["/data/general/npcs/vampire.lua"] and zone.npc_list.__loaded_files["/data/general/npcs/ghoul.lua"] and zone.npc_list.__loaded_files["/data/general/npcs/wight.lua"]
end)
specialList("actor", {
	"/data/general/npcs/vampire.lua",
	"/data/general/npcs/wight.lua",
}, true)
defineTile('~', mod.class.Grid.new{
	define_as = "NECRO",
	name = "corrupted lava floor", image = "terrain/lava_floor.png",
	display = '.', color=colors.RED, back_color=colors.DARK_GREY,
	shader = "lava",
	mindam = resolvers.mbonus(5, 15),
	maxdam = resolvers.mbonus(10, 30),
	on_stand = function(self, x, y, who)
		local DT = engine.DamageType
		local dam = DT:get(DT.RETCH).projector(self, x, y, DT.RETCH, rng.range(self.mindam, self.maxdam))
		self.x, self.y = x, y
		if who.player and not who:attr("undead") then self:logCombat(who, "#Source# emits dark energies at your feet.") end
		if who.dead and not who:attr("undead") then
			--add undead
			local m = game.zone:makeEntityByName(game.level, "actor", "RISEN_CORPSE")
			game.zone:addEntity(game.level, m, "actor", x, y)
			game.logSeen(m, "The corrupted lava reanimates %s's corpse!", who.name:capitalize())
		end
	end,
})

defineTile('S', "FLOOR", nil, mod.class.NPC.new{
	type = "humanoid", subtype = "human",
	display = "p", color=colors.GOLD,
	name = "human sun-paladin",
	faction = "sunwall", hard_faction = "sunwall",
	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	desc = [[A Human in shining plate armour.]],
	level_range = {10, nil}, exp_worth = 1,
	rank = 2,
	size_category = 3,
	autolevel = "warriormage",
	ai = "dumb_talented_simple", ai_state = { talent_in=3, },
	stats = { str=12, dex=8, mag=6, con=10 },
	positive_regen = 10,
	max_life = resolvers.rngavg(140,170),
	combat_armor = 10, combat_def = 10,
	resolvers.equip{
		{type="weapon", subtype="mace", autoreq=true},
		{type="armor", subtype="shield", autoreq=true},
		{type="armor", subtype="massive", autoreq=true},
	},
	resolvers.talents{
		[Talents.T_ARMOUR_TRAINING]={base = 3, every = 4, max = 10},
		[Talents.T_CHANT_OF_FORTRESS]={base = 1, every = 6, max = 5},
		[Talents.T_SEARING_LIGHT]={base = 1, every = 5, max = 5},
		[Talents.T_MARTYRDOM]={base=2, every= 7, max = 5},
		[Talents.T_WEAPON_OF_LIGHT]={base = 1, every = 5, max = 5},
		[Talents.T_FIREBEAM]={base = 5, every = 7, max = 5},
		[Talents.T_WEAPON_COMBAT]={base = 4, every = 7, max = 5},
		[Talents.T_HEALING_LIGHT]={base = 2, every = 7, max = 5},
	},
	on_added = function(self)
		self.energy.value = game.energy_to_act self:useTalent(self.T_WEAPON_OF_LIGHT)
		self.energy.value = game.energy_to_act self:useTalent(self.T_CHANT_OF_FORTRESS)
	end,
}
)

defineTile('.', "FLOOR")
defineTile('!', "DOOR_VAULT", nil, nil, nil, {room_map={special=false, room=false, can_open=true}})
defineTile('+', "DOOR")
defineTile('X', "HARDWALL")
defineTile('v', "FLOOR", {random_filter={add_levels=5,tome_mod="vault"}}, {random_filter={add_levels=5, type="undead", subtype="vampire", name="vampire"}})
defineTile('U', "FLOOR", {random_filter={add_levels=10, tome_mod="gvault"}}, {random_filter={add_levels=10, type="undead", subtype="vampire", name="master vampire"}})
defineTile('V', "FLOOR", {random_filter={add_levels=15, tome_mod="gvault"}}, {random_filter={add_levels=15, type="undead", subtype="vampire", name="elder vampire"}})
defineTile('L', "FLOOR", {random_filter={add_levels=20, tome_mod="gvault"}}, {random_filter={add_levels=20, type="undead", subtype="vampire", name="vampire lord"}})
defineTile('W', "FLOOR", {random_filter={add_levels=15, tome_mod="gvault"}}, {random_filter={add_levels=15, type="undead", subtype="wight", name="grave wight"}})
startx = 0
starty = 7

rotates = {"default", "90", "180", "270", "flipx", "flipy"}

return {
[[XXXXXXXXXXXXXXXXXXXXXXXXXXXXX]],
[[X....X......................X]],
[[X....X..~.~..v~..~.V........X]],
[[X....X....~..~.~..~..XXXXX..X]],
[[X....X..~.v.~...~...XXXXXX..X]],
[[X..S.X..~.~~.v~.~..XXXXXXX..X]],
[[X..S.+.~..~..~....LXXXXXXX..X]],
[[!....+.~.~.~.v.~...XXXXXXX..X]],
[[X..S.+..~..~.~.v.~..XXXXXX..X]],
[[X..S.X...~..~..~..~..XXXXX..X]],
[[X....X.~.~.~......~..W......X]],
[[X....X.......~.~..V.........X]],
[[XXXXXXXXXXXXXXXXXXXXXXXXXXXXX]],
}