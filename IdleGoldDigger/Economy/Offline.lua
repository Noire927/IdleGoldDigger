local addonName, addon = ...

local Config = addon.Config

addon.Offline = {}

local Offline = addon.Offline

-- Get the current Automated Mining Crew level
function Offline:GetCrewLevel()
	local level = tonumber(IdleDB.offlineUpgradeLevel) or 0

	return math.max(0, math.min(Config.MAX_CREW_LEVEL, level))
end

-- Check whether the crew has reached its maximum level
function Offline:IsCrewMaxed()
	return self:GetCrewLevel() >= Config.MAX_CREW_LEVEL
end

-- Check whether another crew upgrade is possible
function Offline:CanUpgradeCrew()
	return not self:IsCrewMaxed()
end

-- Calculate the maximum amount of offline time
function Offline:GetTimeLimit()
	return self:GetCrewLevel() * Config.OFFLINE_SECONDS_PER_LEVEL
end

-- Calculate how long the player has been away
function Offline:CalculateAwayTime(now)
	now = now or time()

	local lastSeen = IdleDB.lastSeen or now

	return math.max(0, now - lastSeen)
end

-- Calculate earnings from offline progress
function Offline:CalculateEarnings(now)
	local away = self:CalculateAwayTime(now)
	local cappedAway = math.min(away, self:GetTimeLimit())

	local earnings = cappedAway * addon.Mining:GetTotalRate()

	return earnings, cappedAway, away
end

-- Apply offline progress to the player's gold
function Offline:ApplyProgress(now)
	now = now or time()

	local earnings, cappedAway = self:CalculateEarnings(now)

	addon.Diamonds:AwardGold(earnings)

	IdleDB.lastSeen = now

	return earnings, cappedAway
end
