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

local Talents = require"engine.interface.ActorTalents"

newEntity{ define_as = "TRAP_ALARM",
	type = "annoy", subtype="alarm", id_by_type=true, unided_name = "trap",
	display = '^',
	triggered = function() end,
}

newEntity{ base = "TRAP_ALARM",
	name = "intruder alarm", auto_id = true, image = "trap/trap_intruder_alarm_01.png",
	detect_power = resolvers.clscale(26,25,8,0.5),
	disarm_power = resolvers.clscale(30,25,8,0.5),
	rarity = 3, level_range = {1, 50},
	color=colors.UMBER,
	message = "@Target@ triggers an alarm!",
	unided_name = "pressure plate",
	desc = function(self) return ("Makes noise, alerting others.") end,
	pressure_trap = true,
	triggered = function(self, x, y, who)
		for i = x - 20, x + 20 do for j = y - 20, y + 20 do if game.level.map:isBound(i, j) then
			local actor = game.level.map(i, j, game.level.map.ACTOR)
			if actor and not actor.player then
				if who:reactionToward(actor) > 0 then
					local tx, ty, a = who:getTarget()
					if a then
						actor:setTarget(a)
					end
				elseif who:reactionToward(actor) < 0 then
					actor:setTarget(who)
				end
			end
		end end end
		return true, true
	end
}

newEntity{ base = "TRAP_ALARM",
	name = "summoning alarm", auto_id = true, image = "trap/trap_summoning_alarm_01.png",
	detect_power = resolvers.clscale(30,25,8,0.5),
	disarm_power = resolvers.clscale(46,25,8,0.5),
	rarity = 3, level_range = {10, 50},
	color=colors.DARK_UMBER,
	nb_summon = resolvers.mbonus(3, 2),
	message = "An alarm rings!",
	unided_name = "ring of faded sigils",
	desc = function(self) return ("Summons creatures.") end,
	unlock_talent_on_disarm = {tid=Talents.T_AMBUSH_TRAP, chance=8},
	triggered = function(self, sx, sy, who)
		for i = 1, self.nb_summon do
			-- Find space
			local x, y = util.findFreeGrid(sx, sy, 10, true, {[game.level.map.ACTOR]=true})
			if not x then
				break
			end

			-- Find an actor with that filter
			local m = game.zone:makeEntity(game.level, "actor")
			if m then
				game.zone:addEntity(game.level, m, "actor", x, y)
				m:setTarget(who)
				game.logSeen(m, "%s appears out of the thin air!", m.name:capitalize())
			end
		end
		return true, true
	end
}
