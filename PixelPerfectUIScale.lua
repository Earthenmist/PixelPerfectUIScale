-- Enforces a pixel-perfect UI scale (768 / physical screen height).
-- v1.4.12: Safely skips Retail Edit Mode hooks when running on Classic clients.

local ADDON_NAME = ...
local f = CreateFrame("Frame")

local THROTTLE_SEC = 0.5
local TOLERANCE    = 0.0005
local TOUCH_CVARS  = true -- Keep Blizzard's saved UI scale in sync so /reload during combat starts correctly.

local pending = false
local pendingNameplateFix = false
local throttleUntil = 0

PixelPerfectUIScale_Debug = PixelPerfectUIScale_Debug or false
PixelPerfectUIScaleDB = PixelPerfectUIScaleDB or {}

local DEFAULTS = {
  mode = "auto",          -- auto/manual/preset
  modifier = 1,
  uiScale = nil,           -- used by manual mode
  gameMenuScale = 1,
  multiMonitor = false,
  ultrawide = false,
  writeCVars = true,
}

local PRESETS = {
  small = 0.90,
  medium = 1.00,
  large = 1.10,
}

local function CopyDefaults()
  PixelPerfectUIScaleDB = PixelPerfectUIScaleDB or {}
  for k, v in pairs(DEFAULTS) do
    if PixelPerfectUIScaleDB[k] == nil then
      PixelPerfectUIScaleDB[k] = v
    end
  end
end
CopyDefaults()

local function dprint(fmt, ...)
  if PixelPerfectUIScale_Debug and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff46c7ff[PPScale]|r " .. string.format(fmt, ...))
  end
end

local function Clamp(v, minV, maxV)
  v = tonumber(v) or minV
  if v < minV then return minV end
  if v > maxV then return maxV end
  return v
end

local function IsSimilar(a, b)
  return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < TOLERANCE
end

local function IsEditModeActive()
  if EditModeManagerFrame and EditModeManagerFrame.editModeActive then
    return EditModeManagerFrame.editModeActive
  end
  if C_EditMode and C_EditMode.IsEditModeActive then
    return C_EditMode.IsEditModeActive()
  end
  return false
end

local function GetPhysicalSize()
  if type(GetPhysicalScreenSize) == "function" then
    local w, h = GetPhysicalScreenSize()
    if w and h and w > 0 and h > 0 then return w, h end
  end
  if type(GetScreenWidth) == "function" and type(GetScreenHeight) == "function" then
    local w, h = GetScreenWidth(), GetScreenHeight()
    if w and h and w > 0 and h > 0 then return w, h end
  end
  if UIParent and UIParent.GetWidth and UIParent.GetHeight and UIParent.GetScale then
    local s = UIParent:GetScale() or 1
    return UIParent:GetWidth() * s, UIParent:GetHeight() * s
  end
end

local function NormalisedWidth(width, height)
  if PixelPerfectUIScaleDB.multiMonitor and width and width >= 3840 then
    if width >= 9840 then return 3280 end
    if width >= 7680 then return 2560 end
    if width >= 5760 then return 1920 end
    if width >= 5040 then return 1680 end
    if width >= 4800 and height == 900 then return 1600 end
    if width >= 4320 then return 1440 end
    if width >= 4080 then return 1360 end
    return 1224
  end

  if PixelPerfectUIScaleDB.ultrawide and width and width >= 2560 then
    if width >= 3440 and (height == 1440 or height == 1600) then return 2560 end
    if width >= 2560 and (height == 1080 or height == 1200) then return 1920 end
  end
end

local function BaseScale()
  local _, h = GetPhysicalSize()
  if not h or h <= 0 then return nil end
  return 768 / h
end

local function GetModifier()
  PixelPerfectUIScaleDB.modifier = Clamp(PixelPerfectUIScaleDB.modifier or 1, 0.5, 3.0)
  return PixelPerfectUIScaleDB.modifier
end

local function DesiredScale()
  local base = BaseScale()
  if not base then return nil end

  if PixelPerfectUIScaleDB.mode == "manual" and PixelPerfectUIScaleDB.uiScale then
    return Clamp(PixelPerfectUIScaleDB.uiScale, 0.4, 1.15)
  end

  return Clamp(base * GetModifier(), 0.4, 1.15)
end

local function ApplyGameMenuScale()
  local scale = Clamp(PixelPerfectUIScaleDB.gameMenuScale or 1, 0.25, 1.5)
  PixelPerfectUIScaleDB.gameMenuScale = scale

  local frames = { _G.GameMenuFrame, _G.SettingsPanel, _G.InterfaceOptionsFrame }
  for _, frame in ipairs(frames) do
    if frame and frame.SetScale then frame:SetScale(scale) end
  end
