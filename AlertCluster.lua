-- Paltard: AlertCluster.lua
-- One movable anchor for all of Paltard's icon alerts (the same design as
-- Huntard's). One alert shows centered on the anchor; when several are up at
-- once they line up side by side, still centered on it. New alerts only need
-- adding to PROVIDERS.
--
-- Unlocked (/paltard unlock, or untick "Lock position"): the anchor shows as a
-- dark square -- drag it to move, mouse wheel over it to resize.

local P = Paltard
P.AlertCluster = P.AlertCluster or {}

local ICON_SIZE = 48
local GAP = 10 -- pixels between icons at scale 1.0
local UPDATE_INTERVAL = 0.1

-- In left-to-right order. Each returns a status table or nil:
--   { texture = ..., countdown = secondsLeft, cooldownWindow = seconds }
local PROVIDERS = {
	function() return P.Seals and P.Seals.GetStatus() end,
}

local anchor
local pool = {}

local function scale() return P.db.alertCluster.scale end

function P.AlertCluster.Refresh()
	if not anchor then return end
	anchor:ClearAllPoints()
	anchor:SetPoint("CENTER", UIParent, "CENTER", P.db.alertCluster.x, P.db.alertCluster.y)
	local size = ICON_SIZE * scale()
	anchor:SetSize(size, size)
	anchor:EnableMouse(not P.db.locked)
	anchor.bg:SetShown(not P.db.locked)
	anchor.label:SetShown(not P.db.locked)
end

local function createSlot()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("MEDIUM")

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetAllPoints()
	f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- trims the icon's built-in border

	f.swipe = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.swipe:SetAllPoints(f.icon)
	if f.swipe.SetHideCountdownNumbers then f.swipe:SetHideCountdownNumbers(true) end

	f.countdown = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	f.countdown:SetPoint("CENTER")
	f.countdown:SetTextColor(1, 1, 1, 1)

	f:Hide()
	return f
end

local function applySlot(f, status, size)
	f:SetSize(size, size)
	f.icon:SetTexture(status.texture)
	if status.countdown then
		f.countdown:SetFont(f.countdown:GetFont(), 24 * scale(), "OUTLINE")
		f.countdown:SetText(tostring(math.ceil(status.countdown)))
		f.countdown:Show()
		-- Worked out from the time left on every pass, so it stays exact.
		f.swipe:SetCooldown(GetTime() - (status.cooldownWindow - status.countdown), status.cooldownWindow)
		f.swipe:Show()
	else
		f.countdown:Hide()
		f.swipe:Hide()
	end
end

local function layout()
	local active = {}
	for _, provider in ipairs(PROVIDERS) do
		local ok, status = pcall(provider)
		if ok and status then active[#active + 1] = status end
	end

	local size = ICON_SIZE * scale()
	local step = size + GAP * scale()
	for i = 1, math.max(#active, #pool) do
		local f = pool[i]
		if not f then
			f = createSlot()
			pool[i] = f
		end
		if active[i] then
			f:ClearAllPoints()
			f:SetPoint("CENTER", anchor, "CENTER", (i - (#active + 1) / 2) * step, 0)
			applySlot(f, active[i], size)
			f:Show()
		else
			f:Hide()
		end
	end
end

function P.AlertCluster.Init()
	anchor = CreateFrame("Frame", "PaltardAlertAnchor", UIParent)
	anchor:SetFrameStrata("MEDIUM")
	anchor:SetClampedToScreen(true)
	anchor:SetMovable(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
	anchor:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local ux, uy = UIParent:GetCenter()
		P.db.alertCluster.x, P.db.alertCluster.y = x - ux, y - uy
		P.AlertCluster.Refresh()
	end)
	anchor:EnableMouseWheel(true)
	anchor:SetScript("OnMouseWheel", function(_, delta)
		if P.db.locked then return end
		P.db.alertCluster.scale = math.max(0.4, math.min(3, scale() + delta * 0.1))
		P.AlertCluster.Refresh()
	end)

	anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
	anchor.bg:SetAllPoints()
	anchor.bg:SetColorTexture(0, 0, 0, 0.45)

	anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	anchor.label:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
	anchor.label:SetText("Paltard")

	P.AlertCluster.Refresh()

	local ticker = CreateFrame("Frame")
	ticker:SetScript("OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		if self.t >= UPDATE_INTERVAL then
			self.t = 0
			layout()
		end
	end)
end
