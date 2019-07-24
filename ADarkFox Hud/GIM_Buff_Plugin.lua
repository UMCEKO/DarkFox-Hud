local plugin = "buffs"

--BLT bug screws with certain library scripts that are require'd more than once
GIM_LOADED_SCRIPTS = GIM_LOADED_SCRIPTS or {}
GIM_LOADED_SCRIPTS[plugin] = GIM_LOADED_SCRIPTS[plugin] or {}
if GIM_LOADED_SCRIPTS[plugin][RequiredScript] then return end
GIM_LOADED_SCRIPTS[plugin][RequiredScript] = true

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Buffs", desc = "Handles tracking of player buff/debuffs and status effects" }, "init_buffs_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then
	
	GameInfoManager._BUFFS = {
		definitions = {
			temporary = {
				chico_injector =									{ "chico_injector", },
				damage_speed_multiplier =						{ "second_wind" },
				team_damage_speed_multiplier_received =	{ "second_wind" },
				dmg_multiplier_outnumbered =					{ "underdog" },
				dmg_dampener_outnumbered =						{ "underdog_aced" },
				dmg_dampener_outnumbered_strong =			{ "overdog" },
				dmg_dampener_close_contact =					{ "close_contact", "close_contact", "close_contact" },
				overkill_damage_multiplier =					{ "overkill" },
				berserker_damage_multiplier =					{ "swan_song", "swan_song_aced" },
				first_aid_damage_reduction =					{ "quick_fix" },
				increased_movement_speed =						{ "running_from_death_move_speed" },
				reload_weapon_faster =							{ "running_from_death_reload_speed" },
				revived_damage_resist =							{ "up_you_go" },
				swap_weapon_faster =								{ "running_from_death_swap_speed" },
				single_shot_fast_reload =						{ "aggressive_reload_aced" },
				armor_break_invulnerable =						{ "armor_break_invulnerable_debuff" },
				loose_ammo_restore_health =					{ "medical_supplies_debuff" },
				melee_life_leech =								{ "life_drain_debuff" },
				loose_ammo_give_team =							{ "ammo_give_out_debuff" },
				revive_damage_reduction =						{ "combat_medic_success" },
				unseen_strike =									{ "unseen_strike", "unseen_strike" },
				pocket_ecm_kill_dodge =							{ "pocket_ecm_kill_dodge" },
			},
			property = {
				bloodthirst_reload_speed =						{ "bloodthirst_aced" },
				revived_damage_reduction =						{ "pain_killer" },
				revive_damage_reduction =						{ "combat_medic_interaction" },
				bullet_storm =										{ "bullet_storm" },
				shock_and_awe_reload_multiplier =			{ "lock_n_load" },
				trigger_happy =									{ "trigger_happy" },
				desperado =											{ "desperado" },
				bipod_deploy_multiplier =						false,
			},
			cooldown = {
				long_dis_revive =									{ "inspire_revive_debuff" },
			},
			team = {
				damage_dampener = {
					team_damage_reduction =						{ "cc_passive_damage_reduction" },
					hostage_multiplier =							{ "cc_hostage_damage_reduction" },
				},
				stamina = {
					passive_multiplier = 						{ "cc_passive_stamina_multiplier" },
					hostage_multiplier =							{ "cc_hostage_stamina_multiplier" },
				},
				health = {
					passive_multiplier =							{ "cc_passive_health_multiplier" },
					hostage_multiplier =							{ "cc_hostage_health_multiplier" },
				},
				armor = {
					multiplier =									{ "cc_passive_armor_multiplier" },
					passive_regen_time_multiplier =			{ "armorer_armor_regen_multiplier" },
					regen_time_multiplier =						{ "shock_and_awe" },
				},
				damage = {
					hostage_absorption =							{ "forced_friendship" },
				},
			},
		},
		event_clbks = {
			activate = {
				armor_break_invulnerable_debuff = function()
					local duration = managers.player:upgrade_value("temporary", "armor_break_invulnerable")[1]
					managers.gameinfo:event("buff", "activate", "armor_break_invulnerable")
					managers.gameinfo:event("buff", "set_duration", "armor_break_invulnerable", { duration = duration })
				end,
			},
			set_duration = {
				overkill = function(id, data)
					if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
						local duration = managers.player:upgrade_value("temporary", "overkill_damage_multiplier")[2]
						managers.gameinfo:event("buff", "activate", "overkill_aced")
						managers.gameinfo:event("buff", "set_duration", "overkill_aced", { duration = duration })
					end
				end,
			},
			set_value = {
				overkill = function(id, data)
					if managers.player:has_category_upgrade("player", "overkill_all_weapons") then
						local value = managers.player:upgrade_value("temporary", "overkill_damage_multiplier")[1]
						managers.gameinfo:event("buff", "set_value", "overkill_aced", { value = value })
					end
				end,
			},
		},
	}
	
	function GameInfoManager:init_buffs_plugin()
		self._buffs = self._buffs or {}
		self._team_buffs = self._team_buffs or {}
		
		self:add_scheduled_callback("init_local_team_buffs", 0, function()
			for category, data in pairs(Global.player_manager.team_upgrades or {}) do
				for upgrade, value in pairs(data) do
					managers.gameinfo:event("team_buff", "activate", 0, category, upgrade, 1)
				end
			end
		end)
	end
	
	function GameInfoManager:get_buffs(id)
		if id then
			return self._buffs[id]
		else
			return self._buffs
		end
	end
	
	function GameInfoManager:get_player_actions(id)
		if id then
			return self._player_actions[id]
		else
			return self._player_actions
		end
	end
	
	
	function GameInfoManager:_buff_event(event, id, data)
		if event == "activate" then
			if self._buffs[id] then return end
			self._buffs[id] = {}
		elseif self._buffs[id] then
			if event == "set_duration" then
				local t = data.t or Application:time()
				local expire_t = data.expire_t or (data.duration + t)
				
				if self._buffs[id].t == t and 
					self._buffs[id].expire_t == expire_t and 
					self._buffs[id].no_expire == data.no_expire then 
						return
				end
				
				self._buffs[id].t = t
				self._buffs[id].expire_t = expire_t
				self._buffs[id].no_expire = data.no_expire
				
				if not self._buffs[id].no_expire then
					self:add_scheduled_callback(id .. "_expire", expire_t - Application:time(), callback(self, self, "_buff_event"), "deactivate", id)
				end
			elseif event == "set_value" then
				if self._buffs[id].value == data.value then return end
				self._buffs[id].value = data.value
			elseif event == "set_stack_count" then
				if self._buffs[id].stack_count == data.stack_count then return end
				self._buffs[id].stack_count = data.stack_count
			elseif event == "set_expire" then
				local expire_t = data.duration and (data.duration + Application:time()) or data.expire_t
				return self:_buff_event("set_duration", id, { t = self._buffs[id].t, expire_t = expire_t, no_expire = self._buffs[id].no_expire })
			elseif event == "change_expire" then
				local expire_t = data.difference and (self._buffs[id].expire_t + data.difference) or data.expire_t
				return self:_buff_event("set_duration", id, { t = self._buffs[id].t, expire_t = expire_t, no_expire = self._buffs[id].no_expire })
			elseif event == "increment_stack_count" then
				return self:_buff_event("set_stack_count", id, { stack_count = (self._buffs[id].stack_count or 0) + 1 })
			elseif event == "decrement_stack_count" then
				return self:_buff_event("set_stack_count", id, { stack_count = (self._buffs[id].stack_count or 0) - 1 })
			end
		else
			return
		end
		
		--printf("(%.2f) GameInfoManager:_buff_event(%s, %s)", Application:time(), event, id)
		--[[
		for k, v in pairs(self._buffs[id]) do
			printf("\t%s: %s", tostring(k), tostring(v))
		end
		]]
		self:_listener_callback("buff", event, id, self._buffs[id])
		
		local event_clbk = GameInfoManager._BUFFS.event_clbks[event] and GameInfoManager._BUFFS.event_clbks[event][id]
		if event_clbk then
			event_clbk(id, self._buffs[id])
		end
		
		if event == "deactivate" then
			if not self._buffs[id].no_expire then
				self:remove_scheduled_callback(id .. "_expire")
			end
			self._buffs[id] = nil
		end
	end
	
	function GameInfoManager:_temporary_buff_event(event, category, upgrade, level, data)		
		local defs = GameInfoManager._BUFFS.definitions
		local buff_data = defs[category] and defs[category][upgrade]
		
		if buff_data then
			local id = buff_data[level or 1]
			
			if id and not buff_data.ignore then
				self:_buff_event(event, id, data)
			end
		elseif buff_data == nil then
			printf("(%.2f) GameInfoManager:_temporary_buff_event(%s): Unrecognized buff %s %s %s", Application:time(), event, tostring(category), tostring(upgrade), tostring(level))
		end
	end
	
	function GameInfoManager:_team_buff_event(event, peer_id, category, upgrade, level, data)
		local defs = GameInfoManager._BUFFS.definitions.team
		local id = defs[category] and defs[category][upgrade] and defs[category][upgrade][level]
		
		if id then
			self._team_buffs[id] = self._team_buffs[id] or {}
			local was_active = next(self._team_buffs[id])
			
			if event == "activate" then
				self._team_buffs[id][peer_id] = true
				
				if not was_active then
					self:_buff_event(event, id)
				end
			elseif event == "deactivate" then
				self._team_buffs[id][peer_id] = nil
				
				if was_active and not next(self._team_buffs[id]) then
					self:_buff_event(event, id)
				end
			elseif event == "set_value" then
				self:_buff_event(event, id, data)
			end
		else
			printf("(%.2f) GameInfoManager:_team_buff_event(%s, %s): Unrecognized buff %s %s %s", Application:time(), event, tostring(peer_id), tostring(category), tostring(upgrade), tostring(level))
		end
	end
	
	local STACK_ID = 0
	function GameInfoManager:_timed_stack_buff_event(event, id, data)
		if event == "add_timed_stack" then
			if not self._buffs[id] then
				self:_buff_event("activate", id, data)
				self._buffs[id].stacks = {}
			end
			
			local ct = Application:time()
			local t = data.t or ct
			local expire_t = data.expire_t or (data.duration + t)
			local value = data.value
			self._buffs[id].stacks[STACK_ID] = { t = t, expire_t = expire_t, value = value }
			self:add_scheduled_callback(string.format("%s_%s", id, STACK_ID), expire_t - ct, callback(self, self, "_timed_stack_buff_event"), "remove_timed_stack", id, { stack_id = STACK_ID })
			
			STACK_ID = (STACK_ID + 1) % 10000
			
			self:_listener_callback("buff", event, id, self._buffs[id])
			--self:_buff_event("increment_stack_count", id)
		elseif self._buffs[id] and self._buffs[id].stacks then
			if event == "remove_timed_stack" then
				if self._buffs[id].stacks[data.stack_id] then
					self._buffs[id].stacks[data.stack_id] = nil
					self:remove_scheduled_callback(id .. "_" .. data.stack_id)
					self:_listener_callback("buff", event, id, self._buffs[id])
					--self:_buff_event("decrement_stack_count", id)
					
					if not next(self._buffs[id].stacks) then
						self:_buff_event("deactivate", id, data)
					end
				end
			end
		end
	end
	
	function GameInfoManager:_player_weapon_event(event, key, data)
		self:_listener_callback("player_weapon", event, key, data)
	end
	
