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

uberTalent{
	name = "Spectral Shield",
	not_listed = true,  -- Functionality was baselined on shields
	mode = "passive",
	require = { special={desc="Know the Block talent, have cast 100 spells, and have a block value over 200", fct=function(self)
		return self:knowTalent(self.T_BLOCK) and self:getTalentFromId(self.T_BLOCK).getBlockValue(self) >= 200 and self.talent_kind_log and self.talent_kind_log.spell and self.talent_kind_log.spell >= 100
	end} },
	on_learn = function(self, t)
		self:attr("spectral_shield", 1)
	end,
	on_unlearn = function(self, t)
		self:attr("spectral_shield", -1)
	end,
	info = function(self, t)
		return ([[By infusing your shield with raw magic, your block can now block any damage type.]])
		:format()
	end,
}

-- Re-used icon
uberTalent{
	name = "Ethereal Form", image = "talents/displace_damage.png",
	mode = "passive",
	require = { special={desc="Have an effective defense of at least 40", fct=function(self)
		if self:combatDefense() >= 40 then return true end
	end} },
	passives = function(self, t, tmptable)
		self:talentTemporaryValue(tmptable, "resists_pen", {all = 25})
		self:talentTemporaryValue(tmptable, "resists", {absolute = 25})
		self:talentTemporaryValue(tmptable, "combat_def", math.max(self:getMag(), self:getDex()) * 0.7)
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if (stat == self.STAT_MAG) or (stat == self.STAT_DEX) then
			self:updateTalentPassives(t)
		end
	end,
	callbackOnMeleeHit = function(self, t, src, dam)
		self:setEffect(self.EFF_ETHEREAL_FORM, 8, {})
	end,
	callbackOnArcheryHit = function(self, t, src, dam)
		self:setEffect(self.EFF_ETHEREAL_FORM, 8, {})
	end,
	info = function(self, t)
		return ([[You gain 25%% absolute damage resistance and 25%% all damage penetration.  Each time you are struck by a weapon these bonuses are reduced by 5%% but fully recovered after 8 turns.
			Additionally, you gain 70%% of the highest of your Magic or Dexterity stat as defense (%d)]])
		:format(math.max(self:getMag(), self:getDex()) * 0.7)
	end,
}

uberTalent{
	name = "Aether Permeation",
	mode = "passive",
	require = { special={desc="Have at least 25% arcane damage reduction and have been exposed to the void of space", fct=function(self)
		return (game.state.birth.ignore_prodigies_special_reqs or self:attr("planetary_orbit")) and self:combatGetResist(DamageType.ARCANE) >= 25
	end} },
	cant_steal = true,
	on_learn = function(self, t)
		local ret = {}
		self:talentTemporaryValue(ret, "force_use_resist", DamageType.ARCANE)
		self:talentTemporaryValue(ret, "force_use_resist_percent", 66)
		self:talentTemporaryValue(ret, "resists", {[DamageType.ARCANE] = 20})
		self:talentTemporaryValue(ret, "resists_cap", {[DamageType.ARCANE] = 10})
		return ret
	end,
	on_unlearn = function(self, t)
	end,
	info = function(self, t)
		return ([[You manifest a thin layer of aether all around you. Any attack passing through it will check arcane resistance instead of the incoming damage resistance.
		In effect, all of your resistances are equal to 66%% of your arcane resistance, which is increased by 20%% (and cap increased by 10%%).]])
		:format()
	end,
}

