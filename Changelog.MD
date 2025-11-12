📜 Changelog – Version 1.3.0  
📅 Release Date: 12-11-2025  
  
🛠️ Changes & Improvements:  
  
✅ New Slash Command:  
Added /ppscale modifier <number> to customize your personal scale multiplier.  
Example: /ppscale modifier 1.5  
Useful for 4K and ultrawide displays where the default 768 / height scale appears too small.  
Supports values from 0.5× to 3.0×.  
Setting is saved between sessions.  
  
✅ Enhanced Debug & Control:  
/ppscale status now shows base, modifier, and resulting scale values.  
Added proper feedback when enabling/disabling CVar writes (/ppscale cvars on|off).  
  
✅ Midnight Beta Compatibility:  
Confirmed fully compatible with new combat restrictions.  
Scale updates and CVar writes are safely deferred during combat and re-applied on PLAYER_REGEN_ENABLED.  
Optional chat message can notify when scale updates are postponed due to combat.  
  
✅ Stability & UX:  
Improved internal validation and clamping for user-set modifiers (range limited to 0.5–3.0).  
Cleaned up debug output for consistency with retail client logging style.  
  
⚠️ Known Issues / Notes:  
UI scale changes are deferred while in combat (intentional for Midnight).  
Excessive modifier values may cause UI distortion; 1.0–1.7 recommended for 4K displays.  
  
🚀 Thank you for using Pixel Perfect UI Scale!  
If you have suggestions or feature requests, please share them on our Discord or GitHub.  
