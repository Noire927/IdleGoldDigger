local addonName, addon = ...

local Config = addon.Config

addon.Mining = {}

local Mining = addon.Mining

-- Miner cost
function Mining:GetMinerCost()
	return math.floor(Config.MINER_BASE_COST * Config.MINER_COST_MULTIPLIER ^ IdleDB.miners)
end

-- Pickaxe upgrade cost
function Mining:GetPickaxeCost()
	return math.floor(Config.PICKAXE_BASE_COST * Config.PICKAXE_COST_MULTIPLIER ^ IdleDB.pickaxeLevel)
end

-- Drill cost
function Mining:GetDrillCost()
	return math.floor(Config.DRILL_BASE_COST * Config.DRILL_COST_MULTIPLIER ^ IdleDB.transmuters)
end

-- Automated Mining Crew upgrade cost
function Mining:GetCrewCost()
	return math.floor(Config.CREW_BASE_COST * Config.CREW_COST_MULTIPLIER ^ IdleDB.offlineUpgradeLevel)
end

-- Miner production rate
function Mining:GetMinerRate()
	return IdleDB.miners * Config.MINER_RATE * Config.PICKAXE_BONUS ^ IdleDB.pickaxeLevel
end

-- Drill production rate
function Mining:GetDrillRate()
	return IdleDB.transmuters * Config.DRILL_RATE
end

-- Combined production rate
function Mining:GetTotalRate()
	return self:GetMinerRate() + self:GetDrillRate()
end
