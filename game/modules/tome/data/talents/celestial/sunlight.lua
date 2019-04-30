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
	cooldown = 4,
	positive = -16,
	range = 7,
	tactical = { ATTACK = {LIGHT = 2} },
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 6, 160) end,
	getDamageOnSpot = function(self, t) return self:combatTalentSpellDamage(t, 6, 80) end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.LIGHT, self:spellCrit(t.getDamage(self, t)), {type="light"})

		local _ _, x, y = self:canProject(tg, x, y)
		-- Add a lasting map effect
		game.level.map:addEffect(self,
			x, y, 4,
			DamageType.LIGHT, t.getDamageOnSpot(self, t),
			0,
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
		return ([[Calls the power of the Sun into a searing lance, doing %0.2f damage to the target and leaving a spot on the ground for 4 turns that does %0.2f light damage to anyone within it.
		The damage dealt will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, damage), damageonspot)
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
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 4, 80) end,
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
	cooldown = 5,
	positive = 15,
	tactical = { ATTACK = {FIRE = 2}  },
	range = 7,
	direct_hit = true,
	requires_target = true,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 10, 200) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local dam = self:spellCrit(t.getDamage(self, t))
		self:project(tg, x, y, DamageType.LIGHT, dam)
		self:project(tg, x, y, DamageType.FIREBURN, dam, {initial=0})
		local _ _, x, y = self:canProject(tg, x, y)
		game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "light_beam", {tx=x-self.x, ty=y-self.y})

		game:playSoundNear(self, "talents/flame")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Call forth the Sun to summon a fiery beam, dealing %d light damage and burning all targets in a line for %d fire damage over 3 turns.
		The damage done will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, damage), damDesc(self, DamageType.FIRE, damage))
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
	range = 0,
	radius = 6,
	direct_hit = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), friendlyfire=false, talent=t}
	end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 10, 200) end,
	getDuration = function(self, t) return 6 end,
	getPower = function(self, t) return self:combatTalentLimit(t, 1.5, 0.3, 1) end,
	action = function(self, t)
		local damVal = math.max(self.inc_damage.LIGHT, self.inc_damage.DARKNESS * t.getPower(self, t))
		local damInc = damVal - self.inc_damage.LIGHT
		local penVal = math.max(self.resists_pen.LIGHT, self.resists_pen.DARKNESS * t.getPower(self, t))
		local penInc = penVal - self.resists_pen.LIGHT
		self:setEffect(EFF_SUNBURST, t.getDuration(self, t), {damVal=damVal, damInc=damInc, penVal=penVal, penInc=penInc}) --all these params for eff tt

		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end

			DamageType:get(DamageType.LIGHT).projector(self, px, py, DamageType.LIGHT, self:spellCrit(t.getDamage(self, t)))
		end)
		return true
	end,
	info = function(self, t)
		return ([[Release a furious burst of sunlight, setting your light damage and penetration to %d%% of your darkness damage and penetration for %d turns, if doing so would increase their values.
		The burst of sunlight will deal %d light damage to all within radius %d.]]):format(t.getPower(self, t)*100, t.getDuration(self, t), damDesc(self, DamageType.LIGHT, t.getDamage(self, t)), self:getTalentRadius(t))
	end,
}
