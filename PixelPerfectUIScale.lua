-- PixelPerfectUIScale v1.2.0
-- Enforces a pixel-perfect UI scale (768 / physical screen height).

local f = CreateFrame("Frame")

-- Settings
local THROTTLE_SEC = 0.5
local TOLERANCE    = 0.02
local TOUCH_CVARS  = true  -- set to false to avoid writing useUiScale/uiScale

-- Events to watch
local EVENTS = {
  "PLAYER_LOGIN",
  "PLAYER_ENTERING_WORLD",
  "DISPLAY_SIZE_CHANGED",
  "UI_SCALE_CHANGED",
  "EDIT_MODE_LAYOUTS_UPDATED",
  "PLAYER_REGEN_ENABLED",
}

for _, e in ipairs(EVENTS) do f:RegisterEvent(e) end

-- Optional: react to CVar changes (Dragonflight+). Only useful if TOUCH_CVARS is true.
if C_CVar and C_CVar.RegisterCVarChangedCallback then
  C_CVar.RegisterCVarChangedCallback(function(name)
    if not TOUCH_CVARS then return end
    if name == "uiScale" or name == "useUiScale" then
      C_Timer.After(0.05, function() PixelPerfectUIScale_Apply(true) end)
    end
  end, "PixelPerfectUIScale")
end

-- Debug print
PixelPerfectUIScale_Debug = PixelPerfectUIScale_Debug or false
local function dprint(fmt, ...)
  if PixelPerfectUIScale_Debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff46c7ff[PPScale]|r " .. string.format(fmt, ...))
  end
end

-- Slash command
SLASH_PIXELPERFECTUISCALE1 = "/ppscale"
SlashCmdList.PIXELPERFECTUISCALE = function(msg)
  msg = (msg or ""):lower()
  if msg == "debug" then
    PixelPerfectUIScale_Debug = not PixelPerfectUIScale_Debug
    print("PPScale debug:", PixelPerfectUIScale_Debug and "ON" or "OFF")
  elseif msg == "now" then
    PixelPerfectUIScale_Apply(true)
  elseif msg == "status" then
    local want = (function() local _,h=GetPhysicalScreenSize() if h and h>0 then return 768/h end end)()
    local have = UIParent:GetScale()
    print(string.format("PPScale status: want %.5f, have %.5f, CVars %s",
      want or -1, have or -1, TOUCH_CVARS and "ON" or "OFF"))
  elseif msg == "cvars on" then
    TOUCH_CVARS = true
    print("PPScale: TOUCH_CVARS set to ON.")
  elseif msg == "cvars off" then
    TOUCH_CVARS = false
    print("PPScale: TOUCH_CVARS set to OFF.")
  else
    print("/ppscale debug     - toggle verbose logging")
    print("/ppscale now       - force reapply immediately")
    print("/ppscale status    - show desired vs current scale")
    print("/ppscale cvars on  - allow writing uiScale/useUiScale CVars")
    print("/ppscale cvars off - do not write CVars")
  end
end

-- Helpers
local function isSimilar(a, b)
  return math.abs((a or 0) - (b or 0)) < TOLERANCE
end

local function desiredScale()
  local _, h = GetPhysicalScreenSize()
  if not h or h == 0 then return nil end
  return 768 / h
end

local throttleUntil = 0
local pending = false

function PixelPerfectUIScale_Apply(force)
  pending = false

  if InCombatLockdown() then
    dprint("In combat; deferring")
    pending = true
    return
  end

  local want = desiredScale()
  if not want then
    dprint("No physical height yet; will retry")
    pending = true
    return
  end

  -- Optionally keep Blizzard Settings CVars in sync
  if TOUCH_CVARS and SetCVar then
    if tonumber(GetCVar("useUiScale") or 0) ~= 1 then
      SetCVar("useUiScale", "1")
      dprint("Set useUiScale=1")
    end
    local cvarScale = tonumber(GetCVar("uiScale") or 0)
    if not isSimilar(cvarScale, want) then
      SetCVar("uiScale", tostring(want))
      dprint("Set CVar uiScale -> %.5f", want)
    end
  end

  -- Apply to UIParent (and re-assert a couple of times to beat races)
  local current = UIParent:GetScale()
  if force or not isSimilar(current, want) then
    UIParent:SetScale(want)
    dprint("Applied UIParent:SetScale(%.5f) (was %.5f)", want, current or -1)

    C_Timer.After(0.25, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        dprint("Re-applied after 0.25s; now %.5f", UIParent:GetScale())
      end
    end)

    C_Timer.After(0.75, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        dprint("Re-applied after 0.75s; now %.5f", UIParent:GetScale())
      end
    end)

    C_Timer.After(1.25, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        dprint("Re-applied after 1.25s; now %.5f", UIParent:GetScale())
      end
    end)
  else
    dprint("Scale within tolerance (want %.5f, have %.5f)", want, current)
  end
end

f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    if pending then PixelPerfectUIScale_Apply(true) end
    return
  end

  local now = GetTime()
  if now < throttleUntil then return end
  throttleUntil = now + THROTTLE_SEC

  C_Timer.After(0.05, function()
    pending = true
    PixelPerfectUIScale_Apply(false)
  end)
end)