end

if RequiredScript == "lib/managers/playermanager" then
	
	local check_skills_original = PlayerManager.check_skills
	local activate_temporary_upgrade_original = PlayerManager.activate_temporary_upgrade
	local activate_temporary_upgrade_by_level_original = PlayerManager.activate_temporary_upgrade_by_level
	local deactivate_temporary_upgrade_original = PlayerManager.deactivate_temporary_upgrade
	local disable_cooldown_upgrade_original = PlayerManager.disable_cooldown_upgrade
	local replenish_grenades_original = PlayerManager.replenish_grenades
	local _on_grenade_cooldown_end_original = PlayerManager._on_grenade_cooldown_end
	local speed_up_grenade_cooldown_original = PlayerManager.speed_up_grenade_cooldown
	local aquire_team_upgrade_original = PlayerManager.aquire_team_upgrade
	local unaquire_team_upgrade_original = PlayerManager.unaquire_team_upgrade
	local add_synced_team_upgrade_original = PlayerManager.add_synced_team_upgrade
	local peer_dropped_out_original = PlayerManager.peer_dropped_out
	local _dodge_shot_gain_original = PlayerManager._dodge_shot_gain
	local on_killshot_original = PlayerManager.on_killshot
	local on_headshot_dealt_original = PlayerManager.on_headshot_dealt
	local _on_messiah_recharge_event_original = PlayerManager._on_messiah_recharge_event
	local use_messiah_charge_original = PlayerManager.use_messiah_charge
	local count_up_player_minions_original = PlayerManager.count_up_player_minions
	local count_down_player_minions_original = PlayerManager.count_down_player_minions
	local set_synced_cocaine_stacks_original = PlayerManager.set_synced_cocaine_stacks
	local chk_wild_kill_counter_original = PlayerManager.chk_wild_kill_counter
	
	local IS_SOCIOPATH = false
	
	function PlayerManager:check_skills(...)
		check_skills_original(self, ...)
		
		managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
		managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
		
		IS_SOCIOPATH = self:has_category_upgrade("player", "killshot_regen_armor_bonus") or
			self:has_category_upgrade("player", "killshot_close_regen_armor_bonus") or
			self:has_category_upgrade("player", "killshot_close_panic_chance") or
			self:has_category_upgrade("player", "melee_kill_life_leech")
	end
	
	function PlayerManager:activate_temporary_upgrade(category, upgrade, ...)
		activate_temporary_upgrade_original(self, category, upgrade, ...)
		
		local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
		if data then
			local level = self:upgrade_level(category, upgrade, 0)
			managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
			managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.expire_time })
			managers.gameinfo:event("temporary_buff", "set_value", category, upgrade, level, { value = self:temporary_upgrade_value(category, upgrade) })
		end
	end
	
	function PlayerManager:activate_temporary_upgrade_by_level(category, upgrade, level, ...)
		activate_temporary_upgrade_by_level_original(self, category, upgrade, level, ...)
		
		local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
		if data then
			local level = self:upgrade_level(category, upgrade, 0)
			managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
			managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.expire_time })
			managers.gameinfo:event("temporary_buff", "set_value", category, upgrade, level, { value = data.upgrade_value })
		end
	end
	
	function PlayerManager:deactivate_temporary_upgrade(category, upgrade, ...)
		local data = self._temporary_upgrades[category] and self._temporary_upgrades[category][upgrade]
		if data then
			local level = self:upgrade_level(category, upgrade, 0)
			managers.gameinfo:event("temporary_buff", "deactivate", category, upgrade, level)
		end
		
		return deactivate_temporary_upgrade_original(self, category, upgrade, ...)
	end
	
	function PlayerManager:disable_cooldown_upgrade(category, upgrade, ...)
		disable_cooldown_upgrade_original(self, category, upgrade, ...)
		
		local data = self._global.cooldown_upgrades[category] and self._global.cooldown_upgrades[category][upgrade]
		if data then
			local level = self:upgrade_level(category, upgrade, 0)
			managers.gameinfo:event("temporary_buff", "activate", category, upgrade, level)
			managers.gameinfo:event("temporary_buff", "set_duration", category, upgrade, level, { expire_t = data.cooldown_time })
		end
	end
	
	function PlayerManager:replenish_grenades(cooldown, ...)
		if not self:has_active_timer("replenish_grenades") then
			local id = managers.blackmarket:equipped_grenade()
			
			if id then
				managers.gameinfo:event("buff", "activate", id .. "_use")
				managers.gameinfo:event("buff", "set_duration", id .. "_use", { duration = cooldown })
			end
		end
		
		return replenish_grenades_original(self, cooldown, ...)
	end
	
	function PlayerManager:_on_grenade_cooldown_end(...)
		local id = managers.blackmarket:equipped_grenade()
		
		if id then
			managers.gameinfo:event("buff", "deactivate", id .. "_use")
		end
		
		return _on_grenade_cooldown_end_original(self, ...)
	end
	
	function PlayerManager:speed_up_grenade_cooldown(t, ...)
		if self:has_active_timer("replenish_grenades") then
			local id = managers.blackmarket:equipped_grenade()
			
			if id then
				managers.gameinfo:event("buff", "change_expire", id .. "_use", { difference = -t })
			end
		end
		
		return speed_up_grenade_cooldown_original(self, t, ...)
	end
	
	function PlayerManager:aquire_team_upgrade(upgrade, ...)
		aquire_team_upgrade_original(self, upgrade, ...)
		managers.gameinfo:event("team_buff", "activate", 0, upgrade.category, upgrade.upgrade, 1)
	end
	
	function PlayerManager:unaquire_team_upgrade(upgrade, ...)
		unaquire_team_upgrade_original(self, upgrade, ...)
		managers.gameinfo:event("team_buff", "deactivate", 0, upgrade.category, upgrade.upgrade, 1)
	end
	
	function PlayerManager:add_synced_team_upgrade(peer_id, category, upgrade, ...)
		add_synced_team_upgrade_original(self, peer_id, category, upgrade, ...)
		managers.gameinfo:event("team_buff", "activate", peer_id, category, upgrade, 1)
	end
	
	function PlayerManager:peer_dropped_out(peer, ...)
		local peer_id = peer:id()
		for category, data in pairs(self._global.synced_team_upgrades[peer_id] or {}) do
			for upgrade, value in pairs(data) do
				managers.gameinfo:event("team_buff", "deactivate", peer_id, category, upgrade, 1)
			end
		end
		
		return peer_dropped_out_original(self, peer, ...)
	end
	
	function PlayerManager:_dodge_shot_gain(gain_value, ...)
		if gain_value then
			if gain_value > 0 then
				managers.gameinfo:event("buff", "activate", "sicario_dodge")
				managers.gameinfo:event("buff", "set_value", "sicario_dodge", { value = gain_value * self:upgrade_value("player", "sicario_multiplier", 1) })
				managers.gameinfo:event("buff", "activate", "sicario_dodge_debuff")
				managers.gameinfo:event("buff", "set_duration", "sicario_dodge_debuff", { duration = tweak_data.upgrades.values.player.dodge_shot_gain[1][2] })
			else
				managers.gameinfo:event("buff", "set_value", "sicario_dodge", { value = 0 })
				managers.gameinfo:event("buff", "deactivate", "sicario_dodge")
			end
		end
		
		return _dodge_shot_gain_original(self, gain_value, ...)
	end
	
	function PlayerManager:on_killshot(...)
		local last_killshot = self._on_killshot_t
		local result = on_killshot_original(self, ...)
		
		if IS_SOCIOPATH and self._on_killshot_t ~= last_killshot then
			managers.gameinfo:event("buff", "activate", "sociopath_debuff")
			managers.gameinfo:event("buff", "set_duration", "sociopath_debuff", { expire_t = self._on_killshot_t })
		end
		
		return result
	end
	
	function PlayerManager:on_headshot_dealt(...)
		local t = Application:time()
		if (self._on_headshot_dealt_t or 0) <= t and self:has_category_upgrade("player", "headshot_regen_armor_bonus") then
			managers.gameinfo:event("buff", "activate", "bullseye_debuff")
			managers.gameinfo:event("buff", "set_duration", "bullseye_debuff", { duration = tweak_data.upgrades.on_headshot_dealt_cooldown or 0 })
		end
		
		return on_headshot_dealt_original(self, ...)
	end

	function PlayerManager:_on_messiah_recharge_event(...)
		_on_messiah_recharge_event_original(self, ...)
	
		managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
		managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
	end
	
	function PlayerManager:use_messiah_charge(...)
		use_messiah_charge_original(self, ...)
		
		managers.gameinfo:event("buff", (self._messiah_charges > 0) and "activate" or "deactivate", "messiah")
		managers.gameinfo:event("buff", "set_stack_count", "messiah", { stack_count = self._messiah_charges })
	end
	
	function PlayerManager:count_up_player_minions(...)
		local result = count_up_player_minions_original(self, ...)
		if self._local_player_minions > 0 then
			if self:has_category_upgrade("player", "minion_master_speed_multiplier") then
				managers.gameinfo:event("buff", "activate", "partner_in_crime")
			end
			if self:has_category_upgrade("player", "minion_master_health_multiplier") then
				managers.gameinfo:event("buff", "activate", "partner_in_crime_aced")
			end
		end
		return result
	end
	
	function PlayerManager:count_down_player_minions(...)
		local result = count_down_player_minions_original(self, ...)
		if self._local_player_minions <= 0 then
			managers.gameinfo:event("buff", "deactivate", "partner_in_crime")
			managers.gameinfo:event("buff", "deactivate", "partner_in_crime_aced")
		end
		return result
	end
	
	function PlayerManager:set_synced_cocaine_stacks(...)
		set_synced_cocaine_stacks_original(self, ...)
		
		local max_stack = 0
		for peer_id, data in pairs(self._global.synced_cocaine_stacks) do
			if data.in_use and data.amount > max_stack then
				max_stack = data.amount
			end
		end
		
		local ratio = max_stack / tweak_data.upgrades.max_total_cocaine_stacks
		managers.gameinfo:event("buff", ratio > 0 and "activate" or "deactivate", "maniac")
		managers.gameinfo:event("buff", "set_value", "maniac", { value = max_stack } )
	end
	
	function PlayerManager:chk_wild_kill_counter(...)
		local t = Application:time()
		local player = self:player_unit()
		local expire_t
		local old_stacks = 0
		local do_check = alive(player) and (managers.player:has_category_upgrade("player", "wild_health_amount") or managers.player:has_category_upgrade("player", "wild_armor_amount"))
		
		if do_check then
			local dmg = player:character_damage()
			local missing_health_ratio = math.clamp(1 - dmg:health_ratio(), 0, 1)
			local missing_armor_ratio = math.clamp(1 - dmg:armor_ratio(), 0, 1)
			local less_armor_wild_cooldown = managers.player:upgrade_value("player", "less_armor_wild_cooldown", 0)
			local less_health_wild_cooldown = managers.player:upgrade_value("player", "less_health_wild_cooldown", 0)
			local trigger_cooldown = tweak_data.upgrades.wild_trigger_time or 30

			if less_health_wild_cooldown ~= 0 and less_health_wild_cooldown[1] ~= 0 then
				local missing_health_stacks = math.floor(missing_health_ratio / less_health_wild_cooldown[1])
				trigger_cooldown = trigger_cooldown - less_health_wild_cooldown[2] * missing_health_stacks
			end
			if less_armor_wild_cooldown ~= 0 and less_armor_wild_cooldown[1] ~= 0 then
				local missing_armor_stacks = math.floor(missing_armor_ratio / less_armor_wild_cooldown[1])
				trigger_cooldown = trigger_cooldown - less_armor_wild_cooldown[2] * missing_armor_stacks
			end
			
			expire_t = t + math.max(trigger_cooldown, 0)
		
			if self._wild_kill_triggers then
				old_stacks = #self._wild_kill_triggers
				for i = 1, #self._wild_kill_triggers, 1 do
					if self._wild_kill_triggers[i] > t then
						break
					end
					old_stacks = old_stacks - 1
				end
			end
		end
		
		chk_wild_kill_counter_original(self, ...)
		
		if do_check and self._wild_kill_triggers and #self._wild_kill_triggers > old_stacks then
			managers.gameinfo:event("timed_stack_buff", "add_timed_stack", "biker", { t = t, expire_t = expire_t })
		end
	end

	
	function PlayerManager:update_hostage_skills()
		local stack_count = (managers.groupai:state():hostage_count() or 0) + (self:num_local_minions() or 0)
		local has_hostage = stack_count > 0
		
		if self:has_team_category_upgrade("health", "hostage_multiplier") or self:has_team_category_upgrade("stamina", "hostage_multiplier") or self:has_team_category_upgrade("damage_dampener", "hostage_multiplier") then
			managers.gameinfo:event("buff", has_hostage and "activate" or "deactivate", "hostage_situation")
			
			if has_hostage then
				local value = self:team_upgrade_value("damage_dampener", "hostage_multiplier", 0)
				managers.gameinfo:event("buff", "set_stack_count", "hostage_situation", { stack_count = stack_count })
				managers.gameinfo:event("buff", "set_value", "hostage_situation", { value = value })
			end
		end
		
		if PlayerManager.HAS_HOSTAGE ~= has_hostage then
			PlayerManager.HAS_HOSTAGE = has_hostage
			
			if alive(self:player_unit()) then
				self:player_unit():character_damage():check_passive_regen_buffs("hostage_taker")
			end
		end
	end
	
