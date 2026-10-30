local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.MiniWindow = {}

local MiniWindow = addon.UI.MiniWindow
local UI = addon.UI

local MINI_HEIGHT = 32

-- Resize the minimized bar to fit its currency text
function MiniWindow:Fit()
	local miniWindow = UI.miniWindow
	local miniGoldText = UI.miniGoldText

	if not miniWindow or not miniGoldText then
		return
	end

	local textWidth = miniGoldText:GetStringWidth()
	local screenWidth = UIParent:GetWidth()

	local needW = math.ceil(textWidth + 48)
	local needH = math.max(MINI_HEIGHT, IdleDB.fontSize + 16)

	needW = math.min(needW, screenWidth)

	miniWindow:SetSize(needW, needH)

	miniGoldText:SetWidth(math.max(1, needW - 48))
end

-- Hide the main window and show the minimized bar
function MiniWindow:Minimize()
	local window = UI.window
	local miniWindow = UI.miniWindow

	if not window or not miniWindow or UI.isMinimized then
		return
	end

	-- Save the full dimensions before hiding the window
	IdleDB.width = window:GetWidth()
	IdleDB.height = window:GetHeight()

	UI.isMinimized = true
	IdleDB.windowState = "minimized"

	UI.minimizeBtn:SetText("+")
	UI.goldText:Hide()
	UI.minerText:Hide()
	UI.transmuteText:Hide()
	UI.upgradeText:Hide()

	UI.crewBtn:Hide()
	UI.buyBtn:Hide()
	UI.pickaxeBtn:Hide()
	UI.transmuteBtn:Hide()

	UI.diamondText:Hide()
	window.resizeGrip:Hide()

	UI.miniGoldText:SetText(addon.Formatting:FormatWholeGold(IdleDB.gold))

	UI.miniGoldText:Show()

	miniWindow:Show()

	self:Fit()

	window:Hide()
end

-- Restore the main window
function MiniWindow:Restore()
	local window = UI.window
	local miniWindow = UI.miniWindow

	if not window or not miniWindow or not UI.isMinimized then
		return
	end

	UI.isMinimized = false
	IdleDB.windowState = "open"

	miniWindow:Hide()
	window:Show()

	UI.goldText:Show()
	UI.minerText:Show()
	UI.transmuteText:Show()
	UI.upgradeText:Show()

	UI.crewBtn:Show()
	UI.buyBtn:Show()
	UI.pickaxeBtn:Show()
	UI.transmuteBtn:Show()

	UI.diamondText:Show()
	window.resizeGrip:Show()

	window:SetSize(IdleDB.width or 240, IdleDB.height or 240)

	UI.minimizeBtn:SetText("-")

	UI.MainWindow:Fit(false)
end

-- Toggle between minimized and restored states
function MiniWindow:Toggle()
	if UI.isMinimized then
		self:Restore()
	else
		self:Minimize()
	end
end

-- Build the minimized window
function MiniWindow:Build()
	if UI.miniWindow then
		return
	end

	local miniWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

	UI.miniWindow = miniWindow

	miniWindow:SetSize(240, MINI_HEIGHT)

	-- Restore saved position, or use the center of the screen
	if IdleDB.miniX ~= nil and IdleDB.miniY ~= nil then
		local x = math.max(0, math.min(IdleDB.miniX, UIParent:GetWidth() - miniWindow:GetWidth()))

		local y = math.max(0, math.min(IdleDB.miniY, UIParent:GetHeight() - miniWindow:GetHeight()))

		miniWindow:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	else
		miniWindow:SetPoint("CENTER")
	end

	miniWindow:SetFrameStrata("DIALOG")
	miniWindow:SetMovable(true)
	miniWindow:EnableMouse(true)
	miniWindow:RegisterForDrag("LeftButton")

	miniWindow:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = {
			left = 3,
			right = 3,
			top = 3,
			bottom = 3,
		},
	})

	miniWindow:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	miniWindow:SetBackdropBorderColor(0.6, 0.45, 0.15, 1)

	miniWindow:SetClampedToScreen(true)

	miniWindow:SetScript("OnDragStart", miniWindow.StartMoving)

	miniWindow:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()

		IdleDB.miniX = self:GetLeft()
		IdleDB.miniY = self:GetBottom()
	end)

	-- Gold-only currency display
	UI.miniGoldText = miniWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	UI.miniGoldText:SetPoint("CENTER", miniWindow, "CENTER", -8, 0)

	UI.miniGoldText:SetTextColor(1, 0.82, 0)
	UI.miniGoldText:Hide()

	-- Restore button
	local restoreBtn = CreateFrame("Button", nil, miniWindow)

	UI.miniRestoreBtn = restoreBtn

	restoreBtn:SetSize(20, 20)
	restoreBtn:SetPoint("RIGHT", miniWindow, "RIGHT", -6, 0)
	restoreBtn:SetFrameLevel(miniWindow:GetFrameLevel() + 2)

	restoreBtn:SetNormalFontObject("GameFontNormal")
	restoreBtn:SetHighlightFontObject("GameFontHighlight")
	restoreBtn:SetText("+")

	restoreBtn:SetScript("OnClick", function()
		self:Restore()
	end)

	miniWindow:Hide()

	return miniWindow
end
