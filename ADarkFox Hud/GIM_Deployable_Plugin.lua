local plugin = "deployables"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Deployables", desc = "Handles mission assets and deployable bags/crates" }, "init_deployables_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then
	
	GameInfoManager._DEPLOYABLES = {
		interaction_ids = {
			firstaid_box =		"doc_bag",
			ammo_bag =			"ammo_bag",
			doctor_bag =		"doc_bag",
			bodybags_bag =		"body_bag",
			grenade_crate =	"grenade_crate",
		},
		amount_offsets = {
			[tostring(Idstring("units/payday2/equipment/gen_equipment_ammobag/gen_equipment_ammobag"))] = 0,	--AmmoBagBase / bag
			[tostring(Idstring("units/payday2/props/stn_prop_armory_shelf_ammo/stn_prop_armory_shelf_ammo"))] = -1,	--CustomAmmoBagBase / shelf 1
			[tostring(Idstring("units/pd2_dlc_spa/props/spa_prop_armory_shelf_ammo/spa_prop_armory_shelf_ammo"))] = -1,	--CustomAmmoBagBase / shelf 2
			[tostring(Idstring("units/payday2/equipment/gen_equipment_medicbag/gen_equipment_medicbag"))] = 0,	--DoctorBagBase / bag
			[tostring(Idstring("units/payday2/props/stn_prop_medic_firstaid_box/stn_prop_medic_firstaid_box"))] = -1,	--CustomDoctorBagBase / cabinet 1
			[tostring(Idstring("units/pd2_dlc_casino/props/cas_prop_medic_firstaid_box/cas_prop_medic_firstaid_box"))] = -1,	--CustomDoctorBagBase / cabinet 2
			[tostring(Idstring("units/pd2_dlc_old_hoxton/equipment/gen_equipment_first_aid_kit/gen_equipment_first_aid_kit"))] = 0,	--FirstAidKitBase / FAK
			[tostring(Idstring("units/payday2/equipment/gen_equipment_grenade_crate/gen_equipment_explosives_case"))] = 0,	--GrenadeCrateBase / grenate crate
			[tostring(Idstring("units/payday2/equipment/gen_equipment_grenade_crate/gen_equipment_explosives_case_single"))] = 0,	--CustomGrenadeCrateBase / single grenade box
		},
		ignore_ids = {
			chill_combat = {	--Safehouse Raid (2x ammo shelves)
				[100751] = true,
				[101242] = true,
			},
			sah = { --Shacklethorne Auction (1x3 grenade crate)
				[400178] = true,
			}
		},
	}
	
	function GameInfoManager:init_deployables_plugin()
		self._deployables = self._deployables or {}
		self._deployables.ammo_bag = self._deployables.ammo_bag or {}
		self._deployables.doc_bag = self._deployables.doc_bag or {}
		self._deployables.body_bag = self._deployables.body_bag or {}
		self._deployables.grenade_crate = self._deployables.grenade_crate or {}
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
	
	function GameInfoManager:_deployable_interaction_handler(event, key, data)
		local type = GameInfoManager._DEPLOYABLES.interaction_ids[data.interact_id]
		
		if self._deployables[type][key] then
			local active = event == "add"
			
			if active then
				local offset = GameInfoManager._DEPLOYABLES.amount_offsets[tostring(data.unit:name())] or 0
				if offset ~= 0 then
					self:_bag_deployable_event("set_amount_offset", key, { amount_offset = offset }, type)
				end
			end
			
			self:_bag_deployable_event("set_active", key, { active = active }, type)
		end
	end
	
	function GameInfoManager:_doc_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "doc_bag")
	end
	
	function GameInfoManager:_ammo_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "ammo_bag")
	end
	
	function GameInfoManager:_body_bag_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "body_bag")
	end
	
	function GameInfoManager:_grenade_crate_event(event, key, data)
		self:_bag_deployable_event(event, key, data, "grenade_crate")
	end
	
	function GameInfoManager:_bag_deployable_event(event, key, data, type)
		if event == "create" then
			if self._deployables[type][key] then return end
			self._deployables[type][key] = { unit = data.unit, type = type }
			self:_listener_callback(type, event, key, self._deployables[type][key])
		elseif self._deployables[type][key] then
			if event == "set_active" then
				if self._deployables[type][key].active == data.active then return end
				self._deployables[type][key].active = data.active
			elseif event == "set_owner" then
				self._deployables[type][key].owner = data.owner
			elseif event == "set_max_amount" then
				self._deployables[type][key].max_amount = data.max_amount
			elseif event == "set_amount_offset" then
				self._deployables[type][key].amount_offset = data.amount_offset
			elseif event == "set_amount" then
				self._deployables[type][key].amount = data.amount
			elseif event == "set_upgrades" then
				self._deployables[type][key].upgrades = data.upgrades
			end
			
			self:_listener_callback(type, event, key, self._deployables[type][key])
			
			if event == "destroy" then
				self._deployables[type][key] = nil
			end
		end
	end
	
	local _interactive_unit_event_original = GameInfoManager._interactive_unit_event
	
	function GameInfoManager:_interactive_unit_event(event, key, data)
		if GameInfoManager._DEPLOYABLES.interaction_ids[data.interact_id] then
			local ignore_lookup = GameInfoManager._DEPLOYABLES.ignore_ids
			local level_id = managers.job:current_level_id()
			
			if not (ignore_lookup[level] and ignore_lookup[level][data.editor_id]) then
				self:_deployable_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original(self, event, key, data)
	end
	
