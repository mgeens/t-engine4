-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2017 Nicolas Casalini
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

local Map = require "engine.Map"

----------------------------------------------------------------
-- Poisons
----------------------------------------------------------------

local function cancelPoisons(self)
	local todel = {}
	for tid, p in pairs(self.sustain_talents) do
		local t = self:getTalentFromId(tid)
		if t.vile_poison or t.type[1] == "cunning/poisons-effects" then
			todel[#todel+1] = tid
		end
	end
	while #todel > 1 do self:forceUseTalent(rng.tableRemove(todel), {ignore_energy=true}) end
end

newTalent{
	name = "Apply Poison",
	type = {"cunning/poisons", 1},
	require = cuns_req1,
	mode = "sustained",
	points = 5,
	cooldown = 10,
	no_break_stealth = true,
	tactical = { BUFF = 2 },
	sustain_stamina = 10,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 4, 7)) end,
	getChance = function(self,t) return self:combatTalentLimit(t, 100, 25, 45) end,
	getDamage = function(self, t) return 8 + self:combatTalentStatDamage(t, "cun", 10, 60) * 0.6 end,
	ApplyPoisons = function(self, t, target, weapon) -- apply poison(s) to a target
		if self:knowTalent(self.T_VULNERABILITY_POISON) then -- apply vulnerability first
			target:setEffect(target.EFF_VULNERABILITY_POISON, t.getDuration(self, t), {src=self, power=self:callTalent(self.T_VULNERABILITY_POISON, "getDamage") , apply_power=self:combatAttack(), no_ct_effect=true})
		end
		if target:canBe("poison") then
			local insidious = 0
			if self:isTalentActive(self.T_INSIDIOUS_POISON) then insidious = self:callTalent(self.T_INSIDIOUS_POISON, "getEffect") end
			local numbing = 0
			if self:isTalentActive(self.T_NUMBING_POISON) then numbing = self:callTalent(self.T_NUMBING_POISON, "getEffect") end
			local crippling = 0
			if self:isTalentActive(self.T_CRIPPLING_POISON) then crippling = self:callTalent(self.T_CRIPPLING_POISON, "getEffect") end
			local leeching = 0
			if self:isTalentActive(self.T_LEECHING_POISON) then leeching = self:callTalent(self.T_LEECHING_POISON, "getEffect") end
			local volatile = 0
			if self:isTalentActive(self.T_VOLATILE_POISON) then volatile = self:callTalent(self.T_VOLATILE_POISON, "getEffect")/100 end
			local dam = t.getDamage(self,t) * (1 + volatile)
			target:setEffect(target.EFF_DEADLY_POISON, t.getDuration(self, t), {src=self, power=dam, max_power=dam*4, insidious=insidious, crippling=crippling, numbing=numbing, leeching=leeching, volatile=volatile, apply_power=self:combatAttack(), no_ct_effect=true})
			if self.vile_poisons then
				for tid, val in pairs(self.vile_poisons) do -- apply any special procs
					local tal = self:getTalentFromId(tid)
					if tal and tal.proc then
						tal.proc(self, tal, target, weapon)
					end
				end
			end
		end
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype, mult, dam)
		if target and hitted and rng.percent(t.getChance(self,t)) then
			t.ApplyPoisons(self, t, target, weapon)
		end
	end,
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		if target and hitted and rng.percent(t.getChance(self,t)) then
			t.ApplyPoisons(self, t, target, weapon)
		end
	end,
	activate = function(self, t)
		local ret = {}
		local h1x, h1y = self:attachementSpot("hand1", true) if h1x then self:talentParticles(ret, {type="apply_poison", args={x=h1x, y=h1y}}) end
		local h2x, h2y = self:attachementSpot("hand2", true) if h2x then self:talentParticles(ret, {type="apply_poison", args={x=h2x, y=h2y}}) end
		self:talentParticles(ret, {type="apply_poison", args={}})
		return ret
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[Learn how to coat your melee weapons, throwing knives, sling and bow ammo with poison, giving your attacks a %d%% chance to poison the target for %d nature damage per turn for %d turns. Every application of the poison stacks, up to a maximum of %d nature damage per turn.
		The damage scales with your Cunning.]]):
		format(t.getChance(self,t), damDesc(self, DamageType.NATURE, t.getDamage(self, t)), t.getDuration(self, t), damDesc(self, DamageType.NATURE, t.getDamage(self, t)*4))
	end,
}

