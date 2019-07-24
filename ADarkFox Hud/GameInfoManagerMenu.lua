local main_menu_id = "gameinfomanager_options_menu"
local file_name = ModPath .. "plugin_settings.json"

local function save_settings()
	local file = io.open(file_name, "w+")
	if file then
		file:write(json.encode(GameInfoManager._PLUGIN_SETTINGS))
		file:close()
	end
end

local function load_settings()
	local file = io.open(file_name, "r")
	if file then
		GameInfoManager._PLUGIN_SETTINGS = json.decode(file:read("*all"))
		file:close()
	end
end


--Populate options menus
Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenus_GameInfoManager", function(menu_manager, nodes)
	MenuHelper:NewMenu(main_menu_id)
	
	for id, data in pairs(GameInfoManager._PLUGINS_LOADED) do
		local clbk_id = id .. "_clbk"
	
		MenuHelper:AddToggle({
			id = "gameinfomanager_plugin_" .. id,
			title = "gameinfomanager_plugin_" .. id .. "_title",
			desc = "gameinfomanager_plugin_" .. id .. "_desc",
			callback = clbk_id,
			value = GameInfoManager._PLUGIN_SETTINGS[id] and true or false,
			menu_id = main_menu_id,
		})
		
		MenuCallbackHandler[clbk_id] = function(self, item)
			GameInfoManager._PLUGIN_SETTINGS[id] = item:value() == "on"
		end
	end
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_GameInfoManager", function(menu_manager, nodes)
	local back_clbk = "hudlist_back_clbk"
	
	MenuCallbackHandler[back_clbk] = function(self, item)
		save_settings()
	end
	
	if nodes.blt_options then
		nodes[main_menu_id] = MenuHelper:BuildMenu(main_menu_id, { back_callback = back_clbk })
		MenuHelper:AddMenuItem(nodes.blt_options, main_menu_id, main_menu_id .. "_title", main_menu_id .. "_desc" )
	end
end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_GameInfoManager_localization", function(self)
	local strings = {
		gameinfomanager_options_menu_title = "GameInfoManager Plugins",
		gameinfomanager_options_menu_desc = "Enable/disable available plugins (may require restarting to apply)",
	}
	
	for id, data in pairs(GameInfoManager._PLUGINS_LOADED) do
		strings["gameinfomanager_plugin_" .. id .. "_title"] = data.title
		strings["gameinfomanager_plugin_" .. id .. "_desc"] = data.desc
	end
	
	self:add_localized_strings(strings)
end)

load_settings()
