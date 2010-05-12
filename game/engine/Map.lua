-- TE4 - T-Engine 4
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
local Entity = require "engine.Entity"
local Tiles = require "engine.Tiles"
local Faction = require "engine.Faction"
local DamageType = require "engine.DamageType"

--- Represents a level map, handles display and various low level map work
module(..., package.seeall, class.make)

--- The place of a terrain entity in a map grid
TERRAIN = 1
--- The place of a terrain entity in a map grid
TRAP = 50
--- The place of an actor entity in a map grid
ACTOR = 100
--- The place of an object entity in a map grid
OBJECT = 1000

--- The order of display for grid seen
searchOrder = { TERRAIN, TRAP, OBJECT, ACTOR }

color_shown   = { 1, 1, 1, 1 }
color_obscure = { 0.6, 0.6, 0.6, 1 }

--- Sets the viewport size
-- Static
-- @param x screen coordonate where the map will be displayed (this has no impact on the real display). This is used to compute mouse clicks
-- @param y screen coordonate where the map will be displayed (this has no impact on the real display). This is used to compute mouse clicks
-- @param w width
-- @param h height
-- @param tile_w width of a single tile
-- @param tile_h height of a single tile
-- @param fontname font parameters, can be nil
-- @param fontsize font parameters, can be nil
function _M:setViewPort(x, y, w, h, tile_w, tile_h, fontname, fontsize, multidisplay)
	self.multidisplay = multidisplay
	self.display_x, self.display_y = math.floor(x), math.floor(y)
	self.viewport = {width=math.floor(w), height=math.floor(h), mwidth=math.floor(w/tile_w), mheight=math.floor(h/tile_h)}
	self.tile_w, self.tile_h = tile_w, tile_h
	self.fontname, self.fontsize = fontname, fontsize
	self:resetTiles()
end

--- Defines the "obscure" factor of unseen map
-- By default it is 0.6, 0.6, 0.6, 1
function _M:setObscure(r, g, b, a)
	self.color_obscure = {r, g, b, a}
	-- If we are used on a real map, set it localy
	if self._map then self._map:setObscure(unpack(self.color_obscure)) end
end

--- Defines the "shown" factor of seen map
-- By default it is 1, 1, 1, 1
function _M:setShown(r, g, b, a)
	self.color_shown= {r, g, b, a}
	-- If we are used on a real map, set it localy
	if self._map then self._map:setShown(unpack(self.color_shown)) end
end

--- Create the tile repositories
function _M:resetTiles()
	self.tiles = Tiles.new(self.tile_w, self.tile_h, self.fontname, self.fontsize, true)
	self.tilesSurface = Tiles.new(self.tile_w, self.tile_h, self.fontname, self.fontsize, false)
end

--- Defines the faction of the person seeing the map
-- Usualy this will be the player's faction. If you do not want to use tactical display, dont use it
function _M:setViewerFaction(faction, friend, neutral, enemy)
	self.view_faction = faction
	self.faction_friend = "tactical_friend.png"
	self.faction_neutral = "tactical_neutral.png"
	self.faction_enemy = "tactical_enemy.png"
end

--- Defines the actor that sees the map
-- Usualy this will be the player. This is used to determine invisibility/...
function _M:setViewerActor(player)
	self.actor_player = player
end

--- Creates a map
-- @param w width (in grids)
-- @param h height (in grids)
function _M:init(w, h)
	self.mx = 0
	self.my = 0
	self.w, self.h = w, h
	self.map = {}
	self.lites = {}
	self.seens = {}
	self.remembers = {}
	self.effects = {}
	for i = 0, w * h - 1 do self.map[i] = {} end

	self:loaded()
end

--- Serialization
function _M:save()
	return class.save(self, {
		_map = true,
		_fovcache = true,
		surface = true,
		particle = true,
		particles = true,
	})
