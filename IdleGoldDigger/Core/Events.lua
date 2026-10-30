local addonName, addon = ...

addon.Events = {}

local Events = addon.Events

-- Start the passive income ticker
function Events:StartTicker()
	if self.ticker then
		return
	end

	self.tickerElapsed = 0

	self.ticker = CreateFrame("Frame")

	self.ticker:SetScript("OnUpdate", function(_, elapsed)
		self.tickerElapsed = self.tickerElapsed + elapsed

		while self.tickerElapsed >= 1 do
			self.tickerElapsed = self.tickerElapsed - 1

			local income = addon.Mining:GetTotalRate()

addon.Diamonds:AwardGold(income)

IdleDB.lastSeen = time()

addon.UI:Refresh()
		end
	end)
end

-- Handle addon initialization
function Events:OnAddonLoaded(loadedAddon)
	if loadedAddon ~= addonName then
		return
	end

	-- Initialize and validate saved variables
	addon.Database:Validate()

	-- Apply offline progress
	local now = time()
	local earnings, cappedAway = addon.Offline:ApplyProgress(now)

	-- Build the main and minimized windows
	addon.UI.MainWindow:Build()
	addon.UI.MiniWindow:Build()

	-- Build options and apply saved font settings
	addon.UI.Options:Build()
	addon.UI.Options:ApplyFont()

	-- Update all displays
	addon.UI:Refresh()

	-- Start passive income
	self:StartTicker()

	-- Stop listening for ADDON_LOADED
	self.frame:UnregisterEvent("ADDON_LOADED")

	return earnings, cappedAway
end

-- Handle player logout
function Events:OnPlayerLogout()
	if not IdleDB then
		return
	end

	-- Save the main window dimensions when it is not minimized
	if addon.UI.window and not addon.UI.isMinimized then
		IdleDB.width = addon.UI.window:GetWidth()
		IdleDB.height = addon.UI.window:GetHeight()
	end

	-- Save the logout timestamp
	IdleDB.lastSeen = time()
end

-- Create and register the event frame
function Events:Initialize()
	if self.frame then
		return
	end

	self.frame = CreateFrame("Frame")

	self.frame:RegisterEvent("ADDON_LOADED")
	self.frame:RegisterEvent("PLAYER_LOGOUT")

	self.frame:SetScript("OnEvent", function(_, event, ...)
		if event == "ADDON_LOADED" then
			self:OnAddonLoaded(...)
		elseif event == "PLAYER_LOGOUT" then
			self:OnPlayerLogout()
		end
	end)
end
