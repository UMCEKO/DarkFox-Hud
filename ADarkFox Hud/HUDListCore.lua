printf = printf or function(...) end

function debug_print(...)
	local msg = "[HUDList]: " .. string.format(...)
	printf(msg)
	log(msg)
end

if RequiredScript == "lib/managers/hudmanagerpd2" then

	local _setup_player_info_hud_pd2_original = HUDManager._setup_player_info_hud_pd2
	local update_original = HUDManager.update

	function HUDManager:_setup_player_info_hud_pd2(...)
		_setup_player_info_hud_pd2_original(self, ...)
		
		if not managers.hudlist then
			managers.hudlist = HUDListManager:new(managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel)
			managers.hudlist:post_init()
		end
	end

	function HUDManager:update(t, dt, ...)
		managers.hudlist:update(t, dt)
		return update_original(self, t, dt, ...)
	end
	
	return
	
end


HUDListManager = HUDListManager or class()
function HUDListManager:init(hud_panel)
	self._hud_panel = hud_panel
	self._lists = {}
end

function HUDListManager:post_init()
	for _, clbk in ipairs(HUDListManager.post_init_events or {}) do
		clbk()
	end
	
	HUDListManager.post_init_events = nil
end

function HUDListManager:lists() return self._lists end
function HUDListManager:list(id) return self._lists[id] end

function HUDListManager:add_list(id, class, ...)
	if not self._lists[id] then
		local class = HUDListManager.get_class(class)
		self._lists[id] = class:new(id, self._hud_panel, ...)
		self._lists[id]:post_init(...)
	end
	
	return self._lists[id]
end

function HUDListManager:remove_list(id)
	if self._lists[id] then
		self._lists[id] = nil
	end
end

function HUDListManager:update(t, dt)
	for _, list in pairs(self._lists) do
		if list and list:active() then
			list:update(t, dt)
		end
	end
end

function HUDListManager.get_class(class)
	return type(class) == "string" and _G.HUDList[class] or class
end

function HUDListManager.add_post_init_event(clbk)
	if managers and managers.hudlist then
		clbk()
	else
		HUDListManager.post_init_events = HUDListManager.post_init_events or {}
		table.insert(HUDListManager.post_init_events, clbk)
	end
end


HUDList = HUDList or {}

HUDList.Base = HUDList.Base or class()
HUDList.Base._item_number = 0	--Unique ID for all items created, incremented in HUDList.Base:init()
function HUDList.Base:init(id, ppanel, data)
	local data = data or {}

	self._internal = {
		id = id,
		parent_panel = ppanel,
		priority = data.priority or 0,
		item_number = HUDList.Base._item_number,
		visible = false,
		active = false,
		inactive_reasons = { default = true },
		enabled = true,
		disabled_reasons = {},
		fade_rate = data.fade_rate or 4,
		move_rate = data.fade_rate or 100,
		temp_instant_positioning = true,
	}
	
	self._panel = self._internal.parent_panel:panel({
		name = id,
		visible = false,
		alpha = 0,
		w = data.w or 0,
		h = data.h or 0,
		x = data.x or 0,
		y = data.y or 0,
	})
	
	if data.bg then
		self._panel:rect({
			name = "bg",
			halign = "grow",
			valign = "grow",
			alpha = data.bg.alpha or 0.25,
			color = data.bg.color or Color.black,
			layer = -100,
		})
	end
	
	HUDList.Base._item_number = HUDList.Base._item_number + 1
end

function HUDList.Base:set_parent_list(plist)
	self._internal.parent_list = plist
end

function HUDList.Base:post_init(...)

end

function HUDList.Base:destroy()
	if alive(self._panel) and alive(self._internal.parent_panel) then
		self._internal.parent_panel:remove(self._panel)
	end
end

function HUDList.Base:delete(instant)
	self._internal.deleted = true
	
	if instant or not self._internal.fade_rate or not self:visible() then
		self:_visibility_state_changed(false)
	else
		self:set_active(false)
	end
