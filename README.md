# PixelPerfectUIScale

**PixelPerfectUIScale** is a lightweight World of Warcraft addon that ensures your UI always uses a **pixel-perfect scale**.

It calculates the correct scale using:

`768 / screenHeight`

…and applies it automatically on login and whenever display or UI scale settings change.

## ✨ Features
- Automatically enforces pixel-perfect UI scale (`768 / screenHeight`)
- Optional custom modifier for 4K / ultrawide monitors  
  - `/ppscale modifier <number>`
  - Example: `/ppscale modifier 1.5` → `(768 / screenHeight) × 1.5`
  - Supports values between **0.5 and 3.0**
  - Saved between sessions
- Safe handling during combat (scale changes are deferred until after combat)
- Listens for key scale-related events:
  - `PLAYER_LOGIN`
  - `PLAYER_ENTERING_WORLD`
  - `DISPLAY_SIZE_CHANGED`
  - `UI_SCALE_CHANGED`
  - `EDIT_MODE_LAYOUTS_UPDATED`
- Optional syncing of Blizzard `uiScale` CVars so the Settings UI stays consistent
- Midnight-compatible (no protected calls or combat taint)

## 💬 Slash Commands
| Command | Description |
|--------|-------------|
| `/ppscale status` | Show desired vs current scale (base, modifier, and result) |
| `/ppscale modifier <num>` | Set a multiplier for custom scaling (e.g. `1.25`) |
| `/ppscale now` | Force scale reapply immediately |
| `/ppscale debug` | Toggle verbose debug output |
| `/ppscale cvars on/off` | Toggle writing to Blizzard `uiScale` CVars |

## ❓ Why use this instead of the WeakAura?
- No dependency on WeakAuras
- Lightweight and always active
- Midnight-safe — handles combat restrictions automatically
- Future-proof — continues working even if WeakAuras is not updated for future expansions

## 📦 Install
### CurseForge
- Install via the CurseForge app or download the latest release.

### Manual
1. Download the latest release `.zip`.
2. Extract into: `World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure the folder name is `PixelPerfectUIScale` (not nested).
4. Relaunch the game.

## 🧩 Compatibility
- **Game:** Retail
- **Era:** The War Within / Midnight-ready
- **Dependencies:** None

## 💬 Support & Community
For bug reports, feature requests, release notes, and beta builds, join the official Discord:

**LanniOfAlonsus • Addon Hub**  
https://discord.gg/U8mKfHpeeP

## ❤️ Credits
- Original WeakAura: **“Pixel perfect ui scale”** by **potat0nerd**
- Addon conversion & maintenance: **LanniOfAlonsus**

## 📜 License
All Rights Reserved.