uberTalent{
	name = "Mystical Cunning", image = "talents/vulnerability_poison.png",
	mode = "passive",
	require = { special={desc="Know how to either prepare traps or apply poisons", fct=function(self)
		return self:knowTalent(self.T_APPLY_POISON) or self:knowTalent(self.T_TRAP_MASTERY)
	end} },
	autolearn_talent = {Talents.T_VULNERABILITY_POISON, Talents.T_GRAVITIC_TRAP}, -- requires uber.lua loaded last
	passives = function(self, t, tmptable)
		self:talentTemporaryValue(tmptable, "talents_types_mastery", {["cunning/trapping"] = 1})
		self:talentTemporaryValue(tmptable, "talents_types_mastery", {["cunning/poisons"] = 1})
		self:talentTemporaryValue(tmptable, "talent_cd_reduction", {[Talents.T_VENOMOUS_STRIKE] = 3})
		self:talentTemporaryValue(tmptable, "talent_cd_reduction", {[Talents.T_LURE] = 5})
	end,
	info = function(self, t)
		local descs = ""
		for i, tid in pairs(t.autolearn_talent) do
			local bonus_t = self:getTalentFromId(tid)
			if bonus_t then
				descs = ("%s\n#YELLOW#%s#LAST#\n%s\n"):format(descs, bonus_t.name, self:callTalent(bonus_t.id, "info"))
			end
		end
		return ([[Your study of arcane forces has let you develop a new way of applying your aptitude for trapping and poisons.

		You gain 1.0 mastery in the Cunning/Poisons and Cunning/Trapping talent trees.
		Your Venomous Strike talent cooldown is reduced by 3.
		Your Lure talent cooldown is reduced by 5.

		You learn the following talents:
%s]])
		:format(descs)
	end,
}

uberTalent{
	name = "Arcane Might",
	mode = "passive",
	info = function(self, t)
		return ([[You have learned to harness your latent arcane powers, channeling them through your weapon.
		This has the following effects:
		Equipped weapons are treated as having an additional 50%% Magic modifier;
		Your raw Physical Power is increased by 100%% of your raw Spellpower;
		Your physical critical chance is increased by 25%% of your bonus spell critical chance.]])
		:format()
	end,
}

uberTalent{
	name = "Temporal Form",
	cooldown = 30,
	require = { special={desc="Have cast over 1000 spells and visited a zone outside of time", fct=function(self) return
		self.talent_kind_log and self.talent_kind_log.spell and self.talent_kind_log.spell >= 1000 and (game.state.birth.ignore_prodigies_special_reqs or self:attr("temporal_touched"))
	end} },
	no_energy = true,
	is_spell = true,
	requires_target = true,
	range = 10,
	tactical = { DEFEND = 2, BUFF = 2 },
	action = function(self, t)
		self:setEffect(self.EFF_TEMPORAL_FORM, 10, {})
		return true
	end,
	info = function(self, t)
		return ([[You can wrap temporal threads around you, assuming the form of a telugoroth for 10 turns.
		While in this form you gain pinning, bleeding, blindness and stun immunity, 30%% temporal resistance, your temporal damage bonus is set to your current highest damage bonus + 30%%, 50%% of the damage you deal becomes temporal, and you gain 20%% temporal resistance penetration.
		You also are able to cast anomalies: Anomaly Rearrange, Anomaly Temporal Storm, Anomaly Flawed Design, Anomaly Gravity Pull and Anomaly Wormhole.]])
		:format()
	end,
}

uberTalent{
	name = "Blighted Summoning",
	mode = "passive",
	require = { special={desc="Have summoned at least 100 creatures affected by this talent. More permanent summons may count for more than 1.", fct=function(self)
		return self:attr("summoned_times") and self:attr("summoned_times") >= 100
	end} },
	cant_steal = true,
	-- Give the bonus to all summons immediately
	on_learn = function(self, t)
		if game.party and game.party:hasMember(self) and game.party.members then
			for act, def in pairs(game.party.members) do
				if act ~= self and act.summoner == self and not act.is_blighted_summon then
					act:incIncStat("mag", self:getMag())
					act:addTemporaryValue("all_damage_convert", DamageType.BLIGHT)
					act:addTemporaryValue("all_damage_convert_percent", 50)
					act:incVim(act:getMaxVim())
					if not act:knowTalent(act.T_BONE_SHIELD) then
						act:learnTalent(act.T_BONE_SHIELD, true, 3, {no_unlearn=true})
						act:forceUseTalent(act.T_BONE_SHIELD, {ignore_energy=true})
					end
					if not act:knowTalent(act.T_VIRULENT_DISEASE) then
						act:learnTalent(act.T_VIRULENT_DISEASE, true, 3, {no_unlearn=true})
					end
					act.is_blighted_summon = true
				end
			end
		end
	end,
	-- Called by addedToLevel to Actor.lua
	doBlightedSummon = function(self, t, who)
		if who.is_blighted_summon or not self:knowTalent(self.T_BLIGHTED_SUMMONING) then return false end
		who:incIncStat("mag", self:getMag())
		who:incVim(who:getMaxVim())
		who:addTemporaryValue("all_damage_convert", DamageType.BLIGHT)
		who:addTemporaryValue("all_damage_convert_percent", 50)
		if not who:knowTalent(who.T_BONE_SHIELD) then
			who:learnTalent(who.T_BONE_SHIELD, true, 3, {no_unlearn=true})
			who:forceUseTalent(who.T_BONE_SHIELD, {ignore_energy=true})
		end
		if not who:knowTalent(who.T_VIRULENT_DISEASE) then
			who:learnTalent(who.T_VIRULENT_DISEASE, true, 3, {no_unlearn=true})
		end
		who.is_blighted_summon = true
	end,
	info = function(self, t)
		return ([[You infuse blighted energies into all of your summons, granting them Bone Shield and Virulent Disease at talent level 3 and causing 50%% of their damage to be converted to Blight.
		Your summons gain a bonus to Magic equal to yours.
		]]):format()
	end,
}

