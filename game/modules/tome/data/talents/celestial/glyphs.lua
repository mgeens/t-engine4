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

local Trap = require "mod.class.Trap"

newTalent{
	name = "Glyphs",
	type = {"celestial/glyphs", 1},
	require = divi_req_high1,
	random_ego = "attack",
	points = 5,
	mode = "sustained",
	sustain_positive = 5,
	sustain_negative = 5,
	range = function(self, t) return 7 end,
	radius = function(self, t) return 1 end,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t} end,
	trapPower = function(self, t) return math.max(1,self:combatScale(self:getTalentLevel(t) * self:getMag(15, true), 0, 0, 75, 75)) end,
	getGlyphCD = function(self, t) return 20 - self:combatTalentLimit(t, 15, 1, 13) end,
	getDuration = function(self, t)
		if self:knowTalent(self.T_PERSISTENT_GLYPHS) then
			local pg = self:getTalentFromId(self.T_PERSISTENT_GLYPHS)
			return self:combatTalentLimit(t, 6, 2, 5) + pg.getPersistentDuration(self, pg)
		else
			return self:combatTalentLimit(t, 6, 2, 5)
		end
	end,
	getGlyphDam = function(self, t)
		if self:knowTalent(self.T_GLYPHS_OF_FURY) then
			local pg = self:getTalentFromId(self.T_GLYPHS_OF_FURY)
			return pg.getTriggerDam(self, pg)
		else
			return 0
		end
	end,
	getBlindDur = function(self, t) return self:combatTalentLimit(t, 7, 1, 4.5) end,
	getFatigueDur = function(self, t) return self:combatTalentLimit(t, 14, 1, 8) end,
	getFatigueDam = function(self, t) return self:combatTalentSpellDamage(t, 1, 80) end,
	getKnockBack = function(self, t) return self:combatTalentLimit(t, 10, 1, 6) end,
	on_crit = function(self, t)
		if self:getPositive() < 5 or self:getNegative() < 5 then return nil end
		if self.turn_procs.glyphs then return nil end
