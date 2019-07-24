	PlayerStandard.EQUIPMENT_PRESS_INTERRUPT = true --Use equipment key "G" to stop interacting (default false)
	local MIN_TIMER_DURATION = 5 --Interaction duration (in seconds) for the toggle behavior to activate (default 0)

local PlayerStandard__check_action_interact_original = PlayerStandard._check_action_interact

function PlayerStandard:_check_action_interact(t, input)
	local interrupt_key_press = input.btn_interact_press
		if PlayerStandard.EQUIPMENT_PRESS_INTERRUPT then
			interrupt_key_press = input.btn_use_item_press
		end
	if interrupt_key_press and self:_interacting() then
		self:_interupt_action_interact()
		return false
	elseif input.btn_interact_release and self._interact_params then
		if self._interact_params.timer >= MIN_TIMER_DURATION then
			return false
		end
	end

	return PlayerStandard__check_action_interact_original(self, t, input)
end 

if not _PlayerStandard__check_use_item then _PlayerStandard__check_use_item = PlayerStandard._check_use_item end
function PlayerStandard:_check_use_item( t, input )
    if input.btn_use_item_press and self:is_deploying() then
        self:_interupt_action_use_item()
        return false
    elseif input.btn_use_item_release then
        return false
    end
    
    return _PlayerStandard__check_use_item(self, t, input)
end

