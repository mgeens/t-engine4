-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
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

local reward = {
	all = {
		["technique/conditioning"] = true,
		["cunning/survival"] = true,
	},
	normal = {
		["spell/divination"] = true,
		["spell/staff-combat"] = true,
		["spell/stone-alchemy"] = true,
		["celestial/chants"] = true,
		["celestial/light"] = true,
		["chronomancy/chronomancy"] = true,
	},
	antimagic = {
		["wild-gift/call"] = true,
		["wild-gift/mindstar-mastery"] = true,
		["technique/mobility"] = true,
		["technique/field-control"] = true,
		["psionic/dreaming"] = true,
	},
}
local function generate_rewards()
	local answers = {}
	local what = game.player:attr("forbid_arcane") and reward.antimagic or reward.normal
	table.merge(what, reward.all)
	if what then
		for tt, mastery in pairs(what) do if game.player:knowTalentType(tt) == nil then
			local tt_def = game.player:getTalentTypeFrom(tt)
			local cat = tt_def.type:gsub("/.*", "")
			local doit = function(npc, player)
				player:learnTalentType(tt, true)
				player:setTalentTypeMastery(tt, math.max(0.9, player:getTalentTypeMastery(tt)))
			end
			answers[#answers+1] = {("[%s (at mastery %0.2f)]"):format(cat:capitalize().." / "..tt_def.name:capitalize(), 0.9),
				action=doit,
				on_select=function(npc, player)
					game.tooltip_x, game.tooltip_y = 1, 1
					game:tooltipDisplayAtMap(game.w, game.h, "#GOLD#"..(cat:capitalize().." / "..tt_def.name:capitalize()).."#LAST#\n"..tt_def.description)
				end,
			}
		end end
	end
	return answers
end

newChat{ id="welcome",
	text = [[Learn which category?]],
	answers = generate_rewards(),
}

return "welcome"
