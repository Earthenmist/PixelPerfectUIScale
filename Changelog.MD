📜 Changelog – Version 1.3.2  
📅 Release Date: 05-12-2025  
  
🛠️ Changes & Improvements:  
  
✅ Fixed  
Resolved an issue where Edit Mode’s *snap to elements* feature stopped working while the addon was enabled.  
  The addon was listening to `EDIT_MODE_LAYOUTS_UPDATED` and reapplying UIParent scale during layout updates, which interfered with Edit Mode’s snapping logic.  
  This event hook has been removed to ensure Edit Mode behaves normally.  
  
⚠️ Known Issues / Notes:  
- Midnight compatible  
  
🚀 Thank you for using Pixel Perfect UI Scale!  
If you have suggestions or feature requests, please share them on our Discord or GitHub.  
