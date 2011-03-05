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
local Store = require "engine.Store"
local Dialog = require "engine.ui.Dialog"

module(..., package.seeall, class.inherit(Store))

_M.stores_def = {}

function _M:loadStores(f)
	self.stores_def = self:loadList(f)
end

function _M:init(t, no_default)
	t.store.buy_percent = t.store.buy_percent or function(self, o) if o.type == "gem" then return 40 else return 15 end end
	t.store.sell_percent = t.store.sell_percent or function(self, o) return 100 + 2 * (o.__store_level or 0) end -- Stores prices goes up with item level
	t.store.purse = t.store.purse or 20
	Store.init(self, t, no_default)

	self.name = self.name .. (" (Max buy %0.2f gold)"):format(self.store.purse)

	if not self.store.actor_filter then
		self.store.actor_filter = function(o)
			return not o.quest and not o.lore and o.cost and o.cost > 0
		end
	end
end

--- Caleld when a new object is stocked
function _M:stocked_object(o)
	o.__store_level = game.zone.base_level + game.level.level - 1
end

--- Restock based on player level
function _M:canRestock()
	local s = self.store
	if self.last_filled and self.last_filled >= game.state.boss_killed - s.restock_every then
		print("[STORE] not restocking yet [bosses killed]", game.state.boss_killed, s.restock_every, self.last_filled)
		return false
	end
	return true
end

--- Fill the store with goods
-- @param level the level to generate for (instance of type engine.Level)
-- @param zone the zone to generate for
function _M:loadup(level, zone)
	if Store.loadup(self, level, zone) then
		self.last_filled = game.state.boss_killed
	end
end


--- Called on object purchase try
-- @param who the actor buying
-- @param o the object trying to be purchased
-- @param item the index in the inventory
-- @param nb number of items (if stacked) to buy
-- @return true if allowed to buy
function _M:tryBuy(who, o, item, nb)
	local price = self:getObjectPrice(o, "buy")
	if who.money >= price * nb then
		return nb, price * nb
	else
		Dialog:simplePopup("Not enough gold", "You do not have enough gold!")
	end
end

--- Called on object sale try
-- @param who the actor selling
-- @param o the object trying to be sold
-- @param item the index in the inventory
-- @param nb number of items (if stacked) to sell
-- @return true if allowed to sell
function _M:trySell(who, o, item, nb)
	local price = self:getObjectPrice(o, "sell")
	if price <= 0 or nb <= 0 then return end
	price = math.min(price * nb, self.store.purse * nb)
	return nb, price
end

--- Called on object purchase
-- @param who the actor buying
-- @param o the object trying to be purchased
-- @param item the index in the inventory
-- @param nb number of items (if stacked) to buy
-- @param before true if this happens before removing the item
-- @return true if allowed to buy
function _M:onBuy(who, o, item, nb, before)
	if before then return end
	local price = self:getObjectPrice(o, "buy")
	if who.money >= price * nb then
		who:incMoney(- price * nb)
	end
end

--- Called on object sale
-- @param who the actor selling
-- @param o the object trying to be sold
-- @param item the index in the inventory
-- @param nb number of items (if stacked) to sell
-- @param before true if this happens before removing the item
-- @return true if allowed to sell
function _M:onSell(who, o, item, nb, before)
	if before then o:identify(true) return end

	local price = self:getObjectPrice(o, "sell")
	if price <= 0 or nb <= 0 then return end
	price = math.min(price * nb, self.store.purse * nb)
	who:incMoney(price)
	o:forAllStack(function(so) so.__store_forget = true end) -- Make sure the store does never forget about it
end

--- Override the default
function _M:doBuy(who, o, item, nb, store_dialog)
	nb = math.min(nb, o:getNumber())
	local price
	nb, price = self:tryBuy(who, o, item, nb)
	if nb then
		Dialog:yesnoPopup("Buy", ("Buy %d %s for %0.2f gold"):format(nb, o:getName{do_color=true, no_count=true}, price), function(ok) if ok then
			self:onBuy(who, o, item, nb, true)
			-- Learn lore ?
			if who.player and o.lore then
				self:removeObject(self:getInven("INVEN"), item)
				who:learnLore(o.lore)
			else
				self:transfer(self, who, item, nb)
			end
			self:onBuy(who, o, item, nb, false)
			if store_dialog then store_dialog:updateStore() end
		end end, "Buy", "Cancel")
	end
end

--- Override the default
function _M:doSell(who, o, item, nb, store_dialog)
	nb = math.min(nb, o:getNumber())
	local price
	nb, price = self:trySell(who, o, item, nb)
	if nb then
		Dialog:yesnoPopup("Sell", ("Sell %d %s for %0.2f gold"):format(nb, o:getName{do_color=true, no_count=true}, price), function(ok) if ok then
			self:onSell(who, o, item, nb, true)
			self:transfer(who, self, item, nb)
			self:onSell(who, o, item, nb, false)
			if store_dialog then store_dialog:updateStore() end
		end end, "Sell", "Cancel")
	end
end

--- Called to describe an object, being to sell or to buy
-- @param who the actor
-- @param what either "sell" or "buy"
-- @param o the object
-- @return a string (possibly multiline) describing the object
function _M:descObject(who, what, o)
	if what == "buy" then
		local desc = tstring({"font", "bold"}, {"color", "GOLD"}, ("Buy for: %0.2f gold (You have %0.2f gold)"):format(self:getObjectPrice(o, "buy"), who.money), {"font", "normal"}, {"color", "LAST"}, true, true)
		desc:merge(o:getDesc())
		return desc
	else
		local desc = tstring({"font", "bold"}, {"color", "GOLD"}, ("Sell for: %0.2f gold (You have %0.2f gold)"):format(self:getObjectPrice(o, "sell"), who.money), {"font", "normal"}, {"color", "LAST"}, true, true)
		desc:merge(o:getDesc())
		return desc
	end
end

function _M:getObjectPrice(o, what)
	local v = o:getPrice() * util.getval(what == "buy" and self.store.sell_percent or self.store.buy_percent, self, o) / 100
	return math.ceil(v * 10) / 10
end

--- Called to describe an object's price, being to sell or to buy
-- @param who the actor
-- @param what either "sell" or "buy"
-- @param o the object
-- @return a string describing the price
function _M:descObjectPrice(who, what, o)
	return self:getObjectPrice(o, what), who.money
end

--- Actor interacts with the store
-- @param who the actor who interacts
function _M:interact(who)
	who:sortInven()
	Store.interact(self, who)
end

--- Display tooltips
function _M:on_select(item)
	if item.last_display_x then
		game.tooltip_x, game.tooltip_y = {}, 1
		game.tooltip:displayAtMap(nil, nil, item.last_display_x, item.last_display_y, item.desc)

		if not item.object or item.object.wielded then game.tooltip2_x = nil return end
		local winven = item.object:wornInven()
		winven = winven and game.player:getInven(winven)
		if not winven then game.tooltip2_x = nil return end

		local str = tstring{{"font", "bold"}, {"color", "GREY"}, "Currently equiped:", {"font", "normal"}, {"color", "LAST"}, true}
		local ok = false
		for i = 1, #winven do
			str:merge(winven[i]:getDesc())
			if i < #winven then str:add{true, "---", true} end
			ok = true
		end
		if ok then
			game.tooltip2_x, game.tooltip2_y = {}, 1
			game.tooltip2:displayAtMap(nil, nil, 1, item.last_display_y, str)
			game.tooltip2.last_display_x = game.tooltip.last_display_x - game.tooltip2.w
			last = item
		else
			game.tooltip2_x = nil
		end
	end
end
