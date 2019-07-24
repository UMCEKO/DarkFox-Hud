local plugin = "sentries"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Sentries", desc = "Tracks deployable sentries" }, "init_sentry_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then
	
	function GameInfoManager:init_sentry_plugin()
		self._deployables = self._deployables or {}
		self._deployables.sentry = self._deployables.sentry or {}
	end
	
	function GameInfoManager:get_deployables(type, key)
		if type and key then
			return self._deployables[type][key]
		elseif type then
			return self._deployables[type]
		else
			return self._deployables
		end
	end

	function GameInfoManager:_sentry_event(event, key, data)
		if event == "create" then
			local sentry_type = data.unit:base() and data.unit:base():get_type()
			
			if not self._deployables.sentry[key] and (sentry_type == "sentry_gun" or sentry_type == "sentry_gun_silent") then
				self._deployables.sentry[key] = { unit = data.unit, kills = 0, type = "sentry" }
				self:_listener_callback("sentry", event, key, self._deployables.sentry[key])
			end
		elseif self._deployables.sentry[key] then
			if event == "set_active" then
				if self._deployables.sentry[key].active == data.active then return end
				self._deployables.sentry[key].active = data.active
			elseif event == "set_ammo_ratio" then
				self._deployables.sentry[key].ammo_ratio = data.ammo_ratio
			elseif event == "increment_kills" then
				self._deployables.sentry[key].kills = self._deployables.sentry[key].kills + 1
			elseif event == "set_health_ratio" then
				self._deployables.sentry[key].health_ratio = data.health_ratio
			elseif event == "set_owner" then
				self._deployables.sentry[key].owner = data.owner
			end
			
			self:_listener_callback("sentry", event, key, self._deployables.sentry[key])
			
			if event == "destroy" then
				self._deployables.sentry[key] = nil
			end
		end
	end
	
end

if RequiredScript == "lib/units/enemies/cop/copdamage" then

	local chk_killshot_original = CopDamage.chk_killshot
	
	function CopDamage:chk_killshot(attacker_unit, ...)
		if alive(attacker_unit) then
			local key = tostring(attacker_unit:key())
			
			if attacker_unit:in_slot(25) and managers.gameinfo:get_deployables("sentry", key) then
				managers.gameinfo:event("sentry", "increment_kills", key)
			end
		end
		
		return chk_killshot_original(self, attacker_unit, ...)
	end

end

if RequiredScript == "lib/units/equipment/sentry_gun/sentrygunbase" then
	
	local spawn_original = SentryGunBase.spawn
	local init_original = SentryGunBase.init
	local sync_setup_original = SentryGunBase.sync_setup
	local destroy_original = SentryGunBase.destroy
	
	function SentryGunBase.spawn(owner, pos, rot, peer_id, ...)
		local unit = spawn_original(owner, pos, rot, peer_id, ...)
		if alive(unit) then
			managers.gameinfo:event("sentry", "create", tostring(unit:key()), { unit = unit })
			managers.gameinfo:event("sentry", "set_owner", tostring(unit:key()), { owner = peer_id })
		end
		return unit
	end
	
	function SentryGunBase:init(unit, ...)
		managers.gameinfo:event("sentry", "create", tostring(unit:key()), { unit = unit })
		init_original(self, unit, ...)
	end
	
	function SentryGunBase:sync_setup(upgrade_lvl, peer_id, ...)
		managers.gameinfo:event("sentry", "set_owner", tostring(self._unit:key()), { owner = peer_id })
		return sync_setup_original(self, upgrade_lvl, peer_id, ...)
	end
	
	function SentryGunBase:destroy(...)
		managers.gameinfo:event("sentry", "set_active", tostring(self._unit:key()), { active = false })
		managers.gameinfo:event("sentry", "destroy", tostring(self._unit:key()))
		return destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/equipment/sentry_gun/sentrygundamage" then
	
	local init_original = SentryGunDamage.init
	local set_health_original = SentryGunDamage.set_health
	local sync_health_original = SentryGunDamage.sync_health
	local _apply_damage_original = SentryGunDamage._apply_damage
	local die_original = SentryGunDamage.die
	local load_original = SentryGunDamage.load
	
	function SentryGunDamage:init(...)
		init_original(self, ...)
		managers.gameinfo:event("sentry", "set_active", tostring(self._unit:key()), { active = true })
		managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	end
	
	function SentryGunDamage:set_health(...)
		set_health_original(self, ...)
		managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	end
	
	function SentryGunDamage:sync_health(...)
		sync_health_original(self, ...)
		managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	end
	
	function SentryGunDamage:_apply_damage(...)
		local result = _apply_damage_original(self, ...)
		managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
		return result
	end
	
	function SentryGunDamage:die(...)
		managers.gameinfo:event("sentry", "set_active", tostring(self._unit:key()), { active = false })
		return die_original(self, ...)
	end
	
	function SentryGunDamage:load(...)
		load_original(self, ...)
		managers.gameinfo:event("sentry", "set_health_ratio", tostring(self._unit:key()), { health_ratio = self:health_ratio() })
	end
	
end

if RequiredScript == "lib/units/weapons/sentrygunweapon" then
	
	local init_original = SentryGunWeapon.init
	local change_ammo_original = SentryGunWeapon.change_ammo
	local sync_ammo_original = SentryGunWeapon.sync_ammo
	local load_original = SentryGunWeapon.load
	
	function SentryGunWeapon:init(...)
		init_original(self, ...)
		managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
	end
	
	function SentryGunWeapon:change_ammo(...)
		change_ammo_original(self, ...)
		managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
	end
	
	function SentryGunWeapon:sync_ammo(...)
		sync_ammo_original(self, ...)
		managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
	end
	
	function SentryGunWeapon:load(...)
		load_original(self, ...)
		managers.gameinfo:event("sentry", "set_ammo_ratio", tostring(self._unit:key()), { ammo_ratio = self:ammo_ratio() })
	end
	
end