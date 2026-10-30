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
	crew = "Interface\\Icons\\INV_Misc_Gear_01",
}

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
		UI.transmuteText:GetStringWidth(),
		UI.upgradeText:GetStringWidth()
	)

	local buttonWidth = ICON_SIZE * 4 + BUTTON_GAP * 3
	local needW = math.ceil(math.max(textWidth, buttonWidth) + 40)

	local textHeight = UI.goldText:GetStringHeight()
		+ UI.diamondText:GetStringHeight()
		+ UI.minerText:GetStringHeight()
		+ UI.transmuteText:GetStringHeight()
		+ UI.upgradeText:GetStringHeight()
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

	window:SetSize(IdleDB.width or 240, IdleDB.height or 240)
	window:SetPoint("CENTER")
	window:SetMovable(true)
	window:SetResizable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")

	window:SetScript("OnDragStart", window.StartMoving)

	window:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
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

	-- Pickaxe upgrade display
	UI.upgradeText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	UI.upgradeText:SetPoint("TOP", UI.transmuteText, "BOTTOM", 0, -6)

	-- Miner purchase button
	UI.buyBtn = Helpers:MakeIconButton(window, ICONS.miner, "Buy Miner")

	UI.buyBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE * 1.5 + BUTTON_GAP * 1.5), 12)

	UI.buyBtn:SetScript("OnClick", function()
		addon.Purchases:BuyMiner()
		UI:Refresh()
	end)

	-- Pickaxe upgrade button
	UI.pickaxeBtn = Helpers:MakeIconButton(window, ICONS.upgrade, "Upgrade Pickaxe")

	UI.pickaxeBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE + BUTTON_GAP) / 2, 12)

	UI.pickaxeBtn:SetScript("OnClick", function()
		addon.Purchases:BuyPickaxe()
		UI:Refresh()
	end)

	-- Drill purchase button
	UI.transmuteBtn = Helpers:MakeIconButton(window, ICONS.drill, "Buy Drill")

	UI.transmuteBtn:SetPoint("BOTTOM", window, "BOTTOM", (ICON_SIZE + BUTTON_GAP) / 2, 12)

	UI.transmuteBtn:SetScript("OnClick", function()
		addon.Purchases:BuyDrill()
		UI:Refresh()
	end)

	-- Automated Mining Crew button
	UI.crewBtn = Helpers:MakeIconButton(window, ICONS.crew, "Automated Mining Crew", function()
		local level = addon.Offline:GetCrewLevel()
		local hours = addon.Offline:GetTimeLimit() / 3600

		GameTooltip:AddLine("Your crew mines gold while you're away.", 1, 1, 1, true)

		GameTooltip:AddLine("Offline progress: " .. hours .. " / " .. Config.MAX_CREW_LEVEL .. " hours", 0.2, 1, 0.2)

		GameTooltip:AddLine("Each upgrade adds 1 hour.", 0.8, 0.8, 0.8)

		GameTooltip:AddLine("Upgrade level: " .. level .. "/" .. Config.MAX_CREW_LEVEL, 0.8, 0.8, 0.8)
	end)

	UI.crewBtn:SetPoint("BOTTOM", window, "BOTTOM", ICON_SIZE * 1.5 + BUTTON_GAP * 1.5, 12)

	UI.crewBtn:SetScript("OnClick", function()
		addon.Purchases:BuyCrew()
		UI:Refresh()
	end)

	return window
end
