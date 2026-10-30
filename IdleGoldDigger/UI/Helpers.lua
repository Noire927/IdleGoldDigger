
local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Helpers = {}

local Helpers = addon.UI.Helpers

-- Update the appearance and purchasing state of an icon button
function Helpers:UpdateButtonAppearance(button, cost, goldTint, forceDisabled)
    local canAfford = not forceDisabled and IdleDB.gold >= cost

    button:SetEnabled(canAfford)
    button:SetAlpha(canAfford and 1 or 0.5)
    button.icon:SetDesaturated(not canAfford)

    if canAfford and goldTint then
        button.icon:SetVertexColor(
            goldTint[1],
            goldTint[2],
            goldTint[3]
        )
    else
        button.icon:SetVertexColor(1, 1, 1)
    end
end

-- Set the displayed price of a button
function Helpers:SetButtonPrice(button, cost)
    button.priceText:SetText(cost())
end

-- Apply minimum and maximum window dimensions
function Helpers:SetBounds(window, minW, minH, maxW, maxH)
    if window.SetResizeBounds then
        window:SetResizeBounds(minW, minH, maxW, maxH)
    else
        window:SetMinResize(minW, minH)
        window:SetMaxResize(maxW, maxH)
    end
end

-- Create an icon button with a visible price
function Helpers:MakeIconButton(parent, texture, tooltip, onTooltip)
    local button = CreateFrame("Button", nil, parent)

    local iconSize = 36

    button:SetSize(iconSize, iconSize + 20)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(iconSize, iconSize)
    button.icon:SetPoint("TOP", button, "TOP", 0, 0)
    button.icon:SetTexture(texture)

    button:SetHighlightTexture(
        "Interface\\Buttons\\ButtonHilight-Square"
    )

    button.tooltipTitle = tooltip

    button.priceText = button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )

    button.priceText:SetPoint(
        "TOP",
        button.icon,
        "BOTTOM",
        0,
        -2
    )

    button.priceText:SetTextColor(1, 0.82, 0)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)

        if onTooltip then
            onTooltip(self, GameTooltip)
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Create a slider with a fallback for missing templates
function Helpers:MakeSlider(parent, name)
    local ok, slider = pcall(
        CreateFrame,
        "Slider",
        name,
        parent,
        "OptionsSliderTemplate"
    )

    if ok and slider then
        return slider
    end

    slider = CreateFrame("Slider", name, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(16)

    slider:SetThumbTexture(
        "Interface\\Buttons\\UI-SliderBar-Button-Horizontal"
    )

    local track = slider:CreateTexture(nil, "BACKGROUND")

    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(4)

    return slider
end