end

function HUDList.Base:set_target_position(x, y, instant)
	if not alive(self._panel) then
		debug_print("Dead panel for item: %s", tostring(self:id()))
		return
	end

	if self._move_thread_x then
		self._panel:stop(self._move_thread_x)
		self._move_thread_x = nil
	end
	if self._move_thread_y then
		self._panel:stop(self._move_thread_y)
		self._move_thread_y = nil
	end

	if instant or self._internal.temp_instant_positioning or not self._internal.move_rate then
		self._panel:set_position(x, y)
	else
		local do_move = function(o, init, target, rate, move_func)
			over(math.abs(init - target) / rate, function(r)
				move_func(o, math.lerp(init, target, r))
			end)
			
			move_func(o, target)
		end
		
		self._move_thread_x = self._panel:animate(do_move, self._panel:x(), x, self._internal.move_rate, function(o, v) o:set_x(v) end)
		self._move_thread_y = self._panel:animate(do_move, self._panel:y(), y, self._internal.move_rate, function(o, v) o:set_y(v) end)
	end
	
	self._internal.temp_instant_positioning = nil
end

function HUDList.Base:set_target_alpha(alpha, instant)
	if not alive(self._panel) then
		debug_print("Dead panel for item: %s", tostring(self:id()))
		return
	end

	if self._fade_thread then
		self._panel:stop(self._fade_thread)
		self._fade_thread = nil
	end
	
	self:_set_visible(alpha > 0 or self._panel:alpha() > 0)
	
	if instant or not self._internal.fade_rate then
		self._panel:set_alpha(alpha)
		self:_set_visible(alpha > 0)
	else
		local do_fade = function(o, init, target, rate)
			over(math.abs(init - target) / rate, function(r)
				local a = math.lerp(init, target, r)
				o:set_alpha(a)
			end)
			
			o:set_alpha(target)
			self:_set_visible(target > 0)
		end
		
		self._fade_thread = self._panel:animate(do_fade, self._panel:alpha(), alpha, self._internal.fade_rate)
	end
end

function HUDList.Base:set_priority(priority)
	local priority = priority or 0
	
	if self._internal.priority ~= priority then
		self._internal.priority = priority
		
		if self._internal.parent_list then
			self._internal.parent_list:rearrange()
		end
	end
end

function HUDList.Base:set_active(state, reason)
	local state = not (state and true or false)
	local reason = reason or "default"
	
	self._internal.inactive_reasons[reason] = state and true or nil
	local active = not next(self._internal.inactive_reasons)
	
	if self._internal.active ~= active then
		self._internal.active = active
		self:set_target_alpha(active and 1 or 0)
	end
end

function HUDList.Base:set_enabled(state, reason)
	local state = not (state and true or false)
	local reason = reason or "default"
	
	self._internal.disabled_reasons[reason] = state and true or nil
	local enabled = not next(self._internal.disabled_reasons)
	
	if self._internal.enabled ~= enabled then
		self._internal.enabled = enabled
		self:_set_visible(self._panel:alpha() > 0)
	end
end

function HUDList.Base:update(t, dt)

end

function HUDList.Base:id() return self._internal.id end
function HUDList.Base:active() return self._internal.active end
function HUDList.Base:enabled() return self._internal.enabled end
function HUDList.Base:visible() return self._internal.visible end
function HUDList.Base:priority() return self._internal.priority end
function HUDList.Base:item_number() return self._internal.item_number end
function HUDList.Base:panel() return self._panel end

function HUDList.Base:set_fade_rate(rate) self._internal.fade_rate = rate end
function HUDList.Base:set_move_rate(rate) self._internal.move_rate = rate end
function HUDList.Base:activate(reason) self:set_active(true, reason) end
function HUDList.Base:deactivate(reason) self:set_active(false, reason) end
function HUDList.Base:enable(reason) self:set_enabled(true, reason) end
function HUDList.Base:disable(reason) self:set_enabled(false, reason) end

