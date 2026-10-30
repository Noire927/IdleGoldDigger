
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
        UI.upgradeText,
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

    n = math.floor(
        math.max(MIN_FONT, math.min(MAX_FONT, n)) + 0.5
    )

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

-- Build the options panel
function Options:Build()
    if optionsPanel then
        return
    end

    optionsPanel = CreateFrame("Frame", nil)
    optionsPanel.name = "Idle Gold Digger"

    -- Panel title
    local title = optionsPanel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontNormalLarge"
    )

    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Idle Gold Digger")

    -- Font size label
    fontLabel = optionsPanel:CreateFontString(
        nil,
        "ARTWORK",
        "GameFontHighlight"
    )

    fontLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
    fontLabel:SetText("Window size: " .. IdleDB.fontSize)

    -- Font size slider
    fontSlider = Helpers:MakeSlider(
        optionsPanel,
        "IdleGoldDiggerFontSlider"
    )

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

    -- Register the settings category
    if Settings and Settings.RegisterCanvasLayoutCategory then
        optionsCategory = Settings.RegisterCanvasLayoutCategory(
            optionsPanel,
            optionsPanel.name
        )

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
        local categoryID = optionsCategory.GetID
            and optionsCategory:GetID()
            or optionsCategory.ID

        Settings.OpenToCategory(categoryID)

    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    end
end