newTalent{
	name = "Toxic Death",
	type = {"cunning/poisons", 2},
	points = 5,
	mode = "passive",
	require = cuns_req2,
	getRadius = function(self, t) return math.floor(self:combatTalentLimit(t, 10, 1.5, 3.5)) end,
	on_kill = function(self, t, target)
		local poisons = {}
		local to_spread  = 0
		for k, v in pairs(target.tmp) do
			local e = target.tempeffect_def[k]
			if e.subtype.poison and v.src == self then
				print("[Toxic Death] spreading poison", k, target.x, target.y)
				poisons[k] = target:copyEffect(k) poisons[k]._from_toxic_death = true
				to_spread = to_spread + 1
			end
		end
		-- Note: New effects functions are called in order: merge, on_gain, activate
		if to_spread > 0 then
			local tg = {type="ball", range = 10, radius=t.getRadius(self, t), selffire = false, friendlyfire = false, talent=t, stop_block=true}
			target.dead = false -- for combat log purposes
			game.logSeen(target, "#GREEN#Poison bursts out of %s's corpse!", target.name:capitalize())
			game.level.map:particleEmitter(target.x, target.y, tg.radius, "slime")
			self:project(tg, target.x, target.y, function(tx, ty)
				local target2 = game.level.map(tx, ty, Map.ACTOR)
				if not target2 or target2 == target then return end
				for eff, p in pairs(poisons) do
					game:playSoundNear(target, "creatures/jelly/jelly_hit")
					if p.unresistable or target2:canBe("poison") then target2:setEffect(eff, p.dur, table.clone(p)) end
				end
			end)
			target.dead = true
		end
	end,
	info = function(self, t)
		return ([[When you kill a creature, all of your poisons affecting it will spread to foes in a radius of %d.]]):format(t.getRadius(self, t))
	end,
}

newTalent{
	name = "Vile Poisons",
	type = {"cunning/poisons", 3},
	points = 5,
	mode = "passive",
	require = cuns_req3,
	on_learn = function(self, t)
		local lev = self:getTalentLevelRaw(t)
		if lev == 1 then
			self.vile_poisons = {}
			self:learnTalent(self.T_NUMBING_POISON, true, nil, {no_unlearn=true})
		elseif lev == 2 then
			self:learnTalent(self.T_INSIDIOUS_POISON, true, nil, {no_unlearn=true})
		elseif lev == 3 then
			self:learnTalent(self.T_CRIPPLING_POISON, true, nil, {no_unlearn=true})
		elseif lev == 4 then
			self:learnTalent(self.T_LEECHING_POISON, true, nil, {no_unlearn=true})
		elseif lev == 5 then
			self:learnTalent(self.T_VOLATILE_POISON, true, nil, {no_unlearn=true})
		end
	end,
	on_unlearn = function(self, t)
		local lev = self:getTalentLevelRaw(t)
		if lev == 0 then
			self:unlearnTalent(self.T_NUMBING_POISON)
			self.vile_poisons = nil
		elseif lev == 1 then
			self:unlearnTalent(self.T_INSIDIOUS_POISON)
		elseif lev == 2 then
			self:unlearnTalent(self.T_CRIPPLING_POISON)
		elseif lev == 3 then
			self:unlearnTalent(self.T_LEECHING_POISON)
		elseif lev == 4 then
			self:unlearnTalent(self.T_VOLATILE_POISON)
		end
	end,
info = function(self, t)
	return ([[Learn how to enhance your Deadly Poison, adding additional effects. Each level, you will learn a new kind of poison enhancement:
	Level 1: Numbing Poison
	Level 2: Insidious Poison
	Level 3: Crippling Poison
	Level 4: Leeching Poison
	Level 5: Volatile Poison
	New poison enhancements can also be learned from special teachers in the world.
	Also increases the effectiveness of your poisons by %d%%. (The effect varies for each poison.)
	Adjusting your weapon coating takes no time and does not break stealth.
	You may only have two poison enhancements active at once; applying a third will cause one of the existing ones to be cancelled at random.]]):
	format(self:getTalentLevel(t) * 20)
end,
}

