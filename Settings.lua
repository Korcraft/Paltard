-- Paltard: Settings.lua
-- One settings page, built twice and kept in sync: in its own window
-- (/paltard) and under Options > AddOns > Paltard -- the same setup as
-- Huntard, AutoVendor and Wayfinder. Plain widgets (no slider templates),
-- since template availability varies between clients.

local P = Paltard
P.Settings = P.Settings or {}

local WIDTH, HEIGHT = 360, 250
local PAD = 20
local SYNC_INTERVAL = 0.5

local frame
local syncers = {}

local function syncAll()
	for _, sync in ipairs(syncers) do sync() end
end

local function makeHeader(parent, y, text)
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", PAD, y)
	header:SetText(text)
end

local function makeCheckbox(parent, y, text, get, set)
	local check = CreateFrame("CheckButton", nil, parent)
	check:SetSize(24, 24)
	check:SetPoint("TOPLEFT", PAD, y)
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

	local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT", check, "RIGHT", 4, 0)
	label:SetText(text)
	check:SetHitRectInsets(0, -(label:GetStringWidth() + 4), 0, 0)

	check:SetScript("OnClick", function(self)
		set(self:GetChecked() and true or false)
		syncAll()
	end)
	table.insert(syncers, function() check:SetChecked(get()) end)
end

local function makeSlider(parent, y, text, minValue, maxValue, get, set, describe)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("TOPLEFT", PAD, y)
	label:SetText(text)

	local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	valueText:SetPoint("TOPRIGHT", -PAD, y)

	local slider = CreateFrame("Slider", nil, parent)
	slider:SetOrientation("HORIZONTAL")
	slider:SetPoint("TOPLEFT", PAD, y - 18)
	slider:SetPoint("TOPRIGHT", -PAD, y - 18)
	slider:SetHeight(16)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(true)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:EnableMouseWheel(true)

	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	track:SetHeight(4)
	track:SetColorTexture(0.4, 0.4, 0.4, 0.9)

	local syncing = false
	local function sync()
		local value = get()
		syncing = true
		slider:SetValue(value)
		syncing = false
		valueText:SetText(describe(value))
	end
	slider:SetScript("OnValueChanged", function(_, value)
		if syncing then return end
		set(math.floor(value + 0.5))
		sync()
	end)
	slider:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(self:GetValue() + delta)
	end)
	table.insert(syncers, sync)
end

local function makeButton(parent, x, y, width, text, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 22)
	button:SetPoint("TOPLEFT", x, y)
	button:SetText(text)
	button:SetScript("OnClick", onClick)
end

local function buildContent(page)
	makeHeader(page, -10, "Seal Countdown")
	makeCheckbox(page, -30, "Show the seal countdown",
		function() return P.db.seals.enabled end,
		function(on) P.db.seals.enabled = on end)
	makeSlider(page, -64, "Pop up for the last", 1, 15,
		function() return P.db.seals.warnSeconds end,
		P.Seals.SetWarnSeconds,
		function(s) return s .. (s == 1 and " second" or " seconds") end)
	makeButton(page, PAD, -110, 120, "Test", P.Seals.Test)

	makeHeader(page, -150, "Layout")
	makeCheckbox(page, -170, "Lock position",
		function() return P.db.locked end,
		P.SetLocked)
	makeButton(page, WIDTH - PAD - 130, -171, 130, "Reset Position", P.ResetPositions)
end

-- Re-syncs when shown and every SYNC_INTERVAL while shown, so a slash
-- command used while the page is open shows up too.
local function keepSynced(page)
	page:HookScript("OnShow", syncAll)
	page:HookScript("OnUpdate", function(self, elapsed)
		self.sinceSync = (self.sinceSync or 0) + elapsed
		if self.sinceSync >= SYNC_INTERVAL then
			self.sinceSync = 0
			syncAll()
		end
	end)
end

local function buildWindow()
	frame = CreateFrame("Frame", "PaltardSettingsFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIDTH + 12, HEIGHT + 60)
	frame:SetTitle("Paltard")
	frame:SetPortraitToAsset("Interface\\Icons\\Ability_ThunderBolt")
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	table.insert(UISpecialFrames, "PaltardSettingsFrame") -- Escape closes it

	local page = CreateFrame("Frame", nil, frame.Inset)
	page:SetAllPoints()
	buildContent(page)
	keepSynced(frame)

	local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	version:SetPoint("BOTTOMLEFT", 12, 8)
	local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
	version:SetText("Paltard " .. (getMeta and getMeta("Paltard", "Version") or ""))
end

function P.Settings.Toggle()
	if not frame then buildWindow() end
	frame:SetShown(not frame:IsShown())
end

-- The same page under Options > AddOns > Paltard.
function P.Settings.Init()
	if not (_G.Settings and _G.Settings.RegisterCanvasLayoutCategory and _G.Settings.RegisterAddOnCategory) then
		return
	end
	local canvas = CreateFrame("Frame", nil, UIParent)
	canvas:Hide()
	local title = canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Paltard")

	local content = CreateFrame("Frame", nil, canvas)
	content:SetPoint("TOPLEFT", 0, -44)
	content:SetSize(WIDTH, HEIGHT)
	buildContent(content)
	keepSynced(canvas)

	pcall(function()
		_G.Settings.RegisterAddOnCategory(_G.Settings.RegisterCanvasLayoutCategory(canvas, "Paltard"))
	end)
end