end

local function SyncCVars(want)
  if not TOUCH_CVARS or not PixelPerfectUIScaleDB.writeCVars or not SetCVar or not GetCVar then return end
  if InCombatLockdown and InCombatLockdown() then return end

  if tonumber(GetCVar("useUiScale") or 0) ~= 1 then
    SetCVar("useUiScale", "1")
    dprint("Set useUiScale=1")
  end

  local current = tonumber(GetCVar("uiScale") or 0)
  if not IsSimilar(current, want) then
    SetCVar("uiScale", tostring(want))
    dprint("Set CVar uiScale -> %.5f", want)
  end
end

local function FixNamePlates()
  if InCombatLockdown and InCombatLockdown() then
    pendingNameplateFix = true
    return
  end

  if NamePlateDriverFrame then
    if NamePlateDriverFrame.SetIgnoreParentScale then NamePlateDriverFrame:SetIgnoreParentScale(true) end
    if NamePlateDriverFrame.SetScale then NamePlateDriverFrame:SetScale(1) end
  end

  pendingNameplateFix = false
end

local function ResizeUIParentForMonitorMode()
  if not UIParent then return end

  local physicalW, physicalH = GetPhysicalSize()
  local screenW, screenH = GetScreenWidth and GetScreenWidth(), GetScreenHeight and GetScreenHeight()
  if not physicalW or not physicalH or not screenW or not screenH then return end

  local newW = NormalisedWidth(physicalW, physicalH)
  if newW then
    UIParent:SetSize(newW / (physicalH / screenH), screenH)
  else
    UIParent:SetSize(screenW, screenH)
  end
end

local function TrySetScale(want, reason)
  if IsEditModeActive() then
    pending = true
    dprint("Blocked scale apply (%s): Edit Mode active", reason or "unknown")
    return false
  end

  if InCombatLockdown and InCombatLockdown() then
    pending = true
    dprint("Blocked scale apply (%s): in combat", reason or "unknown")
    return false
  end

  SyncCVars(want)
  UIParent:SetScale(want)
  ResizeUIParentForMonitorMode()
  FixNamePlates()
  ApplyGameMenuScale()
  return true
end

function PixelPerfectUIScale_Apply(force)
  pending = false

  if IsEditModeActive() then
    pending = true
    dprint("Edit Mode active; deferring scale apply")
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    pending = true
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff7f00[PPScale]|r UI scale update deferred until after combat.")
    end
    return
  end

  local want = DesiredScale()
  if not want then
    pending = true
    dprint("No screen height yet; will retry")
    return
  end

  local current = UIParent:GetScale()
  if force or not IsSimilar(current, want) then
    if TrySetScale(want, "apply") then
      dprint("Applied UIParent:SetScale(%.5f) (was %.5f)", want, current or -1)
    end

    for _, delay in ipairs({0.25, 0.75, 1.25}) do
      C_Timer.After(delay, function()
        if IsEditModeActive() or (InCombatLockdown and InCombatLockdown()) then
          pending = true
          return
        end
        if not IsSimilar(UIParent:GetScale(), want) then
          TrySetScale(want, "reapply")
          dprint("Re-applied after %.2fs; now %.5f", delay, UIParent:GetScale())
        end
      end)
    end
  else
    SyncCVars(want)
    ResizeUIParentForMonitorMode()
    ApplyGameMenuScale()
    dprint("Scale within tolerance (want %.5f, have %.5f)", want, current)
  end
end

local function HookEditMode()
  if PixelPerfectUIScale_EditModeHooked or not hooksecurefunc then return end

  local editModeFrame = EditModeManagerFrame
  if not editModeFrame then return end

  local hasEnterEditMode = type(editModeFrame.EnterEditMode) == "function"
  local hasExitEditMode  = type(editModeFrame.ExitEditMode) == "function"

  -- Classic clients can expose EditModeManagerFrame without the Retail Edit Mode
  -- methods. hooksecurefunc errors if asked to hook a missing function, so skip
  -- these hooks unless the methods are actually available.
  if not hasEnterEditMode and not hasExitEditMode then
    dprint("Edit Mode hooks skipped: EnterEditMode/ExitEditMode unavailable")
    return
  end

  if hasEnterEditMode then
    hooksecurefunc(editModeFrame, "EnterEditMode", function()
      pending = true
      dprint("Entered Edit Mode; blocking scale applies")
    end)
  end

  if hasExitEditMode then
    hooksecurefunc(editModeFrame, "ExitEditMode", function()
      C_Timer.After(0.10, function()
        if not IsEditModeActive() then
          dprint("Exited Edit Mode; re-applying scale")
          PixelPerfectUIScale_Apply(true)
        end
      end)
    end)
  end

  PixelPerfectUIScale_EditModeHooked = true