function HUDList.Base:_delete()
	if self._internal.parent_list then
		self._internal.parent_list:_delete_item(self._internal.id)
	else
		managers.hudlist:remove_list(self._internal.id)
	end
	
	self:destroy()
end

function HUDList.Base:_set_visible(state)
	local state = state and self:enabled() and true or false
	
	if self._internal.visible ~= state then
		self._internal.visible = state
		self._panel:set_visible(state)
		self:_visibility_state_changed(state)
	end
end

function HUDList.Base:_visibility_state_changed(state)
	if not state and self._internal.deleted then
		self:_delete()
	end
	
	if self._internal.parent_list then
		self._internal.parent_list:item_visibility_state_changed(self._internal.id, state)
	end
end


HUDList.ListBase = HUDList.ListBase or class(HUDList.Base)
function HUDList.ListBase:init(id, ppanel, data)
	HUDList.ListBase.super.init(self, id, ppanel, data)
	
	self:set_fade_rate(nil)
	
	self._item_margin = data and data.item_margin or 0
	self._max_items = data and data.max_items
	self._valign = data and data.valign
	self._halign = data and data.halign
	
	self._items = {}
	self._item_index = {}	--Read using self:_get_item_index() to ensure it updates if necessary before reading
	self._item_order = {}
	
	if data.static_item then
		local class = HUDListManager.get_class(data.static_item.class)
		self._static_item = class:new(
			"static",
			self._panel,
			unpack(data.static_item.data or {}))
	end
	
	if data.expansion_indicator then
		--TODO
		--self._expansion_indicator = HUDList.ExpansionIndicator:new("expansion_indicator", self._panel)
		--self._expansion_indicator:post_init()
	end
end

function HUDList.ListBase:post_init(...)
	HUDList.ListBase.super.post_init(self)
	
	if self._static_item then
		self._static_item:activate()
		self:_update_item_order()
	end
end

function HUDList.ListBase:destroy()
	self:clear_items(true)
	HUDList.ListBase.super.destroy(self)
end

function HUDList.ListBase:items() return self._items end
function HUDList.ListBase:item(id) return self._items[id] end
function HUDList.ListBase:static_item() return self._static_item end
function HUDList.ListBase:expansion_indicator() return self._expansion_indicator end

function HUDList.ListBase:update(t, dt)
	HUDList.ListBase.super.update(self, t, dt)
	
	for _, id in ipairs(self:_get_item_index()) do
		local item = self._items[id]
		
		if item and item:active() then
			item:update(t, dt)
		end
	end
	
	if self._internal.rearrange_needed then
		self:_update_item_order()
		self:_rearrange()
		self._internal.rearrange_needed = false
	end
end

function HUDList.ListBase:add_item(id, class, ...)
	if not self._items[id] then
		self._items[id] = HUDListManager.get_class(class):new(id, self._panel, ...)
		self._items[id]:set_parent_list(self)
		self._items[id]:post_init(...)
		self._index_update_needed = true
	else
		self._items[id]._internal.deleted = nil
	end
	
	return self._items[id]
end

function HUDList.ListBase:clear_items(instant)
	for _, id in ipairs(self:_get_item_index()) do
		self._items[id]:delete(instant)
	end
end

function HUDList.ListBase:remove_item(id, instant)
	if self._items[id] then
		self._items[id]:delete(instant)
	end
end

function HUDList.ListBase:_delete_item(id)
	self._items[id] = nil
	self._index_update_needed = true
end

function HUDList.ListBase:item_visibility_state_changed(id, state)
	self:rearrange()
	
	if state then
		self:set_active(true)
	else
		for id, item in pairs(self._items) do
			if item:visible() then
				return
			end
		end
		self:set_active(false)
	end
end

