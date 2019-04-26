local Trap = require "mod.class.Trap"








newTalent{
	name = "Glyphs",
	type = {"celestial/glyphs", 1},
	require = divi_req_high1,
	random_ego = "attack",
	points = 5,
	mode = "passive",
	range = function(self, t) return 7 end,
	radius = function(self, t) return 1 end,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t} end,
	getDuration = function(self, t)
		if self:knowTalent(self.T_PERSISTENT_GLYPHS) then
			local pg = self:getTalentFromId(self.T_PERSISTENT_GLYPHS)
			return self:combatTalentSpellDamage(t, 3, 6) + pg.getPersistentDuration(self, pg)
		else
			return self:combatTalentSpellDamage(t, 3, 6)
		end
	end,
	getGlyphCD = function(self, t)
		if self:knowTalent(self.T_PERSISTENT_GLYPHS) then
			local pg = self:getTalentFromId(self.T_PERSISTENT_GLYPHS)
			return 9 - pg.getPersistentCooldown(self, pg)
		else
			return 9
		end
	end,
	trapPower = function(self, t) return math.max(1,self:combatScale(self:getTalentLevel(t) * self:getMag(15, true), 0, 0, 75, 75)) end,
	getGlyphDam = function(self, t) return self:combatTalentSpellDamage(t, 20, 200) end,
	getDetDur = function(self, t) return self:combatTalentLimit(t, 8, 3, 7) end,

	on_crit = function(self, t)
		if self:getPositive() < 5 or self:getNegative() < 5 then return nil end
		if self.turn_procs.glyphs then return nil end
		if not rng.percent(100) then return nil end

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
		local detDur = t.getDetDur(self, t)

----------------------------------------------------------------
-- START - Define Glyph Traps - START
----------------------------------------------------------------
para_glyph = Trap.new{
	name = "glyph of paralysis",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_explosion_02_64.png",
	faction = self.faction,
	dam = dam,
	detDur = detDur,
	desc = function(self)
		return ([[Deals %d light damage.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam))
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
		self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.LIGHT, self.dam, {type="light"})
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
	name = "glyph of fatigue",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_fatigue_01_64.png",
	faction = self.faction,
	dam = dam,
	desc = function(self)
		return ([[Deals %d darkness damage.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam))
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
		self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.DARKNESS, self.dam, {type="light"})
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
	name = "glyph of explosion",
	type = "elemental", id_by_type=true, unided_name = "trap",
	display = '^', color=colors.GOLD, image = "trap/trap_glyph_repulsion_01_64.png",
	faction = self.faction,
	dam = dam,
--	agdam = agdam,
	desc = function(self)
		return ([[Explodes (radius 1), knocking back and dealing %d light and %d darkness damage.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam), engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam))
	end,
	canTrigger = function(self, x, y, who)
		if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
		return false
	end,
	triggered = function(self, x, y, who)
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.LIGHT, self.dam, {type="light"})
			game.level.map:particleEmitter(x, y, 0, "sunburst", {radius=0, x=x, y=y})
			self:project({type="hit", x=x,y=y}, x, y, engine.DamageType.DARKKNOCKBACK, self.dam, {type="light"})
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
--[[
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
		self.turn_procs.glyphs = 1
		local dam = self:spellCrit(t.getGlyphDam(self, t))
		local detDur = t.getDetDur(self, t)
		]]
--get a random glyph from table
		local trap = rng.tableRemove(glyphs)

--set cooldown
		--self.turn_procs.glyphs = 1
		if trap == para_glyph then self.turn_procs.glyph_para = t.getGlyphCD(self, t)
		elseif trap == fatigue_glyph then self.turn_procs.glyph_fatigue = t.getGlyphCD(self, t)
		elseif trap == explosion_glyph then self.turn_procs.glyph_explosion = t.getGlyphCD(self, t)
		end

---put a glyph on each glyphgrid
		for i = 1, 9 do
			local spot = i == 1 and {x=x, y=y} or rng.tableRemove(glyphgrids)
			if not spot then break end



--place glyph
			trap:identify(true)
			trap:resolve() trap:resolve(nil, true)
			trap:setKnown(self, true)
			game.level:addEntity(trap)
			game.zone:addEntity(game.level, trap, "trap", spot.x, spot.y)
			game.level.map:particleEmitter(spot.x, spot.y, 1, "summon")

--trigger glyphs
--			if self:knowTalent(self.T_AGRESSIVE_BINDING) then
--				trap:trigger(spot.x, spot.y)
--			end

		end

