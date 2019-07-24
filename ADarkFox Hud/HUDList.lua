local function log_error(fmt, ...)
	log(string.format("[ERROR] (HUDList.lua): " .. fmt, ...))
end

local function log_warning(fmt, ...)
	log(string.format("[WARNING] (HUDList.lua): " .. fmt, ...))
end


if HUDListManager then
	HUDListManager.add_post_init_event(function()
		if not GameInfoManager then
			return log_error("Script requires GameInfoManager to function, aborting setup")
		else
			managers.gameinfo:add_scheduled_callback("HUDList_setup_clbk", 1, function()
				managers.hudlist:setup()
			end)
		end
	end)
end


function HUDListManager:setup()
	self:_setup_left_list()
	self:_setup_right_list()
	self:_setup_buff_list()
end

function HUDListManager:_setup_left_list()
	local scale = HUDListManager.ListOptions.left_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = self._hud_panel:h()
	local x = 0
	
	local list = self:add_list("left_list", HUDList.VerticalList, { 
		valign = "top", 
		halign = "left", 
		x = x, 
		w = list_w, 
		h = list_h, 
		item_margin = 5
	})
	self:_set_left_list_y()
	
	local function list_config_template(size, prio, ...)
		return {
			halign = "left", 
			valign = "center", 
			w = list_w, 
			h = size--[[ * scale]], 
			priority = prio,
			item_margin = 3, 
			static_item = {
				class = HUDList.StaticItem, 
				data = { 30--[[ * scale]], ... },
			}
		}
	end

	if GameInfoManager.plugin_active("deployables") then
		list:add_item("equipment", HUDList.RescalableHorizontalList, list_config_template(40, 8, 
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.ammo_bag.skills, valign = "top", halign = "right" },
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.doc_bag.skills, valign = "top", halign = "left" },
			{ h_scale = 0.55, w_scale = 0.55, preplanning = HUDListManager.EQUIPMENT_TABLE.grenade_crate.preplanning, valign = "bottom", halign = "right" },
			{ h_scale = 0.55, w_scale = 0.55, skills = HUDListManager.EQUIPMENT_TABLE.body_bag.skills, valign = "bottom", halign = "left" })):rescale(scale)
		self:_set_show_ammo_bags()
		self:_set_show_doc_bags()
		self:_set_show_body_bags()
		self:_set_show_grenade_crates()
	end
	
	if GameInfoManager.plugin_active("sentries") then
		list:add_item("sentries", HUDList.RescalableHorizontalList, list_config_template(40, 7, { skills = HUDListManager.EQUIPMENT_TABLE.sentry.skills })):rescale(scale)
		self:_set_show_sentries()
	end
	
	if GameInfoManager.plugin_active("timers") then
		list:add_item("timers", HUDList.TimerList, list_config_template(60, 6, { skills = { 3, 6 } })):rescale(scale)
		self:_set_show_timers()
	end
	
	if GameInfoManager.plugin_active("units") then
		list:add_item("minions", HUDList.RescalableHorizontalList, list_config_template(45, 5, { skills = { 6, 8 } })):rescale(scale)
		self:_set_show_minions()
	end
	
	if GameInfoManager.plugin_active("ecms") then
		list:add_item("ecm_retrigger", HUDList.RescalableHorizontalList, list_config_template(40, 4, { skills = { 6, 2 } })):rescale(scale)
		list:add_item("ecms", HUDList.RescalableHorizontalList, list_config_template(40, 3, { skills = { 1, 4 } })):rescale(scale)
		self:_set_show_ecms()
		self:_set_show_ecm_retrigger()
	end
	
	if GameInfoManager.plugin_active("cameras") then
		list:add_item("tape_loop", HUDList.RescalableHorizontalList, list_config_template(40, 2, { skills = { 4, 2 } })):rescale(scale)
		self:_set_show_tape_loop()
	end
	
	if GameInfoManager.plugin_active("pagers") then
		list:add_item("pagers", HUDList.RescalableHorizontalList, list_config_template(40, 1, { perks = { 1, 4 } })):rescale(scale)
		self:_set_show_pagers()
	end
end

function HUDListManager:_setup_right_list()
	local scale = HUDListManager.ListOptions.right_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = self._hud_panel:h()
	local x = 0

	local list = self:add_list("right_list", HUDList.VerticalList, { 
		valign = "top", 
		halign = "right", 
		x = x, 
		w = list_w, 
		h = list_h, 
		item_margin = 5,
	})
	self:_set_right_list_y()
	
	local function list_config_template(prio)
		return {
			halign = "right", 
			valign = "center", 
			w = list_w, 
			h = 50--[[ * scale]], 
			item_margin = 3, 
			priority = prio,
		}
	end
	
	if GameInfoManager.plugin_active("units") then
		list:add_item("unit_count_list", HUDList.RescalableHorizontalList, list_config_template(4)):rescale(scale)
		self:_set_show_enemies()
		self:_set_show_turrets()
		self:_set_show_civilians()
		self:_set_show_hostages()
		self:_set_show_minion_count()
	end
	
	if GameInfoManager.plugin_active("loot") then
		list:add_item("loot_list", HUDList.RescalableHorizontalList, list_config_template(3)):rescale(scale)
		self:_set_show_loot()
	end
	
	if GameInfoManager.plugin_active("pickups") then
		list:add_item("special_pickup_list", HUDList.RescalableHorizontalList, list_config_template(2)):rescale(scale)
		self:_set_show_special_pickups()
	end
	
	if GameInfoManager.plugin_active("loot") or GameInfoManager.plugin_active("pagers") or GameInfoManager.plugin_active("cameras") then
		list:add_item("stealth_list", HUDList.StealthList, list_config_template(1)):rescale(scale)
		
		if GameInfoManager.plugin_active("loot") then
			self:_set_show_body_count()
		end
		if GameInfoManager.plugin_active("pagers") then
			self:_set_show_pager_count()
		end
		if GameInfoManager.plugin_active("cameras") then
			self:_set_show_camera_count()
		end
	end
