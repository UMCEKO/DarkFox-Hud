local function get_icon_data(icon)
	local texture = icon.texture
	local texture_rect = icon.texture_rect

	if icon.skills then
		texture = "guis/textures/pd2/skilltree/icons_atlas"
		local x, y = unpack(icon.skills)
		texture_rect = { x * 64, y * 64, 64, 64 }
	elseif icon.skills_new then
		texture = "guis/textures/pd2/skilltree_2/icons_atlas_2"
		local x, y = unpack(icon.skills_new)
		texture_rect = { x * 80, y * 80, 80, 80 }
	elseif icon.perks then
		texture = "guis/" .. (icon.bundle_folder and ("dlcs/" .. tostring(icon.bundle_folder) .. "/") or "") .. "textures/pd2/specialization/icons_atlas"
		local x, y = unpack(icon.perks)
		texture_rect = { x * 64, y * 64, 64, 64 }
	elseif icon.hud_icons then
		texture, texture_rect = tweak_data.hud_icons:get_icon_data(icon.hud_icons)
	elseif icon.hudtabs then
		texture = "guis/textures/pd2/hud_tabs"
		texture_rect = icon.hudtabs
	elseif icon.preplanning then
		texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/preplan_icon_types"
		local x, y = unpack(icon.preplanning)
		texture_rect = { x * 48, y * 48, 48, 48 }
	end
	
	return texture, texture_rect
end

local function format_time_string(t)
	t = math.floor(t * 10) / 10
	
	if t < 0 then
		return string.format("%.1f", 0)
	elseif t < 10 then
		return string.format("%.1f", t)
	elseif t < 60 then
		return string.format("%d", t)
	else
		return string.format("%d:%02d", t/60, t%60)
	end
end

