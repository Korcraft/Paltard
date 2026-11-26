-- Paltard: Seals.lua
-- Seal countdown. Every seal lasts 30 seconds. When you cast one, a timer
-- starts; for its last few seconds (5 by default) the seal's icon pops up
-- with a countdown and a cooldown swipe, then disappears when it fades.
--
-- Built the way Huntard tracks Serpent Sting and aspects: from your own
-- casts (UNIT_SPELLCAST_SUCCEEDED), because this client hides buff data
-- ("secret" auras) during combat -- reading the buff itself isn't reliable
-- mid-fight, but your own casts always are.
--   * Casting a seal starts (or restarts) the timer with that seal's icon.
--     Only one seal can be up, so a new seal replaces the old timer.
--   * Casting Judgement uses up the seal, so it ends the timer.
--   * Dying ends it.
-- Not seen: a seal you right-click off, or one dispelled by an enemy. The
-- icon would then still show for the rest of the 30 seconds.

local P = Paltard
P.Seals = P.Seals or {}

local SEAL_DURATION = 30 -- seconds, every seal
local SEAL_PREFIX = "Seal of "
local JUDGEMENT = { ["Judgement"] = true, ["Judgment"] = true }
local TEST_SEAL = "Seal of Righteousness"

local current -- { name, icon, castAt, test } for the seal that's up, or nil
local lastEvent = "none yet"

-- Name and icon of a spell (by ID or name), on old and new clients.
local function spellInfo(id)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(id)
		if info then return info.name, info.iconID end
	end
	if _G.GetSpellInfo then
		local name, _, icon = _G.GetSpellInfo(id)
		return name, icon
	end
	return nil
end

local function warnSeconds()
	return P.db.seals.warnSeconds
end

function P.Seals.SetWarnSeconds(seconds)
	P.db.seals.warnSeconds = math.max(1, math.min(15, math.floor(seconds + 0.5)))
	return P.db.seals.warnSeconds
end

local function remaining()
	if not current then return nil end
	local left = current.castAt + SEAL_DURATION - GetTime()
	if left <= 0 then
		current = nil
		return nil
	end
	return left
end

-- For AlertCluster.lua: a status table while the seal is in its last
-- seconds, otherwise nil.
function P.Seals.GetStatus()
	if not P.db.seals.enabled then return nil end
	local left = remaining()
	if not left or left > warnSeconds() then return nil end
	return { texture = current.icon, countdown = left, cooldownWindow = warnSeconds() }
end

local function onCast(spellID)
	local name, icon = spellInfo(spellID)
	if type(name) ~= "string" then return end
	if name:sub(1, #SEAL_PREFIX) == SEAL_PREFIX then
		current = { name = name, icon = icon, castAt = GetTime() }
		lastEvent = "cast " .. name .. " at " .. string.format("%.1f", GetTime())
	elseif JUDGEMENT[name] and current then
		lastEvent = "Judgement used up " .. current.name .. " at " .. string.format("%.1f", GetTime())
		current = nil
	end
end

-- /pt test: a seal that's just entering its warning window.
function P.Seals.Test()
	local _, icon = spellInfo(TEST_SEAL)
	current = {
		name = TEST_SEAL .. " (test)",
		icon = icon or "Interface\\Icons\\Ability_ThunderBolt",
		castAt = GetTime() - (SEAL_DURATION - warnSeconds()),
		test = true,
	}
	lastEvent = "test countdown started"
	if not P.db.seals.enabled then
		print(P.PREFIX .. "the seal countdown is switched off in /pt, so the test won't show.")
	end
end

-- /pt debug: what's being tracked, in a copy window.
function P.Seals.Debug()
	local lines = {}
	local left = remaining()
	lines[#lines + 1] = "Seal countdown enabled: " .. tostring(P.db.seals.enabled)
	lines[#lines + 1] = "Warning window: last " .. warnSeconds() .. " seconds of " .. SEAL_DURATION
	lines[#lines + 1] = ""
	if current and left then
		lines[#lines + 1] = "Tracking: " .. current.name
		lines[#lines + 1] = "Icon: " .. tostring(current.icon)
		lines[#lines + 1] = string.format("Time left: %.1f s (icon %s)", left,
			left <= warnSeconds() and "showing" or "hidden until the last " .. warnSeconds() .. " s")
	else
		lines[#lines + 1] = "Tracking: no seal"
	end
	lines[#lines + 1] = "Last event: " .. lastEvent
	lines[#lines + 1] = ""
	local name, icon = spellInfo(TEST_SEAL)
	lines[#lines + 1] = "Spell lookup check (" .. TEST_SEAL .. "): name=" .. tostring(name) .. " icon=" .. tostring(icon)
	lines[#lines + 1] = "C_Spell.GetSpellInfo: " .. tostring(C_Spell and C_Spell.GetSpellInfo ~= nil)
		.. "   GetSpellInfo: " .. tostring(_G.GetSpellInfo ~= nil)
	P.ShowCopyableText("Paltard seal debug", table.concat(lines, "\n"))
end

function P.Seals.Init()
	local watch = CreateFrame("Frame")
	watch:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	watch:RegisterEvent("PLAYER_DEAD")
	watch:SetScript("OnEvent", function(_, event, _, _, spellID)
		if event == "PLAYER_DEAD" then
			current = nil
			lastEvent = "died"
			return
		end
		onCast(spellID) -- UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	end)
end