end

function HUDListManager:_setup_buff_list()
	local scale = HUDListManager.ListOptions.buff_list_scale or 1
	local list_w = self._hud_panel:w()
	local list_h = 70 * scale
	local x = 0
	
	self:add_list("buff_list", HUDList.HorizontalList, { 
		halign = "center", 
		valign = "center",
		x = x,
		w = list_w, 
		h = list_h, 
		item_margin = 0,
	})
	self:_set_buff_list_y()

	if GameInfoManager.plugin_active("buffs") then
		self:_set_show_buffs()
	end
	if GameInfoManager.plugin_active("player_actions") then
		self:_set_show_player_actions()
	end
end


--General config
function HUDListManager:_set_left_list_y()
	local list_panel = self:list("left_list"):panel()
	local y = HUDListManager.ListOptions.left_list_y or 40
	list_panel:set_y(y)
end

function HUDListManager:_set_right_list_y()
	local list_panel = self:list("right_list"):panel()
	local y = HUDListManager.ListOptions.right_list_y or 0
	list_panel:set_y(y)
end

function HUDListManager:_set_buff_list_y()
	local list_panel = self:list("buff_list"):panel()
	local list_h = list_panel:h()
	local y = self._hud_panel:bottom() - ((HUDListManager.ListOptions.buff_list_y or 80) + list_h)

	if HUDManager.CUSTOM_TEAMMATE_PANEL then
		local teammate_panel = managers.hud._teammate_panels_custom or managers.hud._teammate_panels 
		y = teammate_panel[HUDManager.PLAYER_PANEL]:panel():top() - (list_h + 5)
	end
	
	list_panel:set_y(y)
end

function HUDListManager:_set_left_list_scale()
	for lid, list in pairs(self:list("left_list"):items()) do
		list:rescale(HUDListManager.ListOptions.left_list_scale or 1)
	end
	self:list("left_list"):rearrange()
end

function HUDListManager:_set_right_list_scale()
	for lid, list in pairs(self:list("right_list"):items()) do
		list:rescale(HUDListManager.ListOptions.right_list_scale or 1)
	end
	self:list("right_list"):rearrange()
end

function HUDListManager:_set_buff_list_scale()
	
end

