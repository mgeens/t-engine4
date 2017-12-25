-- TE4 - T-Engine 4
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

require "engine.class"
local Entity = require "engine.Entity"
local Dialog = require "engine.ui.Dialog"
local Image = require "engine.ui.Image"
local Textzone = require "engine.ui.Textzone"
local ListColumns = require "engine.ui.ListColumns"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(mode)
	if not mode then mode = core.steam and "steam" or "te4" end
	self.mode = mode

	Dialog.init(self, game.__mod_info.long_name.." #GOLD#Online Store", game.w * 0.8, game.h * 0.8)

	self:generateList()

	self.c_list = ListColumns.new{width=self.iw, height=self.ih, item_height=132, hide_columns=true, scrollbar=true, sortable=true, columns={
		{name="", width=100, display_prop="", direct_draw=function(item, x, y)
			item.img:toScreen(nil, x+2, y+2, 128, 128)
			item.txt:display(x+10+130, y+2 + (128 - item.txt.h) / 2, 0)
		end},
	}, list=self.list, fct=function(item) end, select=function(item, sel) end}


	self:loadUI{
		{left=0, top=0, ui=self.c_list},
	}
	self:setupUI(false, false)

	self.key:addBinds{
		ACCEPT = "EXIT",
		EXIT = function()
			game:unregisterDialog(self)
			if on_exit then on_exit() end
		end,
	}
end

function _M:generateList()
	local list = {}
	for file in fs.iterate("/data/microtxn/", "%.lua$") do
		local f, err = loadfile("/data/microtxn/"..file)
		setfenv(f, {mode=self.mode})
		local ok, res = pcall(f)
		if ok and res then
			res.img = Entity.new{image=res.image}
			res.txt = Textzone.new{width=self.iw - 10 - 132, auto_height=true, text=("%s\n#SLATE##{italic}#%s#{normal}#"):format(res.name, res.desc)}
			list[#list+1] = res
		end
	end
	self.list = list
end
