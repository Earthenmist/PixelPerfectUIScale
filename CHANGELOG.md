## 🧩 Addon Updates (2026-08-07)

**PixelPerfectUIScale** — v1.4.15  

**Changes:**  
• Added bounded startup/world-entry retry handling so `/reload` inside Mythic+ or other instances can reapply the desired UI scale without needing to leave the dungeon.  
• Coalesced overlapping startup retries and reduced repeated combat-defer chat messages.   

**Fixes:**  
• Fixed cases where Blizzard UI rebuild timing after an in-instance reload could leave the UI at the wrong scale until zoning.

**Known issues:**  
• None currently known.
