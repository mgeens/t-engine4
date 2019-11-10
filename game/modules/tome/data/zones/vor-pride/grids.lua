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

load("/data/general/grids/basic.lua", function(e)
	if e.define_as ~= "FLOOR" and e.image == "terrain/marble_floor.png" then
		e.image = "terrain/grass_burnt1.png"
	end
end)
load("/data/general/grids/forest.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/burntland.lua")

newEntity{
	define_as = "GENERIC_BOOK1", image = "terrain/marble_floor.png", add_mos = {{image="terrain/book_generic1.png"}},
	type = "floor", subtype = "floor",
	name = "book",
	display = '_', color_r=255, color_g=0, color_b=0,
	notice = true,
	always_remember = true,
}

newEntity{
	define_as = "GENERIC_BOOK2", image = "terrain/marble_floor.png", add_mos = {{image="terrain/book_generic2.png"}},
	type = "floor", subtype = "floor",
	name = "book",
	display = '_', color_r=255, color_g=0, color_b=0,
	notice = true,
	always_remember = true,
}

newEntity{
	define_as = "GENERIC_BOOK3", image = "terrain/marble_floor.png", add_mos = {{image="terrain/book_generic3.png"}},
	type = "floor", subtype = "floor",
	name = "book",
	display = '_', color_r=255, color_g=0, color_b=0,
	notice = true,
	always_remember = true,
}

newEntity{
	define_as = "CANDLE",
	type = "floor", subtype = "floor",
	name = "reading candle", image = "terrain/marble_floor.png",
	force_clone = true,
	display = ';', color=colors.GOLD,
	always_remember = true,
	nice_tiler = { method="replace", base={"CANDLE", 100, 1, 3}},
}
for i = 1, 3 do newEntity{base = "CANDLE", define_as = "CANDLE"..i, embed_particles = {{name="candle", rad=1, args={candle_id="light1"}}} } end


-- Convert all to gothic walls
local convert = {
	["terrain/granite_door1.png"] = "terrain/gothic_walls/granite_door1.png",
	["terrain/granite_door1_open.png"] = "terrain/gothic_walls/granite_door1_open.png",
	["terrain/granite_door1_open_vert.png"] = "terrain/gothic_walls/granite_door1_open_vert.png",
	["terrain/granite_door1_open_vert_north.png"] = "terrain/gothic_walls/granite_door1_open_vert_north.png",
	["terrain/granite_door1_vert.png"] = "terrain/gothic_walls/granite_door1_vert.png",
	["terrain/granite_door1_vert_north.png"] = "terrain/gothic_walls/granite_door1_vert_north.png",
	["terrain/granite_wall1_1.png"] = "terrain/gothic_walls/granite_wall1_1.png",
	["terrain/granite_wall1_2.png"] = "terrain/gothic_walls/granite_wall1_2.png",
	["terrain/granite_wall1_3.png"] = "terrain/gothic_walls/granite_wall1_3.png",
	["terrain/granite_wall1_4.png"] = "terrain/gothic_walls/granite_wall1_4.png",
	["terrain/granite_wall1_5.png"] = "terrain/gothic_walls/granite_wall1_5.png",
	["terrain/granite_wall2.png"] = "terrain/gothic_walls/granite_wall2.png",
	["terrain/granite_wall2_1.png"] = "terrain/gothic_walls/granite_wall2_1.png",
	["terrain/granite_wall2_2.png"] = "terrain/gothic_walls/granite_wall2_2.png",
	["terrain/granite_wall2_3.png"] = "terrain/gothic_walls/granite_wall2_3.png",
	["terrain/granite_wall2_4.png"] = "terrain/gothic_walls/granite_wall2_4.png",
	["terrain/granite_wall2_5.png"] = "terrain/gothic_walls/granite_wall2_5.png",
	["terrain/granite_wall2_6.png"] = "terrain/gothic_walls/granite_wall2_6.png",
	["terrain/granite_wall2_7.png"] = "terrain/gothic_walls/granite_wall2_7.png",
	["terrain/granite_wall2_8.png"] = "terrain/gothic_walls/granite_wall2_8.png",
	["terrain/granite_wall2_9.png"] = "terrain/gothic_walls/granite_wall2_9.png",
	["terrain/granite_wall2_10.png"] = "terrain/gothic_walls/granite_wall2_10.png",
	["terrain/granite_wall2_11.png"] = "terrain/gothic_walls/granite_wall2_11.png",
	["terrain/granite_wall2_12.png"] = "terrain/gothic_walls/granite_wall2_12.png",
	["terrain/granite_wall2_13.png"] = "terrain/gothic_walls/granite_wall2_13.png",
	["terrain/granite_wall2_14.png"] = "terrain/gothic_walls/granite_wall2_14.png",
	["terrain/granite_wall2_15.png"] = "terrain/gothic_walls/granite_wall2_15.png",
	["terrain/granite_wall2_16.png"] = "terrain/gothic_walls/granite_wall2_16.png",
	["terrain/granite_wall2_17.png"] = "terrain/gothic_walls/granite_wall2_17.png",
	["terrain/granite_wall3.png"] = "terrain/gothic_walls/granite_wall3.png",
	["terrain/granite_wall_pillar_1.png"] = "terrain/gothic_walls/granite_wall_pillar_1.png",
	["terrain/granite_wall_pillar_2.png"] = "terrain/gothic_walls/granite_wall_pillar_2.png",
	["terrain/granite_wall_pillar_7.png"] = "terrain/gothic_walls/granite_wall_pillar_7.png",
	["terrain/granite_wall_pillar_8.png"] = "terrain/gothic_walls/granite_wall_pillar_8.png",
	["terrain/granite_wall_pillar_9.png"] = "terrain/gothic_walls/granite_wall_pillar_9.png",
	["terrain/granite_wall_pillar_small.png"] = "terrain/gothic_walls/granite_wall_pillar_small.png",
	["terrain/granite_wall_pillar_small_top.png"] = "terrain/gothic_walls/granite_wall_pillar_small_top.png",
	["terrain/marble_floor.png"] = "terrain/gothic_walls/marble_floor.png",
	["terrain/granite_wall_pillar_3.png"] = "terrain/gothic_walls/granite_wall_pillar_3.png",
	["terrain/stair_down.png"] = "terrain/gothic_walls/stair_down.png",
	["terrain/stair_up.png"] = "terrain/gothic_walls/stair_up.png",
	["terrain/stair_up_wild.png"] = "terrain/gothic_walls/stair_up_wild.png",
}

for _, e in ipairs(loading_list) do
	if e.image and convert[e.image] then e.image = convert[e.image] end
	for i, mo in ipairs(e.add_mos or {}) do
		if mo.image and convert[mo.image] then mo.image = convert[mo.image] end
	end
	for i, ad in ipairs(e.add_displays or {}) do
		if ad.image and convert[ad.image] then ad.image = convert[ad.image] end
		for j, mo in ipairs(ad.add_mos or {}) do
			if mo.image and convert[mo.image] then mo.image = convert[mo.image] end
		end
	end
end
