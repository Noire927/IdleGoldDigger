local addonName, addon = ...

addon.Config = {}

local Config = addon.Config

-- Currency settings
Config.COPPER_PER_SILVER = 100
Config.SILVER_PER_GOLD = 100
Config.COPPER_PER_GOLD = Config.COPPER_PER_SILVER * Config.SILVER_PER_GOLD

-- Miner settings
Config.MINER_BASE_COST = 10
Config.MINER_COST_MULTIPLIER = 1.15
Config.MINER_RATE = 0.5

-- Pickaxe settings
Config.PICKAXE_BASE_COST = 50
Config.PICKAXE_COST_MULTIPLIER = 1.65
Config.PICKAXE_BONUS = 1.35

-- Drill settings
Config.DRILL_BASE_COST = 100
Config.DRILL_COST_MULTIPLIER = 1.55
Config.DRILL_RATE = 2

-- Automated Mining Crew settings
Config.CREW_BASE_COST = 10000
Config.CREW_COST_MULTIPLIER = 2
Config.MAX_CREW_LEVEL = 4
Config.OFFLINE_SECONDS_PER_LEVEL = 60 * 60

-- Diamond milestone settings
Config.DIAMOND_MILESTONES = {
	10000,
	50000,
	250000,
	1000000,
	5000000,
}
