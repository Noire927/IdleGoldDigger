local addonName, addon = ...

local Config = addon.Config

addon.Formatting = {}

local Formatting = addon.Formatting

-- Convert gold into gold, silver and copper values
function Formatting:GetCurrencyValues(totalGold)
	local totalCopper = math.floor(totalGold * Config.COPPER_PER_GOLD + 0.5)

	local gold = math.floor(totalCopper / Config.COPPER_PER_GOLD)
	local remainingCopper = totalCopper % Config.COPPER_PER_GOLD

	local silver = math.floor(remainingCopper / Config.COPPER_PER_SILVER)

	local copper = remainingCopper % Config.COPPER_PER_SILVER

	return gold, silver, copper
end

-- Format gold, silver and copper for the main display
function Formatting:FormatGold(amount)
	local gold, silver, copper = self:GetCurrencyValues(amount)

	local goldText

	if gold >= 1000000 then
		goldText = string.format("%.2fM", gold / 1000000)
	elseif gold >= 1000 then
		goldText = string.format("%.2fK", gold / 1000)
	else
		goldText = tostring(gold)
	end

	local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
	local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
	local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

	return goldText .. goldIcon .. " " .. silver .. silverIcon .. " " .. copper .. copperIcon
end

-- Format whole gold for the minimized display
function Formatting:FormatWholeGold(amount)
	local gold = math.floor(amount)

	local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"

	if gold >= 1000000 then
		return string.format("%.2fM", gold / 1000000) .. goldIcon
	elseif gold >= 1000 then
		return string.format("%.2fK", gold / 1000) .. goldIcon
	end

	return gold .. goldIcon
end
