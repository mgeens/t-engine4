-- TE4 - T-Engine 4
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
local http = require "socket.http"
local url = require "socket.url"
local ltn12 = require "ltn12"
local Dialog = require "engine.ui.Dialog"
local UserChat = require "engine.UserChat"
local sha1 = require("sha1").sha1
require "Json2"

--- Handles the player profile, possibly online
-- @classmod engine.PlayerProfile
module(..., package.seeall, class.make)

------------------------------------------------------------
-- some simple serialization stuff
------------------------------------------------------------
local function basicSerialize(o)
	if type(o) == "number" or type(o) == "boolean" then
		return tostring(o)
	elseif type(o) == "function" then
		return string.format("loadstring(%q)", string.dump(o))
	else   -- assume it is a string
		return string.format("%q", o)
	end
end

local function serialize_data(outf, name, value, saved, filter, allow, savefile, force)
	saved = saved or {}       -- initial value
	outf(name, " = ")
	if type(value) == "number" or type(value) == "string" or type(value) == "boolean" or type(value) == "function" then
		outf(basicSerialize(value), "\n")
	elseif type(value) == "table" then
			saved[value] = name   -- save name for next time
			outf("{}\n")     -- create a new table

			for k,v in pairs(value) do      -- save its fields
				local fieldname
				fieldname = string.format("%s[%s]", name, basicSerialize(k))
				serialize_data(outf, fieldname, v, saved, {new=true}, false, savefile, false)
			end
	else
		error("cannot save a " .. type(value) .. " ("..name..")")
	end
end

local function serialize(data)
	local tbl = {}
	local outf = function(...) for i,str in ipairs{...} do table.insert(tbl, str) end end
	for k, e in pairs(data) do
		serialize_data(outf, tostring(k), e)
	end
	return table.concat(tbl)
end
------------------------------------------------------------


function _M:init()
	self.chat = UserChat.new()
	self.dlc_files = {classes={}, files={}}
	self.saved_events = {}
	self.temporary_event_handlers = {}
	self.generic = {}
	self.modules = {}
	self.evt_cbs = {}
	self.data_log = {log={}}
	self.stats_fields = {}
	local checkstats = function(self, field) return self.stats_fields[field] end
	self.config_settings =
	{
		[checkstats]     = { invalid = { read={online=true}, write="online" }, valid = { read={online=true}, write="online" } },
		["^allow_build$"] = { invalid = { read={offline=true,online=true}, write="offline" }, valid = { read={offline=true,online=true}, write="online" } },
		["^achievements$"] = { invalid = { read={offline=true,online=true}, write="offline" }, valid = { read={online=true}, write="online" } },
		["^donations$"] = { invalid = { read={offline=true}, write="offline" }, valid = { read={offline=true}, write="offline" } },
	}
	self.auth = false
	self.connected = nil
end

function _M:start()
	self:funFactsGrab()
	self:loadGenericProfile()

	if self.generic.online and self.generic.online.login and self.generic.online.pass then
		-- Convert to encrypted pass
		if not self.generic.online.v2 then
			self.generic.online.pass = sha1(self.generic.online.pass)
			self:saveGenericProfile("online", {login=self.generic.online.login, pass=self.generic.online.pass, v2=true})
		end

		self.login = self.generic.online.login
		self.pass = self.generic.online.pass
		self:tryAuth()
		self:waitFirstAuth()
	elseif core.steam and self.generic.onlinesteam and self.generic.onlinesteam.autolog then
		core.steam.sessionTicket(function(ticket) if ticket then
			self.steam_token = ticket:toHex()
			self:tryAuth()
			self:waitFirstAuth()
		end end)
	end
end

function _M:addStatFields(...)
	for i, f in ipairs{...} do
		self.stats_fields[f] = true
	end
end

function _M:loadData(f, where)
	setfenv(f, where)
	local ok, err = pcall(f)
	if not ok and err then print("Error executing data", err) end
end

function _M:mountProfile(online, module)
	-- Create the directory if needed
	local restore = fs.getWritePath()
	fs.setWritePath(engine.homepath)
	fs.mkdir(string.format("/profiles/%s/generic/", online and "online" or "offline"))
	if module then fs.mkdir(string.format("/profiles/%s/modules/%s", online and "online" or "offline", module)) end

	local path = engine.homepath..fs.getPathSeparator().."profiles"..fs.getPathSeparator()..(online and "online" or "offline")
	fs.mount(path, "/current-profile")
	print("[PROFILE] mounted ", online and "online" or "offline", "on /current-profile")
	fs.setWritePath(path)

	return restore
