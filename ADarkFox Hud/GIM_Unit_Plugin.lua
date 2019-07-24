local plugin = "units"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Units", desc = "Handles various unit tracking tasks, e.g. for counters" }, "init_unit_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	function GameInfoManager:init_unit_plugin()
		self._units = self._units or {}
		self._unit_count = self._unit_count or {}
		self._minions = self._minions or {}
		self._turrets = self._turrets or {}
	end
	
	function GameInfoManager:get_units(key)
		if key then
			return self._units[key]
		else
			return self._units
		end
	end
	
	function GameInfoManager:get_unit_count(id)
		if id then
			return self._unit_count[id] or 0
		else
			return self._unit_count
		end
	end
	
	function GameInfoManager:get_minions(key)
		if key then
			return self._minions[key]
		else
			return self._minions
		end
	end
	
	function GameInfoManager:get_turrets(key)
		if key then
			return self._turrets[key]
		else
			return self._turrets
		end
	end
	
	function GameInfoManager:_unit_event(event, key, data)
		if event == "add" then
			if not self._units[key] then
				local unit_type = data.unit:base()._tweak_table
				self._units[key] = { unit = data.unit, type = unit_type }
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", unit_type, 1)
			end
		elseif event == "remove" then
			if self._units[key] then
				self:_listener_callback("unit", event, key, self._units[key])
				self:_unit_count_event("change", self._units[key].type, -1)
				self._units[key] = nil
				
				if self._minions[key] then
					self:_minion_event("remove", key)
				end
			end
		end
	end
	
	function GameInfoManager:_unit_count_event(event, unit_type, value)
		if event == "change" then
			if value ~= 0 then
				self._unit_count[unit_type] = (self._unit_count[unit_type] or 0) + value
				self:_listener_callback("unit_count", "change", unit_type, value)
			end
		elseif event == "set" then
			self:_unit_count_event("change", unit_type, value - (self._unit_count[unit_type] or 0))
		end
	end
	
	function GameInfoManager:_minion_event(event, key, data)
		if event == "add" then
			if not self._minions[key] then
				self._minions[key] = { unit = data.unit, kills = 0, type = data.unit:base()._tweak_table }
				self:_listener_callback("minion", "add", key, self._minions[key])
				self:_unit_count_event("change", "minion", 1)
			end
		elseif self._minions[key] then
			if event == "set_health_ratio" then
				self._minions[key].health_ratio = data.health_ratio
			elseif event == "increment_kills" then
				self._minions[key].kills = self._minions[key].kills + 1
			elseif event == "set_owner" then
				self._minions[key].owner = data.owner
			elseif event == "set_damage_resistance" then
				self._minions[key].damage_resistance = data.damage_resistance
			elseif event == "set_damage_multiplier" then
				self._minions[key].damage_multiplier = data.damage_multiplier
			end
			
			self:_listener_callback("minion", event, key, self._minions[key])
			
			if event == "remove" then
				self:_unit_count_event("change", "minion", -1)
				self._minions[key] = nil
			end
		end
	end
	
	function GameInfoManager:_turret_event(event, key, unit)
		if event == "add" then
			if not self._turrets[key] then
				self._turrets[key] = unit
				self:_unit_count_event("change", "turret", 1)
			end
		elseif event == "remove" then
			if self._turrets[key] then
				self:_unit_count_event("change", "turret", -1)
				self._turrets[key] = nil
			end
		end
	end
	
end

