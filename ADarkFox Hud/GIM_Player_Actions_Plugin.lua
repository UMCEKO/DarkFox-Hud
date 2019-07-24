local plugin = "player_actions"

--BLT bug screws with certain library scripts that are require'd more than once
GIM_LOADED_SCRIPTS = GIM_LOADED_SCRIPTS or {}
GIM_LOADED_SCRIPTS[plugin] = GIM_LOADED_SCRIPTS[plugin] or {}
if GIM_LOADED_SCRIPTS[plugin][RequiredScript] then return end
GIM_LOADED_SCRIPTS[plugin][RequiredScript] = true

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Player Actions", desc = "Handles tracking of player action timers/charges" }, "init_player_actions_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then
	
	function GameInfoManager:init_player_actions_plugin()
		self._player_actions = self._player_actions or {}
	end
	
	function GameInfoManager:get_player_actions(id)
		if id then
			return self._player_actions[id]
		else
			return self._player_actions
		end
	end
	
	function GameInfoManager:_player_action_event(event, id, data)
		if event == "activate" then
			if self._player_actions[id] then return end
			self._player_actions[id] = {}
		elseif self._player_actions[id] then
			if event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or (data.duration + t)
				self._player_actions[id].t = t
				self._player_actions[id].expire_t = expire_t
			elseif event == "set_value" then
				self._player_actions[id].value = data.value
			elseif event == "set_expire" then
				local expire_t = data.duration and (data.duration + Application:time()) or data.expire_t
				return self:_player_action_event("set_duration", id, { t = self._player_actions[id].t, expire_t = expire_t })
			elseif event == "change_expire" then
				local expire_t = data.difference and (self._player_actions[id].expire_t + data.difference) or data.expire_t
				return self:_player_action_event("set_duration", id, { t = self._player_actions[id].t, expire_t = expire_t })
			end
		else
			return
		end
		
		--printf("(%.2f) GameInfoManager:_player_action_event(%s, %s)", Application:time(), event, id)
		--for k, v in pairs(self._player_actions[id]) do
		--	printf("\t%s: %s", tostring(k), tostring(v))
		--end
		
		self:_listener_callback("player_action", event, id, self._player_actions[id])
		
		if event == "deactivate" then
			self._player_actions[id] = nil
		end
	end
	
end


