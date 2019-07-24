local plugin = "pickups"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Pickups", desc = "Handles special equipment/pickups" }, "init_pickups_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	GameInfoManager._PICKUPS = {
		interaction_ids = {
			gen_pku_crowbar = true,
			pickup_keycard = true,
			pickup_hotel_room_keycard = true,
			gage_assignment = true,
			pickup_boards = true,
			stash_planks_pickup = true,
			muriatic_acid = true,
			hydrogen_chloride = true,
			caustic_soda = true,
			press_pick_up = true,
			ring_band = true,
		},
		ignore_ids = {
			firestarter_2 = {	--Firestarter day 2 (1x keycard)
				[107208] = true,
			},
			big = {	--Big Bank (1x keycard)
				[101499] = true,
			},
			roberts = {	--GO Bank (1x keycard)
				[106104] = true,
			},
		},
	}
	
	function GameInfoManager:init_pickups_plugin()
		self._special_equipment = self._special_equipment or {}
	end
	
	function GameInfoManager:get_special_equipment(key)
		if key then
			return self._special_equipment[key]
		else
			return self._special_equipment
		end
	end
	
	function GameInfoManager:_special_equipment_interaction_handler(event, key, data)
		if event == "add" then
			if not self._special_equipment[key] then
				self._special_equipment[key] = { unit = data.unit, interact_id = data.interact_id }
				self:_listener_callback("special_equipment", "add", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, 1, self._special_equipment[key])
			end
		elseif event == "remove" then
			if self._special_equipment[key] then
				self:_listener_callback("special_equipment", "remove", key, self._special_equipment[key])
				self:_special_equipment_count_event("change", data.interact_id, -1, self._special_equipment[key])
				self._special_equipment[key] = nil
			end
		end
	end
	
	function GameInfoManager:_special_equipment_count_event(event, interact_id, value, data)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("special_equipment_count", "change", interact_id, value, data)
			end
		end
	end
	
	local _interactive_unit_event_original = GameInfoManager._interactive_unit_event
	
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if GameInfoManager._PICKUPS.interaction_ids[data.interact_id] then
			local level_id = managers.job:current_level_id()
			
			if not (GameInfoManager._PICKUPS.ignore_ids[level_id] and GameInfoManager._PICKUPS.ignore_ids[level_id][data.editor_id]) then
				self:_special_equipment_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original(self, event, key, data)
	end
	
end
