-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012, 2013 Nicolas Casalini
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

load("/data/general/objects/objects-far-east.lua")
load("/data/general/objects/lore/sunwall.lua")
load("/data/general/objects/lore/orc-prides.lua")

newEntity{ base = "BASE_LORE",
	define_as = "NOTE_LORE",
	name = "draft note", lore="grushnak-pride-note",
	desc = [[A note.]],
	rarity = false,
	encumberance = 0,
}

for i = 1, 5 do
newEntity{ base = "BASE_LORE",
	define_as = "GARKUL_HISTORY"..i,
	name = "The Legend of Garkul", lore="garkul-history-"..i,
	desc = [[The Legend of Garkul the Devourer, mightiest of all orcs.]],
	rarity = false,
}
end