end
function _M:loaded()
	self.particles = {}
	self.particle = core.display.loadImage("/data/gfx/particle.png"):glTexture()

	self._map = core.map.newMap(self.w, self.h, self.mx, self.my, self.viewport.mwidth, self.viewport.mheight, self.tile_w, self.tile_h, self.multidisplay)
	self._map:setObscure(unpack(self.color_obscure))
	self._map:setShown(unpack(self.color_shown))
	self._fovcache =
	{
		block_sight = core.fov.newCache(self.w, self.h),
		block_esp = core.fov.newCache(self.w, self.h),
		block_sense = core.fov.newCache(self.w, self.h),
	}

	local mapseen = function(t, x, y, v)
		if x < 0 or y < 0 or x >= self.w or y >= self.h then return end
		if v ~= nil then
			t[x + y * self.w] = v
			self._map:setSeen(x, y, v)
			self.changed = true
		end
		return t[x + y * self.w]
	end
	local mapremember = function(t, x, y, v)
		if x < 0 or y < 0 or x >= self.w or y >= self.h then return end
		if v ~= nil then
			t[x + y * self.w] = v
			self._map:setRemember(x, y, v)
			self.changed = true
		end
		return t[x + y * self.w]
	end
	local maplite = function(t, x, y, v)
		if x < 0 or y < 0 or x >= self.w or y >= self.h then return end
		if v ~= nil then
			t[x + y * self.w] = v
			self._map:setLite(x, y, v)
			self.changed = true
		end
		return t[x + y * self.w]
	end

	getmetatable(self).__call = _M.call
	setmetatable(self.lites, {__call = maplite})
	setmetatable(self.seens, {__call = mapseen})
	setmetatable(self.remembers, {__call = mapremember})

	self.surface = core.display.newSurface(self.viewport.width, self.viewport.height)
	self.changed = true
	self.finished = true

	self:redisplay()
end

--- Recreate the internal map using new dimensions
function _M:recreate()
	self._map = core.map.newMap(self.w, self.h, self.mx, self.my, self.viewport.mwidth, self.viewport.mheight, self.tile_w, self.tile_h, self.multidisplay)
	self.changed = true
	self:redisplay()
end

--- Redisplays the map, storing seen information
function _M:redisplay()
	for i = 0, self.w - 1 do for j = 0, self.h - 1 do
		self._map:setSeen(i, j, self.seens(i, j))
		self._map:setRemember(i, j, self.remembers(i, j))
		self._map:setLite(i, j, self.lites(i, j))
		self:updateMap(i, j)
	end end
end

--- Closes things in the object to allow it to be garbage collected
-- Map objects are NOT automatically garbage collected because they contain FOV C structure, which themselves have a reference
-- to the map. Cyclic references! BAD BAD BAD !<br/>
-- The closing should be handled automatically by the Zone class so no bother for authors
function _M:close()
end

--- Cleans the FOV infos (seens table)
function _M:cleanFOV()
	if not self.clean_fov then return end
	self.clean_fov = false
	for i = 0, self.w * self.h - 1 do self.seens[i] = nil end
	self._map:cleanSeen()
end

function _M:updateMap(x, y)
	local g = self(x, y, TERRAIN)
	local o = self(x, y, OBJECT)
	local a = self(x, y, ACTOR)
	local t = self(x, y, TRAP)

	if g then g = self.tiles:get(g.display, g.color_r, g.color_g, g.color_b, g.color_br, g.color_bg, g.color_bb, g.image) end
	if t then
		-- Handles invisibility and telepathy and other such things
		if not self.actor_player or t:knownBy(self.actor_player) then
			t = self.tiles:get(t.display, t.color_r, t.color_g, t.color_b, t.color_br, t.color_bg, t.color_bb, t.image)
		else
			t = nil
		end
	end
	if o then o = self.tiles:get(o.display, o.color_r, o.color_g, o.color_b, o.color_br, o.color_bg, o.color_bb, o.image) end
	if a then
		-- Handles invisibility and telepathy and other such things
		if not self.actor_player or self.actor_player:canSee(a) then
			a = self.tiles:get(a.display, a.color_r, a.color_g, a.color_b, a.color_br, a.color_bg, a.color_bb, a.image)
		else
			a = nil
		end
	end

	self._map:setGrid(x, y, g, t, o, a)

	if self:checkAllEntities(x, y, "block_sight", self.actor_player) then self._fovcache.block_sight:set(x, y, true)
	else self._fovcache.block_sight:set(x, y, false) end
	if self:checkAllEntities(x, y, "block_esp", self.actor_player) then self._fovcache.block_esp:set(x, y, true)
	else self._fovcache.block_esp:set(x, y, false) end
	if self:checkAllEntities(x, y, "block_sense", self.actor_player) then self._fovcache.block_sense:set(x, y, true)
	else self._fovcache.block_sense:set(x, y, false) end
