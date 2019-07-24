local plugin = "timers"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Timers", desc = "Handles drills, hacks and misc. mission timers" }, "init_timers_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	GameInfoManager._TIMER_CALLBACKS = {
		default = {
			--Digital specific functions
			set = function(timers, key, timer)
				if timers[key] and timers[key].active and not timers[key].duration then
					GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timer)
				end
				GameInfoManager._TIMER_CALLBACKS.default.update(timers, key, Application:time(), timer)
			end,
			start_count_up = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					if not timers[key].duration then
						GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timers[key].timer_value)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			start_count_down = function(timers, key)
				if timers[key] and timers[key].ext._visible then
					if not timers[key].duration then
						GameInfoManager._TIMER_CALLBACKS.default.set_duration(timers, key, timers[key].timer_value)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
				end
			end,
			pause = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, true)
			end,
			resume = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_jammed(timers, key, false)
			end,
			stop = function(timers, key)
				GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
			end,
			
			--General functions
			update = function(timers, key, t, timer, progress_ratio)
				if timers[key] then
					timers[key].timer_value = timer
					timers[key].progress_ratio = progress_ratio
					managers.gameinfo:_listener_callback("timer", "update", key, timers[key])
				end
			end,
			set_duration = function(timers, key, duration)
				if timers[key] then
					timers[key].duration = duration
					managers.gameinfo:_listener_callback("timer", "set_duration", key, timers[key])
				end
			end,
			set_active = function(timers, key, status)
				if timers[key] and timers[key].active ~= status then
					timers[key].active = status
					managers.gameinfo:_listener_callback("timer", "set_active", key, timers[key])
				end
			end,
			set_jammed = function(timers, key, status)
				if timers[key] and timers[key].jammed ~= status then
					timers[key].jammed = status
					managers.gameinfo:_listener_callback("timer", "set_jammed", key, timers[key])
				end
			end,
			set_powered = function(timers, key, status)
				local unpowered = not status
				if timers[key] and timers[key].unpowered ~= unpowered then
					timers[key].unpowered = unpowered
					managers.gameinfo:_listener_callback("timer", "set_unpowered", key, timers[key])
				end
			end,
			set_upgradable = function(timers, key, status)
				if timers[key] and timers[key].upgradable ~= status then
					timers[key].upgradable = status
					managers.gameinfo:_listener_callback("timer", "set_upgradable", key, timers[key])
				end
			end,
			set_acquired_upgrades = function(timers, key, acquired_upgrades)
				if timers[key] then
					timers[key].acquired_upgrades = acquired_upgrades
					managers.gameinfo:_listener_callback("timer", "set_acquired_upgrades", key, timers[key])
				end
			end,
		},
		overrides = {
			--Common functions
			stop_on_loud_pause = function(...)
				if not managers.groupai:state():whisper_mode() then
					GameInfoManager._TIMER_CALLBACKS.default.stop(...)
				else
					GameInfoManager._TIMER_CALLBACKS.default.pause(...)
				end
			end,
			stop_on_pause = function(...)
				GameInfoManager._TIMER_CALLBACKS.default.stop(...)
			end,
		
			[132864] = {	--Meltdown vault temperature
				set = function(timers, key, timer)
					if timer > 0 then
						GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, true)
					end
					GameInfoManager._TIMER_CALLBACKS.default.set(timers, key, timer)
				end,
				start_count_down = function(timers, key)
					GameInfoManager._TIMER_CALLBACKS.default.set_active(timers, key, false)
				end,
				pause = function(...) end,
			},
			[101936] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--GO Bank time lock
			[139706] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Hoxton Revenge alarm	(UNTESTED)
			[132675] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Hoxton Revenge panic room time lock	(UNTESTED)
			[133922] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--The Diamond pressure plates timer
			[130022] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130122] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130222] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130422] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			[130522] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_loud_pause(...) end },	--Train heist vaults
			--[130320] = { },	--The Diamond outer time lock
			--[130395] = { },	--The Diamond inner time lock
			--[101457] = { },	--Big Bank time lock door #1
			--[104671] = { },	--Big Bank time lock door #2
			--[167575] = { },	--Golden Grin BFD timer
			--[135034] = { },	--Lab rats cloaker safe 1
			--[135076] = { },	--Lab rats cloaker safe 2
			--[135246] = { },	--Lab rats cloaker safe 3
			--[135247] = { },	--Lab rats cloaker safe 4
			[141821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[141823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 1 timer
			[140321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[140323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 2 timer
			[139821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[139823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 3 timer
			[141321] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141322] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[141323] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 4 timer
			[140821] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140822] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
			[140823] = { pause = function(...) GameInfoManager._TIMER_CALLBACKS.overrides.stop_on_pause(...) end },	--Cursed kill room safe 5 timer
		}
	}

	function GameInfoManager:init_timers_plugin()
		self._timers = self._timers or {}
	end
	
	function GameInfoManager:get_timers(key)
		if key then
			return self._timers[key]
		else
			return self._timers
		end
	end

	function GameInfoManager:_timer_event(event, key, ...)
		if event == "create" then
			if not self._timers[key] then	
				local unit, ext, device_type = ...
				local id = unit:editor_id()		
				self._timers[key] = { unit = unit, ext = ext, device_type = device_type, id = id, jammed = false, powered = true, upgradable = false }
				self:_listener_callback("timer", "create", key, self._timers[key])
			end
		elseif event == "destroy" then
			if self._timers[key] then
				GameInfoManager._TIMER_CALLBACKS.default.set_active(self._timers, key, false)
				self:_listener_callback("timer", "destroy", key, self._timers[key])
				self._timers[key] = nil
			end
		elseif self._timers[key] then
			local timer_id = self._timers[key].id
			local timer_override = GameInfoManager._TIMER_CALLBACKS.overrides[timer_id]
			
			if timer_override and timer_override[event] then
				timer_override[event](self._timers, key, ...)
			else
				GameInfoManager._TIMER_CALLBACKS.default[event](self._timers, key, ...)
			end
		end
	end

end

if RequiredScript == "lib/units/props/digitalgui" then
	
	local init_original = DigitalGui.init
	local update_original = DigitalGui.update
	local timer_set_original = DigitalGui.timer_set
	local timer_start_count_up_original = DigitalGui.timer_start_count_up
	local timer_start_count_down_original = DigitalGui.timer_start_count_down
	local timer_pause_original = DigitalGui.timer_pause
	local timer_resume_original = DigitalGui.timer_resume
	local _timer_stop_original = DigitalGui._timer_stop
	local load_original = DigitalGui.load
	local destroy_original = DigitalGui.destroy
	
	function DigitalGui:init(unit, ...)
		self._info_key = tostring(unit:key())
		self._ignore = self.TYPE == "number"	--Maybe need move to after init?
		return init_original(self, unit, ...)
	end
	
	function DigitalGui:update(unit, t, ...)
		update_original(self, unit, t, ...)
		self:_do_timer_callback("update", t, self._timer)
	end
	
	function DigitalGui:timer_set(timer, ...)
		if not self._info_created and Network:is_server() then
			self._info_created = true
			self:_do_timer_callback("create", self._unit, self, "digital")
		end
		self:_do_timer_callback("set", timer)
		return timer_set_original(self, timer, ...)
	end
	
	function DigitalGui:timer_start_count_up(...)
		self:_do_timer_callback("start_count_up")
		return timer_start_count_up_original(self, ...)
	end
	
	function DigitalGui:timer_start_count_down(...)
		self:_do_timer_callback("start_count_down")
		return timer_start_count_down_original(self, ...)
	end
	
	function DigitalGui:timer_pause(...)
		self:_do_timer_callback("pause")
		return timer_pause_original(self, ...)
	end
	
	function DigitalGui:timer_resume(...)
		self:_do_timer_callback("resume")
		return timer_resume_original(self, ...)
	end
	
	function DigitalGui:_timer_stop(...)
		self:_do_timer_callback("stop")
		return _timer_stop_original(self, ...)
	end
	
	function DigitalGui:load(data, ...)
		self:_do_timer_callback("create", self._unit, self, "digital")
	
		load_original(self, data, ...)
		
		local state = data.DigitalGui
		if state.timer then
			self:_do_timer_callback("set", state.timer)
		end
		if state.timer_count_up then
			self:_do_timer_callback("start_count_up")
		end
		if state.timer_count_down then
			self:_do_timer_callback("start_count_down")
		end
		if state.timer_paused then
			self:_do_timer_callback("pause")
		end
	end
	
	function DigitalGui:destroy(...)
		self:_do_timer_callback("destroy")
		return destroy_original(self, ...)
	end
	
	
	function DigitalGui:_do_timer_callback(event, ...)
		if not self._ignore then
			managers.gameinfo:event("timer", event, self._info_key, ...)
		end
	end
	
end

if RequiredScript == "lib/units/props/timergui" then
	
	local init_original = TimerGui.init
	local set_background_icons_original = TimerGui.set_background_icons
	local set_visible_original = TimerGui.set_visible
	local update_original = TimerGui.update
	local _start_original = TimerGui._start
	local _set_done_original = TimerGui._set_done
	local _set_jammed_original = TimerGui._set_jammed
	local _set_powered = TimerGui._set_powered
	local destroy_original = TimerGui.destroy
	
	function TimerGui:init(unit, ...)
		self._info_key = tostring(unit:key())
		local device_type = unit:base().is_drill and "drill" or unit:base().is_hacking_device and "hack" or unit:base().is_saw and "saw" or "timer"
		managers.gameinfo:event("timer", "create", self._info_key, unit, self, device_type)
		init_original(self, unit, ...)
	end
	
	function TimerGui:set_background_icons(...)
		local skills = self._unit:base().get_skill_upgrades and self._unit:base():get_skill_upgrades()
		
		if skills then
			local can_upgrade = false
			local interact_ext = self._unit:interaction()
			local pinfo = interact_ext and interact_ext.get_player_info_id and interact_ext:get_player_info_id()
			
			if skills and pinfo then
				for i, _ in pairs(interact_ext:split_info_id(pinfo)) do
					if not skills[i] then
						can_upgrade = true
						break
					end
				end
			end
			
			local upgrade_table = {
				restarter = (skills.auto_repair_level_1 or 0) + (skills.auto_repair_level_2 or 0),
				faster = (skills.speed_upgrade_level or 0),
				silent = (skills.reduced_alert and 1 or 0) + (skills.silent_drill and 1 or 0),
			}
			
			managers.gameinfo:event("timer", "set_upgradable", self._info_key, can_upgrade)
			managers.gameinfo:event("timer", "set_acquired_upgrades", self._info_key, upgrade_table)
		end
		
		return set_background_icons_original(self, ...)
	end
	
	function TimerGui:set_visible(visible, ...)
		if not visible and self._unit:base().is_drill then
			managers.gameinfo:event("timer", "set_active", self._info_key, false)
		end
		return set_visible_original(self, visible, ...)
	end
	
	function TimerGui:update(unit, t, dt, ...)
		update_original(self, unit, t, dt, ...)
		managers.gameinfo:event("timer", "update", self._info_key, t, self._time_left, 1 - self._current_timer / self._timer)
	end
	
	function TimerGui:_start(...)
		_start_original(self, ...)
		managers.gameinfo:event("timer", "set_active", self._info_key, true)
	end
	
	function TimerGui:_set_done(...)
		managers.gameinfo:event("timer", "set_active", self._info_key, false)
		return _set_done_original(self, ...)
	end
	
	function TimerGui:_set_jammed(jammed, ...)
		managers.gameinfo:event("timer", "set_jammed", self._info_key, jammed and true or false)
		return _set_jammed_original(self, jammed, ...)
	end
	
	function TimerGui:_set_powered(powered, ...)
		managers.gameinfo:event("timer", "set_powered", self._info_key, powered and true or false)
		return _set_powered(self, powered, ...)
	end
	
	function TimerGui:destroy(...)
		managers.gameinfo:event("timer", "destroy", self._info_key)
		return destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/props/securitylockgui" then
	
	local init_original = SecurityLockGui.init
	local update_original = SecurityLockGui.update
	local _start_original = SecurityLockGui._start
	local _set_done_original = SecurityLockGui._set_done
	local _set_jammed_original = SecurityLockGui._set_jammed
	local _set_powered = SecurityLockGui._set_powered
	local destroy_original = SecurityLockGui.destroy
	
	function SecurityLockGui:init(unit, ...)
		self._info_key = tostring(unit:key())
		managers.gameinfo:event("timer", "create", self._info_key, unit, self, "securitylock")
		init_original(self, unit, ...)
	end
	
	function SecurityLockGui:update(unit, t, ...)
		update_original(self, unit, t, ...)
		managers.gameinfo:event("timer", "update", self._info_key, t, self._current_timer, 1 - self._current_timer / self._timer)
	end
	
	function SecurityLockGui:_start(...)
		_start_original(self, ...)
		managers.gameinfo:event("timer", "set_active", self._info_key, true)
	end
	
	function SecurityLockGui:_set_done(...)
		managers.gameinfo:event("timer", "set_active", self._info_key, false)
		return _set_done_original(self, ...)
	end
	
	function SecurityLockGui:_set_jammed(jammed, ...)
		managers.gameinfo:event("timer", "set_jammed", self._info_key, jammed and true or false)
		return _set_jammed_original(self, jammed, ...)
	end
	
	function SecurityLockGui:_set_powered(powered, ...)
		managers.gameinfo:event("timer", "set_powered", self._info_key, powered and true or false)
		return _set_powered(self, powered, ...)
	end
	
	function SecurityLockGui:destroy(...)
		managers.gameinfo:event("timer", "destroy", self._info_key)
		return destroy_original(self, ...)
	end
	
end
