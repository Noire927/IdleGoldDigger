local addonName, addon = ...

addon.Commands = {}

local Commands = addon.Commands

-- Display available commands
function Commands:PrintHelp()
	print("|cff00ccffIdle Gold Digger - Commands|r")
	print("|cffffd700/gameidle|r - Show or hide the game window")
	print("|cffffd700/gameidle play|r - Open the main window")
	print("|cffffd700/gameidle options|r - Open addon settings")
	print("|cffffd700/gameidle font <8-24>|r - Change text size")
	print("|cffffd700/gameidle reset|r - Reset current mining progress")
	print("|cffffd700/gameidle help|r - Display this command list")
end

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

				if miniWindow:IsShown() then
					IdleDB.windowState = "minimized"
				else
					IdleDB.windowState = "hidden"
				end
			end
		else
			local window = addon.UI.window

			if window then
				window:SetShown(not window:IsShown())

				if window:IsShown() then
					IdleDB.windowState = "open"
				else
					IdleDB.windowState = "hidden"
				end
			end
		end

	-- Open the main window
	elseif command == "play" then
		if addon.UI.isMinimized then
			addon.UI.MiniWindow:Restore()
		elseif addon.UI.window then
			addon.UI.window:Show()
			IdleDB.windowState = "open"
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

	-- Display available commands
	elseif command == "cmd" or command == "help" then
		self:PrintHelp()

	-- Reset mining progress
	elseif command == "reset" then
		self:ResetProgress()

	-- Test diamond milestone progression
	elseif command == "testdiamond" then
		addon.Diamonds:AwardGold(10000)
		addon.UI:Refresh()

	-- Unknown command
	else
		print("|cff00ccffIdle Gold Digger:|r " .. "Unknown command. Type /gameidle help for help.")
	end
end

-- Register slash commands
function Commands:Initialize()
	SLASH_IDLEGOLDDIGGER1 = "/gameidle"

	SlashCmdList["IDLEGOLDDIGGER"] = function(message)
		Commands:Handle(message)
	end
end
