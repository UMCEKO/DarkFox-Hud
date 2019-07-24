local re_old = VoteManager._restart_counter
function VoteManager:_restart_counter(...)
	re_old(self, ...)
	self._callback_counter = 0
end