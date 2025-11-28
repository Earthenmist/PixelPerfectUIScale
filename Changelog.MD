📜 Changelog – Version 1.3.1-Beta  
📅 Release Date: 28-11-2025  
  
🛠️ Changes & Improvements:  
  
✅ Fixed  
Resolved an issue where Edit Mode’s *snap to elements* feature stopped working while the addon was enabled.  
  The addon was listening to `EDIT_MODE_LAYOUTS_UPDATED` and reapplying UIParent scale during layout updates, which interfered with Edit Mode’s snapping logic.  
  This event hook has been removed to ensure Edit Mode behaves normally.  
  
### Notes  
- This is a minor hotfix release to improve UX while editing UI layouts.   
  
⚠️ Known Issues / Notes:  
UI scale changes are deferred while in combat (intentional for Midnight).  
Excessive modifier values may cause UI distortion; 1.0–1.7 recommended for 4K displays.  
  
🚀 Thank you for using Pixel Perfect UI Scale!  
If you have suggestions or feature requests, please share them on our Discord or GitHub.  
