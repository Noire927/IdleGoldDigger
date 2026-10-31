local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")

local window
local miniWindow
local goldText, diamondText, minerText, transmuteText, upgradeText
local miniGoldText
local buyBtn, pickaxeBtn, transmuteBtn, crewBtn
local minimizeBtn
local miniRestoreBtn
local isMinimized = false
local optionsPanel, optionsCategory, fontSlider, fontLabel

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local MIN_FONT, MAX_FONT, DEFAULT_FONT = 8, 24, 12

local MAX_W, MAX_H = 500, 400
local MIN_W, MIN_H = 200, 180
local ICON_SIZE = 36
local BUTTON_GAP = 12
local MINI_HEIGHT = 32

local ICONS = {
	miner = "Interface\\Icons\\Trade_Mining",
	upgrade = "Interface\\Icons\\Trade_Mining",
	drill = "Interface\\Icons\\Trade_Engineering",
	crew = "Interface\\Icons\\INV_Misc_Gear_01",
	gold = "Interface\\Icons\\INV_Misc_Coin_01",
}

-- Currency settings
local COPPER_PER_SILVER = 100
local SILVER_PER_GOLD = 100
local COPPER_PER_GOLD = COPPER_PER_SILVER * SILVER_PER_GOLD

-- Economy settings
local MINER_BASE_COST = 10
local MINER_COST_MULTIPLIER = 1.15
local MINER_RATE = 0.5

local PICKAXE_BASE_COST = 50
local PICKAXE_COST_MULTIPLIER = 1.65
local PICKAXE_BONUS = 1.35

local DRILL_BASE_COST = 100
local DRILL_COST_MULTIPLIER = 1.55
local DRILL_RATE = 2

-- Automated Mining Crew settings
local CREW_BASE_COST = 10000
local CREW_COST_MULTIPLIER = 2
local MAX_CREW_LEVEL = 4
local OFFLINE_SECONDS_PER_LEVEL = 60 * 60

local PICKAXE_TINT = { 1, 0.85, 0.35 }

