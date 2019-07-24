local plugin = "loot"

if not GameInfoManager.has_plugin(plugin) then
	GameInfoManager.add_plugin(plugin, { title = "Loot", desc = "Handles loot-related events, e.g. counting and loot unit tracking" }, "init_loot_plugin")
end

if not GameInfoManager.plugin_active(plugin) then
	return
end

if RequiredScript == "lib/setups/setup" then

	GameInfoManager._LOOT = {
		interaction_to_carry = {
			weapon_case =				"weapon",
			weapon_case_axis_z =		"weapon",
			samurai_armor =			"samurai_suit",
			gen_pku_warhead_box =	"warhead",
			corpse_dispose =			"person",
			hold_open_case =			"drone_control_helmet",	--May be reused in future heists for other loot
		},
		bagged_ids = {
			painting_carry_drop = true,
			carry_drop = true,
			safe_carry_drop = true,
			goat_carry_drop = true,
		},
		composite_loot_units = {
			gen_pku_warhead_box = 2,	--[132925] = 2, [132926] = 2, [132927] = 2,	--Meltdown warhead cases
			--hold_open_bomb_case = 4,	--The Bomb heists cases, extra cases on docks screws with counter...
			[103428] = 4, [103429] = 3, [103430] = 2, [103431] = 1,	--Shadow Raid armor
			--[102913] = 1, [102915] = 1, [102916] = 1,	--Train Heist turret (unit fixed, need workaround)
			[105025] = 10, [105026] = 9, [104515] = 8, [104518] = 7, [104517] = 6, [104522] = 5, [104521] = 4, [104520] = 3, [104519] = 2, [104523] = 1, --Slaughterhouse alt 1.
			[105027] = 10, [105028] = 9, [104525] = 8, [104524] = 7, [104490] = 6, [100779] = 5, [100778] = 4, [100777] = 3, [100773] = 2, [100771] = 1, --Slaughterhouse alt 2.
		},
		conditional_ignore_ids = {
			ff3_vault = function(wall_id)
				if managers.job:current_level_id() == "framing_frame_3" then
					for _, unit in pairs(World:find_units_quick("all", 1)) do
						if unit:editor_id() == wall_id then
							return true
						end
					end
				end
			end,

			--FF3 lounge vault
			[100548] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100549] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100550] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100551] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100552] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100553] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100554] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			[100555] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(100448) end,
			--FF3 bedroom vault
			[100556] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100557] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100558] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100559] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100560] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100561] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100562] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			[100563] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101431) end,
			--FF3 upstairs vault
			[100564] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100566] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100567] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100568] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100569] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100570] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100571] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
			[100572] = function() return GameInfoManager._LOOT.conditional_ignore_ids.ff3_vault(101423) end,
		},
		ignore_ids = {
			watchdogs_2 = {	--Watchdogs day 2 (8x coke)
				[100054] = true, [100058] = true, [100426] = true, [100427] = true, [100428] = true, [100429] = true, [100491] = true, [100492] = true, [100494] = true, [100495] = true,
			},
			family = {	--Diamond store (1x money)
				[100899] = true,
			},	--Hotline Miami day 1 (1x money)
			mia_1 = {	--Hotline Miami day 1 (1x money)
				[104526] = true,
			},
			welcome_to_the_jungle_1 = {	--Big Oil day 1 (1x money, 1x gold)
				[100886] = true, [100872] = true,
			},
			mus = {	--The Diamond (RNG)
				[300047] = true, [300686] = true, [300457] = true, [300458] = true, [301343] = true, [301346] = true,
			},
			arm_und = {	--Transport: Underpass (8x money)
				[101237] = true, [101238] = true, [101239] = true, [103835] = true, [103836] = true, [103837] = true, [103838] = true, [101240] = true,
			},
			ukrainian_job = {	--Ukrainian Job (3x money)
				[101514] = true, [102052] = true, [102402] = true,
			},
			jewelry_store = {	--Jewelry Store (2x money)
				[102052] = true, [102402] = true,
			},
			fish = {	--Yacht (1x artifact painting)
				[500533] = true,
			},
			chill_combat = {	--Safe House Raid (1x artifact painting, 1x toothbrush)
				[150416] = true, [102691] = true,
			},
			tag = {	--Breakin' Feds (1x evidence)
				[134563] = true,
			},
			sah = { --Shacklethorne Auction (2x artifact)
				[400791] = true, [400792] = true,
			}
		},
	}
	GameInfoManager._LOOT.ignore_ids.watchdogs_2_day = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.watchdogs_2)
	GameInfoManager._LOOT.ignore_ids.welcome_to_the_jungle_1_night = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.welcome_to_the_jungle_1)
	GameInfoManager._LOOT.ignore_ids.chill = table.deep_map_copy(GameInfoManager._LOOT.ignore_ids.chill_combat)
	
	function GameInfoManager:init_loot_plugin()
		self._loot = self._loot or {}
	end
	
	function GameInfoManager:get_loot(key)
		if key then
			return self._loot[key]
		else
			return self._loot
		end
	end
	
	function GameInfoManager:_loot_interaction_handler(event, key, data)
		if event == "add" then
			if not self._loot[key] then
				local composite_lookup = GameInfoManager._LOOT.composite_loot_units
				local count = composite_lookup[data.editor_id] or composite_lookup[data.interact_id] or 1
				local bagged = GameInfoManager._LOOT.bagged_ids[data.interact_id] and true or false
			
				self._loot[key] = { unit = data.unit, carry_id = data.carry_id, count = count, bagged = bagged }
				self:_listener_callback("loot", "add", key, self._loot[key])
				self:_loot_count_event("change", key, self._loot[key].count)
			end
		elseif event == "remove" then
			if self._loot[key] then
				self:_listener_callback("loot", "remove", key, self._loot[key])
				self:_loot_count_event("change", key, -self._loot[key].count)
				self._loot[key] = nil
			end
		end
	end
	
	function GameInfoManager:_loot_count_event(event, key, value)
		if event == "change" then
			if value ~= 0 then
				self:_listener_callback("loot_count", "change", self._loot[key].carry_id, self._loot[key], value)
			end
		end
	end
	
	local _interactive_unit_event_original = GameInfoManager._interactive_unit_event
	
	function GameInfoManager:_interactive_unit_event(event, key, data)
		local lookup = GameInfoManager._LOOT
		local carry_id = data.unit:carry_data() and data.unit:carry_data():carry_id() or 
			lookup.interaction_to_carry[data.interact_id] or 
			(self._loot[key] and self._loot[key].carry_id)
		
		if carry_id then
			local level_id = managers.job:current_level_id()
			
			if not (lookup.ignore_ids[level_id] and lookup.ignore_ids[level_id][data.editor_id]) and not (lookup.conditional_ignore_ids[data.editor_id] and lookup.conditional_ignore_ids[data.editor_id]()) then
				data.carry_id = carry_id
				self:_loot_interaction_handler(event, key, data)
			end
		end
		
		return _interactive_unit_event_original(self, event, key, data)
	end
	
end
