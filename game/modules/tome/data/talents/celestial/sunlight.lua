-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2018 Nicolas Casalini
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

local DamageType = require "engine.DamageType"

newTalent{
	name = "Searing Light",
	type = {"celestial/sunlight", 1},
	require = divi_req1,
	random_ego = "attack",
	points = 5,
	cooldown = 5,
	positive = -10,
	range = 7,
	radius = 1,
	tactical = { ATTACK = {LIGHT = 2} },
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 17, 200) end,
	getDamageOnSpot = function(self, t) return self:combatTalentSpellDamage(t, 17, 200)/2 end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), radius=1, talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local dam = self:spellCrit(t.getDamage(self, t))
		self:project(tg, x, y, DamageType.LIGHT, dam, {type="light"})

		local _ _, x, y = self:canProject(tg, x, y)
		-- Add a lasting map effect
		game.level.map:addEffect(self,
			x, y, 4,
			DamageType.LIGHT, dam / 2,
			1,
			5, nil,
			{type="light_zone"},
			nil, self:spellFriendlyFire()
		)

		game:playSoundNear(self, "talents/flame")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local damageonspot = t.getDamageOnSpot(self, t)
		return ([[Calls the power of the Sun into a searing lance, doing %d damage to the target and leaving a spot on the ground for 4 turns that does %d light damage to anyone within it.
		The damage dealt will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, damage), damDesc(self, DamageType.LIGHT, damageonspot))
	end,
}

newTalent{
	name = "Sun Flare",
	type = {"celestial/sunlight", 2},
	require = divi_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	positive = -15,
	tactical = { DISABLE = 2,
		ATTACKAREA = function(self, t, aitarget)
			if self:getTalentLevel(t) >= 3 then return {light = 1} end
		end, },
	direct_hit = true,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 2.5, 4.5)) end,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t), talent=t}
	end,
	requires_target = true,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 10, 120) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		-- Temporarily turn on "friendlyfire" to lite all tiles
		tg.selffire = true
		tg.radius = tg.radius * 2
		self:project(tg, self.x, self.y, DamageType.LITE, 1)
		tg.radius = tg.radius / 2
		tg.selffire = false
		local grids = self:project(tg, self.x, self.y, DamageType.BLIND, t.getDuration(self, t))
		if self:getTalentLevel(t) >= 3 then
			self:project(tg, self.x, self.y, DamageType.LIGHT, t.getDamage(self, t))
		end
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "sunburst", {radius=tg.radius, grids=grids, tx=self.x, ty=self.y, max_alpha=80})
		game:playSoundNear(self, "talents/flame")
		return true
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		local damage = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		return ([[Invokes the Sun to cause a flare within radius %d, blinding your foes for %d turns and lighting up your immediate area (radius %d).
		At level 3 it will also do %0.2f light damage within radius %d.
		The damage done will increase with your Spellpower.]]):
		format(radius, duration, radius * 2, damDesc(self, DamageType.LIGHT, damage), radius)
   end,
}

newTalent{
	name = "Firebeam",
	type = {"celestial/sunlight",3},
	require = divi_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	positive = 10,
	tactical = { ATTACK = {FIRE = 2}  },
	range = 7,
	direct_hit = true,
	requires_target = true,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 16, 200) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local dam = self:spellCrit(t.getDamage(self, t))
		self:project(tg, x, y, DamageType.LIGHT, dam)
		self:project(tg, x, y, DamageType.FIREBURN, {dam=dam/2, dur=3, initial=0})
		local _ _, x, y = self:canProject(tg, x, y)
		game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "light_beam", {tx=x-self.x, ty=y-self.y})

		game:playSoundNear(self, "talents/flame")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Call forth the Sun to summon a fiery beam, dealing %d light damage and burning all targets in a line for %d fire damage over 3 turns.
		The damage done will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, damage), damDesc(self, DamageType.FIRE, damage/2))
	end,
}

newTalent{
	name = "Sunburst",
	type = {"celestial/sunlight", 4},
	require = divi_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 15,
	positive = 20,
	tactical = { ATTACKAREA = {LIGHT = 2} },
	range = 7,
	direct_hit = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=7, friendlyfire=false, talent=t}
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 10, 120) end,
	getDuration = function(self, t) return 6 end,
	getPower = function(self, t) return self:combatTalentLimit(t, 1, 0.2, 0.7) end,
	getTargetCount = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5)) end,
	action = function(self, t)
		local damInc = (self.inc_damage.DARKNESS or 0) * t.getPower(self, t)
		self:setEffect(self.EFF_SUNBURST, t.getDuration(self, t), {damInc=damInc})

		--do cool lasers
		local tgts = {}
		local grids = core.fov.circle_grids(self.x, self.y, self:getTalentRange(t), true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) < 0 then
				tgts[#tgts+1] = a
			end
		end end

		if #tgts <= 0 then return true end

		local dam = self:spellCrit(t.getDamage(self, t))

		-- Randomly take targets
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		for i = 1, t.getTargetCount(self, t) do
			if #tgts <= 0 then break end
			local a, id = rng.table(tgts)
			table.remove(tgts, id)

			self:project(tg, a.x, a.y, DamageType.LIGHT, dam)
			self:project(tg, a.x, a.y, DamageType.FIREBURN, {dam=dam/2, dur=3, initial=0})
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(a.x-self.x), math.abs(a.y-self.y)), "light_beam", {tx=a.x-self.x, ty=a.y-self.y})

			game:playSoundNear(self, "talents/spell_generic")
		end

		return true
	end,
	info = function(self, t)
		return ([[Release a furious burst of sunlight, increasing your bonus light damage by %d%% of your bonus darkness damage for %d turns and dealing %d light damage to %d foes in radius %d, setting them ablaze for %d fire damage over 3 turns.]]):format(t.getPower(self, t)*100, t.getDuration(self, t), damDesc(self, DamageType.LIGHT, t.getDamage(self, t)), t.getTargetCount(self, t), self:getTalentRange(t), damDesc(self, DamageType.FIRE, t.getDamage(self, t)/2))
	end,
}
