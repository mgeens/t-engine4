local Trap = require "mod.class.Trap"



newTalent{
	name = "Glyph of Paralysis",
	type = {"celestial/glyphs", 1},
	require = divi_req_high1,
	random_ego = "attack",
	points = 5,
	cooldown = 20,
	positive = -10,
	no_energy = true,
	tactical = { ATTACKAREA = {LIGHT = 2} },
--	requires_target = true,
	range = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5, "log")) end,
	radius = function() return 1 end,
	direct_hit = true,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t} end,
	getDamage = function(self, t) return 15 + self:combatSpellpower(0.15) * self:combatTalentScale(t, 1.5, 5) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end, -- Duration of glyph
	trapPower = function(self,t) return math.max(1,self:combatScale(self:getTalentLevel(t) * self:getMag(15, true), 0, 0, 75, 75)) end,
	getNb = function(self, t) return 9 end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		if game.level.map(x, y, Map.TRAP) then game.logPlayer(self, "You somehow fail to set the corrosive seed.") return nil end
		
		local grids = {}
		self:project(tg, x, y, function(px, py)
			if not ((px == x and py == y) or game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move") or game.level.map(px, py, Map.TRAP)) then grids[#grids+1] = {x=px, y=py} end
		end)
		local dam = self:spellCrit(t.getDamage(self, t))
		local slowPower = t.getSlow(self, t)
		for i = 1, t.getNb(self, t) do
			local spot = i == 1 and {x=x, y=y} or rng.tableRemove(grids)
			if not spot then break end
			local trap = Trap.new{
				name = "glyph of paralysis",
				type = "elemental", id_by_type=true, unided_name = "trap",
				display = '^', color=colors.GOLD, image = "trap/trap_glyph_explosion_02_64.png",
				faction = self.faction,
				dam = dam,
				pinDur = pinDur,
				desc = function(self)
					return ([[Deals %d light damage and pins for %d turns.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam), self.pinDur)
				end,
				canTrigger = function(self, x, y, who)
					if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
					return false
				end,
				triggered = function(self, x, y, who)
					who:setEffect(who.EFF_PPIN, self.pinDur)
					self:project({type="hit",x=x,y=y}, x, y, engine.DamageType.LIGHT, self.dam)
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
			trap:identify(true)
			trap:resolve() trap:resolve(nil, true)
			trap:setKnown(self, true)
			game.level:addEntity(trap)
			game.zone:addEntity(game.level, trap, "trap", spot.x, spot.y)
			game.level.map:particleEmitter(spot.x, spot.y, 1, "summon")
		end

		return true
	end,
	info = function(self, t)
		local pinPin = t.getPin(self, t)
		local dam = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		return ([[Bind light in glyphs on the floor. All enemies walking over the glyphs will struck by a paralysing light, dealing %d light damage and pinning them for %d turns.
		
		The glyph is a hidden trap (%d detection and %d disarm power) and lasts for 6, 7, 9, 10, 11 turns.
		
		The damage will increase with Spellpower. The detection and disarm power increases with Magic.]]):
		format(slow, damDesc(self, DamageType.LIGHT, damage), t.trapPower(self, t), t.trapPower(self, t), duration)
	end,
}





newTalent{
	name = "Glyph of Fatigue",
	type = {"celestial/glyphs", 2},
	require = divi_req_high2,
	random_ego = "attack",
	points = 5,
	cooldown = 20,
	positive = -10,
	no_energy = true,
	tactical = { ATTACKAREA = {DARK = 2} },
--	requires_target = true,
	range = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5, "log")) end,
	radius = function() return 1 end,
	direct_hit = true,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t} end,
	getDamage = function(self, t) return 15 + self:combatSpellpower(0.15) * self:combatTalentScale(t, 1.5, 5) end,
	getSlow = function(self, t) return self:combatTalentLimit(t, 1, 0.20, 0.35) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end, -- Duration of glyph
	trapPower = function(self,t) return math.max(1,self:combatScale(self:getTalentLevel(t) * self:getMag(15, true), 0, 0, 75, 75)) end,
	getNb = function(self, t) return 9 end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		if game.level.map(x, y, Map.TRAP) then game.logPlayer(self, "You somehow fail to set the corrosive seed.") return nil end
		
		local grids = {}
		self:project(tg, x, y, function(px, py)
			if not ((px == x and py == y) or game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move") or game.level.map(px, py, Map.TRAP)) then grids[#grids+1] = {x=px, y=py} end
		end)
		local dam = self:spellCrit(t.getDamage(self, t))
		local slowPower = t.getSlow(self, t)
		for i = 1, t.getNb(self, t) do
			local spot = i == 1 and {x=x, y=y} or rng.tableRemove(grids)
			if not spot then break end
			local trap = Trap.new{
				name = "glyph of fatigue",
				type = "elemental", id_by_type=true, unided_name = "trap",
				display = '^', color=colors.GOLD, image = "trap/trap_glyph_fatigue_01_64.png",
				faction = self.faction,
				dam = dam,
				slowPower = slowPower,
				desc = function(self)
					return ([[Slows (%d%%) for 5 turns.]]):format(self.slowPower*100, engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam))
				end,
				canTrigger = function(self, x, y, who)
					if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
					return false
				end,
				triggered = function(self, x, y, who)
					who:setEffect(who.EFF_CELESTIAL_FATIGUE, 5, {power=self.slowPower})
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
			trap:identify(true)
			trap:resolve() trap:resolve(nil, true)
			trap:setKnown(self, true)
			game.level:addEntity(trap)
			game.zone:addEntity(game.level, trap, "trap", spot.x, spot.y)
			game.level.map:particleEmitter(spot.x, spot.y, 1, "summon")
		end

		return true
	end,
	info = function(self, t)
		local slow = t.getSlow(self, t)
		local dam = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		return ([[Bind darkness in glyphs on the floor. All enemies walking over the glyphs will afflicted with a fatiguing darkness for 5 turns, slowing (%d%%) them and dealing %d darkness damage when they use a talent.
		
		The glyph is a hidden trap (%d detection and %d disarm power) and lasts for 6, 7, 9, 10, 11 turns.
		
		The damage will increase with Spellpower. The detection and disarm power increases with Magic.]]):
		format(slow, damDesc(self, DamageType.DARKNESS, damage), t.trapPower(self, t), t.trapPower(self, t), duration)
	end,
}





