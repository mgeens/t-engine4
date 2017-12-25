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

if mode == "steam" then

return {
	id = "VAULT_SPACE",
	name = "Storage Vault Space (+2)",
	image = "/data/gfx/shockbolt/terrain/padlock2.png",
	desc = [[Unsure what to do with your huge collection of coins?
Feeling a bit tight on the online vault storage?

For every of purchase of a DLC or on the online store you also gain a new free vault slot for 2€ of purchased value.]],

	price = 10,
	multi_pruchase = true,
}

else

return {
	id = "VAULT_SPACE",
	name = "Storage Vault Space (+2)",
	image = "/data/gfx/shockbolt/terrain/padlock2.png",
	desc = [[Unsure what to do with your huge collection of coins?
Feeling a bit tight on the online vault storage?

Remember that for every 2 euro of donations you also gain a new free vault slot.]],

	price = 10,
	multi_pruchase = true,
}

end
