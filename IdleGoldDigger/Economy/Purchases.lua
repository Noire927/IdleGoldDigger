local addonName, addon = ...

addon.Purchases = {}

local Purchases = addon.Purchases

-- Check whether the player can afford a purchase
function Purchases:CanAfford(cost)
	return IdleDB.gold >= cost
end

-- Spend gold if the player can afford the purchase
function Purchases:SpendGold(cost)
	if not self:CanAfford(cost) then
		return false
	end

	IdleDB.gold = IdleDB.gold - cost

	return true
end

-- Purchase a miner
function Purchases:BuyMiner()
	local cost = addon.Mining:GetMinerCost()

	if not self:SpendGold(cost) then
		return false, cost
	end

	IdleDB.miners = IdleDB.miners + 1

	return true, cost
end

-- Upgrade the pickaxe
function Purchases:BuyPickaxe()
	local cost = addon.Mining:GetPickaxeCost()

	if not self:SpendGold(cost) then
		return false, cost
	end

	IdleDB.pickaxeLevel = IdleDB.pickaxeLevel + 1

	return true, cost
end

-- Purchase a drill
function Purchases:BuyDrill()
	local cost = addon.Mining:GetDrillCost()

	if not self:SpendGold(cost) then
		return false, cost
	end

	IdleDB.transmuters = IdleDB.transmuters + 1

	return true, cost
end

-- Upgrade the Automated Mining Crew
function Purchases:BuyCrew()
	if not addon.Offline:CanUpgradeCrew() then
		return false, nil, "MAX"
	end

	local cost = addon.Mining:GetCrewCost()

	if not self:SpendGold(cost) then
		return false, cost
	end

	IdleDB.offlineUpgradeLevel = IdleDB.offlineUpgradeLevel + 1

	return true, cost
end