end

--- Sets/gets a value from the map
-- It is defined as the function metamethod, so one can simply do: mymap(x, y, Map.TERRAIN)
-- @param x position
-- @param y position
-- @param pos what kind of entity to set(Map.TERRAIN, Map.OBJECT, Map.ACTOR)
-- @param entity the entity to set, if null it will return the current one
function _M:call(x, y, pos, entity)
	if x < 0 or y < 0 or x >= self.w or y >= self.h then return end
	if entity then
		self.map[x + y * self.w][pos] = entity
		self.changed = true

		self:updateMap(x, y)
	else
		if self.map[x + y * self.w] then
			if not pos then
				return self.map[x + y * self.w]
			else
				return self.map[x + y * self.w][pos]
			end
		end
	end
end

--- Removes an entity
-- @param x position
-- @param y position
-- @param pos what kind of entity to set(Map.TERRAIN, Map.OBJECT, Map.ACTOR)
function _M:remove(x, y, pos)
	if self.map[x + y * self.w] then
		self.map[x + y * self.w][pos] = nil
		self:updateMap(x, y)
		self.changed = true
	end
end

--- Displays the map on a surface
-- @return a surface containing the drawn map
function _M:display()
	self._map:toScreen(self.display_x, self.display_y)

	-- Tactical display
	if self.view_faction then
		local e
		local z
		local friend
		for i = self.mx, self.mx + self.viewport.mwidth - 1 do
		for j = self.my, self.my + self.viewport.mheight - 1 do
			local z = i + j * self.w

			if self.seens[z] then
				e = self(i, j, ACTOR)
				if e and (not self.actor_player or self.actor_player:canSee(e)) then
					-- Tactical overlay ?
					if e.faction then
						friend = Faction:factionReaction(self.view_faction, e.faction)
						if friend > 0 then
							self.tiles:get(nil, 0,0,0, 0,0,0, self.faction_friend):toScreen(self.display_x + (i - self.mx) * self.tile_w, self.display_y + (j - self.my) * self.tile_h, self.tile_w, self.tile_h)
						elseif friend < 0 then
							self.tiles:get(nil, 0,0,0, 0,0,0, self.faction_enemy):toScreen(self.display_x + (i - self.mx) * self.tile_w, self.display_y + (j - self.my) * self.tile_h, self.tile_w, self.tile_h)
						else
							self.tiles:get(nil, 0,0,0, 0,0,0, self.faction_neutral):toScreen(self.display_x + (i - self.mx) * self.tile_w, self.display_y + (j - self.my) * self.tile_h, self.tile_w, self.tile_h)
						end
					end
				end
			end
		end end
	end

	self:displayParticles()
	self:displayEffects()

	-- If nothing changed, return the same surface as before
	if not self.changed then return end
	self.changed = false
	self.clean_fov = true
end

--- Sets checks if a grid lets sigth pass through
-- Used by FOV code
function _M:opaque(x, y)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return false end
	local e = self(x, y, TERRAIN)
	if e and e:check("block_sight") then return true end
end

