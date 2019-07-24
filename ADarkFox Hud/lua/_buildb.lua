_G.BuilDB = _G.BuilDB or {}
BuilDB._path = ModPath
BuilDB._db_path = SavePath .. "buildb_builds.txt"
BuilDB._data_path = SavePath .. "buildb_settings.txt"
BuilDB._import_menu_id = "buildb_import"
BuilDB._data = {}
BuilDB._tree_tags = { "m", "e", "t", "g", "f" }
BuilDB._perk_tags = {
	"C", -- Crew chief
	"M", -- Muscle
	"A", -- Armorer
	"R", -- Rogue
	"H", -- Hitman
	"O", -- crOok
	"B", -- Burglar
	"I", -- Infiltrator
	"S", -- Sociopath
	"G", -- Gambler
	"N", -- griNder
	"Y", -- Yakuza
	"E", -- Ex-president
	"1", -- ? maniac
	"T", -- ? anarchisT
	"K", -- ? biKer
	"P", -- ? kingPin
	"2", -- ? sicario
	"3", -- ? stoic
	"4", -- ? tagteam
}
BuilDB.settings = {
	base_url = "http://pd2skills.com/#/v3/",
	text_editor = '%windir%\\system32\\notepad.exe',
}

function BuilDB:GetUrlFromSkills()
	local packed_trees = {}
	for tree, data in ipairs(tweak_data.skilltree.trees) do
		packed_trees[tree] = self:GetUrlPartFromSkillTree(tree)
	end

	local packed_string = self.settings.base_url
	for i = 0, 4 do
		local threetree = ""
		for j = 1, 3 do
			threetree = threetree .. packed_trees[i * 3 + j]
		end
		if threetree ~= "" then
			packed_string = packed_string .. self._tree_tags[i + 1] .. threetree .. ":"
		end
	end

	if managers.infamy:owned("infamy_root") then
		local b = managers.infamy:owned("infamy_mastermind") and "b" or ""
		local c = managers.infamy:owned("infamy_enforcer") and "c" or ""
		local d = managers.infamy:owned("infamy_technician") and "d" or ""
		local e = managers.infamy:owned("infamy_ghost") and "e" or ""
		packed_string = packed_string .. "i" .. b .. c .. d .. e .. "a:"
	end

	local current_specialization = managers.skilltree:digest_value(Global.skilltree_manager.specializations.current_specialization, false, 1)	
	local tree_data = Global.skilltree_manager.specializations[current_specialization]
	if tree_data and current_specialization <= #self._perk_tags then
		local tier_data = tree_data.tiers
		if tier_data then
			local current_tier = managers.skilltree:digest_value(tier_data.current_tier, false)			
			packed_string = packed_string .. "p" .. self._perk_tags[current_specialization] .. tostring(current_tier - 1) .. ":"
		end
	end

	local level = managers.experience:current_level()
	if level < 100 then
		packed_string = packed_string .. "::l" .. tostring(level)
	end

	return packed_string .. "::"
end

function BuilDB:GetUrlPartFromSkillTree(tree, switch_data)
	local itoc = {5, 3, 4, 1, 2, 0}
	local basecharvals = {97, 103, 109}
	local basecharval = basecharvals[(tree - 1) % 3 + 1]
	local result = ""
	local td = tweak_data.skilltree.trees[tree]

	local i = 0
	for _, tier in ipairs(td.tiers) do
		for _, skill_id in ipairs(tier) do
			i = i + 1
			local step = managers.skilltree:skill_step(skill_id)
			if step > 0 then
				local cv = basecharval + itoc[i]
				if step > 1 then
					cv = cv - 32
				end
				result = result .. string.char(cv)
			end
		end
	end
	return result
end

function BuilDB:CheckDB()
	if not io.file_is_readable(self._db_path) then
		local fh = io.open(self._db_path, "w")
		if not fh then
			return false
		end
		fh:write(string.char(239, 187, 191))
		fh:write("# Keep the UTF-8 encoding of this file or some characters may not appear correctly in the game.\n")
		fh:write("# Only the lines matching the format \"URL + 1 tabulation + build description\" will be listed in the import menu.\n\n")
		fh:write("http://pd2skills.com/#/v3/mACEf:eGHjKl:tlr:gjl:ibcdea:::	Example\n")
		fh:write("You can describe your build more precisely without interfering with the menu.\n")
		fh:write("Only the first 2 lines following a build link are displayed (above the list).\n")
		fh:write("So this line won't appear.\n")
		fh:close()
	end
	return true
