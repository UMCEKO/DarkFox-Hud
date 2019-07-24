local plugin = "ecms"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "ECMs", desc = "Handles ECM jammer and feedback timers" }, "init_ecms_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then
	
	function GameInfoManager:init_ecms_plugin()
		self._ecms = self._ecms or {}
	end
	
	function GameInfoManager:get_ecms(key)
		if key then
			return self._ecms[key]
		else
			return self._ecms
		end
	end
	
	function GameInfoManager:_ecm_event(event, key, data)
		if event == "create" then
			if self._ecms[key] then return end
			self._ecms[key] = { unit = data.unit, is_pocket_ecm = data.is_pocket_ecm, max_duration = data.max_duration, t = data.t, expire_t = data.expire_t }
			self:_listener_callback("ecm", event, key, self._ecms[key])
		elseif self._ecms[key] then
			if event == "set_jammer_battery" then
				if not self._ecms[key].jammer_active then return end
				self._ecms[key].jammer_battery = data.jammer_battery
			elseif event == "set_retrigger_delay" then
				if not self._ecms[key].retrigger_active then return end
				self._ecms[key].retrigger_delay = data.retrigger_delay
			elseif event == "set_jammer_active" then
				if self._ecms[key].jammer_active == data.jammer_active then return end
				self._ecms[key].jammer_active = data.jammer_active
			elseif event == "set_retrigger_active" then
				if self._ecms[key].retrigger_active == data.retrigger_active then return end
				self._ecms[key].retrigger_active = data.retrigger_active
			elseif event == "set_owner" then
				self._ecms[key].owner = data.owner
			elseif event == "set_upgrade_level" then
				self._ecms[key].upgrade_level = data.upgrade_level
			end
			
			self:_listener_callback("ecm", event, key, self._ecms[key])
			
			if event == "destroy" then
				self._ecms[key] = nil
			end
		end
	end

end

if RequiredScript == "lib/units/equipment/ecm_jammer/ecmjammerbase" then
	
	local init_original = ECMJammerBase.init
	local setup_original = ECMJammerBase.setup
	local sync_setup_original = ECMJammerBase.sync_setup
	local set_active_original = ECMJammerBase.set_active
	local _set_feedback_active_original = ECMJammerBase._set_feedback_active
	local update_original = ECMJammerBase.update
	local contour_interaction_original = ECMJammerBase.contour_interaction
	local destroy_original = ECMJammerBase.destroy
	
	function ECMJammerBase:init(unit, ...)
		self._ecm_unit_key = tostring(unit:key())
		managers.gameinfo:event("ecm", "create", self._ecm_unit_key, { unit = unit })
		return init_original(self, unit, ...)
	end
	
	function ECMJammerBase:setup(upgrade_lvl, owner, ...)
		managers.gameinfo:event("ecm", "set_owner", self._ecm_unit_key, { owner = owner })
		managers.gameinfo:event("ecm", "set_upgrade_level", self._ecm_unit_key, { upgrade_level = upgrade_lvl })
		return setup_original(self, upgrade_lvl, owner, ...)
	end
	
	function ECMJammerBase:sync_setup(upgrade_lvl, peer_id, ...)
		managers.gameinfo:event("ecm", "set_owner", self._ecm_unit_key, { owner = peer_id })
		managers.gameinfo:event("ecm", "set_upgrade_level", self._ecm_unit_key, { upgrade_level = upgrade_lvl })
		return sync_setup_original(self, upgrade_lvl, peer_id, ...)
	end
	
	function ECMJammerBase:set_active(active, ...)
		if self._jammer_active ~= active then
			managers.gameinfo:event("ecm", "set_jammer_active", self._ecm_unit_key, { jammer_active = active })
		end
		
		return set_active_original(self, active, ...)
	end
	
	function ECMJammerBase:_set_feedback_active(state, ...)
		if not state and self._feedback_active then
			local session = managers.network:session()
			local peer_id = session and session:local_peer():id()
			
			if peer_id and self._owner_id == peer_id and managers.player:has_category_upgrade("ecm_jammer", "can_retrigger") then
				self._retrigger_delay = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
				managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = true })
			end
		end
		
		return _set_feedback_active_original(self, state, ...)
	end
	
	function ECMJammerBase:update(unit, t, dt, ...)
		update_original(self, unit, t, dt, ...)
		
		if not self._battery_empty then
			managers.gameinfo:event("ecm", "set_jammer_battery", self._ecm_unit_key, { jammer_battery = self._battery_life })
		end
		
		if self._retrigger_delay then
			self._retrigger_delay = self._retrigger_delay - dt
			managers.gameinfo:event("ecm", "set_retrigger_delay", self._ecm_unit_key, { retrigger_delay = self._retrigger_delay })
			
			if self._retrigger_delay <= 0 then
				self._retrigger_delay = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
			end
		end
	end
	
	function ECMJammerBase:contour_interaction(...)
		if alive(self._unit) and managers.network:session() and (self._owner_id == managers.network:session():local_peer():id()) and managers.player:has_category_upgrade("ecm_jammer", "can_activate_feedback") then
			self._retrigger_delay = nil
			managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = false })
		end
		
		return contour_interaction_original(self, ...)
	end
	
	function ECMJammerBase:destroy(...)
		managers.gameinfo:event("ecm", "set_retrigger_active", self._ecm_unit_key, { retrigger_active = false })
		managers.gameinfo:event("ecm", "destroy", self._ecm_unit_key)
		destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/managers/group_ai_states/groupaistatebase" then

	local register_ecm_jammer_original = GroupAIStateBase.register_ecm_jammer
	
	function GroupAIStateBase:register_ecm_jammer(unit, jam_settings, ...)
		if alive(unit) and not (unit:base() and unit:base().battery_life_multiplier) then
			local key = tostring(unit:key())
			
			if jam_settings then
				local max_duration = tweak_data.upgrades.values.player.pocket_ecm_jammer_base[1].duration
				local t = Application:time()
				local expire_t = t + max_duration
				
				managers.gameinfo:event("ecm", "create", key, { is_pocket_ecm = true, unit = unit, t = t, expire_t = expire_t, max_duration = max_duration })
				managers.gameinfo:event("ecm", "set_jammer_active", key, { jammer_active = true })
			else
				managers.gameinfo:event("ecm", "set_jammer_active", key, { jammer_active = false })
				managers.gameinfo:event("ecm", "destroy", key)
			end
		end
		
		return register_ecm_jammer_original(self, unit, jam_settings, ...)
	end

end