local DEFAULT_COLOR_TABLE = {
	{ ratio = 0.0, color = Color(1, 0.9, 0.1, 0.1) }, --Red
	{ ratio = 0.5, color = Color(1, 0.9, 0.9, 0.1) }, --Yellow
	{ ratio = 1.0, color = Color(1, 0.1, 0.9, 0.1) } --Green
}
local function get_color_from_table(value, max_value, color_table, default_color)
	local color_table = color_table or DEFAULT_COLOR_TABLE
	local ratio = math.clamp(value / max_value, 0 , 1)
	local tmp_color = color_table[#color_table].color
	local color = default_color or Color(tmp_color.alpha, tmp_color.red, tmp_color.green, tmp_color.blue)
	
	for i, data in ipairs(color_table) do
		if ratio < data.ratio then
			local nxt = color_table[math.clamp(i-1, 1, #color_table)]
			local scale = (ratio - data.ratio) / (nxt.ratio - data.ratio)
			color = Color(
				(data.color.alpha or 1) * (1-scale) + (nxt.color.alpha or 1) * scale, 
				(data.color.red or 0) * (1-scale) + (nxt.color.red or 0) * scale, 
				(data.color.green or 0) * (1-scale) + (nxt.color.green or 0) * scale, 
				(data.color.blue or 0) * (1-scale) + (nxt.color.blue or 0) * scale)
			break
		end
	end
	
	return color
end

local function make_circle_gui(panel, size, add_bg, add_bg_circle, x, y)
	local cricle, bg, bg_circle

	circle = CircleBitmapGuiObject:new(panel, {
		use_bg = true,
		radius = size / 2,
		color = Color.white:with_alpha(1),
		layer = 0,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
	})
	circle._alpha = 1
	if x and y then
		circle:set_position(x, y)
	end
	
	if add_bg then
		local texture, texture_rect = get_icon_data({ hudtabs = { 84, 34, 19, 19 } })
		bg = panel:bitmap({
			texture = texture,
			texture_rect = texture_rect,
			align = "center",
			vertical = "center",
			valign = "scale",
			halign = "scale",
			w = size * 1.3,
			h = size * 1.3,
			layer = -20,
			alpha = 0.25,
			color = Color.black,
		})
		local diff = size * 0.3 / 2
		local cx, cy = circle:position()
		bg:set_position(cx - diff, cy - diff)
	end
	
	if add_bg_circle then
		bg_circle = panel:bitmap({
			texture = "guis/textures/pd2/hud_progress_active",
			w = size,
			h = size,
			align = "center",
			vertical = "center",
			valign = "scale",
			halign = "scale",
			layer = -10,
		})
		bg_circle:set_position(circle:position())
	end
	
	return circle, bg, bg_circle
end

local dir = Vector3()
local fwd = Vector3()
local function get_distance_and_rotation(camera, unit)
	mvector3.set(fwd, camera:rotation():y())
	mvector3.set(dir, unit:position())
	mvector3.subtract(dir, camera:position())
	local distance = mvector3.normalize(dir)
	local rotation = math.atan2(fwd.x*dir.y - fwd.y*dir.x, fwd.x*dir.x + fwd.y*dir.y)
	
	return distance, rotation
end

local function HUDBGBox_create_rescalable(...)
	local box_panel = HUDBGBox_create(...)
	for _, vertical in ipairs({ "top", "bottom" }) do
		for _, horizontal in ipairs({ "left", "right" }) do
			local corner_icon = box_panel:child(string.format("%s_%s", horizontal, vertical))
			corner_icon:set_halign("scale")
			corner_icon:set_valign("scale")
		end
	end
	return box_panel
end

local function tostring_trimmed(number, max_decimals)
	return string.format("%." .. (max_decimals or 10) .. "f", number):gsub("%.?0+$", "")
end

HUDList.StaticItem = HUDList.StaticItem or class(HUDList.Base)
function HUDList.StaticItem:init(id, ppanel, size, ...)
	HUDList.StaticItem.super.init(self, id, ppanel, { w = size, h = size })
	
	self._base_size = size
	
	for i, icon in ipairs({ ... }) do
		local texture, texture_rect = get_icon_data(icon)
		
		local bitmap = self._panel:bitmap({
			texture = texture,
			texture_rect = texture_rect,
			h = self._panel:w() * (icon.h_scale or 1),
			w = self._panel:w() * (icon.w_scale or 1),
			align = "center",
			vertical = "center",
			valign = "scale",
			halign = "scale",
		})
		
		bitmap:set_center(self._panel:center())
		
		if icon.valign == "top" then 
			bitmap:set_top(self._panel:top())
		elseif icon.valign == "bottom" then 
			bitmap:set_bottom(self._panel:bottom())
		end
		
		if icon.halign == "left" then
			bitmap:set_left(self._panel:left())
		elseif icon.halign == "right" then
			bitmap:set_right(self._panel:right())
		end
	end
end

function HUDList.StaticItem:rescale(scale)
	self._panel:set_size(self._base_size * scale, self._base_size * scale)
end


HUDList.RescalableHorizontalList = HUDList.RescalableHorizontalList or class(HUDList.HorizontalList)
function HUDList.RescalableHorizontalList:init(...)
	HUDList.RescalableHorizontalList.super.init(self, ...)
	
	self._current_scale = 1
	self._base_h = self._panel:h()
end

function HUDList.RescalableHorizontalList:rescale(scale)
	if self._current_scale ~= scale then
		local h = self._base_h * scale
		self._current_scale = scale
		
		self._panel:set_h(h)
		for id, item in pairs(self:items()) do
			item:rescale(scale)
		end
		
		if self._static_item then
			self._static_item:rescale(scale)
		end
		
		if self._expansion_indicator then
			self._expansion_indicator:rescale(scale)
		end
		
		self:rearrange()
	end
end


HUDList.EventItemBase = HUDList.EventItemBase or class(HUDList.Base)
function HUDList.EventItemBase:init(...)
	HUDList.EventItemBase.super.init(self, ...)
	self._listener_clbks = {}
end

function HUDList.EventItemBase:post_init(...)
	HUDList.EventItemBase.super.post_init(self, ...)
	self:_register_listeners()
end

function HUDList.EventItemBase:destroy()
	HUDList.EventItemBase.super.destroy(self)
	self:_unregister_listeners()
end

function HUDList.EventItemBase:rescale(scale)
	self._panel:set_size(self._internal.parent_panel:h(), self._internal.parent_panel:h())
end

function HUDList.EventItemBase:_register_listeners()
	for i, data in ipairs(self._listener_clbks) do
		for _, event in pairs(data.event) do
			managers.gameinfo:register_listener(data.name, data.source, event, data.clbk, data.keys, data.data_only)
		end
	end
end

function HUDList.EventItemBase:_unregister_listeners()
	for i, data in ipairs(self._listener_clbks) do
		for _, event in pairs(data.event) do
			managers.gameinfo:unregister_listener(data.name, data.source, event)
		end
	end
end


HUDList.TimerList = HUDList.TimerList or class(HUDList.RescalableHorizontalList)
HUDList.TimerList.RECHECK_INTERVAL = 1
function HUDList.TimerList:update(t, dt, ...)
	self._recheck_order_t = (self._recheck_order_t or 0) - dt
	
	if self._recheck_order_t < 0 then
		for i = 2, #self._item_order, 1 do
			local prev = self:item(self._item_order[i-1])
			local cur = self:item(self._item_order[i])
			
			if prev and cur and prev:priority() < cur:priority() then
				self:rearrange()
				break
			end
		end
		
		self._recheck_order_t = self.RECHECK_INTERVAL
	end
	
	return HUDList.TimerList.super.update(self, t, dt, ...)
end


HUDList.TimerItem = HUDList.TimerItem or class(HUDList.EventItemBase)
HUDList.TimerItem.COLORS = {
	standard = Color(1, 1, 1, 1),
	upgradable = Color(1, 0.0, 0.8, 1.0),
	disabled = Color(1, 1, 0, 0),
}
HUDList.TimerItem.FLASH_SPEED = 2
HUDList.TimerItem.DEVICE_TYPES = {
	default =		{ class = "TimerItem",					title = "Timer" },
	digital =		{ class = "TimerItem",					title = "Timer" }, 
	timer =			{ class = "TimerItem",					title = "Timer" },
	hack =			{ class = "TimerItem",					title = "Hack" },
	securitylock =	{ class = "TimerItem",					title = "Hack" },
	saw =				{ class = "UpgradeableTimerItem",	title = "Saw" },
	drill =			{ class = "UpgradeableTimerItem",	title = "Drill" },
}
function HUDList.TimerItem:init(id, ppanel, timer_data)
	local diameter = ppanel:h() * 2/3

	HUDList.TimerItem.super.init(self, id, ppanel, { w = diameter, h = ppanel:h() })
	
	self._unit = timer_data.unit
	self._remaining = math.huge
	
	self._type_text = self._panel:text({
		name = "type_text",
		text = self.DEVICE_TYPES[timer_data.device_type].title or self.DEVICE_TYPES.default.title,
		align = "center",
		vertical = "top",
		valign = "scale",
		halign = "scale",
		w = diameter,
		h = (self._panel:h() - diameter) * 0.6,
		font_size = (self._panel:h() - diameter) * 0.6,
		font = tweak_data.hud_corner.assault_font,
	})	
	
	self._circle, self._bg, self._circle_bg = make_circle_gui(self._panel, diameter, true, true, 0, self._type_text:h())
	self._circle_bg:set_visible(false)
	self._circle_bg:set_color(Color.red)
	
	local arrow_w = diameter * 0.25
	self._arrow = self._panel:bitmap({
		name = "arrow",
		texture = "guis/textures/hud_icons",
		texture_rect = { 434, 46, 30, 19 },
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = arrow_w,
		h = arrow_w * 2/3,
	})
	self._arrow:set_center(self._circle_bg:center())

	self._main_text = self._panel:text({
		name = "time_text",
		align = "center",
		vertical = "top",
		valign = "scale",
		halign = "scale",
		w = diameter,
		h = diameter * 0.35,
		font = tweak_data.hud_corner.assault_font,
		font_size = diameter * 0.35,
	})
	self._main_text:set_bottom(self._arrow:top() - 1)

	self._secondary_text = self._panel:text({
		name = "distance_text",
		align = "center",
		vertical = "bottom",
		valign = "scale",
		halign = "scale",
		w = diameter,
		h = diameter * 0.3,
		font = tweak_data.hud_corner.assault_font,
		font_size = diameter * 0.3,
	})
	self._secondary_text:set_top(self._arrow:bottom() + 1)
	
	self._flash_color_table = {
		{ ratio = 0.0, color = self.COLORS.disabled },
		{ ratio = 1.0, color = self.COLORS.standard }
	}
	
	local key = tostring(self._unit:key())
	local listener_id = string.format("HUDList_timer_listener_%s", key)
	local events = {
		update = callback(self, self, "_update_timer"),
		set_jammed = callback(self, self, "_set_jammed"),
		set_unpowered = callback(self, self, "_set_unpowered"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "timer", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.TimerItem:post_init(timer_data, ...)
	HUDList.TimerItem.super.post_init(self, timer_data, ...)
	
	self:_set_jammed(timer_data)
	self:_set_unpowered(timer_data)
	self:_update_timer(timer_data)
end

function HUDList.TimerItem:priority(...)
	return -self._remaining
end

function HUDList.TimerItem:update(t, dt)
	if self:visible() then
		if self._jammed or self._unpowered then
			self._circle_bg:set_alpha(math.sin(t*360 * self.FLASH_SPEED) * 0.5 + 0.5)
			local new_color = get_color_from_table(math.sin(t*360 * self.FLASH_SPEED) * 0.5 + 0.5, 1, self._flash_color_table, self.COLORS.standard)
			self:_set_colors(new_color)
		end
		
		self:_update_distance(t, dt)
	end
	
	return HUDList.TimerItem.super.update(self, t, dt)
end

function HUDList.TimerItem:rescale(scale)
	self._panel:set_size(self._internal.parent_panel:h() * 2/3, self._internal.parent_panel:h())
	self._type_text:set_font_size((self._panel:h() - self._panel:w()) * 0.6)
	self._main_text:set_font_size(self._panel:w() * 0.35)
	self._secondary_text:set_font_size(self._panel:w() * 0.3)
end

function HUDList.TimerItem:_update_timer(data)
	if data.timer_value then
		self._remaining = data.timer_value
		self._main_text:set_text(format_time_string(self._remaining))
		
		if data.progress_ratio then
			self._circle:set_current(1 - data.progress_ratio)
		elseif data.duration then
			self._circle:set_current(self._remaining/data.duration)
		end
	end
end

function HUDList.TimerItem:_set_jammed(data)
	self._jammed = data.jammed
	self:_check_is_running()
end

function HUDList.TimerItem:_set_unpowered(data)
	self._unpowered = data.unpowered
	self:_check_is_running()
end

function HUDList.TimerItem:_check_is_running()
	if not (self._jammed or self._unpowered) then
		self:_set_colors(self._flash_color_table[2].color)
		self._circle_bg:set_visible(false)
	else
		self._circle_bg:set_visible(true)
	end
end

function HUDList.TimerItem:_update_distance(t, dt)
	local camera = managers.viewport:get_current_camera()
	if camera and alive(self._unit) then
		local distance, rotation = get_distance_and_rotation(camera, self._unit)
		self._secondary_text:set_text(string.format("%.0fm", distance / 100))
		self._arrow:set_rotation(270 - rotation)
	end
end

function HUDList.TimerItem:_set_colors(color)
	self._secondary_text:set_color(color)
	self._main_text:set_color(color)
	self._type_text:set_color(color)
	self._arrow:set_color(color)
end

HUDList.UpgradeableTimerItem = HUDList.UpgradeableTimerItem or class(HUDList.TimerItem)
function HUDList.UpgradeableTimerItem:init(id, ppanel, timer_data)
	HUDList.UpgradeableTimerItem.super.init(self, id, ppanel, timer_data)
	
	self._upgrades = {"faster", "silent", "restarter"}
	self._upgrade_icons = {}
	
	local icon_size = self._panel:h() - self._type_text:h() - self._circle_bg:h()
	for _, upgrade in ipairs(self._upgrades) do
		self._upgrade_icons[upgrade] = self._panel:bitmap{
			texture = "guis/textures/pd2/skilltree/drillgui_icon_" .. upgrade,
			w = icon_size,
			h = icon_size,
			align = "center",
			vertical = "center",
			valign = "scale",
			halign = "scale",
			y = self._panel:h() - icon_size,
			visible = false,
		}
	end
	
	local key = tostring(timer_data.unit:key())
	local listener_id = string.format("HUDList_timer_listener_%s", key)
	local events = {
		set_upgradable = callback(self, self, "_set_upgradable"),
		set_acquired_upgrades = callback(self, self, "_set_acquired_upgrades"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "timer", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.UpgradeableTimerItem:post_init(timer_data, ...)
	HUDList.UpgradeableTimerItem.super.post_init(self, timer_data, ...)
	
	self:_set_upgradable(timer_data)
	self:_set_acquired_upgrades(timer_data)
	self._upgradable_timer_data = nil
end

function HUDList.UpgradeableTimerItem:_set_upgradable(data)
	self._upgradable = data.upgradable
	local current_color = self._upgradable and self.COLORS.upgradable or self.COLORS.standard
	self._flash_color_table[2].color = current_color
	self:_set_colors(current_color)
end

function HUDList.UpgradeableTimerItem:_set_acquired_upgrades(data)
	local x = 0
	
	for _, upgrade in ipairs(self._upgrades) do
		local icon = self._upgrade_icons[upgrade]
		local level =  data.acquired_upgrades and data.acquired_upgrades[upgrade] or 0
		
		icon:set_visible(level > 0)
		if level > 0 then
			icon:set_color(TimerGui.upgrade_colors["upgrade_color_" .. level] or Color.white)
			icon:set_x(x)
			x = x + icon:w()
		end
	end
end

HUDList.TemperatureGaugeItem = HUDList.TemperatureGaugeItem or class(HUDList.TimerItem)
function HUDList.TemperatureGaugeItem:init(id, ppanel, timer_data, timer_params)
	self._start = timer_params.start
	self._goal = timer_params.goal
	self._last_value = self._start
	
	HUDList.TemperatureGaugeItem.super.init(self, id, ppanel, timer_data)
	
	self._type_text:set_text("Temp")
end

function HUDList.TemperatureGaugeItem:update(t, dt)
	if self._estimated_t then
		self._estimated_t = self._estimated_t - dt
		
		if self:visible() then
			self._main_text:set_text(format_time_string(self._estimated_t))
		end
	end
	
	return HUDList.TemperatureGaugeItem.super.update(self, t, dt)
end

function HUDList.TemperatureGaugeItem:priority(...)
	return 1
end

function HUDList.TemperatureGaugeItem:_update_timer(data)
	if data.timer_value then
		local dv = math.abs(self._last_value - data.timer_value)
		local remaining = math.abs(self._goal - data.timer_value)
		
		if dv > 0 then
			self._estimated_t = remaining / dv
			self._circle:set_current(remaining / math.abs(self._goal - self._start))
		end
		
		self._last_value = data.timer_value
	end
end


HUDList.SentryEquipmentItem = HUDList.SentryEquipmentItem or class(HUDList.EventItemBase)
function HUDList.SentryEquipmentItem:init(id, ppanel, sentry_data)
	local equipment_settings = HUDListManager.EQUIPMENT_TABLE.sentry
	
	HUDList.SentryEquipmentItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h(), priority = equipment_settings.priority })
	
	self._unit = sentry_data.unit
	self._type = sentry_data.type
	
	self._ammo_bar = self._panel:bitmap({
		name = "radial_ammo",
		texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
		render_template = "VertexColorTexturedRadial",
		color = Color.red,
		w = self._panel:w(),
		h = self._panel:w(),
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
	})
	
	self._ammo_bar_bg = self._panel:bitmap({
		name = "radial_ammo_bg",
		texture = "guis/textures/pd2/endscreen/exp_ring",
		color = Color.red,
		w = self._panel:w() * 1.15,
		h = self._panel:w() * 1.15,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		visible = false,
		alpha = 0,
		layer = -1,
	})
	self._ammo_bar_bg:set_center(self._panel:w() / 2, self._panel:h() / 2)
	
	self._health_bar = self._panel:bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_health",
		render_template = "VertexColorTexturedRadial",
		color = Color.red,
		w = self._panel:w(),
		h = self._panel:w(),
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
	})
	
	local texture, texture_rect = get_icon_data({ hudtabs = { 84, 34, 19, 19 } })
	self._owner_icon = self._panel:bitmap({
		name = "owner_icon",
		texture = texture,
		texture_rect = texture_rect,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		h = self._panel:w() * 0.5,
		w = self._panel:w() * 0.5,
		color = Color.black,
		alpha = 0.25,
	})
	self._owner_icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
	
	self._kills = self._panel:text({
		name = "kills",
		text = "0",
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h(),
		layer = 10,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.5,
	})
	
	local listener_id = string.format("HUDList_sentry_listener_%s", id)
	local events = {
		set_ammo_ratio = callback(self, self, "_set_ammo_ratio"),
		set_health_ratio = callback(self, self, "_set_health_ratio"),
		increment_kills = callback(self, self, "_set_kills"),
		set_owner = callback(self, self, "_set_owner"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "sentry", event = { event }, clbk = clbk, keys = { id }, data_only = true })
	end
end

function HUDList.SentryEquipmentItem:post_init(sentry_data, ...)
	HUDList.SentryEquipmentItem.super.post_init(self, sentry_data, ...)

	self:_set_owner(sentry_data)
	self:_set_kills(sentry_data)
	self:_set_ammo_ratio(sentry_data)
	self:_set_health_ratio(sentry_data)
end

function HUDList.SentryEquipmentItem:rescale(scale)
	HUDList.SentryEquipmentItem.super.rescale(self, scale)
	self._kills:set_font_size(self._panel:h() * 0.5)
end

function HUDList.SentryEquipmentItem:is_player_owner()
	return self._owner == managers.network:session():local_peer():id()
end

function HUDList.SentryEquipmentItem:_set_owner(data)
	if data.owner then
		self._owner = data.owner
		self._owner_icon:set_alpha(0.75)
		self._owner_icon:set_color(self._owner and self._owner > 0 and tweak_data.chat_colors[self._owner]:with_alpha(1) or Color.white)
	end
	
	self:set_active(HUDListManager.ListOptions.show_sentries < 2 or self:is_player_owner())
end

function HUDList.SentryEquipmentItem:_set_ammo_ratio(data)
	if data.ammo_ratio then
		self._ammo_bar:set_color(Color(data.ammo_ratio, 1, 1))
		
		
		if data.ammo_ratio <= 0 then
			self:set_active(self:is_player_owner())
			
			self._ammo_bar_bg:animate(function(o)
				local bc = o:color()
				local t = 0
				
				o:set_visible(true)
				
				while true do
					local r = math.sin(t*720) * 0.25 + 0.25
					o:set_alpha(r)
					t = t + coroutine.yield()
				end
			end)
		end
		
	end
end

function HUDList.SentryEquipmentItem:_set_health_ratio(data)
	if data.health_ratio then
		self._health_bar:set_color(Color(data.health_ratio, 1, 1))
	end
end

function HUDList.SentryEquipmentItem:_set_kills(data)
	self._kills:set_text(tostring(data.kills))
end


HUDList.BagEquipmentItem = HUDList.BagEquipmentItem or class(HUDList.EventItemBase)
function HUDList.BagEquipmentItem:init(id, ppanel, equipment_type)
	local equipment_settings = HUDListManager.EQUIPMENT_TABLE[equipment_type]
	
	HUDList.BagEquipmentItem.super.init(self, id, ppanel, { w = ppanel:h() * 0.8, h = ppanel:h(), priority = equipment_settings.priority })
	
	self._units = {}
	self._type = equipment_type
	self._max_amount = 0
	self._amount = 0
	self._amount_offset = 0
	
	self._box = HUDBGBox_create_rescalable(self._panel, {
			w = self._panel:w(),
			h = self._panel:h(),
			halign = "scale",
			valign = "scale",
		}, {})
	
	local texture, texture_rect = get_icon_data(equipment_settings)
	self._icon = self._panel:bitmap({
		name = "icon",
		texture = texture,
		texture_rect = texture_rect,
		h = self._panel:w() * 0.8,
		w = self._panel:w() * 0.8,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		layer = 1,
	})
	self._icon:set_center_x(self._panel:center_x())
	
	self._info_text = self._panel:text({
		name = "info",
		align = "center",
		vertical = "bottom",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h(),
		layer = 1,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.4,
	})
end

function HUDList.BagEquipmentItem:rescale(scale)
	self._panel:set_size(self._internal.parent_panel:h() * 0.8, self._internal.parent_panel:h())
	self._info_text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.BagEquipmentItem:equipment_type()
	return self._type
end

function HUDList.BagEquipmentItem:add_bag_unit(key, data)
	self._units[key] = data
	self:_rebuild_listeners()
	self:_update_info()
	self:set_active(next(self._units) and true or false)
end

function HUDList.BagEquipmentItem:remove_bag_unit(key, data)
	self._units[key] = nil
	self:_rebuild_listeners()
	self:_update_info()
	self:set_active(next(self._units) and true or false)
end

function HUDList.BagEquipmentItem:_rebuild_listeners()
	self:_unregister_listeners()
	self._listener_clbks = {}
	self:_generate_listeners_table()
	self:_register_listeners()
end

function HUDList.BagEquipmentItem:_generate_listeners_table()
	local keys = {}
	for key, data in pairs(self._units) do
		table.insert(keys, key)
	end
	
	local listener_id = string.format("HUDList_bag_listener_%s", self:id())
	local events = {
		set_max_amount = callback(self, self, "_update_info"),
		set_amount = callback(self, self, "_update_info"),
		set_amount_offset = callback(self, self, "_update_info"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = self._type, event = { event }, clbk = clbk, keys = keys, data_only = true })
	end
end

function HUDList.BagEquipmentItem:_update_info(...)
	local max_amount = 0
	local amount = 0
	local amount_offset = 0
	
	for key, data in pairs(self._units) do
		max_amount = max_amount + (data.max_amount or 0)
		amount = amount + (data.amount or 0)
		amount_offset = amount_offset + (data.amount_offset or 0)
	end
	
	self._max_amount = max_amount
	self._amount = amount
	self._amount_offset = amount_offset
	self:_update_text()
	self._info_text:set_color(get_color_from_table(self._amount + self._amount_offset, self._max_amount + self._amount_offset))
end

function HUDList.BagEquipmentItem:_update_text()
	self._info_text:set_text(string.format("%.0f", self._amount + self._amount_offset))
end

HUDList.AmmoBagItem = HUDList.AmmoBagItem or class(HUDList.BagEquipmentItem)	
function HUDList.AmmoBagItem:_update_text()
	self._info_text:set_text(string.format("%.0f%%", (self._amount + self._amount_offset) * 100))
end

HUDList.BodyBagItem = HUDList.BodyBagItem or class(HUDList.BagEquipmentItem)
function HUDList.BodyBagItem:_generate_listeners_table()
	HUDList.BodyBagItem.super._generate_listeners_table(self)
	
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_bag_listener_%s", self:id()),
		source = "whisper_mode",
		event = { "change" },
		clbk = callback(self, self, "_whisper_mode_change"),
		data_only = true,
	})
end

function HUDList.BodyBagItem:set_active(state)
	return HUDList.BodyBagItem.super.set_active(self, state and managers.groupai:state():whisper_mode())
end

function HUDList.BodyBagItem:_whisper_mode_change(state)
	self:set_active(self:active())
end


HUDList.MinionItem = HUDList.MinionItem or class(HUDList.EventItemBase)
function HUDList.MinionItem:init(id, ppanel, minion_data)
	HUDList.MinionItem.super.init(self, id, ppanel, { w = ppanel:h() * 0.8, h = ppanel:h() })
	
	self._unit = minion_data.unit
	local type_string = HUDListManager.UNIT_TYPES[minion_data.type] and HUDListManager.UNIT_TYPES[minion_data.type].long_name or "UNDEF"

	self._health_bar = self._panel:bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_health",
		texture_rect = { 128, 0, -128, 128 },
		render_template = "VertexColorTexturedRadial",
		blend_mode = "add",
		layer = 2,
		color = Color(1, 1, 0, 0),
		w = self._panel:w(),
		h = self._panel:w(),
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
	})
	self._health_bar:set_bottom(self._panel:bottom())
	
	self._hit_indicator = self._panel:bitmap({
		name = "radial_health",
		texture = "guis/textures/pd2/hud_radial_rim",
		blend_mode = "add",
		layer = 1,
		color = Color.red,
		alpha = 0,
		w = self._panel:w(),
		h = self._panel:w(),
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
	})
	self._hit_indicator:set_center(self._health_bar:center())

	self._outline = self._panel:bitmap({
		name = "outline",
		texture = "guis/textures/pd2/hud_shield",
		texture_rect = { 128, 0, -128, 128 },
		blend_mode = "add",
		w = self._panel:w() * 0.95,
		h = self._panel:w() * 0.95,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		layer = 1,
		alpha = 0,
		color = Color(0.8, 0.8, 1.0),
	})
	self._outline:set_center(self._health_bar:center())
	
	self._damage_upgrade_text = self._panel:text({
		name = "type",
		text = "W",
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:w(),
		layer = 3,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:w() * 0.4,
		alpha  = 0.5
	})
	self._damage_upgrade_text:set_bottom(self._panel:bottom())
	
	self._unit_type = self._panel:text({
		name = "type",
		text = type_string,
		align = "center",
		vertical = "top",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:w() * 0.3,
		layer = 3,
		font = tweak_data.hud_corner.assault_font,
		font_size = math.min(8 / string.len(type_string), 1) * 0.25 * self._panel:h(),
	})
	
	self._kills = self._panel:text({
		name = "kills",
		text = "0",
		align = "right",
		vertical = "bottom",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:w(),
		layer = 10,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:w() * 0.4,
	})
	self._kills:set_center(self._health_bar:center())
	
	local key = tostring(self._unit:key())
	local listener_id = string.format("HUDList_minion_listener_%s", key)
	local events = {
		set_health_ratio = callback(self, self, "_set_health_ratio"),
		set_owner = callback(self, self, "_set_owner"),
		increment_kills = callback(self, self, "_set_kills"),
		set_damage_resistance = callback(self, self, "_set_damage_resistance"),
		set_damage_multiplier = callback(self, self, "_set_damage_multiplier"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "minion", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.MinionItem:post_init(minion_data, ...)
	HUDList.MinionItem.super.post_init(self, minion_data, ...)

	self:_set_health_ratio(minion_data, true)
	self:_set_damage_resistance(minion_data)
	self:_set_damage_multiplier(minion_data)
	self:_set_owner(minion_data)
end

function HUDList.MinionItem:rescale(scale)
	self._panel:set_size(self._internal.parent_panel:h() * 0.8, self._internal.parent_panel:h())
	self._damage_upgrade_text:set_font_size(self._panel:w() * 0.4)
	self._unit_type:set_font_size(math.min(8 / string.len(self._unit_type:text()), 1) * 0.25 * self._panel:h())
	self._kills:set_font_size(self._panel:w() * 0.4)
end

function HUDList.MinionItem:is_player_owner()
	return self._owner == managers.network:session():local_peer():id()
end

function HUDList.MinionItem:_set_health_ratio(data, skip_animate)
	if data.health_ratio then
		self._health_bar:set_color(Color(1, data.health_ratio, 1, 1))
		if not skip_animate then
			self._hit_indicator:stop()
			self._hit_indicator:animate(function(o)
				over(1, function(r)
					o:set_alpha(1-r)
				end)
			end)
		end
	end
end

function HUDList.MinionItem:_set_owner(data)
	if data.owner then
		self._owner = data.owner
		self._unit_type:set_color(tweak_data.chat_colors[data.owner]:with_alpha(1) or Color(1, 1, 1, 1))
	end
	
	self:set_active(HUDListManager.ListOptions.show_minions < 2 or self:is_player_owner())
end

function HUDList.MinionItem:_set_kills(data)
	self._kills:set_text(data.kills)
end

function HUDList.MinionItem:_set_damage_resistance(data)
	local max_mult = tweak_data.upgrades.values.player.convert_enemies_health_multiplier[1] * tweak_data.upgrades.values.player.passive_convert_enemies_health_multiplier[2]
	local alpha = math.clamp(1 - ((data.damage_resistance or 1) - max_mult) / (1 - max_mult), 0, 1) * 0.8 + 0.2
	self._outline:set_alpha(alpha)
end

function HUDList.MinionItem:_set_damage_multiplier(data)
	self._damage_upgrade_text:set_alpha((data.damage_multiplier or 1) > 1 and 1 or 0.5)
end


HUDList.PagerItem = HUDList.PagerItem or class(HUDList.EventItemBase)
HUDList.PagerItem.FLASH_SPEED = 2
function HUDList.PagerItem:init(id, ppanel, pager_data)
	HUDList.PagerItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
	
	self._unit = pager_data.unit
	self._start_t = pager_data.start_t
	self._expire_t = pager_data.expire_t
	self._duration = pager_data.expire_t - pager_data.start_t
	self._remaining = pager_data.expire_t - Application:time()
	
	self._circle, self._bg, self._circle_bg = make_circle_gui(self._panel, self._panel:h(), true, true)
	
	local arrow_w = self._panel:w() * 0.25
	self._arrow = self._panel:bitmap({
		name = "arrow",
		texture = "guis/textures/hud_icons",
		texture_rect = { 434, 46, 30, 19 },
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = arrow_w,
		h = arrow_w * 2/3,
	})
	self._arrow:set_center(self._panel:w() / 2, self._panel:h() / 2)

	self._time_text = self._panel:text({
		name = "time_text",
		align = "center",
		vertical = "top",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h() * 0.35,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.35,
	})
	self._time_text:set_bottom(self._arrow:top() - 1)

	self._distance_text = self._panel:text({
		name = "distance_text",
		align = "center",
		vertical = "bottom",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h() * 0.3,
		font = tweak_data.hud_corner.assault_font,
		font_size = self._panel:h() * 0.3,
	})
	self._distance_text:set_top(self._arrow:bottom() + 1)
	
	local key = tostring(self._unit:key())
	table.insert(self._listener_clbks, { 
		name = string.format("HUDList_pager_listener_%s", key), 
		source = "pager", 
		event = { "set_answered" }, 
		clbk = callback(self, self, "_set_answered"), 
		keys = { key }, 
		data_only = true
	})
end

function HUDList.PagerItem:rescale(scale)
	HUDList.PagerItem.super.rescale(self, scale)
	self._time_text:set_font_size(self._panel:h() * 0.35)
	self._distance_text:set_font_size(self._panel:h() * 0.3)
end

function HUDList.PagerItem:_set_answered()
	self._answered = true
	self._time_text:set_color(Color(1, 0.1, 0.9, 0.1))
	
	self._circle_bg:set_color(Color.green)
	self._circle_bg:set_alpha(0.8)
	self._circle_bg:set_visible(true)
end

function HUDList.PagerItem:update(t, dt)
	if not self._answered then
		self._remaining = math.max(self._remaining - dt, 0)
		
		if self:visible() then
			self._ratio = self._remaining / self._duration
			
			local color = get_color_from_table(self._remaining, self._duration)
			self._time_text:set_text(format_time_string(self._remaining))
			self._time_text:set_color(color)
			self._circle_bg:set_color(color)
			self._circle:set_current(self._ratio)
			
			if self._ratio <= 0.25 then
				self._circle_bg:set_alpha(math.sin(t*360 * self.FLASH_SPEED) * 0.3 + 0.5)
			end
		end
	end
	
	if self:visible() then
		local camera = managers.viewport:get_current_camera()
		if camera and alive(self._unit) then
			local distance, rotation = get_distance_and_rotation(camera, self._unit)
			self._distance_text:set_text(string.format("%.0fm", distance / 100))
			self._arrow:set_rotation(270 - rotation)
		end
	end
	
	return HUDList.PagerItem.super.update(self, t, dt)
end	


HUDList.ECMItem = HUDList.ECMItem or class(HUDList.EventItemBase)
function HUDList.ECMItem:init(id, ppanel, ecm_data)
	HUDList.ECMItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
	
	self._unit = ecm_data.unit
	self._max_duration = ecm_data.max_duration or tweak_data.upgrades.ecm_jammer_base_battery_life
	
	self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
	
	self._text = self._panel:text({
		name = "text",
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h(),
		font = tweak_data.hud_corner.assault_font,
		layer = 10,
		font_size = self._panel:h() * 0.4,
	})
	
	local texture, texture_rect = get_icon_data({ skills_new = { 3, 4 } })
	self._pager_block_icon = self._panel:bitmap({
		name = "pager_block_icon",
		texture = texture,
		texture_rect = texture_rect,
		w = self._panel:w() * 0.7,
		h = self._panel:h() * 0.7,
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		alpha = 0.85,
	})
	self._pager_block_icon:set_bottom(self._panel:h() * 1.1)
	self._pager_block_icon:set_right(self._panel:w() * 1.1)
	
	local key = tostring(self._unit:key())
	local listener_id = string.format("HUDList_ecm_jammer_listener_%s", key)
	local events = {
		set_upgrade_level = callback(self, self, "_set_upgrade_level"),
		set_jammer_battery = callback(self, self, "_set_jammer_battery"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "ecm", event = { event }, clbk = clbk, keys = { key }, data_only = true })
	end
end

function HUDList.ECMItem:post_init(ecm_data, ...)
	HUDList.ECMItem.super.post_init(self, ecm_data, ...)

	self:_set_jammer_battery(ecm_data)
	self:_set_upgrade_level(ecm_data)
end

function HUDList.ECMItem:rescale(scale)
	HUDList.ECMItem.super.rescale(self, scale)
	self._text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.ECMItem:_set_upgrade_level(data)
	if data.upgrade_level then
		self._blocks_pager = data.upgrade_level == 3
		self._max_duration = tweak_data.upgrades.ecm_jammer_base_battery_life * ECMJammerBase.battery_life_multiplier[data.upgrade_level]
		self._pager_block_icon:set_visible(self._blocks_pager)
	end
end

function HUDList.ECMItem:_set_jammer_battery(data)
	if data.jammer_battery then
		self._text:set_text(format_time_string(data.jammer_battery))
		self._text:set_color(get_color_from_table(data.jammer_battery, self._max_duration))
		self._circle:set_current(data.jammer_battery / self._max_duration)
	end
end

HUDList.PocketECMItem = HUDList.PocketECMItem or class(HUDList.ECMItem)
function HUDList.PocketECMItem:init(id, ppanel, ecm_data)
	HUDList.PocketECMItem.super.init(self, id, ppanel, ecm_data)
	
	self._start_t = ecm_data.t
	self._expire_t = ecm_data.expire_t
end

function HUDList.PocketECMItem:update(...)
	HUDList.PocketECMItem.super.update(self, ...)
	
	local t = Application:time()
	local remaining = self._expire_t - t
	self:_set_jammer_battery({ jammer_battery = remaining })
end


HUDList.ECMRetriggerItem = HUDList.ECMRetriggerItem or class(HUDList.EventItemBase)
function HUDList.ECMRetriggerItem:init(id, ppanel, ecm_data)
	HUDList.ECMRetriggerItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
	
	self._unit = ecm_data.unit
	self._max_duration = tweak_data.upgrades.ecm_feedback_retrigger_interval or 60
	
	self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
	
	self._text = self._panel:text({
		name = "text",
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h(),
		font = tweak_data.hud_corner.assault_font,
		layer = 10,
		font_size = self._panel:h() * 0.4,
	})
	
	local key = tostring(self._unit:key())
	table.insert(self._listener_clbks, { 
		name = string.format("HUDList_ecm_retrigger_listener_%s", key), 
		source = "ecm", 
		event = { "set_retrigger_delay" }, 
		clbk = callback(self, self, "_set_retrigger_delay"), 
		keys = { key }, 
		data_only = true
	})
end

function HUDList.ECMRetriggerItem:post_init(ecm_data, ...)
	HUDList.ECMRetriggerItem.super.post_init(self, ecm_data, ...)

	self:_set_retrigger_delay(ecm_data)
end

function HUDList.ECMRetriggerItem:rescale(scale)
	HUDList.ECMRetriggerItem.super.rescale(self, scale)
	self._text:set_font_size(self._panel:h() * 0.4)
end

function HUDList.ECMRetriggerItem:_set_retrigger_delay(data)
	if data.retrigger_delay then
		local remaining = self._max_duration - data.retrigger_delay
		self._text:set_text(format_time_string(data.retrigger_delay))
		self._text:set_color(get_color_from_table(remaining, self._max_duration))
		self._circle:set_current(1 - remaining / self._max_duration)
	end
end


HUDList.TapeLoopItem = HUDList.TapeLoopItem or class(HUDList.EventItemBase)
function HUDList.TapeLoopItem:init(id, ppanel, tape_loop_data)
	HUDList.TapeLoopItem.super.init(self, id, ppanel, { w = ppanel:h(), h = ppanel:h() })
	
	self._unit = tape_loop_data.unit
	self._start_t = tape_loop_data.tape_loop_start_t
	self._expire_t = tape_loop_data.tape_loop_expire_t
	self._duration = self._expire_t - self._start_t
	
	self._circle, self._bg = make_circle_gui(self._panel, self._panel:h(), true)
	
	self._text = self._panel:text({
		name = "text",
		align = "center",
		vertical = "center",
		valign = "scale",
		halign = "scale",
		w = self._panel:w(),
		h = self._panel:h(),
		font = tweak_data.hud_corner.assault_font,
		layer = 10,
		font_size = self._panel:h() * 0.4,
	})
end

function HUDList.TapeLoopItem:update(t, dt)
	if self:visible() then
		local remaining = self._expire_t - t
		self._text:set_text(format_time_string(remaining))
		self._circle:set_current(remaining / self._duration)
	end
	
	return HUDList.TapeLoopItem.super.update(self, t, dt)
end

function HUDList.TapeLoopItem:rescale(scale)
	HUDList.TapeLoopItem.super.rescale(self, scale)
	self._text:set_font_size(self._panel:h() * 0.4)
end


HUDList.StealthList = HUDList.StealthList or class(HUDList.RescalableHorizontalList)
function HUDList.StealthList:post_init(...)
	HUDList.StealthList.super.post_init(self, ...)
	managers.gameinfo:register_listener("HUDList_stealth_list_listener", "whisper_mode", "change", callback(self, self, "_whisper_mode_change"), nil, true)
end

function HUDList.StealthList:_whisper_mode_change(state)
	if not state then
		self:clear_items()
	end
end


HUDList.CounterItem = HUDList.CounterItem or class(HUDList.EventItemBase)
function HUDList.CounterItem:init(id, ppanel, data)
	HUDList.CounterItem.super.init(self, id, ppanel, { w = ppanel:h() / 2, h = ppanel:h(), priority = data.priority })

	local texture, texture_rect = get_icon_data(data.icon or {})
	self._icon = self._panel:bitmap({
		name = "icon",
		texture = texture,
		texture_rect = texture_rect,
		color = (data.icon and data.icon.color or Color.white):with_alpha(1),
		blend_mode = data.icon and data.icon.blend_mode or "normal",
		h = self._panel:w(),
		w = self._panel:w(),
		halign = "scale",
		valign = "scale",
	})
	
	self._box = HUDBGBox_create_rescalable(self._panel, {
			w = self._panel:w(),
			h = self._panel:w(),
			halign = "scale",
			valign = "scale",
		}, {})
	self._box:set_bottom(self._panel:bottom())
	
	self._text = self._box:text({
		name = "text",
		align = "center",
		vertical = "center",
		halign = "scale",
		valign = "scale",
		w = self._box:w(),
		h = self._box:h(),
		font = tweak_data.hud_corner.assault_font,
		font_size = self._box:h() * 0.6
	})
	
	self._count = 0
end

function HUDList.CounterItem:rescale(scale)
	self._panel:set_size(self._internal.parent_panel:h() / 2, self._internal.parent_panel:h())
	self._text:set_font_size(self._box:h() * 0.6)
end

function HUDList.CounterItem:change_count(diff)
	self:set_count(self._count + diff)
end

function HUDList.CounterItem:set_count(num)
	self._count = num
	self._text:set_text(tostring(self._count))
	self:set_active(self._count > 0)
end


HUDList.UsedPagersItem = HUDList.UsedPagersItem or class(HUDList.CounterItem)
function HUDList.UsedPagersItem:init(id, ppanel)
	HUDList.UsedPagersItem.super.init(self, id, ppanel, { icon = { perks = {1, 4} } })
	
	self._listener_clbks = {
		{
			name = "HUDList_pager_count_listener",
			source = "pager",
			event = { "add" },
			clbk = callback(self, self, "_add_pager"),
			data_only = true,
		}
	}
end

function HUDList.UsedPagersItem:post_init(...)
	HUDList.UsedPagersItem.super.post_init(self, ...)
	self:set_count(table.size(managers.gameinfo:get_pagers()))
end

function HUDList.UsedPagersItem:_add_pager(...)
	self:change_count(1)
end

function HUDList.UsedPagersItem:set_count(num)
	HUDList.UsedPagersItem.super.set_count(self, num)
	
	if self._count >= #tweak_data.player.alarm_pager.bluff_success_chance - 1 then
		self._text:set_color(Color.red)
	end
end


HUDList.CameraCountItem = HUDList.CameraCountIteM or class(HUDList.CounterItem)
function HUDList.CameraCountItem:init(id, ppanel)
	HUDList.CameraCountItem.super.init(self, id, ppanel, { icon = { skills = {4, 2} } })
	
	self._listener_clbks = {
		{
			name = "HUDList_camera_count_listener",
			source = "camera_count",
			event = { "change_count" },
			clbk = callback(self, self, "_recount_cameras"),
			data_only = true,
		},
		{
			name = "HUDList_camera_count_listener",
			source = "camera",
			event = { "set_active", "start_tape_loop", "stop_tape_loop" },
			clbk = callback(self, self, "_recount_cameras"),
			data_only = true,
		},
	}
end

function HUDList.CameraCountItem:post_init(...)
	HUDList.CameraCountItem.super.post_init(self, ...)
	self:_recount_cameras()
end

function HUDList.CameraCountItem:_recount_cameras(...)
	if managers.groupai:state():whisper_mode() then
		local count = 0
		for key, data in pairs(managers.gameinfo:get_cameras()) do
			if data.active or data.tape_loop_expire_t then
				count = count + 1
			end
		end
		self:set_count(count)
	end
end


HUDList.LootItem = HUDList.LootItem or class(HUDList.CounterItem)
HUDList.LootItem.MAP = {
	armor =			{ text = "Armor" },
	artifact =		{ text = "Artifact" },
	body =			{ text = "Body" },
	bomb =			{ text = "Bomb" },
	coke =			{ text = "Coke" },
	dentist =		{ text = "Unknown" },
	diamond =		{ text = "Diamond" },
	drone_ctrl =	{ text = "BCI" },
	evidence =		{ text = "Evidence" },
	goat =			{ text = "Goat" },
	gold =			{ text = "Gold" },
	headset =		{ text = "Headset" },
	jewelry =		{ text = "Jewelry" },
	meth =			{ text = "Meth" },
	money =			{ text = "Money" },
	painting =		{ text = "Painting" },
	pig =				{ text = "Pig" },
	present =		{ text = "Present" },
	prototype =		{ text = "Prototype" },
	safe =			{ text = "Safe" },
	server =			{ text = "Server" },
	shell =			{ text = "Shell" },
	shoes =			{ text = "Shoes" },
	toast =			{ text = "Toast" },
	toothbrush =	{ text = "Toothbrush" },
	toy =				{ text = "Toy" },
	turret =			{ text = "Turret" },
	warhead =		{ text = "Warhead" },
	weapon =			{ text = "Weapon" },
	wine =			{ text = "Wine" },
	
	aggregate =		{ text = "" },	--Aggregated loot
	body_stealth =	{ icon = { skills_new = {7, 2} } },	--Bodies for stealth
}
function HUDList.LootItem:init(id, ppanel, members)
	local data = HUDList.LootItem.MAP[id]
	HUDList.LootItem.super.init(self, id, ppanel, data)

	if not data.icon then
		local texture, texture_rect = get_icon_data({ hudtabs = { 32, 33, 32, 32 } })
		self._icon:set_image(texture, unpack(texture_rect))
		self._icon:set_alpha(0.75)
		self._icon:set_w(self._panel:w() * 1.2)
		self._icon:set_center_x(self._panel:w() / 2)
		self._default_icon = true
	end
	
	self._loot_types = {}
	self._bagged_count = 0
	self._unbagged_count = 0

	if data.text then
		self._name_text = self._panel:text({
			name = "text",
			text = string.sub(data.text, 1, 5) or "",
			align = "center",
			vertical = "center",
			halign = "scale",
			valign = "scale",
			w = self._panel:w(),
			h = self._panel:w(),
			color = Color(0.0, 0.5, 0.0),
			font = tweak_data.hud_corner.assault_font,
			font_size = self._panel:w() * 0.4,
			layer = 10
		})
		self._name_text:set_center_x(self._icon:center_x())
		self._name_text:set_y(self._name_text:y() + self._icon:h() * 0.1)
	end
	
	for _, loot_id in pairs(members) do
		self._loot_types[loot_id] = true
	end
	
	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_loot_count_listener", id),
			source = "loot_count",
			event = { "change" },
			clbk = callback(self, self, "_change_loot_count"),
			keys = members,
			data_only = true,
		}
	}