end
function _M:umountProfile(online, pop)
	local path = engine.homepath..fs.getPathSeparator().."profiles"..fs.getPathSeparator()..(online and "online" or "offline")
	fs.umount(path)
	print("[PROFILE] unmounted ", online and "online" or "offline", "from /current-profile")

	if pop then fs.setWritePath(pop) end
end

-- Define the fields that are sync'ed online, and how they are sync'ed
local generic_profile_defs = {
	firstrun = {nosync=true, no_sync=true, {firstrun="number"}, receive=function(data, save) save.firstrun = data.firstrun end },
	online = {nosync=true, no_sync=true, {login="string:40", pass="string:40", v2="number"}, receive=function(data, save) save.login = data.login save.pass = data.pass save.v2 = data.v2 end },
	onlinesteam = {nosync=true, no_sync=true, {autolog="boolean"}, receive=function(data, save) save.autolog = data.autolog end },
	modules_played = { {name="index:string:30"}, {time_played="number"}, receive=function(data, save) max_set(save, data.name, data, "time_played") end, export=function(env) for k, v in pairs(env) do add{name=k, time_played=v} end end },
	modules_loaded = { {name="index:string:30"}, {nb="number"}, receive=function(data, save) max_set(save, data.name, data, "nb") end, export=function(env) for k, v in pairs(env) do add{name=k, nb=v} end end },
}

--- Loads profile generic profile from disk
-- Generic profile is always read from the "online" profile
function _M:loadGenericProfile()
	-- Delay when we are currently saving
	if savefile_pipe and savefile_pipe.saving then savefile_pipe:pushGeneric("loadGenericProfile", function() self:loadGenericProfile() end) return end

	local pop = self:mountProfile(true)
	local d = "/current-profile/generic/"
	for i, file in ipairs(fs.list(d)) do
		if file:find(".profile$") then
			local f, err = loadfile(d..file)
			if not f and err then
				print("Error loading data profile", file, err)
			else
				local field = file:gsub(".profile$", "")
				self.generic[field] = self.generic[field] or {}
				self:loadData(f, self.generic[field])
			end
		end
	end
	self:umountProfile(true, pop)
end

--- Check if we can load this field from this profile
function _M:filterLoadData(online, field)
	local ok = false
	for f, conf in pairs(self.config_settings) do
		local try = false
		if type(f) == "string" then try = field:find(f)
		elseif type(f) == "function" then try = f(self, field) end
		if try then
			local c
			if self.hash_valid then c = conf.valid
			else c = conf.invalid
			end
			if not c then break end

			c = c.read
			if not c then break end

			if online and c.online then ok = true
			elseif not online and c.offline then ok = true
			end
			break
		end
	end
	print("[PROFILE] filtering load of ", field, " from profile ", online and "online" or "offline", "=>", ok and "allowed" or "disallowed")
	return ok
end

--- Return if we should save this field in the online or offline profile
function _M:filterSaveData(field)
	local online = false
	for f, conf in pairs(self.config_settings) do
		local try = false
		if type(f) == "string" then try = field:find(f)
		elseif type(f) == "function" then try = f(self, field) end
		if try then
			local c
			if self.hash_valid then c = conf.valid
			else c = conf.invalid
			end
			if not c then break end

			c = c.write
			if not c then break end

			if c == "online" then online = true else online = false end
			break
		end
	end
	print("[PROFILE] filtering save of ", field, " to profile ", online and "online" or "offline")
	return online
end

--- Loads profile module profile from disk
function _M:loadModuleProfile(short_name, mod_def)
	self.mod = {}
	if short_name == "boot" then return end

	-- Delay when we are currently saving
	if savefile_pipe and savefile_pipe.saving then savefile_pipe:pushGeneric("loadModuleProfile", function() self:loadModuleProfile(short_name) end) return end

	local def = mod_def.profile_defs or {}
	local function load(online)
		local pop = self:mountProfile(online, short_name)
		local d = "/current-profile/modules/"..short_name.."/"
		self.modules[short_name] = self.modules[short_name] or {}
		for i, file in ipairs(fs.list(d)) do
			if file:find(".profile$") then
				local field = file:gsub(".profile$", "")

				if self:filterLoadData(online, field) then
					local f, err = loadfile(d..file)
					if not f and err then
						print("Error loading data profile", file, err)
					else
						self.modules[short_name][field] = self.modules[short_name][field] or {}
						self:loadData(f, self.modules[short_name][field])
						if def[field].incr_only then
							if not self.modules[short_name][field].incr_only then
								print("[PROFILE] Old non incremental data for "..field..": discarding")
								self.modules[short_name][field] = {}
							end
						end
					end
				end
			end
		end
		self:umountProfile(online, pop)
	end

	load(false) -- Load from offline profile
	load(true) -- Load from online profile

	self.mod = self.modules[short_name]
	self.mod_name = short_name

	self:getConfigs(short_name, nil, mod_def)
	self:syncOnline(short_name, mod_def)