newTalent{
	name = "Glyph of Explosion",
	type = {"celestial/glyphs", 3},
	require = divi_req_high3,
	random_ego = "attack",
	points = 5,
	cooldown = 20,
	positive = -10,
	no_energy = true,
	tactical = { ATTACKAREA = {LIGHT = 2} },
--	requires_target = true,
	range = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5, "log")) end,
	radius = function() return 1 end,
	direct_hit = true,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t} end,
	getDamage = function(self, t) return 15 + self:combatSpellpower(0.15) * self:combatTalentScale(t, 1.5, 5) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 6, 10)) end, -- Duration of glyph
	trapPower = function(self,t) return math.max(1,self:combatScale(self:getTalentLevel(t) * self:getMag(15, true), 0, 0, 75, 75)) end,
	getNb = function(self, t) return 9 end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		if game.level.map(x, y, Map.TRAP) then game.logPlayer(self, "You somehow fail to set the corrosive seed.") return nil end
		
		local grids = {}
		self:project(tg, x, y, function(px, py)
			if not ((px == x and py == y) or game.level.map:checkEntity(px, py, Map.TERRAIN, "block_move") or game.level.map(px, py, Map.TRAP)) then grids[#grids+1] = {x=px, y=py} end
		end)
		local dam = self:spellCrit(t.getDamage(self, t))
		for i = 1, t.getNb(self, t) do
			local spot = i == 1 and {x=x, y=y} or rng.tableRemove(grids)
			if not spot then break end
			local trap = Trap.new{
				name = "glyph of explosion",
				type = "elemental", id_by_type=true, unided_name = "trap",
				display = '^', color=colors.GOLD, image = "trap/trap_glyph_explosion_02_64.png",
				faction = self.faction,
				dam = dam,
				desc = function(self)
					return ([[Explodes (radius 1), knocking back and dealing %d light and %d darkness damage.]]):format(engine.interface.ActorTalents.damDesc(self, engine.DamageType.LIGHT, self.dam), engine.interface.ActorTalents.damDesc(self, engine.DamageType.DARKNESS, self.dam))
				end,
				canTrigger = function(self, x, y, who)
					if who:reactionToward(self.summoner) < 0 then return mod.class.Trap.canTrigger(self, x, y, who) end
					return false
				end,
				triggered = function(self, x, y, who)
					self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.LIGHT, self.dam, {type="light"})
					game.level.map:particleEmitter(x, y, 1, "sunburst", {radius=1, x=x, y=y})
					self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.DARKKNOCKBACK, self.dam, {type="light"})
					game.level.map:particleEmitter(x, y, 1, "shadow_flash", {radius=1, x=x, y=y})
					
					if self.summoner:knowTalent(self.summoner.T_DIVINE_GLYPHS) then
						local dg = self.summoner:getTalentFromId(self.summoner.T_DIVINE_GLYPHS)
						local maxStacks = dg.getMaxStacks(self.summoner, dg)
						--self.summoner:setEffect(self.summoner.EFF_DIVINE_GLYPHS, 6, {maxStacks=maxStacks})
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
			trap:identify(true)
			trap:resolve() trap:resolve(nil, true)
			trap:setKnown(self, true)
			game.level:addEntity(trap)
			game.zone:addEntity(game.level, trap, "trap", spot.x, spot.y)
			game.level.map:particleEmitter(spot.x, spot.y, 1, "summon")
		end

		if self:knowTalent(self.T_DIVINE_GLYPHS) then
			local dg = self:getTalentFromId(self.T_DIVINE_GLYPHS)
			local dam = dam * dg.getGlyphPower(self, dg)
			local maxStacks = dg.getMaxStacks(self, dg)
			
			self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.LIGHT, dam, {type="light"})
			game.level.map:particleEmitter(x, y, 1, "sunburst", {radius=1, x=x, y=y})
			self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.DARKKNOCKBACK, dam, {type="light"})
			game.level.map:particleEmitter(x, y, 1, "shadow_flash", {radius=1, x=x, y=y})
			
			self:setEffect(self.EFF_DIVINE_GLYPHS, 6, {maxStacks=maxStacks, explosionStacks=1})
		end

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		return ([[Bind light and darkness in glyphs on the floor. All enemies walking over the glyphs will trigger a twilight explosion that knocks back and deals %d light and %d darkness damage.
		
		The glyph is a hidden trap (%d detection and %d disarm power) and lasts for 6, 7, 9, 10, 11 turns.
		
		The damage will increase with Spellpower. The detection and disarm power increases with Magic.]]):
		format(damDesc(self, DamageType.LIGHT, damage), damDesc(self, DamageType.DARKNESS, damage), t.trapPower(self, t), t.trapPower(self, t), duration)
	end,
}