end

function HUDList.LootItem:rescale(scale)
	HUDList.LootItem.super.rescale(self, scale)
	if self._name_text then
		self._name_text:set_font_size(self._panel:w() * 0.4)
	end
	if self._default_icon then
		self._icon:set_w(self._panel:w() * 1.2)
	end
end

function HUDList.LootItem:post_init(...)
	HUDList.LootItem.super.post_init(self, ...)
	self:update_value()
end

function HUDList.LootItem:update_value()
	local total_unbagged = 0
	local total_bagged = 0
	
	for _, data in pairs(managers.gameinfo:get_loot()) do
		if self._loot_types[data.carry_id] and self:_check_loot_condition(data) then
			if data.bagged then
				total_bagged = total_bagged + data.count
			else
				total_unbagged = total_unbagged + data.count
			end
		end
	end

	self:set_count(total_unbagged, total_bagged)
end

function HUDList.LootItem:set_count(unbagged, bagged)
	self._unbagged_count = unbagged
	self._bagged_count = bagged
	
	local total = self._unbagged_count + self._bagged_count
	self._text:set_text(HUDListManager.ListOptions.separate_bagged_loot and (self._unbagged_count .. "/" .. self._bagged_count) or total)
	self:set_active(total > 0)
end

function HUDList.LootItem:_change_loot_count(data, value)
	if not self:_check_loot_condition(data) then return end
	
	self:set_count(
		self._unbagged_count + (data.bagged and 0 or value), 
		self._bagged_count + (data.bagged and value or 0)
	)