newTalent{
	name = "Venomous Strike",
	type = {"cunning/poisons", 4},
	points = 5,
	cooldown = 10,
	stamina = 14,
	require = cuns_req4,
	requires_target = true,
	on_learn = venomous_throw_check,
	on_unlearn = venomous_throw_check,
	getDamage = function (self, t) return self:combatTalentWeaponDamage(t, 1.2, 2.1) end,
	getSecondaryDamage = function (self, t) return self:combatTalentStatDamage(t, "cun", 50, 550) end,
	getNb = function(self, t) return math.floor(self:combatTalentScale(t, 1, 4, "log")) end,
	getPower = function(self, t) return self:combatTalentLimit(t, 50, 10, 30)/100 end,
	tactical = { ATTACK = {NATURE = 2}},
	speed = "weapon",
	is_melee = function(self, t) return not self:hasArcheryWeapon() end,
	range = function(self, t)
		if self:hasArcheryWeapon() then return util.getval(archery_range, self, t) end
		return 1
	end,
	applyVenomousEffects = function(self, t, target) -- apply venomous strike effects to the target
		local idam = t.getSecondaryDamage(self,t)
		local vdam = t.getSecondaryDamage(self,t)*0.6
		local power = t.getPower(self,t)
		local heal = t.getSecondaryDamage(self,t)
		local nb = t.getNb(self,t)
		if self:isTalentActive(self.T_INSIDIOUS_POISON) and target:canBe("poison") then target:setEffect(target.EFF_POISONED, 5, {src=self, power=idam/5, no_ct_effect=true}) end		
		if self:isTalentActive(self.T_NUMBING_POISON) then target:setEffect(target.EFF_SLOW, 5, {power=power, no_ct_effect=true}) end
		if self:isTalentActive(self.T_CRIPPLING_POISON) then 
			local tids = {}
			for tid, lev in pairs(target.talents) do
				local t = target:getTalentFromId(tid)
				if t and not target.talents_cd[tid] and t.mode == "activated" and not t.innate then tids[#tids+1] = t end
			end
	
			local count = 0
			local cdr = math.floor(nb*1.5)
	
			for i = 1, nb do
				local t = rng.tableRemove(tids)
				if not t then break end
				target.talents_cd[t.id] = cdr
				game.logSeen(target, "#GREEN#%s's %s is disrupted by crippling poison!", target.name:capitalize(), t.name)
				count = count + 1
			end		
		end
		if self:isTalentActive(self.T_LEECHING_POISON) then self:heal(heal, target) end
		if self:isTalentActive(self.T_VOLATILE_POISON) then 
			local tg = {type="ball", radius=nb, friendlyfire=false, x=target.x, y=target.y}
			self:project(tg, target.x, target.y, DamageType.NATURE, vdam)
		end
	end,
	action = function(self, t)
		local dam = t.getDamage(self,t)
		if not self:hasArcheryWeapon() then
			local tg = {type="hit", range=self:getTalentRange(t)}
			local x, y, target = self:getTarget(tg)
			if not target or not self:canProject(tg, x, y) then return nil end
			local hit = self:attackTarget(target, DamageType.NATURE, dam, true)
			if hit then t.applyVenomousEffects(self, t, target) end
		else
			local targets = self:archeryAcquireTargets(nil, {one_shot=true})
			if not targets then return end
			local hit = self:archeryShoot(targets, t, nil, {mult=dam, damtype=DamageType.NATURE})
			if hit then t.applyVenomousEffects(self, t, target) end
		end
		
		self.talents_cd[self.T_VENOMOUS_THROW] = 8

		return true
	end,
	effectsDescription = function(self, t)
		local power = t.getPower(self,t)
		local idam = t.getSecondaryDamage(self,t)
		local nb = t.getNb(self,t)
		local heal = t.getSecondaryDamage(self,t)
		local vdam = t.getSecondaryDamage(self,t)*0.6
		return ([[Numbing Poison - Reduces global speed by %d%% for 5 turns.
		Insidious Poison - Applies a standard poison that deals %0.2f nature damage over 5 turns.
		Crippling Poison - Places %d talents on cooldown for %d turns.
		Leeching Poison - Heals you for %d.
		Volatile Poison - Deals a further %0.2f nature damage to foes in a radius %d ball.
		]]):
		format(power*100, damDesc(self, DamageType.NATURE, idam), nb, math.floor(nb*1.5), heal, damDesc(self, DamageType.NATURE, vdam), nb)
	end,
	info = function(self, t)
		local dam = 100 * t.getDamage(self,t)
		local desc = t.effectsDescription(self, t)
		return ([[You strike your target with your melee or ranged weapon, doing %d%% weapon damage as nature and inflicting additional effects based on your active vile poisons:
		
		%s
		Learning this talent in addition to the Throwing Knives talent allows you to learn the Venomous Throw talent, which can be used to throw poisoned daggers at your foes, but is put on cooldown when this talent is used.
		]]):
		format(dam, desc)
	end,
}

----------------------------------------------------------------
-- Deadly Poison Enhancements
----------------------------------------------------------------

newTalent{
	name = "Numbing Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	getEffect = function(self, t) return self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 35, 10, 20) end, -- Limit effect to <35%
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
	return ([[Enhances your Deadly Poison with a numbing agent, causing the poison to reduce all damage the target deals by %d%%.]]):
	format(t.getEffect(self, t))
	end,
}

newTalent{
	name = "Insidious Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	getEffect = function(self, t) return self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 100, 35.5, 57.5) end, -- Limit -healing effect to <100%
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
	return ([[Enhances your Deadly Poison with an insidious agent, causing it to reduce the healing taken by enemies by %d%%.]]):
	format(t.getEffect(self, t))
	end	
}

newTalent{
	name = "Crippling Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	getEffect = function(self, t) return self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 35, 10, 20) end, --	Limit chance to < 35%
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
	return ([[Enhances your Deadly Poison with a crippling agent, giving enemies a %d%% chance on using a talent to fail and lose a turn.]]):
	format(t.getEffect(self, t))
	end,
}

newTalent{
	name = "Leeching Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	getEffect = function(self, t) return self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 100, 10, 40) end, -- limit < 50%
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
	return ([[Enhances your Deadly Poison with a leeching agent, causing it to heal you for %d%% of the damage it does to its target.]]):
	format(t.getEffect(self, t))
	end,
}

newTalent{
	name = "Volatile Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	getEffect = function(self, t) return self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 100, 15, 50) end, --	Limit effect to < 100%
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
	return ([[Enhances your Deadly Poison with a volatile agent, causing the poison to deal %d%% increased damage and damage to all adjacent enemies.]]):
	format(t.getEffect(self, t))
	end,
}

-- learned only with the Mystical Cunning prodigy
newTalent{
	name = "Vulnerability Poison",
	type = {"cunning/poisons-effects", 1},
	points = 1,
	mode = "passive",
	no_unlearn_last = true,
	getDamage = function(self, t) return self:combatStatScale("mag", 20, 50, 0.75) end,
	info = function(self, t)
	return ([[Whenever you apply Deadly Poison, you also apply an unresistable magical poison dealing %0.2f arcane damage (based on your Magic) each turn. This poison reduces all damage resistance by 10%% and poison immunity by 50%%.]]):
	format(damDesc(self, DamageType.ARCANE, t.getDamage(self,t)))
	end,
}

-- learned from the lost merchant
newTalent{
	name = "Stoning Poison",
	type = {"cunning/poisons", 4},
	require = {stat = {cun=40}, level=25},
	hide = true,
	points = 1,
	mode = "sustained",
	cooldown = 10,
	no_break_stealth = true,
	no_energy = true,
	tactical = { BUFF = 2 },
	no_unlearn_last = true,
	vile_poison = true,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(self:getTalentLevel(self.T_VILE_POISONS), 6, 8)) end,
	getDOT = function(self, t) return 8 + self:combatTalentStatDamage(self.T_VILE_POISONS, "cun", 10, 30) * 0.4 end,
	stoneTime = function(self, t) return math.ceil(self:combatTalentLimit(self:getTalentLevel(self.T_VILE_POISONS), 1, 10, 5.6)) end, -- Time to stone target, always > 1 turn
	getEffect = function(self, t) return math.floor(self:combatTalentScale(self:getTalentLevel(self.T_VILE_POISONS), 3, 4)) end,
	on_learn = function(self, t)
		table.set(self, "__show_special_talents", t.id, true)
	end,
	on_unlearn = function(self, t)
		table.set(self, "__show_special_talents", t.id, false)
	end,
	proc = function(self, t, target, weapon) -- apply when applying other poisons with the Apply Poison talent
		local dam = t.getDOT(self, t)
		if target:hasEffect(target.EFF_STONED) then return end
		target:setEffect(target.EFF_STONE_POISON, t.getDuration(self, t), {src=self, power=dam, max_power=dam*4, stone=t.getEffect(self, t), time_to_stone = t.stoneTime(self, t)})
	end,
	activate = function(self, t)
		cancelPoisons(self)
		self.vile_poisons = self.vile_poisons or {}
		self.vile_poisons[t.id] = true
		return {}
	end,
	deactivate = function(self, t, p)
		self.vile_poisons[t.id] = nil
		return true
	end,
	info = function(self, t)
		local dam = damDesc(self, DamageType.NATURE, t.getDOT(self, t))
		return ([[Enhance your Deadly Poison with a stoning agent.  Whenever you apply Deadly Poison, you afflict your target with an additional earth-based poison that inflicts %d nature damage per turn (stacking up to %d damage per turn) for %d turns.
		After either %d turns or the poison has run its course (<100%% chance, see effect description), the target will be turned to stone for %d turns.
		The damage scales with your Cunning.]]):
		format(dam, dam*4, t.getDuration(self, t), t.stoneTime(self, t), t.getEffect(self, t))
	end,
}