function HUDList.ListBase:rearrange()
	self._internal.rearrange_needed = true
end

function HUDList.ListBase:_get_item_index()
	if self._index_update_needed then
		self._item_index = {}
		self._index_update_needed = nil
		
		for id, item in pairs(self._items) do
			table.insert(self._item_index, id)
		end
	end
	
	return self._item_index
end

function HUDList.ListBase:_update_item_order()
	local new_order = {}
	
	for id, item in pairs(self._items) do
		local insert_at = #new_order + 1
		local new_data = { id = id, prio = item:priority(), no = item:item_number() }
		
		for i, data in ipairs(new_order) do
			if (data.prio < new_data.prio) or ((data.prio == new_data.prio) and (data.no > new_data.no)) then
				insert_at = i
				break
			end
		end
		
		table.insert(new_order, insert_at, new_data)
	end
	
	local total_items = #new_order
	local list_maxed = self._max_items and (total_items > self._max_items) or false
	
	self._item_order = {}
	for i, data in ipairs(new_order) do
		table.insert(self._item_order, data.id)
		self._items[data.id]:set_active(not list_maxed or i <= self._max_items, "list_full")
	end
	
	if self._expansion_indicator then
		self._expansion_indicator:set_active(list_maxed)
		if list_maxed then
			self._expansion_indicator:set_extra_count(total_items - self._max_items)
			table.insert(self._item_order, self._max_items + 1, self._expansion_indicator:id())
		end
	end
	
	if self._static_item and self._static_item:visible() then
		table.insert(self._item_order, 1, self._static_item:id())
	end
	
	return self._item_order
end


HUDList.HorizontalList = HUDList.HorizontalList or class(HUDList.ListBase)
function HUDList.HorizontalList:init(...)
	HUDList.HorizontalList.super.init(self, ...)
end

function HUDList.HorizontalList:_rearrange()
	local w = 0
	
	if self._halign == "center"  then
		local total_w = 0
		
		for _, id in ipairs(self._item_order) do
			local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
			
			if item:visible() then
				total_w = total_w + self._item_margin + item:panel():w()
			end
		end
		
		w = (self._panel:w() - total_w + self._item_margin) / 2
	end
	
	for _, id in ipairs(self._item_order) do
		local x, y
		local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
		local p = item:panel()
		
		if self._halign == "right" then
			x = self._panel:w() - w - p:w()
		else
			x = w
		end
		
		if self._valign == "top" then
			y = 0
		elseif self._valign == "bottom" then
			y = self._panel:h() - p:h()
		else
			y = (self._panel:h() - p:h()) / 2
		end
		
		item:set_target_position(x, y)
		
		if item:visible() then
			w = w + p:w() + self._item_margin
		end
	end
end


HUDList.VerticalList = HUDList.VerticalList or class(HUDList.ListBase)
function HUDList.VerticalList:init(...)
	HUDList.VerticalList.super.init(self, ...)
end

function HUDList.VerticalList:_rearrange()
	local h = 0

	if self._valign == "center"  then
		local total_h = 0
		
		for _, id in ipairs(self._item_order) do
			local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
			
			if item:visible() then
				total_h = total_h + self._item_margin + item:panel():h()
			end
		end
		
		h = (self._panel:h() - total_h + self._item_margin) / 2
	end
	
	for _, id in ipairs(self._item_order) do
		local x, y
		local item = self:item(id) or id == "static" and self._static_item or id == "expansion_indicator" and self._expansion_indicator
		local p = item:panel()
		
		if self._valign == "bottom" then
			y = self._panel:h() - h - p:h()
		else
			y = h
		end
		
		if self._halign == "left" then
			x = 0
		elseif self._halign == "right" then
			x = self._panel:w() - p:w()
		else
			x = (self._panel:w() - p:w()) / 2
		end
		
		item:set_target_position(x, y)
		
		if item:visible() then
			h = h + p:h() + self._item_margin
		end
	end
end