uberTalent{
	name = "Revisionist History",
	cooldown = 30,
	no_energy = true,
	is_spell = true,
	no_npc_use = true,
	require = { special={desc="Have time-travelled at least once", fct=function(self) return game.state.birth.ignore_prodigies_special_reqs or (self:attr("time_travel_times") and self:attr("time_travel_times") >= 1) end} },
	action = function(self, t)
		if game._chronoworlds and game._chronoworlds.revisionist_history then
			self:hasEffect(self.EFF_REVISIONIST_HISTORY).back_in_time = true
			self:removeEffect(self.EFF_REVISIONIST_HISTORY)
			return nil -- the effect removal starts the cooldown
		end

		if checkTimeline(self) == true then return end

		game:onTickEnd(function()
			game:chronoClone("revisionist_history")
			self:setEffect(self.EFF_REVISIONIST_HISTORY, 19, {})
		end)
		return nil -- We do not start the cooldown!
	end,
	info = function(self, t)
		return ([[You can now control the recent past. Upon using this prodigy you gain a temporal effect for 20 turns.
		While this effect holds you can use the prodigy again to rewrite history.
		This prodigy splits the timeline. Attempting to use another spell that also splits the timeline while this effect is active will be unsuccessful.]])
		:format()
	end,
}
newTalent{
	name = "Unfold History", short_name = "REVISIONIST_HISTORY_BACK",
	type = {"uber/other",1},
	cooldown = 30,
	no_energy = true,
	is_spell = true,
	no_npc_use = true,
	action = function(self, t)
		if game._chronoworlds and game._chronoworlds.revisionist_history then
			self:hasEffect(self.EFF_REVISIONIST_HISTORY).back_in_time = true
			self:removeEffect(self.EFF_REVISIONIST_HISTORY)
			return nil -- the effect removal starts the cooldown
		end
		return nil -- We do not start the cooldown!
	end,
	info = function(self, t)
		return ([[Rewrite the recent past to go back to when you cast Revisionist History.]])
		:format()
	end,
}

uberTalent{
	name = "Cauterize",
	mode = "passive",
	cooldown = 12,
	require = { special={desc="Have received at least 7500 fire damage and have cast at least 1000 spells", fct=function(self) return
		self.talent_kind_log and self.talent_kind_log.spell and self.talent_kind_log.spell >= 1000 and self.damage_intake_log and self.damage_intake_log[DamageType.FIRE] and self.damage_intake_log[DamageType.FIRE] >= 7500
	end} },
	trigger = function(self, t, value)
		self:startTalentCooldown(t)

		if self.player then world:gainAchievement("AVOID_DEATH", self) end
		self:setEffect(self.EFF_CAUTERIZE, 8, {dam=value/10})
		return true
	end,
	info = function(self, t)
		return ([[Your inner flame is strong. Each time that you receive a blow that would kill you, your body is wreathed in flames.
		The flames will cauterize the wound, fully absorbing all damage done this turn, but they will continue to burn for 8 turns.
		Each turn 10% of the damage absorbed will be dealt by the flames. This will bypass resistance and affinity.
		Warning: this has a cooldown.]])
	end,
}
