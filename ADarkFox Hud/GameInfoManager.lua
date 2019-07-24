printf = printf or function(...) end

if RequiredScript == "lib/setups/setup" then
	
	local init_managers_original = Setup.init_managers
	local update_original = Setup.update
	
	function Setup:init_managers(managers, ...)
		managers.gameinfo = managers.gameinfo or GameInfoManager:new()
		managers.gameinfo:post_init()
		return init_managers_original(self, managers, ...)
	end
	
	function Setup:update(t, dt, ...)
		managers.gameinfo:update(t, dt)
		return update_original(self, t, dt, ...)
	end

end
	
if RequiredScript == "lib/entry" then
	
	GameInfoManager = GameInfoManager or class()
	GameInfoManager._PLUGINS_LOADED = {}
	GameInfoManager._PLUGIN_SETTINGS = GameInfoManager._PLUGIN_SETTINGS or { PLACEHOLDER = true }	--BLT JSON decode doesn't like empty tables
	
	function GameInfoManager:init()
		self._t = 0
		self._scheduled_callbacks = {}
		self._scheduled_callbacks_index = {}
		self._listeners = {}
	end
	
	function GameInfoManager:post_init()
		self:do_post_init_events()
	end
	
	function GameInfoManager:do_post_init_events()
		for _, clbk in ipairs(GameInfoManager.post_init_events or {}) do
			if type(clbk) == "string" then
				if self[clbk] then
					self[clbk](self)
				end
			else
				clbk()
			end
		end
		
		GameInfoManager.post_init_events = nil
	end
	
	function GameInfoManager:update(t, dt)
		self._t = t
		
		while self._scheduled_callbacks[1] and self._scheduled_callbacks[1].t <= t do
			local data = table.remove(self._scheduled_callbacks, 1)
			self._scheduled_callbacks_index[data.id] = nil
			data.clbk(unpack(data.args))
		end
	end
	
	function GameInfoManager:add_scheduled_callback(id, delay, clbk, ...)
		self:remove_scheduled_callback(id)
	
		local t = self._t + delay
		local pos = 1
		
		for i, data in ipairs(self._scheduled_callbacks) do
			if data.t >= t then break end
			pos = pos + 1
		end
		
		table.insert(self._scheduled_callbacks, pos, { id = id, t = t, clbk = clbk, args = { ... } })
		self._scheduled_callbacks_index[id] = true
	end
	
	function GameInfoManager:remove_scheduled_callback(id)
		if self._scheduled_callbacks_index[id] then
			for i, data in ipairs(self._scheduled_callbacks) do
				if data.id == id then
					self._scheduled_callbacks_index[id] = nil
					return table.remove(self._scheduled_callbacks, i)
				end
			end
		end
	end
	
	function GameInfoManager:event(source, ...)
		local target = "_" .. source .. "_event"
		
		if self[target] then
			self[target](self, ...)
		else
			printf("Error: No event handler for %s", target)
		end
	end

	
	function GameInfoManager:_interactive_unit_event(event, key, data)
		--Placeholder for callbacks
	end
	
	function GameInfoManager:_whisper_mode_event(event, key, status)
		self:_listener_callback("whisper_mode", "change", key, status)
	end
	
	
	function GameInfoManager:register_listener(listener_id, source_type, event, clbk, keys, data_only)
		local listener_keys = nil
		
		if keys then
			listener_keys = {}
			for _, key in ipairs(keys) do
				listener_keys[key] = true
			end
		end
		
		self._listeners[source_type] = self._listeners[source_type] or {}
		self._listeners[source_type][event] = self._listeners[source_type][event] or {}
		self._listeners[source_type][event][listener_id] = { clbk = clbk, keys = listener_keys, data_only = data_only }
	end
	
	function GameInfoManager:unregister_listener(listener_id, source_type, event)
		if self._listeners[source_type] then
			if self._listeners[source_type][event] then
				self._listeners[source_type][event][listener_id] = nil
			end
		end
	end
	
	function GameInfoManager:_listener_callback(source, event, key, ...)
		for listener_id, data in pairs(self._listeners[source] and self._listeners[source][event] or {}) do
			if not data.keys or data.keys[key] then
				if data.data_only then
					data.clbk(...)
				else
					data.clbk(event, key, ...)
				end
			end
		end
	end

	
	function GameInfoManager.add_post_init_event(clbk)
		GameInfoManager.post_init_events = GameInfoManager.post_init_events or {}
		table.insert(GameInfoManager.post_init_events, clbk)
		
		if managers and managers.gameinfo then
			managers.gameinfo:do_post_init_events()
		end
	end
	
	function GameInfoManager.add_plugin(name, data, init_clbk)
		GameInfoManager._PLUGINS_LOADED[name] = data
		if GameInfoManager._PLUGIN_SETTINGS[name] == nil then
			GameInfoManager._PLUGIN_SETTINGS[name] = true
		end
		
		if init_clbk then
			GameInfoManager.add_post_init_event(init_clbk)
		end
	end
	
	function GameInfoManager.has_plugin(name)
		return GameInfoManager._PLUGINS_LOADED[name] and true or false
	end
	
	function GameInfoManager.plugin_active(name)
		return GameInfoManager.has_plugin(name) and GameInfoManager._PLUGIN_SETTINGS[name] and true or false
	end
	