end

--- Saves a profile data
function _M:saveGenericProfile(name, data, nosync, nowrite)
	-- Delay when we are currently saving
	if not profile then return end
	core.game.resetLocale()
	if savefile_pipe and savefile_pipe.saving then savefile_pipe:pushGeneric("saveGenericProfile", function() self:saveGenericProfile(name, data, nosync) end) return end

	if not generic_profile_defs[name] then print("[PROFILE] refusing unknown generic data", name) return end

	profile.generic[name] = profile.generic[name] or {}
	local dataenv = profile.generic[name]
	local f = generic_profile_defs[name].receive
	setfenv(f, {
		inc_set=function(dataenv, key, data, dkey)
			local v = data[dkey]
			if type(v) == "number" then
			elseif type(v) == "table" and v[1] == "inc" then v = (dataenv[key] or 0) + v[2]
			end
			dataenv[key] = v
			data[dkey] = v
		end,
		max_set=function(dataenv, key, data, dkey)
			local v = data[dkey]
			if type(v) == "number" then
			elseif type(v) == "table" and v[1] == "inc" then v = (dataenv[key] or 0) + v[2]
			end
			v = math.max(v, dataenv[key] or 0)
			dataenv[key] = v
			data[dkey] = v
		end,
	})
	f(data, dataenv)

	if not nowrite then
		local pop = self:mountProfile(true)
		local f = fs.open("/generic/"..name..".profile", "w")
		if f then
			f:write(serialize(dataenv))
			f:close()
		end
		self:umountProfile(true, pop)
	end

	if not nosync and not generic_profile_defs[name].no_sync then self:setConfigs("generic", name, data) end
end

--- Saves a module profile data
function _M:saveModuleProfile(name, data, nosync, nowrite)
	if module == "boot" then return end
	core.game.resetLocale()
	if not game or not game.__mod_info.profile_defs then return end
	if game.__mod_info.profile_defs[name].incr_only then print("[PROFILE] data in incr only mode but called with saveModuleProfile", name) return end

	-- Delay when we are currently saving
	if savefile_pipe and savefile_pipe.saving then savefile_pipe:pushGeneric("saveModuleProfile", function() self:saveModuleProfile(name, data, nosync) end) return end

	local module = self.mod_name

	-- Check for readability
	profile.mod[name] = profile.mod[name] or {}
	local dataenv = profile.mod[name]
	local f = game.__mod_info.profile_defs[name].receive
	setfenv(f, {
		inc_set=function(dataenv, key, data, dkey)
			local v = data[dkey]
			if type(v) == "number" then
			elseif type(v) == "table" and v[1] == "inc" then v = (dataenv[key] or 0) + v[2]
			end
			dataenv[key] = v
			data[dkey] = v
		end,
		max_set=function(dataenv, key, data, dkey)
			local v = data[dkey]
			if type(v) == "number" then
			elseif type(v) == "table" and v[1] == "inc" then v = (dataenv[key] or 0) + v[2]
			end
			v = math.max(v, dataenv[key] or 0)
			dataenv[key] = v
			data[dkey] = v
		end,
	})
	f(data, dataenv)

	if not nowrite then
		local online = self:filterSaveData(name)
		local pop = self:mountProfile(online, module)
		local f = fs.open("/modules/"..module.."/"..name..".profile", "w")
		if f then
			f:write(serialize(dataenv))
			f:close()
		end
		self:umountProfile(online, pop)
	end

	if not nosync and not game.__mod_info.profile_defs[name].no_sync then self:setConfigs(module, name, data) end
end

--- Loads the incremental log data
function _M:incrLoadProfile(mod_def)
	if not mod_def or not mod_def.short_name then return end
	local pop = self:mountProfile(true)
	local file = "/current-profile/modules/"..mod_def.short_name.."/incr.log"
	if fs.exists(file) then
		local f, err = loadfile(file)
		if not f and err then
			print("Error loading incr log", file, err)
		else
			self:loadData(f, self.data_log)
		end
	end
	self:umountProfile(true, pop)
end