-- Diamond milestone settings
local DIAMOND_MILESTONES = {
	10000,
	50000,
	250000,
	1000000,
	5000000,
}
-- Validate saved data before using it
local function ValidateSavedData()
	IdleDB = IdleDB or {}

	local function GetNumber(key, default, minimum, maximum)
		local value = tonumber(IdleDB[key])

		if not value or value ~= value or value == math.huge or value == -math.huge then
			value = default
		end

		value = math.max(minimum, value)

		if maximum then
			value = math.min(maximum, value)
		end

		return value
	end

	IdleDB.gold = GetNumber("gold", 100, 0)
	IdleDB.lifetimeGold = GetNumber("lifetimeGold", 0, 0)

	IdleDB.diamonds = math.floor(GetNumber("diamonds", 0, 0))

	IdleDB.runDiamonds = math.floor(GetNumber("runDiamonds", 0, 0, #DIAMOND_MILESTONES))

	IdleDB.runDiamonds = math.min(IdleDB.runDiamonds, IdleDB.diamonds, #DIAMOND_MILESTONES)

	IdleDB.miners = math.floor(GetNumber("miners", 0, 0))
	IdleDB.pickaxeLevel = math.floor(GetNumber("pickaxeLevel", 0, 0))
	IdleDB.transmuters = math.floor(GetNumber("transmuters", 0, 0))

	IdleDB.offlineUpgradeLevel = math.floor(GetNumber("offlineUpgradeLevel", 0, 0, MAX_CREW_LEVEL))

	IdleDB.fontSize = math.floor(GetNumber("fontSize", DEFAULT_FONT, MIN_FONT, MAX_FONT))

	IdleDB.width = GetNumber("width", 240, MIN_W, MAX_W)
	IdleDB.height = GetNumber("height", 240, MIN_H, MAX_H)

	IdleDB.lastSeen = math.floor(GetNumber("lastSeen", time(), 0))

	if IdleDB.miniX ~= nil then
		IdleDB.miniX = GetNumber("miniX", 0, 0)
	end

	if IdleDB.miniY ~= nil then
		IdleDB.miniY = GetNumber("miniY", 0, 0)
	end
end

-- Costs
local function MinerCost()
	return math.floor(MINER_BASE_COST * MINER_COST_MULTIPLIER ^ IdleDB.miners)
end

local function PickaxeCost()
	return math.floor(PICKAXE_BASE_COST * PICKAXE_COST_MULTIPLIER ^ IdleDB.pickaxeLevel)
end

local function DrillCost()
	return math.floor(DRILL_BASE_COST * DRILL_COST_MULTIPLIER ^ IdleDB.transmuters)
end

-- Automated Mining Crew upgrade cost
local function CrewCost()
	return math.floor(CREW_BASE_COST * CREW_COST_MULTIPLIER ^ IdleDB.offlineUpgradeLevel)
end

-- Maximum offline time allowed by the crew upgrade
local function GetOfflineTimeLimit()
	local level = math.max(0, math.min(MAX_CREW_LEVEL, IdleDB.offlineUpgradeLevel or 0))

	return level * OFFLINE_SECONDS_PER_LEVEL
end

-- Income
local function MinerRate()
	return IdleDB.miners * MINER_RATE * PICKAXE_BONUS ^ IdleDB.pickaxeLevel
end

local function DrillRate()
	return IdleDB.transmuters * DRILL_RATE
end

local function Rate()
	return MinerRate() + DrillRate()
end
-- Check and award diamond milestones
local function CheckDiamondMilestones()
	while IdleDB.runDiamonds < #DIAMOND_MILESTONES do
		local nextMilestone = DIAMOND_MILESTONES[IdleDB.runDiamonds + 1]

		if IdleDB.lifetimeGold < nextMilestone then
			break
		end

		IdleDB.runDiamonds = IdleDB.runDiamonds + 1
		IdleDB.diamonds = IdleDB.diamonds + 1

		print("|cff00ccffIdle Gold Digger:|r " .. "You earned a diamond! Total diamonds: " .. IdleDB.diamonds)
	end
end

-- Award production gold and track lifetime earnings
local function AwardGold(amount)
	if not amount or amount <= 0 or amount == math.huge or amount ~= amount then
		return
	end

	IdleDB.gold = IdleDB.gold + amount
	IdleDB.lifetimeGold = IdleDB.lifetimeGold + amount

	CheckDiamondMilestones()
end
-- Format gold, silver, and copper with WoW coin icons
local function FormatGold(amount)
	local totalCopper = math.floor(amount * COPPER_PER_GOLD + 0.5)

	local gold = math.floor(totalCopper / COPPER_PER_GOLD)
	local silver = math.floor((totalCopper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
	local copper = totalCopper % COPPER_PER_SILVER

	local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
	local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
	local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

	if gold >= 1000000 then
		return string.format("%.2fM", gold / 1000000)
			.. goldIcon
			.. " "
			.. silver
			.. silverIcon
			.. " "
			.. copper
			.. copperIcon
	elseif gold >= 1000 then
		return string.format("%.2fK", gold / 1000)
			.. goldIcon
			.. " "
			.. silver
			.. silverIcon
			.. " "
			.. copper
			.. copperIcon
	end

	return gold .. goldIcon .. " " .. silver .. silverIcon .. " " .. copper .. copperIcon
end

-- Format whole gold with the WoW gold coin icon
local function FormatWholeGold(amount)
	local gold = math.floor(amount)
	local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"

	if gold >= 1000000 then
		return string.format("%.2fM", gold / 1000000) .. goldIcon
	elseif gold >= 1000 then
		return string.format("%.2fK", gold / 1000) .. goldIcon
	end

	return gold .. goldIcon
end

-- Update the appearance and purchasing state of an icon button
local function UpdateButtonAppearance(button, cost, goldTint, forceDisabled)
	local canAfford = not forceDisabled and IdleDB.gold >= cost

	button:SetEnabled(canAfford)
	button:SetAlpha(canAfford and 1 or 0.5)
	button.icon:SetDesaturated(not canAfford)

	if canAfford and goldTint then
		button.icon:SetVertexColor(goldTint[1], goldTint[2], goldTint[3])
	else
		button.icon:SetVertexColor(1, 1, 1)
	end
end

-- Window sizing
local function SetBounds(minW, minH)
	minW = math.min(MAX_W, math.max(MIN_W, minW))
	minH = math.min(MAX_H, math.max(MIN_H, minH))

	if window.SetResizeBounds then
		window:SetResizeBounds(minW, minH, MAX_W, MAX_H)
	else
		window:SetMinResize(minW, minH)
		window:SetMaxResize(MAX_W, MAX_H)
	end
end

-- Resize the main window to fit its contents
local function FitWindow(snap)
	if not window or isMinimized then
		return
	end

	local textWidth = math.max(
		goldText:GetStringWidth(),
		diamondText:GetStringWidth(),
		minerText:GetStringWidth(),
		transmuteText:GetStringWidth(),
		upgradeText:GetStringWidth()
	)

	local buttonWidth = ICON_SIZE * 4 + BUTTON_GAP * 3
	local needW = math.ceil(math.max(textWidth, buttonWidth) + 40)

	local textHeight = goldText:GetStringHeight()
		+ diamondText:GetStringHeight()
		+ minerText:GetStringHeight()
		+ transmuteText:GetStringHeight()
		+ upgradeText:GetStringHeight()
		+ 30

	local buttonHeight = ICON_SIZE + 24
	local needH = math.ceil(textHeight + buttonHeight + 32)

	needW = math.min(MAX_W, math.max(MIN_W, needW))
	needH = math.min(MAX_H, math.max(MIN_H, needH))

	SetBounds(needW, needH)

	local curW, curH = window:GetWidth(), window:GetHeight()

	if snap then
		window:SetSize(needW, needH)
	elseif curW < needW or curH < needH then
		window:SetSize(math.max(curW, needW), math.max(curH, needH))
	end

	IdleDB.width = window:GetWidth()
	IdleDB.height = window:GetHeight()
end

-- Resize the minimized bar to fit its currency text
local function FitMiniWindow()
	if not miniWindow or not miniGoldText then
		return
	end

	local textWidth = miniGoldText:GetStringWidth()
	local screenWidth = UIParent:GetWidth()

	local needW = math.ceil(textWidth + 40)
	local needH = math.max(MINI_HEIGHT, IdleDB.fontSize + 16)

	needW = math.min(needW, screenWidth)
	miniWindow:SetSize(needW, needH)

	miniGoldText:SetWidth(math.min(textWidth + 4, needW - 40))
end

-- Create an icon button with a visible price
local function MakeIconButton(parent, texture, tooltip)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(ICON_SIZE, ICON_SIZE + 20)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetSize(ICON_SIZE, ICON_SIZE)
	button.icon:SetPoint("TOP", button, "TOP", 0, 0)
	button.icon:SetTexture(texture)

	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

	button.tooltipTitle = tooltip

	button.priceText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	button.priceText:SetPoint("TOP", button.icon, "BOTTOM", 0, -2)

	button.priceText:SetTextColor(1, 0.82, 0)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)

		if self == crewBtn then
			local level = IdleDB.offlineUpgradeLevel
			local hours = GetOfflineTimeLimit() / 3600

			GameTooltip:AddLine("Your crew mines gold while you're away.", 1, 1, 1, true)

			GameTooltip:AddLine("Offline progress: " .. hours .. " / " .. MAX_CREW_LEVEL .. " hours", 0.2, 1, 0.2)

			GameTooltip:AddLine("Each upgrade adds 1 hour.", 0.8, 0.8, 0.8)

			GameTooltip:AddLine("Upgrade level: " .. level .. "/" .. MAX_CREW_LEVEL, 0.8, 0.8, 0.8)
		end

		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return button
end

local function SetButtonPrice(button, cost)
	button.priceText:SetText(cost())
end

-- Refresh the display and purchase buttons
local function Refresh()
	if not window or not IdleDB then
		return
	end

	goldText:SetText(string.format("%s  (+%.1f gold/s)", FormatGold(IdleDB.gold), Rate()))

	diamondText:SetText("|TInterface\\Icons\\INV_Misc_Gem_Diamond_01:18:18:0:0|t " .. IdleDB.diamonds)

	minerText:SetText(string.format("Miners: %d  (+%.2f/s)", IdleDB.miners, MinerRate()))

	transmuteText:SetText(string.format("Drills: %d  (+%.2f/s)", IdleDB.transmuters, DrillRate()))

	upgradeText:SetText(
		string.format(
			"Pickaxe level: %d  (x%.2f miner production)",
			IdleDB.pickaxeLevel,
			PICKAXE_BONUS ^ IdleDB.pickaxeLevel
		)
	)

	-- Update prices
	SetButtonPrice(buyBtn, MinerCost)
	SetButtonPrice(pickaxeBtn, PickaxeCost)
	SetButtonPrice(transmuteBtn, DrillCost)

	local crewMaxed = IdleDB.offlineUpgradeLevel >= MAX_CREW_LEVEL

	if crewMaxed then
		crewBtn.priceText:SetText("MAX")
	else
		SetButtonPrice(crewBtn, CrewCost)
	end

	-- Update button appearance
	UpdateButtonAppearance(buyBtn, MinerCost())

	UpdateButtonAppearance(pickaxeBtn, PickaxeCost(), PICKAXE_TINT)

	UpdateButtonAppearance(transmuteBtn, DrillCost())

	UpdateButtonAppearance(crewBtn, CrewCost(), nil, crewMaxed)

	-- Keep the minimized currency counter gold-only
	if isMinimized and miniGoldText then
		miniGoldText:SetText(FormatWholeGold(IdleDB.gold))
		FitMiniWindow()
	end

	FitWindow(false)
end

-- Apply the saved font size
local function ApplyFont()
	local size = IdleDB.fontSize

	goldText:SetFont(FONT_PATH, size, "")
	minerText:SetFont(FONT_PATH, size, "")
	transmuteText:SetFont(FONT_PATH, size, "")
	upgradeText:SetFont(FONT_PATH, size, "")
	diamondText:SetFont(FONT_PATH, size, "")
	miniGoldText:SetFont(FONT_PATH, size, "")
end

local function SetFontSize(n)
	n = math.floor(math.max(MIN_FONT, math.min(MAX_FONT, n)) + 0.5)

	IdleDB.fontSize = n

	ApplyFont()
	Refresh()

	if isMinimized then
		FitMiniWindow()
	else
		FitWindow(true)
	end

	if fontSlider then
		if fontSlider:GetValue() ~= n then
			fontSlider:SetValue(n)
		end

		fontLabel:SetText("Window size: " .. n)
	end
end

-- Slider fallback
local function MakeSlider(parent, name)
	local ok, slider = pcall(CreateFrame, "Slider", name, parent, "OptionsSliderTemplate")

	if ok and slider then
		return slider
	end

	slider = CreateFrame("Slider", name, parent)
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(16)

	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(0, 0, 0, 0.6)
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	track:SetHeight(4)

	return slider
end

-- Build the options panel
local function BuildOptionsPanel()
	optionsPanel = CreateFrame("Frame", nil)
	optionsPanel.name = "Idle Gold Digger"

	local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Idle Gold Digger")

	fontLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")

	fontLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)

	fontLabel:SetText("Window size: " .. IdleDB.fontSize)

	fontSlider = MakeSlider(optionsPanel, "IdleGoldDiggerFontSlider")

	fontSlider:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -16)

	fontSlider:SetWidth(220)
	fontSlider:SetMinMaxValues(MIN_FONT, MAX_FONT)
	fontSlider:SetValueStep(1)

	if fontSlider.SetObeyStepOnDrag then
		fontSlider:SetObeyStepOnDrag(true)
	end

	if fontSlider.Low then
		fontSlider.Low:SetText(MIN_FONT)
	end

	if fontSlider.High then
		fontSlider.High:SetText(MAX_FONT)
	end

	if fontSlider.Text then
		fontSlider.Text:SetText("")
	end

	fontSlider:SetValue(IdleDB.fontSize)

	fontSlider:SetScript("OnValueChanged", function(_, value)
		value = math.floor(value + 0.5)

		if value ~= IdleDB.fontSize then
			SetFontSize(value)
		end
	end)

	if Settings and Settings.RegisterCanvasLayoutCategory then
		optionsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)

		Settings.RegisterAddOnCategory(optionsCategory)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(optionsPanel)
	end
end

-- Open the options panel
local function OpenOptions()
	if optionsCategory and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(optionsCategory.GetID and optionsCategory:GetID() or optionsCategory.ID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
	end
end

-- Purchases
local function BuyMiner()
	local cost = MinerCost()

	if IdleDB.gold < cost then
		return
	end

	IdleDB.gold = IdleDB.gold - cost
	IdleDB.miners = IdleDB.miners + 1

	Refresh()
end

local function BuyPickaxe()
	local cost = PickaxeCost()

	if IdleDB.gold < cost then
		return
	end

	IdleDB.gold = IdleDB.gold - cost
	IdleDB.pickaxeLevel = IdleDB.pickaxeLevel + 1

	Refresh()
end

local function BuyDrill()
	local cost = DrillCost()

	if IdleDB.gold < cost then
		return
	end

	IdleDB.gold = IdleDB.gold - cost
	IdleDB.transmuters = IdleDB.transmuters + 1

	Refresh()
end

-- Upgrade the Automated Mining Crew
local function BuyCrewUpgrade()
	if IdleDB.offlineUpgradeLevel >= MAX_CREW_LEVEL then
		return
	end

	local cost = CrewCost()

	if IdleDB.gold < cost then
		return
	end

	IdleDB.gold = IdleDB.gold - cost
	IdleDB.offlineUpgradeLevel = IdleDB.offlineUpgradeLevel + 1

	Refresh()
end

-- Minimize to a compact title bar
local function MinimizeWindow()
	if not window or isMinimized then
		return
	end

	-- Save the full dimensions before hiding the window
	IdleDB.width = window:GetWidth()
	IdleDB.height = window:GetHeight()

	isMinimized = true

	goldText:Hide()
	minerText:Hide()
	transmuteText:Hide()
	upgradeText:Hide()

	crewBtn:Hide()
	buyBtn:Hide()
	pickaxeBtn:Hide()
	transmuteBtn:Hide()
	diamondText:Hide()
	window.resizeGrip:Hide()

	miniGoldText:SetText(FormatWholeGold(IdleDB.gold))
	miniGoldText:Show()

	miniWindow:Show()
	FitMiniWindow()
	window:Hide()
end

-- Restore the full window
local function RestoreWindow()
	if not window or not isMinimized then
		return
	end

	isMinimized = false

	miniWindow:Hide()
	window:Show()

	goldText:Show()
	minerText:Show()
	transmuteText:Show()
	upgradeText:Show()

	crewBtn:Show()
	buyBtn:Show()
	pickaxeBtn:Show()
	transmuteBtn:Show()
	diamondText:Show()
	window.resizeGrip:Show()

	window:SetSize(IdleDB.width or 240, IdleDB.height or 240)

	minimizeBtn:SetText("-")

	FitWindow(false)
end

-- Main window
local function BuildUI()
	window = CreateFrame("Frame", "IdleGoldDiggerFrame", UIParent, "BasicFrameTemplateWithInset")

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

		FitWindow(false)
	end)

	-- Minimize button beside the close button
	minimizeBtn = CreateFrame("Button", nil, window)
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
		if isMinimized then
			RestoreWindow()
		else
			MinimizeWindow()
		end
	end)

	-- Separate compact window shown when minimized
	miniWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

	miniWindow:SetSize(240, MINI_HEIGHT)

	if IdleDB.miniX ~= nil and IdleDB.miniY ~= nil then
		local x = math.max(0, math.min(IdleDB.miniX, UIParent:GetWidth() - miniWindow:GetWidth()))

		local y = math.max(0, math.min(IdleDB.miniY, UIParent:GetHeight() - miniWindow:GetHeight()))

		miniWindow:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	else
		miniWindow:SetPoint("CENTER")
	end

	miniWindow:SetFrameStrata("DIALOG")
	miniWindow:SetMovable(true)
	miniWindow:EnableMouse(true)
	miniWindow:RegisterForDrag("LeftButton")

	miniWindow:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})

	miniWindow:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	miniWindow:SetBackdropBorderColor(0.6, 0.45, 0.15, 1)

	miniWindow:SetClampedToScreen(true)

	miniWindow:SetScript("OnDragStart", miniWindow.StartMoving)

	miniWindow:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()

		IdleDB.miniX = self:GetLeft()
		IdleDB.miniY = self:GetBottom()
	end)

	-- Gold-only currency text for minimized overlay
	miniGoldText = miniWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	miniGoldText:SetPoint("CENTER", miniWindow, "CENTER", -8, 0)

	miniGoldText:SetTextColor(1, 0.82, 0)
	miniGoldText:Hide()

	-- Restore button on the minimized bar
	miniRestoreBtn = CreateFrame("Button", nil, miniWindow)
	miniRestoreBtn:SetSize(20, 20)
	miniRestoreBtn:SetPoint("RIGHT", miniWindow, "RIGHT", -6, 0)
	miniRestoreBtn:SetFrameLevel(miniWindow:GetFrameLevel() + 2)

	miniRestoreBtn:SetNormalFontObject("GameFontNormal")
	miniRestoreBtn:SetHighlightFontObject("GameFontHighlight")
	miniRestoreBtn:SetText("+")

	miniRestoreBtn:SetScript("OnClick", function()
		RestoreWindow()
	end)

	miniWindow:Hide()

	-- Gold text
	goldText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")

	goldText:SetPoint("TOP", 0, -30)

	-- Diamond counter
	diamondText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	diamondText:SetPoint("TOP", goldText, "BOTTOM", 0, -6)

	diamondText:SetTextColor(0.3, 0.85, 1)
	-- Diamond tooltip with milestone progress
	diamondText:EnableMouse(true)

	diamondText:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Diamonds", 0.3, 0.85, 1)

		GameTooltip:AddLine("Earn diamonds by reaching lifetime gold milestones.", 1, 1, 1, true)

		GameTooltip:AddLine("Lifetime gold: " .. FormatWholeGold(IdleDB.lifetimeGold), 1, 0.82, 0)

		GameTooltip:AddLine(" ")

		GameTooltip:AddLine("Diamond milestones:", 1, 1, 1)

		for i, milestone in ipairs(DIAMOND_MILESTONES) do
			if i <= IdleDB.runDiamonds then
				GameTooltip:AddLine("|cff00ff00[X] " .. FormatWholeGold(milestone) .. " - Earned|r")
			elseif i == IdleDB.runDiamonds + 1 then
				GameTooltip:AddLine("|cffffff00" .. FormatWholeGold(milestone) .. " - NEXT|r")
			else
				GameTooltip:AddLine("|cff999999" .. FormatWholeGold(milestone) .. "|r")
			end
		end

		local nextMilestone = DIAMOND_MILESTONES[IdleDB.runDiamonds + 1]

		GameTooltip:AddLine(" ")

		if nextMilestone then
			local remaining = math.max(0, nextMilestone - IdleDB.lifetimeGold)

			GameTooltip:AddLine("Next diamond in: " .. FormatWholeGold(remaining), 0.3, 0.85, 1)
		else
			GameTooltip:AddLine("All diamond milestones completed!", 0, 1, 0)
		end

		GameTooltip:Show()
	end)

	diamondText:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Miner text
	minerText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	minerText:SetPoint("TOP", diamondText, "BOTTOM", 0, -6)

	-- Drill text
	transmuteText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	transmuteText:SetPoint("TOP", minerText, "BOTTOM", 0, -6)

	-- Pickaxe upgrade text
	upgradeText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	upgradeText:SetPoint("TOP", transmuteText, "BOTTOM", 0, -6)

	-- Horizontal icon toolbar
	buyBtn = MakeIconButton(window, ICONS.miner, "Buy Miner")

	buyBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE * 1.5 + BUTTON_GAP * 1.5), 12)

	buyBtn:SetScript("OnClick", BuyMiner)

	pickaxeBtn = MakeIconButton(window, ICONS.upgrade, "Upgrade Pickaxe")

	pickaxeBtn:SetPoint("BOTTOM", window, "BOTTOM", -(ICON_SIZE + BUTTON_GAP) / 2, 12)

	pickaxeBtn:SetScript("OnClick", BuyPickaxe)

	transmuteBtn = MakeIconButton(window, ICONS.drill, "Buy Drill")

	transmuteBtn:SetPoint("BOTTOM", window, "BOTTOM", (ICON_SIZE + BUTTON_GAP) / 2, 12)

	transmuteBtn:SetScript("OnClick", BuyDrill)

	-- Automated Mining Crew button
	crewBtn = MakeIconButton(window, ICONS.crew, "Automated Mining Crew")

	crewBtn:SetPoint("BOTTOM", window, "BOTTOM", ICON_SIZE * 1.5 + BUTTON_GAP * 1.5, 12)

	crewBtn:SetScript("OnClick", BuyCrewUpgrade)

	ApplyFont()
