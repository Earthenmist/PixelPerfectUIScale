📜 Changelog – Version 1.4.5  
  
📅 Release Date: 30-01-2026  
  
🛠️ Changes & Improvements  
✅ Fixed  
  
Improved compatibility with Edit Mode’s Snap to Elements system.  
Removed automatic enforcement of Blizzard UI scale CVars (useUiScale, uiScale) which could cause snapping inconsistencies during layout adjustments.  
Stopped listening to UI_SCALE_CHANGED events to prevent unwanted scale reapplication while using Edit Mode.  
  
✅ Changes  
  
UI scale is now applied more conservatively to prioritise Edit Mode stability.  
Users can still manually enable CVar enforcement if desired via command:  
/ppscale cvars on  
  
⚠️ Notes  
  
CVar enforcement is disabled by default to ensure the best experience when frequently using Edit Mode.  
  
📜 Changelog – Version 1.4.4  
  
📅 Release Date: 29-01-2026  
  
🛠️ Changes & Improvements  
✅ Fixed  
  
Prevented UI scale from being re-applied while Edit Mode is active.  
Resolved delayed timers that could override scale during layout adjustments.  
Added safe re-application of UI scale after exiting Edit Mode.  
  
✅ Improvements  
  
Reduced interference with frame positioning and snapping behaviour.  
Improved overall stability when opening and closing Edit Mode.  
  
📜 Changelog – Version 1.4.3  

📅 Release Date: 24-01-2026  

🛠️ Changes & Improvements  
✅ Fixed  

Resolved ADDON_ACTION_BLOCKED errors caused by attempting to call :SetScale() on individual nameplate frames (protected).  
Nameplates are now excluded safely by setting NamePlateDriverFrame to ignore parent scaling and enforcing scale 1 on the driver container only.  
Nameplate scale fixes are deferred until after combat when necessary.  

---

📜 Changelog – Version 1.4.1  
  
📅 Release Date: 24-01-2026  
  
🛠️ Changes & Improvements  
✅ Fixed  
  
Nameplates are now excluded from the enforced UIParent scale to prevent unintended shrinking or double-scaling when using nameplate addons (e.g. Platynator).  
The addon now re-asserts nameplate container scale after applying UI scale and when new nameplates are created.  
  
---

📜 Changelog – Version 1.4.0  
  
📅 Release Date: 14-01-2026  
  
🛠️ Changes & Improvements  
✅ Fixed  
  
Resolved an issue where Edit Mode’s “snap to elements” feature stopped working while the addon was enabled.  
The addon was listening to EDIT_MODE_LAYOUTS_UPDATED and reapplying UIParent scale during layout updates, which interfered with Edit Mode snapping.  
This event hook has been removed to ensure Edit Mode behaves normally.  
  
✅ Compatibility  
  
Now supports all versions of WoW Classic, including:  
  
Classic Era  
Hardcore  
Season of Discovery  
The Burning Crusade Classic  
Mists of Pandaria Classic  
  
⚠️ Known Issues / Notes  
  
Fully compatible with Retail and Midnight clients.  
  
🚀 Thank you for using Pixel Perfect UI Scale!  
  
If you have suggestions or feature requests, please share them in the comments on CurseForge or on GitHub.  
