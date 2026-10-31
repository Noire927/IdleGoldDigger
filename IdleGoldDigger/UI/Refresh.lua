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
		string.format("%s  (+%.1f gold/s)", addon.Formatting:FormatGold(IdleDB.gold), addon.Mining:GetTotalRate())
	)

	-- Diamond display
	self.diamondText:SetText("|TInterface\\Icons\\INV_Misc_Gem_Diamond_01:18:18:0:0|t " .. IdleDB.diamonds)

	-- Manual mining display
	self.minerText:SetText(string.format("Manual mining: +%.2f gold/click", addon.Mining:GetManualMiningGold()))

	-- Drill display
	local drillUpgradeLevel = IdleDB.drillUpgradeLevel or 0
	local drillMultiplier = Config.DRILL_PRODUCTION_MULTIPLIER ^ drillUpgradeLevel

	self.transmuteText:SetText(
		string.format(
			"Drills: %d  (+%.2f/s, x%.2f upgrade)",
			IdleDB.transmuters,
			addon.Mining:GetDrillRate(),
			drillMultiplier
		)
	)

	-- Calculate purchase costs
	local pickaxeCost = addon.Mining:GetPickaxeCost()
	local drillCost = addon.Mining:GetDrillCost()
	local drillUpgradeCost = addon.Mining:GetDrillUpgradeCost()
	local crewCost = addon.Mining:GetCrewCost()

	-- Manual mining button label
	if self.buyBtn.priceText then
		self.buyBtn.priceText:SetText("Mine")
	end

	-- Update displayed prices
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
	Helpers:UpdateButtonAppearance(self.pickaxeBtn, pickaxeCost, PICKAXE_TINT)

	Helpers:UpdateButtonAppearance(self.transmuteBtn, drillCost)

	-- Drill Upgrade button
	if self.drillUpgradeBtn then
		Helpers:SetButtonPrice(self.drillUpgradeBtn, function()
			return drillUpgradeCost
		end)

		Helpers:UpdateButtonAppearance(self.drillUpgradeBtn, drillUpgradeCost)
	end

	Helpers:UpdateButtonAppearance(self.crewBtn, crewCost, nil, crewMaxed)

	-- Update minimized gold display
	if self.isMinimized and self.miniGoldText then
		self.miniGoldText:SetText(addon.Formatting:FormatWholeGold(IdleDB.gold))

		self.MiniWindow:Fit()
	end

	-- Fit the main window around its contents
	self.MainWindow:Fit(false)
end
