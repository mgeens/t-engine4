-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2018 Nicolas Casalini
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
local lom = require "lxp.lom"
local mime = require "mime"

--- Base class to generate map-like
-- @classmod engine.tilemaps.Tilemap
module(..., package.seeall, class.make)

function _M:init(size, fill_with)
	if size then
		self.data_w = math.floor(size[1])
		self.data_h = math.floor(size[2])
		if self.data_w and self.data_h then
			self.data = self:makeData(self.data_w, self.data_h, fill_with or ' ')
		end
	end
end

function _M:getSize()
	return self.data_w, self.data_h
end

function _M:makeData(w, h, fill_with)
	local data = {}
	for y = 1, h do
		data[y] = {}
		for x = 1, w do
			data[y][x] = fill_with
		end
	end
	return data
end

local point_meta = {
	__add = function(a, b)
		if type(b) == "number" then return _M:point(a.x + b, a.y + b)
		else return _M:point(a.x + b.x, a.y + b.y) end
	end,
	__sub = function(a, b)
		if type(b) == "number" then return _M:point(a.x - b, a.y - b)
		else return _M:point(a.x - b.x, a.y - b.y) end
	end,
	__eq = function(a, b)
		return a.x == b.x and a.y == b.y
	end,
}
--- Make a point data, can be added
function _M:point(x, y)
	local p = {x=math.floor(x), y=math.floor(y)}
	setmetatable(p, point_meta)
	return p
end

--- Find all empty spaces (defaults to ' ') and fill them with a give char
function _M:fillAll(fill_with, empty_char)
	if not self.data then return end
	empty_char = empty_char or ' '
	fill_with = fill_with or '#'
	for y = 1, self.data_h do
		for x = 1, self.data_w do
			if self.data[y][x] == empty_char then
				self.data[y][x] = fill_with
			end
		end
	end
end

--- Check if the given coords are on the map
function _M:isBound(pos, y)
	if y then pos = self:point(pos, y) end
	if pos.x >= 1 and pos.x <= self.data_w and pos.y >=1 and pos.y <= self.data_h then
		return true
	else
		return false
	end
end

--- Draw a single tile
function _M:put(pos, char)
	if self:isBound(pos) then
		self.data[pos.y][pos.x] = char
	end
end

--- Flip the map
function _M:flip(axis)
	local ndata = self:makeData(self.data_w, self.data_h, '')
	for y = 1, self.data_h do
		for x = 1, self.data_w do
			local nx, ny = x, y
			if axis == "x" or axis == true then
				x = self.data_w - (x - 1)
			elseif axis == "y" or axis == false then
				y = self.data_h - (y - 1)
			end
			ndata[ny][nx] = self.data[y][x]
		end
	end
	self.data = ndata
	return self
end

--- Rotate the map
function _M:rotate(angle)
	local function rotate_coords(i, j)
		local ii, jj = i, j
		if angle == 90 then ii, jj = j, self.data_w - i + 1
		elseif angle == 180 then ii, jj = self.data_w - i + 1, self.data_h - j + 1
		elseif angle == 270 then ii, jj = self.data_h - j + 1, i
		end
		return ii, jj
	end

	local ndata_w, ndata_h = self.data_w, self.data_h
	if angle == 90 or angle == 270 then ndata_w, ndata_h = self.data_h, self.data_w end
	local ndata = self:makeData(ndata_w, ndata_h, '')
	for y = 1, self.data_h do
		for x = 1, self.data_w do
			local nx, ny = rotate_coords(x, y)
			ndata[ny][nx] = self.data[y][x]
		end
	end
	self.data = ndata
	self.data_w = ndata_w
	self.data_h = ndata_h
	return self
end

