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
require "engine.ui.Dialog"
local List = require "engine.ui.List"
local GetQuantity = require "engine.dialogs.GetQuantity"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init()
	self:generateList()
	engine.ui.Dialog.init(self, "DEBUG -- Change Zone", 1, 1)

	local list = List.new{width=400, height=500, scrollbar=true, list=self.list, fct=function(item) self:use(item) end}

	self:loadUI{
		{left=0, top=0, ui=list},
	}
	self:setupUI(true, true)

	self.key:addCommands{ __TEXTINPUT = function(c)
		for i = list.sel + 1, #self.list do
			local v = self.list[i]
			if v.name:sub(1, 1):lower() == c:lower() then list:select(i) return end
		end
		for i = 1, list.sel do
			local v = self.list[i]
			if v.name:sub(1, 1):lower() == c:lower() then list:select(i) return end
		end
	end}
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end,
		LUA_CONSOLE = function()
			if config.settings.cheat then
				local DebugConsole = require "engine.DebugConsole"
				game:registerDialog(DebugConsole.new())
			end
		end,}
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:use(item)
	if not item then return end
	game:unregisterDialog(self)

	game:registerDialog(GetQuantity.new("Zone: "..item.name, "Level "..item.min.."-"..item.max, 1, item.max, function(qty)
		game:changeLevel(qty, item.zone)
	end), 1)
end

function _M:generateList()
	local list = {}

	local function parse(base, add, add_simple)
		for i, dir in ipairs(fs.list(base.."/zones/")) do
			local f = loadfile(base.."/zones/"..dir.."/zone.lua")
			if f then
				setfenv(f, setmetatable({}, {__index=_G}))
				local ok, z = pcall(f)
				if ok then
					list[#list+1] = {name=z.name..(add_simple and " ["..add_simple.."]" or ""), zone=add..dir, min=1, max=z.max_level}
				end
			end
		end
	end

	parse("/data", "")
	for i, dir in ipairs(fs.list("/")) do
		local _, _, addon = dir:find("^data%-(.+)$")
		if addon then
			parse("/"..dir, addon.."+", addon)
		end
	end

	table.sort(list, function(a,b) return a.name < b.name end)

	local chars = {}
	for i, v in ipairs(list) do
		v.name = v.name
		chars[self:makeKeyChar(i)] = i
	end
	list.chars = chars

	self.list = list
end
