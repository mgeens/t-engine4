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

local Level = require "engine.Level"
local Object = require "engine.Object"
local Map = require "engine.Map"

newTalent{
	name = "Predator",
	type = {"cursed/predator", 1},
	require = cursed_lev_req1,
	mode = "passive",
	points = 5,
	getATK = function(self, t) return self:combatTalentScale(t, 0.5, 2) end,
	-- ATK bonus handled in Combat.lua with comment: -- Predator apr bonus
	getAPR = function(self, t) return self:combatTalentScale(t, 0.25, 1) end,
	-- APR bonus handled in Combat.lua with comment: -- Predator apr bonus
	getTypeKillMax = function(self, t) return math.floor(self:combatTalentLimit(t, 40, 10, 30)) end,
	callbackOnKill = function(self, t, target)
		local killmax = t.getTypeKillMax(self, t)
		local type = target.type
		-- Make a table with key/value pair == type/count
		self.pred_type_tbl = self.pred_type_tbl or {}
		self.pred_type_tbl[type] = self.pred_type_tbl[type] or 0
		self.pred_type_tbl[type] = math.min(self.pred_type_tbl[type] + 1, killmax)
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted)
		-- Let NPCs use this with type/count generated the first time they attack that type
		if not self == game.player and target and target.type then
			self.pred_type_tbl = self.pred_type_tbl or {}
			local type = target.type
			if not self.pred_type_tbl[type] then
				local killmax = t.getTypeKillMax(self, t)
				local killfloor = math.floor(rank^2)
				self.pred_type_tbl[type] = rng.range(killfloor, killmax)
			end
		end
		-- Hate gain for early game
		if hitted and target then
			local killmax = t.getTypeKillMax(self, t)
			if target.type and self.pred_type_tbl and self.pred_type_tbl[target.type] and self.pred_type_tbl[target.type] >= killmax then return
			else self:incHate(1) end
		end
	end,
	info = function(self, t)
		return ([[Improve your predation by learning from past hunts. You gain %0.2f accuracy and %0.2f armor penetration against foes for each foe of that type you have previously slain, up to %d of the type killed (%d accuracy and %d apr).
		Additionally, you will gain 1 hate every time you attack a foe of a type you have killed less than %d of.]]):format(t.getATK(self, t), t.getAPR(self, t), t.getTypeKillMax(self, t), t.getATK(self, t) * t.getTypeKillMax(self, t), t.getAPR(self, t) * t.getTypeKillMax(self, t), t.getTypeKillMax(self, t))
	end,
}

