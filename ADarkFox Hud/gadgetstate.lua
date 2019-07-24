if RequiredScript == "lib/units/weapons/newraycastweaponbase" then

	local on_equip_original = NewRaycastWeaponBase.on_equip
	local toggle_gadget_original = NewRaycastWeaponBase.toggle_gadget

	function NewRaycastWeaponBase:on_equip(...)
		self:set_gadget_on(self._stored_gadget_on or 0, false)
		return on_equip_original(self, ...)
	end

	function NewRaycastWeaponBase:toggle_gadget(...)
		if toggle_gadget_original(self, ...) then 
			self._stored_gadget_on = self._gadget_on
			return true
		end
	end

elseif RequiredScript == "lib/units/weapons/shotgun/newshotgunbase" then

	local on_equip_original = NewShotgunBase.on_equip
	
	function NewShotgunBase:on_equip(...)
		self:set_gadget_on(self._stored_gadget_on or 0, false)
		return on_equip_original(self, ...)
	end

end