end

if RequiredScript == "lib/utils/temporarypropertymanager" then

	local activate_property_original = TemporaryPropertyManager.activate_property
	local add_to_property_original = TemporaryPropertyManager.add_to_property
	local mul_to_property_original = TemporaryPropertyManager.mul_to_property
	local set_time_original = TemporaryPropertyManager.set_time
	local remove_property_original = TemporaryPropertyManager.remove_property
	
	function TemporaryPropertyManager:activate_property(prop, ...)
		activate_property_original(self, prop, ...)
		
		local data = self._properties[prop]
		managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
		managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
		managers.gameinfo:event("temporary_buff", "set_duration", "property", prop, 1, { expire_t = data[2] })
		managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
	end
	
	function TemporaryPropertyManager:add_to_property(prop, ...)
		local was_active = self:has_active_property(prop)
		
		add_to_property_original(self, prop, ...)
		
		local data = self._properties[prop]
		if was_active then
			managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
			managers.gameinfo:event("temporary_buff", "set_expire", "property", prop, 1, { expire_t = data[2] })
			managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
		end
	end
	
	function TemporaryPropertyManager:mul_to_property(prop, ...)
		local was_active = self:has_active_property(prop)
		
		mul_to_property_original(self, prop, ...)
		
		local data = self._properties[prop]
		if was_active then
			managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
			managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = data[1] })
		end
	end
	
	function TemporaryPropertyManager:set_time(prop, ...)
		set_time_original(self, prop, ...)
		
		local data = self._properties[prop]
		if data and self:has_active_property(prop) then
			managers.gameinfo:event("temporary_buff", "set_expire", "property", prop, 1, { expire_t = data[2] })
		end
	end
	
	function TemporaryPropertyManager:remove_property(prop, ...)
		if self:has_active_property(prop) then
			managers.gameinfo:event("temporary_buff", "deactivate", "property", prop, 1)
		end
		
		return remove_property_original(self, prop, ...)
	end
	