end

if C_CVar and C_CVar.RegisterCVarChangedCallback then
  C_CVar.RegisterCVarChangedCallback(function(name)
    if name == "uiScale" or name == "useUiScale" then
      C_Timer.After(0.05, function()
        if IsEditModeActive() then pending = true return end
        PixelPerfectUIScale_Apply(true)
      end)
    end
  end, "PixelPerfectUIScale")
end

-- Settings UI -----------------------------------------------------------------
local panel
local function MakeLabel(parent, text, size)
  local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  fs:SetText(text)
  fs:SetTextColor(1, 0.82, 0)
  fs:SetJustifyH("LEFT")
  if size then fs:SetFontObject(size) end
  return fs
end

local function MakeSection(parent, title, top)
  local label = MakeLabel(parent, title)
  label:SetPoint("TOPLEFT", 16, top)

  -- Keep the settings panel native-looking by avoiding heavy section backdrops.
  -- The Blizzard Options frame already provides the panel background.
  local section = CreateFrame("Frame", nil, parent)
  section:SetPoint("TOPLEFT", 16, top - 16)
  section:SetPoint("RIGHT", -16, 0)
  section:SetHeight(86)
  return section, label
end

local function MakeCheck(parent, text)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb.Text:SetText(text)
  cb.Text:SetTextColor(1, 1, 1)
  return cb
end

local function MakeButton(parent, text, width)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetText(text)
  b:SetSize(width or 100, 24)
  return b
end

local function PrepareEditBox(box, slider)
  -- Keep the numeric input above the slider hit area. Without this, the
  -- OptionsSliderTemplate can catch the first click and move the slider
  -- when the user is trying to type a value.
  box:EnableMouse(true)
  box:SetFrameLevel((slider:GetFrameLevel() or 1) + 10)
  box:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
  end)
  box:SetScript("OnMouseDown", function(self)
    self:SetFocus()
  end)
end

local function RefreshPanel()
  if not panel then return end
  local want = DesiredScale() or 1
  panel.uiSlider:SetValue(want)
  panel.uiValue:SetText(string.format("%.2f", want))
  panel.menuSlider:SetValue(PixelPerfectUIScaleDB.gameMenuScale or 1)
  panel.menuValue:SetText(string.format("%.2f", PixelPerfectUIScaleDB.gameMenuScale or 1))
  panel.multi:SetChecked(PixelPerfectUIScaleDB.multiMonitor)
  panel.ultra:SetChecked(PixelPerfectUIScaleDB.ultrawide)
  panel.cvars:SetChecked(PixelPerfectUIScaleDB.writeCVars)
end