end

function HUDList.LootItem:_check_loot_condition(data)
	local loot_type = HUDListManager.LOOT_TYPES[data.carry_id]
	local condition_clbk = HUDListManager.LOOT_CONDITIONS[loot_type]
	return not condition_clbk or condition_clbk(data)
end


HUDList.BodyCountItem = HUDList.BodyCountItem or class(HUDList.LootItem)
function HUDList.BodyCountItem:init(id, ppanel)
	HUDList.BodyCountItem.super.init(self, id, ppanel, { "person", "special_person" })
end

function HUDList.BodyCountItem:_check_loot_condition()
	return managers.groupai:state():whisper_mode()
end

function HUDList.BodyCountItem:set_count(...)
	if self:_check_loot_condition() then
		HUDList.BodyCountItem.super.set_count(self, ...)
	end
end


HUDList.UnitCountItem = HUDList.UnitCountItem or class(HUDList.CounterItem)
HUDList.UnitCountItem.MAP = {
	--TODO: Security and cop are both able to be dominate/jokered. Specials could cause issues if made compatible. Straight subtraction won't work. Should be fine for aggregated enemy counter
	enemies =	{ priority = 0,	class = "DominatableCountItem",	icon = { skills = {0, 5} } },	--Aggregated enemies
	hostages =	{ priority = 6,	class = "UnitCountItem",			icon = { skills = {4, 7} } },	--Aggregated hostages
	
	cop =			{ priority = 2,	class = "DominatableCountItem",	icon = { skills = {0, 5} } },
	security =	{ priority = 3,	class = "DominatableCountItem",	icon = { perks = {1, 4} } },
	thug =		{ priority = 3,	class = "UnitCountItem",			icon = { skills = {4, 12} } },
	thug_boss =	{ priority = 3,	class = "UnitCountItem",			icon = { skills = {1, 1} } },
	tank =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {3, 1} } },
	tank_med =	{ priority = 1,	class = "UnitCountItem",			icon = { hud_icons = "crime_spree_dozer_medic" } },
	tank_min =	{ priority = 1,	class = "UnitCountItem",			icon = { hud_icons = "crime_spree_dozer_minigun" } },
	spooc =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {1, 3} } },
	taser =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {3, 5} } },
	shield =		{ priority = 1,	class = "ShieldCountItem",			icon = { texture = "guis/textures/pd2/hud_buff_shield" } },
	sniper =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {6, 5} } },
	medic =		{ priority = 1,	class = "UnitCountItem",			icon = { skills = {5, 7} } },
	phalanx =	{ priority = 0,	class = "UnitCountItem",			icon = { texture = "guis/textures/pd2/hud_buff_shield" } },
	
	turret =			{ priority = 3,	class = "UnitCountItem",		icon = { skills = {7, 5} } },
	unique =			{ priority = 4,	class = "UnitCountItem",		icon = { skills = {3, 8} } },
	civ =				{ priority = 4,	class = "CivilianCountItem",	icon = { skills = {6, 7} } },
	cop_hostage =	{ priority = 5,	class = "UnitCountItem",		icon = { skills = {2, 8} } },
	civ_hostage =	{ priority = 6,	class = "UnitCountItem",		icon = { skills = {4, 7} } },
	minion =			{ priority = 7,	class = "UnitCountItem",		icon = { skills = {6, 8} } },
}
function HUDList.UnitCountItem:init(id, ppanel, members)
	local data = HUDList.UnitCountItem.MAP[id]
	HUDList.UnitCountItem.super.init(self, id, ppanel, data)
	
	self._unit_types = {}
	
	for _, unit_id in pairs(members) do
		self._unit_types[unit_id] = true
		self._count = self._count + managers.gameinfo:get_unit_count(unit_id)
	end
	
	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_unit_count_listener", id),
			source = "unit_count",
			event = { "change" },
			clbk = callback(self, self, "_change_count"),
			keys = members,
		},
	}