--- Saves a incr profile data
function _M:incrDataProfile(name, data)
	if module == "boot" then return end
	core.game.resetLocale()
	if not game or not game.__mod_info.profile_defs then return end
	if not game.__mod_info.profile_defs[name].incr_only then print("[PROFILE] data in non-incr only mode but called with incrDataProfile", name) return end

	-- Delay when we are currently saving
	if savefile_pipe and savefile_pipe.saving then savefile_pipe:pushGeneric("incrDataProfile", function() self:incrDataProfile(name, data) end) return end

	local module = self.mod_name

	-- Check for readability
	local dataenv = self.data_log.log
	dataenv[#dataenv+1] = {module=game.__mod_info.short_name, kind=name, data=data}

	local pop = self:mountProfile(true, module)
	local f = fs.open("/modules/"..module.."/incr.log", "w")
	if f then
		f:write(serialize(self.data_log))
		f:close()
	end
	self:umountProfile(true, pop)

	self:syncIncrData()
end

function _M:checkFirstRun()
	local result = self.generic.firstrun
	if not result then
		self:saveGenericProfile("firstrun", {firstrun=os.time()})
	end
	return result
end

function _M:performlogin(login, pass)
	pass = sha1(pass)

	self.login=login
	self.pass=pass
	print("[ONLINE PROFILE] attempting log in ", self.login)
	self.auth_tried = nil
	self:tryAuth()
	self:waitFirstAuth()
	if profile.auth then
		self:saveGenericProfile("online", {login=login, pass=pass, v2=true})
		self:getConfigs("generic")
		self:syncOnline("generic")
	end
end

function _M:performloginSteam(token, name, email, news)
	self.steam_token = token
	self.steam_token_name = name
	if email then self.steam_token_email = email end
	if news ~= nil then self.steam_token_news = news end
	print("[ONLINE PROFILE] attempting log in steam", token)
	self.auth_tried = nil
	self:tryAuth()
	self:waitFirstAuth()
	if (profile.auth) then
		self:saveGenericProfile("onlinesteam", {autolog=true})
		self:getConfigs("generic")
		self:syncOnline("generic")
	end
end

-----------------------------------------------------------------------
-- Events from the profile thread
-----------------------------------------------------------------------

function _M:popEvent(specific)
	if not specific then
		if #self.saved_events > 0 then return table.remove(self.saved_events, 1) end
		return core.profile.popEvent()
	else
		for i, evt in ipairs(self.saved_events) do
			if evt.e == specific then return table.remove(self.saved_events, i) end
		end
		local evt = core.profile.popEvent()
		if evt then
			if type(evt) == "string" then evt = evt:unserialize() end

			if evt.e == specific then return evt end
			self.saved_events[#self.saved_events+1] = evt
		end
	end
end

function _M:waitEvent(name, cb, wait_max)
	-- Dont try as it would fail and we'd fait for nothing
	if config.settings.disable_all_connectivity then return end

	-- Wait anwser, this blocks thegame but cant really be avoided :/
	local stop = false
	local first = true
	local tries = 0
	while not stop do
		if not first then
			if not self.waiting_event_no_redraw then pcall(core.display.forceRedraw) end
			core.game.sleep(50)
		end
		local evt = self:popEvent(name)
		while evt do
			if type(game) == "table" then evt = game:handleProfileEvent(evt)
			else evt = self:handleEvent(evt) end
--			print("==== waiting event", name, evt.e)
			if evt.e == name then
				stop = true
				cb(evt)
				break
			end
			evt = self:popEvent(name)
		end
		first = false
		tries = tries + 1
		if wait_max and tries * 50 > wait_max then break end
	end
end

function _M:noMoreAuthWait()
	self.no_more_wait_auth = true
end

function _M:waitFirstAuth(timeout)
	-- Dont try as it would fail and we'd fait for nothing
	if config.settings.disable_all_connectivity then return end

	if self.no_more_wait_auth then return end
	if self.auth_tried and self.auth_tried >= 1 then return end
	if not self.waiting_auth then return end
	print("[PROFILE] waiting for first auth")
	if self.connected == false then print("[PROFILE] waiting cancelled, connected = false") return end -- Set to false when we got a disconnect event, at boot it is nil
	local first = true
	timeout = timeout or 120
	while self.waiting_auth and timeout > 0 do
		if not first then
			if not self.waiting_auth_no_redraw then core.display.forceRedraw() end
			core.game.sleep(50)
		end
		local evt = self:popEvent()
		while evt do
			local e
			if type(game) == "table" then e = game:handleProfileEvent(evt)
			else e = self:handleEvent(evt) end
			if e and e.e == "Disconnected" then print("[PROFILE] waiting cancelled, got disconnect event") timeout = 0 break end
			if not self.waiting_auth then break end
			evt = self:popEvent()
		end
		first = false
		timeout = timeout - 1
	end
end

function _M:onAuth(fct)
	if self.auth then fct() return end
	self.on_auth_cb = self.on_auth_cb or {}
	self.on_auth_cb[#self.on_auth_cb+1] = fct
end

function _M:eventAuth(e)
	self.waiting_auth = false
	self.connected = true
	self.auth_tried = (self.auth_tried or 0) + 1
	if e.ok then
		self.auth = e.ok:unserialize()
		print("[PROFILE] Main thread got authed", self.auth.name)
		self:getConfigs("generic", function(e) self:syncOnline(e.module) end)
		for _, fct in ipairs(self.on_auth_cb or {}) do fct() end
		self.on_auth_cb = nil
	else
		self.auth_last_error = e.reason or "unknown"
	end
end

function _M:eventGetNews(e)
	if e.news and self.evt_cbs.GetNews then
		self.evt_cbs.GetNews(e.news:unserialize())
		self.evt_cbs.GetNews = nil
	end
end

function _M:eventIncrLogConsume(e)
	local module = type(game) == "table" and game.__mod_info.short_name
	if not module then return end
	print("[PROFILE] Server accepted our incr log, deleting")
	local pop = self:mountProfile(true, module)
	fs.delete("/modules/"..module.."/incr.log")
	self:umountProfile(true, pop)
	self.data_log.log = {}
end

function _M:eventGetConfigs(e)
	local data = zlib.decompress(e.data):unserialize()
	local module = e.module
	if not data then print("[ONLINE PROFILE] get configs") return end
	self:setConfigsBatch(true)
	for i = 1, #data do
		local val = data[i]

		if module == "generic" then
			self:saveGenericProfile(e.kind, val, true, i < #data)
		else
			self:saveModuleProfile(e.kind, val, true, i < #data)
		end
	end
	self:setConfigsBatch(false)
	if self.evt_cbs.GetConfigs then self.evt_cbs.GetConfigs(e) self.evt_cbs.GetConfigs = nil end
end

function _M:eventPushCode(e)
	if not config.settings.allow_online_events then
		if e.return_uuid then
			core.profile.pushOrder(string.format("o='CodeReturn' uuid=%q data=%q", e.return_uuid, table.serialize{error='user disabled events, refusing to load code'}))
		end
		return
	end

	local f, err = loadstring(e.code)
	if not f then
		if e.return_uuid then
			core.profile.pushOrder(string.format("o='CodeReturn' uuid=%q data=%q", e.return_uuid, table.serialize{error=err}))
		end
	else
		local ok, err = pcall(f)
		if config.settings.cheat then print(ok, err) end
		if e.return_uuid then
			core.profile.pushOrder(string.format("o='CodeReturn' uuid=%q data=%q", e.return_uuid, table.serialize{result=ok and err, error=not ok and err}))
		end
	end
end

function _M:eventChat(e)
	self.chat:event(e)
end

function _M:eventConnected(e)
	if game and type(game) == "table" and game.log then game.log("#YELLOW#Connection to online server established.") end
	print("[PlayerProfile] eventConnected")
	self.connected = true
end

function _M:eventDisconnected(e)
	if game and type(game) == "table" and game.log and self.connected then game.log("#YELLOW#Connection to online server lost, trying to reconnect.") end
	print("[PlayerProfile] eventDisconnected")
	self.connected = false
end

function _M:eventFunFacts(e)
	if e.data then
		self.funfacts = zlib.decompress(e.data):unserialize()
	end
end

function _M:registerTemporaryEventHandler(name, fct)
	self.temporary_event_handlers[name] = self.temporary_event_handlers[name] or {}
	table.insert(self.temporary_event_handlers[name], fct)
end

--- Got an event from the profile thread
function _M:handleEvent(e)
	if type(e) == "string" then e = e:unserialize() end
	if not e then return end
	if self["event"..e.e] then self["event"..e.e](self, e)
	elseif self.temporary_event_handlers[e.e] then
		for _, fct in ipairs(self.temporary_event_handlers[e.e]) do print("[PROFILE] temporary_event_handlers", e.e, pcall(fct, e)) end
		self.temporary_event_handlers[e.e] = nil
	end
	return e
end

-----------------------------------------------------------------------
-- Orders for the profile thread
-----------------------------------------------------------------------

function _M:getNews(callback, steam)
	print("[ONLINE PROFILE] get news")
	self.evt_cbs.GetNews = callback
	if not steam then core.profile.pushOrder("o='GetNews'")
	else core.profile.pushOrder("o='GetNews' steam=true")
	end
end

function _M:tryAuth()
	-- Dont try as it would fail and we'd fait for nothing
	if config.settings.disable_all_connectivity then return end

	print("[ONLINE PROFILE] auth")
	self.auth_last_error = nil
	if self.steam_token then
		core.profile.pushOrder(table.serialize{o="SteamLogin", token=self.steam_token, name=self.steam_token_name, email=self.steam_token_email, news=self.steam_token_news})
	else
		core.profile.pushOrder(table.serialize{o="Login", l=self.login, p=self.pass})
	end
	self.waiting_auth = true
	if __module_extra_info.sleep_on_auth then
		core.game.sleep((tonumber(__module_extra_info.sleep_on_auth) or 5) * 1000)
		self:waitEvent("Auth", function(e) end, 10000)
	end
end

function _M:logOut()
	core.profile.pushOrder(table.serialize{o="Logoff"})
	profile.generic.online = nil
	profile.auth = nil

	local pop = self:mountProfile(true)
	fs.delete("/generic/online.profile")
	fs.delete("/generic/onlinesteam.profile")
	self:umountProfile(true, pop)
end

function _M:getConfigs(module, cb, mod_def)
	self:waitFirstAuth()
	if not self.auth then return end
	self.evt_cbs.GetConfigs = cb
	if module == "generic" then
		for k, def in pairs(generic_profile_defs) do
			if not def.no_sync then
				core.profile.pushOrder(table.serialize{o="GetConfigs", module=module, kind=k})
			end
		end
	else
		for k, def in pairs((mod_def or game.__mod_info).profile_defs or {}) do
			if not def.no_sync and not def.incr_only then
				core.profile.pushOrder(table.serialize{o="GetConfigs", module=module, kind=k})
			end
		end
	end
end

function _M:setConfigsBatch(v)
	core.profile.pushOrder(table.serialize{o="SetConfigsBatch", v=v and true or false})
end

function _M:syncIncrData()
	self:waitFirstAuth()
	if not self.auth then return end
	local module = game and game.__mod_info.short_name
	if not module then return end
	
	core.profile.pushOrder(table.serialize{o="SendIncrLog", data=zlib.compress(table.serialize(self.data_log.log))})
end

function _M:setConfigs(module, name, data)
	self:waitFirstAuth()
	if not self.auth then return end
	if name == "online" then return end
	if module ~= "generic" then
		if not game.__mod_info.profile_defs then print("[PROFILE] saving config but no profile defs", module, name) return end
		if not game.__mod_info.profile_defs[name] then print("[PROFILE] saving config but no profile def kind", module, name) return end
	else
		if not generic_profile_defs[name] then print("[PROFILE] saving config but no profile def kind", module, name) return end
	end
	core.profile.pushOrder(table.serialize{o="SetConfigs", module=module, kind=name, data=zlib.compress(table.serialize(data))})
end

function _M:syncOnline(module, mod_def)
	self:waitFirstAuth()
	if not self.auth then return end
	local sync = self.generic
	if module ~= "generic" then sync = self.modules[module] end
	if not sync then return end

	self:setConfigsBatch(true)
	if module == "generic" then
		for k, def in pairs(generic_profile_defs) do
			if not def.no_sync and def.export and sync[k] then
				local f = def.export
				local ret = {}
				setfenv(f, setmetatable({add=function(d) ret[#ret+1] = d end}, {__index=_G}))
				f(sync[k])
				for i, r in ipairs(ret) do
					core.profile.pushOrder(table.serialize{o="SetConfigs", module=module, kind=k, data=zlib.compress(table.serialize(r))})
				end
			end
		end
	else
		for k, def in pairs((mod_def or game.__mod_info).profile_defs or {}) do
			if not def.no_sync and not def.incr_only and def.export and sync[k] then
				local f = def.export
				local ret = {}
				setfenv(f, setmetatable({add=function(d) ret[#ret+1] = d end}, {__index=_G}))
				f(sync[k])
				for i, r in ipairs(ret) do
					core.profile.pushOrder(table.serialize{o="SetConfigs", module=module, kind=k, data=zlib.compress(table.serialize(r))})
				end
			end
		end
	end
	self:setConfigsBatch(false)
end

function _M:checkModuleHash(module, md5)
	self.hash_valid = false
	if not self.auth then return nil, "no online profile active" end
	if config.settings.cheat then return nil, "cheat mode active" end
	if game and game:isTainted() then return nil, "savefile tainted" end
	core.profile.pushOrder(table.serialize{o="CheckModuleHash", module=module, md5=md5})

	local ok = false
	self:waitEvent("CheckModuleHash", function(e) ok = e.ok end, 10000)

	if not ok then return nil, "bad game version" end
	print("[ONLINE PROFILE] module hash is valid")
	self.hash_valid = true
	return true
end

function _M:checkAddonHash(module, addon, md5)
	if not self.auth then return nil, "no online profile active" end
	if config.settings.cheat then return nil, "cheat mode active" end
	if game and game:isTainted() then return nil, "savefile tainted" end
	core.profile.pushOrder(table.serialize{o="CheckAddonHash", module=module, addon=addon, md5=md5})

	local ok = false
	self:waitEvent("CheckAddonHash", function(e) ok = e.ok end, 10000)

	if not ok then return nil, "bad game addon version" end
	print("[ONLINE PROFILE] addon hash is valid")
	return true
end

function _M:checkAddonUpdates(list)
	if not self.auth then return nil, "no online profile active" end
	if #list == 0 then return nil, "nothing to update" end
	core.profile.pushOrder(table.serialize{o="CheckAddonUpdates", list=list})

	local ok = false
	self:waitEvent("CheckAddonUpdates", function(e) ok = e.ok end, 10000)

	if not ok then return nil, "bad game addon version" end
	ok = ok:unserialize()
	print("[ONLINE PROFILE] addon update list returned")
	table.print(ok)
	return ok
end

function _M:checkBatchHash(list)
	if not self.auth then return nil, "no online profile active" end
	if config.settings.cheat then return nil, "cheat mode active" end
	if game and game:isTainted() then return nil, "savefile tainted" end
	core.profile.pushOrder(table.serialize{o="CheckBatchHash", data=list})

	local ok = false
	local error = nil
	self:waitEvent("CheckBatchHash", function(e) ok = e.ok error = e.error end, 10000)

	if not ok then return nil, error or "unknown error" end
	print("[ONLINE PROFILE] all hashes are valid")
	self.hash_valid = true
	return true
end

function _M:sendError(what, err)
	print("[ONLINE PROFILE] sending error")
	local addons = {}
	for _, a in pairs(game.__mod_info.addons or {}) do
		addons[#addons+1] = a.version_name or "--"
	end
	local version = game.__mod_info.version_name
	if game.__mod_info.version_desc then version = game.__mod_info.version_name.." ("..tostring(game.__mod_info.version_desc)..")" end
	local beta = engine.version_hasbeta()
	if beta then version = version.."-"..beta end
	core.profile.pushOrder(table.serialize{
		o="SendError",
		login=self.login,
		what=what,
		err=err,
		module=game.__mod_info.short_name,
		version=version,
		charuuid=game:getPlayer(true) and game:getPlayer(true).__te4_uuid,
		addons=table.concat(addons, ", "),
	})
end

function _M:registerNewCharacter(module)
	if not self.auth or not self.hash_valid then return end
	local dialog = Dialog:simpleWaiter("Registering character", "Character is being registered on https://te4.org/")
	core.display.forceRedraw()

	core.profile.pushOrder(table.serialize{o="RegisterNewCharacter", module=module})
	local uuid = nil
	self:waitEvent("RegisterNewCharacter", function(e) uuid = e.uuid end, 10000)

	dialog:done()
	if not uuid then return end
	print("[ONLINE PROFILE] new character UUID ", uuid)
	return uuid
end

function _M:getCharball(id_profile, uuid)
	if not self.auth then return end
	local dialog = Dialog:simpleWaiter("Retrieving data from the server", "Retrieving...")
	core.display.forceRedraw()

	local data = nil
	core.profile.pushOrder(table.serialize{o="GetCharball", module=game.__mod_info.short_name, uuid=uuid, id_profile=id_profile})
	self:waitEvent("GetCharball", function(e) data = e.data end, 30000)

	dialog:done()
	if not data then return end
	return data
end

function _M:getDLCD(name, version, file)
	if not self.auth then return end
	local data = nil
	core.profile.pushOrder(table.serialize{o="GetDLCD", name=name, version=version, file=file})
	self:waitEvent("GetDLCD", function(e) data = e.data end, 30000)
	if not data then 
		print("DLCD for", name, version, file, "got a result of size0")
		return "" 
	end
	print("DLCD for", name, version, file, "got a result of size", (data or ""):len())
	return (data:len() > 0) and zlib.decompress(data) or data
end

function _M:registerSaveCharball(module, uuid, data)
	if not self.auth or not self.hash_valid then return end
	core.profile.pushOrder(table.serialize{o="SaveCharball",
		module=module,
		uuid=uuid,
		data=data,
	})
	print("[ONLINE PROFILE] saved character charball", uuid)
end

function _M:registerSaveChardump(module, uuid, title, tags, data)
	if not self.auth or not self.hash_valid then return end
	core.profile.pushOrder(table.serialize{o="SaveChardump",
		module=module,
		uuid=uuid,
		data=data,
		metadata=table.serialize{tags=tags, title=title},
	})
	print("[ONLINE PROFILE] saved character ", uuid)
end

function _M:setSaveID(module, uuid, savename, md5)
	if not self.auth or not self.hash_valid or not md5 then return end
	core.profile.pushOrder(table.serialize{o="SaveMD5",
		module=module,
		uuid=uuid,
		savename=savename,
		md5=md5,
	})
	print("[ONLINE PROFILE] saved character md5", uuid, savename, md5)
end

--- check if our save is valid
function _M:checkSaveID(module, uuid, savename, md5)
	if not self.auth or not self.hash_valid or not md5 then return function() return false end end
	core.profile.pushOrder(table.serialize{o="CheckSaveMD5",
		module=module,
		uuid=uuid,
		savename=savename,
		md5=md5,
	})
	print("[ONLINE PROFILE] checking character md5", uuid, savename, md5)
--[[
	return function()
		local ok = false
		self:waitEvent("CheckSaveMD5", function(e)
			if e.savename == savename and e.ok then ok = true end
		end, 30000)
		return ok
	end
]]
	return function() return true end
end

function _M:currentCharacter(module, title, uuid)
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="CurrentCharacter",
		module=module,
		mod_short=(game and type(game)=="table") and game.__mod_info.short_name or "unknown",
		title=title,
		valid=self.hash_valid,
		uuid=uuid,
	})
	print("[ONLINE PROFILE] current character ", title)
end

function _M:newProfile(Login, Name, Password, Email, Newsletter)
	print("[ONLINE PROFILE] profile options ", Login, Email, Name, Newsletter)

	core.profile.pushOrder(table.serialize{o="NewProfile2", login=Login, email=Email, name=Name, pass=Password, newsletter=Newsletter and 'yes' or 'no'})
	local id = nil
	local reason = nil
	self:waitEvent("NewProfile2", function(e) id = e.uid reason = e.reason end)

	if not id then print("[ONLINE PROFILE] could not create") return nil, reason or "unknown" end
	print("[ONLINE PROFILE] profile id ", id)
	self:performlogin(Login, Password)
	return id
end

function _M:entityVaultPoke(module, kind, name, desc, data)
	if not data then return end
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="EntityPoke",
		module=module,
		kind=kind,
		name=name,
		desc=desc,
		data=data,
	})
	print("[ONLINE PROFILE] poke entity vault", module, kind, name)
end

function _M:entityVaultPeek(module, kind, id)
	if not id then return end
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="EntityPeek",
		module=module,
		kind=kind,
		id=id,
	})
	print("[ONLINE PROFILE] peek entity vault", module, kind, id)
end

function _M:entityVaultEmpty(module, kind, id)
	if not id then return end
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="EntityEmpty",
		module=module,
		kind=kind,
		id=id,
	})
	print("[ONLINE PROFILE] empty entity vault", module, kind, id)
end

function _M:entityVaultInfos(module, kind)
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="EntityInfos",
		module=module,
		kind=kind,
	})
	print("[ONLINE PROFILE] list entity vault", module, kind)
end

function _M:addonEnableUpload()
	if not self.auth then return end
	core.profile.pushOrder(table.serialize{o="AddonEnableUpload"})
	print("[ONLINE PROFILE] enabling addon upload grants")
end

function _M:funFactsGrab(module)
	core.profile.pushOrder(table.serialize{o="FunFactsGrab", module=module})
	print("[ONLINE PROFILE] fun facts", module)
end

function _M:isDonator(s)
	s = s or 1
	if core.steam then return true end
	if not self.auth or not tonumber(self.auth.donated) or tonumber(self.auth.donated) < s then return false else return true end
end

function _M:canMTXN()
	if config.settings.disable_all_connectivity then return false end
	return self:isDonator()
end

function _M:allowDLC(dlc)
	-- if core.steam then if core.steam.checkDLC(dlc[2]) then return true end end
	-- if self.auth and self.auth.dlcs and self.auth.dlcs[dlc[1]] then return true end
	-- return false
	return true
end