end

if RequiredScript == "lib/managers/group_ai_states/groupaistatebase" then
	
	local set_whisper_mode_original = GroupAIStateBase.set_whisper_mode
	
	function GroupAIStateBase:set_whisper_mode(enabled, ...)
		set_whisper_mode_original(self, enabled, ...)
		managers.gameinfo:event("whisper_mode", "change", nil, enabled)
	end
	
end

if RequiredScript == "lib/managers/objectinteractionmanager" then
	
	local init_original = ObjectInteractionManager.init
	local update_original = ObjectInteractionManager.update
	local add_unit_original = ObjectInteractionManager.add_unit
	local remove_unit_original = ObjectInteractionManager.remove_unit
	
	function ObjectInteractionManager:init(...)
		init_original(self, ...)
		self._queued_units = {}
	end
	
	function ObjectInteractionManager:update(t, ...)
		update_original(self, t, ...)
		self:_process_queued_units(t)
	end
	
	function ObjectInteractionManager:add_unit(unit, ...)
		self:add_unit_clbk(unit)
		return add_unit_original(self, unit, ...)
	end
	
	function ObjectInteractionManager:remove_unit(unit, ...)
		self:remove_unit_clbk(unit)
		return remove_unit_original(self, unit, ...)
	end
	
	
	function ObjectInteractionManager:add_unit_clbk(unit)
		self._queued_units[tostring(unit:key())] = unit
	end
	
	function ObjectInteractionManager:remove_unit_clbk(unit, interact_id)
		local key = tostring(unit:key())
		
		if self._queued_units[key] then
			self._queued_units[key] = nil
		else
			local id = interact_id or unit:interaction().tweak_data
			local editor_id = unit:editor_id()
			managers.gameinfo:event("interactive_unit", "remove", key, { unit = unit, editor_id = editor_id, interact_id = id })
		end
	end
	
	function ObjectInteractionManager:_process_queued_units(t)
		for key, unit in pairs(self._queued_units) do
			if alive(unit) then
				local interact_id = unit:interaction().tweak_data
				local editor_id = unit:editor_id()
				managers.gameinfo:event("interactive_unit", "add", key, { unit = unit, editor_id = editor_id, interact_id = interact_id })
			end
		end
	
		self._queued_units = {}
	end
	
end

if RequiredScript == "lib/units/interactions/interactionext" then
	
	local set_tweak_data_original = BaseInteractionExt.set_tweak_data
	
	function BaseInteractionExt:set_tweak_data(...)
		local old_tweak = self.tweak_data
		local was_active = self:active()
		
		set_tweak_data_original(self, ...)
		
		if was_active and self:active() and self.tweak_data ~= old_tweak then
			managers.interaction:remove_unit_clbk(self._unit, old_tweak)
			managers.interaction:add_unit_clbk(self._unit)
		end
	end
	
end