--- Widen the map
function _M:scale(sx, sy)
	local ndata = self:makeData(self.data_w * sx, self.data_h * sy, '')
	for y = 0, self.data_h - 1 do
		for x = 0, self.data_w - 1 do
			for nx = x * sx, x * sx + sx - 1 do
				for ny = y * sy, y * sy + sy - 1 do
					ndata[ny + 1][nx + 1] = self.data[y + 1][x + 1]
				end
			end
		end
	end
	self.data = ndata
	self.data_w, self.data_h = self.data_w * sx, self.data_h * sy
	return self
end

--- Used internally to load a tilemap from a tmx file
function _M:tmxLoad(file)
	local f = fs.open(file, "r") local data = f:read(10485760) f:close()
	local map = lom.parse(data)
	local mapprops = {}
	if map:findOne("properties") then mapprops = map:findOne("properties"):findAllAttrs("property", "name", "value") end
	self.props = mapprops

	local w, h = tonumber(map.attr.width), tonumber(map.attr.height)
	if mapprops.map_data then
		local params = self:loadLuaInEnv(g, nil, "return "..mapprops.map_data)
		table.merge(self.data, params, true)
	end

	local gids = {}

	for _, tileset in ipairs(map:findAll("tileset")) do
		local firstgid = tonumber(tileset.attr.firstgid)
		local has_tile = tileset:findOne("tile")
		for _, tile in ipairs(tileset:findAll("tile")) do
			local tileprops = {}
			if tile:findOne("properties") then tileprops = tile:findOne("properties"):findAllAttrs("property", "name", "value") end
			local gid = tonumber(tile.attr.id)
			gids[firstgid + gid] = {tid=tileprops.id or ' '}
		end
	end

	local data = {}
	for y = 1, h do
		data[y] = {}
		for x = 1, w do data[y][x] = ' ' end
	end

	local function populate(x, y, gid)
		if not gids[gid] then return end
		local g = gids[gid]
		data[y][x] = g.tid
	end

	for _, layer in ipairs(map:findAll("layer")) do
		local mapdata = layer:findOne("data")
		if mapdata.attr.encoding == "base64" then
			local b64 = mime.unb64(mapdata[1]:trim())
			local data
			if mapdata.attr.compression == "zlib" then data = zlib.decompress(b64)
			elseif not mapdata.attr.compression then data = b64
			else error("tmx map compression unsupported: "..mapdata.attr.compression)
			end
			local gid, i = nil, 1
			local x, y = 1, 1
			while i <= #data do
				gid, i = struct.unpack("<I4", data, i)				
				populate(x, y, gid)
				x = x + 1
				if x > w then x = 1 y = y + 1 end
			end
		elseif mapdata.attr.encoding == "csv" then
			local data = mapdata[1]:gsub("[^,0-9]", ""):split(",")
			local x, y = 1, 1
			for i, gid in ipairs(data) do
				gid = tonumber(gid)
				populate(x, y, gid)
				x = x + 1
				if x > w then x = 1 y = y + 1 end
			end
		elseif not mapdata.attr.encoding then
			local data = mapdata:findAll("tile")
			local x, y = 1, 1
			for i, tile in ipairs(data) do
				local gid = tonumber(tile.attr.gid)
				populate(x, y, gid)
				x = x + 1
				if x > w then x = 1 y = y + 1 end
			end
		end
	end
	return data, w, h
end

function _M:collapseToLineFormat(data)
	if not data then return nil end
	local ndata = {}
	for y = 1, #data do ndata[y] = table.concat(data[y]) end
	return ndata
end

--- Do we have results, or did we fail?
function _M:hasResult()
	return self.data and true or false
end

