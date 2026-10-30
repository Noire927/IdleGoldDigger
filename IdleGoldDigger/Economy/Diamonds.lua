local addonName, addon = ...

local Config = addon.Config

addon.Diamonds = {}

local Diamonds = addon.Diamonds

-- Check and award diamond milestones
function Diamonds:CheckMilestones()
	while IdleDB.runDiamonds < #Config.DIAMOND_MILESTONES do
		local nextMilestone = Config.DIAMOND_MILESTONES[IdleDB.runDiamonds + 1]

		if IdleDB.lifetimeGold < nextMilestone then
			break
		end

		IdleDB.runDiamonds = IdleDB.runDiamonds + 1
		IdleDB.diamonds = IdleDB.diamonds + 1

		print("|cff00ccffIdle Gold Digger:|r " .. "You earned a diamond! Total diamonds: " .. IdleDB.diamonds)
	end
end

-- Award gold and track lifetime earnings
function Diamonds:AwardGold(amount)
	if not amount or amount <= 0 or amount == math.huge or amount ~= amount then
		return
	end

	IdleDB.gold = IdleDB.gold + amount
	IdleDB.lifetimeGold = IdleDB.lifetimeGold + amount

	self:CheckMilestones()
end
