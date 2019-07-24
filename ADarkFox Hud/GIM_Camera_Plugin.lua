local plugin = "cameras"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Cameras", desc = "Handles tracking of camera units and tape loop timers" }, "init_cameras_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	function GameInfoManager:init_cameras_plugin()
		self._cameras = self._cameras or {}
	end
	
	function GameInfoManager:get_cameras(key)
		if key then
			return self._cameras[key]
		else
			return self._cameras
		end
	end
	
	function GameInfoManager:_camera_event(event, key, data)
		if event == "create" then
			if not self._cameras[key] then
				self._cameras[key] = { unit = data.unit }
				self:_listener_callback("camera", event, key, self._cameras[key])
			end
		elseif self._cameras[key] then
			if event == "set_active" then
				if self._cameras[key].active == data.active then return end
				self._cameras[key].active = data.active
			elseif event == "start_tape_loop" then
				self._cameras[key].tape_loop_expire_t = data.tape_loop_expire_t
				self._cameras[key].tape_loop_start_t = Application:time()
			elseif event == "stop_tape_loop" then
				self._cameras[key].tape_loop_expire_t = nil
				self._cameras[key].tape_loop_start_t = nil
			end
			
			self:_listener_callback("camera", event, key, self._cameras[key])
			
			if event == "destroy" then
				self._cameras[key] = nil
			end
		end
	end

end

if RequiredScript == "lib/units/interactions/interactionext" then
	
	local SecurityCameraInteractionExt_set_active_original = SecurityCameraInteractionExt.set_active
	
	function SecurityCameraInteractionExt:set_active(active, ...)
		managers.gameinfo:event("camera", "set_active", tostring(self._unit:key()), { active = active and true or false } )
		return SecurityCameraInteractionExt_set_active_original(self, active, ...)
	end
	
end

if RequiredScript == "lib/units/props/securitycamera" then
	
	local init_original = SecurityCamera.init
	local _start_tape_loop_original = SecurityCamera._start_tape_loop
	local _deactivate_tape_loop_restart_original = SecurityCamera._deactivate_tape_loop_restart
	local _deactivate_tape_loop_original = SecurityCamera._deactivate_tape_loop
	local destroy_original = SecurityCamera.destroy
	
	function SecurityCamera:init(unit, ...)
		managers.gameinfo:event("camera", "create", tostring(unit:key()), { unit = unit } )
		return init_original(self, unit, ...)
	end
	
	function SecurityCamera:_start_tape_loop(...)
		_start_tape_loop_original(self, ...)
		managers.gameinfo:event("camera", "start_tape_loop", tostring(self._unit:key()), { tape_loop_expire_t = self._tape_loop_end_t + 5 })
	end
	
	function SecurityCamera:_deactivate_tape_loop_restart(...)
		managers.gameinfo:event("camera", "stop_tape_loop", tostring(self._unit:key()))
		return _deactivate_tape_loop_restart_original(self, ...)
	end
	
	function SecurityCamera:_deactivate_tape_loop(...)
		managers.gameinfo:event("camera", "stop_tape_loop", tostring(self._unit:key()))
		return _deactivate_tape_loop_original(self, ...)
	end
	
	function SecurityCamera:destroy(...)
		destroy_original(self, ...)
		managers.gameinfo:event("camera", "destroy", tostring(self._unit:key()))
	end
	
end