newTalent{
	name = "Savage Hunter",
	type = {"cursed/predator", 2},
	mode = "sustained",
	require = cursed_lev_req2,
	points = 5,
	cooldown = 10,
	radius = function(self, t) return 4 end,
	getMiasmaCount = function(self, t) return self:combatTalentScale(t, 4, 7) end,
	getDamage = function(self, t) return self:combatTalentMindDamage(t, 0, 60) end,
	getChance = function(self, t) return self:combatTalentScale(t, 5, 15) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "pierce_cursed_miasma", 10)
	end,
	canCreep = function(x, y, ignoreCreepingDark)
		-- not on map
		if not game.level.map:isBound(x, y) then return false end
		 -- already dark
		 if not ignoreCreepingDark then
			if game.level.map:checkAllEntities(x, y, "cursedMiasma") then return false end
		end
		 -- allow objects and terrain to block, but not actors
		if game.level.map:checkAllEntities(x, y, "block_move") and not game.level.map(x, y, Map.ACTOR) then return false end

		return true
	end,
	doCreep = function(tCreepingDarkness, self, useCreep)
		local start = rng.range(0, 8)
		for i = start, start + 8 do
			local x = self.x + (i % 3) - 1
			local y = self.y + math.floor((i % 9) / 3) - 1
			if not (x == self.x and y == self.y) and tCreepingDarkness.canCreep(x, y) then
				-- add new dark
				local newCreep
				if useCreep then
					 -- transfer some of our creep to the new dark
					newCreep = self.creep --math.ceil(self.creep / 2)
					--self.creep = self.creep - 1
				else
					-- just clone our creep
					newCreep = self.creep
				end
				tCreepingDarkness.createDark(self.summoner, x, y, self.damage, self.duration, newCreep, self.creepChance, 0)
				return true
			end

			-- nowhere to creep
			return false
		end
	end,
	createDark = function(summoner, x, y, damage, duration, creep, creepChance, initialCreep)
		local e = Object.new{
			name = summoner.name:capitalize() .. "'s cursed miasma",
			block_sight=function(self, x, y, who)
				if who and who.attr and who:attr("pierce_cursed_miasma") and x and who.x and core.fov.distance(x, y, who.x, who.y) <= 10 then
					return false
				end
				return true
			end,
			canAct = false,
			canCreep = true,
			x = x, y = y,
			damage = damage,
			originalDuration = duration,
			duration = duration,
			creep = creep,
			creepChance = creepChance,
			summoner = summoner,
			summoner_gain_exp = true,
			act = function(self)
				local Map = require "engine.Map"

				self:useEnergy()

				-- apply damage to anything inside the darkness
				local actor = game.level.map(self.x, self.y, Map.ACTOR)
				if actor then
					self.summoner:project({type="hit", range=10, talent=self.summoner:getTalentFromId(self.summoner.T_SAVAGE_HUNTER)}, actor.x, actor.y, engine.DamageType.CURSED_MIASMA, self.damage)
				end

				if self.duration <= 0 then
					-- remove
					if self.particles then game.level.map:removeParticleEmitter(self.particles) end
					game.level.map:remove(self.x, self.y, Map.TERRAIN+3)
					game.level:removeEntity(self, true)
					self.cursedMiasma = nil
					game.level.map:scheduleRedisplay()
				else
					self.duration = self.duration - 1

					local tCreepingDarkness = self.summoner:getTalentFromId(self.summoner.T_SAVAGE_HUNTER)

					if self.canCreep and self.creep > 0 and rng.percent(self.creepChance) then
						if not tCreepingDarkness.doCreep(tCreepingDarkness, self, true) then
							-- doCreep failed..pass creep on to a neighbor and stop creeping
							self.canCreep = false
							local start = rng.range(0, 8)
							for i = start, start + 8 do
								local x = self.x + (i % 3) - 1
								local y = self.y + math.floor((i % 9) / 3) - 1
								if not (x == self.x and y == self.y) and tCreepingDarkness.canCreep(x, y) then
									local dark = game.level.map:checkAllEntities(x, y, "cursedMiasma")
									if dark and dark.canCreep then
										-- transfer creep
										dark.creep = dark.creep + self.creep
										tCreepingDarkness.doCreep(tCreepingDarkness, dark, true)
										self.creep = 0
										return
									end
								end
							end
						end
					end
				end
			end,
		}
		e.cursedMiasma = e -- used for checkAllEntities to return the cursed miamsa Object itself
		game.level:addEntity(e)
		game.level.map(x, y, Map.TERRAIN+3, e)

		-- add particles
		e.particles = Particles.new("cursed_miasma", 1, {is_ascii = config.settings.tome.gfx.tiles == "ascii" or config.settings.tome.gfx.tiles == "ascii_full"})
		e.particles.x = x
		e.particles.y = y
		game.level.map:addParticleEmitter(e.particles)

		-- do some initial creeping
		if initialCreep > 0 then
			local tCreepingDarkness = summoner:getTalentFromId(summoner.T_SAVAGE_HUNTER)
			while initialCreep > 0 do
				if not tCreepingDarkness.doCreep(tCreepingDarkness, e, false) then
					e.canCreep = false
					e.initialCreep = 0
					break
				end
				initialCreep = initialCreep - 1
			end
		end
	end,

	activate = function(self, t)
		local ret = {}
		return ret
	end,
	deactivate = function(self, t)
		return true
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, critted)
		if hitted and critted and not (self.x and self.y and game.level.map:checkAllEntities(self.x, self.y, "cursedMiasma")) then
			local miasma_count = 0
			local damage = self:mindCrit(t.getDamage(self, t))
			local x, y = self.x, self.y
			if t.canCreep(x, y) then t.createDark(self, x, y, damage, rng.range(7,9), 8, 100, 0) miasma_count=1 end
			local locations = {}
			local grids = core.fov.circle_grids(x, y, 4, true)
			for darkX, yy in pairs(grids) do for darkY, _ in pairs(grids[darkX]) do
				local l = line.new(x, y, darkX, darkY)
				local lx, ly = l()
				while lx and ly do
					if game.level.map:checkAllEntities(lx, ly, "block_move") and not game.level.map(x, y, Map.ACTOR) then break end

					lx, ly = l()
				end
				if not lx and not ly then lx, ly = darkX, darkY end

				if lx == darkX and ly == darkY and t.canCreep(darkX, darkY) then
					locations[#locations+1] = {darkX, darkY}
				end
			end end

			repeat
				if #locations <= 0 then break end
				local location, id = rng.table(locations)
				table.remove(locations, id)
				if t.canCreep(location[1], location[2]) then
					t.createDark(self, location[1], location[2], damage, rng.range(7,9), 8, 100, 0)
					miasma_count = miasma_count + 1
				end
			until miasma_count >= t.getMiasmaCount(self, t)
		end
	end,
	info = function(self, t)
		return ([[Upon making a critical melee attack the savagery of your predation causes a cursed miasma begins to permeate your hunting grounds.
		The miasma will seep from %d locations, including your own, within radius %d, deals %d damage and blocks sight.
		Prey lost within your miasma have a %d%% chance to lose track of you and may mistake friends for foe.]]):format(t.getMiasmaCount(self, t), self:getTalentRadius(t), self:damDesc(DamageType.DARKNESS, t.getDamage(self, t)), t.getChance(self, t))
	end,
}

