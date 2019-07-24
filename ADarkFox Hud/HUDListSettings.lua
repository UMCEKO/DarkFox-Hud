--Default settings for HUDList
HUDListManager.ListOptions = HUDListManager.ListOptions or {
	--General settings
	right_list_y = 0,	--Margin from top for the right list
	right_list_scale = 1,	--Size scale of right list
	left_list_y = 40,	--Margin from top for the left list
	left_list_scale = 1,	--Size scale of left list
	buff_list_y = 80,	--Margin from bottom for the buff list
	buff_list_scale = 1,	--Size scale of buff list

	--Left side list
	show_timers = true,	--Drills, time locks, hacking etc.
	show_ammo_bags = 2,	--Show ammo bags/shelves and remaining amount
	show_doc_bags = 2,	--Show doc bags/cabinets and remaining charges
	show_body_bags = 2,	--Show body bags and remaining amount. Auto-disabled if heist goes loud
	show_grenade_crates = 2,	--Show grenade crates with remaining amount
	show_sentries = 2,	--Deployable sentries, color-coded by owner
	show_ecms = true,	--Active ECMs with time remaining
	show_ecm_retrigger = true,	--Countdown for player owned ECM feedback retrigger delay
	show_minions = 2,	--Converted enemies, type and health
	show_pagers = true,	--Show currently active pagers
	show_tape_loop = true,	--Show active tape loop duration

	--Right side list
	show_enemies = 1,		--Currently spawned enemies
	show_turrets = true,	--Show active SWAT turrets
	show_civilians = true,	--Currently spawned, untied civs
	show_hostages = 1,	--Currently tied civilian and dominated cops
	show_minion_count = true,	--Current number of jokered enemies
	show_pager_count = true,	--Show number of triggered pagers (only counts pagers triggered while you were present). Auto-disabled if heist goes loud
	show_camera_count = true,	--Show number of active cameras on the map. Auto-disabled if heist goes loud (experimental, has some issues)
	show_body_count = true,		--Show number of corpses/body bags on map. Auto-disabled if heist goes loud
	show_loot = 1,	--Show spawned and active loot bags/piles (may not be shown if certain mission parameters has not been met)
		separate_bagged_loot = true,	 --Show bagged/unbagged loot as separate values
	show_special_pickups = true,	--Show number of special equipment/items
		ignore_special_pickups = {	--Exclude specific special pickups from showing
			crowbar = false,
			keycard = false,
			courier = false,
			planks = false,
			meth_ingredients = false,
			secret_item = false,	--Biker heist bottle / BoS rings
		},
	
	--Buff list
	show_buffs = true,	--Show active effects (buffs/debuffs)
		ignore_buffs = {	--Exclude specific effects from showing
			aggressive_reload_aced = true,
			ammo_efficiency = true,
			armor_break_invulnerable = true,
			berserker = true,
			biker = true,
			bloodthirst_aced = true,
			bloodthirst_basic = true,	--true,
			bullet_storm = true,
			chico_injector = true,
			close_contact = true,
			combat_medic = true,	--true,
			desperado = true,
			die_hard = true,
			dire_need = true,
			grinder = true,
			hostage_situation = true,	--true,
			hostage_taker = true,
			inspire = true,
			lock_n_load = true,
			maniac = true,	--true,
			melee_stack_damage = true,
			messiah = true,
			muscle_regen = true,
			overdog = true,
			overkill = true,
			pain_killer = true,	--true,
			partner_in_crime = true,
			quick_fix = true,	--true,
			running_from_death = true,
			running_from_death_aced = true,
			second_wind = true,
			sicario_dodge = true,
			sixth_sense = true,
			smoke_screen = true,
			swan_song = true,
			tooth_and_claw = true,	--Also integrated into armor regen
			trigger_happy = true,
			underdog = true,
			unseen_strike = true,
			uppers = true,
			up_you_go = true,	--true,
			yakuza = true,
			
			ammo_give_out_debuff = true,
			anarchist_armor_recovery_debuff = true,
			armor_break_invulnerable_debuff = true,	--Composite
			bullseye_debuff = true,
			chico_injector_debuff = true,	--Composite
			grinder_debuff = true,	--Composite
			inspire_debuff = true,
			inspire_revive_debuff = true,
			life_drain_debuff = true,
			medical_supplies_debuff = true,
			self_healer_debuff = true,
			sicario_dodge = true,	--Composite
			smoke_grenade = true,
			sociopath_debuff = true,
			some_invulnerability_debuff = true,
			unseen_strike_debuff = true,	--Composite
			uppers_debuff = true,	--Composite
			
			armorer = true,
			crew_chief = true,
			forced_friendship = true,
			shock_and_awe = true,
		
			damage_increase = true,
			damage_reduction = true,
			melee_damage_increase = true,
			passive_health_regen = true,
		},
	show_player_actions = true,	--Show active player actions (armor regen, interactions, weapon charge, reload etc.)
		ignore_player_actions = {	--Exclude specific effects from showing
			anarchist_armor_regeneration = false,
			standard_armor_regeneration = false,
			melee_charge = false,
			weapon_charge = false,
			reload = false,
			interact = false,
		},
}

function HUDListManager.change_setting(setting, value)
	if HUDListManager.ListOptions[setting] ~= value then
		HUDListManager.ListOptions[setting] = value
		
		local clbk = "_set_" .. setting
		if HUDListManager[clbk] and managers.hudlist then
			managers.hudlist[clbk](managers.hudlist)
			return true
		end
	end
end

function HUDListManager.change_ignore_buff_setting(buff, value)
	if HUDListManager.ListOptions.ignore_buffs[buff] ~= value then
		HUDListManager.ListOptions.ignore_buffs[buff] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_buff(buff, value)
		end
	end
end

function HUDListManager.change_ignore_player_action_setting(action, value)
	if HUDListManager.ListOptions.ignore_player_actions[action] ~= value then
		HUDListManager.ListOptions.ignore_player_actions[action] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_player_action(action, value)
		end
	end
end

function HUDListManager.change_ignore_special_pickup_setting(pickup, value)
	if HUDListManager.ListOptions.ignore_special_pickups[pickup] ~= value then
		HUDListManager.ListOptions.ignore_special_pickups[pickup] = value
		
		if managers.hudlist then
			managers.hudlist:_set_ignored_special_pickup(pickup, value)
		end
	end
end
