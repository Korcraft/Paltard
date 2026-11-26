-- Paltard: Core.lua
-- Saved settings, the paladin-only switch, slash commands and a copyable
-- text window for debug output. The seal timer is in Seals.lua, the movable
-- icon frame in AlertCluster.lua, the settings page in Settings.lua.

Paltard = Paltard or {}
local P = Paltard

local PREFIX = "|cfff58cbaPaltard|r "
P.PREFIX = PREFIX

local DEFAULTS = {
	locked = false,
	alertCluster = { x = 120, y = -200, scale = 1.0 },
	seals = { enabled = true, warnSeconds = 5 },
}

local function applyDefaults(db, defaults)
	for k, v in pairs(defaults) do
		if db[k] == nil then
			if type(v) == "table" then
				db[k] = {}
				applyDefaults(db[k], v)
			else
				db[k] = v
			end
		elseif type(v) == "table" and type(db[k]) == "table" then
			applyDefaults(db[k], v)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Copyable text window (chat can't be copied from)
-- ---------------------------------------------------------------------------

local debugWindow

function P.ShowCopyableText(title, text)
	if not debugWindow then
		local f = CreateFrame("Frame", "PaltardDebugWindow", UIParent)
		f:SetSize(560, 440)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetToplevel(true)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)

		local bg = f:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.05, 0.05, 0.05, 0.97)

		local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOP", 0, -10)
		f.label = label

		local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("TOP", label, "BOTTOM", 0, -4)
		hint:SetText("Click inside, then Ctrl+A, Ctrl+C to copy")

		local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		closeBtn:SetSize(80, 22)
		closeBtn:SetPoint("BOTTOM", 0, 10)
		closeBtn:SetText("Close")
		closeBtn:SetScript("OnClick", function() f:Hide() end)

		local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 14, -44)
		scroll:SetPoint("BOTTOMRIGHT", -32, 40)

		local edit = CreateFrame("EditBox", nil, scroll)
		edit:SetMultiLine(true)
		edit:SetFontObject("ChatFontNormal")
		edit:SetWidth(500)
		edit:SetAutoFocus(false)
		edit:SetTextInsets(4, 4, 4, 4)
		edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		scroll:SetScrollChild(edit)
		f.edit = edit

		f:Hide()
		debugWindow = f
	end
	debugWindow.label:SetText(title)
	debugWindow.edit:SetText(text)
	debugWindow.edit:HighlightText()
	debugWindow.edit:SetFocus()
	debugWindow:Show()
end

-- ---------------------------------------------------------------------------

function P.RefreshMovables()
	if P.AlertCluster and P.AlertCluster.Refresh then P.AlertCluster.Refresh() end
end

function P.ResetPositions()
	local d = {}
	applyDefaults(d, DEFAULTS)
	P.db.alertCluster = d.alertCluster
	P.RefreshMovables()
	print(PREFIX .. "position and size reset.")
end

function P.SetLocked(locked)
	P.db.locked = locked and true or false
	P.RefreshMovables()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, addonName)
	if event == "ADDON_LOADED" and addonName == "Paltard" then
		PaltardDB = PaltardDB or {}
		applyDefaults(PaltardDB, DEFAULTS)
		P.db = PaltardDB
	elseif event == "PLAYER_LOGIN" then
		-- Paltard does nothing at all on other classes.
		local _, class = UnitClass("player")
		P.active = class == "PALADIN"
		if not P.active then return end
		if P.Seals and P.Seals.Init then P.Seals.Init() end
		if P.AlertCluster and P.AlertCluster.Init then P.AlertCluster.Init() end
		if P.Settings and P.Settings.Init then P.Settings.Init() end
		print(PREFIX .. "loaded. Type |cffffffff/pt|r for settings.")
	end
end)

local function printHelp()
	print(PREFIX .. "commands:")
	print("  /pt         - open the settings window")
	print("  /pt lock    - lock the seal icon in place")
	print("  /pt unlock  - unlock it: drag to move, mouse wheel to resize")
	print("  /pt reset   - put it back in its default spot and size")
	print("  /pt test    - show a sample seal countdown")
	print("  /pt debug   - show what seal tracking has recorded (copy window)")
end

SLASH_PALTARD1 = "/pt"
SLASH_PALTARD2 = "/paltard"
SlashCmdList.PALTARD = function(msg)
	if not P.active then
		print(PREFIX .. "only runs on paladins, so it's switched off on this character.")
		return
	end
	msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
	if msg == "" or msg == "settings" or msg == "config" then
		P.Settings.Toggle()
	elseif msg == "lock" then
		P.SetLocked(true)
		print(PREFIX .. "locked.")
	elseif msg == "unlock" then
		P.SetLocked(false)
		print(PREFIX .. "unlocked - drag the dark square to move it, mouse wheel over it to resize.")
	elseif msg == "reset" then
		P.ResetPositions()
	elseif msg == "test" then
		P.Seals.Test()
	elseif msg == "debug" then
		P.Seals.Debug()
	else
		printHelp()
	end
end
