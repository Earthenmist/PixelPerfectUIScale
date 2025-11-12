#PixelPerfectUIScale  
  
PixelPerfectUIScale is a lightweight addon that ensures your World of Warcraft UI always uses a pixel-perfect scale.  
It calculates the correct scale (768 / screenHeight) and applies it automatically when the game loads, when display settings change, or when Edit Mode is applied.  
  
🧩 Background  
This addon is a direct conversion of the WeakAura “Pixel perfect ui scale” created by potat0nerd.  
With the WeakAuras team announcing that there will be no “Midnight release” of WeakAuras for future expansions, we wanted to preserve the functionality of this WA in a standalone addon that does not depend on WeakAuras.  
  
⚙️ Features  
✅ Automatically enforces pixel-perfect scale (768 / screenHeight)  
✅ Optional custom modifier via /ppscale modifier <number>  
Multiplies the base scale to better fit 4K and ultrawide monitors  
Example: /ppscale modifier 1.5 → uses (768 / screenHeight) × 1.5  
Supports values between 0.5 and 3.0, saved between sessions  
✅ Safe handling during combat — scale changes are deferred until after combat  
✅ Listens for scale-related events:  
PLAYER_LOGIN  
PLAYER_ENTERING_WORLD  
DISPLAY_SIZE_CHANGED  
UI_SCALE_CHANGED  
EDIT_MODE_LAYOUTS_UPDATED  
✅ Optionally syncs Blizzard’s uiScale CVars so Settings UI remains consistent  
✅ Compatible with the Midnight client — no protected calls or combat taint  
  
💬 Slash Commands  
Command	Description  
/ppscale status	Show desired vs current scale (base, modifier, and result).  
/ppscale modifier <num>	Set a multiplier for custom scaling (e.g. 1.25).  
/ppscale now	Force scale reapply immediately.  
/ppscale debug	Toggle verbose debug output.  
/ppscale cvars on/off	Toggle whether to write to Blizzard uiScale CVars.  

❓ Why use this instead of the WeakAura?  
⚡ No dependency on WeakAuras  
🧠 Lightweight and always active  
🔒 Midnight-safe — handles combat restrictions automatically  
🏗️ Future-proof — continues working even if WA isn’t updated for new expansions  
🪄 Installation  
Download and extract into your WoW Interface/AddOns/ folder.  
Example path:  
World of Warcraft/_retail_/Interface/AddOns/PixelPerfectUIScale/  
Make sure the addon is enabled in the AddOns menu.  
Type /ppscale status in-game to confirm it’s working.  
Adjust your modifier if needed:  
/ppscale modifier 1.5  
  
👏 Credits  
Original WeakAura: “Pixel perfect ui scale” by potat0nerd  
Addon Conversion & Maintenance: Lanni of Alonsus  