if RequiredScript == "lib/managers/enemymanager" then
	
	local on_enemy_registered_original = EnemyManager.on_enemy_registered
	local on_enemy_unregistered_original = EnemyManager.on_enemy_unregistered
	local register_civilian_original = EnemyManager.register_civilian
	local on_civilian_died_original = EnemyManager.on_civilian_died
	local on_civilian_destroyed_original = EnemyManager.on_civilian_destroyed
	
	function EnemyManager:on_enemy_registered(unit, ...)
		managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
		return on_enemy_registered_original(self, unit, ...)
	end
	
	function EnemyManager:on_enemy_unregistered(unit, ...)
		managers.gameinfo:event("unit", "remove", tostring(unit:key()))
		return on_enemy_unregistered_original(self, unit, ...)
	end
	
	function EnemyManager:register_civilian(unit, ...)
		managers.gameinfo:event("unit", "add", tostring(unit:key()), { unit = unit })
		return register_civilian_original(self, unit, ...)
	end
	
	function EnemyManager:on_civilian_died(unit, ...)
		managers.gameinfo:event("unit", "remove", tostring(unit:key()))
		return on_civilian_died_original(self, unit, ...)
	end
	
	function EnemyManager:on_civilian_destroyed(unit, ...)
		managers.gameinfo:event("unit", "remove", tostring(unit:key()))
		return on_civilian_destroyed_original(self, unit, ...)
	end
	
end

if RequiredScript == "lib/managers/group_ai_states/groupaistatebase" then
	
	local update_original = GroupAIStateBase.update
	local on_hostage_state_original = GroupAIStateBase.on_hostage_state
	local sync_hostage_headcount_original = GroupAIStateBase.sync_hostage_headcount
	local convert_hostage_to_criminal_original = GroupAIStateBase.convert_hostage_to_criminal
	local sync_converted_enemy_original = GroupAIStateBase.sync_converted_enemy
	local register_turret_original = GroupAIStateBase.register_turret
	local unregister_turret_original = GroupAIStateBase.unregister_turret
	
	function GroupAIStateBase:update(t, ...)
		if self._client_hostage_count_expire_t then
			if t < self._client_hostage_count_expire_t then
				self:_client_hostage_count_cbk()
			else
				self._client_hostage_count_expire_t = nil
			end
		end
		
		return update_original(self, t, ...)
	end
	
	function GroupAIStateBase:on_hostage_state(...)
		on_hostage_state_original(self, ...)
		self:_update_hostage_count()
	end
	
	function GroupAIStateBase:sync_hostage_headcount(...)
		sync_hostage_headcount_original(self, ...)
		
		if Network:is_server() then
			self:_update_hostage_count()
		else
			self._client_hostage_count_expire_t = self._t + 10
		end
	end
	
	function GroupAIStateBase:convert_hostage_to_criminal(unit, peer_unit, ...)
		convert_hostage_to_criminal_original(self, unit, peer_unit, ...)
		
		if unit:brain()._logic_data.is_converted then
			local key = tostring(unit:key())
			local peer_id = peer_unit and managers.network:session():peer_by_unit(peer_unit):id() or managers.network:session():local_peer():id()
			local owner_base = peer_unit and peer_unit:base() or managers.player
			local damage_mult = (owner_base:upgrade_value("player", "convert_enemies_damage_multiplier", 1) or 1)
			
			managers.gameinfo:event("minion", "add", key, { unit = unit })
			managers.gameinfo:event("minion", "set_owner", key, { owner = peer_id })
			if damage_mult > 1 then
				managers.gameinfo:event("minion", "set_damage_multiplier", key, { damage_multiplier = damage_mult })
			end
		end
	end
	
	function GroupAIStateBase:sync_converted_enemy(converted_enemy, ...)
		managers.gameinfo:event("minion", "add", tostring(converted_enemy:key()), { unit = converted_enemy })
		return sync_converted_enemy_original(self, converted_enemy, ...)
	end
	
	function GroupAIStateBase:register_turret(unit, ...)
		managers.gameinfo:event("turret", "add", tostring(unit:key()), unit)
		return register_turret_original(self, unit, ...)
	end
	
	function GroupAIStateBase:unregister_turret(unit, ...)
		managers.gameinfo:event("turret", "remove", tostring(unit:key()), unit)
		return unregister_turret_original(self, unit, ...)
	end
	
	
	function GroupAIStateBase:_client_hostage_count_cbk()
		local police_hostages = 0
		local police_hostages_mk2 = 0
		local civilian_hostages = self._hostage_headcount
	
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			if u_data and u_data.unit and u_data.unit.anim_data and u_data.unit:anim_data() then
				if u_data.unit:anim_data().surrender then
					police_hostages = police_hostages + 1
				end
			end
		end
		
		civilian_hostages = civilian_hostages - police_hostages
		managers.gameinfo:event("unit_count", "set", "civ_hostage", civilian_hostages)
		managers.gameinfo:event("unit_count", "set", "cop_hostage", police_hostages)
	end
	
	function GroupAIStateBase:_update_hostage_count()
		if Network:is_server() then
			managers.gameinfo:event("unit_count", "set", "civ_hostage", self._hostage_headcount - self._police_hostage_headcount)
			managers.gameinfo:event("unit_count", "set", "cop_hostage", self._police_hostage_headcount)
		else
			self:_client_hostage_count_cbk()
		end
	end
	
