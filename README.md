# PixelPerfectUIScale
PixelPerfectUIScale is a lightweight addon that ensures your World of Warcraft UI always uses a pixel-perfect scale.
It calculates the correct scale (768 / screenHeight) and applies it automatically when the game loads, when display settings change, or when Edit Mode is applied.

Background

This addon is a direct conversion of the WeakAura “Pixel perfect ui scale” created by potat0nerd.
With the WeakAuras team announcing that there will be no “midnight release” of WeakAuras for future expansions, we wanted to preserve the functionality of this WA in a standalone addon that does not depend on WeakAuras.

Features

Automatically enforces pixel-perfect scale (768 / screenHeight)

Listens for scale-changing events:
PLAYER_LOGIN, PLAYER_ENTERING_WORLD, DISPLAY_SIZE_CHANGED, UI_SCALE_CHANGED, EDIT_MODE_LAYOUTS_UPDATED

Safe handling during combat (applies after leaving combat if needed)

Optionally syncs Blizzard’s uiScale CVars so Settings UI stays consistent

/ppscale commands:

/ppscale status – show desired vs current scale

/ppscale debug – toggle verbose output

/ppscale now – force reapply immediately

/ppscale cvars on/off – toggle whether to write CVars

Why use this instead of the WA?

No dependency on WeakAuras

Lightweight, always active

Future-proof: will continue working even if WA isn’t updated immediately for new expansions

Installation

Download and extract into your WoW Interface/AddOns/ folder.
Path example: World of Warcraft/_retail_/Interface/AddOns/PixelPerfectUIScale/

Make sure the addon is enabled in the AddOns menu.

Type /ppscale status in-game to confirm.

Credits

Original WeakAura: “Pixel perfect ui scale” by potat0nerd – https://wago.io/_F7SrQJMS

Converted and maintained as an addon by Lanni of Alonsus
