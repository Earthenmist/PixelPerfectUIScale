## :jigsaw: Addon Updates (2026-01-30)

**PixelPerfectUIScale** — v1.4.5  

**Changes:**  
• UI scale is now applied more conservatively to prioritise Edit Mode stability.  
• CVar enforcement is now **disabled by default** for the best Edit Mode experience.  
• Users can still manually enable CVar enforcement via: `/ppscale cvars on`

**Fixes:**  
• Improved compatibility with Edit Mode’s **Snap to Elements** system.  
• Removed automatic enforcement of Blizzard UI scale CVars (`useUiScale`, `uiScale`) which could cause snapping inconsistencies.  
• Stopped listening to `UI_SCALE_CHANGED` events to prevent unwanted scale reapplication while using Edit Mode.

**Known issues:**  
• None currently known.
