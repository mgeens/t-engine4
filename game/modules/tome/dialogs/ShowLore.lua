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

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local ListColumns = require "engine.ui.ListColumns"
local Textbox = require "engine.ui.Textbox"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local Image = require "engine.ui.Image"
local LorePopup = require "mod.dialogs.LorePopup"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(title, actor)
	self.actor = actor
	local total = #actor.lore_defs + actor.additional_lore_nb
	local nb = 0
	for id, data in pairs(actor.lore_known) do nb = nb + 1 end

	Dialog.init(self, (title or "Lore").." ("..nb.."/"..total..")", game.w * 0.8, game.h * 0.8)

	local vsep = Separator.new{dir="horizontal", size=self.ih - 10}
	self.c_desc = TextzoneList.new{width=math.floor(self.iw / 2 - vsep.w / 2), scrollbar=true, height=self.ih}

	self:generateList()

	self.c_search = Textbox.new{title="Search: ", text="", chars=20, max_len=60, fct=function() end, on_change=function(text) self:search(text) end}

	self.c_list = ListColumns.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - 10 - self.c_search.h, scrollbar=true, sortable=true, columns={
		{name="", width={40,"fixed"}, display_prop="order", sort="order"},
		{name="Lore", width=60, display_prop="name", sort="name"},
		{name="Category", width=40, display_prop="cat", sort="cat"},
	}, list=self.list, fct=function(item) self:popup(item) end, select=function(item, sel) self:select(item) end}

	self:loadUI{
		{left=0, top=0, ui=self.c_search},
		{left=0, top=self.c_search, ui=self.c_list},
		{right=0, top=0, ui=self.c_desc},
		{hcenter=0, top=5, ui=vsep},
	}
	self:setFocus(self.c_list)
	self:setupUI()
	self:select(self.list[1])

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:search(text)
	if text == "" then self.search_filter = nil
	else self.search_filter = text end

	self:generateList()
end

function _M:matchSearch(name)
	if not self.search_filter then return true end
	return name:lower():find(self.search_filter:lower(), 1, 1)
end

function _M:generateList()
	-- Makes up the list
	local list = {}
	for id, _ in pairs(self.actor.lore_known) do
		local l = self.actor:getLore(id)
		if self:matchSearch(tostring(l.order)) or self:matchSearch(l.name) or self:matchSearch(l.category) then
			list[#list+1] = { name=l.name, desc=util.getval(l.lore), cat=l.category, order=l.order, image=l.image, lore=l }
		end
	end
	-- Add known artifacts
	table.sort(list, function(a, b) return a.order < b.order end)
	self.list = list
	if self.c_list then self.c_list:setList(list) end
end

function _M:popup(item)
	if item then
		LorePopup.new(item.lore, game.w * 0.6, 0.8)
	end
end

function _M:select(item)
	if item then
		self.c_desc:switchItem(item, ("#GOLD#Category:#AQUAMARINE# %s\n#GOLD#Found as:#0080FF# %s\n#GOLD#Text:#ANTIQUE_WHITE# %s"):format(item.cat, item.name, item.desc))
		if item.image then
			if type(item.image) == "string" then
				self.image = Image.new{file="lore/"..item.image, auto_width=true, auto_height=true}
				local r = self.image.w / self.image.h
				self.image.w = self.iw / 2 - 20
				self.image.h = self.image.w / r
				item.image = self.image
			else
				self.image = item.image
			end
		else
			self.image = nil
		end
	end
end

function _M:innerDisplay(x, y, nb_keyframes)
	if self.image then
		self.image:display(x + self.iw - self.image.w, y + self.ih - self.image.h)
	end
end
