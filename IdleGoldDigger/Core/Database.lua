local addonName, addon = ...

local Config = addon.Config

addon.Database = {}

-- Database validation settings
local MIN_FONT = 8
local MAX_FONT = 24
local DEFAULT_FONT = 12

local MIN_W, MIN_H = 200, 180
local MAX_W, MAX_H = 500, 400

-- Validate and initialize saved data
function addon.Database:Validate()
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

	-- Currency
	IdleDB.gold = GetNumber("gold", 100, 0)
	IdleDB.lifetimeGold = GetNumber("lifetimeGold", 0, 0)

	-- Diamonds
	IdleDB.diamonds = math.floor(GetNumber("diamonds", 0, 0))

	IdleDB.runDiamonds = math.floor(GetNumber("runDiamonds", 0, 0, #Config.DIAMOND_MILESTONES))

	IdleDB.runDiamonds = math.min(IdleDB.runDiamonds, IdleDB.diamonds, #Config.DIAMOND_MILESTONES)

	-- Mining upgrades
	IdleDB.pickaxeLevel = math.floor(GetNumber("pickaxeLevel", 0, 0))
	IdleDB.transmuters = math.floor(GetNumber("transmuters", 0, 0))
	IdleDB.drillUpgradeLevel = math.floor(GetNumber("drillUpgradeLevel", 0, 0))

	-- Automated Mining Crew
	IdleDB.offlineUpgradeLevel = math.floor(GetNumber("offlineUpgradeLevel", 0, 0, Config.MAX_CREW_LEVEL))

	-- UI settings
	IdleDB.fontSize = math.floor(GetNumber("fontSize", DEFAULT_FONT, MIN_FONT, MAX_FONT))

	-- Gameplay settings
	if type(IdleDB.notifyOffline) ~= "boolean" then
		IdleDB.notifyOffline = true
	end

	if type(IdleDB.notifyDiamonds) ~= "boolean" then
		IdleDB.notifyDiamonds = true
	end

	if type(IdleDB.lockWindowPosition) ~= "boolean" then
		IdleDB.lockWindowPosition = false
	end

	-- Window state
	local validWindowStates = {
		open = true,
		minimized = true,
		hidden = true,
	}

	if not validWindowStates[IdleDB.windowState] then
		IdleDB.windowState = "open"
	end

	IdleDB.width = GetNumber("width", 240, MIN_W, MAX_W)
	IdleDB.height = GetNumber("height", 240, MIN_H, MAX_H)
	-- Main window position
	if type(IdleDB.point) ~= "string" then
		IdleDB.point = "CENTER"
	end

	IdleDB.x = GetNumber("x", 0, -10000, 10000)
	IdleDB.y = GetNumber("y", 0, -10000, 10000)
	-- Session tracking
	IdleDB.lastSeen = math.floor(GetNumber("lastSeen", time(), 0))

	-- Minimized window position
	if IdleDB.miniX ~= nil then
		IdleDB.miniX = GetNumber("miniX", 0, 0)
	end

	if IdleDB.miniY ~= nil then
		IdleDB.miniY = GetNumber("miniY", 0, 0)
	end
end
