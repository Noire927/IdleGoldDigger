local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.MainWindow = {}

local MainWindow = addon.UI.MainWindow
local UI = addon.UI
local Config = addon.Config
local Helpers = UI.Helpers

-- Main window settings
local ICON_SIZE = 36
local BUTTON_GAP = 12

local MAX_W, MAX_H = 500, 400
local MIN_W, MIN_H = 200, 180

local ICONS = {
	miner = "Interface\\Icons\\Trade_Mining",
	upgrade = "Interface\\Icons\\Trade_Mining",
	drill = "Interface\\Icons\\Trade_Engineering",
	drillUpgrade = "Interface\\Icons\\Trade_Engineering",
	crew = "Interface\\Icons\\INV_Misc_Gear_01",
}

-- Save the main window position
function MainWindow:SavePosition()
	local window = UI.window

	if not window then
		return
	end

	local point, _, _, x, y = window:GetPoint(1)

	if point then
		IdleDB.point = point
		IdleDB.x = x or 0
		IdleDB.y = y or 0
	end
end

-- Reset the main window position
function MainWindow:ResetPosition()
	local window = UI.window

	if not window then
		return
	end

	window:ClearAllPoints()
	window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	self:SavePosition()
end

-- Lock or unlock window movement
function MainWindow:SetPositionLocked(locked)
	locked = not not locked

	IdleDB.lockWindowPosition = locked

	if UI.window then
		UI.window:SetMovable(not locked)
	end
end

-- Resize the main window to fit its contents
function MainWindow:Fit(snap)
	local window = UI.window

	if not window or UI.isMinimized then
		return
	end

	local textWidth = math.max(
		UI.goldText:GetStringWidth(),
		UI.diamondText:GetStringWidth(),
		UI.minerText:GetStringWidth(),
		UI.transmuteText:GetStringWidth()
	)

	local buttonWidth = ICON_SIZE * 5 + BUTTON_GAP * 4
	local needW = math.ceil(math.max(textWidth, buttonWidth) + 40)

	local textHeight = UI.goldText:GetStringHeight()
		+ UI.diamondText:GetStringHeight()
		+ UI.minerText:GetStringHeight()
		+ UI.transmuteText:GetStringHeight()
		+ 30

	local buttonHeight = ICON_SIZE + 24
	local needH = math.ceil(textHeight + buttonHeight + 32)

	needW = math.min(MAX_W, math.max(MIN_W, needW))
	needH = math.min(MAX_H, math.max(MIN_H, needH))

	Helpers:SetBounds(window, needW, needH, MAX_W, MAX_H)

	local curW, curH = window:GetWidth(), window:GetHeight()

	if snap then
		window:SetSize(needW, needH)
	elseif curW < needW or curH < needH then
		window:SetSize(math.max(curW, needW), math.max(curH, needH))
	end

	IdleDB.width = window:GetWidth()
	IdleDB.height = window:GetHeight()
end