end

if RequiredScript == "lib/network/handlers/unitnetworkhandler" then

	local mark_minion_original = UnitNetworkHandler.mark_minion
	local hostage_trade_original = UnitNetworkHandler.hostage_trade
	local unit_traded_original = UnitNetworkHandler.unit_traded
	
	function UnitNetworkHandler:mark_minion(unit, owner_id, joker_level, ...)
		mark_minion_original(self, unit, owner_id, joker_level, ...)
		
		if alive(unit) and unit:in_slot(16) then
			local key = tostring(unit:key())
			local damage_mult = managers.player:upgrade_value_by_level("player", "convert_enemies_damage_multiplier", joker_level, 1)

			managers.gameinfo:event("minion", "add", key, { unit = unit })
			managers.gameinfo:event("minion", "set_owner", key, { owner = owner_id })
			if damage_mult > 1 then
				managers.gameinfo:event("minion", "set_damage_multiplier", key, { damage_multiplier = damage_mult })
			end
		end
	end
	
	function UnitNetworkHandler:hostage_trade(unit, ...)
		if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
			managers.gameinfo:event("minion", "remove", tostring(unit:key()))
		end
		
		return hostage_trade_original(self, unit, ...)
	end
	
	function UnitNetworkHandler:unit_traded(unit, ...)
		if self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit) then
			managers.gameinfo:event("minion", "remove", tostring(unit:key()))
		end
		
		return unit_traded_original(self, unit, ...)
	end
	
end

if RequiredScript == "lib/units/enemies/cop/copdamage" then
	
	local convert_to_criminal_original = CopDamage.convert_to_criminal
	local _on_damage_received_original = CopDamage._on_damage_received
	local chk_killshot_original = CopDamage.chk_killshot
	
	function CopDamage:convert_to_criminal(...)
		convert_to_criminal_original(self, ...)
		
		if self._damage_reduction_multiplier < 1 then
			local key = tostring(self._unit:key())
			local data = { damage_resistance = self._damage_reduction_multiplier }
			managers.enemy:add_delayed_clbk(key .. "_update_minion_dmg_resist", callback(self, self, "_update_minion_dmg_resist", data), 0)
		end
	end
	
	function CopDamage:_on_damage_received(damage_info, ...)
		if self._unit:in_slot(16) then
			managers.gameinfo:event("minion", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
		end
		return _on_damage_received_original(self, damage_info, ...)
	end
	
	function CopDamage:chk_killshot(attacker_unit, ...)
		if alive(attacker_unit) then
			local key = tostring(attacker_unit:key())
			
			if attacker_unit:in_slot(16) and managers.gameinfo:get_minions(key) then
				managers.gameinfo:event("minion", "increment_kills", key)
			end
		end
		
		return chk_killshot_original(self, attacker_unit, ...)
	end
	
	
	function CopDamage:_update_minion_dmg_resist(data)
		if alive(self._unit) then
			managers.gameinfo:event("minion", "set_damage_resistance", tostring(self._unit:key()), data)
		end
	end
	
end