end

function HUDList.UnitCountItem:post_init(...)
	HUDList.UnitCountItem.super.post_init(self, ...)	
	self:set_count(self._count)
end

function HUDList.UnitCountItem:_change_count(event, unit_type, value)
	self:change_count(value)
end

HUDList.ShieldCountItem = HUDList.ShieldCountItem or class(HUDList.UnitCountItem)
function HUDList.ShieldCountItem:init(...)
	HUDList.ShieldCountItem.super.init(self, ...)
	
	self._shield_filler = self._panel:rect({
		name = "shield_filler",
		w = self._icon:w() * 0.4,
		h = self._icon:h() * 0.4,
		align = "center",
		vertical = "center",
		halign = "scale",
		valign = "scale",
		color = self._icon:color():with_alpha(1),
		layer = self._icon:layer() - 1,
	})
	self._shield_filler:set_center(self._icon:center())
end

HUDList.CivilianCountItem = HUDList.CivilianCountItem or class(HUDList.UnitCountItem)
function HUDList.CivilianCountItem:init(...)
	HUDList.CivilianCountItem.super.init(self, ...)
	
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_%s_civ_count_listener", self:id()),
		source = "unit_count",
		event = { "change" },
		clbk = callback(self, self, "_change_count"),
		keys = { "civ_hostage" }
	})
end

function HUDList.CivilianCountItem:post_init(...)
	HUDList.CivilianCountItem.super.post_init(self, ...)
	self:change_count(-managers.gameinfo:get_unit_count("civ_hostage"))
end

function HUDList.CivilianCountItem:_change_count(event, unit_type, value)
	self:change_count(unit_type == "civ_hostage" and -value or value)
end

HUDList.DominatableCountItem = HUDList.DominatableCountItem or class(HUDList.UnitCountItem)
function HUDList.DominatableCountItem:init(id, ppanel, members)
	HUDList.DominatableCountItem.super.init(self, id, ppanel, members)
	
	self._hostage_offset = 0
	self._joker_offset = 0
	
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_%s_dominatable_count_listener", id),
		source = "unit_count",
		event = { "change" },
		clbk = callback(self, self, "_change_dominatable_count"),
		keys = { "cop_hostage" }
	})
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_%s_dominatable_minion_count_listener", id),
		source = "minion",
		event = { "add", "remove" },
		clbk = callback(self, self, "_change_joker_count"),
	})
end

function HUDList.DominatableCountItem:post_init(...)
	HUDList.DominatableCountItem.super.post_init(self, ...)
	self:_change_dominatable_count()
end

function HUDList.DominatableCountItem:set_count(num)
	self._count = num
	local actual = self._count - self._hostage_offset - self._joker_offset
	self._text:set_text(tostring(actual))
	self:set_active(actual > 0)
end

function HUDList.DominatableCountItem:_change_dominatable_count(...)
	local offset = 0
	
	for u_key, u_data in pairs(managers.enemy:all_enemies()) do
		local unit = u_data.unit
		if alive(unit) and self._unit_types[unit:base()._tweak_table] then
			if Network:is_server() then
				if unit:brain():surrendered() then
					offset = offset + 1
				end
			else
				if unit:anim_data().surrender then
					offset = offset + 1
				end
			end
		end
	end
	
	if self._hostage_offset ~= offset then
		self._hostage_offset = offset
		self:set_count(self._count)
	end
end

function HUDList.DominatableCountItem:_change_joker_count(event, key, data)
	if self._unit_types[data.type] then
		self._joker_offset = self._joker_offset + (event == "add" and 1 or -1)
		self:_change_dominatable_count()
		self:set_count(self._count)
	end
end


HUDList.SpecialPickupItem = HUDList.SpecialPickupItem or class(HUDList.CounterItem)
HUDList.SpecialPickupItem.MAP = {
	courier = 					{ icon = { texture = "guis/dlcs/trk/textures/pd2/achievements_atlas7", texture_rect = { 435, 435, 85, 85 }}},
	--courier = 					{ icon = { skills = { 6, 0 } } },
	crowbar =					{ icon = { hud_icons = "equipment_crowbar" } },
	keycard =					{ icon = { hud_icons = "equipment_bank_manager_key" } },
	planks =						{ icon = { hud_icons = "equipment_planks" } },
	meth_ingredients =		{ icon = { hud_icons = "pd2_methlab" } },
	secret_item =				{ icon = { hud_icons = "pd2_question" } },	
}
function HUDList.SpecialPickupItem:init(id, ppanel, members)
	HUDList.SpecialPickupItem.super.init(self, id, ppanel, HUDList.SpecialPickupItem.MAP[id])
	
	self._pickup_types = {}
	
	for _, pickup_id in pairs(members) do
		self._pickup_types[pickup_id] = true
	end
	
	for _, data in pairs(managers.gameinfo:get_special_equipment()) do
		if self._pickup_types[data.interact_id] then
			self._count = self._count + 1
		end
	end
	
	self._listener_clbks = {
		{
			name = string.format("HUDList_%s_special_pickup_count_listener", id),
			source = "special_equipment_count",
			event = { "change" },
			clbk = callback(self, self, "_change_special_equipment_count_clbk"),
			keys = members,
		}
	}
end

function HUDList.SpecialPickupItem:post_init(...)
	HUDList.SpecialPickupItem.super.post_init(self, ...)
	self:set_count(self._count)
end

function HUDList.SpecialPickupItem:_change_special_equipment_count_clbk(event, interact_id, value, data)
	self:change_count(value)
end


local PanelFrame = class()
function PanelFrame:init(parent, settings)
	settings = settings or {}
	
	local h = settings.h or parent:h()
	local w = settings.w or parent:w()
	local total = 2*w + 2*h
	
	self._panel = parent:panel({
		w = w,
		h = h,
		alpha = settings.alpha or 1,
		visible = settings.visible,
	})
	
	self._invert_progress = settings.invert_progress
	self._stages = { 0, w/total, (w+h)/total, (2*w+h)/total, 1 }
	self._top = self._panel:rect({})
	self._bottom = self._panel:rect({})
	self._left = self._panel:rect({})
	self._right = self._panel:rect({})
	
	self:set_width(settings.bar_w or 2)
	self:set_color(settings.color or Color.white)
	self:reset()
end

function PanelFrame:panel()
	return self._panel
end

function PanelFrame:set_width(w)
	self._top:set_h(w)
	self._top:set_top(0)
	self._bottom:set_h(w)
	self._bottom:set_bottom(self._panel:h())
	self._left:set_w(w)
	self._left:set_left(0)
	self._right:set_w(w)
	self._right:set_right(self._panel:w())
end

function PanelFrame:set_color(c)
	self._top:set_color(c)
	self._bottom:set_color(c)
	self._left:set_color(c)
	self._right:set_color(c)
end

function PanelFrame:reset()
	self._current_stage = 1
	self._top:set_w(self._panel:w())
	self._right:set_h(self._panel:h())
	self._right:set_bottom(self._panel:h())
	self._bottom:set_w(self._panel:w())
	self._bottom:set_right(self._panel:w())
	self._left:set_h(self._panel:h())
end

