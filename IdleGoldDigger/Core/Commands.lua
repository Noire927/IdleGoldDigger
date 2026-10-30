local addonName, addon = ...

addon.Commands = {}

local Commands = addon.Commands

-- Reset the current mining progress
function Commands:ResetProgress()
	IdleDB.gold = 100
	IdleDB.miners = 0
	IdleDB.pickaxeLevel = 0
	IdleDB.transmuters = 0
	IdleDB.lastSeen = time()
	IdleDB.offlineUpgradeLevel = 0

	-- Refresh the interface after resetting
	addon.UI:Refresh()

	print("|cff00ccffIdle Gold Digger:|r Progress has been reset.")
end

-- Handle slash command input
function Commands:Handle(message)
	local command, argument = message:match("^(%S*)%s*(.-)$")

	command = string.lower(command or "")
	argument = argument or ""

	-- Open or toggle the addon window
	if command == "" then
		if addon.UI.isMinimized then
			local miniWindow = addon.UI.miniWindow

			if miniWindow then
				miniWindow:SetShown(not miniWindow:IsShown())
			end
		else
			local window = addon.UI.window

			if window then
				window:SetShown(not window:IsShown())
			end
		end

	-- Open the main window
	elseif command == "open" then
		if addon.UI.isMinimized then
			addon.UI.MiniWindow:Restore()
		elseif addon.UI.window then
			addon.UI.window:Show()
		end

	-- Open the options panel
	elseif command == "options" or command == "settings" then
		addon.UI.Options:Open()

	-- Change the font size
	elseif command == "font" then
		local fontSize = tonumber(argument)

		if fontSize then
			addon.UI.Options:SetFontSize(fontSize)
		else
			print("|cff00ccffIdle Gold Digger:|r " .. "Usage: /gameidle font <8-24>")
		end

	-- Reset mining progress
	elseif command == "reset" then
		self:ResetProgress()

	-- Test diamond milestone progression
	elseif command == "testdiamond" then
		addon.Diamonds:AwardGold(10000)
		addon.UI:Refresh()

	-- Unknown command
	else
		print(
			"|cff00ccffIdle Gold Digger:|r "
				.. "Unknown command. Available commands: "
				.. "open, options, font, reset, testdiamond"
		)
	end
end

-- Register slash commands
function Commands:Initialize()
	SLASH_IDLEGOLDDIGGER1 = "/gameidle"

	SlashCmdList["IDLEGOLDDIGGER"] = function(message)
		Commands:Handle(message)
	end
end