local function BuildSettingsPanel()
  if panel then return panel end

  panel = CreateFrame("Frame")
  panel.name = "PixelPerfectUIScale"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("PixelPerfectUIScale")

  local monitor = MakeSection(panel, "Monitor", -48)
  local multi = MakeCheck(monitor, "Multi-Monitor Support")
  multi:SetPoint("TOPLEFT", 0, -10)
  multi:SetScript("OnClick", function(self)
    PixelPerfectUIScaleDB.multiMonitor = self:GetChecked() and true or false
    PixelPerfectUIScale_Apply(true)
  end)
  panel.multi = multi

  local ultra = MakeCheck(monitor, "Ultrawide Support")
  ultra:SetPoint("LEFT", multi, "RIGHT", 165, 0)
  ultra:SetScript("OnClick", function(self)
    PixelPerfectUIScaleDB.ultrawide = self:GetChecked() and true or false
    PixelPerfectUIScale_Apply(true)
  end)
  panel.ultra = ultra

  local cvars = MakeCheck(monitor, "Save scale to WoW CVars")
  cvars:SetPoint("LEFT", ultra, "RIGHT", 165, 0)
  cvars:SetScript("OnClick", function(self)
    PixelPerfectUIScaleDB.writeCVars = self:GetChecked() and true or false
    PixelPerfectUIScale_Apply(true)
  end)
  panel.cvars = cvars

  local ui = MakeSection(panel, "UI Scale", -138)
  local uiText = MakeLabel(ui, "UI Scale")
  uiText:SetPoint("TOPLEFT", 58, -8)

  local uiSlider = CreateFrame("Slider", nil, ui, "OptionsSliderTemplate")
  uiSlider:SetPoint("TOPLEFT", 0, -36)
  uiSlider:SetSize(160, 14)
  uiSlider:SetMinMaxValues(0.4, 1.15)
  uiSlider:SetValueStep(0.01)
  uiSlider:SetObeyStepOnDrag(true)
  uiSlider.Low:SetText("0.4")
  uiSlider.High:SetText("1.15")
  uiSlider.Text:SetText("")
  panel.uiSlider = uiSlider

  local uiValue = CreateFrame("EditBox", nil, ui, "InputBoxTemplate")
  uiValue:SetSize(70, 20)
  uiValue:SetPoint("TOP", uiSlider, "BOTTOM", 0, -10)
  uiValue:SetAutoFocus(false)
  uiValue:SetJustifyH("CENTER")
  PrepareEditBox(uiValue, uiSlider)
  panel.uiValue = uiValue

  uiSlider:SetScript("OnValueChanged", function(_, value)
    value = Clamp(value, 0.4, 1.15)
    PixelPerfectUIScaleDB.mode = "manual"
    PixelPerfectUIScaleDB.uiScale = value
    if panel and panel.uiValue and not panel.uiValue:HasFocus() then panel.uiValue:SetText(string.format("%.2f", value)) end
    PixelPerfectUIScale_Apply(false)
  end)

  uiValue:SetScript("OnEnterPressed", function(self)
    local value = Clamp(self:GetText(), 0.4, 1.15)
    PixelPerfectUIScaleDB.mode = "manual"
    PixelPerfectUIScaleDB.uiScale = value
    self:ClearFocus()
    PixelPerfectUIScale_Apply(true)
    RefreshPanel()
  end)
  uiValue:SetScript("OnEscapePressed", function(self) self:ClearFocus(); RefreshPanel() end)

  local small = MakeButton(ui, "Small")
  small:SetPoint("LEFT", uiSlider, "RIGHT", 8, 0)
  small:SetScript("OnClick", function()
    PixelPerfectUIScaleDB.mode = "preset"; PixelPerfectUIScaleDB.modifier = PRESETS.small; PixelPerfectUIScaleDB.uiScale = nil
    PixelPerfectUIScale_Apply(true); RefreshPanel()
  end)

  local medium = MakeButton(ui, "Medium")
  medium:SetPoint("LEFT", small, "RIGHT", 4, 0)
  medium:SetScript("OnClick", function()
    PixelPerfectUIScaleDB.mode = "preset"; PixelPerfectUIScaleDB.modifier = PRESETS.medium; PixelPerfectUIScaleDB.uiScale = nil
    PixelPerfectUIScale_Apply(true); RefreshPanel()
  end)

  local large = MakeButton(ui, "Large")
  large:SetPoint("LEFT", medium, "RIGHT", 4, 0)
  large:SetScript("OnClick", function()
    PixelPerfectUIScaleDB.mode = "preset"; PixelPerfectUIScaleDB.modifier = PRESETS.large; PixelPerfectUIScaleDB.uiScale = nil
    PixelPerfectUIScale_Apply(true); RefreshPanel()
  end)

  local auto = MakeButton(ui, "Auto Scale")
  auto:SetPoint("LEFT", large, "RIGHT", 4, 0)
  auto:SetScript("OnClick", function()
    PixelPerfectUIScaleDB.mode = "auto"; PixelPerfectUIScaleDB.modifier = 1; PixelPerfectUIScaleDB.uiScale = nil
    PixelPerfectUIScale_Apply(true); RefreshPanel()
  end)

  local menu = MakeSection(panel, "Game Menu", -246)
  local menuText = MakeLabel(menu, "Scale")
  menuText:SetPoint("TOPLEFT", 68, -8)

  local menuSlider = CreateFrame("Slider", nil, menu, "OptionsSliderTemplate")
  menuSlider:SetPoint("TOPLEFT", 0, -36)
  menuSlider:SetSize(160, 14)
  menuSlider:SetMinMaxValues(0.25, 1.5)
  menuSlider:SetValueStep(0.01)
  menuSlider:SetObeyStepOnDrag(true)
  menuSlider.Low:SetText("0.25")
  menuSlider.High:SetText("1.5")
  menuSlider.Text:SetText("")
  panel.menuSlider = menuSlider

  local menuValue = CreateFrame("EditBox", nil, menu, "InputBoxTemplate")
  menuValue:SetSize(70, 20)
  menuValue:SetPoint("TOP", menuSlider, "BOTTOM", 0, -10)
  menuValue:SetAutoFocus(false)
  menuValue:SetJustifyH("CENTER")
  PrepareEditBox(menuValue, menuSlider)
  panel.menuValue = menuValue

  menuSlider:SetScript("OnValueChanged", function(_, value)
    PixelPerfectUIScaleDB.gameMenuScale = Clamp(value, 0.25, 1.5)
    if panel and panel.menuValue and not panel.menuValue:HasFocus() then panel.menuValue:SetText(string.format("%.2f", PixelPerfectUIScaleDB.gameMenuScale)) end
    ApplyGameMenuScale()
  end)

  menuValue:SetScript("OnEnterPressed", function(self)
    PixelPerfectUIScaleDB.gameMenuScale = Clamp(self:GetText(), 0.25, 1.5)
    self:ClearFocus(); ApplyGameMenuScale(); RefreshPanel()
  end)
  menuValue:SetScript("OnEscapePressed", function(self) self:ClearFocus(); RefreshPanel() end)

  panel:SetScript("OnShow", RefreshPanel)

  if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "PixelPerfectUIScale")
    Settings.RegisterAddOnCategory(category)
    PixelPerfectUIScale_SettingsCategoryID = category.ID
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end

  return panel