function PanelFrame:set_ratio(r)
	r = math.clamp(r, 0, 1)
	if self._invert_progress then
		r = 1-r
	end
	
	if r < self._stages[self._current_stage] then
		self:reset()
	end
	
	while r > self._stages[self._current_stage + 1] do
		if self._current_stage == 1 then
			self._top:set_w(0)
		elseif self._current_stage == 2 then
			self._right:set_h(0)
		elseif self._current_stage == 3 then
			self._bottom:set_w(0)
		elseif self._current_stage == 4 then
			self._left:set_h(0)
		end
		self._current_stage = self._current_stage + 1
	end
	
	local low = self._stages[self._current_stage]
	local high = self._stages[self._current_stage + 1]
	local stage_progress = (r - low) / (high - low)
	
	if self._current_stage == 1 then
		self._top:set_w(self._panel:w() * (1-stage_progress))
		self._top:set_right(self._panel:w())
	elseif self._current_stage == 2 then
		self._right:set_h(self._panel:h() * (1-stage_progress))
		self._right:set_bottom(self._panel:h())
	elseif self._current_stage == 3 then
		self._bottom:set_w(self._panel:w() * (1-stage_progress))
	elseif self._current_stage == 4 then
		self._left:set_h(self._panel:h() * (1-stage_progress))
	end
end


local function buff_value_standard(item, buffs)
	local value = 0
	for buff, data in pairs(buffs) do
		value = value + (data.active and data.value or 0)
	end
	return value
end

local function buff_stack_count_standard(item, buffs)
	local value = 0
	for buff, data in pairs(buffs) do
		value = value + (data.active and data.stack_count or 0)
	end
	return value
end

HUDList.BuffItemBase = HUDList.BuffItemBase or class(HUDList.EventItemBase)
HUDList.BuffItemBase.MAP = {
	--Buffs
	aggressive_reload_aced = {
		skills_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	ammo_efficiency = {
		skills_new = tweak_data.skilltree.skills.spotter_teamwork.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	armor_break_invulnerable = {
		perks = {6, 1},
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks" } },
	},
	berserker = {
		skills_new = tweak_data.skilltree.skills.wolverine.icon_xy,
		class = "BerserkerBuffItem",
		priority = 3,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	biker = {
		perks = {0, 0}, bundle_folder = "wild",
		class = "BikerBuffItem",
		priority = 8,
		menu_data = { grouping = { "perks", "biker" }, sort_key = "prospect" },
	},
	bloodthirst_aced = {
		skills_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
		class = "TimedBuffItem",
		priority = 3,
		ace_icon = true,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	bloodthirst_basic = {
		skills_new = tweak_data.skilltree.skills.bloodthirst.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	bullet_storm = {
		skills_new = tweak_data.skilltree.skills.ammo_reservoir.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	calm = {
		perks = {2, 0}, bundle_folder = "myh",
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "stoic" } },
	},
	chico_injector = {
		perks = {0, 0}, bundle_folder = "chico",
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "scarface" }, sort_key = "injector" },
	},
	close_contact = {
		perks = {5, 4},
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks" }, sort_key = "close_combat_no_talk" },
	},
	combat_medic = {
		skills_new = tweak_data.skilltree.skills.combat_medic.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	desperado = {
		skills_new = tweak_data.skilltree.skills.expert_handling.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	die_hard = {
		skills_new = tweak_data.skilltree.skills.show_of_force.icon_xy,
		class = "BuffItemBase",
		priority = 7,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	dire_need = {
		skills_new = tweak_data.skilltree.skills.dire_need.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		menu_data = { grouping = { "skills", "ghost" } },
	},
	grinder = {
		perks = {4, 6},
		class = "TimedStackBuffItem",
		priority = 8,
		menu_data = { grouping = { "perks", "grinder" }, sort_key = "histamine" },
	},
	hostage_situation = {
		perks = {0, 1},
		class = "BuffItemBase",
		priority = 3,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "perks", "crew_chief" } },
	},
	hostage_taker = {
		skills_new = tweak_data.skilltree.skills.black_marketeer.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	inspire = {
		skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	lock_n_load = {
		skills_new = tweak_data.skilltree.skills.shock_and_awe.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		show_value = buff_value_standard,
		menu_data = { grouping = { "skills", "technician" } },
	},
	maniac = {
		perks = {0, 0}, bundle_folder = "coco",
		class = "TimedBuffItem",
		priority = 7,
		show_value = buff_value_standard,
		menu_data = { grouping = { "perks", "maniac" }, sort_key = "excitement" },
	},
	melee_stack_damage = {
		perks = {5, 4},
		class = "TimedBuffItem",
		priority = 7,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "perks", "infiltrator" }, sort_key = "overdog_melee_damage" },
	},
	messiah = {
		skills_new = tweak_data.skilltree.skills.messiah.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	muscle_regen = {
		perks = {4, 1},
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "muscle" }, sort_key = "800_pound_gorilla" },
	},
	overdog = {
		perks = {6, 4},
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "infiltrator" }, sort_key = "overdog_damage_reduction" },
	},
	overkill = {
		skills_new = tweak_data.skilltree.skills.overkill.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	pain_killer = {
		skills_new = tweak_data.skilltree.skills.fast_learner.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	partner_in_crime = {
		skills_new = tweak_data.skilltree.skills.control_freak.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	pocket_ecm_kill_dodge = {
		perks = {3, 0}, bundle_folder = "joy",
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "hacker" } },
	},
	quick_fix = {
		skills_new = tweak_data.skilltree.skills.tea_time.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	running_from_death_aced = {
		skills_new = tweak_data.skilltree.skills.running_from_death.icon_xy,
		class = "BuffItemBase",
		priority = 3,
		ace_icon = true,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	running_from_death_basic = {
		skills_new = tweak_data.skilltree.skills.running_from_death.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	second_wind = {
		skills_new = tweak_data.skilltree.skills.scavenger.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "ghost" } },
	},
	sicario_dodge = {
		perks = {1, 0}, bundle_folder = "max",
		class = "TimedBuffItem",
		priority = 7,
		show_value = buff_value_standard,
		menu_data = { grouping = { "perks", "sicario" }, sort_key = "twitch" },
	},
	sixth_sense = {
		skills_new = tweak_data.skilltree.skills.chameleon.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "ghost" } },
	},
	smoke_screen = {
		perks = {0, 1}, bundle_folder = "max",
		class = "BuffItemBase",
		priority = 7,
		menu_data = { grouping = { "perks", "sicario" } },
	},
	swan_song = {
		skills_new = tweak_data.skilltree.skills.perseverance.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	tooth_and_claw = {
		perks = {0, 3},
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "hitman" } },
	},
	trigger_happy = {
		skills_new = tweak_data.skilltree.skills.trigger_happy.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		show_stack_count = buff_stack_count_standard,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	underdog = {
		skills_new = tweak_data.skilltree.skills.underdog.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	unseen_strike = {
		skills_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "ghost" } },
	},
	uppers = {
		skills_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	up_you_go = {
		skills_new = tweak_data.skilltree.skills.up_you_go.icon_xy,
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "skills", "fugitive" } },
	},
	yakuza = {
		perks = {2, 7},
		class = "BerserkerBuffItem",
		priority = 3,
		menu_data = { grouping = { "perks", "yakuza" } },
	},
	
	--Debuffs
	ammo_give_out_debuff = {
		perks = {5, 5},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "gambler" } },
	},
	anarchist_armor_recovery_debuff = {
		perks = {0, 1}, bundle_folder = "opera",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "anarchist" }, sort_key = "lust_for_life" },
	},
	armor_break_invulnerable_debuff = {
		perks = {6, 1},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks" } },
	},
	bullseye_debuff = {
		skills_new = tweak_data.skilltree.skills.prison_wife.icon_xy,
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	chico_injector_debuff = {
		perks = {0, 0}, bundle_folder = "chico",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "scarface" }, sort_key = "injector_debuff" },
	},
	grinder_debuff = {
		perks = {4, 6},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "grinder" }, sort_key = "histamine_debuff" },
	},
	inspire_debuff = {
		skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 10,
		title = "Boost",
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	inspire_revive_debuff = {
		skills_new = tweak_data.skilltree.skills.inspire.icon_xy,
		class = "TimedBuffItem",
		priority = 10,
		title = "Revive",
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	life_drain_debuff = {
		perks = {7, 4},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "infiltrator" } },
	},
	medical_supplies_debuff = {
		perks = {4, 5},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "gambler" } },
	},
	pocket_ecm_jammer_debuff = {
		perks = {0, 0}, bundle_folder = "joy",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "hacker" } },
	},
	self_healer_debuff = {
		hud_icons = "csb_lifesteal",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "boosts" }, sort_key = "gage_boost_lifesteal" },
	},
	sicario_dodge_debuff = {
		perks = {1, 0}, bundle_folder = "max",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "sicario" }, sort_key = "twitch_debuff" },
	},
	smoke_grenade = {
		perks = {0, 0}, bundle_folder = "max",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "sicario" } },
	},
	sociopath_debuff = {
		perks = {3, 5},
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "perks", "sociopath" } },
	},
	some_invulnerability_debuff = {
		hud_icons = "csb_melee",
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "boosts" }, sort_key = "gage_boost_invulnerability" },
	},
	stoic_flask = {
		perks = {0, 1}, bundle_folder = "myh",
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "stoic" } },
	},
	unseen_strike_debuff = {
		skills_new = tweak_data.skilltree.skills.unseen_strike.icon_xy,
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "skills", "ghost" } },
	},
	uppers_debuff = {
		skills_new = tweak_data.skilltree.skills.tea_cookies.icon_xy,
		class = "TimedBuffItem",
		priority = 10,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	virtue_debuff = {
		perks = {3, 0}, bundle_folder = "myh",
		class = "TimedBuffItem",
		priority = 7,
		menu_data = { grouping = { "perks", "stoic" } },
		show_value = buff_value_standard,
	},
	
	--Team buffs
	armorer = {
		perks = {6, 0},
		class = "TeamBuffItem",
		priority = 1,
		title = "Armorer",
		menu_data = { grouping = { "perks", "armorer" }, sort_key = "liquid_armor" },
	},
	crew_chief = {
		perks = {2, 0},
		class = "TeamBuffItem",
		priority = 1,
		title = "Crew Chief",
		menu_data = { grouping = { "perks", "crew_chief" } },
	},
	forced_friendship = {
		skills = tweak_data.skilltree.skills.triathlete.icon_xy,
		class = "TeamBuffItem",
		priority = 1,
		menu_data = { grouping = { "skills", "mastermind" } },
	},
	shock_and_awe = {
		perks = {6, 2},
		class = "TeamBuffItem",
		priority = 1,
		menu_data = { grouping = { "skills", "enforcer" } },
	},
	
	--Composite buffs
	damage_increase = {
		perks = {7, 0},
		class = "DamageIncreaseBuffItem",
		priority = 5,
		title = "+Dmg",
		menu_data = { grouping = { "composite" } },
	},
	damage_reduction = {
		skills = {6, 4},
		class = "DamageReductionBuffItem",
		priority = 5,
		title = "-Dmg",
		menu_data = { grouping = { "composite" } },
	},
	melee_damage_increase = {
		skills = {4, 10},
		class = "MeleeDamageIncreaseBuffItem",
		priority = 5,
		title = "+M.Dmg",
		menu_data = { grouping = { "composite" } },
	},
	passive_health_regen = {
		perks = {4, 1},
		class = "HealthRegenBuffItemBase",
		priority = 5,
		show_value = buff_value_standard,
		title = "Regen",
		menu_data = { grouping = { "composite" } },
	},
}
HUDList.BuffItemBase.BUFF_COLORS = {
	standard = Color.white,
	debuff = Color.red,
	team = Color.green,
}
HUDList.BuffItemBase.PROGRESS_BAR_WIDTH = 2
function HUDList.BuffItemBase:init(id, ppanel, members, item_data)
	HUDList.BuffItemBase.super.init(self, id, ppanel, { h = ppanel:h(), w = ppanel:h() * 0.6, priority = -item_data.priority })
	
	self:set_fade_rate(100)
	self:set_move_rate(nil)
	
	self._member_data = {}
	self._active_buffs = {}
	self._active_debuffs = {}
	self._standard_color = self._standard_color or item_data.color or self.BUFF_COLORS.standard
	self._debuff_color = self._debuff_color or item_data.debuff_color or self.BUFF_COLORS.debuff
	self._show_stack_count = self._show_stack_count or item_data.show_stack_count
	self._show_value = self._show_value or item_data.show_value
	self._timed = self._timed or item_data.timed
	
	for _, buff in ipairs(members) do
		self._member_data[buff] = {}
	end
	
	local icon_size = self._panel:w() - HUDList.BuffItemBase.PROGRESS_BAR_WIDTH * 3 - 5
	local texture, texture_rect = get_icon_data(item_data)
	
	self._icon = self._panel:bitmap({
		texture = texture,
		texture_rect = texture_rect,
		h = icon_size,
		w = icon_size,
		color = self._standard_color,
		rotation = item_data.icon_rotation or 0,
	})
	self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
	
	self._bg = self._panel:rect({
		h = self._icon:h(),
		w = self._icon:w(),
		layer = -10,
		color = Color.black,
		alpha = 0.2,
	})
	self._bg:set_center(self._icon:center())
	
	if item_data.ace_icon then
		self._ace_icon = self._panel:bitmap({
			texture = "guis/textures/pd2/skilltree_2/ace_symbol",
			h = icon_size * 1.5,
			w = icon_size * 1.5,
			color = self._standard_color,
			layer = self._icon:layer() - 1,
		})
		self._ace_icon:set_center(self._icon:center())
	end
	
	if self._show_stack_count then
		self._stack_panel = self._panel:panel({
			w = self._icon:w() * 0.4,
			h = self._icon:h() * 0.4,
			layer = self._icon:layer() + 1,
			visible = false,
		})
		self._stack_panel:set_right(self._icon:right())
		self._stack_panel:set_bottom(self._icon:bottom())
	
		self._stack_panel:bitmap({
			w = self._stack_panel:w(),
			h = self._stack_panel:h(),
			texture = "guis/textures/pd2/equip_count",
			texture_rect = { 5, 5, 22, 22 },
			alpha = 0.8,
		})
		
		self._stack_text = self._stack_panel:text({
			valign = "center",
			align = "center",
			vertical = "center",
			w = self._stack_panel:w(),
			h = self._stack_panel:h(),
			layer = 1,
			color = Color.black,
			font = tweak_data.hud.small_font,
			font_size = self._stack_panel:h() * 0.85,
		})
	end
	
	if self._timed then
		self._expire_data = {}
		self._progress_bars = {}
		
		for i = 1, 3, 1 do
			local progress_bar = PanelFrame:new(self._panel, { 
				bar_w = self.PROGRESS_BAR_WIDTH, 
				w = self._icon:w() + self.PROGRESS_BAR_WIDTH * (i-1) * 2,
				h = self._icon:h() + self.PROGRESS_BAR_WIDTH * (i-1) * 2,
				visible = false,
			})
			progress_bar:panel():set_center(self._icon:center())
			
			table.insert(self._progress_bars, progress_bar)
		end
	end
	
	if self._timed or self._show_value then
		local h = (self._panel:h() - self._icon:h()) / 2
		
		self._value_text = self._panel:text({
			align = "center",
			vertical = "bottom",
			w = self._panel:w(),
			h = h,
			font = tweak_data.hud_corner.assault_font,
			font_size = 0.7 * h,
		})
		self._value_text:set_bottom(self._panel:h())
	end
	
	if item_data.title then
		local h = (self._panel:h() - self._icon:h()) / 2
		
		self._title_text = self._panel:text({
			text = item_data.title,
			align = "center",
			vertical = "top",
			w = self._panel:w(),
			h = h,
			font = tweak_data.hud_corner.assault_font,
			font_size = 0.7 * h,
		})
	end
	
	local listener_id = string.format("HUDList_buff_listener_%s", id)
	local events = {
		set_value = self._show_value and callback(self, self, "_set_value_clbk") or nil,
		set_stack_count = self._show_stack_count and callback(self, self, "_set_stack_count_clbk") or nil,
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = members })
	end