-- find a target
		local tgts = {}
		local grids = core.fov.circle_grids(self.x, self.y, self:getTalentRange(t), true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) < 0 then
				tgts[#tgts+1] = a
			end
		end end
		if #tgts < 1 then return nil end
--target glyphs
		local tg = self:getTalentTarget(t)
		local target = rng.tableRemove(tgts)
		local glyphgrids = {}
		if not self:canProject(tg, target.x, target.y) then return end
		self:project(tg, target.x, target.y, function(px, py)
			if not ((px == x and py == y) or game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move") or game.level.map(px, py, Map.TRAP)) then glyphgrids[#glyphgrids+1] = {x=px, y=py} end
		end)
		self.turn_procs.glyphs = 1 --as late as possible, but before any crits to prevent stack overflow
		local dam = self:spellCrit(t.getGlyphDam(self, t))
		local blindDur = t.getBlindDur(self, t)
		local fatigueDur = t.getFatigueDur(self, t)
		local fatigueDam = self:spellCrit(t.getFatigueDam(self, t))
		local dist = t.getKnockBack(self, t)

----------------------------------------------------------------
-- START - Define Glyph Traps - START
----------------------------------------------------------------
para_glyph = Trap.new{
	name = "glyph of sunlight",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_explosion_02_64.png",
	faction = self.faction,
	dam = dam,
	blindDur = blindDur,
	desc = function(self)
		return ([[Deals %d light damage and blinds for %d turns.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam), self.blindDur)
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
		if self.dam then
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.LIGHT, self.dam, {type="light"})
		end
		if who:canBe("blind") then
			who:setEffect(who.EFF_BLINDED, self.blindDur, {})
		end
		game.level.map:particleEmitter(x, y, 0, "sunburst", {radius=0, x=x, y=y})
--divine glyphs buff
		if self.summoner:knowTalent(self.summoner.T_DIVINE_GLYPHS) then
			self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs or 0
			if self.summoner.turn_procs.divine_glyphs < 3 then
				local dg = self.summoner:getTalentFromId(self.summoner.T_DIVINE_GLYPHS)
				local maxStacks = dg.getMaxStacks(self.summoner, dg)
				local dur = dg.getTurns(self.summoner, dg)
				self.summoner:setEffect(self.summoner.EFF_DIVINE_GLYPHS, dur, {maxStacks=maxStacks})
				self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs + 1
			end
		end
		return true
	end,
	temporary = t.getDuration(self, t),
	x = tx, y = ty,
	disarm_power = math.floor(t.trapPower(self,t)),
	detect_power = math.floor(t.trapPower(self,t)),
	canAct = false,
	energy = {value=0},
	act = function(self)
		self:useEnergy()
		self.temporary = self.temporary - 1
		if self.temporary <= 0 then
			if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
			game.level:removeEntity(self)
		end
	end,
	summoner = self,
	summoner_gain_exp = true,
}

fatigue_glyph = Trap.new{
	name = "glyph of starlight",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_fatigue_01_64.png",
	faction = self.faction,
	fatigueDur = fatigueDur,
	fatigueDam = fatigueDam,
	desc = function(self)
		return ([[Inflicts a fatiguing darkness, dealing %d darkness damage and icnreasing the cooldown of a cooling-down talent by 1 upon every action for %d turns.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam), self.fatigueDur)
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
		if self.dam then
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.DARKNESS, self.dam, {type="light"})
		end
		who:setEffect(who.EFF_STARLIGHT_FATIGUE, self.fatigueDur, {dam=self.fatigueDam, src=self})
		game.level.map:particleEmitter(x, y, 0, "shadow_flash", {radius=0, x=x, y=y})
--divine glyphs buff
		if self.summoner:knowTalent(self.summoner.T_DIVINE_GLYPHS) then
			self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs or 0
			if self.summoner.turn_procs.divine_glyphs < 3 then
				local dg = self.summoner:getTalentFromId(self.summoner.T_DIVINE_GLYPHS)
				local maxStacks = dg.getMaxStacks(self.summoner, dg)
				local dur = dg.getTurns(self.summoner, dg)
				self.summoner:setEffect(self.summoner.EFF_DIVINE_GLYPHS, dur, {maxStacks=maxStacks})
				self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs + 1
			end
		end
		return true
	end,
	temporary = t.getDuration(self, t),
	x = tx, y = ty,
	disarm_power = math.floor(t.trapPower(self,t)),
	detect_power = math.floor(t.trapPower(self,t)),
	canAct = false,
	energy = {value=0},
	act = function(self)
		self:useEnergy()
		self.temporary = self.temporary - 1
		if self.temporary <= 0 then
			if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
			game.level:removeEntity(self)
		end
	end,
	summoner = self,
	summoner_gain_exp = true,
}

explosion_glyph = Trap.new{
	name = "glyph of twilight",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_repulsion_01_64.png",
	faction = self.faction,
	dam = dam,
	dist=dist,
	desc = function(self)
		return ([[Explodes, knocking back and dealing %d light and %d darkness damage.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam/2), engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam/2))
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
		if self.dam then
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.LIGHT, self.dam/2, {type="light"})
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.DARKNESS, self.dam/2, {type="light"})
		end
		if who.canBe("knockback") then
			local ox, oy = self.x, self.y
			local dir = util.getDir(who.x, who.y, who.old_x, who.old_y)
			self.x, self.y = util.coordAddDir(self.x, self.y, dir)
			who:knockback(self.x, self.y, self.dist)
			self.x, self.y = ox, oy
		end
--divine glyphs buff
		if self.summoner:knowTalent(self.summoner.T_DIVINE_GLYPHS) then
			self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs or 0
			if self.summoner.turn_procs.divine_glyphs < 3 then
				local dg = self.summoner:getTalentFromId(self.summoner.T_DIVINE_GLYPHS)
				local maxStacks = dg.getMaxStacks(self.summoner, dg)
				local dur = dg.getTurns(self.summoner, dg)
				self.summoner:setEffect(self.summoner.EFF_DIVINE_GLYPHS, dur, {maxStacks=maxStacks})
				self.summoner.turn_procs.divine_glyphs = self.summoner.turn_procs.divine_glyphs + 1
			end
		end
		return true
	end,
	temporary = t.getDuration(self, t),
	x = tx, y = ty,
	disarm_power = math.floor(t.trapPower(self,t) * 0.8),
	detect_power = math.floor(t.trapPower(self,t) * 0.8),
	inc_damage = table.clone(self.inc_damage or {}, true),
	resists_pen = table.clone(self.resists_pen or {}, true),
	canAct = false,
	energy = {value=0},
	act = function(self)
		self:useEnergy()
		self.temporary = self.temporary - 1
		if self.temporary <= 0 then
			if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
			game.level:removeEntity(self)
		end
	end,
	summoner = self,
	summoner_gain_exp = true,
}
----------------------------------------------------------------
-- END - Define Glyph Traps - END
----------------------------------------------------------------
--build a table of glyphs
		local glyphs = {}
		if not self.turn_procs.glyph_para then
			glyphs[#glyphs+1] = para_glyph
		end
		if not self.turn_procs.glyph_fatigue then
			glyphs[#glyphs+1] = fatigue_glyph
		end
		if not self.turn_procs.glyph_explosion then
			glyphs[#glyphs+1] = explosion_glyph
		end
		if #glyphs < 1 then return nil end
--get a random glyph from table
		local trap = rng.tableRemove(glyphs)
--set cooldowns
		if trap == para_glyph then self.turn_procs.glyph_para = t.getGlyphCD(self, t)
		elseif trap == fatigue_glyph then self.turn_procs.glyph_fatigue = t.getGlyphCD(self, t)
		elseif trap == explosion_glyph then self.turn_procs.glyph_explosion = t.getGlyphCD(self, t)
		end
---place a glyph on each glyphgrid
		for i = 1, 9 do
			local spot = i == 1 and {x=x, y=y} or rng.tableRemove(glyphgrids)
			if not spot then break end
			trap:identify(true)
			trap:resolve() trap:resolve(nil, true)
			trap:setKnown(self, true)
			game.level:addEntity(trap)
			game.zone:addEntity(game.level, trap, "trap", spot.x, spot.y)
			game.level.map:particleEmitter(spot.x, spot.y, 1, "summon")
		end
--cost resources
		self:incNegative(-5)
		self:incPositive(-5)
	end,
	activate = function(self, t)
		local ret = {}
		if core.shader.active() then
			particle1 = self:addParticles(Particles.new("shader_ring_rotating", 1, {rotation=0, radius=0.8, img="runicshield_yellow"}, {type="lightningshield", time_factor=3000, noup=1.0}))
			particle1.toback = true
			particle2 = self:addParticles(Particles.new("shader_ring_rotating", 1, {rotation=0, radius=0.8, img="runicshield_dark"}, {type="lightningshield", time_factor=3000, noup=1.0}))
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if p.particle1 then self:removeParticles(p.particle1) end
		if p.particle2 then self:removeParticles(p.particle2) end
		return true
	end,
	info = function(self, t)
		local dam = t.getGlyphDam(self, t)
		local blindDur = t.getBlindDur(self, t)
		local fatigueDur = t.getFatigueDur(self, t)
		local fatigueDam = t.getFatigueDam(self, t)
		local kbDist = t.getKnockBack(self, t)
		return ([[When one of your spells goes critical, you bind glyphs in radius 1 centred on a random target in range 7 at the cost of 5 positive and 5 negative.
		Glyphs are hidden traps (%d detection and disarm power) lasting for %d turns.
		This can only happen once per turn and each glyph can only be bound every %d turns.
		Glyph damage will scale with spellpower and detection and disarm powers scale with magic.

		Avalable glyphs are:
		Glyph of Sunlight - Bind sunlight into a glyph. When triggered it will release a brilliant light, dealing %d light damage and blinding for %d turns.
		Glyph of Fatigue - Bind starlight into a glyph. When triggered it will release a fatiguing darkness. For %d turns, every action the foe makes will increase the cooldown of a cooling-down talent by 1 and cause it to take %d darkness damage.
		Glyph of Explosion - Bind twilight into a glyph. When triggered it will release a burst of twilight, knocking the foe back %d tiles and dealing %d light and %d darkness damage.
		]]):format(t.trapPower(self, t), t.getDuration(self, t), t.getGlyphCD(self, t), damDesc(self, DamageType.LIGHT, dam), blindDur, fatigueDur, damDesc(self, DamageType.DARKNESS, fatigueDam), kbDist, damDesc(self, DamageType.LIGHT, dam/2), damDesc(self, DamageType.DARKNESS, dam/2))
	end,
}



newTalent{
	name = "Glyphs of Fury",
	type = {"celestial/glyphs", 2},
	require = divi_req_high2,
	random_ego = "attack",
	points = 5,
	mode = "passive",
	getPersistentDuration = function(self, t) return self:combatTalentLimit(t, 6, 2, 5) end,
	getTriggerDam = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	info = function(self, t)
		local dam = t.getTriggerDam(self, t)
		return ([[Your glyphs are imbued with celestial fury; they last %d turns longer and when triggered they will deal damage.
		Glyph of Sunlight: Deals %d light damage.
		Glyph of Starlight: Deals %d darkness damage.
		Glyph of Twilight: Deals %d light and %d darkness damage.]]):format(t.getPersistentDuration(self, t), damDesc(self, DamageType.LIGHT, dam), damDesc(self, DamageType.DARKNESS, dam), damDesc(self, DamageType.LIGHT, dam/2), damDesc(self, DamageType.DARKNESS, dam/2))
	end,
}




newTalent{
	name = "Divine Glyphs",
	type = {"celestial/glyphs", 3},
	require = divi_req_high3,
	random_ego = "attack",
	points = 5,
	mode = "passive",
	getMaxStacks = function(self, t) return self:combatTalentLimit(t, 6, 2, 5) end,
	getTurns = function(self, t) return self:combatTalentLimit(t, 14, 1, 12) end,
	info = function(self, t)
		return ([[Up to 3 times pers turn when one of your glyphs triggers you feel a surge of celestial power, increasing your darkness and light resistence and affinity by 5%% for %d turns, stacking up to %d times.]]):format(t.getTurns(self, t), t.getMaxStacks(self, t))
	end,
}



newTalent{
	name = "Twilight Glyph",
	type = {"celestial/glyphs",4},
	require = divi_req_high4,
	points = 5,
	random_ego = "attack",
	cooldown = function(self, t) return 6 + (consecutive_twilights or 0) * 2 end,
	negative = 7,
	positive = 7,
	tactical = { ATTACKAREA = {LIGHT = 1, DARKNESS = 1} },
	range = 7,
	direct_hit = true,
	getDamage =  function(self, t) return self:combatTalentSpellDamage(t, 10, 170) end,
	getConsecutiveTurns = function(self, t) return self:combatTalentLimit(t, 15, 4, 10) end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		--alternate between damage types
		self.twilightdam = self.twilightdam or false
		if self.twilightdam == false then
			self:project(tg, x, y, DamageType.LIGHT, self:spellCrit(t.getDamage(self, t)))
			self.twilightdam = true

			game.level.map:particleEmitter(x, y, 1, "circle", {base_rot=0, oversize=0.8, a=130, limit_life=5, appear=5, speed=0, img="healcelestial", radius=0})

		else
			self:project(tg, x, y, DamageType.DARKNESS, self:spellCrit(t.getDamage(self, t)))
			self.twilightdam = false

			game.level.map:particleEmitter(x, y, 1, "circle", {base_rot=0, oversize=0.8, a=130, limit_life=5, appear=5, speed=0, img="healdark", radius=0})

		end
		--count casts and cd at limit
		self.consecutive_twilights = (self.consecutive_twilights or 0) + 1
		if self.consecutive_twilights < t.getConsecutiveTurns(self, t) then
			self.turn_procs.twilightsurge = 1
		else
			self:startTalentCooldown(t)
			self.consecutive_twilights = 0
		end
		return true, {ignore_cd=true}
	end,
	--cd if not used consecutively
	callbackOnActEnd = function(self, t)
		self.consecutive_twilights = self.consecutive_twilights or 0
		if self.consecutive_twilights > 0 then
			if not self.turn_procs.twilightsurge then
				self:startTalentCooldown(t)
				self.consecutive_twilights = 0
			end
		end
	end,
	info = function(self, t)
		local dam = t.getDamage(self, t)
		return ([[Bind the twilight into a transient glyph that will instantly deal damage alternating between %d light and %d darkness before dissipating.
		This spell can be used for %d consecutive turns without going on cooldown, however each consecutive cast will increase the cooldown by 2. When the cast limit is reached or a turn is spent not casting this spell, it will go on cooldown.]]):format(damDesc(self, DamageType.LIGHT, dam), damDesc(self, DamageType.DARKNESS, dam), t.getConsecutiveTurns(self, t))
	end,
}
