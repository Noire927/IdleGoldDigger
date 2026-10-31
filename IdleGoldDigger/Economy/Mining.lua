local addonName, addon = ...

local Config = addon.Config

addon.Mining = {}

local Mining = addon.Mining

-- Manual mining reward
function Mining:GetManualMiningGold()
	return Config.MINER_BASE_GOLD * Config.PICKAXE_BONUS ^ IdleDB.pickaxeLevel
end

-- Pickaxe upgrade cost
function Mining:GetPickaxeCost()
	return math.floor(Config.PICKAXE_BASE_COST * Config.PICKAXE_COST_MULTIPLIER ^ IdleDB.pickaxeLevel)
end

-- Drill cost
function Mining:GetDrillCost()
	return math.floor(Config.DRILL_BASE_COST * Config.DRILL_COST_MULTIPLIER ^ IdleDB.transmuters)
end

-- Drill upgrade cost
function Mining:GetDrillUpgradeCost()
	local level = IdleDB.drillUpgradeLevel or 0

	return math.floor(Config.DRILL_UPGRADE_BASE_COST * Config.DRILL_UPGRADE_COST_MULTIPLIER ^ level)
end

-- Automated Mining Crew upgrade cost
function Mining:GetCrewCost()
	return math.floor(Config.CREW_BASE_COST * Config.CREW_COST_MULTIPLIER ^ IdleDB.offlineUpgradeLevel)
end

-- Total drill production rate
function Mining:GetDrillRate()
	local upgradeLevel = IdleDB.drillUpgradeLevel or 0
	local productionMultiplier = Config.DRILL_PRODUCTION_MULTIPLIER ^ upgradeLevel

	return IdleDB.transmuters * Config.DRILL_RATE * productionMultiplier
end

-- Combined passive production rate
function Mining:GetTotalRate()
	return self:GetDrillRate()
end