end

-- Addon initialization
f:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGOUT" then
		if IdleDB then
			IdleDB.lastSeen = time()

			-- Preserve full dimensions when logging out while restored
			if window and not isMinimized then
				IdleDB.width = window:GetWidth()
				IdleDB.height = window:GetHeight()
			end
		end

		return
	end

	if name ~= "IdleGoldDigger" then
		return
	end

	ValidateSavedData()

	-- Offline progress, limited by Automated Mining Crew level
	local away = math.max(0, time() - IdleDB.lastSeen)
	local cappedAway = math.min(away, GetOfflineTimeLimit())

	AwardGold(cappedAway * Rate())
	IdleDB.lastSeen = time()

	BuildUI()
	BuildOptionsPanel()
	Refresh()

	-- Passive income ticker
	C_Timer.NewTicker(1, function()
		AwardGold(Rate())
		IdleDB.lastSeen = time()

		Refresh()
	end)
end)

-- Slash commands
SLASH_IDLEGOLDDIGGER1 = "/gameidle"

local function ResetProgress()
	IdleDB.gold = 100
	IdleDB.miners = 0
	IdleDB.pickaxeLevel = 0
	IdleDB.transmuters = 0
	IdleDB.lastSeen = time()
	IdleDB.offlineUpgradeLevel = 0

	Refresh()

	print("|cffffcc00Idle Gold Digger:|r Progress has been reset!")
end

SlashCmdList["IDLEGOLDDIGGER"] = function(msg)
	local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.*)$")

	if cmd == "open" then
		if isMinimized then
			RestoreWindow()
		elseif window then
			window:Show()
		end
	elseif cmd == "options" or cmd == "settings" then
		OpenOptions()
	elseif cmd == "font" then
		local n = tonumber(arg)

		if n then
			SetFontSize(n)
		else
			print("Idle Gold Digger: use /gameidle font <" .. MIN_FONT .. "-" .. MAX_FONT .. ">")
		end
	elseif cmd == "reset" then
		ResetProgress()

	-- Testing command: awards 10,000 gold to test diamond milestones
	elseif cmd == "testdiamond" then
		AwardGold(10000)
		Refresh()
	else
		if isMinimized then
			miniWindow:SetShown(not miniWindow:IsShown())
		elseif window then
			window:SetShown(not window:IsShown())
		end
	end
end