newTalent{
	name = "Divine Glyphs",
	type = {"celestial/glyphs", 4},
	require = divi_req_high4,
	random_ego = "attack",
	points = 5,
	mode = "passive",
	getGlyphPower = function(self, t) return self:combatTalentScale(t, 0.6, 0.1, 0.5) end,
	getMaxStacks = function(self, t) return self:combatTalentScale(t, 3, 6) end,
	getTurns = function(self, t) return 6 - self:getTalentLevelRaw() end,
	
	
	info = function(self, t)
		return ([[When you bind a glyph you will also trigger its effect %d%% power (this only happens once every %d turns).
		Additionally, every time a glyph triggers you will gain a beneficial effect, stacking up to %d times.
		Glyph of Paralysis: +4% to light resistance and affinity.
		Glyph of Fatigue: +4% to darkness resistance and affinity.
		Glyph of Explosion: +4% to light and darkness damage.]]):
		format(t.getGlyphPower(self, t), t.getTurns(self, t), t.getMaxStacks(self, t))
	end,
}

--[[
		--check for talent and turn limit
		if self:knowTalent(self.T_DIVINE_GLYPHS) and not self.turn_procs.divine_glyphs then
			local dg = self:getTalentFromId(self.T_DIVINE_GLYPHS)
			local dam = dam * dg.getGlyphPower(self, dg)
			local maxStacks = dg.getMaxStacks(self, dg)
			local glyphTurns = dg.getTurns(self, dg)
			
			--do the glyph effect
			self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.LIGHT, dam, {type="light"})
			game.level.map:particleEmitter(x, y, 1, "sunburst", {radius=1, x=x, y=y})
			self:project({type="ball", x=x,y=y, radius=1}, x, y, engine.DamageType.DARKKNOCKBACK, dam, {type="light"})
			game.level.map:particleEmitter(x, y, 1, "shadow_flash", {radius=1, x=x, y=y})
			--set self buff manually
			self:setEffect(self.EFF_DIVINE_GLYPHS, 6, {maxStacks=maxStacks})
			--cooldown
			self.turn_procs.divine_glyphs = glyphTurns
		end
]]