end

if RequiredScript == "lib/utils/propertymanager" then
	
	local add_to_property_original = PropertyManager.add_to_property
	local mul_to_property_original = PropertyManager.mul_to_property
	local set_property_original = PropertyManager.set_property
	local remove_property_original = PropertyManager.remove_property
	
	function PropertyManager:add_to_property(prop, ...)
		local was_active = self:has_property(prop)
		
		add_to_property_original(self, prop, ...)
		
		if not was_active then
			managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
		end
		managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
		managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
	end

	function PropertyManager:mul_to_property(prop, ...)
		local was_active = self:has_property(prop)
		
		mul_to_property_original(self, prop, ...)
		
		if not was_active then
			managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
		end
		managers.gameinfo:event("temporary_buff", "increment_stack_count", "property", prop, 1)
		managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
	end

	function PropertyManager:set_property(prop, ...)
		local was_active = self:has_property(prop)
		
		set_property_original(self, prop, ...)
		
		if not was_active then
			managers.gameinfo:event("temporary_buff", "activate", "property", prop, 1)
		end
		managers.gameinfo:event("temporary_buff", "set_value", "property", prop, 1, { value = self._properties[prop] })
	end

	function PropertyManager:remove_property(prop, ...)
		if self:has_property(prop) then
			managers.gameinfo:event("temporary_buff", "deactivate", "property", prop, 1)
		end
		
		return remove_property_original(self, prop, ...)
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractionshockandawe" then
	
	local shockandawe_original = PlayerAction.ShockAndAwe.Function
	
	function PlayerAction.ShockAndAwe.Function(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
		local weapon_unit = player_manager:equipped_weapon_unit()
		local min_threshold = min_bullets + (weapon_unit:base():is_category("smg", "assault_rifle", "lmg") and player_manager:upgrade_value("player", "automatic_mag_increase", 0) or 0)
		local max_threshold = math.floor(min_threshold + math.log(min_reload_increase/max_reload_increase) / math.log(penalty))				
		local ammo = weapon_unit:base():get_ammo_max_per_clip()
		local bonus = math.clamp(max_reload_increase * math.pow(penalty, ammo - min_threshold), min_reload_increase, max_reload_increase)
		
		managers.gameinfo:event("buff", "activate", "lock_n_load")
		managers.gameinfo:event("buff", "set_value", "lock_n_load", { value = bonus })
		
		shockandawe_original(player_manager, target_enemies, max_reload_increase, min_reload_increase, penalty, min_bullets, ...)
		
		managers.gameinfo:event("buff", "deactivate", "lock_n_load")
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractionexperthandling" then
	
	local experthandling_original = PlayerAction.ExpertHandling.Function
	
	function PlayerAction.ExpertHandling.Function(player_manager, accuracy_bonus, max_stacks, max_time, ...)
		managers.gameinfo:event("buff", "activate", "desperado")
		managers.gameinfo:event("buff", "set_duration", "desperado", { expire_t = max_time })
		experthandling_original(player_manager, accuracy_bonus, max_stacks, max_time, ...)
		managers.gameinfo:event("buff", "deactivate", "desperado")
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractiontriggerhappy" then

	local trigger_happy_original = PlayerAction.TriggerHappy.Function
	
	function PlayerAction.TriggerHappy.Function(player_manager, damage_bonus, max_stacks, max_time, ...)
		managers.gameinfo:event("buff", "activate", "trigger_happy")
		managers.gameinfo:event("buff", "set_duration", "trigger_happy", { expire_t = max_time })
		trigger_happy_original(player_manager, damage_bonus, max_stacks, max_time, ...)
		managers.gameinfo:event("buff", "deactivate", "trigger_happy")
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractionbloodthirstbase" then
	
	local bloodthirstbase_original = PlayerAction.BloodthirstBase.Function
	
	function PlayerAction.BloodthirstBase.Function(player_manager, melee_multiplier, max_multiplier, ...)
		local multiplier = 1
		
		local function on_enemy_killed()
			if multiplier < max_multiplier then
				multiplier = math.min(multiplier + melee_multiplier, max_multiplier)
				managers.gameinfo:event("buff", "increment_stack_count", "bloodthirst_basic")
				managers.gameinfo:event("buff", "set_value", "bloodthirst_basic", { value = multiplier })
			end
		end
		
		managers.gameinfo:event("buff", "activate", "bloodthirst_basic")
		on_enemy_killed()
		player_manager:register_message(Message.OnEnemyKilled, "bloodthirst_basic_buff_listener", on_enemy_killed)
		
		bloodthirstbase_original(player_manager, melee_multiplier, max_multiplier, ...)
		
		player_manager:unregister_message(Message.OnEnemyKilled, "bloodthirst_basic_buff_listener")
		managers.gameinfo:event("buff", "deactivate", "bloodthirst_basic")
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractiondireneed" then
	
	local direneed_original = PlayerAction.DireNeed.Function
	
	function PlayerAction.DireNeed.Function(...)
		managers.gameinfo:event("buff", "activate", "dire_need")
		direneed_original(...)
		managers.gameinfo:event("buff", "deactivate", "dire_need")
	end
	
end

if RequiredScript == "lib/player_actions/skills/playeractionunseenstrike" then

	local unseenstrike_original = PlayerAction.UnseenStrike.Function
	
	function PlayerAction.UnseenStrike.Function(player_manager, min_time, ...)
		local function on_player_damage()
			if not player_manager:has_activate_temporary_upgrade("temporary", "unseen_strike") then
				managers.gameinfo:event("buff", "activate", "unseen_strike_debuff")
				managers.gameinfo:event("buff", "set_duration", "unseen_strike_debuff", { duration = min_time })
			end
		end
		
		managers.player:register_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener", on_player_damage)
		
		unseenstrike_original(player_manager, min_time, ...)
		
		managers.player:unregister_message(Message.OnPlayerDamage, "unseen_strike_debuff_listener")
	end

end

if RequiredScript == "lib/player_actions/skills/playeractionammoefficiency" then

	local ammo_efficieny_original = PlayerAction.AmmoEfficiency.Function
	
	function PlayerAction.AmmoEfficiency.Function(player_manager, target_headshots, bullet_refund, target_time, ...)
		local headshots = 0
		
		local function on_headshot_dealt()
			headshots = headshots + 1
			managers.gameinfo:event("buff", "set_stack_count", "ammo_efficiency", { stack_count = target_headshots - headshots })
		end
		
		managers.gameinfo:event("buff", "activate", "ammo_efficiency")
		managers.gameinfo:event("buff", "set_duration", "ammo_efficiency", { expire_t = target_time })
		on_headshot_dealt()
		player_manager:register_message(Message.OnHeadShot, "ammo_efficiency_buff_listener", on_headshot_dealt)
		
		ammo_efficieny_original(player_manager, target_headshots, bullet_refund, target_time, ...)
		
		player_manager:unregister_message(Message.OnHeadShot, "ammo_efficiency_buff_listener")
		managers.gameinfo:event("buff", "deactivate", "ammo_efficiency")
	end
	
end

if RequiredScript == "lib/modifiers/boosts/gagemodifiermeleeinvincibility" then
	
	local OnPlayerManagerKillshot_original = GageModifierMeleeInvincibility.OnPlayerManagerKillshot
	
	function GageModifierMeleeInvincibility:OnPlayerManagerKillshot(...)
		OnPlayerManagerKillshot_original(self, ...)
		
		if self._special_kill_t == TimerManager:game():time() then
			managers.gameinfo:event("buff", "activate", "some_invulnerability_debuff")
			managers.gameinfo:event("buff", "set_duration", "some_invulnerability_debuff", { duration = self:value() })
		end
	end
	
end

if RequiredScript == "lib/modifiers/boosts/gagemodifierlifesteal" then
	
	local OnPlayerManagerKillshot_original = GageModifierLifeSteal.OnPlayerManagerKillshot
	
	function GageModifierLifeSteal:OnPlayerManagerKillshot(...)
		OnPlayerManagerKillshot_original(self, ...)
	
		if self._last_killshot_t == TimerManager:game():time() then
			managers.gameinfo:event("buff", "activate", "self_healer_debuff")
			managers.gameinfo:event("buff", "set_duration", "self_healer_debuff", { duration = self:value("cooldown") })
		end
	end
	
end

if RequiredScript == "lib/units/beings/player/playermovement" then
	
	local update_original = PlayerMovement.update
	local on_morale_boost_original = PlayerMovement.on_morale_boost
	
	function PlayerMovement:update(unit, t, ...)
		self:_update_radius_buffs(t)
		return update_original(self, unit, t, ...)
	end
	
	function PlayerMovement:on_morale_boost(...)
		managers.gameinfo:event("buff", "activate", "inspire")
		managers.gameinfo:event("buff", "set_duration", "inspire", { duration = tweak_data.upgrades.morale_boost_time })
		return on_morale_boost_original(self, ...)
	end
	
	local recheck_t = 0
	local recheck_interval = 0.5
	local FAK_in_range = false
	local player_in_smoke = false
	function PlayerMovement:_update_radius_buffs(t)
		if t > recheck_t and alive(self._unit) then
			recheck_t = t + recheck_interval
			
			local fak_in_range = FirstAidKitBase.GetFirstAidKit(self._unit:position())
			if fak_in_range ~= FAK_in_range then
				FAK_in_range = fak_in_range
				managers.gameinfo:event("buff", fak_in_range and "activate" or "deactivate", "uppers")
			end
			
			local in_smoke = false
			for _, smoke_screen in ipairs(managers.player:smoke_screens()) do
				if smoke_screen:is_in_smoke(self._unit) then
					in_smoke = true
					break
				end
			end
			
			if in_smoke ~= player_in_smoke then
				player_in_smoke = in_smoke
				managers.gameinfo:event("buff", in_smoke and "activate" or "deactivate", "smoke_screen")
			end
		end
	end
	
end

if RequiredScript == "lib/units/beings/player/playerdamage" then
	
	local init_original = PlayerDamage.init
	local set_health_original = PlayerDamage.set_health
	local _upd_health_regen_original = PlayerDamage._upd_health_regen
	local _check_bleed_out_original = PlayerDamage._check_bleed_out
	local _start_regen_on_the_side_original = PlayerDamage._start_regen_on_the_side
	local add_damage_to_hot_original = PlayerDamage.add_damage_to_hot
	local _update_delayed_damage_original = PlayerDamage._update_delayed_damage
	local delay_damage_original = PlayerDamage.delay_damage
	local clear_delayed_damage_original = PlayerDamage.clear_delayed_damage
	
	local CALM_COOLDOWN = false
	local CALM_HEALING = false
	local DELAYED_DAMAGE_BUFFER_SIZE = 16
	
	function PlayerDamage:init(...)
		init_original(self, ...)
		
		CALM_COOLDOWN = managers.player:has_category_upgrade("player", "damage_control_auto_shrug") and managers.player:upgrade_value("player", "damage_control_auto_shrug") or false
		CALM_HEALING = managers.player:has_category_upgrade("player", "damage_control_healing") and (managers.player:upgrade_value("player", "damage_control_healing") * 0.01) or false
		DELAYED_DAMAGE_BUFFER_SIZE = math.round(1 / (tweak_data.upgrades.values.player.damage_control_passive[1][2] * 0.01))
		
		if managers.player:has_category_upgrade("player", "damage_to_armor") then
			CopDamage.register_listener("anarchist_debuff_listener", {"on_damage"}, function(dmg_info)
				local attacker = dmg_info and dmg_info.attacker_unit
				if alive(attacker) and attacker:base() and attacker:base().thrower_unit then
					attacker = attacker:base():thrower_unit()
				end
			
				if self._unit == attacker then
					local t = Application:time()
					local data = self._damage_to_armor
					if (data.elapsed == t) or (t - data.elapsed > data.target_tick) then
						managers.gameinfo:event("buff", "activate", "anarchist_armor_recovery_debuff")
						managers.gameinfo:event("buff", "set_duration", "anarchist_armor_recovery_debuff", { t = t, duration = data.target_tick })
					end
				end
			end)
		end
	end
	
	local HEALTH_RATIO_BONUSES = {
		melee_damage_health_ratio_multiplier = { category = "melee", buff_id = "berserker", offset = 1 },
		damage_health_ratio_multiplier = { category = "damage", buff_id = "berserker_aced", offset = 1 },
		armor_regen_damage_health_ratio_multiplier = { category = "armor_regen", buff_id = "yakuza_recovery" },
		movement_speed_damage_health_ratio_multiplier = { category = "movement_speed", buff_id = "yakuza_speed" },
	}
	local LAST_HEALTH_RATIO = 0
	function PlayerDamage:set_health(...)
		local was_hurt = self:_max_health() > (self:get_real_health() + 0.001)
	
		set_health_original(self, ...)
		
		local health_ratio = self:health_ratio()
		
		if health_ratio ~= LAST_HEALTH_RATIO then
			local is_hurt = self:_max_health() > (self:get_real_health() + 0.001)
			LAST_HEALTH_RATIO = health_ratio
		
			for upgrade, data in pairs(HEALTH_RATIO_BONUSES) do
				if managers.player:has_category_upgrade("player", upgrade) then
					local bonus_ratio = managers.player:get_damage_health_ratio(health_ratio, data.category)
					local value = (data.offset or 0) + managers.player:upgrade_value("player", upgrade, 0) * bonus_ratio
					managers.gameinfo:event("buff", bonus_ratio > 0 and "activate" or "deactivate", data.buff_id)
					managers.gameinfo:event("buff", "set_value", data.buff_id, { value = value })
				end
			end
			
			if managers.player:has_category_upgrade("player", "passive_damage_reduction") then
				local threshold = managers.player:upgrade_value("player", "passive_damage_reduction")
				local value = managers.player:team_upgrade_value("damage_dampener", "team_damage_reduction")
				if health_ratio < threshold then
					value = 2 * value - 1
				end
				managers.gameinfo:event("buff", "set_value", "cc_passive_damage_reduction", { value = value })
			end
			
			if was_hurt ~= is_hurt then
				self:check_passive_regen_buffs()
			end
		end
	end
	
	function PlayerDamage:_upd_health_regen(...)
		_upd_health_regen_original(self, ...)
		
		if self._health_regen_update_timer and self._health_regen_update_timer >= 5 then
			self:check_passive_regen_buffs()
		end
	end
	
	function PlayerDamage:_check_bleed_out(...)
		local last_uppers = self._uppers_elapsed or 0
		
		local result = _check_bleed_out_original(self, ...)
		
		if (self._uppers_elapsed or 0) > last_uppers then
			managers.gameinfo:event("buff", "activate", "uppers_debuff")
			managers.gameinfo:event("buff", "set_duration", "uppers_debuff", { duration = self._UPPERS_COOLDOWN })
		end
	end
	
	function PlayerDamage:_start_regen_on_the_side(time, ...)
		if self._regen_on_the_side_timer <= 0 and time > 0 then
			managers.gameinfo:event("buff", "activate", "tooth_and_claw")
			managers.gameinfo:event("buff", "set_duration", "tooth_and_claw", { duration = time })
		end
		
		return _start_regen_on_the_side_original(self, time, ...)
	end
	
	function PlayerDamage:add_damage_to_hot(...)
		if not (self:got_max_doh_stacks() or self:need_revive() or self:dead() or self._check_berserker_done) then
			local stack_duration = ((self._doh_data.total_ticks or 1) + managers.player:upgrade_value("player", "damage_to_hot_extra_ticks", 0)) * (self._doh_data.tick_time or 1)
			managers.gameinfo:event("buff", "activate", "grinder_debuff")
			managers.gameinfo:event("buff", "set_duration", "grinder_debuff", { duration = tweak_data.upgrades.damage_to_hot_data.stacking_cooldown })
			managers.gameinfo:event("timed_stack_buff", "add_timed_stack", "grinder", { duration = stack_duration })
		end
		
		return add_damage_to_hot_original(self, ...)
	end
	
	local DELAYED_DAMAGE_BUFFER = {}
	local DELAYED_DAMAGE_TOTAL = 0
	local DELAYED_DAMAGE_BUFFER_INDEX = 0
	function PlayerDamage:_update_delayed_damage(t, ...)
		if self._delayed_damage.next_tick and t >= self._delayed_damage.next_tick then
			--managers.gameinfo:event("buff", "set_duration", "virtue_debuff", { duration = 1, no_expire = true })
			
			if DELAYED_DAMAGE_TOTAL > 0 then
				DELAYED_DAMAGE_TOTAL = DELAYED_DAMAGE_TOTAL - DELAYED_DAMAGE_BUFFER[DELAYED_DAMAGE_BUFFER_INDEX + 1]
				DELAYED_DAMAGE_BUFFER[DELAYED_DAMAGE_BUFFER_INDEX + 1] = 0
				DELAYED_DAMAGE_BUFFER_INDEX = (DELAYED_DAMAGE_BUFFER_INDEX + 1) % DELAYED_DAMAGE_BUFFER_SIZE
				managers.gameinfo:event("buff", "set_value", "virtue_debuff", { value = math.round(DELAYED_DAMAGE_TOTAL * 10) })
			else
				DELAYED_DAMAGE_TOTAL = 0
			end
		end
		
		return _update_delayed_damage_original(self, t, ...)
	end
	
	function PlayerDamage:delay_damage(damage, seconds, ...)
		if not self._delayed_damage.next_tick then
			managers.gameinfo:event("buff", "activate", "virtue_debuff")
			
			if CALM_COOLDOWN then
				managers.gameinfo:event("buff", "activate", "calm")
			end
		end
		
		if CALM_COOLDOWN then
			managers.gameinfo:event("buff", "set_duration", "calm", { duration = CALM_COOLDOWN })
		end
	
		local tick_dmg = damage / seconds
		for i = 1, DELAYED_DAMAGE_BUFFER_SIZE, 1 do
			DELAYED_DAMAGE_BUFFER[i] = (DELAYED_DAMAGE_BUFFER[i] or 0) + tick_dmg
		end
		DELAYED_DAMAGE_TOTAL = DELAYED_DAMAGE_TOTAL + damage
		
		local t = self._delayed_damage.next_tick and (self._delayed_damage.next_tick - 1) or TimerManager:game():time()
		local expire_t = t + DELAYED_DAMAGE_BUFFER_SIZE
		
		managers.gameinfo:event("buff", "set_duration", "virtue_debuff", { t = t, expire_t = expire_t })
		managers.gameinfo:event("buff", "set_value", "virtue_debuff", { value = math.round(DELAYED_DAMAGE_TOTAL * 10) })
		
		return delay_damage_original(self, damage, seconds, ...)
	end
	
	function PlayerDamage:clear_delayed_damage(...)
		DELAYED_DAMAGE_BUFFER = {}
		DELAYED_DAMAGE_TOTAL = 0
	
		managers.gameinfo:event("buff", "deactivate", "virtue_debuff")
		managers.gameinfo:event("buff", "deactivate", "calm")
	
		return clear_delayed_damage_original(self, ...)
	end
	
	
	local MUSCLE_REGEN_ACTIVE = false
	local HOSTAGE_REGEN_ACTIVE = false
	local PASSIVE_REGEN_BUFFS = {
		hostage_taker = { 
			category = "player", 
			upgrade = "hostage_health_regen_addend", 
			check = function() return PlayerManager.HAS_HOSTAGE end,
		},
		muscle_regen = { 
			category = "player",
			upgrade = "passive_health_regen",
		},
	}
	function PlayerDamage:check_passive_regen_buffs(buff)
		local is_hurt = self:_max_health() > (self:get_real_health() + 0.001)
		
		for buff_id, data in pairs(PASSIVE_REGEN_BUFFS) do
			if not buff or buff == buff_id then
				local value = managers.player:upgrade_value(data.category, data.upgrade, 0)
				local can_use = value > 0 and (not data.check or data.check())
				
				if is_hurt and can_use then
					local t = Application:time()
					local start_t = t - (5 - (self._health_regen_update_timer or 5))
					local expire_t = start_t + 5
					managers.gameinfo:event("buff", "activate", buff_id)
					managers.gameinfo:event("buff", "set_value", buff_id, { value = value })
					managers.gameinfo:event("buff", "set_duration", buff_id, { t = start_t, expire_t = expire_t })
				else
					managers.gameinfo:event("buff", "deactivate", buff_id)
				end
			end
		end
	end
	
end

if RequiredScript == "lib/units/beings/player/states/playerstandard" then
	
	local _do_action_intimidate_original = PlayerStandard._do_action_intimidate
	local _do_melee_damage_original = PlayerStandard._do_melee_damage
	local _start_action_interact_original = PlayerStandard._start_action_interact
	local _interupt_action_interact_original = PlayerStandard._interupt_action_interact
	
	function PlayerStandard:_do_action_intimidate(t, interact_type, ...)
		if interact_type == "cmd_gogo" or interact_type == "cmd_get_up" then
			local duration = (tweak_data.upgrades.morale_boost_base_cooldown * managers.player:upgrade_value("player", "morale_boost_cooldown_multiplier", 1)) or 3.5
			managers.gameinfo:event("buff", "activate", "inspire_debuff")
			managers.gameinfo:event("buff", "set_duration", "inspire_debuff", { duration = duration })
		end
		
		return _do_action_intimidate_original(self, t, interact_type, ...)
	end
	
	function PlayerStandard:_do_melee_damage(t, ...)
		local result = _do_melee_damage_original(self, t, ...)
		
		local stack = self._state_data.stacking_dmg_mul and self._state_data.stacking_dmg_mul.melee
		if stack then
			managers.gameinfo:event("buff", stack[2] > 0 and "activate" or "deactivate", "melee_stack_damage")
			
			if stack[2] > 0 then
				local value = managers.player:upgrade_value("melee", "stacking_hit_damage_multiplier", 0)
				managers.gameinfo:event("buff", "set_duration", "melee_stack_damage", { expire_t = stack[1] })
				managers.gameinfo:event("buff", "set_stack_count", "melee_stack_damage", { stack_count = stack[2] })
				managers.gameinfo:event("buff", "set_value", "melee_stack_damage", { value = 1 + stack[2] * value })
			end
		end
		
		return result
	end
	
	function PlayerStandard:_start_action_interact(...)
		if managers.player:has_category_upgrade("player", "interacting_damage_multiplier") then
			local value = managers.player:upgrade_value("player", "interacting_damage_multiplier", 0)
			managers.gameinfo:event("buff", "activate", "die_hard")
			managers.gameinfo:event("buff", "set_value", "die_hard", { value = value })
		end
		
		return _start_action_interact_original(self, ...)
	end
	
	function PlayerStandard:_interupt_action_interact(...)
		if self._interact_expire_t and managers.player:has_category_upgrade("player", "interacting_damage_multiplier") then
			managers.gameinfo:event("buff", "deactivate", "die_hard")
		end
		
		return _interupt_action_interact_original(self, ...)
	end
	
	
	--OVERRIDE
	function PlayerStandard:_update_omniscience(t, dt)
		local action_forbidden = 
			not managers.player:has_category_upgrade("player", "standstill_omniscience") or 
			managers.player:current_state() == "civilian" or 
			self:_interacting() or 
			self._ext_movement:has_carry_restriction() or 
			self:is_deploying() or 
			self:_changing_weapon() or 
			self:_is_throwing_projectile() or 
			self:_is_meleeing() or 
			self:_on_zipline() or 
			self._moving or 
			self:running() or 
			self:_is_reloading() or 
			self:in_air() or 
			self:in_steelsight() or 
			self:is_equipping() or 
			self:shooting() or 
			not managers.groupai:state():whisper_mode() or 
			not tweak_data.player.omniscience
		
		if action_forbidden then
			if self._state_data.omniscience_t then
				managers.gameinfo:event("buff", "deactivate", "sixth_sense")
				self._state_data.omniscience_t = nil
			end
			return
		end
		
		if not self._state_data.omniscience_t then
			managers.gameinfo:event("buff", "activate", "sixth_sense")
			managers.gameinfo:event("buff", "set_duration", "sixth_sense", { duration = tweak_data.player.omniscience.start_t, no_expire = true })
			managers.gameinfo:event("buff", "set_stack_count", "sixth_sense", { stack_count = nil })
		end
		
		self._state_data.omniscience_t = self._state_data.omniscience_t or t + tweak_data.player.omniscience.start_t
		if t >= self._state_data.omniscience_t then
			local sensed_targets = World:find_units_quick("sphere", self._unit:movement():m_pos(), tweak_data.player.omniscience.sense_radius, managers.slot:get_mask("trip_mine_targets"))
			managers.gameinfo:event("buff", "set_stack_count", "sixth_sense", { stack_count = #sensed_targets })
			
			for _, unit in ipairs(sensed_targets) do
				if alive(unit) and not unit:base():char_tweak().is_escort then
					self._state_data.omniscience_units_detected = self._state_data.omniscience_units_detected or {}
					if not self._state_data.omniscience_units_detected[unit:key()] or t >= self._state_data.omniscience_units_detected[unit:key()] then
						self._state_data.omniscience_units_detected[unit:key()] = t + tweak_data.player.omniscience.target_resense_t
						managers.game_play_central:auto_highlight_enemy(unit, true)
					end
				else
				end
			end
			self._state_data.omniscience_t = t + tweak_data.player.omniscience.interval_t
			managers.gameinfo:event("buff", "set_duration", "sixth_sense", { duration = tweak_data.player.omniscience.interval_t, no_expire = true })
		end
	end
	
end

if RequiredScript == "lib/units/beings/player/playerinventory" then
	
	local equip_selection_original = PlayerInventory.equip_selection
	
	function PlayerInventory:equip_selection(...)
		if equip_selection_original(self, ...) then
			local unit = self:equipped_unit()
			managers.gameinfo:event("player_weapon", "equip", tostring(unit:key()), { unit = unit })
			return true
		end
		
		return false
	end
	
end

if RequiredScript == "lib/managers/group_ai_states/groupaistatebase" then

	local sync_hostage_headcount_original = GroupAIStateBase.sync_hostage_headcount

	function GroupAIStateBase:sync_hostage_headcount(...)
		sync_hostage_headcount_original(self, ...)
		managers.player:update_hostage_skills()
	end

end
