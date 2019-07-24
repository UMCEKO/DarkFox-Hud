local plugin = "pagers"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Pagers", desc = "Handles pager events for timers and counters" }, "init_pagers_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	function GameInfoManager:init_pagers_plugin()
		self._pagers = self._pagers or {}
	end
	
	function GameInfoManager:get_pagers(key)
		if key then
			return self._pagers[key]
		else
			return self._pagers
		end
	end
	
	function GameInfoManager:_pager_event(event, key, data)
		if event == "add" then
			if not self._pagers[key] then
				local t = Application:time()
				
				self._pagers[key] = { 
					unit = data.unit, 
					active = true, 
					answered = false,
					start_t = t,
					expire_t = t + 12,
				}
				self:_listener_callback("pager", "add", key, self._pagers[key])
			end
		elseif self._pagers[key] then
			if event == "remove" then
				if self._pagers[key].active then
					self:_listener_callback("pager", "remove", key, self._pagers[key])
					self._pagers[key].active = nil
				end
			elseif event == "set_answered" then
				if not self._pagers[key].answered then
					self._pagers[key].answered = true
					self:_listener_callback("pager", "set_answered", key, self._pagers[key])
				end
			end
		end
	end
	
	local _interactive_unit_event_original = GameInfoManager._interactive_unit_event
	
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if data.interact_id == "corpse_alarm_pager" then
			self:_pager_event(event, key, data)
		end
		
		return _interactive_unit_event_original(self, event, key, data)
	end
	
end

if RequiredScript == "lib/managers/objectinteractionmanager" then

	local interact_original = ObjectInteractionManager.interact

	function ObjectInteractionManager:interact(...)
		if alive(self._active_unit) and self._active_unit:interaction().tweak_data == "corpse_alarm_pager" then
			managers.gameinfo:event("pager", "set_answered", tostring(self._active_unit:key()))
		end
		
		return interact_original(self, ...)
	end
	
end

if RequiredScript == "lib/network/handlers/unitnetworkhandler" then
	
	local interaction_set_active_original = UnitNetworkHandler.interaction_set_active
	local alarm_pager_interaction_original = UnitNetworkHandler.alarm_pager_interaction
	
	function UnitNetworkHandler:interaction_set_active(unit, u_id, active, tweak_data, flash, sender, ...)
		if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_sender(sender) then
			if tweak_data == "corpse_alarm_pager" then
				if not alive(unit) then
					local u_data = managers.enemy:get_corpse_unit_data_from_id(u_id)
					unit = u_data and u_data.unit
				end
				
				
				if alive(unit) then
					if not active then
						--managers.gameinfo:event("pager", "remove", tostring(unit:key()))
					elseif not flash then
						managers.gameinfo:event("pager", "set_answered", tostring(unit:key()))
					end
				end
			end
		end

		return interaction_set_active_original(self, unit, u_id, active, tweak_data, flash, sender, ...)
	end
	
	function UnitNetworkHandler:alarm_pager_interaction(u_id, tweak_table, status, sender, ...)
		if self._verify_gamestate(self._gamestate_filter.any_ingame) then
			local unit_data = managers.enemy:get_corpse_unit_data_from_id(u_id)
			if unit_data and unit_data.unit:interaction():active() and unit_data.unit:interaction().tweak_data == tweak_table and self._verify_sender(sender) then
				if status == 1 then
					managers.gameinfo:event("pager", "set_answered", tostring(unit_data.unit:key()))
				else
					--managers.gameinfo:event("pager", "remove", tostring(unit_data.unit:key()))
				end
			end
		end
	
		return alarm_pager_interaction_original(self, u_id, tweak_table, status, sender, ...)
	end
	
end