end

if RequiredScript == "lib/units/equipment/doctor_bag/doctorbagbase" then
	
	local spawn_original = DoctorBagBase.spawn
	local init_original = DoctorBagBase.init
	local sync_setup_original = DoctorBagBase.sync_setup
	local _set_visual_stage_original = DoctorBagBase._set_visual_stage
	local destroy_original = DoctorBagBase.destroy
	
	function DoctorBagBase.spawn(pos, rot, amount_upgrade_lvl, peer_id, ...)
		local unit = spawn_original(pos, rot, amount_upgrade_lvl, peer_id, ...)
		if alive(unit) then
			local key = tostring(unit:key())
			managers.gameinfo:event("doc_bag", "create", key, { unit = unit })
			managers.gameinfo:event("doc_bag", "set_owner", key, { owner = peer_id })
		end
		return unit
	end
	
	function DoctorBagBase:init(unit, ...)
		local key = tostring(unit:key())
		managers.gameinfo:event("doc_bag", "create", key, { unit = unit })
		init_original(self, unit, ...)
		managers.gameinfo:event("doc_bag", "set_max_amount", key, { max_amount = self._max_amount })
	end
	
	function DoctorBagBase:sync_setup(amount_upgrade_lvl, peer_id, ...)
		managers.gameinfo:event("doc_bag", "set_owner", tostring(self._unit:key()), { owner = peer_id })
		return sync_setup_original(self, amount_upgrade_lvl, peer_id, ...)
	end
	
	function DoctorBagBase:_set_visual_stage(...)
		managers.gameinfo:event("doc_bag", "set_amount", tostring(self._unit:key()), { amount = self._amount })
		return _set_visual_stage_original(self, ...)
	end
	
	function DoctorBagBase:destroy(...)
		managers.gameinfo:event("doc_bag", "destroy", tostring(self._unit:key()))
		return destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/equipment/ammo_bag/ammobagbase" then
	
	local spawn_original = AmmoBagBase.spawn
	local init_original = AmmoBagBase.init
	local sync_setup_original = AmmoBagBase.sync_setup
	local _set_visual_stage_original = AmmoBagBase._set_visual_stage
	local destroy_original = AmmoBagBase.destroy
	
	function AmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl, peer_id, bullet_storm_level, ...)
		local unit = spawn_original(pos, rot, ammo_upgrade_lvl, peer_id, bullet_storm_level, ...)
		if alive(unit) then
			local key = tostring(unit:key())
			managers.gameinfo:event("ammo_bag", "create", key, { unit = unit })
			managers.gameinfo:event("ammo_bag", "set_owner", key, { owner = peer_id })
			managers.gameinfo:event("ammo_bag", "set_upgrades", key, { upgrades = { bullet_storm = bullet_storm_level } })
		end
		return unit
	end
	
	function AmmoBagBase:init(unit, ...)
		local key = tostring(unit:key())
		managers.gameinfo:event("ammo_bag", "create", key, { unit = unit })
		init_original(self, unit, ...)
		managers.gameinfo:event("ammo_bag", "set_max_amount", key, { max_amount = self._max_ammo_amount })
	end
	
	function AmmoBagBase:sync_setup(ammo_upgrade_lvl, peer_id, bullet_storm_level, ...)
		local key =tostring(self._unit:key())
		managers.gameinfo:event("ammo_bag", "set_owner", key, { owner = peer_id })
		managers.gameinfo:event("ammo_bag", "set_upgrades", key, { upgrades = { bullet_storm = bullet_storm_level } })
		return sync_setup_original(self, ammo_upgrade_lvl, peer_id, bullet_storm_level, ...)
	end
	
	function AmmoBagBase:_set_visual_stage(...)
		managers.gameinfo:event("ammo_bag", "set_amount", tostring(self._unit:key()), { amount = self._ammo_amount })
		return _set_visual_stage_original(self, ...)
	end
	
	function AmmoBagBase:destroy(...)
		managers.gameinfo:event("ammo_bag", "destroy", tostring(self._unit:key()))
		return destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/equipment/bodybags_bag/bodybagsbagbase" then
	
	local spawn_original = BodyBagsBagBase.spawn
	local init_original = BodyBagsBagBase.init
	local sync_setup_original = BodyBagsBagBase.sync_setup
	local _set_visual_stage_original = BodyBagsBagBase._set_visual_stage
	local destroy_original = BodyBagsBagBase.destroy
	
	function BodyBagsBagBase.spawn(pos, rot, upgrade_lvl, peer_id, ...)
		local unit = spawn_original(pos, rot, upgrade_lvl, peer_id, ...)
		if alive(unit) then
			local key = tostring(unit:key())
			managers.gameinfo:event("body_bag", "create", key, { unit = unit })
			managers.gameinfo:event("body_bag", "set_owner", key, { owner = peer_id })
		end
		return unit
	end
	
	function BodyBagsBagBase:init(unit, ...)
		local key = tostring(unit:key())
		managers.gameinfo:event("body_bag", "create", key, { unit = unit })
		init_original(self, unit, ...)
		managers.gameinfo:event("body_bag", "set_max_amount", key, { max_amount = self._max_bodybag_amount })
	end
	
	function BodyBagsBagBase:sync_setup(upgrade_lvl, peer_id, ...)
		managers.gameinfo:event("body_bag", "set_owner", tostring(self._unit:key()), { owner = peer_id })
		return sync_setup_original(self, upgrade_lvl, peer_id, ...)
	end
	
	function BodyBagsBagBase:_set_visual_stage(...)
		managers.gameinfo:event("body_bag", "set_amount", tostring(self._unit:key()), { amount = self._bodybag_amount })
		return _set_visual_stage_original(self, ...)
	end
	
	function BodyBagsBagBase:destroy(...)
		managers.gameinfo:event("body_bag", "destroy", tostring(self._unit:key()))
		return destroy_original(self, ...)
	end
	