--[[
if RequiredScript == "lib/managers/objectinteractionmanager" then
	
	local init_original = ObjectInteractionManager.init
	local update_original = ObjectInteractionManager.update
	local add_unit_original = ObjectInteractionManager.add_unit
	local remove_unit_original = ObjectInteractionManager.remove_unit
	
	
	ObjectInteractionManager.TRIGGERS = {
		[136843] = {
			136844, 136845, 136846, 136847, --HB armory ammo shelves
			136859, 136860, 136864, 136865, 136866, 136867, 136868, 136869, 136870, --HB armory grenades
		},	
		[151868] = { 151611 }, --GGC armory ammo shelf 1
		[151869] = {
			151612, --GGC armory ammo shelf 2
			151596, 151597, 151598, --GGC armory grenades
		},
		--[101835] = { 101470, 101472, 101473 },	--HB infirmary med boxes (not needed, triggers on interaction activation)
	}
	
	ObjectInteractionManager.INTERACTION_TRIGGERS = {
		requires_ecm_jammer_double = {
			[Vector3(-2217.05, 2415.52, -354.502)] = 136843,	--HB armory door 1
			[Vector3(1817.05, 3659.48, 45.4985)] = 136843,	--HB armory door 2
		},
		drill = {
			[Vector3(142, 3098, -197)] = 151868,	--GGC armory cage 1 alt 1
			[Vector3(-166, 3413, -197)] = 151869,	--GGC armory cage 2 alt 1
			[Vector3(3130, 1239, -195.5)] = 151868,	--GGC armory cage X alt 2	(may be reversed)
			[Vector3(3445, 1547, -195.5)] = 151869,	--GGC armory cage Y alt 2	(may be reversed)
		},
	}
	
	function ObjectInteractionManager:init(...)
		init_original(self, ...)
		
		self._queued_units = {}
		self._unit_triggers = {}
		self._trigger_blocks = {}
		
		GroupAIStateBase.register_listener_clbk("ObjectInteractionManager_cancel_pager_listener", "on_whisper_mode_change", callback(self, self, "_whisper_mode_change"))
	end
	
	function ObjectInteractionManager:update(t, ...)
		update_original(self, t, ...)
		self:_check_queued_units(t)
	end
	
	function ObjectInteractionManager:add_unit(unit, ...)		
		for pos, trigger_id in pairs(ObjectInteractionManager.INTERACTION_TRIGGERS[unit:interaction().tweak_data] or {}) do
			if mvector3.distance(unit:position(), pos) <= 10 then
				self:block_trigger(trigger_id, true)
				break
			end
		end
	
		table.insert(self._queued_units, unit)
		return add_unit_original(self, unit, ...)
	end
	
	function ObjectInteractionManager:remove_unit(unit, ...)
		for pos, trigger_id in pairs(ObjectInteractionManager.INTERACTION_TRIGGERS[unit:interaction().tweak_data] or {}) do
			if mvector3.distance(unit:position(), pos) <= 10 then
				self._trigger_blocks[trigger_id] = false
				break
			end
		end
	
		self:_check_remove_unit(unit)
		return remove_unit_original(self, unit, ...)
	end
	
	function ObjectInteractionManager:_check_queued_units(t)
		local level_id = managers.job:current_level_id()
		
		for i, unit in ipairs(self._queued_units) do
			if alive(unit) then
				local editor_id = unit:editor_id()
				local interaction_id = unit:interaction().tweak_data

				if false then --ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id] then
					local data = ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id]
					local blocked
					
					for trigger_id, editor_ids in pairs(ObjectInteractionManager.TRIGGERS) do
						if table.contains(editor_ids, editor_id) then							
							blocked = self._trigger_blocks[trigger_id]
							self._unit_triggers[trigger_id] = self._unit_triggers[trigger_id] or {}
							table.insert(self._unit_triggers[trigger_id], { unit = unit, class = data.class, offset = data.offset })
							break
						end
					end
					
					unit:base():set_equipment_active(data.class, not blocked, data.offset)
				end
				
				self._do_listener_callback("on_unit_added", unit)
			end
		end
		
		self._queued_units = {}
	end
	
	function ObjectInteractionManager:_check_remove_unit(unit)
		for i, queued_unit in ipairs(self._queued_units) do
			if queued_unit:key() == unit:key() then
				table.remove(self._queued_units, i)
				return
			end
		end
		
		local editor_id = unit:editor_id()
		local interaction_id = unit:interaction().tweak_data
		
		if false then --ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id] then
			unit:base():set_equipment_active(ObjectInteractionManager.EQUIPMENT_INTERACTION_ID[interaction_id].class, false)
		end
		
		self._do_listener_callback("on_unit_removed", unit)
	end
	
	function ObjectInteractionManager:block_trigger(trigger_id, status)
		if ObjectInteractionManager.TRIGGERS[trigger_id] then
			--io.write("ObjectInteractionManager:block_trigger(" .. tostring(trigger_id) .. ", " .. tostring(status) .. ")\n")
			self._trigger_blocks[trigger_id] = status
			
			for id, data in ipairs(self._unit_triggers[trigger_id] or {}) do
				if alive(data.unit) then
					--io.write("Set active " .. tostring(data.unit:editor_id()) .. ": " .. tostring(not status) .. "\n")
					data.unit:base():set_equipment_active(data.class, not status, data.offset)
				end
			end
		end
	end
	
end

if RequiredScript == "lib/units/props/missiondoor" then

	local deactivate_original = MissionDoor.deactivate
	
	function MissionDoor:deactivate(...)
		managers.interaction:block_trigger(self._unit:editor_id(), false)
		return deactivate_original(self, ...)
	end
	
end
]]