end

function HUDList.BuffItemBase:apply_current_values(id, data)
	if data then
		if self._timed and data.t and data.expire_t then
			self:_set_duration_clbk("set_duration", id, data)
		end
		if self._show_value and data.value then
			self:_set_value_clbk("set_value", id, data)
		end
		if self._show_stack_count and data.stack_count then
			self:_set_stack_count_clbk("set_stack_count", id, data)
		end
	end
end

function HUDList.BuffItemBase:set_buff_active(id, status, data, is_debuff)
	local active_table = is_debuff and self._active_debuffs or self._active_buffs
	
	if status then
		self._member_data[id].active = status and true or false
		table.insert(active_table, id)
	elseif table.contains(active_table, id) then
		self._member_data[id].active = status and true or false
		table.delete(active_table, id)
		
		if self._timed then
			self:_update_expire_data()
		end
	end
	
	self:set_active(#self._active_debuffs + #self._active_buffs > 0)
end

function HUDList.BuffItemBase:update(t, dt)
	if self:visible() then
		if self._timed then
			local text = ""
			local debuff_start_index
		
			for i, data in ipairs(self._expire_data) do
				local total = data.expire_t - data.t
				local current = t - data.t
				local remaining = total - current
				
				self._progress_bars[i]:set_ratio(current/total)
				
				debuff_start_index = data.is_debuff and string.len(text) or debuff_start_index
				text = text .. format_time_string(remaining)
				if i < #self._expire_data then
					text = text .. "/"
				end
			end
			
			if not self._show_value then
				self._value_text:set_text(text)
				if debuff_start_index then
					self._value_text:set_range_color(debuff_start_index, string.len(text), self.BUFF_COLORS.debuff)
				end
			end
		end
	end
	
	return HUDList.BuffItemBase.super.update(self, t, dt)
end

function HUDList.BuffItemBase:_set_duration_clbk(event, id, data)
	self._member_data[id].t = data.t
	self._member_data[id].expire_t = data.expire_t
	self:_update_expire_data()
end

function HUDList.BuffItemBase:_set_value_clbk(event, id, data)
	self._member_data[id].value = data.value
	self:_update_value_text()
end

function HUDList.BuffItemBase:_set_stack_count_clbk(event, id, data)
	self._member_data[id].stack_count = data.stack_count
	self:_update_stack_count()
end

function HUDList.BuffItemBase:_update_expire_data()
	self._expire_data = {}
	
	local min_t, min_expire_t, max_t, max_expire_t
	local debuff_t, debuff_expire_t
	
	if #self._active_buffs > 0 then
		for _, id in ipairs(self._active_buffs) do
			local data = self._member_data[id]
			
			if data.expire_t then
				if not max_expire_t or data.expire_t > max_expire_t then
					max_t = data.t
					max_expire_t = data.expire_t
				end
				if not min_expire_t or data.expire_t < min_expire_t then
					min_t = data.t
					min_expire_t = data.expire_t
				end
			end
		end
		
		if min_expire_t then
			table.insert(self._expire_data, { t = min_t, expire_t = min_expire_t })
			if math.abs(max_expire_t - min_expire_t) > 0.01 then
				table.insert(self._expire_data, { t = max_t, expire_t = max_expire_t })
			end
		end
	end
	
	if #self._active_debuffs > 0 then
		for _, id in ipairs(self._active_debuffs) do
			local data = self._member_data[id]
			
			if data.expire_t and data.t then
				if not debuff_expire_t or data.expire_t > debuff_expire_t then
					debuff_t = data.t
					debuff_expire_t = data.expire_t
				end
			end
		end
		
		if debuff_expire_t then
			table.insert(self._expire_data, { t = debuff_t, expire_t = debuff_expire_t, is_debuff = true })
		end
	end
	
	for i, progress_bar in ipairs(self._progress_bars) do
		local expire_data = self._expire_data[i]
		progress_bar:panel():set_visible(expire_data and true or false)
		progress_bar:set_color(expire_data and expire_data.is_debuff and self.BUFF_COLORS.debuff or self._standard_color)
	end
	
	self:_set_icon_color((debuff_expire_t and (not min_expire_t or min_expire_t > debuff_expire_t)) and self._debuff_color or self._standard_color)
end

function HUDList.BuffItemBase:_update_value_text()
	local value = self._show_value(self, self._member_data)
	self._value_text:set_text(tostring_trimmed(value, 2))
end

function HUDList.BuffItemBase:_update_stack_count()
	local stacks = self._show_stack_count(self, self._member_data)
	self._stack_panel:set_visible(stacks > 0)
	self._stack_text:set_text(string.format("%d", stacks))
end

function HUDList.BuffItemBase:_set_icon_color(color)
	self._icon:set_color(color)
	if self._ace_icon then
		self._ace_icon:set_color(color)
	end
end


HUDList.BerserkerBuffItem = HUDList.BerserkerBuffItem or class(HUDList.BuffItemBase)
function HUDList.BerserkerBuffItem:init(...)
	self._show_value = self._show_value_function
	HUDList.BerserkerBuffItem.super.init(self, ...)
end

function HUDList.BerserkerBuffItem._show_value_function(item, buffs)
	local values = {}
	
	for buff, data in pairs(buffs) do
		if data.active and data.value then
			table.insert(values, data.value)
		end
	end
	
	return values
end

function HUDList.BerserkerBuffItem:_update_value_text()
	local values = self._show_value(self, self._member_data)
	local text = ""
	
	for i, value in ipairs(values) do
		text = text .. tostring_trimmed(value, 2)
		if i < #values then
			text = text .. " / "
		end
	end
	
	self._value_text:set_text(text)
end


HUDList.TeamBuffItem = HUDList.TeamBuffItem or class(HUDList.BuffItemBase)
HUDList.TeamBuffItem.BUFF_LEVELS = {
	cc_passive_damage_reduction =	1,
	cc_passive_stamina_multiplier = 3,
	cc_passive_health_multiplier = 5,
	cc_passive_armor_multiplier = 7,
	cc_hostage_damage_reduction = 9,
	cc_hostage_health_multiplier = 9,
	cc_hostage_stamina_multiplier = 9,
}
function HUDList.TeamBuffItem:init(...)
	self._show_value = self._show_value_function
	HUDList.TeamBuffItem.super.init(self, ...)
	self._standard_color = self.BUFF_COLORS.team
	self:_set_icon_color(self._standard_color)
end

function HUDList.TeamBuffItem._show_value_function(item, buffs)
	local level = 0
	
	--printf("Updating team buff level: %s", tostring(item:id()))
	for id, data in pairs(buffs) do
		level = math.max(level, data.active and HUDList.TeamBuffItem.BUFF_LEVELS[id] or 0)
		
		--if data.active then
		--	printf("\tActive buff: %s / %s", id, tostring(HUDList.TeamBuffItem.BUFF_LEVELS[id]))
		--end
	end
	return level
end

function HUDList.TeamBuffItem:set_buff_active(...)
	HUDList.TeamBuffItem.super.set_buff_active(self, ...)
	self:_update_value_text()
end

function HUDList.TeamBuffItem:_update_value_text()
	local value = self._show_value(self, self._member_data)
	self._value_text:set_text(value > 0 and tostring_trimmed(value) or "")
end


HUDList.TimedBuffItem = HUDList.TimedBuffItem or class(HUDList.BuffItemBase)
function HUDList.TimedBuffItem:init(id, ppanel, members, item_data)
	self._timed = true
	HUDList.TimedBuffItem.super.init(self, id, ppanel, members, item_data)
	
	table.insert(self._listener_clbks, {
		name = string.format("HUDList_buff_listener_%s", id),
		source = "buff",
		event = { "set_duration" },
		clbk = callback(self, self, "_set_duration_clbk"),
		keys = members,
	})
end


HUDList.TimedStackBuffItem = HUDList.TimedStackBuffItem or class(HUDList.TimedBuffItem)
function HUDList.TimedStackBuffItem:init(id, ppanel, members, item_data)
	self._show_stack_count = self._show_stack_count_function
	self._stack_count = 0
	HUDList.TimedStackBuffItem.super.init(self, id, ppanel, members, item_data)
	
	local listener_id = string.format("HUDList_buff_listener_%s", id)
	local events = {
		add_timed_stack = callback(self, self, "_stack_changed_clbk"),
		remove_timed_stack = callback(self, self, "_stack_changed_clbk"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = members })
	end
end

function HUDList.TimedStackBuffItem:apply_current_values(id, data)
	HUDList.TimedStackBuffItem.super.apply_current_values(self, id, data)
	
	if data then
		if data.stacks then
			self:_stack_changed_clbk("add_timed_stack", id, data)
		end
	end
end

function HUDList.TimedStackBuffItem._show_stack_count_function(item, buffs)
	return item._stack_count or 0
end

function HUDList.TimedStackBuffItem:_stack_changed_clbk(event, id, data)
	--This is a simplification which assumes only one buff is present with timed stacks, which is the case currently for grinder/biker
	self._stacks = data.stacks
	self._stack_count = table.size(self._stacks)
	
	self._member_data[id].stacks = data.stacks
	self:_update_expire_data()
	self:_update_stack_count()
end

function HUDList.TimedStackBuffItem:_update_expire_data()
	self._expire_data = {}
	
	local min_t, min_expire_t, max_t, max_expire_t
	local debuff_t, debuff_expire_t
	
	if self._stack_count > 0 then
		for _, data in pairs(self._stacks) do
			if data.expire_t then
				if not max_expire_t or data.expire_t > max_expire_t then
					max_t = data.t
					max_expire_t = data.expire_t
				end
				if not min_expire_t or data.expire_t < min_expire_t then
					min_t = data.t
					min_expire_t = data.expire_t
				end
			end
		end
		
		if min_expire_t then
			table.insert(self._expire_data, { t = min_t, expire_t = min_expire_t })
			if max_expire_t ~= min_expire_t then
				table.insert(self._expire_data, { t = max_t, expire_t = max_expire_t })
			end
		end
	end
	
	if #self._active_debuffs > 0 then
		for _, id in ipairs(self._active_debuffs) do
			local data = self._member_data[id]
			
			if data.expire_t and data.t then
				if not debuff_expire_t or data.expire_t > debuff_expire_t then
					debuff_t = data.t
					debuff_expire_t = data.expire_t
				end
			end
		end
		
		if debuff_expire_t then
			table.insert(self._expire_data, { t = debuff_t, expire_t = debuff_expire_t, is_debuff = true })
		end
	end
	
	for i, progress_bar in ipairs(self._progress_bars) do
		local expire_data = self._expire_data[i]
		progress_bar:panel():set_visible(expire_data and true or false)
		progress_bar:set_color(expire_data and expire_data.is_debuff and self.BUFF_COLORS.debuff or self._standard_color)
	end
	
	self:_set_icon_color((debuff_expire_t and (not min_expire_t or min_expire_t > debuff_expire_t)) and self._debuff_color or self._standard_color)
end

HUDList.BikerBuffItem = HUDList.BikerBuffItem or class(HUDList.TimedStackBuffItem)
function HUDList.BikerBuffItem:_stack_changed_clbk(...)
	HUDList.BikerBuffItem.super._stack_changed_clbk(self, ...)
	self:_set_icon_color((self._stack_count >= tweak_data.upgrades.wild_max_triggers_per_time) and self._debuff_color or self._standard_color)
end


HUDList.CompositeBuffItemBase = HUDList.CompositeBuffItemBase or class(HUDList.TimedBuffItem)
function HUDList.CompositeBuffItemBase:init(...)
	self._show_value = self._show_value_function
	HUDList.CompositeBuffItemBase.super.init(self, ...)
end

function HUDList.CompositeBuffItemBase:set_buff_active(...)
	HUDList.CompositeBuffItemBase.super.set_buff_active(self, ...)
	self:_update_value_text()
end

HUDList.DamageReductionBuffItem = HUDList.DamageReductionBuffItem or class(HUDList.CompositeBuffItemBase)
HUDList.DamageReductionBuffItem.EXCLUSIVE_BUFFS = {
	combat_medic_success = "combat_medic_interaction"
}
function HUDList.DamageReductionBuffItem._show_value_function(item, buffs)
	local v = 1
	for id, data in pairs(buffs) do
		local exclusive_buff = item.EXCLUSIVE_BUFFS[id]
		if not (exclusive_buff and buffs[exclusive_buff].active) then
			v = v * (data.active and data.value or 1)
		end
	end
	return v
end

function HUDList.DamageReductionBuffItem:_update_value_text()
	local str = tostring_trimmed(self._show_value(self, self._member_data), 2)
	self._value_text:set_text(string.format("x%s", str))
end

HUDList.DamageIncreaseBuffItem = HUDList.DamageIncreaseBuffItem or class(HUDList.CompositeBuffItemBase)
HUDList.DamageIncreaseBuffItem.WEAPON_REQUIREMENT = {
	include = {
		overkill = { shotgun = true, saw = true },
		berserker = { saw = true },
	},
	exclude = {
		overkill_aced = { shotgun = true, saw = true },
		berserker_aced = { saw = true },
	},
}
function HUDList.DamageIncreaseBuffItem:init(...)
	HUDList.DamageIncreaseBuffItem.super.init(self, ...)
	
	table.insert(self._listener_clbks, {
		name = "HUDList_DamageIncreaseBuffItem_weapon_equipped_listener",
		source = "player_weapon",
		event = { "equip" },
		clbk = callback(self, self, "_update_value_text"),
		data_only = true,
	})
end

function HUDList.DamageIncreaseBuffItem._show_value_function(item, buffs)
	local weapon = managers.player:equipped_weapon_unit()
	
	if alive(weapon) then
		local categories = weapon:base():weapon_tweak_data().categories
		local value = 1
		
		for buff, data in pairs(buffs) do
			local include_data = item.WEAPON_REQUIREMENT.include[buff]
			local exclude_data = item.WEAPON_REQUIREMENT.exclude[buff]
			local include = not include_data
			local exclude = false
			
			if include_data then
				for _, category in ipairs(categories) do
					include = include or include_data[category]
				end
			end
			
			if exclude_data then
				for _, category in ipairs(categories) do
					exclude = exclude or exclude_data[category]
				end
			end
			
			if include and not exclude then
				value = value * (data.active and data.value or 1)
			end
		end
		
		return value, tweak and tweak.ignore_damage_upgrades
	end
	
	return 1
end

function HUDList.DamageIncreaseBuffItem:_update_value_text()
	local value, ignores_upgrades = self._show_value(self, self._member_data)
	local str = tostring_trimmed(value, 2)
	
	local text = string.format("x%s", str)
	if ignores_upgrades then
		text = string.format("(%s)", text)
	end
	
	self._value_text:set_text(text)
end

HUDList.MeleeDamageIncreaseBuffItem = HUDList.MeleeDamageIncreaseBuffItem or class(HUDList.CompositeBuffItemBase)
function HUDList.MeleeDamageIncreaseBuffItem._show_value_function(item, buffs)
	local v = 1
	for id, data in pairs(buffs) do
		v = v * (data.active and data.value or 1)
	end
	return v
end

function HUDList.MeleeDamageIncreaseBuffItem:_update_value_text()
	local str = tostring_trimmed(self._show_value(self, self._member_data), 2)
	self._value_text:set_text(string.format("x%s", str))
end

HUDList.HealthRegenBuffItemBase = HUDList.HealthRegenBuffItemBase or class(HUDList.CompositeBuffItemBase)
function HUDList.HealthRegenBuffItemBase:_update_value_text()
	local str = tostring_trimmed(self._show_value(self, self._member_data) * 100, 5)
	self._value_text:set_text(string.format("+%s%%", str))
end


HUDList.PlayerActionItemBase = HUDList.PlayerActionItemBase or class(HUDList.EventItemBase)
HUDList.PlayerActionItemBase.MAP = {
	anarchist_armor_regeneration = {
		perks = {0, 0}, bundle_folder = "opera",
		priority = 15,
	},
	standard_armor_regeneration = {
		perks = {6, 0},
		class = "ArmorRegenActionItem",
		priority = 15,
	},
	melee_charge = {
		skills = { 4, 10 },
		priority = 15,
		title = "M.Charge",
		delay = 0.5,
		invert = true,
	},
	weapon_charge = {
		texture = "guis/dlcs/west/textures/pd2/blackmarket/icons/weapons/plainsrider",
		icon_rotation = 90,
		icon_ratio = 0.75,
		priority = 15,
		title = "W.Charge",
		delay = 0.5,
		invert = true,
	},
	reload = {
		skills_new = tweak_data.skilltree.skills.speedy_reload.icon_xy,
		priority = 15,
		title = "Reload",
		min_duration = 0.25,
	},
	interact = {
		skills_new = tweak_data.skilltree.skills.second_chances.icon_xy,
		priority = 15,
		title = "Interact",
		min_duration = 0.5,
	},
}	
function HUDList.PlayerActionItemBase:init(id, ppanel, action_data, item_data)
	HUDList.PlayerActionItemBase.super.init(self, id, ppanel, { h = ppanel:h(), w = ppanel:h() * 0.6, priority = -item_data.priority })
	
	self:set_fade_rate(100)
	self:set_move_rate(nil)
	
	self._min_duration = item_data.min_duration
	self._delay = item_data.delay
	self._standard_color = Color.white
	
	local icon_size = self._panel:w() - HUDList.BuffItemBase.PROGRESS_BAR_WIDTH * 3 - 5
	local texture, texture_rect = get_icon_data(item_data)
	
	self._icon = self._panel:bitmap({
		texture = texture,
		texture_rect = texture_rect,
		h = icon_size * 1/(item_data.icon_ratio or 1),
		w = icon_size * (item_data.icon_ratio or 1),
		color = self._standard_color,
		rotation = item_data.icon_rotation or 0,
	})
	self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
	
	self._bg = self._panel:rect({
		h = icon_size,
		w = icon_size,
		layer = -10,
		color = Color.black,
		alpha = 0.2,
	})
	self._bg:set_center(self._icon:center())
	
	self._progress_bar = PanelFrame:new(self._panel, { 
		bar_w = self.PROGRESS_BAR_WIDTH, 
		w = icon_size,
		h = icon_size,
		visible = true,
		invert_progress = item_data.invert,
	})
	self._progress_bar:panel():set_center(self._icon:center())
	
	local text_h = (self._panel:h() - icon_size) / 2
	self._value_text = self._panel:text({
		align = "center",
		vertical = "bottom",
		w = self._panel:w(),
		h = text_h,
		font = tweak_data.hud_corner.assault_font,
		font_size = 0.7 * text_h,
	})
	self._value_text:set_bottom(self._panel:h())
	
	if item_data.title then
		local h = (self._panel:h() - icon_size) / 2
		
		self._title_text = self._panel:text({
			text = item_data.title,
			align = "center",
			vertical = "top",
			w = self._panel:w(),
			h = h,
			font = tweak_data.hud_corner.assault_font,
			font_size = 0.7 * h,
		})
	end
	
	self:_set_duration_clbk(action_data)
	
	local listener_id = string.format("HUDList_buff_listener_%s", id)
	local events = {
		set_duration = callback(self, self, "_set_duration_clbk")
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "player_action", event = { event }, clbk = clbk, keys = { id }, data_only = true })
	end