-- Create the main window
function MainWindow:Build()
	if UI.window then
		return
	end

	local window = CreateFrame("Frame", "IdleGoldDiggerFrame", UIParent, "BasicFrameTemplateWithInset")

	UI.window = window

	-- Save when the main window is closed
	window:HookScript("OnHide", function()
		if not UI.isMinimized then
			IdleDB.windowState = "hidden"
		end
	end)

	-- Restore saved size and position
	window:SetSize(IdleDB.width or 240, IdleDB.height or 240)

	window:SetPoint(IdleDB.point or "CENTER", UIParent, IdleDB.point or "CENTER", IdleDB.x or 0, IdleDB.y or 0)

	window:SetMovable(not IdleDB.lockWindowPosition)
	window:SetResizable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")

	-- Window movement
	window:SetScript("OnDragStart", function(self)
		if not IdleDB.lockWindowPosition then
			self:StartMoving()
		end
	end)

	window:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		MainWindow:SavePosition()
	end)

	-- Resize grip
	local grip = CreateFrame("Button", nil, window)

	window.resizeGrip = grip

	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -4, 4)

	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	grip:SetScript("OnMouseDown", function()
		window:StartSizing("BOTTOMRIGHT")
	end)

	grip:SetScript("OnMouseUp", function()
		window:StopMovingOrSizing()

		IdleDB.width = window:GetWidth()
		IdleDB.height = window:GetHeight()

		self:Fit(false)
	end)

	-- Minimize button
	local minimizeBtn = CreateFrame("Button", nil, window)

	UI.minimizeBtn = minimizeBtn

	minimizeBtn:SetSize(20, 20)

	local closeBtn = _G["IdleGoldDiggerFrameCloseButton"]

	if closeBtn then
		minimizeBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
	else
		minimizeBtn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -28, -6)
	end

	minimizeBtn:SetNormalFontObject("GameFontNormal")
	minimizeBtn:SetHighlightFontObject("GameFontHighlight")
	minimizeBtn:SetText("-")
	minimizeBtn:SetFrameLevel(window:GetFrameLevel() + 5)

	minimizeBtn:SetScript("OnClick", function()
		if UI.MiniWindow then
			UI.MiniWindow:Toggle()
		end
	end)

	-- Gold display
	UI.goldText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")

	UI.goldText:SetPoint("TOP", 0, -30)

	-- Diamond counter
	UI.diamondText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	UI.diamondText:SetPoint("TOP", UI.goldText, "BOTTOM", 0, -6)
	UI.diamondText:SetTextColor(0.3, 0.85, 1)

	UI.diamondText:EnableMouse(true)

	UI.diamondText:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Diamonds", 0.3, 0.85, 1)

		GameTooltip:AddLine("Earn diamonds by reaching lifetime gold milestones.", 1, 1, 1, true)

		GameTooltip:AddLine("Lifetime gold: " .. addon.Formatting:FormatWholeGold(IdleDB.lifetimeGold), 1, 0.82, 0)

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Diamond milestones:", 1, 1, 1)

		for i, milestone in ipairs(Config.DIAMOND_MILESTONES) do
			if i <= IdleDB.runDiamonds then
				GameTooltip:AddLine("|cff00ff00[X] " .. addon.Formatting:FormatWholeGold(milestone) .. " - Earned|r")
			elseif i == IdleDB.runDiamonds + 1 then
				GameTooltip:AddLine("|cffffff00" .. addon.Formatting:FormatWholeGold(milestone) .. " - NEXT|r")
			else
				GameTooltip:AddLine("|cff999999" .. addon.Formatting:FormatWholeGold(milestone) .. "|r")
			end
		end

		local nextMilestone = Config.DIAMOND_MILESTONES[IdleDB.runDiamonds + 1]

		GameTooltip:AddLine(" ")

		if nextMilestone then
			local remaining = math.max(0, nextMilestone - IdleDB.lifetimeGold)

			GameTooltip:AddLine("Next diamond in: " .. addon.Formatting:FormatWholeGold(remaining), 0.3, 0.85, 1)
		else
			GameTooltip:AddLine("All diamond milestones completed!", 0, 1, 0)
		end

		GameTooltip:Show()
	end)

	UI.diamondText:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Miner display
	UI.minerText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	UI.minerText:SetPoint("TOP", UI.diamondText, "BOTTOM", 0, -6)

	-- Drill display
	UI.transmuteText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	UI.transmuteText:SetPoint("TOP", UI.minerText, "BOTTOM", 0, -6)

	-- Manual mining button
	UI.buyBtn = Helpers:MakeIconButton(window, ICONS.miner, "Mine Gold", function()
		local reward = addon.Mining:GetManualMiningGold()
		local multiplier = Config.PICKAXE_BONUS ^ IdleDB.pickaxeLevel

		GameTooltip:AddLine("Click to manually mine gold.", 1, 1, 1, true)

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Gold per click: +" .. string.format("%.2f", reward), 0, 1, 0)

		GameTooltip:AddLine("Pickaxe multiplier: x" .. string.format("%.2f", multiplier), 1, 0.82, 0)
	end)

	UI.buyBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE * 2 + BUTTON_GAP * 2), 12)

	UI.buyBtn:SetScript("OnClick", function()
		addon.Purchases:MineGold()
		UI:Refresh()
	end)

	-- Drill purchase button
	UI.transmuteBtn = Helpers:MakeIconButton(window, ICONS.drill, "Buy Drill", function()
		local drillCount = IdleDB.transmuters
		local drillRate = addon.Mining:GetDrillRate()
		local drillCost = addon.Mining:GetDrillCost()

		GameTooltip:AddLine("Purchase a drill to generate passive gold.", 1, 1, 1, true)

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Owned drills: " .. drillCount, 1, 1, 1)

		GameTooltip:AddLine("Total production: +" .. string.format("%.2f", drillRate) .. " gold/s", 0, 1, 0)

		GameTooltip:AddLine("Next drill cost: " .. addon.Formatting:FormatWholeGold(drillCost), 1, 0.82, 0)
	end)

	UI.transmuteBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE + BUTTON_GAP), 12)

	UI.transmuteBtn:SetScript("OnClick", function()
		addon.Purchases:BuyDrill()
		UI:Refresh()
	end)

	-- Drill production upgrade button
	UI.drillUpgradeBtn = Helpers:MakeIconButton(window, ICONS.drillUpgrade, "Upgrade Drills", function()
		local level = IdleDB.drillUpgradeLevel or 0
		local currentMultiplier = Config.DRILL_PRODUCTION_MULTIPLIER ^ level
		local nextMultiplier = Config.DRILL_PRODUCTION_MULTIPLIER ^ (level + 1)
		local cost = addon.Mining:GetDrillUpgradeCost()

		GameTooltip:AddLine("Upgrade all drills to increase their gold production.", 1, 1, 1, true)

		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Upgrade level: " .. level, 1, 1, 1)

		GameTooltip:AddLine("Current multiplier: x" .. string.format("%.2f", currentMultiplier), 0, 1, 0)

		GameTooltip:AddLine("Next multiplier: x" .. string.format("%.2f", nextMultiplier), 0, 1, 0)

		GameTooltip:AddLine("Upgrade cost: " .. addon.Formatting:FormatWholeGold(cost), 1, 0.82, 0)
	end)

	UI.drillUpgradeBtn:SetPoint("BOTTOM", window, "BOTTOM", ICON_SIZE + BUTTON_GAP, 12)

	UI.drillUpgradeBtn:SetScript("OnClick", function()
		addon.Purchases:BuyDrillUpgrade()
		UI:Refresh()
	end)

	-- Pickaxe upgrade button
	UI.pickaxeBtn = Helpers:MakeIconButton(window, ICONS.upgrade, "Upgrade Pickaxe", function()
		local level = IdleDB.pickaxeLevel
		local multiplier = Config.PICKAXE_BONUS ^ level
		local nextMultiplier = Config.PICKAXE_BONUS ^ (level + 1)
		local cost = addon.Mining:GetPickaxeCost()

		GameTooltip:AddLine("Upgrade your pickaxe to earn more gold per click.", 1, 1, 1, true)

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Current level: " .. level, 1, 1, 1)

		GameTooltip:AddLine("Current multiplier: x" .. string.format("%.2f", multiplier), 0, 1, 0)

		GameTooltip:AddLine("Next multiplier: x" .. string.format("%.2f", nextMultiplier), 0, 1, 0)

		GameTooltip:AddLine("Upgrade cost: " .. addon.Formatting:FormatWholeGold(cost), 1, 0.82, 0)
	end)

	UI.pickaxeBtn:SetPoint("BOTTOM", window, "BOTTOM", 0, 12)

	UI.pickaxeBtn:SetScript("OnClick", function()
		addon.Purchases:BuyPickaxe()
		UI:Refresh()
	end)

	-- Automated Mining Crew button
	UI.crewBtn = Helpers:MakeIconButton(window, ICONS.crew, "Automated Mining Crew", function()
		local level = addon.Offline:GetCrewLevel()
		local hours = addon.Offline:GetTimeLimit() / 3600
		local maxLevel = Config.MAX_CREW_LEVEL
		local maxed = addon.Offline:IsCrewMaxed()

		GameTooltip:AddLine("Allows you to earn gold while you're away.", 1, 1, 1, true)

		GameTooltip:AddLine("Offline earnings are based on your gold per second.", 1, 1, 1, true)

		GameTooltip:AddLine("Each upgrade increases your offline time limit by 1 hour.", 0.8, 0.8, 0.8, true)

		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Upgrade level: " .. level .. "/" .. maxLevel, 1, 1, 1)

		GameTooltip:AddLine("Offline limit: " .. hours .. " hours", 0, 1, 0)

		if maxed then
			GameTooltip:AddLine("Maximum level reached!", 0, 1, 0)
		else
			local nextCost = addon.Mining:GetCrewCost()
			local nextHours = hours + 1

			GameTooltip:AddLine(" ")

			GameTooltip:AddLine("Next offline limit: " .. nextHours .. " hours", 0, 1, 0)

			GameTooltip:AddLine("Upgrade cost: " .. addon.Formatting:FormatWholeGold(nextCost), 1, 0.82, 0)
		end
	end)

	UI.crewBtn:SetPoint("BOTTOM", window, "BOTTOM", ICON_SIZE * 2 + BUTTON_GAP * 2, 12)

	UI.crewBtn:SetScript("OnClick", function()
		addon.Purchases:BuyCrew()
		UI:Refresh()
	end)

	return window
end
