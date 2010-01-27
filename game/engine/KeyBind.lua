require "config"
require "engine.class"
require "engine.KeyCommand"

--- Handles key binds to "virtual" actions
module(..., package.seeall, class.inherit(engine.KeyCommand))

_M.binds_def = {}
_M.binds_remap = {}
_M.binds_loaded = {}
_M.bind_order = 1

function _M:defineAction(t)
	assert(t.default, "no keybind default")
	assert(t.name, "no keybind name")
	t.desc = t.desc or t.name

	t.order = _M.bind_order
	_M.binds_def[t.type] = t
	_M.bind_order = _M.bind_order + 1
end

--- Loads a list of keybind definitions
-- Keybind definitions are in /data/keybinds/. Modules can define new ones.
-- @param a string representing the keybind, separated by commas. I.e: "move,hotkeys,actions,inventory"
function _M:load(str)
	local defs = str:split(",")
	for i, def in ipairs(defs) do
		if not _M.binds_loaded[def] then
			local f, err = loadfile("/data/keybinds/"..def..".lua")
			if not f and err then error(err) end
			setfenv(f, setmetatable({
				defineAction = function(t) self:defineAction(t) end
			}, {__index=_G}))
			f()

			print("[KEYBINDER] Loaded keybinds: "..def)
			_M.binds_loaded[def] = true
		end
	end
end

--- Loads a keybinds remap
function _M:loadRemap(file)
	local f, err = loadfile(file)
	if not f and err then error(err) end
	local d = {}
	setfenv(f, d)
	f()

	for virtual, keys in pairs(d) do
		print("Remapping", virtual, keys)
		_M.binds_remap[virtual] = keys
	end
end

--- Saves a keybinds remap
function _M:saveRemap(file)
	local restore = false
	if not file then
		restore = fs.getWritePath()
		fs.setWritePath(engine.homepath)
		file = "keybinds.cfg"
	end

	local f = fs.open(file, "w")

	for virtual, keys in pairs(_M.binds_remap) do
		if keys[1] and not keys[2] then
			f:write(("%s = {%q,nil}\n"):format(virtual, keys[1]))
		elseif not keys[1] and keys[2] then
			f:write(("%s = {nil,%q}\n"):format(virtual, keys[2]))
		elseif keys[1] and keys[2] then
			f:write(("%s = {%q,%q}\n"):format(virtual, keys[1], keys[2]))
		elseif not keys[1] and not keys[2] then
			f:write(("%s = {nil,nil}\n"):format(virtual))
		end
	end

	f:close()

	if restore then
		fs.setWritePath(restore)
	end
end

--- Returns the binding table for the given type
function _M:getBindTable(type)
	return _M.binds_remap[type.type] or type.default
end

function _M:init()
	engine.KeyCommand.init(self)
	self.virtuals = {}

	self:bindKeys()
end

--- Binds all virtuals to keys, either defaults or remapped ones
function _M:bindKeys()
	self.binds = {}
	-- Bind defaults
	for type, t in pairs(_M.binds_def) do
		for i, ks in ipairs(_M.binds_remap[type] or t.default) do
			self.binds[ks] = type
		end
	end
end

function _M:findBoundKeys(virtual)
	local bs = {}
	for ks, virt in pairs(self.binds) do
		if virt == virtual then bs[#bs+1] = ks end
	end
	return unpack(bs)
end

function _M:makeKeyString(sym, ctrl, shift, alt, meta, unicode)
	return ("sym:%s:%s:%s:%s:%s"):format(tostring(sym), tostring(ctrl), tostring(shift), tostring(alt), tostring(meta)), unicode and "uni:"..unicode
end

function _M:formatKeyString(ks)
	if not ks then return "--" end

	if ks:find("^uni:") then
		return ks:sub(5)
	else
		local i, j, sym, ctrl, shift, alt, meta = ks:find("^sym:([0-9]+):([a-z]+):([a-z]+):([a-z]+):([a-z]+)$")
		if not i then return "--" end

		ctrl = ctrl == "true" and true or false
		shift = shift == "true" and true or false
		alt = alt == "true" and true or false
		meta = meta == "true" and true or false
		sym = tonumber(sym) or sym
		sym = _M.sym_to_name[sym] or sym
		sym = sym:gsub("^_", "")

		if ctrl then sym = "[ctrl]+"..sym end
		if shift then sym = "[shift]+"..sym end
		if alt then sym = "[alt]+"..sym end
		if meta then sym = "[meta]+"..sym end

		return sym
	end
end

function _M:receiveKey(sym, ctrl, shift, alt, meta, unicode)
	local ks, us = self:makeKeyString(sym, ctrl, shift, alt, meta, unicode)
--	print("[BIND]", sym, ctrl, shift, alt, meta, unicode, " :=: ", ks, us, " ?=? ", self.binds[ks], us and self.binds[us])
	if self.binds[ks] and self.virtuals[self.binds[ks]] then
		self.virtuals[self.binds[ks]](sym, ctrl, shift, alt, meta, unicode)
		return
	elseif us and self.binds[us] and self.virtuals[self.binds[us]] then
		self.virtuals[self.binds[us]](sym, ctrl, shift, alt, meta, unicode)
		return
	end

	engine.KeyCommand.receiveKey(self, sym, ctrl, shift, alt, meta, unicode)
end

--- Adds a key/command combinaison
-- @param sym the key to handle
-- @param mods a table with the mod keys needed, i.e: {"ctrl", "alt"}
-- @param fct the function to call when the key is pressed
function _M:addBind(virtual, fct)
	self.virtuals[virtual] = fct
end

--- Adds a key/command combinaison
-- @param sym the key to handle
-- @param mods a table with the mod keys needed, i.e: {"ctrl", "alt"}
-- @param fct the function to call when the key is pressed
function _M:addBinds(t)
	local later = {}
	for virtual, fct in pairs(t) do
		if type(fct) == "function" then
		print("bind", virtual, fct)
			self:addBind(virtual, fct)
		else
			later[virtual] = fct
		end
	end
	for virtual, fct in pairs(later) do
		self:addBind(virtual, self.virtuals[fct])
	end
end