newTalent{
	name = "Shrouded Hunter",
	type = {"cursed/predator", 3},
	mode = "passive",
	require = cursed_lev_req2,
	points = 5,
	getStealthPower = function(self, t) return self:combatTalentMindDamage(t, 0, 80) end,
	getCritResist = function(self, t) return self:combatTalentScale(t, 0, 20) end,
	passives = function(self, t, p)
		if self.x and self.y and game.level.map:checkAllEntities(self.x, self.y, "cursedMiasma") then
			self:talentTemporaryValue(p, "ignore_direct_crits", t.getCritResist(self, t))
			self:talentTemporaryValue(p, "stealth", t.getStealthPower(self, t))
			if self.updateMainShader then self:updateMainShader() end
		end
	end,
	callbackOnActEnd = function(self, t)
		self:updateTalentPassives(t.id)
	end,
	info = function(self, t)
		return ([[While shrouded in cursed miasma you gain stealth (%d power) and %d%% chance to shrug off critical hits.]]):format(t.getStealthPower(self, t), t.getCritResist(self, t))
	end,
}

newTalent{
	name = "Mark Prey",
	type = {"cursed/predator", 4},
	mode = "passive",
	require = cursed_lev_req4,
	points = 5,
	no_npc_use = true,
	getPower = function(self, t) return self:combatTalentScale(t, 5, 15) end, --damage reduction handled in damage-types.lua
	getCount = function(self, t) return math.floor(1 + self:getTalentLevel(t) / 2) end, --vision handled in player.lua
	callbackOnChangeLevel = function(self, t)
		if self:hasEffect(self.EFF_PREDATOR) then self:removeEffect(self.EFF_PREDATOR) end
		if not self.mark_prey then self.mark_prey = {} end
		if not self.mark_prey[game.level.id] then
			self.mark_prey[game.level.id] = {}
			local marks = {}
			for __, e in pairs(game.level.entities) do
				if e.rank >= 3.2 and self:reactionToward(e) < 0 then
					marks[#marks+1] = {e=e, rank=e.rank, subtype=e.subtype}
				end
			end
			if #marks > 0 then table.sort(marks, "rank") else return end
			for i = 1, t.getCount(self, t) do
				if #marks > 0 then
					self.mark_prey[game.level.id][i] = marks[#marks].e
					table.remove(marks)
				else break
				end
			end
		end
		local power = t.getPower(self, t)
		self:setEffect(self.EFF_PREDATOR, 1, {power=power, count=t.getCount(self, t)})
	end,
	info = function(self, t)
		return([[Focus your predation on the most worthy prey. Upon entering a level for the first time, up to %d foes are marked as your prey. You gain vision of them, wherever they are. Additionally, all damage you receive from their subtype is reduced by %d%%.]]):format(t.getCount(self, t), t.getPower(self, t))
	end,
}