--- Sets checks if a grid lets ESP pass through
-- Used by FOV ESP code
function _M:opaqueESP(x, y)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return false end
	local e = self(x, y, TERRAIN)
	if e and e:check("block_esp") then return true end
end

--- Sets a grid as seen and remembered
-- Used by FOV code
function _M:apply(x, y)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	if self.lites[x + y * self.w] then
		self.seens[x + y * self.w] = true
		self._map:setSeen(x, y, true)
		self.remembers[x + y * self.w] = true
		self._map:setRemember(x, y, true)
	end
end

--- Sets a grid as seen, lited and remembered
-- Used by FOV code
function _M:applyLite(x, y)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	if self.lites[x + y * self.w] or self:checkEntity(x, y, TERRAIN, "always_remember") then
		self.remembers[x + y * self.w] = true
		self._map:setRemember(x, y, true)
	end
	self.seens[x + y * self.w] = true
	self._map:setSeen(x, y, true)
end

--- Sets a grid as seen if ESP'ed
-- Used by FOV code
function _M:applyESP(x, y)
	if not self.actor_player then return end
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	local a = self(x, y, ACTOR)
	if a and self.actor_player:canSee(a, false, 0) then
		self.seens[x + y * self.w] = true
		self._map:setSeen(x, y, true)
	end
end

--- Check all entities of the grid for a property
-- @param x position
-- @param y position
-- @param what property to check
function _M:checkAllEntities(x, y, what, ...)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	if self.map[x + y * self.w] then
		for _, e in pairs(self.map[x + y * self.w]) do
			local p = e:check(what, x, y, ...)
			if p then return p end
		end
	end
end

--- Check specified entity position of the grid for a property
-- @param x position
-- @param y position
-- @param pos entity position in the grid
-- @param what property to check
function _M:checkEntity(x, y, pos, what, ...)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return end
	if self.map[x + y * self.w] then
		if self.map[x + y * self.w][pos] then
			local p = self.map[x + y * self.w][pos]:check(what, x, y, ...)
			if p then return p end
		end
	end
end

--- Lite all grids
function _M:liteAll(x, y, w, h)
	for i = x, x + w - 1 do for j = y, y + h - 1 do
		self.lites(i, j, true)
	end end
end

--- Remember all grids
function _M:rememberAll(x, y, w, h)
	for i = x, x + w - 1 do for j = y, y + h - 1 do
		self.remembers(i, j, true)
	end end
end

--- Sets the current view area with the given coords at the center
function _M:centerViewAround(x, y)
	self.mx = x - math.floor(self.viewport.mwidth / 2)
	self.my = y - math.floor(self.viewport.mheight / 2)
	self.changed = true
	self:checkMapViewBounded()
end

--- Sets the current view area if x and y are out of bounds
function _M:moveViewSurround(x, y, marginx, marginy)
	if self.mx + marginx >= x or self.mx + self.viewport.mwidth - marginx <= x then
		self.mx = x - math.floor(self.viewport.mwidth / 2)
		self.changed = true
	end
	if self.my + marginy >= y or self.my + self.viewport.mheight - marginy <= y then
		self.my = y - math.floor(self.viewport.mheight / 2)
		self.changed = true
	end
	self:checkMapViewBounded()
end

--- Checks the map is bound to the screen (no "empty space" if the map is big enough)
function _M:checkMapViewBounded()
	if self.mx < 0 then self.mx = 0 self.changed = true end
	if self.my < 0 then self.my = 0 self.changed = true end
	if self.mx > self.w - self.viewport.mwidth then self.mx = self.w - self.viewport.mwidth self.changed = true end
	if self.my > self.h - self.viewport.mheight then self.my = self.h - self.viewport.mheight self.changed = true end

	-- Center if smaller than map viewport
	if self.w < self.viewport.mwidth then self.mx = math.floor((self.w - self.viewport.mwidth) / 2) end
	if self.h < self.viewport.mheight then self.my = math.floor((self.h - self.viewport.mheight) / 2) end

	self._map:setScroll(self.mx, self.my)