end

function HUDList.PlayerActionItemBase:update(t, dt)
	if self._delayed_activation_t and t > self._delayed_activation_t then
		self._delayed_activation_t = nil
		self:enable("delayed_enable")
	end

	if self:visible() then
		if self._t and self._expire_t then
			local total = self._expire_t - self._t
			local current = t - self._t
			local remaining = total - current
			
			self._progress_bar:set_ratio(current/total)
			
			if remaining <= 0 then
				self._t = nil
				self._expire_t = nil
				self._value_text:set_text("")
			else
				self._value_text:set_text(format_time_string(remaining))
			end
		end
	end
	
	return HUDList.PlayerActionItemBase.super.update(self, t, dt)
end

function HUDList.PlayerActionItemBase:_set_duration_clbk(data)
	self._t = data.t
	self._expire_t = data.expire_t
	
	if self._t and self._expire_t then
		if self._delay then
			self._delayed_activation_t = self._t + self._delay
		end
		
		if self._min_duration and self._min_duration < (self._expire_t - self._t) then
			self:enable("insufficient_duration")
		end
	end
end


HUDList.ArmorRegenActionItem = HUDList.ArmorRegenActionItem or class(HUDList.PlayerActionItemBase)
function HUDList.ArmorRegenActionItem:init(...)
	HUDList.ArmorRegenActionItem.super.init(self, ...)
	
	local listener_id = "HUDList_armor_regen_tooth_and_claw_listener"
	local events = {
		--activate = callback(self, self, "_tooth_and_claw_event"),
		deactivate = callback(self, self, "_tooth_and_claw_event"),
		set_duration = callback(self, self, "_tooth_and_claw_event"),
	}
	
	for event, clbk in pairs(events) do
		table.insert(self._listener_clbks, { name = listener_id, source = "buff", event = { event }, clbk = clbk, keys = { "tooth_and_claw" } })
	end
end

function HUDList.ArmorRegenActionItem:_set_duration_clbk(...)
	HUDList.ArmorRegenActionItem.super._set_duration_clbk(self, ...)
	self._standard_expire_t = self._expire_t
	self._standard_t = self._t
	self:_check_max_expire_t()
end

function HUDList.ArmorRegenActionItem:_tooth_and_claw_event(event, id, data)
	self._forced_t = (event ~= "deactivate") and data.t or nil
	self._forced_expire_t = (event ~= "deactivate") and data.expire_t or nil
	self:_check_max_expire_t()
end

function HUDList.ArmorRegenActionItem:_check_max_expire_t()
	if self._expire_t and self._forced_expire_t then
		if self._forced_expire_t < self._standard_expire_t then
			self._expire_t = self._forced_expire_t
			self._t = self._forced_t
		end
	end
end