--Left list config
function HUDListManager:_set_show_timers()
	local list = self:list("left_list"):item("timers")
	local listener_id = "HUDListManager_timer_listener"
	local events = { "set_active" }
	local clbk = callback(self, self, "_timer_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_timers then
			managers.gameinfo:register_listener(listener_id, "timer", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "timer", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_timers()) do
		if HUDListManager.ListOptions.show_timers then
			clbk("set_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ammo_bags()
	self:_show_bag_deployable_by_type("ammo_bag", HUDListManager.ListOptions.show_ammo_bags)
end

function HUDListManager:_set_show_doc_bags()
	self:_show_bag_deployable_by_type("doc_bag", HUDListManager.ListOptions.show_doc_bags)
end

function HUDListManager:_set_show_body_bags()
	self:_show_bag_deployable_by_type("body_bag", HUDListManager.ListOptions.show_body_bags)
end

function HUDListManager:_set_show_grenade_crates()
	self:_show_bag_deployable_by_type("grenade_crate", HUDListManager.ListOptions.show_grenade_crates)
end

function HUDListManager:_set_show_sentries()
	local list = self:list("left_list"):item("sentries")
	local listener_id = "HUDListManager_sentry_listener"
	local events = { "set_active" }
	local clbk = callback(self, self, "_sentry_equipment_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_sentries > 0 then
			managers.gameinfo:register_listener(listener_id, "sentry", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "sentry", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_deployables("sentry")) do
		if HUDListManager.ListOptions.show_sentries > 0 then
			clbk("set_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_minions()
	local listener_id = "HUDListManager_minion_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_minion_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_minions > 0 then
			managers.gameinfo:register_listener(listener_id, "minion", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "minion", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_minions()) do
		clbk(HUDListManager.ListOptions.show_minions > 0 and "add" or "remove", key, data)
	end
end

function HUDListManager:_set_show_pagers()
	local list = self:list("left_list"):item("pagers")
	local listener_id = "HUDListManager_pager_listener"
	local events = { "add", "remove" }
	local clbk = callback(self, self, "_pager_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_pagers then
			managers.gameinfo:register_listener(listener_id, "pager", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "pager", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_pagers()) do
		if HUDListManager.ListOptions.show_pagers then
			if data.active then
				clbk("add", key, data)
			end
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ecms()
	local list = self:list("left_list"):item("ecms")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_jammer_active" } 
	local clbk = callback(self, self, "_ecm_event")

	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecms then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecms then
			clbk("set_jammer_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_ecm_retrigger()
	local list = self:list("left_list"):item("ecm_retrigger")
	local listener_id = "HUDListManager_ecm_listener"
	local events = { "set_retrigger_active" } 
	local clbk = callback(self, self, "_ecm_retrigger_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			managers.gameinfo:register_listener(listener_id, "ecm", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "ecm", event)
		end
	end

	for key, data in pairs(managers.gameinfo:get_ecms()) do
		if HUDListManager.ListOptions.show_ecm_retrigger then
			clbk("set_retrigger_active", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_set_show_tape_loop()
	local list = self:list("left_list"):item("tape_loop")
	local listener_id = "HUDListManager_tape_loop_listener"
	local events = { "start_tape_loop", "stop_tape_loop" }
	local clbk = callback(self, self, "_tape_loop_event")
	
	for _, event in pairs(events) do
		if HUDListManager.ListOptions.show_tape_loop then
			managers.gameinfo:register_listener(listener_id, "camera", event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, "camera", event)
		end
	end
	
	for key, data in pairs(managers.gameinfo:get_cameras()) do
		if data.tape_loop_expire_t and HUDListManager.ListOptions.show_tape_loop then
			clbk("start_tape_loop", key, data)
		else
			list:remove_item(key, true)
		end
	end
end

function HUDListManager:_show_bag_deployable_by_type(deployable_type, option_value)
	local list = self:list("left_list"):item("equipment")
	local listener_id = string.format("HUDListManager_%s_listener", deployable_type)
	local events = { "set_active" }
	local clbk = callback(self, self, "_deployable_equipment_event")
	
	for _, event in pairs(events) do
		if option_value > 0 then
			managers.gameinfo:register_listener(listener_id, deployable_type, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, deployable_type, event)
		end
	end
	
	for id, item in pairs(list:items()) do
		if item:equipment_type() == deployable_type then
			item:delete(true)
		end
	end
	
	if option_value > 0 then
		for key, data in pairs(managers.gameinfo:get_deployables(deployable_type)) do
			clbk("set_active", key, data)
		end
	end
end

--Right list config
function HUDListManager:_set_show_enemies()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("enemies")
	
	for unit_type, unit_ids in pairs(all_types) do
		list:remove_item(unit_type, true)
	end
	list:remove_item("enemies", true)
	
	if HUDListManager.ListOptions.show_enemies == 1 then
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, true)
		end
	elseif HUDListManager.ListOptions.show_enemies == 2 then
		self:_update_unit_count_list_items(list, "enemies", all_ids, true)
	end
end

function HUDListManager:_set_show_civilians()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("civilians")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_civilians)
	end
end

function HUDListManager:_set_show_hostages()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("hostages")
	
	for unit_type, unit_ids in pairs(all_types) do
		list:remove_item(unit_type, true)
	end
	list:remove_item("hostages", true)
	
	if HUDListManager.ListOptions.show_hostages == 1 then
		for unit_type, unit_ids in pairs(all_types) do
			self:_update_unit_count_list_items(list, unit_type, unit_ids, true)
		end
	elseif HUDListManager.ListOptions.show_hostages == 2 then
		self:_update_unit_count_list_items(list, "hostages", all_ids, true)
	end
end

function HUDListManager:_set_show_minion_count()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("minions")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_minion_count)
	end
end

function HUDListManager:_set_show_turrets()
	local list = self:list("right_list"):item("unit_count_list")
	local all_types, all_ids = self:_get_units_by_category("turrets")
	
	for unit_type, unit_ids in pairs(all_types) do
		self:_update_unit_count_list_items(list, unit_type, unit_ids, HUDListManager.ListOptions.show_turrets)
	end
end	

function HUDListManager:_set_show_pager_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_pager_count then
		list:add_item("PagerCount", HUDList.UsedPagersItem)
	else
		list:remove_item("PagerCount", true)
	end
end

function HUDListManager:_set_show_camera_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_camera_count then
		list:add_item("CameraCount", HUDList.CameraCountItem)
	else
		list:remove_item("CameraCount", true)
	end
end

function HUDListManager:_set_show_special_pickups()
	local list = self:list("right_list"):item("special_pickup_list")
	local all_ids = {}
	local all_types = {}
	
	for pickup_id, pickup_type in pairs(HUDListManager.SPECIAL_PICKUP_TYPES) do
		all_types[pickup_type] = all_types[pickup_type] or {}
		table.insert(all_types[pickup_type], pickup_id)
		table.insert(all_ids, pickup_id)
	end
	
	for pickup_type, members in pairs(all_types) do
		if HUDListManager.ListOptions.show_special_pickups and not HUDListManager.ListOptions.ignore_special_pickups[pickup_type] then
			list:add_item(pickup_type, HUDList.SpecialPickupItem, members)
		else
			list:remove_item(pickup_type, true)
		end
	end
end

function HUDListManager:_set_ignored_special_pickup(pickup, value)
	self:_set_show_special_pickups()
end

function HUDListManager:_set_show_loot()
	local list = self:list("right_list"):item("loot_list")
	local all_ids = {}
	local all_types = {}
	
	for loot_id, loot_type in pairs(HUDListManager.LOOT_TYPES) do
		all_types[loot_type] = all_types[loot_type] or {}
		table.insert(all_types[loot_type], loot_id)
		table.insert(all_ids, loot_id)
	end
	
	for loot_type, loot_ids in pairs(all_types) do
		list:remove_item(loot_type, true)
	end
	list:remove_item("aggregate", true)
	
	if HUDListManager.ListOptions.show_loot == 1 then
		for loot_type, loot_ids in pairs(all_types) do
			list:add_item(loot_type, HUDList.LootItem, loot_ids)
		end
	elseif HUDListManager.ListOptions.show_loot == 2 then
		list:add_item("aggregate", HUDList.LootItem, all_ids)
	end
end

function HUDListManager:_set_separate_bagged_loot()
	for _, item in pairs(self:list("right_list"):item("loot_list"):items()) do
		item:update_value()
	end
end

function HUDListManager:_get_units_by_category(category)
	local all_types = {}
	local all_ids = {}
	
	for unit_id, data in pairs(HUDListManager.UNIT_TYPES) do
		if data.category == category then
			all_types[data.type_id] = all_types[data.type_id] or {}
			table.insert(all_types[data.type_id], unit_id)
			table.insert(all_ids, unit_id)
		end
	end
	
	return all_types, all_ids
end

function HUDListManager:_update_unit_count_list_items(list, id, members, show)
	if show then
		local data = HUDList.UnitCountItem.MAP[id]
		local item = list:add_item(id, data.class or HUDList.UnitCountItem, members)
	else
		list:remove_item(id, true)
	end
end

function HUDListManager:_set_show_body_count()
	local list = self:list("right_list"):item("stealth_list")
	
	if HUDListManager.ListOptions.show_body_count then
		list:add_item("body_stealth", HUDList.BodyCountItem)
	else
		list:remove_item("body_stealth", true)
	end
end

--Buff list config
function HUDListManager:_set_show_buffs()
	local listener_id = "HUDListManager_buff_listener"
	local src = "buff"
	local events = { "activate", "deactivate" }
	local clbk = callback(self, self, "_buff_event")
	local list = self:list("buff_list")
	
	for _, event in ipairs(events) do
		if HUDListManager.ListOptions.show_buffs then
			managers.gameinfo:register_listener(listener_id, src, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, src, event)
		end
	end
	
	for buff_id, data in pairs(managers.gameinfo:get_buffs()) do
		if HUDListManager.ListOptions.show_buffs then
			clbk("activate", buff_id, data)
		else
			list:remove_item(buff_id, true)
		end
	end
end

function HUDListManager:_set_ignored_buff(item_id, value)
	local list = self:list("buff_list")
	
	if HUDListManager.ListOptions.show_buffs then
		if not value then
			local members = {}
			for id, data in pairs(HUDListManager.BUFFS) do
				if table.contains(data, item_id) then
					table.insert(members, id)
				end
			end
			
			local item_data = HUDList.BuffItemBase.MAP[item_id]
			local item = item_data and list:add_item(item_id, item_data.class or "BuffItemBase", members, item_data)
			
			for _, member_id in ipairs(members) do
				local buff_data = managers.gameinfo:get_buffs(member_id)
				
				if item and buff_data then
					local is_debuff = HUDListManager.BUFFS[member_id].is_debuff
					item:set_buff_active(member_id, true, buff_data, is_debuff)
					item:apply_current_values(member_id, buff_data)
				end
			end
		else
			list:remove_item(item_id, true)
		end
	end
end

function HUDListManager:_get_buff_items(id)
	local buff_list = self:list("buff_list")
	local items = {}
	local is_debuff = false
	
	local function create_item(item_id)
		if HUDListManager.ListOptions.ignore_buffs[item_id] then return end
		
		local item_data = HUDList.BuffItemBase.MAP[item_id]
		
		if item_data then
			local members = {}
		
			for buff_id, data in pairs(HUDListManager.BUFFS) do
				if table.contains(data, item_id) and not table.contains(members, buff_id) then
					table.insert(members, buff_id)
				end
			end
			
			return buff_list:add_item(item_id, item_data.class or "BuffItemBase", members, item_data)
		end
		
		printf("(%.2f) HUDListManager:_get_buff_items(%s): No map entry for item", Application:time(), tostring(item_id))
	end
	
	if HUDListManager.BUFFS[id] then
		for _, item_id in ipairs(HUDListManager.BUFFS[id]) do
			local item = buff_list:item(item_id) or create_item(item_id)
			if item then
				table.insert(items, item)
			end
		end
		is_debuff = HUDListManager.BUFFS[id].is_debuff
	else
		printf("(%.2f) HUDListManager:_get_buff_items(%s): No definition for buff", Application:time(), tostring(id))
	end
	
	return items, is_debuff
end

function HUDListManager:_set_show_player_actions()
	local listener_id = "HUDListManager_player_action_listener"
	local src = "player_action"
	local events = { "activate", "deactivate" }
	local clbk = callback(self, self, "_player_action_event")
	local list = self:list("buff_list")
	
	for _, event in ipairs(events) do
		if HUDListManager.ListOptions.show_player_actions then
			managers.gameinfo:register_listener(listener_id, src, event, clbk)
		else
			managers.gameinfo:unregister_listener(listener_id, src, event)
		end
	end
	
	for action_id, data in pairs(managers.gameinfo:get_player_actions()) do
		if HUDListManager.ListOptions.show_player_actions then
			clbk("activate", action_id, data)
		else
			list:remove_item(action_id, true)
		end
	end
end

function HUDListManager:_set_ignored_player_action(id, value)
	local list = self:list("buff_list")
	
	if HUDListManager.ListOptions.show_player_actions then
		if not value then
			local action_data = managers.gameinfo:get_player_actions(id)
			
			if action_data then
				self:_player_action_event("activate", id, action_data)
			end
		else
			list:remove_item(id, true)
		end
	end
end

--Event handlers
function HUDListManager:_timer_event(event, key, data)
	local settings = HUDListManager.TIMER_SETTINGS[data.id] or {}
	
	if not settings.ignore then
		local timer_list = self:list("left_list"):item("timers")
		
		if event == "set_active" then
			if data.active then
				local class = settings.class or (HUDList.TimerItem.DEVICE_TYPES[data.device_type] or HUDList.TimerItem.DEVICE_TYPES.default).class
				timer_list:add_item(key, class, data, settings.params):activate()
			else
				timer_list:remove_item(key)
			end
		end
	end
end

function HUDListManager:_deployable_equipment_event(event, key, data)
	if event == "set_active" then
		local equipment_list = self:list("left_list"):item("equipment")
		local level_id = managers.job:current_level_id()
		local editor_id = data.unit:editor_id()
		local item_id = key
		local type_to_option = {
			doc_bag = HUDListManager.ListOptions.show_doc_bags,
			ammo_bag = HUDListManager.ListOptions.show_ammo_bags,
			body_bag = HUDListManager.ListOptions.show_body_bags,
			grenade_crate = HUDListManager.ListOptions.show_grenade_crates,
		}
		
		if type_to_option[data.type] == 2 then
			item_id = data.type
		elseif HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id] and HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id][editor_id] then
			item_id = HUDListManager.FORCE_AGGREGATE_EQUIPMENT[level_id][editor_id]
		end
	
		if data.active then
			local class = HUDListManager.EQUIPMENT_TABLE[data.type].class
			local item = equipment_list:add_item(item_id, class, data.type)
			item:add_bag_unit(key, data)
		else
			local item = equipment_list:item(item_id)
			if item then
				item:remove_bag_unit(key, data)
			end
		end
	end
end

function HUDListManager:_sentry_equipment_event(event, key, data)
	local sentry_list = self:list("left_list"):item("sentries")
	
	if event == "set_active" then
		if data.active then
			local class = HUDListManager.EQUIPMENT_TABLE[data.type].class
			local item = sentry_list:add_item(key, class, data)
			item:set_active(HUDListManager.ListOptions.show_sentries < 2 or item:is_player_owner())
		else
			sentry_list:remove_item(key)
		end
	end
end

function HUDListManager:_minion_event(event, key, data)
	local minion_list = self:list("left_list"):item("minions")
	
	if event == "add" then
		local item = minion_list:add_item(key, HUDList.MinionItem, data)
		item:set_active(HUDListManager.ListOptions.show_minions < 2 or item:is_player_owner())
	elseif event == "remove" then
		minion_list:remove_item(key)
	end
end

function HUDListManager:_pager_event(event, key, data)
	local pager_list = self:list("left_list"):item("pagers")
	
	if event == "add" then
		pager_list:add_item(key, HUDList.PagerItem, data):activate()
	elseif event == "remove" then
		pager_list:remove_item(key)
	end
end

function HUDListManager:_ecm_event(event, key, data)
	local list = self:list("left_list"):item("ecms")
	
	if event == "set_jammer_active" then
		if data.jammer_active then
			list:add_item(key, data.is_pocket_ecm and HUDList.PocketECMItem or HUDList.ECMItem, data):activate()
		else
			list:remove_item(key)
		end
	end
end

function HUDListManager:_ecm_retrigger_event(event, key, data)
	local list = self:list("left_list"):item("ecm_retrigger")
	
	if event == "set_retrigger_active" then
		if data.retrigger_active then
			list:add_item(key, HUDList.ECMRetriggerItem, data):activate()
		else
			list:remove_item(key)
		end
	end
end

function HUDListManager:_tape_loop_event(event, key, data)
	local list = self:list("left_list"):item("tape_loop")
	
	if event == "start_tape_loop" then
		list:add_item(key, HUDList.TapeLoopItem, data):activate()
	elseif event == "stop_tape_loop" then
		list:remove_item(key)
	end
end

function HUDListManager:_buff_event(event, id, data)
	local items, is_debuff = self:_get_buff_items(id)
	local active = event == "activate" and true or false
	
	for _, item in ipairs(items) do
		item:set_buff_active(id, active, data, is_debuff)
		if active then
			item:apply_current_values(id, data)
		end
	end
end

function HUDListManager:_player_action_event(event, id, data)
	if not HUDListManager.ListOptions.ignore_player_actions[id] then
		local item_data = HUDList.PlayerActionItemBase.MAP[id]
		local activate = event == "activate" and true or false
	
		if item_data then
			local item = self:list("buff_list"):add_item(id, item_data.class or "PlayerActionItemBase", data, item_data)
			if item_data.delay then
				item:disable("delayed_enable")
			end
			if item_data.min_duration then
				item:disable("insufficient_duration")
			end
			item:set_active(activate)
		else
			printf("(%.2f) HUDListManager:_player_action_event(%s, %s): No map entry for item", Application:time(), event, id)
		end
	end
end


--Definitions/configuration
HUDListManager.TIMER_SETTINGS = {
	[132864] = {	--Meltdown vault temperature
		class = "TemperatureGaugeItem",
		params = { start = 0, goal = 50, priority = -1 },
	},
	[135076] = { ignore = true },	--Lab rats cloaker safe 2
	[135246] = { ignore = true },	--Lab rats cloaker safe 3
	[135247] = { ignore = true },	--Lab rats cloaker safe 4
	[100007] = { ignore = true },	--Cursed kill room timer
	[100888] = { ignore = true },	--Cursed kill room timer
	[100889] = { ignore = true },	--Cursed kill room timer
	[100891] = { ignore = true },	--Cursed kill room timer
	[100892] = { ignore = true },	--Cursed kill room timer
	[100878] = { ignore = true },	--Cursed kill room timer
	[100176] = { ignore = true },	--Cursed kill room timer
	[100177] = { ignore = true },	--Cursed kill room timer
	[100029] = { ignore = true },	--Cursed kill room timer
	[141821] = { ignore = true },	--Cursed kill room safe 1 timer
	[141822] = { ignore = true },	--Cursed kill room safe 1 timer
	[140321] = { ignore = true },	--Cursed kill room safe 2 timer
	[140322] = { ignore = true },	--Cursed kill room safe 2 timer
	[139821] = { ignore = true },	--Cursed kill room safe 3 timer
	[139822] = { ignore = true },	--Cursed kill room safe 3 timer
	[141321] = { ignore = true },	--Cursed kill room safe 4 timer
	[141322] = { ignore = true },	--Cursed kill room safe 4 timer
	[140821] = { ignore = true },	--Cursed kill room safe 5 timer
	[140822] = { ignore = true },	--Cursed kill room safe 5 timer
}

HUDListManager.UNIT_TYPES = {
	cop = 						{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_scared = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	cop_female = 				{ type_id = "cop",			category = "enemies",	long_name = "Cop" },
	fbi = 						{ type_id = "cop",			category = "enemies",	long_name = "FBI" },
	swat = 						{ type_id = "cop",			category = "enemies",	long_name = "SWAT" },
	heavy_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "H. SWAT" },
	fbi_swat = 					{ type_id = "cop",			category = "enemies",	long_name = "FBI SWAT" },
	fbi_heavy_swat = 			{ type_id = "cop",			category = "enemies",	long_name = "H. FBI SWAT" },
	city_swat = 				{ type_id = "cop",			category = "enemies",	long_name = "Elite" },
	heavy_swat_sniper =		{ type_id = "cop",			category = "enemies",	long_name = "H. Sniper" },
	bolivian_indoors =		{ type_id = "security",		category = "enemies",	long_name = "Sosa Security" },
	security = 					{ type_id = "security",		category = "enemies",	long_name = "Sec. guard" },
	security_undominatable ={ type_id = "security",		category = "enemies",	long_name = "Sec. guard" },
	gensec = 					{ type_id = "security",		category = "enemies",	long_name = "GenSec" },
	bolivian =					{ type_id = "thug",			category = "enemies",	long_name = "Sosa Thug" },
	gangster = 					{ type_id = "thug",			category = "enemies",	long_name = "Gangster" },
	mobster = 					{ type_id = "thug",			category = "enemies",	long_name = "Mobster" },
	biker = 						{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	biker_escape = 			{ type_id = "thug",			category = "enemies",	long_name = "Biker" },
	tank = 						{ type_id = "tank",			category = "enemies",	long_name = "Bulldozer" },
	tank_hw = 					{ type_id = "tank",			category = "enemies",	long_name = "Headless dozer" },
	tank_medic =				{ type_id = "tank_med",		category = "enemies",	long_name = "Medic dozer" },
	tank_mini =					{ type_id = "tank_min",		category = "enemies",	long_name = "Minigun dozer" },
	--tank_medic =				{ type_id = "tank",		category = "enemies",	long_name = "Medic dozer" },
	--tank_mini =					{ type_id = "tank",		category = "enemies",	long_name = "Minigun dozer" },
	spooc = 						{ type_id = "spooc",			category = "enemies",	long_name = "Cloaker" },
	taser = 						{ type_id = "taser",			category = "enemies",	long_name = "Taser" },
	shield = 					{ type_id = "shield",		category = "enemies",	long_name = "Shield" },
	sniper = 					{ type_id = "sniper",		category = "enemies",	long_name = "Sniper" },
	medic = 						{ type_id = "medic",			category = "enemies",	long_name = "Medic" },
	biker_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Biker Boss" },
	chavez_boss =				{ type_id = "thug_boss",	category = "enemies",	long_name = "Chavez" },
	drug_lord_boss =			{ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	drug_lord_boss_stealth ={ type_id = "thug_boss",	category = "enemies",	long_name = "Sosa Boss" },
	mobster_boss = 			{ type_id = "thug_boss",	category = "enemies",	long_name = "Commissar" },
	hector_boss = 				{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	hector_boss_no_armor = 	{ type_id = "thug_boss",	category = "enemies",	long_name = "Hector" },
	phalanx_vip = 				{ type_id = "phalanx",		category = "enemies",	long_name = "Cpt. Winter" },
	phalanx_minion = 			{ type_id = "phalanx",		category = "enemies",	long_name = "Phalanx" },
	civilian = 					{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
	civilian_female = 		{ type_id = "civ",			category = "civilians",	long_name = "Civilian" },
	bank_manager = 			{ type_id = "civ",			category = "civilians",	long_name = "Bank mngr." },
	--captain = 					{ type_id = "unique",		category = "civilians",	long_name = "Captain" },	--Alaska
	--drunk_pilot = 				{ type_id = "unique",		category = "civilians",	long_name = "Pilot" },	--White X-mas
	--escort = 					{ type_id = "unique",		category = "civilians",	long_name = "Escort" },	--?
	--escort_cfo = 				{ type_id = "unique",		category = "civilians",	long_name = "CFO" },	--Diamond Heist CFO
	--escort_chinese_prisoner = 	{ type_id = "unique",		category = "civilians",	long_name = "Prisoner" },	--Green Bridge
	--escort_undercover = 		{ type_id = "unique",		category = "civilians",	long_name = "Taxman" },	--Undercover
	--old_hoxton_mission = 	{ type_id = "unique",		category = "civilians",	long_name = "Hoxton" },	--Hox Breakout/BtM (Locke)
	--inside_man = 				{ type_id = "unique",		category = "civilians",	long_name = "Insider" },	--FWB
	--boris = 						{ type_id = "unique",		category = "civilians",	long_name = "Boris" },	--Goat sim
	--spa_vip = 					{ type_id = "unique",			category = "civilians",	long_name = "Charon" },	--10-10
	--spa_vip_hurt = 			{ type_id = "unique",			category = "civilians",	long_name = "Charon" },	--10-10
	
	--Custom unit definitions
	turret = 					{ type_id = "turret",		category = "turrets",	long_name = "SWAT Turret" },
	minion =						{ type_id = "minion",		category = "minions",	long_name = "Joker" },
	cop_hostage =				{ type_id = "cop_hostage",	category = "hostages",	long_name = "Dominated" },
	civ_hostage =				{ type_id = "civ_hostage",	category = "hostages",	long_name = "Hostage" },
}

HUDListManager.LOOT_TYPES = {
	ammo =						"shell",
	artifact_statue =			"artifact",
	circuit =					"server",
	cloaker_cocaine =			"coke",
	cloaker_gold =				"gold",
	cloaker_money =			"money",
	coke =						"coke",
	coke_pure =					"coke",
	counterfeit_money =		"money",
	cro_loot1 =					"bomb",
	cro_loot2 =					"bomb",
	diamond_necklace =		"jewelry",
	diamonds =					"jewelry",
	diamonds_dah =				"jewelry",
	din_pig =					"pig",
	drk_bomb_part =			"bomb",
	drone_control_helmet =	"drone_ctrl",
	evidence_bag =				"evidence",
	expensive_vine =			"wine",
	goat = 						"goat",
	gold =						"gold",
	hope_diamond =				"diamond",
	lost_artifact = 			"artifact",
	mad_master_server_value_1 =	"server",
	mad_master_server_value_2 =	"server",
	mad_master_server_value_3 =	"server",
	mad_master_server_value_4 =	"server",
	master_server = 			"server",
	masterpiece_painting =	"painting",
	meth =						"meth",
	meth_half =					"meth",
	money =						"money",
	mus_artifact =				"artifact",
	mus_artifact_paint =		"painting",
	old_wine =					"wine",
	ordinary_wine =			"wine",
	painting =					"painting",
	person =						"body",
	present = 					"present",
	prototype = 				"prototype",
	red_diamond =				"diamond",
	robot_toy =					"toy",
	safe_ovk =					"safe",
	safe_wpn =					"safe",
	samurai_suit =				"armor",
	sandwich =					"toast",
	special_person =			"body",
	toothbrush =				"toothbrush",
	turret =						"turret",
	unknown =					"dentist",
	vr_headset =				"headset",
	warhead =					"warhead",
	weapon =						"weapon",
	weapon_glock =				"weapon",
	weapon_scar =				"weapon",
	women_shoes =				"shoes",
	yayo =						"coke",
}

HUDListManager.LOOT_CONDITIONS = {
	body = function(data) 
		return (managers.job:current_level_id() == "mad") and (data.bagged or data.unit:editor_id() ~= -1)
	end,
}

HUDListManager.SPECIAL_PICKUP_TYPES = {
	gen_pku_crowbar =					"crowbar",
	pickup_keycard =					"keycard",
	pickup_hotel_room_keycard =	"keycard",	--GGC keycard
	gage_assignment =					"courier",
	pickup_boards =					"planks",
	stash_planks_pickup =			"planks",
	muriatic_acid =					"meth_ingredients",
	hydrogen_chloride =				"meth_ingredients",
	caustic_soda =						"meth_ingredients",
	press_pick_up =					"secret_item",		--Biker heist bottle
	ring_band = 						"secret_item",		--BoS rings
}

HUDListManager.BUFFS = {
	aggressive_reload_aced =				{ "aggressive_reload_aced" },
	ammo_efficiency =							{ "ammo_efficiency" },
	ammo_give_out_debuff =					{ "ammo_give_out_debuff", is_debuff = true },
	anarchist_armor_recovery_debuff =	{ "anarchist_armor_recovery_debuff", is_debuff = true },
	armor_break_invulnerable =				{ "armor_break_invulnerable" },
	armor_break_invulnerable_debuff =	{ "armor_break_invulnerable", "armor_break_invulnerable_debuff", is_debuff = true },
	armorer_armor_regen_multiplier =		{ "armorer" },
	berserker =									{ "berserker", "damage_increase", "melee_damage_increase" },
	berserker_aced =							{ "berserker", "damage_increase" },
	biker =										{ "biker" },
	bloodthirst_aced =						{ "bloodthirst_aced" },
	bloodthirst_basic =						{ "bloodthirst_basic", "melee_damage_increase" },
	bullet_storm =								{ "bullet_storm" },
	bullseye_debuff =							{ "bullseye_debuff", is_debuff = true },
	calm =										{ "calm" },
	cc_hostage_damage_reduction =			{ "crew_chief" },	--Damage reduction covered by hostage_situation
	cc_hostage_health_multiplier =		{ "crew_chief" },
	cc_hostage_stamina_multiplier =		{ "crew_chief" },
	cc_passive_armor_multiplier =			{ "crew_chief" },
	cc_passive_damage_reduction =			{ "crew_chief", "damage_reduction" },
	cc_passive_health_multiplier =		{ "crew_chief" },
	cc_passive_stamina_multiplier =		{ "crew_chief" },
	chico_injector =							{ "chico_injector" },
	chico_injector_use =						{ "chico_injector", "chico_injector_debuff", is_debuff = true },
	close_contact =							{ "close_contact", "damage_reduction" },
	combat_medic_interaction =				{ "combat_medic", "damage_reduction" },
	combat_medic_success =					{ "combat_medic", "damage_reduction" },
	damage_control_use =						{ "stoic_flask", is_debuff = true },
	desperado =									{ "desperado" },
	die_hard =									{ "die_hard", "damage_reduction" },
	dire_need =									{ "dire_need" },
	forced_friendship =						{ "forced_friendship" },
	grinder =									{ "grinder" },
	grinder_debuff = 							{ "grinder", "grinder_debuff", is_debuff = true },
	hostage_situation =						{ "hostage_situation", "damage_reduction" },
	hostage_taker =							{ "hostage_taker", "passive_health_regen" },
	inspire =									{ "inspire" },
	inspire_debuff =							{ "inspire_debuff", is_debuff = true },
	inspire_revive_debuff =					{ "inspire_revive_debuff", is_debuff = true },
	life_drain_debuff =						{ "life_drain_debuff", is_debuff = true },
	lock_n_load =								{ "lock_n_load" },
	maniac =										{ "maniac" },
	medical_supplies_debuff =				{ "medical_supplies_debuff", is_debuff = true },
	melee_stack_damage =						{ "melee_stack_damage", "melee_damage_increase" },
	messiah =									{ "messiah" },
	muscle_regen =								{ "muscle_regen", "passive_health_regen" },
	overdog =									{ "overdog", "damage_reduction" },
	overkill =									{ "overkill", "damage_increase" },
	overkill_aced =							{ "overkill", "damage_increase" },
	pain_killer =								{ "pain_killer", "damage_reduction" },
	partner_in_crime =						{ "partner_in_crime" },
	partner_in_crime_aced =					{ "partner_in_crime" },
	pocket_ecm_jammer_use =					{ "pocket_ecm_jammer_debuff", is_debuff = true },
	pocket_ecm_kill_dodge =					{ "pocket_ecm_kill_dodge" },
	quick_fix =									{ "quick_fix", "damage_reduction" },
	running_from_death_move_speed =		{ "running_from_death_aced" },
	running_from_death_reload_speed =	{ "running_from_death_basic" },
	running_from_death_swap_speed =		{ "running_from_death_basic" },
	second_wind =								{ "second_wind" },
	self_healer_debuff =						{ "self_healer_debuff", is_debuff = true },
	shock_and_awe =							{ "shock_and_awe" },
	sicario_dodge =							{ "sicario_dodge" },
	sicario_dodge_debuff =					{ "sicario_dodge", "sicario_dodge_debuff", is_debuff = true },
	sixth_sense =								{ "sixth_sense" },
	smoke_screen =								{ "smoke_screen" },
	smoke_screen_grenade_use =				{ "smoke_grenade", is_debuff = true },
	sociopath_debuff =						{ "sociopath_debuff", is_debuff = true },
	some_invulnerability_debuff =			{ "some_invulnerability_debuff", is_debuff = true },
	swan_song =									{ "swan_song" },
	swan_song_aced =							{ "swan_song" },
	tooth_and_claw =							{ "tooth_and_claw" },
	trigger_happy =							{ "trigger_happy", "damage_increase" },
	underdog =									{ "underdog", "damage_increase" },
	underdog_aced =							{ "underdog", "damage_reduction" },
	unseen_strike =							{ "unseen_strike" },
	unseen_strike_debuff =					{ "unseen_strike", "unseen_strike_debuff", is_debuff = true },
	up_you_go =									{ "up_you_go", "damage_reduction" },
	uppers =										{ "uppers" },
	uppers_debuff =							{ "uppers", "uppers_debuff", is_debuff = true },
	virtue_debuff =							{ "virtue_debuff", is_debuff = true },
	yakuza_recovery =							{ "yakuza" },
	yakuza_speed =								{ "yakuza" },
}

HUDListManager.FORCE_AGGREGATE_EQUIPMENT = {
	hox_2 = {	--Hoxton breakout
		[136859] = "armory_grenade",
		[136870] = "armory_grenade",
		[136869] = "armory_grenade",
		[136864] = "armory_grenade",
		[136866] = "armory_grenade",
		[136860] = "armory_grenade",
		[136867] = "armory_grenade",
		[136865] = "armory_grenade",
		[136868] = "armory_grenade",
		[136846] = "armory_ammo",
		[136844] = "armory_ammo",
		[136845] = "armory_ammo",
		[136847] = "armory_ammo",
		[101470] = "infirmary_cabinet",
		[101472] = "infirmary_cabinet",
		[101473] = "infirmary_cabinet",
	},
	kenaz = {	--GGC
		[151596] = "armory_grenade",
		[151597] = "armory_grenade",
		[151598] = "armory_grenade",
		[151611] = "armory_ammo",
		[151612] = "armory_ammo",
	},
	born = {		--Biker heist
		[100776] = "bunker_grenade",
		[101226] = "bunker_grenade",
		[101469] = "bunker_grenade",
		[101472] = "bunker_ammo",
		[101473] = "bunker_ammo",
	},
	spa = {	--10-10
		[132935] = "armory_ammo",
		[132938] = "armory_ammo",
		[133085] = "armory_ammo",
		[133088] = "armory_ammo",
		[133835] = "armory_ammo",
		[133838] = "armory_ammo",
		[134135] = "armory_ammo",
		[134138] = "armory_ammo",
		[137885] = "armory_ammo",
		[137888] = "armory_ammo",
	},
}

HUDListManager.EQUIPMENT_TABLE = {
	sentry =				{ skills = { 7, 5 },			class = "SentryEquipmentItem",	priority = 1 },
	grenade_crate =	{ preplanning = { 1, 0 },	class = "BagEquipmentItem",		priority = 2 },
	ammo_bag =			{ skills = { 1, 0 },			class = "AmmoBagItem",				priority = 3 },
	doc_bag =			{ skills = { 2, 7 },			class = "BagEquipmentItem",		priority = 4 },
	body_bag =			{ skills = { 5, 11 },		class = "BodyBagItem",				priority = 5 },
}
