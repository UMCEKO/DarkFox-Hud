local main_menu_id = "hudlist_menu_main"
local localization_file = ModPath .. "localization/menu.json"
local settings_file = ModPath .. "saved_settings.json"

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_HUDList", function(menu_manager, nodes)
	if not GameInfoManager then return end
	
	local function change_setting(setting, value, setting_type)
		HUDListMenu.setting_changed = true
		
		if setting_type == "ignore_buff" then
			HUDListManager.change_ignore_buff_setting(setting, not value)
		elseif setting_type == "ignore_player_action" then
			HUDListManager.change_ignore_player_action_setting(setting, not value)
		elseif setting_type == "ignore_special_pickup" then
			HUDListManager.change_ignore_special_pickup_setting(setting, not value)
		else
			HUDListManager.change_setting(setting, value)
		end
	end
	
	local function initialize_menu(menu_id, data)
		MenuHelper:NewMenu(menu_id)
		
		for i, item in ipairs(data) do
			local id = item[1]
			local item_type = item[2]
			local item_data = item[3]
			local setting_type = item_data.setting_type
			local clbk_id = "hudlist_menu_" .. id .. "_clbk"
			local title = "hudlist_menu_" .. id .. "_title"
			local desc = "hudlist_menu_" .. id .. "_desc"
			
			local plugin_requirement = item_data.req_plugin
			local default = HUDListManager.ListOptions[id]
			if item_data.default then
				default = item_data.default[1]
			end
			
			if item_type == "toggle" then
				MenuHelper:AddToggle({ id = id, title = title, desc = desc, callback = clbk_id, menu_id = menu_id, priority = -i, value = default and true or false })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					change_setting(id, item:value() == "on", setting_type)
				end
			elseif item_type == "slider" then
				MenuHelper:AddSlider({ id = id, title = title, desc = desc, callback = clbk_id, min = item_data.min, max = item_data.max, step = item_data.step, show_value = true, menu_id = menu_id, priority = -i, value = default or 0 })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					if item_data.round then item:set_value(math.round(item:value())) end
					change_setting(id, item:value(), setting_type)
				end
			elseif item_type == "multichoice" then
				MenuHelper:AddMultipleChoice({ id = id, title = title, desc = desc, callback = clbk_id, items = item_data.items, menu_id = menu_id, priority = -i, value = (default or 0) + 1 })
				
				MenuCallbackHandler[clbk_id] = function(self, item)
					change_setting(id, item:value() - 1, setting_type)
				end
			elseif item_type == "divider" then
				MenuHelper:AddDivider({ id = id, size = item_data.size, menu_id = menu_id, priority = -i })
			end
			
			if plugin_requirement then
				local enabled_clbk = "hudlist_menu_" .. id .. "_enabled_clbk"
				
				MenuCallbackHandler[enabled_clbk] = function(self, item)
					return GameInfoManager.plugin_active(plugin_requirement)
				end
				
				local menu = MenuHelper:GetMenu(menu_id)
				for i, item in pairs(menu._items_list) do
					if item:parameters().name == id then
						item._enabled_callback_name_list = { enabled_clbk }
						break
					end
				end
			end
		end
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			initialize_menu(sub_menu_id, sub_menu_data)
		end
	end
	
	local function finalize_menu(menu_id, data, parent, back_clbk)
		nodes[menu_id] = MenuHelper:BuildMenu(menu_id, { back_callback = back_clbk })
		MenuHelper:AddMenuItem(nodes[parent], menu_id, menu_id .. "_title", menu_id .. "_desc")
		
		for sub_menu_id, sub_menu_data in pairs(data.sub_menus or {}) do
			finalize_menu(sub_menu_id, sub_menu_data, menu_id, back_clbk)
		end
	end
	
	--Menu structure
	local main_menu = {
		sub_menus = {
			hudlist_menu_left_list_options = {
				{ "left_list_y", "slider", { min = 0, max = 1000, step = 1, round = true } },
				{ "left_list_scale", "slider", { min = 0.5, max = 2, step = 0.05 } },
				{ "divider", "divider", { size = 12 } },
				{ "show_ammo_bags", "multichoice", { req_plugin = "deployables", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_doc_bags", "multichoice", { req_plugin = "deployables", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_body_bags", "multichoice", { req_plugin = "deployables", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_grenade_crates", "multichoice", { req_plugin = "deployables", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_sentries", "multichoice", { req_plugin = "sentries", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_player_only" } } },
				{ "show_minions", "multichoice", { req_plugin = "units", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_player_only" } } },
				{ "show_timers", "toggle", { req_plugin = "timers" } },
				{ "show_ecms", "toggle", { req_plugin = "ecms" } },
				{ "show_ecm_retrigger", "toggle", { req_plugin = "ecms" } },
				{ "show_pagers", "toggle", { req_plugin = "pagers" } },
				{ "show_tape_loop", "toggle", { req_plugin = "cameras" } },
				sub_menus = {},
			},
			hudlist_menu_right_list_options = {
				{ "right_list_y", "slider", { min = 0, max = 1000, step = 1, round = true } },
				{ "right_list_scale", "slider", {  min = 0.5, max = 2, step = 0.05 } },
				{ "divider", "divider", { size = 12 } },
				{ "show_loot", "multichoice", { req_plugin = "loot", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "separate_bagged_loot", "toggle", { req_plugin = "loot" } },
				{ "show_enemies", "multichoice", { req_plugin = "units", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_hostages", "multichoice", { req_plugin = "units", items = { "hudlist_menu_option_off", "hudlist_menu_option_all", "hudlist_menu_option_aggregate" } } },
				{ "show_civilians", "toggle", { req_plugin = "units" } },
				{ "show_turrets", "toggle", { req_plugin = "units" } },
				{ "show_minion_count", "toggle", { req_plugin = "units" } },
				{ "show_pager_count", "toggle", { req_plugin = "pagers" } },
				{ "show_camera_count", "toggle", { req_plugin = "cameras" } },
				{ "show_body_count", "toggle", { req_plugin = "loot" } },
				{ "show_special_pickups", "toggle", { req_plugin = "pickups" } },
				{ "divider", "divider", { size = 12 } },
				sub_menus = {},	--hudlist_menu_ignore_special_pickups_options
			},
			hudlist_menu_buff_list_options = {
				{ "buff_list_y", "slider", { min = 0, max = 1000, step = 1, round = true } },
				{ "buff_list_scale", "slider", { min = 0.5, max = 2, step = 0.05 } },
				{ "show_buffs", "toggle", { req_plugin = "buffs" } },
				{ "show_player_actions", "toggle", { req_plugin = "player_actions" } },
				sub_menus = {},	--hudlist_menu_ignore_buffs_options / hudlist_menu_ignore_player_actions_options
			},
		},
	}
	
	--Add pickup items
	if GameInfoManager.plugin_active("pickups") then
		local data = {}
		for id, _ in pairs(HUDList.SpecialPickupItem.MAP) do
			table.insert(data, { id, "toggle", { setting_type = "ignore_special_pickup", default = { not HUDListManager.ListOptions.ignore_special_pickups[id] } } })
		end
		
		main_menu.sub_menus.hudlist_menu_right_list_options.sub_menus.hudlist_menu_ignore_special_pickups_options = data
	end
	
	--Add buffs
	if GameInfoManager.plugin_active("buffs") then
		local menu_structure = { sub_menus = {} }
	
		for id, map_entry in pairs(HUDList.BuffItemBase.MAP) do
			local tmp_tbl = menu_structure
			
			for _, sub_menu in ipairs(map_entry.menu_data.grouping) do
				local menu_id = "hudlist_menu_" .. sub_menu .. "_options"
				tmp_tbl.sub_menus[menu_id] = tmp_tbl.sub_menus[menu_id] or { sub_menus = {} }
				tmp_tbl = tmp_tbl.sub_menus[menu_id]
			end
			
			local function sort_func(a, b)
				local key_a = a[3].sort_key or a[1]
				local key_b = b[3].sort_key or b[1]
				return key_a < key_b
			end
			
			table.insert_sorted(
				tmp_tbl,
				{ id, "toggle", { setting_type = "ignore_buff", default = { not HUDListManager.ListOptions.ignore_buffs[id] }, sort_key = map_entry.menu_data.sort_key } },
				sort_func
			)
		end
		
		main_menu.sub_menus.hudlist_menu_buff_list_options.sub_menus.hudlist_menu_ignore_buffs_options = menu_structure
	end
	
	--Add player actions
	if GameInfoManager.plugin_active("player_actions") then
		local data = {}
		for id, _ in pairs(HUDList.PlayerActionItemBase.MAP) do
			table.insert(data, { id, "toggle", { setting_type = "ignore_player_action", default = { not HUDListManager.ListOptions.ignore_player_actions[id] } } })
		end
		
		main_menu.sub_menus.hudlist_menu_buff_list_options.sub_menus.hudlist_menu_ignore_player_actions_options = data
	end
	
	
	local back_clbk = "hudlist_menu_back_clbk"
	MenuCallbackHandler[back_clbk] = function(self, item)
		HUDListMenu.save_settings()
	end
	
	if nodes.blt_options then
		initialize_menu(main_menu_id, main_menu)
		finalize_menu(main_menu_id, main_menu, "blt_options", back_clbk)
	end
end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_HUDList_localization", function(self)
	LocalizationManager:load_localization_file(localization_file)
end)

HUDListMenu = {
	save_settings = function()
		if HUDListMenu.setting_changed then
			local file = io.open(settings_file, "w+")
			if file then
				HUDListMenu.setting_changed = false
				file:write(json.encode(HUDListManager.ListOptions))
				file:close()
			end
		end
	end,
	
	load_settings = function()
		local file = io.open(settings_file, "r")
		if file then
			HUDListManager.ListOptions = json.decode(file:read("*all"))
			file:close()
		else
			HUDListMenu.save_settings()
		end
	end,
}

HUDListMenu.load_settings()