end

--- Gets the tile under the mouse
function _M:getMouseTile(mx, my)
--	if mx < self.display_x or my < self.display_y or mx >= self.display_x + self.viewport.width or my >= self.display_y + self.viewport.height then return end
	local tmx = math.floor((mx - self.display_x) / self.tile_w) + self.mx
	local tmy = math.floor((my - self.display_y) / self.tile_h) + self.my
	return tmx, tmy
end

--- Get the screen position corresponding to a tile
function _M:getTileToScreen(tx, ty)
	local x = (tx - self.mx) * self.tile_w + self.display_x
	local y = (ty - self.my) * self.tile_h + self.display_y
	return x, y
end

--- Checks the given coords to see if they are in bound
function _M:isBound(x, y)
	if x < 0 or x >= self.w or y < 0 or y >= self.h then return false end
	return true
end

--- Import a map into the current one
-- @param map the map to import
-- @param dx coordinate where to import it in the current map
-- @param dy coordinate where to import it in the current map
-- @param sx coordinate where to start importing the map, defaults to 0
-- @param sy coordinate where to start importing the map, defaults to 0
-- @param sw size of the imported map to get, defaults to map size
-- @param sh size of the imported map to get, defaults to map size
function _M:import(map, dx, dy, sx, sy, sw, sh)
	sx = sx or 0
	sy = sy or 0
	sw = sw or map.w
	sh = sh or map.h

	for i = sx, sx + sw - 1 do for j = sy, sy + sh - 1 do
		local x, y = dx + i, dy + j
		self.map[x + y * self.w] = map.map[i + j * map.w]

		self.remembers(x, y, map.remembers(i, j))
		self.seens(x, y, map.seens(i, j))
		self.lites(x, y, map.lites(i, j))

		self:updateMap(x, y)
	end end
	self.changed = true
end

--- Adds a zone (temporary) effect
-- @param src the source actor
-- @param x the epicenter coords
-- @param y the epicenter coords
-- @param duration the number of turns to persist
-- @param damtype the DamageType to apply
-- @param radius the radius of the effect
-- @param dir the numpad direction of the effect, 5 for a ball effect
-- @param overlay a simple display entity to draw upon the map
-- @param update_fct optional function that will be called each time the effect is updated with the effect itself as parameter. Use it to change radius, move around ....
function _M:addEffect(src, x, y, duration, damtype, dam, radius, dir, angle, overlay, update_fct, friendlyfire)
	if friendlyfire == nil then friendlyfire = true end
	print(friendlyfire)
	table.insert(self.effects, {
		src=src, x=x, y=y, duration=duration, damtype=damtype, dam=dam, radius=radius, dir=dir, angle=angle, overlay=overlay,
		update_fct=update_fct, friendlyfire=friendlyfire
	})
	self.changed = true
end

--- Display the overlay effects, called by self:display()
function _M:displayEffects()
	for i, e in ipairs(self.effects) do
		-- Dont bother with obviously out of screen stuff
		if e.x + e.radius >= self.mx and e.x - e.radius < self.mx + self.viewport.mwidth and e.y + e.radius >= self.my and e.y - e.radius < self.my + self.viewport.mheight then
			local grids
			local s = self.tilesSurface:get(e.overlay.display, e.overlay.color_r, e.overlay.color_g, e.overlay.color_b, e.overlay.color_br, e.overlay.color_bg, e.overlay.color_bb, e.overlay.image, 120)

			-- Handle balls
			if e.dir == 5 then
				grids = core.fov.circle_grids(e.x, e.y, e.radius, true)
			-- Handle beams
			else
				grids = core.fov.beam_grids(e.x, e.y, e.radius, e.dir, e.angle, true)
			end

			-- Now display each grids
			for lx, ys in pairs(grids) do
				for ly, _ in pairs(ys) do
					if self.seens(lx, ly) then
						s:toScreen(self.display_x + (lx - self.mx) * self.tile_w, self.display_y + (ly - self.my) * self.tile_h)
					end
				end
			end
		end
	end