if RequiredScript == "lib/units/beings/player/states/playerstandard" then

	local _start_action_interact_original = PlayerStandard._start_action_interact
	local _interupt_action_interact_original = PlayerStandard._interupt_action_interact
	local _start_action_reload_original = PlayerStandard._start_action_reload
	local _update_reload_timers_original = PlayerStandard._update_reload_timers
	local _interupt_action_reload_original = PlayerStandard._interupt_action_reload
	local _start_action_melee_original = PlayerStandard._start_action_melee
	local _interupt_action_melee_original = PlayerStandard._interupt_action_melee
	local _do_melee_damage_original = PlayerStandard._do_melee_damage
	local _start_action_charging_weapon_original = PlayerStandard._start_action_charging_weapon
	local _end_action_charging_weapon_original = PlayerStandard._end_action_charging_weapon
	
	local RELOADING = false
	
	function PlayerStandard:_start_action_interact(t, input, timer, interact_object, ...)
		managers.gameinfo:event("player_action", "activate", "interact")
		managers.gameinfo:event("player_action", "set_duration", "interact", { duration = timer })
		managers.gameinfo:event("player_action", "set_value", "interact", { value = { unit = interact_object, tweak = interact_object:interaction().tweak_data } })
		
		return _start_action_interact_original(self, t, input, timer, interact_object, ...)
	end
	
	function PlayerStandard:_interupt_action_interact(t, input, complete, ...)
		if self._interact_expire_t then
			managers.gameinfo:event("player_action", "deactivate", "interact")
		end
		
		return _interupt_action_interact_original(self, t, input, complete, ...)
	end
	
	function PlayerStandard:_start_action_reload(t, ...)
		_start_action_reload_original(self, t, ...)
		
		if self._state_data.reload_expire_t then
			RELOADING = true
			managers.gameinfo:event("player_action", "activate", "reload")
			managers.gameinfo:event("player_action", "set_duration", "reload", { duration = self._state_data.reload_expire_t - t })
		end
	end
	
	function PlayerStandard:_update_reload_timers(...)
		_update_reload_timers_original(self, ...)
		
		if RELOADING and not self._state_data.reload_expire_t then
			RELOADING = false
			managers.gameinfo:event("player_action", "deactivate", "reload")
		end
	end
	
	function PlayerStandard:_interupt_action_reload(...)
		if self._state_data.reload_expire_t then
			RELOADING = false
			managers.gameinfo:event("player_action", "deactivate", "reload")
		end
		
		return _interupt_action_reload_original(self, ...)
	end
	
	function PlayerStandard:_start_action_melee(t, input, instant, ...)
		if not instant then
			local duration = tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()].stats.charge_time
			managers.gameinfo:event("player_action", "activate", "melee_charge")
			managers.gameinfo:event("player_action", "set_duration", "melee_charge", { duration = duration })
		end
		
		return _start_action_melee_original(self, t, input, instant, ...)
	end
	
	function PlayerStandard:_interupt_action_melee(...)
		if self._state_data.melee_start_t then
			managers.gameinfo:event("player_action", "deactivate", "melee_charge")
		end
		
		return _interupt_action_melee_original(self, ...)
	end
	
	function PlayerStandard:_do_melee_damage(...)
		if self._state_data.melee_start_t then
			managers.gameinfo:event("player_action", "deactivate", "melee_charge")
		end
		
		return _do_melee_damage_original(self, ...)
	end
	
	function PlayerStandard:_start_action_charging_weapon(...)
		managers.gameinfo:event("player_action", "activate", "weapon_charge")
		managers.gameinfo:event("player_action", "set_duration", "weapon_charge", { duration = self._equipped_unit:base():charge_max_t() })
		return _start_action_charging_weapon_original(self, ...)
	end
	
	function PlayerStandard:_end_action_charging_weapon(...)
		managers.gameinfo:event("player_action", "deactivate", "weapon_charge")
		return _end_action_charging_weapon_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/beings/player/playerdamage" then
	
	local set_armor_original = PlayerDamage.set_armor
	local change_regenerate_speed_original = PlayerDamage.change_regenerate_speed
	local _on_damage_event_original = PlayerDamage._on_damage_event
	local _update_armor_grinding_original = PlayerDamage._update_armor_grinding
	
	local ARMOR_GRIND_ACTIVE = false
	
	function PlayerDamage:set_armor(armor, ...)
		set_armor_original(self, armor, ...)
		
		if armor >= self:_max_armor() then
			ARMOR_GRIND_ACTIVE = false
			managers.gameinfo:event("player_action", "deactivate", "anarchist_armor_regeneration")
			managers.gameinfo:event("player_action", "deactivate", "standard_armor_regeneration")
		elseif self._armor_grinding then
			if not ARMOR_GRIND_ACTIVE then
				ARMOR_GRIND_ACTIVE = true
				local t = Application:time()
				local t_start = t - self._armor_grinding.elapsed
				local expire_t = t_start + self._armor_grinding.target_tick
				managers.gameinfo:event("player_action", "activate", "anarchist_armor_regeneration")
				managers.gameinfo:event("player_action", "set_value", "anarchist_armor_regeneration", { value = self._armor_grinding.armor_value })
				managers.gameinfo:event("player_action", "set_duration", "anarchist_armor_regeneration", { t = t_start, expire_t = expire_t })
			end
		end
	end
	
	function PlayerDamage:change_regenerate_speed(...)
		change_regenerate_speed_original(self, ...)
		self:_check_armor_regen_timer()
	end
	
	function PlayerDamage:_on_damage_event(...)
		_on_damage_event_original(self, ...)
		self:_check_armor_regen_timer(true)
	end
	
	function PlayerDamage:_update_armor_grinding(t, ...)
		_update_armor_grinding_original(self, t, ...)
		
		if ARMOR_GRIND_ACTIVE and self._armor_grinding.elapsed == 0 then
			managers.gameinfo:event("player_action", "set_duration", "anarchist_armor_regeneration", { duration = self._armor_grinding.target_tick })
		end
	end
	
	
	local REGEN_EXPIRE_T = 0
	function PlayerDamage:_check_armor_regen_timer(reset)
		if not self._armor_grinding and self._regenerate_timer and self:get_real_armor() < self:_max_armor() then
			local t = managers.player:player_timer():time()
			local armor_regen_delay = self._regenerate_timer / (self._regenerate_speed or 1)
			local suppression_delay = 0
			
			if self._supperssion_data.decay_start_t and self._supperssion_data.value == tweak_data.player.suppression.max_value then
				suppression_delay = self._supperssion_data.decay_start_t - t
			end
			
			local expire_t = t + armor_regen_delay + suppression_delay
			
			if expire_t ~= REGEN_EXPIRE_T then
				REGEN_EXPIRE_T = expire_t
				managers.gameinfo:event("player_action", "activate", "standard_armor_regeneration")
				managers.gameinfo:event("player_action", reset and "set_duration" or "set_expire", "standard_armor_regeneration", { duration = armor_regen_delay + suppression_delay })
			end
		end
	end
	
end
