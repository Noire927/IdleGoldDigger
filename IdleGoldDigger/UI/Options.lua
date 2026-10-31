local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Options = {}

local Options = addon.UI.Options
local UI = addon.UI
local Helpers = UI.Helpers

-- Font settings
local FONT_PATH = "Fonts\\FRIZQT__.TTF"

local MIN_FONT = 8
local MAX_FONT = 24

-- Options panel controls
local optionsPanel
local optionsCategory
local fontSlider
local fontLabel

-- Reset confirmation dialog
StaticPopupDialogs["IDLE_GOLD_DIGGER_RESET"] = {
	text = "Are you sure you want to reset all progress?\n\nThis will erase your gold, diamonds, upgrades and lifetime earnings.",
	button1 = "Confirm",
	button2 = "Cancel",
	OnAccept = function()
		addon.Commands:ResetProgress()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- Apply the saved font size to all UI text
function Options:ApplyFont()
	if not IdleDB then
		return
	end

	local size = IdleDB.fontSize

	local fontObjects = {
		UI.goldText,
		UI.diamondText,
		UI.minerText,
		UI.transmuteText,
		UI.miniGoldText,
	}

	for _, fontObject in ipairs(fontObjects) do
		if fontObject then
			fontObject:SetFont(FONT_PATH, size, "")
		end
	end
end

-- Change and save the font size
function Options:SetFontSize(n)
	n = tonumber(n)

	if not n or not IdleDB then
		return
	end

	n = math.floor(math.max(MIN_FONT, math.min(MAX_FONT, n)) + 0.5)

	IdleDB.fontSize = n

	self:ApplyFont()

	-- Update the interface if it has been built
	if UI.window then
		UI:Refresh()

		if UI.isMinimized then
			UI.MiniWindow:Fit()
		else
			UI.MainWindow:Fit(true)
		end
	end

	-- Update slider and label
	if fontSlider then
		if fontSlider:GetValue() ~= n then
			fontSlider:SetValue(n)
		end
	end

	if fontLabel then
		fontLabel:SetText("Window size: " .. n)
	end
end

-- Create a gameplay checkbox
local function MakeGameplayCheckbox(parent, label, setting, anchor, relativeTo, offsetY, onClick)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")

	checkbox:SetPoint("TOPLEFT", anchor, relativeTo, 0, offsetY)
	checkbox:SetChecked(IdleDB[setting])

	checkbox.text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
	checkbox.text:SetText(label)

	checkbox:SetScript("OnClick", function(self)
		local checked = self:GetChecked()

		IdleDB[setting] = checked

		if onClick then
			onClick(checked)
		end
	end)

	return checkbox
end

-- Build the options panel
function Options:Build()
	if optionsPanel then
		return
	end

	optionsPanel = CreateFrame("Frame", nil)
	optionsPanel.name = "Idle Gold Digger"

	-- Panel title
	local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Idle Gold Digger")

	-- Font size label
	fontLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")

	fontLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
	fontLabel:SetText("Window size: " .. IdleDB.fontSize)

	-- Font size slider
	fontSlider = Helpers:MakeSlider(optionsPanel, "IdleGoldDiggerFontSlider")

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
			self:SetFontSize(value)
		end
	end)

	-- Gameplay heading
	local gameplayTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	gameplayTitle:SetPoint("TOPLEFT", fontSlider, "BOTTOMLEFT", 0, -32)
	gameplayTitle:SetText("Gameplay")

	-- Gameplay settings
	local offlineCheckbox = MakeGameplayCheckbox(
		optionsPanel,
		"Offline earnings notifications",
		"notifyOffline",
		gameplayTitle,
		"BOTTOMLEFT",
		-12
	)

	local diamondCheckbox = MakeGameplayCheckbox(
		optionsPanel,
		"Diamond milestone notifications",
		"notifyDiamonds",
		offlineCheckbox,
		"BOTTOMLEFT",
		-4
	)

	local lockCheckbox = MakeGameplayCheckbox(
		optionsPanel,
		"Lock window position",
		"lockWindowPosition",
		diamondCheckbox,
		"BOTTOMLEFT",
		-4,
		function(checked)
			UI.MainWindow:SetPositionLocked(checked)
		end
	)

	-- Reset window position button
	local resetPositionButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")

	resetPositionButton:SetSize(160, 26)
	resetPositionButton:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 0, -24)
	resetPositionButton:SetText("Reset Position")

	resetPositionButton:SetScript("OnClick", function()
		UI.MainWindow:ResetPosition()
	end)

	-- Reset progress button
	local resetButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")

	resetButton:SetSize(160, 26)
	resetButton:SetPoint("TOPLEFT", resetPositionButton, "BOTTOMLEFT", 0, -8)
	resetButton:SetText("Reset Progress")

	resetButton:SetScript("OnClick", function()
		StaticPopup_Show("IDLE_GOLD_DIGGER_RESET")
	end)

	-- Register the settings category
	if Settings and Settings.RegisterCanvasLayoutCategory then
		optionsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)

		Settings.RegisterAddOnCategory(optionsCategory)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(optionsPanel)
	end
end

-- Open the options panel
function Options:Open()
	if not optionsPanel then
		return
	end

	if optionsCategory and Settings and Settings.OpenToCategory then
		local categoryID = optionsCategory.GetID and optionsCategory:GetID() or optionsCategory.ID

		Settings.OpenToCategory(categoryID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
	end
end