end

--- Process the overlay effects, call it from your tick function
function _M:processEffects()
	local todel = {}
	for i, e in ipairs(self.effects) do
		local grids

		-- Handle balls
		if e.dir == 5 then
			grids = core.fov.circle_grids(e.x, e.y, e.radius, true)
		-- Handle beams
		else
			grids = core.fov.beam_grids(e.x, e.y, e.radius, e.dir, e.angle, true)
		end

		-- Now display each grids
		for lx, ys in pairs(grids) do
			for ly, _ in pairs(ys) do
				if e.friendlyfire or not (lx == e.src.x and ly == e.src.y) then
					DamageType:get(e.damtype).projector(e.src, lx, ly, e.damtype, e.dam)
				end
			end
		end

		e.duration = e.duration - 1
		if e.duration <= 0 then
			table.insert(todel, i)
		elseif e.update_fct then
			e:update_fct()
		end
	end

	for i = #todel, 1, -1 do table.remove(self.effects, todel[i]) end
end


-------------------------------------------------------------
-------------------------------------------------------------
-- Object functions
-------------------------------------------------------------
-------------------------------------------------------------
function _M:addObject(x, y, o)
	local i = self.OBJECT
	-- Find the first "hole"
	while self(x, y, i) do i = i + 1 end
	-- Fill it
	self(x, y, i, o)
	return true
end

function _M:getObject(x, y, i)
	-- Compute the map stack position
	i = i - 1 + self.OBJECT
	return self(x, y, i)
end

function _M:removeObject(x, y, i)
	-- Compute the map stack position
	i = i - 1 + self.OBJECT
	if not self(x, y, i) then return false end
	-- Remove it
	self:remove(x, y, i)
	-- Move the last one to its position, to never get a "hole"
	local j = i + 1
	while self(x, y, j) do j = j + 1 end
	j = j - 1
	-- If the removed one was not the last
	if j > i then
		local o = self(x, y, j)
		self:remove(x, y, j)
		self(x, y, i, o)
	end

	return true
end

-------------------------------------------------------------
-------------------------------------------------------------
-- Particle projector
-------------------------------------------------------------
-------------------------------------------------------------
_M.particles_def = {}

--- Add a new particle emitter
function _M:particleEmitter(x, y, radius, def, fct, max, args)
	if type(def) == "string" then
		if _M.particles_def[def] then
			def, fct, max = _M.particles_def[def]()
		else
			local odef = def
			print("[PARTICLE] Loading from /data/gfx/particles/"..def..".lua")
			local f = loadfile("/data/gfx/particles/"..def..".lua")
			setfenv(f, setmetatable(args or {}, {__index=_G}))
			def, fct, max = f()
			max = max or 1000
			_M.particles_def[odef] = f
		end
	end

	local e =
	{
		x = x, y = y, radius = radius or 1,
		ps = core.particles.newEmitter(max or 1000, def, self.particle),
		update = fct,
	}
	self.particles[#self.particles+1] = e
end

--- Display the particle emiters, called by self:display()
function _M:displayParticles()
	for i = #self.particles, 1, -1 do
		local e = self.particles[i]
		local alive = false

		alive = not e.update(e)

		-- Dont bother with obviously out of screen stuff
		if alive and e.x + e.radius >= self.mx and e.x - e.radius < self.mx + self.viewport.mwidth and e.y + e.radius >= self.my and e.y - e.radius < self.my + self.viewport.mheight then
			alive = e.ps:toScreen(self.display_x + (e.x - self.mx + 0.5) * self.tile_w, self.display_y + (e.y - self.my + 0.5) * self.tile_h, self.seens(e.x, e.y))
		end

		if not alive then
			table.remove(self.particles, i)
		end
	end
end
