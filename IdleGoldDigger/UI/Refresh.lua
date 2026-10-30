
local addonName, addon = ...

addon.UI = addon.UI or {}

local UI = addon.UI
local Helpers = UI.Helpers
local Config = addon.Config

local PICKAXE_TINT = { 1, 0.85, 0.35 }

-- Refresh all UI displays and purchase buttons
function UI:Refresh()
    if not self.window or not IdleDB or not self.buyBtn then
        return
    end

    -- Gold display
    self.goldText:SetText(
        string.format(
            "%s  (+%.1f gold/s)",
            addon.Formatting:FormatGold(IdleDB.gold),
            addon.Mining:GetTotalRate()
        )
    )

    -- Diamond display
    self.diamondText:SetText(
        "|TInterface\\Icons\\INV_Misc_Gem_Diamond_01:18:18:0:0|t "
            .. IdleDB.diamonds
    )

    -- Miner display
    self.minerText:SetText(
        string.format(
            "Miners: %d  (+%.2f/s)",
            IdleDB.miners,
            addon.Mining:GetMinerRate()
        )
    )

    -- Drill display
    self.transmuteText:SetText(
        string.format(
            "Drills: %d  (+%.2f/s)",
            IdleDB.transmuters,
            addon.Mining:GetDrillRate()
        )
    )

    -- Pickaxe display
    self.upgradeText:SetText(
        string.format(
            "Pickaxe level: %d  (x%.2f miner production)",
            IdleDB.pickaxeLevel,
            Config.PICKAXE_BONUS ^ IdleDB.pickaxeLevel
        )
    )

    -- Calculate purchase costs
    local minerCost = addon.Mining:GetMinerCost()
    local pickaxeCost = addon.Mining:GetPickaxeCost()
    local drillCost = addon.Mining:GetDrillCost()
    local crewCost = addon.Mining:GetCrewCost()

    -- Update displayed prices
    Helpers:SetButtonPrice(self.buyBtn, function()
        return minerCost
    end)

    Helpers:SetButtonPrice(self.pickaxeBtn, function()
        return pickaxeCost
    end)

    Helpers:SetButtonPrice(self.transmuteBtn, function()
        return drillCost
    end)

    -- Automated Mining Crew price
    local crewMaxed = addon.Offline:IsCrewMaxed()

    if crewMaxed then
        self.crewBtn.priceText:SetText("MAX")
    else
        Helpers:SetButtonPrice(self.crewBtn, function()
            return crewCost
        end)
    end

    -- Update purchase button appearance
    Helpers:UpdateButtonAppearance(self.buyBtn, minerCost)

    Helpers:UpdateButtonAppearance(
        self.pickaxeBtn,
        pickaxeCost,
        PICKAXE_TINT
    )

    Helpers:UpdateButtonAppearance(self.transmuteBtn, drillCost)

    Helpers:UpdateButtonAppearance(
        self.crewBtn,
        crewCost,
        nil,
        crewMaxed
    )

    -- Update minimized gold display
    if self.isMinimized and self.miniGoldText then
        self.miniGoldText:SetText(
            addon.Formatting:FormatWholeGold(IdleDB.gold)
        )

        self.MiniWindow:Fit()
    end

    -- Fit the main window around its contents
    self.MainWindow:Fit(false)
end
