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

newTalent{
	name = "Illuminate",
	type = {"spell/phantasm",1},
	require = spells_req1,
	random_ego = "utility",
	points = 5,
	mana = 5,
	cooldown = 14,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end,
	tactical = { DISABLE = function(self, t, aitarget)
			if self:getTalentLevel(t) >= 3 and not aitarget:attr("blind") then
				return 2
			end
			return 0
		end,
		ATTACKAREA = function(self, t)
			if self:getTalentLevel(t) >= 4 then
				return { LIGHT = 2 }
			end
			return 0
		end,
	},
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 28, 180) end,
	getBlindPower = function(self, t) if self:getTalentLevel(t) >= 5 then return 4 else return 3 end end,
	requires_target = true,
	target = function(self, t) return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t), talent=t} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "sunburst", {radius=tg.radius, grids=grids, tx=self.x, ty=self.y, max_alpha=80})
		if self:getTalentLevel(t) >= 3 then
			self:project(tg, self.x, self.y, DamageType.BLIND, t.getBlindPower(self, t))
		end
		if self:getTalentLevel(t) >= 4 then
			self:project(tg, self.x, self.y, DamageType.LIGHT, self:spellCrit(t.getDamage(self, t)))
		end
		tg.selffire = true
		self:project(tg, self.x, self.y, DamageType.LITE, 1)
		game:playSoundNear(self, "talents/heal")
		return true
	end,
	info = function(self, t)
		local radius = self:getTalentRadius(t)
		local turn = t.getBlindPower(self, t)
		local dam = t.getDamage(self, t)
		return ([[Creates a globe of pure light within a radius of %d that illuminates the area.
		At level 3, it also blinds all who see it (except the caster) for %d turns.
		At level 4, it also deals %0.2f light damage.]]):
		format(radius, turn, damDesc(self, DamageType.LIGHT, dam))
	end,
}

newTalent{
	name = "Blur Sight",
	type = {"spell/phantasm", 2},
	mode = "sustained",
	require = spells_req2,
	points = 5,
	sustain_mana = 30,
	cooldown = 10,
	tactical = { BUFF = 2 },
	getDefense = function(self, t) return self:combatScale(self:getTalentLevel(t)*self:combatSpellpower(), 0, 0, 28.6, 267, 0.75) end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/heal")
		return {
			particle = self:addParticles(Particles.new("phantasm_shield", 1)),
			def = self:addTemporaryValue("combat_def", t.getDefense(self, t)),
		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("combat_def", p.def)
		return true
	end,
	info = function(self, t)
		local defence = t.getDefense(self, t)
		return ([[The caster's image blurs, granting a %d bonus to Defense.
		The bonus will increase with your Spellpower.]]):
		format(defence)
	end,
}

newTalent{
	name = "Phantasmal Shield",
	type = {"spell/phantasm", 3},
	mode = "sustained",
	require = spells_req3,
	points = 5,
	sustain_mana = 20,
	cooldown = 10,
	tactical = { BUFF = 2 },
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 1, 80) end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/heal")
		return {
			particle = self:addParticles(Particles.new("phantasm_shield", 1)),
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHT]=t.getDamage(self, t)}),
			evasion = self:addTemporaryValue("evasion", 10),

		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("evasion", p.evasion)

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[The caster is surrounded by a phantasmal shield granting 10%% chance to evade weapon attacks. If hit in melee, the shield will deal %d light damage to the attacker.
		The damage will increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, damage))
	end,
}

newTalent{
	name = "Invisibility",
	type = {"spell/phantasm", 4},
	mode = "sustained",
	require = spells_req4,
	points = 5,
	sustain_mana = 150,
	cooldown = 30,
	tactical = { ESCAPE = 2, DEFEND = 2 },
	getInvisibilityPower = function(self, t) return self:combatTalentSpellDamage(t, 10, 50) end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/heal")
		local ret = {
			invisible = self:addTemporaryValue("invisible", t.getInvisibilityPower(self, t)),
			invisible_damage_penalty = self:addTemporaryValue("invisible_damage_penalty", 0.7),
			drain = self:addTemporaryValue("mana_regen", -2),
		}
		if not self.shader then
			ret.set_shader = true
			self.shader = "invis_edge"
			self:removeAllMOs()
			game.level.map:updateMap(self.x, self.y)
		end
		self:resetCanSeeCacheOf()
		return ret
	end,
	deactivate = function(self, t, p)
		if p.set_shader then
			self.shader = nil
			self:removeAllMOs()
			game.level.map:updateMap(self.x, self.y)
		end
		self:removeTemporaryValue("invisible", p.invisible)
		self:removeTemporaryValue("invisible_damage_penalty", p.invisible_damage_penalty)
		self:removeTemporaryValue("mana_regen", p.drain)
		self:resetCanSeeCacheOf()
		return true
	end,
	info = function(self, t)
		local invisi = t.getInvisibilityPower(self, t)
		return ([[The caster fades from sight, granting %d bonus to invisibility.
		Beware -- you should take off your light, or you will still be easily spotted.
		As you become invisible, you fade out of phase with reality. All your damage is reduced by 70%%.
		This powerful spell constantly drains your mana (2 per turn) while active.
		The invisibility bonus will increase with your Spellpower.]]):
		format(invisi)
	end,
}
