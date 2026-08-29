## 🧩 Addon Updates (2026-08-29)

**PixelPerfectUIScale** — v1.4.16-Release

**Changes:**  
• Updated TOC interface declarations to the current live Retail and supported Classic client versions.
• Bumped release metadata to `1.4.16-Release` in both TOC files.
• Updated maintained author and support references to Earthenmist.
• Clarified README compatibility and install notes for Retail and supported Classic clients.
• Added bounded startup/world-entry retry handling so `/reload` inside Mythic+ or other instances can reapply the desired UI scale without needing to leave the dungeon.  
• Coalesced overlapping startup retries and reduced repeated combat-defer chat messages.   

**Fixes:**  
• Fixed cases where Blizzard UI rebuild timing after an in-instance reload could leave the UI at the wrong scale until zoning.

**Known issues:**  
• None currently known.