--- Locate a specific tile
function _M:locateTile(char, erase)
	local res = {}
	for i = 1, self.data_w do
		for j = 1, self.data_h do
			if self.data[j][i] == char then
				res[#res+1] = self:point(i, j)
				if erase then self.data[j][i] = erase end
			end
		end
	end
	if #res == 0 then return nil end
	return rng.table(res), res
end

--- Return a list of groups of tiles that matches the given cond function
function _M:findGroups(cond)
	if not self.data then return {} end

	local fills = {}
	local opens = {}
	local list = {}
	for i = 1, self.data_w do
		opens[i] = {}
		for j = 1, self.data_h do
			if cond(self.data[j][i]) then
				opens[i][j] = #list+1
				list[#list+1] = {x=i, y=j}
			end
		end
	end

	local nbg = 0
	local function floodFill(x, y)
		nbg=nbg+1
		local q = {{x=x,y=y}}
		local closed = {}
		while #q > 0 do
			local n = table.remove(q, 1)
			if opens[n.x] and opens[n.x][n.y] then
				-- self.data[n.y][n.x] = string.char(string.byte('0') + nbg) -- Debug to visualize floodfill groups
				closed[#closed+1] = n
				list[opens[n.x][n.y]] = nil
				opens[n.x][n.y] = nil
				q[#q+1] = {x=n.x-1, y=n.y}
				q[#q+1] = {x=n.x, y=n.y+1}
				q[#q+1] = {x=n.x+1, y=n.y}
				q[#q+1] = {x=n.x, y=n.y-1}

				q[#q+1] = {x=n.x+1, y=n.y-1}
				q[#q+1] = {x=n.x+1, y=n.y+1}
				q[#q+1] = {x=n.x-1, y=n.y-1}
				q[#q+1] = {x=n.x-1, y=n.y+1}
			end
		end
		return closed
	end

	-- Process all open spaces
	local groups = {}
	while next(list) do
		local i, l = next(list)
		local closed = floodFill(l.x, l.y)
		groups[#groups+1] = {id=id, list=closed}
		print("[Tilemap] Floodfill group", i, #closed)
	end

	return groups
end

--- Return a list of groups of tiles representing each of the connected areas
function _M:findGroupsNotOf(wall)
	wall = table.reverse(wall)
	return self:findGroups(function(c) return not wall[c] end)
end

--- Return a list of groups of tiles representing each of the connected areas
function _M:findGroupsOf(floor)
	floor = table.reverse(floor)
	return self:findGroups(function(c) return floor[c] end)
end

--- Apply a custom method over the given groups, sorting them from bigger to smaller
-- It gives the groups in order of bigger to smaller
function _M:applyOnGroups(groups, fct)
	if not self.data then return end
	table.sort(groups, function(a,b) return #a.list > #b.list end)
	for id, group in ipairs(groups) do
		fct(self.data_w, self.data_h, self.data, group, id)
	end
end

--- Given a list of groups, eliminate them all
function _M:eliminateGroups(wall, groups)
	if not self.data then return end
	print("[Tilemap] Eleminating groups", #groups)
	for i = 1, #groups do
		print("[Tilemap] Eleminating group "..i.." of", #groups[i].list)
		for j = 1, #groups[i].list do
			local jn = groups[i].list[j]
			self.data[jn.y][jn.x] = wall
		end
	end
end

--- Simply destroy all connected groups except the biggest one
function _M:eliminateByFloodfill(walls)
	if not self.data then return 0 end
	local groups = self:findGroupsNotOf(walls)

	-- If nothing exists, regen
	if #groups == 0 then
		print("[Tilemap] Floodfill found nothing")
		return 0
	end

	-- Sort to find the biggest group
	table.sort(groups, function(a,b) return #a.list < #b.list end)
	local g = table.remove(groups)
	if g and #g.list > 0 then
		print("[Tilemap] Ok floodfill with main group size", #g.list)
		self:eliminateGroups(walls[1], groups)
		return #g.list
	else
		print("[Tilemap] Floodfill left nothing")
		return 0
	end
end

function _M:fillGroup(group, char)
	-- print("[Tilemap] Filling group of", #group.list, "with", char)
	for j = 1, #group.list do
		local jn = group.list[j]
		self.data[jn.y][jn.x] = char
	end
end

function _M:isInGroup(group, x, y)
	if not group.reverse then
		group.reverse = {}
		for j = 1, #group.list do
			local jn = group.list[j]
			group.reverse[jn.x] = group.reverse[jn.x] or {}
			group.reverse[jn.x][jn.y] = true
		end
	end
	return group.reverse[x] and group.reverse[x][y]
end
--[=[
--- Find the biggest rectangle that can fit fully in the given group
function _M:groupInnerRectangle(group)
	if #group.list == 0 then return nil end

	-- Make a matrix to work on
	local outrect = self:groupOuterRectangle(group)
	local m = self:makeData(outrect.w, outrect.h, 0)
	local matrix = self:makeData(outrect.w, outrect.h, false)
	for j = 1, #group.list do
		local jn = group.list[j]
		matrix[jn.y - outrect.y1 + 1][jn.x - outrect.x1 + 1] = true
	end

        for i = 1, outrect.w do
        	for j = 1, outrect.h do
        		m[j][i] = matrix[j][i] and (1 + m[j+1][i]) or 0
        	end
        end
                m[i][j]=matrix[i][j]=='1'?1+m[i][j+1]:0;
end

public int maximalRectangle(char[][] matrix) {
	int m = matrix.length;
	int n = m == 0 ? 0 : matrix[0].length;
	int[][] height = new int[m][n + 1];
 
	int maxArea = 0;
	for (int i = 0; i < m; i++) {
		for (int j = 0; j < n; j++) {
			if (matrix[i][j] == '0') {
				height[i][j] = 0;
			} else {
				height[i][j] = i == 0 ? 1 : height[i - 1][j] + 1;
			}
		}
	}
 
	for (int i = 0; i < m; i++) {
		int area = maxAreaInHist(height[i]);
		if (area > maxArea) {
			maxArea = area;
		}
	}
 
	return maxArea;
}
 
private int maxAreaInHist(int[] height) {
	Stack<Integer> stack = new Stack<Integer>();
 
	int i = 0;
	int max = 0;
 
	while (i < height.length) {
		if (stack.isEmpty() || height[stack.peek()] <= height[i]) {
			stack.push(i++);
		} else {
			int t = stack.pop();
			max = Math.max(max, height[t]
					* (stack.isEmpty() ? i : i - stack.peek() - 1));
		}
	}
 
	return max;
}

-- int maximalRectangle(vector<vector<char> > &matrix) {
--         if(matrix.size()==0 || matrix[0].size()==0)return 0;
--         vector<vector<int>>m(matrix.size()+1,vector<int>(matrix[0].size()+1,0));
--         for(int i=0;i<matrix.size();i++)
--             for(int j=matrix[0].size()-1;j>=0;j--)
--                 m[i][j]=matrix[i][j]=='1'?1+m[i][j+1]:0;
--         int max=0;
--         for(int i=0;i<matrix[0].size();i++){
--             int p=0;
--             vector<int>s;
--             while(p!=m.size()){
--                 if(s.empty() || m[p][i]>=m[s.back()][i])
--                     s.push_back(p++);
--                 else{
--                     int t=s.back();
--                     s.pop_back();
--                     max=std::max(max,m[t][i]*(s.empty()?p:p-s.back()-1));
--                 }
--             }
--         }
--         return max;
-- }
--]=]

--- Find the smallest rectangle that can fit around in the given group
function _M:groupOuterRectangle(group)
	local n = group.list[1]
	if not n then return end -- wtf?
	local x1, x2 = n.x, n.x
	local y1, y2 = n.y, n.y

	for j = 1, #group.list do
		local jn = group.list[j]
		if jn.x < x1 then x1 = jn.x end
		if jn.x > x2 then x2 = jn.x end
		if jn.y < y1 then y1 = jn.y end
		if jn.y > y2 then y2 = jn.y end
	end

	-- Debug
	-- for i = x1, x2 do for j = y1, y2 do
	-- 	if not self:isInGroup(group, i, j) then
	-- 		if self.data[j][i] == '#' then
	-- 			self.data[j][i] = 'T'
	-- 		end
	-- 	end
	-- end end

	return self:point(x1, y1), self:point(x2, y2), x2 - x1 + 1, y2 - y1 + 1
end

--- Carve out a simple linear path from coords until a tile is reached
function _M:carveLinearPath(char, from, dir, stop_at, dig_only_into)
	local x, y = math.floor(from.x), math.floor(from.y)
	local dx, dy = util.dirToCoord(dir)
	if type(dig_only_into) == "table" then dig_only_into = table.reverse(dig_only_into) end
	while x >= 1 and x <= self.data_w and y >= 1 and y <= self.data_h and self.data[y][x] ~= stop_at do
		if not dig_only_into or (type(dig_only_into) == "table" and dig_only_into[self.data[y][x]]) or (type(dig_only_into) == "function" and dig_only_into(x, y, self.data[y][x])) then 
			self.data[y][x] = char
		end
		x, y = x + dx, y + dy
	end
end

--- Carve out a simple rectangle
function _M:carveArea(char, from, to, dig_only_into)
	if type(dig_only_into) == "table" then dig_only_into = table.reverse(dig_only_into) end
	for x = from.x, to.x do for y = from.y, to.y do
		if x >= 1 and x <= self.data_w and y >= 1 and y <= self.data_h then
			if not dig_only_into or (type(dig_only_into) == "table" and dig_only_into[self.data[y][x]]) or (type(dig_only_into) == "function" and dig_only_into(x, y, self.data[y][x])) then
				self.data[y][x] = char
			end
		end
	end end
end

--- Apply a function over an area
function _M:applyArea(from, to, fct)
	for x = from.x, to.x do for y = from.y, to.y do
		if x >= 1 and x <= self.data_w and y >= 1 and y <= self.data_h then
			local ret = fct(x, y, self.data[y][x])
			if ret ~= nil then
				self.data[y][x] = ret
			end
		end
	end end
end

--- Get the results
-- @param is_array if true returns a table[][] of characters, if false a table[] of string lines
function _M:getResult(is_array)
	if not self.data then return nil end
	if is_array then return self.data end
	local data = {}
	for y = 1, self.data_h do data[y] = table.concat(self.data[y]) end
	return data
end

--- Debug function to print the result to the log
function _M:printResult()
	if not self.data then
		print("-------------")
		print("------------- Tilemap result")		
		return
	end
	print("------------- Tilemap result --[[")
	for _, line in ipairs(self:getResult()) do
		print(line)
	end
	print("]]-----------")
end

--- Merge an other Tilemap's data
function _M:merge(x, y, tm, char_order, empty_char)
	if not self.data or not tm.data then return end
	-- if x is a table it's a point data so we shift parameters
	if type(x) == "table" then
		x, y, tm, char_order, empty_char = x.x, x.y, y, tm, char_order
	end

	x = math.floor(x)
	y = math.floor(y)
	
	char_order = table.reverse(char_order or {})
	
	empty_char = empty_char or {' '}
	if type(empty_char) == "string" then empty_char = {empty_char} end
	empty_char = table.reverse(empty_char)

	if not tm.data then return end

	for i = 1, tm.data_w do
		for j = 1, tm.data_h do
			local si, sj = i + x - 1, j + y - 1
			if si >= 1 and si <= self.data_w and sj >= 1 and sj <= self.data_h then
				local c = tm.data[j][i]
				if not empty_char[c] then
					local sc = self.data[sj][si]
					local sc_o = char_order[sc] or 0
					local c_o = char_order[c] or 0

					if c_o >= sc_o then
						self.data[sj][si] = tm.data[j][i]
					end
				end
			end
		end
	end
	tm:mergedAt(x, y)
end

--- Does nothing, meant to be superloaded
function _M:mergedAt(x, y)
end


------------------------------------------------------------------------------
-- Simple tunneling
------------------------------------------------------------------------------

function _M:initTunneling()
	if not self.tunnels_map then
		self.tunnels_map = self:makeData(self.data_w, self.data_h, false)
		self.tunnels_next_id = 'a'
	end
	local id = self.tunnels_next_id
	self.tunnels_next_id = string.char(string.byte(self.tunnels_next_id) + 1)
	return id
end

--- Random tunnel dir (no diagonals)
function _M:tunnelRandDir(sx, sy)
	local dirs = util.primaryDirs() --{4,6,8,2}
	return util.dirToCoord(dirs[rng.range(1, #dirs)], sx, sy)
end

--- Find the direction in which to tunnel (no diagonals)
function _M:tunnelDir(x1, y1, x2, y2)
	-- HEX TODO ?
	local xdir = (x1 == x2) and 0 or ((x1 < x2) and 1 or -1)
	local ydir = (y1 == y2) and 0 or ((y1 < y2) and 1 or -1)
	if xdir ~= 0 and ydir ~= 0 then
		if rng.percent(50) then xdir = 0
		else ydir = 0
		end
	end
	return xdir, ydir
end

--- Marks a tunnel as a tunnel and the space behind it
function _M:tunnelMark(x, y, xdir, ydir, id)
	x, y = x - xdir, y - ydir
	local dir = util.coordToDir(xdir, ydir, x, y)
	local sides = util.dirSides(dir, x, y)
	local mark_dirs = {dir, sides.left, sides.right}
	for i, d in ipairs(mark_dirs) do
		local xd, yd = util.dirToCoord(d, x, y)
		if self:isBound(x+xd, y+yd) and not self.tunnels_map[y+yd][x+xd] then 
			self.tunnels_map[y+yd][x+xd] = id
			print("mark tunnel", x+xd, y+yd , id)
		end
	end
	if not self.tunnels_map[y][x] then
		self.tunnels_map[y][x] = id
		print("mark tunnel", x, y , id)
	end
end

--- Tunnel between two points
-- @param x1, y1 starting coordinates
-- @param x2, y2 ending coordinates
-- @param id tunnel id
-- @param virtual set true to mark the tunnel without changing terrain
function _M:tunnel(from, to, char, tunnel_through, tunnel_avoid, config, virtual)
	local x1, y1, x2, y2 = from.x, from.y, to.x, to.y
	config = config or {}
	config.tunnel_change = config.tunnel_change or 60
	config.tunnel_random = config.tunnel_random or 7

	char = char or '.'
	tunnel_through = table.reverse(tunnel_through or {'ALL'})
	tunnel_avoid = table.reverse(tunnel_avoid or {'⍓'})

	local id = self:initTunneling()

	if x1 == x2 and y1 == y2 then return end
	-- Disable the many prints of tunnelling
	-- local print = function()end

	local xdir, ydir = self:tunnelDir(x1, y1, x2, y2)
	print("tunneling from",x1, y1, "to", x2, y2, "initial dir", xdir, ydir)

	local startx, starty = x1, y1
	local tun = {}

	local tries = 2000
	local no_move_tries = 0
	while tries > 0 do
		if rng.percent(config.tunnel_change) then
			if rng.percent(config.tunnel_random) then xdir, ydir = self:tunnelRandDir(x1, x2)
			else xdir, ydir = self:tunnelDir(x1, y1, x2, y2)
			end
		end

		local nx, ny = x1 + xdir, y1 + ydir
		while true do
			if self:isBound(nx, ny) then break end

			if rng.percent(config.tunnel_random) then xdir, ydir = self:tunnelRandDir(nx, ny)
			else xdir, ydir = self:tunnelDir(x1, y1, x2, y2)
			end
			nx, ny = x1 + xdir, y1 + ydir
		end
		print(feat, "try pos", nx, ny, "dir", util.coordToDir(xdir, ydir, nx, ny))
		local nc = self.data[ny][nx]

		if tunnel_avoid[nc] then
			if nx == from.x and ny == from.y then
				tun[#tun+1] = {nx,ny}
				x1, y1 = nx, ny
				print(feat, "accept avoid (start)", nc)
			elseif nx == to.x and ny == to.y then
				tun[#tun+1] = {nx,ny}
				x1, y1 = nx, ny
				print(feat, "accept avoid (end)", nc)
			else
				print(feat, "reject avoid", nc)
				if nx == x2 and ny == y2 then -- stop if next to special target
					x1, y1 = nx, ny
					print(feat, "end adjacent to special target")
				end
			end
		-- elseif nc.can_open ~= nil then
		-- 	if nc.can_open then
		-- 		print(feat, "tunnel crossing can_open", nx,ny)
		-- 		for _, coord in pairs(util.adjacentCoords(nx, ny)) do
		-- 			if self:isBound(coord[1], coord[2]) then
		-- 				self.map.room_map[coord[1]][coord[2]].can_open = false
		-- 				print(feat, "forbidding crossing at ", coord[1], coord[2])
		-- 			end
		-- 		end
		-- 		tun[#tun+1] = {nx,ny,true}
		-- 		x1, y1 = nx, ny
		-- 		print(feat, "accept can_open")
		-- 	else
		-- 		print(feat, "reject can_open")
		-- 	end
		elseif self.tunnels_map[ny][nx] then
			if no_move_tries >= 15 then
				tun[#tun+1] = {nx,ny}
				x1, y1 = nx, ny
				print(feat, "accept tunnel", nc, id)
			else
				print(feat, "reject tunnel", nc, id)
			end
		elseif tunnel_through[nc] or tunnel_through.ALL then
			tun[#tun+1] = {nx,ny}
			x1, y1 = nx, ny
			print(feat, "accept normal", nc)
		else
			print(feat, "reject normal", nc)
		end

		if x1 == nx and y1 == ny then
			self:tunnelMark(x1, y1, xdir, ydir, id)
			no_move_tries = 0
		else
			no_move_tries = no_move_tries + 1
		end

		if x1 == x2 and y1 == y2 then print(feat, "done") break end

		tries = tries - 1
	end

	local doors = {}
	self.possible_doors = self.possible_doors or {}
	for _, t in ipairs(tun) do
		local nx, ny = t[1], t[2]
		if t[3] and self.data.door then self.possible_doors[#self.possible_doors+1] = t end
		if not t[4] and not virtual then
			print("=======TUNN", nx, ny)
			-- self.map(nx, ny, Map.TERRAIN, self:resolve('=') or self:resolve('.') or self:resolve('floor'))
			self:put(self:point(nx, ny), char)
		end
	end
end

------------------------------------------------------------------------------
-- A* tunneling
------------------------------------------------------------------------------

--- The default heuristic for A*, tries to come close to the straight path
-- @int sx
-- @int sy
-- @int cx
-- @int cy
-- @int tx
-- @int ty
local function heuristicCloserPath(sx, sy, cx, cy, tx, ty)
	local h
	-- Chebyshev  distance
	h = math.max(math.abs(tx - cx), math.abs(ty - cy))

	-- tie-breaker rule for straighter paths
	local dx1 = cx - tx
	local dy1 = cy - ty
	local dx2 = sx - tx
	local dy2 = sy - ty
	return h + 0.01*math.abs(dx1*dy2 - dx2*dy1)
end

--- A simple heuristic for A*, using distance
-- @int sx
-- @int sy
-- @int cx
-- @int cy
-- @int tx
-- @int ty
local function heuristicDistance(sx, sy, cx, cy, tx, ty)
	return core.fov.distance(cx, cy, tx, ty)
end

--- Converts x & y into a single value
-- @see astarToDouble
-- @int x
-- @int y
function _M:astarToSingle(x, y)
	return x + y * self.data_w
end

--- Converts a single value back into x & y
-- @see astarToSingle
-- @int c
function _M:astarToDouble(c)
	local y = math.floor(c / self.data_w)
	return c - y * self.data_w, y
end

--- Create Path
-- @param came_from
-- @param cur
function _M:astarCreatePath(came_from, cur, id, char)
	if not came_from[cur] then return end
	local rpath, path = {}, {}
	while came_from[cur] do
		local x, y = self:astarToDouble(cur)
		rpath[#rpath+1] = self:point(x, y)
		self.data[y][x] = char
		self.tunnels_map[y][x] = id
		cur = came_from[cur]
	end
	for i = #rpath, 1, -1 do path[#path+1] = rpath[i] end
	return path
end

--- Compute path from sx/sy to tx/ty
function _M:tunnelAStar(from, to, char, tunnel_through, tunnel_avoid, config)
	local sx, sy, tx, ty = from.x, from.y, to.x, to.y
	config = config or {}

	char = char or '.'
	tunnel_through = table.reverse(tunnel_through or {'ALL'})
	tunnel_avoid = table.reverse(tunnel_avoid or {'⍓'})

	local id = self:initTunneling()

	if sx == tx and sy == ty then return end

	config.erraticness = config.erraticness or 9
	config.tunnel_avoidance = config.tunnel_avoidance or 20
	if type(config.forbid_diagonals) == "nil" then config.forbid_diagonals = true end

	local heur = heuristic or heuristicCloserPath
	local w, h = self.data_w, self.data_h
	local start = self:astarToSingle(sx, sy)
	local stop = self:astarToSingle(tx, ty)
	local open = {[start]=true}
	local closed = {}
	local g_score = {[start] = 0}
	local h_score = {[start] = heur(sx, sy, sx, sy, tx, ty)}
	local f_score = {[start] = heur(sx, sy, sx, sy, tx, ty)}
	local came_from = {}

	if not self:isBound(sx, sy) or not self:isBound(tx, ty) then
		print("Astar fail: source/destination unreachable")
		return nil
	end
	local checkPos = function(node, nx, ny)
		local npos = self:point(nx, ny)
		local nnode = self:astarToSingle(nx, ny)
		if self:isBound(nx, ny) then print("---Check", nx, ny,':', self.data[ny][nx], ":", not closed[nnode], self:isBound(nx, ny), (tunnel_through.ALL or tunnel_through[self.data[ny][nx]]), (not tunnel_avoid[self.data[ny][nx]]), (not config.add_check or config.add_check(nx, ny))) end
		if not closed[nnode] and self:isBound(nx, ny) and (
		   (
		   	npos == from or npos == to -- Always allow on start & stop
		   )
		   or
		   (
		   	(tunnel_through.ALL or tunnel_through[self.data[ny][nx]]) and -- Allowed to tunnel in
		   	(not tunnel_avoid[self.data[ny][nx]]) and -- Avoid tunneling in
		   	(not config.add_check or config.add_check(nx, ny)) -- Extra checks
		   )
		) then
			local nc = self.data[ny][nx]
			local score = 1
			score = score + rng.float(0, config.erraticness)
			if self.tunnels_map[ny][nx] then score = score + config.tunnel_avoidance end
			local tent_g_score = g_score[node] + score -- we can adjust here for difficult passable terrain
			local tent_is_better = false
			if not open[nnode] then open[nnode] = true; tent_is_better = true
			elseif tent_g_score < g_score[nnode] then tent_is_better = true
			end

			if tent_is_better then
				came_from[nnode] = node
				g_score[nnode] = tent_g_score
				h_score[nnode] = heur(sx, sy, tx, ty, nx, ny)
				f_score[nnode] = g_score[nnode] + h_score[nnode]
			end
		end
	end

	while next(open) do
		-- Find lowest of f_score
		local node, lowest = nil, 999999999999999
		local n, _ = next(open)
		while n do
			if f_score[n] < lowest then node = n; lowest = f_score[n] end
			n, _ = next(open, n)
		end

		if node == stop then return self:astarCreatePath(came_from, stop, id, char) end

		open[node] = nil
		closed[node] = true
		local x, y = self:astarToDouble(node)

		-- Check sides
		for _, coord in pairs(util.adjacentCoords(x, y, forbid_diagonals)) do
			checkPos(node, coord[1], coord[2])
		end
	end
end