end

function BuilDB:LoadDB()
	self.builds = {}
	if self:CheckDB() then
		local ldesc = {}
		for line in io.lines(self._db_path) do
			local url, title = line:match('^(http://.*)	(.*)$')
			if url then
				if #ldesc > 0 and #self.builds > 0 then
					self.builds[#self.builds].desc = table.concat(ldesc, "\n")
				end
				ldesc = {}
				table.insert(self.builds, { url = url, title = title, desc = "" })
			else
				if #ldesc < 2 then
					table.insert(ldesc, line)
				end
			end
		end
		if #ldesc > 0 and #self.builds > 0 then
			self.builds[#self.builds].desc = table.concat(ldesc, "\n")
		end
	end
end

function BuilDB:LookAtBuild()
	local build = BuilDB.builds[BuilDB._build_id_to_import]
	Steam:overlay_activate("url", build.url)
end

MenuCallbackHandler.BuilDBHandleHub = function(this, item)
	BuilDB._build_id_to_import = 10000 - item._priority
	local title = managers.localization:text("dialog_skills_respec_title")
	local message = managers.localization:text("buildb_dialog_import_message")
	local menu_options = {
		[1] = {
			text = managers.localization:text("dialog_apply"),
			callback = BuilDB.ImportClbk,
		},
		[2] = {
			text = managers.localization:text("buildb_dialog_import_btn_preview"),
			callback = BuilDB.LookAtBuild,
		},
		[3] = {
			text = managers.localization:text("dialog_cancel"),
			is_cancel_button = true,
		},
	}
	QuickMenu:new(title, message, menu_options, true)
end

function BuilDB:GenerateMenu(node)
	self:LoadDB()

	for i, build in ipairs(self.builds) do
		local params = {
			name = "button_buildb_import-" .. tostring(i),
			text_id = build.title,
			callback = "BuilDBHandleHub",
			to_upper = false,
			help_id = build.desc,
			localize = false,
			localize_help = false
		}
		local new_item = node:create_item(nil, params)
		new_item._priority = 10000 - i
		node:add_item(new_item)
	end
end

BuilDBCreator = BuilDBCreator or class()
function BuilDBCreator.modify_node(node)
	node:clean_items()
	BuilDB:GenerateMenu(node)
	managers.menu:add_back_button(node)
	return node
end

function BuilDB:ShowMenu()
	managers.menu:open_node(self._import_menu_id, {})
	managers.menu:active_menu().renderer.ws:show()
end

function BuilDB:ImportClbk()
	managers.menu:back(true)
	local build = BuilDB.builds[BuilDB._build_id_to_import]
	log("[BuilDB] Old build: " .. BuilDB:GetUrlFromSkills())
	log("[BuilDB] New build: " .. build.url)
	local ok, tip = BuilDB:Import(build.url)
	if not ok then
		local title = managers.localization:text("dialog_error_title")
		local message = string.format("%s (%s)", managers.localization:text("error"), tip)
		QuickMenu:new(title, message, {}, true)
	end
end

function BuilDB:ParseUrl(url)
	local result = {
		skills = {},
		others = {},
	}

	local params = url:match('http://.*#/v[0-9]+/(.*)$')
	if not params or params == "" then
		return
	end

	local params1, params2 = params:match('^(.*):?:?(.*)$')
	for _, s in pairs(params1:split(":")) do
		result.skills[s:sub(1, 1)] = s:sub(2) or ""
	end
	for _, s in pairs(params2:split(":")) do
		result.others[s:sub(1, 1)] = s:sub(2) or ""
	end

	return result
end

function BuilDB:Import(url)
	local params = self:ParseUrl(url)
	if not params then
		return false, "parsing url"
	end

	if params.skills.i then
		if managers.infamy:owned("infamy_root")       and not params.skills.i:find('a') then return false, "infamy" end
		if managers.infamy:owned("infamy_mastermind") and not params.skills.i:find('b') then return false, "infamy" end
		if managers.infamy:owned("infamy_enforcer")   and not params.skills.i:find('c') then return false, "infamy" end
		if managers.infamy:owned("infamy_technician") and not params.skills.i:find('d') then return false, "infamy" end
		if managers.infamy:owned("infamy_ghost")      and not params.skills.i:find('e') then return false, "infamy" end
	end

	local level = managers.experience:current_level()
	if params.skills.l and level < tonumber(params.skills.l) then
		return false, "level"
	end

	if params.skills.p then
		local perk_tag = params.skills.p:match('([A-Z])')
		for perk_id, tag in ipairs(self._perk_tags) do
			if perk_tag == tag then
				managers.skilltree:set_current_specialization(perk_id)
				break
			end
		end
	end

	for tree, tree_data in ipairs(tweak_data.skilltree.trees) do
		local points_spent = managers.skilltree:points_spent(tree)
		managers.skilltree:_set_points_spent(tree, 0)
		for i = #tree_data.tiers, 1, -1 do
			local tier = tree_data.tiers[i]
			for _, skill in ipairs(tier) do
				managers.skilltree:_unaquire_skill(skill)
			end
		end
		managers.skilltree:_aquire_points(points_spent, true)
	end

	local function _invest(tree, skill_id, tier, step)
		if managers.skilltree:has_enough_skill_points(skill_id) and managers.skilltree:unlock(skill_id) then
			local points = managers.skilltree:skill_cost(tier, step)
			local skill_points = managers.skilltree:spend_points(points)
			managers.menu_component._skilltree_gui:set_skill_point_text(skill_points)
			managers.skilltree:_set_points_spent(tree, managers.skilltree:points_spent(tree) + points)
			return true
		else
			return false
		end
	end

	local numtotier = {4, 3, 3, 2, 2, 1}
	local numtorank = {1, 1, 2, 1, 2, 1}
	for i = 0, 4 do
		local new_skills = params.skills[self._tree_tags[i + 1]] or ""
		for j = #new_skills, 1, -1 do
			local c = new_skills:sub(j, j)
			local num = c:lower():byte(1) - 97
			local skill_num = (num % 6) + 1
			local real_tree = i * 3 + 1 + math.floor(num / 6)
			local tier = numtotier[skill_num]
			local rank = numtorank[skill_num]
			local skill_id = tweak_data.skilltree.trees[real_tree].tiers[tier][rank]

			if not _invest(real_tree, skill_id, tier, 1) then
				return false, "level"
			end
			if c:byte(1) < 97 then
				if not _invest(real_tree, skill_id, tier, 2) then
					return false, "level"
				end
			end
		end
	end

	return true
end

function BuilDB:SaveCurrent()
	local ppb = {}
	local ppt = {}
	for tree, tree_data in ipairs(tweak_data.skilltree.trees) do
		local points_spent = managers.skilltree:points_spent(tree)
		local b = math.floor((tree - 1) / 3) + 1
		ppb[b] = (ppb[b] or 0) + points_spent
		table.insert(ppt, {points_spent, managers.localization:text(tree_data.name_id)})
	end

	local roles = {"st_menu_mastermind", "st_menu_enforcer", "st_menu_technician", "st_menu_ghost", "st_menu_hoxton_pack", "menu_loadout_empty"}
	local m = -1
	local r = 6
	for k, v in pairs(ppb) do
		if v > 0 and v > m then
			m = v
			r = k
		end
	end
	local role = managers.localization:text(roles[r])

	table.sort(ppt, function(a, b) return a[1] > b[1] end)
	local descr_tbl = {}
	for i = 1, #ppt do
		if ppt[i][1] > 20 then
			table.insert(descr_tbl, string.format("%s (%i)", ppt[i][2], ppt[i][1]))
		end
	end
	local descr = table.concat(descr_tbl, ", ")

	local current_specialization = managers.skilltree:digest_value(Global.skilltree_manager.specializations.current_specialization, false, 1)	
	local spec_text = managers.localization:text("menu_st_spec_" .. current_specialization)

	local save_text = string.format("\n\n%s	%s %s\n%s\n", self:GetUrlFromSkills(), spec_text, role, descr)
	local fh = io.open(self._db_path, "a")
	if fh then
		fh:write(save_text)
		fh:close()
	end
end