end

if RequiredScript == "lib/units/equipment/grenade_crate/grenadecratebase" then
	
	local init_original = GrenadeCrateBase.init
	local _set_visual_stage_original = GrenadeCrateBase._set_visual_stage
	local destroy_original = GrenadeCrateBase.destroy
	local custom_init_original = CustomGrenadeCrateBase.init
	
	function GrenadeCrateBase:init(unit, ...)
		local key = tostring(unit:key())
		managers.gameinfo:event("grenade_crate", "create", key, { unit = unit })
		init_original(self, unit, ...)
		managers.gameinfo:event("grenade_crate", "set_max_amount", key, { max_amount = self._max_grenade_amount })
	end
	
	function GrenadeCrateBase:_set_visual_stage(...)
		managers.gameinfo:event("grenade_crate", "set_amount", tostring(self._unit:key()), { amount = self._grenade_amount })
		return _set_visual_stage_original(self, ...)
	end
	
	function GrenadeCrateBase:destroy(...)
		managers.gameinfo:event("grenade_crate", "destroy", tostring(self._unit:key()))
		return destroy_original(self, ...)
	end
	
	function CustomGrenadeCrateBase:init(unit, ...)
		local key = tostring(unit:key())
		managers.gameinfo:event("grenade_crate", "create", key, { unit = unit })
		custom_init_original(self, unit, ...)
		managers.gameinfo:event("grenade_crate", "set_max_amount", key, { max_amount = self._max_grenade_amount })
	end
	
end