end

local function OpenSettings()
  BuildSettingsPanel()
  if Settings and Settings.OpenToCategory and PixelPerfectUIScale_SettingsCategoryID then
    Settings.OpenToCategory(PixelPerfectUIScale_SettingsCategoryID)
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
  end
end

SLASH_PIXELPERFECTUISCALE1 = "/ppscale"
SlashCmdList.PIXELPERFECTUISCALE = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

  if msg == "debug" then
    PixelPerfectUIScale_Debug = not PixelPerfectUIScale_Debug
    print("PPScale debug:", PixelPerfectUIScale_Debug and "ON" or "OFF")
  elseif msg == "now" then
    PixelPerfectUIScale_Apply(true)
  elseif msg == "options" or msg == "config" or msg == "settings" then
    OpenSettings()
  elseif msg == "status" then
    local base = BaseScale()
    local want = DesiredScale()
    local have = UIParent:GetScale()
    print(string.format("PPScale status: mode %s, base %.5f, modifier %.2f, want %.5f, have %.5f, CVars %s",
      PixelPerfectUIScaleDB.mode or "auto", base or -1, GetModifier(), want or -1, have or -1, PixelPerfectUIScaleDB.writeCVars and "ON" or "OFF"))
  elseif msg:match("^modifier%s") then
    local num = msg:match("^modifier%s+([%d%.]+)")
    if num then
      PixelPerfectUIScaleDB.mode = "preset"
      PixelPerfectUIScaleDB.modifier = Clamp(num, 0.5, 3.0)
      PixelPerfectUIScaleDB.uiScale = nil
      print(string.format("PPScale modifier set to %.2f.", PixelPerfectUIScaleDB.modifier))
      PixelPerfectUIScale_Apply(true)
      RefreshPanel()
    else
      print(string.format("PPScale modifier is %.2f. Usage: /ppscale modifier <number>  (0.5–3.0)", GetModifier()))
    end
  elseif msg == "cvars on" then
    PixelPerfectUIScaleDB.writeCVars = true
    print("PPScale: CVar syncing ON.")
    PixelPerfectUIScale_Apply(true)
  elseif msg == "cvars off" then
    PixelPerfectUIScaleDB.writeCVars = false
    print("PPScale: CVar syncing OFF.")
  else
    print("/ppscale options        - open settings")
    print("/ppscale now            - force reapply immediately")
    print("/ppscale status         - show desired vs current scale")
    print("/ppscale modifier <n>   - multiply 768/h by <n> (0.5–3.0)")
    print("/ppscale cvars on|off   - allow/deny writing uiScale/useUiScale CVars")
    print("/ppscale debug          - toggle verbose logging")
  end
end

for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "DISPLAY_SIZE_CHANGED", "PLAYER_REGEN_ENABLED" }) do
  f:RegisterEvent(event)
end

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    CopyDefaults()
    HookEditMode()
    BuildSettingsPanel()
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if pending then PixelPerfectUIScale_Apply(true) end
    if pendingNameplateFix then FixNamePlates() end
    return
  end

  local now = GetTime and GetTime() or 0
  if now < throttleUntil then return end
  throttleUntil = now + THROTTLE_SEC

  C_Timer.After(0.05, function()
    pending = true
    PixelPerfectUIScale_Apply(false)
  end)
end)
