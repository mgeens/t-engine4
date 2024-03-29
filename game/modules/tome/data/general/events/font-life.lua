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

-- Find a random spot
local x, y = game.state:findEventGrid(level)
if not x then return false end

local on_stand = function(self, x, y, who) who:setEffect(who.EFF_FONT_OF_LIFE, 1, {}) end
local g = game.level.map(x, y, engine.Map.TERRAIN):cloneFull()
g.name = "font of life"
g.display='&' g.color_r=0 g.color_g=255 g.color_b=0 g.notice = true
g.special_minimap = colors.OLIVE_DRAB
g.on_stand = on_stand
g:removeAllMOs()
if engine.Map.tiles.nicer_tiles then
	g.add_displays = g.add_displays or {}
	g.add_displays[#g.add_displays+1] = mod.class.Grid.new{image="terrain/terrain_pot_03_01_64.png", z=5}
end
g:altered()
game.zone:addEntity(game.level, g, "terrain", x, y)

if core.shader.active(4) then
	level.map:particleEmitter(x, y, 2, "shader_ring_rotating", {rotation=0, radius=4}, {type="flames", aam=0.5, zoom=3, npow=4, time_factor=4000, color1={0.2,0.7,0,1}, color2={0,1,0.3,1}, hide_center=0})
else
	level.map:particleEmitter(x, y, 2, "ultrashield", {rm=0, rM=0, gm=180, gM=220, bm=10, bM=80, am=220, aM=250, radius=2, density=1, life=14, instop=17})
end

local grids = core.fov.circle_grids(x, y, 2, function(_, lx, ly) return not game.state:canEventGrid(level, lx, ly) end)
for x, yy in pairs(grids) do for y, _ in pairs(yy) do
	local g = game.level.map(x, y, engine.Map.TERRAIN):cloneFull()
	g.on_stand = g.on_stand or on_stand
	if g.on_stand == on_stand and g.type == "floor" then
		g.name = g.name .. " (life aura)"
		if not g.special_minimap then g.special_minimap = colors.AQUAMARINE end
	end
	g.always_remember = true
	g.on_stand_safe = true
	game.zone:addEntity(game.level, g, "terrain", x, y)
end end
print("[EVENT] font-life centered at ", x, y)
return true
