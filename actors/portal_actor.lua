ActorClass("Portal", {
	open_gui_on_selected = true,
	homeworld = nil,
	transfer_interval = 5 * MINUTES,
	countdown_tick = 0
})

function Portal:Init()
	self.enabled = true
	game.onevent(HOMEWORLD_EVENTS.HOMEWORLD_ONLINE, function()
		StartCoroutine(self.DoPortalRoutine, self)
	end)
end

function Portal:OnLoad()
	self.enabled = true
	if self.homeworld.online then
		StartCoroutine(self.DoPortalRoutine, self)
	end
end

function Portal:OnDestroy()
	self.enabled = false
	DestroyRoutines(self)
end

function Portal:OnTick()
	self:UpdateGUI()
end

function Portal:DoPortalRoutine()
	while self.enabled do
		while self.countdown_tick > 0 do
			self.countdown_tick = self.countdown_tick - 1
			coroutine.yield()
		end

		local inventory = self.entity.getinventory(1)
		local contents = inventory.getcontents()
		for item, count in pairs(contents) do
			local remaining = count
			local chunk = 10
			while remaining > 0 do
				local take = math.min(chunk, remaining)
				inventory.remove{name = item, count = take}
				self.homeworld:InsertItem(item, take)
				remaining = remaining - take
				coroutine.yield()
			end
		end
		self.countdown_tick = self.transfer_interval
	end
end

function Portal:OpenGUI()
	if game.player.gui.left.portal_gui then
		game.player.gui.left.portal_gui.destroy()
	end

	GUI.PushParent(game.player.gui.left)
	self.gui = GUI.Frame("portal_gui", "Homeworld Portal", GUI.VERTICAL)
	GUI.PushParent(self.gui)
	GUI.Label("label", "Portal opens in:", "caption_label_style")
	GUI.Label("countdown", "00:00", "description_title_label_style")
	GUI.PopAll()
end

function Portal:CloseGUI()
	if self.gui then
		self.gui.destroy()
		self.gui = nil
	end
end

function Portal:UpdateGUI()
	if not self.gui then return end
	if self.homeworld.online then
		if self.countdown_tick >= 0 then
			local minutes = math.floor(self.countdown_tick / 3600)
			local seconds = math.floor((self.countdown_tick / 60) % 60)
			self.gui.label.caption = "Transfering contents in:"
			self.gui.countdown.caption = string.format("%02i:%02i", minutes, seconds)
		end
	else
		local minutes = math.floor(self.homeworld.grace_period / 3600)
		local seconds = math.floor((self.homeworld.grace_period / 60) % 60)
		self.gui.label.caption = "Portal opens in:"
		self.gui.countdown.caption = string.format("%02i:%02i", minutes, seconds)
	end
end