--cost resources
		self:incNegative(-5)
		self:incPositive(-5)



	end,

	info = function(self, t)
		return ([[When you crit have a 50%% chance to bind glyphs in radius 1 centred on a random target in range 7.
		Glyphs are hidden traps (%d detection and disarm power) lasting for %d turns.
		This can only happen once per turn and each glyph can only be bound every %d turns.
		Glyph damage will scale with spellpower and detection and disarm powers scale with magic.

		Avalable glyphs are:
		Glyph of Paralysis -
		Glyph of Fatigue -
		Glyph of Explosion -
		]]):format(t.trapPower(self, t), t.getDuration(self, t), t.getGlyphCD(self, t))
	end,
}



newTalent{
	name = "Persisent Glyphs",
	type = {"celestial/glyphs", 2},
	require = divi_req_high2,
	random_ego = "attack",
	points = 5,
	mode = "passive",
	getPersistentDuration = function(self, t) return self:combatTalentLimit(t, 6, 1, 5) end,
	getPersistentCooldown = function(self, t) return self:combatTalentLimit(t, 4, 1, 3) end,
	info = function(self, t)
		return ([[Your glyph binding becomes more permanent and less taxing, increasing glyph duration by %d turns and reducing their cooldowns by %d turns.
		This will be reflected in the Glyphs talent tooltip.]]):format(t.getPersistentDuration(self, t), t.getPersistentCooldown(self, t))
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
	getTurns = function(self, t) return self:combatTalentLimit(t, 4, 13, 15) end,
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
		local twilightdam = twilightdam or false
		if twilightdam == false then
			self:project(tg, x, y, DamageType.LIGHT, self:spellCrit(t.getDamage(self, t)), {type="light"})
			twilightdam = true

			if core.shader.active(4) then
				tg:addParticles(Particles.new("shader_shield_temp", 1, {toback=true, size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=2.0, beamColor1={0xd8/255, 0xff/255, 0x21/255, 1}, beamColor2={0xf7/255, 0xff/255, 0x9e/255, 1}, circleDescendSpeed=3}))
				tg:addParticles(Particles.new("shader_shield_temp", 1, {toback=false,size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0, beamColor1={0xd8/255, 0xff/255, 0x21/255, 1}, beamColor2={0xf7/255, 0xff/255, 0x9e/255, 1}, circleDescendSpeed=3}))
			end

		else
			self:project(tg, x, y, DamageType.DARKNESS, self:spellCrit(t.getDamage(self, t)), {type="dark"})
			twilightdam = false

			if core.shader.active(4) then
				tg:addParticles(Particles.new("shader_shield_temp", 1, {toback=true, size_factor=1.5, y=-0.3, img="healdark", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=2.0, beamColor1={0xd8/255, 0xff/255, 0x21/255, 1}, beamColor2={0xf7/255, 0xff/255, 0x9e/255, 1}, circleDescendSpeed=3}))
				tg:addParticles(Particles.new("shader_shield_temp", 1, {toback=false,size_factor=1.5, y=-0.3, img="healdark", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0, beamColor1={0xd8/255, 0xff/255, 0x21/255, 1}, beamColor2={0xf7/255, 0xff/255, 0x9e/255, 1}, circleDescendSpeed=3}))
			end

		end
		--count casts and cd at limit
		consecutive_twilights = (consecutive_twilights or 0) + 1
		if consecutive_twilights < t.getConsecutiveTurns(self, t) then
			self.turn_procs.twilightsurge = 1
		else
			self:startTalentCooldown(t)
			consecutive_twilights = 0
		end
		return true, {ignore_cd=true}
	end,
	--cd if not used consecutively
	callbackOnActEnd = function(self, t)
		if consecutive_twilights > 0 and not self.turn_procs.twilightsurge then
			self:startTalentCooldown(t)
			consecutive_twilights = 0
		end
	end,
	info = function(self, t)
		local dam = t.getDamage(self, t)
		return ([[Bind the twilight into a transient glyph that will instantly deal damage alternating between %d light and %d darkness before dissipating.
		This spell can be used for %d consecutive turns without going on cooldown, however each consecutive cast will increase the cooldown by 2. When the cast limit is reached or a turn is spent not casting this spell, it will go on cooldown.]]):format(damDesc(self, DamageType.LIGHT, dam), damDesc(self, DamageType.DARKNESS, dam), t.getConsecutiveTurns(self, t))
	end,
}
