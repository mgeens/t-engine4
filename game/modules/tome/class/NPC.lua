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

require "engine.class"
local ActorAI = require "engine.interface.ActorAI"
local Faction = require "engine.Faction"
local Emote = require("engine.Emote")
require "mod.class.Actor"

module(..., package.seeall, class.inherit(mod.class.Actor, engine.interface.ActorAI))

function _M:init(t, no_default)
	mod.class.Actor.init(self, t, no_default)
	ActorAI.init(self, t)

	-- Grab default image name if none is set
	if not self.image then self.image = "npc/"..(self.type or "unknown").."_"..(self.subtype or "unknown").."_"..(self.name or "unknown"):lower():gsub("[^a-z0-9]", "_")..".png" end
end

function _M:act()
	while self:enoughEnergy() and not self.dead do
		-- Do basic actor stuff
		if not mod.class.Actor.act(self) then return end
		local old_energy = self.energy.value

		-- Compute FOV, if needed
		self:doFOV()

		-- Let the AI think .... beware of Shub !
		-- If AI did nothing, use energy anyway
		self:doAI()

		if self.emote_random and rng.percent(self.emote_random.chance) then
			self:doEmote(rng.table(self.emote_random))
		end

		if not self.energy.used then self:useEnergy() end
		if old_energy == self.energy.value then break end -- Prevent infinite loops
	end
end

function _M:doFOV()
--	if self.lite > 0 then
--	print("lite", self.name, self.lite)
--		self:computeFOV(self.lite, "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyLite(x, y) end, true, true)
--	end
	-- If the actor has no special vision we can use the default cache
	if not self.special_vision then
		self:computeFOV(self.sight or 10, "block_sight", nil, nil, nil, true)
	else
		self:computeFOV(self.sight or 10, "block_sight")
	end
end

--- Give target to others
function _M:seen_by(who)
	if self.ai_target.actor then return end
	if not who.ai_target then return end
	if not who.ai_target.actor then return end
	if self:reactionToward(who) < 0 then return end
	if not who:canSee(who.ai_target.actor) then return end
	self:setTarget(who.ai_target.actor)
end

--- Check if we are angered
-- @param src the angerer
-- @param set true if value is the finite value, false if it is an increment
-- @param value the value to add/subtract
function _M:checkAngered(src, set, value)
	if not src.resolveSource then return end
	if not src.faction then return end
	if self.never_anger then return end
	if self.summoner and self.summoner == src then return end

	-- Cant anger at our own faction unless it's the silly player
	if self.faction == src.faction and not src.player then return end

	local rsrc = src:resolveSource()
	local rid = rsrc.unique or rsrc.name
	if not self.reaction_actor then self.reaction_actor = {} end

	local was_hostile = self:reactionToward(src) < 0

	if not set then
		self.reaction_actor[rid] = util.bound((self.reaction_actor[rid] or 0) + value, -200, 200)
	else
		self.reaction_actor[rid] = util.bound(value, -200, 200)
	end

	if not was_hostile and self:reactionToward(src) < 0 then
		if self.anger_emote then
			self:doEmote(self.anger_emote:gsub("@himher@", src.female and "her" or "him"), 30)
		end
	end
end

--- Called by ActorLife interface
-- We use it to pass aggression values to the AIs
function _M:onTakeHit(value, src)
	if not self.ai_target.actor and src and src.targetable then
		self.ai_target.actor = src
	end

	-- Get angry if attacked by a friend
	if src and src ~= self and src.resolveSource and src.faction and self:reactionToward(src) >= 0 then
		self:checkAngered(src, false, -50)

		-- Call for help if we become hostile
		for i = 1, #self.fov.actors_dist do
			local act = self.fov.actors_dist[i]
			if act and act ~= self and self:reactionToward(act) > 0 and not act.dead and act.checkAngered then
				act:checkAngered(src, false, -50)
			end
		end
	end

	return mod.class.Actor.onTakeHit(self, value, src)
end

function _M:die(src)
	if src and Faction:get(self.faction) and Faction:get(self.faction).hostile_on_attack then
		Faction:setFactionReaction(self.faction, src.faction, Faction:factionReaction(self.faction, src.faction) - self.rank, true)
	end

	-- Get angry if attacked by a friend
	if src and src ~= self and src.resolveSource and src.faction then
		local rsrc = src:resolveSource()
		local rid = rsrc.unique or rsrc.name

		-- Call for help if we become hostile
		for i = 1, #self.fov.actors_dist do
			local act = self.fov.actors_dist[i]
			if act and act ~= self and act:reactionToward(rsrc) >= 0 and self:reactionToward(act) > 0 and not act.dead and act.checkAngered then
				act:checkAngered(src, false, -101)
			end
		end
	end

	-- Self resurrect, mouhaha!
	if self:attr("self_resurrect") then
		self:attr("self_resurrect", -1)
		game.logSeen(src, "#LIGHT_RED#%s rises from the dead!", self.name:capitalize()) -- src, not self as the source, to make sure the player knows his doom ;>
		local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
		game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, "RESURRECT!", {255,120,0})

		local effs = {}

		-- Go through all spell effects
		for eff_id, p in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			effs[#effs+1] = {"effect", eff_id}
		end

		-- Go through all sustained spells
		for tid, act in pairs(self.sustain_talents) do
			if act then
				effs[#effs+1] = {"talent", tid}
			end
		end

		while #effs > 0 do
			local eff = rng.tableRemove(effs)

			if eff[1] == "effect" then
				self:removeEffect(eff[2])
			else
				self:forceUseTalent(eff[2], {ignore_energy=true})
			end
		end
		self.life = self.max_life
		self.mana = self.max_mana
		self.stamina = self.max_stamina
		self.equilibrium = 0
		self.air = self.max_air

		self.dead = false
		self.died = (self.died or 0) + 1
		self:move(self.x, self.y, true)

		return
	end

	return mod.class.Actor.die(self, src)
end

function _M:tooltip(x, y, seen_by)
	local str = mod.class.Actor.tooltip(self, x, y, seen_by)
	if not str then return end
	local killed = game.player.all_kills and (game.player.all_kills[self.name] or 0) or 0

	str:add(
		true,
		("Killed by you: "):format(killed), true,
		"Target: ", self.ai_target.actor and self.ai_target.actor.name or "none", true,
		"UID: "..self.uid
	)
	return str
end

--- Make emotes appear in the log too
function _M:setEmote(e)
	game.logSeen(self, "%s says: '%s'", self.name:capitalize(), e.text)
	mod.class.Actor.setEmote(self, e)
end

--- Simple emote
function _M:doEmote(text, dur, color)
	self:setEmote(Emote.new(text, dur, color))
end
