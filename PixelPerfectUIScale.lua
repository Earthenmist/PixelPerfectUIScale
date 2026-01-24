-- Enforces a pixel-perfect UI scale (768 / physical screen height).

local f = CreateFrame("Frame")

-- Screen height helper (Retail + Classic)
local function PPScale_GetScreenHeight()
  -- Prefer physical pixel height when available
  if type(GetPhysicalScreenSize) == "function" then
    local _, h = GetPhysicalScreenSize()
    if h and h > 0 then return h end
  end
  -- Classic fallback
  if type(GetScreenHeight) == "function" then
    local h = GetScreenHeight()
    if h and h > 0 then return h end
  end
  -- Last resort: approximate from UIParent
  if UIParent and UIParent.GetHeight and UIParent.GetScale then
    local h = UIParent:GetHeight() * UIParent:GetScale()
    if h and h > 0 then return h end
  end
  return nil
end

-- Added modifier support
PixelPerfectUIScaleDB = PixelPerfectUIScaleDB or {}
local function getModifier()
  local m = tonumber(PixelPerfectUIScaleDB.modifier or 1) or 1
  -- sanity clamp so people don't go wild
  if m < 0.5 then m = 0.5 elseif m > 3.0 then m = 3.0 end
  PixelPerfectUIScaleDB.modifier = m
  return m
end

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
  "NAME_PLATE_CREATED",
  -- "EDIT_MODE_LAYOUTS_UPDATED", -- disabled: breaks Edit Mode snap-to-elements
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
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "debug" then
    PixelPerfectUIScale_Debug = not PixelPerfectUIScale_Debug
    print("PPScale debug:", PixelPerfectUIScale_Debug and "ON" or "OFF")

  elseif msg == "now" then
    PixelPerfectUIScale_Apply(true)

  elseif msg == "status" then
    local h = PPScale_GetScreenHeight()
    local base = (h and h > 0) and (768 / h) or nil
    local mod  = getModifier()
    local want = base and (base * mod) or nil
    local have = UIParent:GetScale()
    print(string.format("PPScale status: base %.5f × mod %.2f = want %.5f, have %.5f, CVars %s",
      base or -1, mod, want or -1, have or -1, TOUCH_CVARS and "ON" or "OFF"))

  elseif msg:match("^modifier%s") then
    local num = msg:match("^modifier%s+([%d%.]+)")
    if num then
      local m = tonumber(num)
      if m and m > 0 then
        PixelPerfectUIScaleDB.modifier = m
        print(string.format("PPScale modifier set to %.2f (clamped to %.2f if needed).", m, getModifier()))
        PixelPerfectUIScale_Apply(true)
      else
        print("PPScale: invalid number. Usage: /ppscale modifier 1.25")
      end
    elseif msg:match("^modifier$") then
      print(string.format("PPScale modifier is %.2f. Usage: /ppscale modifier <number>  (0.5–3.0)", getModifier()))
    end

  elseif msg == "cvars on" then
    TOUCH_CVARS = true
    print("PPScale: TOUCH_CVARS set to ON.")

  elseif msg == "cvars off" then
    TOUCH_CVARS = false
    print("PPScale: TOUCH_CVARS set to OFF.")

  else
    print("/ppscale debug          - toggle verbose logging")
    print("/ppscale now            - force reapply immediately")
    print("/ppscale status         - show desired vs current scale")
    print("/ppscale modifier <n>   - multiply 768/h by <n> (e.g. 1.25). Range 0.5–3.0")
    print("/ppscale cvars on|off   - allow/deny writing uiScale/useUiScale CVars")
  end
end


-- Helpers
local function isSimilar(a, b)
  return math.abs((a or 0) - (b or 0)) < TOLERANCE
end

local function desiredScale()
  local h = PPScale_GetScreenHeight()
  if not h or h == 0 then return nil end
  return (768 / h) * getModifier()
end

local throttleUntil = 0
local pending = false

local function IsEditModeActive()
  if EditModeManagerFrame and EditModeManagerFrame.editModeActive then
    return EditModeManagerFrame.editModeActive
  end
  if C_EditMode and C_EditMode.IsEditModeActive then
    return C_EditMode.IsEditModeActive()
  end
  return false
end

-- Nameplates can end up effectively double-scaled when UIParent scale is enforced
-- and another addon (e.g. nameplate skins) applies its own scaling.
-- To keep nameplates visually consistent, we reset the nameplate containers to 1.
local function PPScale_FixNamePlates(plate)
  if NamePlateDriverFrame and NamePlateDriverFrame.SetScale then
    NamePlateDriverFrame:SetScale(1)
  end

  -- If we were given the newly created plate, fix just that first.
  if plate and plate.SetScale then
    plate:SetScale(1)
  end

  -- Re-assert on all active plates (covers existing plates + races)
  if C_NamePlate and C_NamePlate.GetNamePlates then
    local plates = C_NamePlate.GetNamePlates()
    if plates then
      for _, p in ipairs(plates) do
        if p and p.SetScale then
          p:SetScale(1)
        end
      end
    end
  end
end

function PixelPerfectUIScale_Apply(force)
  pending = false

  -- Don’t fight Edit Mode while the user is dragging things around
  if IsEditModeActive() then
    dprint("Edit Mode active; deferring scale apply")
    pending = true
    return
  end

if InCombatLockdown() then
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7f00[PPScale]|r UI scale update deferred until after combat.")
  end
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
    PPScale_FixNamePlates()
    dprint("Applied UIParent:SetScale(%.5f) (was %.5f)", want, current or -1)

    C_Timer.After(0.25, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        PPScale_FixNamePlates()
        dprint("Re-applied after 0.25s; now %.5f", UIParent:GetScale())
      end
    end)

    C_Timer.After(0.75, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        PPScale_FixNamePlates()
        dprint("Re-applied after 0.75s; now %.5f", UIParent:GetScale())
      end
    end)

    C_Timer.After(1.25, function()
      if not isSimilar(UIParent:GetScale(), want) then
        UIParent:SetScale(want)
        PPScale_FixNamePlates()
        dprint("Re-applied after 1.25s; now %.5f", UIParent:GetScale())
      end
    end)
  else
    dprint("Scale within tolerance (want %.5f, have %.5f)", want, current)
  end
end

f:SetScript("OnEvent", function(self, event, ...)
  if event == "NAME_PLATE_CREATED" then
    local plate = ...
    PPScale_FixNamePlates(plate)
    return
  end
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



