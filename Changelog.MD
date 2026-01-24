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
