# Handoff: Artspiration — Dice Roll Art Prompt Generator

## Overview
A mobile app that helps hobbyist artists beat creative block: roll dice across six prompt categories (Medium, Mood, Palette, Style, Setting, Texture), lock the results you like, reroll the rest, and save combos to a personal gallery where you attach a photo of the finished piece.

## About the Design Files
The files in this bundle (`Dice Inspiration App.dc.html`, plus the `ios-frame.jsx` device bezel and `image-slot.js` placeholder helper it references) are **design references built in HTML/React** — a working prototype of the look and interactions, not production code to copy directly. The task is to **recreate this design in the target codebase's real environment** (e.g. React Native, SwiftUI, Flutter — whatever the app is actually built in) using that stack's own patterns, navigation, and persistence — not by embedding this HTML.

## Fidelity
**High-fidelity.** Colors, type, spacing, and interaction states below are final — recreate pixel-close using the target platform's native equivalents (the CSS box-shadow "sticker" style, hand-drawn border-radius asymmetry, and rotations should all be preserved).

## Screens / Views

### 1. Roll screen (default tab)
**Purpose:** Roll dice, lock favorites, reroll the rest, save a combo.

**Layout:** Single scrolling column, 18px side padding, 58px top padding (clears status bar). Header, then a 2-column CSS grid of 6 dice cards (14px gap), then a full-width "Roll All Dice" button, then a full-width "+ Save this roll to Gallery" outlined button. Fixed bottom tab bar (2 tabs, 10px gap, 10/18/22px padding).

**Header:** Small 26×26px rounded-square "die" icon (dark fill, 3 light dots) + "Artspiration" in Kalam 700 28px, both rotated -2°. Subhead "Lock what you like, reroll the rest" in Nunito 13px, muted brown (#6b5f4d).

**Dice card (×6 — Medium, Mood, Palette, Style, Setting, Texture):**
- Card: background #fffaf0, 2.5px solid #241c14 border, asymmetric corner radii (each card's 4 radii differ slightly, ~16-26px, to feel hand-drawn), 5px/5px solid offset shadow in #241c14 ("sticker" look), each card rotated a different small angle (-1.6° to 1.8°), 14px/12px padding.
- Top row: category label — Kalam 700 11.5px uppercase pill, white text on the category's accent color, 3px/9px padding, 8px radius, rotated ±2°. Lock toggle button on the right: Nunito 800 10px uppercase, 1.5px solid #241c14, 4px/9px padding, 8px radius — unlocked = transparent bg/dark text/label "Lock"; locked = filled #241c14 bg/cream text/label "Locked".
- Middle: current value in Kalam 700 19px, dark ink (#241c14), centered. While a die is rolling, the value flickers through random options every ~70-150ms for ~7 ticks (~600ms total) with a "wobble" rotate+scale animation, then settles.
- Bottom: "↻ Reroll" button, Nunito 700 12.5px, 2px solid #241c14, 7px padding, 10px radius. Disabled (dimmed, 0.6 opacity, background #e9e2d0, "not-allowed" cursor) when the die is locked.

**Category accent colors:**
| Category | Hex |
|---|---|
| Medium | #e2572b (coral) |
| Mood | #1f8a70 (teal) |
| Palette | #7c5cbf (purple) |
| Style | #c98a1f (mustard) |
| Setting | #2f6fb0 (blue) |
| Texture | #b23a6b (magenta) |

**Roll All button:** Full width, Kalam 700 22px, cream text on #241c14 fill, 2.5px border, asymmetric 20/26/22/28px radius, 5px/5px offset shadow in mustard (#c98a1f), rotated -0.8°, 16px padding. Rerolls every *unlocked* die simultaneously (same flicker animation, staggered naturally by independent timers).

**Save button:** Full width, Nunito 800 14px, dark text, cream fill, 2px dashed #241c14 border, 14px radius, 11px padding. Label: "+ Save this roll to Gallery". On tap: snapshots the current 6 die values into a new gallery entry (random -1.5° to 1.5° tilt) and switches to the Gallery tab.

### 2. Gallery screen
**Purpose:** Browse saved prompt combos and attach a photo of the resulting artwork.

**Layout:** Same scroll column. Header "Your Gallery" (Kalam 700 26px, rotated -1.5°) + count subhead ("No saved rolls yet" / "N saved roll(s)"). Below: either a vertical stack of gallery cards, or an empty state.

**Gallery card:** Background #fffaf0, 2.5px solid #241c14, 18/22/18/22px radius, 5px/5px offset shadow, 12px padding, random small tilt per card. Contents, stacked with 10px gap:
1. Image drop zone, 170px tall, rounded 12px corners, placeholder text "Drop your artwork here" — user drags/drops or picks a photo of their finished piece here.
2. Wrapping row of 6 small pill chips (Nunito 800 10.5px, white text, 3px/8px padding, 7px radius) — one per category, each in its accent color, showing that entry's rolled values.
3. "Remove" text button, bottom-right, Nunito 600 12px, muted red (#a34a3a), no border/background.

**Empty state:** Centered, 2.5px dashed border (#b3a688), 20px radius, 48px/20px padding. "Nothing here yet!" (Kalam 18px, #8a7c62) + "Roll some dice and save a combo to start your gallery." (Nunito 13px, #a3977f).

### Bottom tab bar (persistent, both screens)
Two full-width flex buttons, 2px solid #241c14 border, 14px radius, Nunito 800 13px. Active tab: filled #241c14 bg, cream text. Inactive: cream bg (#fffaf0), dark text. Labels: "▣ Roll" and "▤ Gallery" (glyphs are Unicode symbols, not icons — replace with real icons in production, e.g. a dice icon and a photo-grid icon).

## Interactions & Behavior
- **Reroll one die:** tap ↻ on an unlocked die → it flickers through random values in its category (~7 ticks, increasing interval, ~600ms) then settles on the final pick, excluding immediate repeat of its previous value where possible.
- **Lock/unlock:** tap Lock/Locked toggle. Locked dice are skipped by both individual reroll and Roll All.
- **Roll All:** rerolls every currently-unlocked die at once, independently animated.
- **Save to Gallery:** captures current 6 values (regardless of lock state) as a new entry at the top of the gallery list, then navigates to the Gallery tab.
- **Remove gallery entry:** deletes that card immediately, no confirmation.
- **Tab switch:** Roll / Gallery, simple state toggle, no transition animation currently.

## State Management
- `tab`: 'roll' | 'gallery'
- `dice`: object keyed by category → `{ value: string, locked: boolean, spinning: boolean }`
- `gallery`: array of `{ id, medium, mood, palette, style, setting, texture, imageUrl/imageRef, rotate }`, newest first
- Rolling is driven by a per-die timer chain (see Interactions above) — implement as a simple animated random-cycle rather than literal setTimeout chains in production if the platform offers better animation primitives.
- **Not yet implemented, worth asking the user about for the real app:** persisting gallery/dice state across sessions (likely needs local storage or a backend), and real image upload/storage for gallery photos (the prototype uses a placeholder drop zone).

## Design Tokens
**Colors:**
- Ink/text: #241c14
- Paper background: #f7f1e4 (with a subtle dot-grain texture: `radial-gradient(circle at 1px 1px, rgba(36,28,20,0.06) 1px, transparent 0)`, 14px tile)
- Card surface: #fffaf0
- Muted brown text: #6b5f4d, #8a7c62, #a3977f
- Category accents: see table above
- Disabled fill: #e9e2d0

**Typography:**
- Display/headings/die values: **Kalam** (Google Font), weight 700
- UI/body/labels: **Nunito** (Google Font), weights 400/600/800

**Shape language:** every card/button uses 4 *different* corner radii (16-28px range) rather than a uniform radius, plus a small rotation (-2° to 2°) — this asymmetry is core to the hand-drawn feel, not an accident to normalize away.

**Shadows:** flat offset "sticker" shadows only — `5px 5px 0 <color>` (no blur), never soft box-shadows.

**Borders:** 2-2.5px solid #241c14 throughout; dashed 2-2.5px for empty/add states.

## Assets
No custom icons or imagery — all decoration is CSS shapes (the die-dot logo, card borders/shadows). The gallery photo slot is a placeholder; production needs real image picker/upload. Fonts are loaded from Google Fonts (Kalam, Nunito) — bundle or link the platform-appropriate equivalents.

## Files
- `Dice Inspiration App.dc.html` — the full prototype (markup + logic)
- `ios-frame.jsx` — iPhone bezel used only to preview the app at phone scale; not part of the app itself
- `image-slot.js` — drag-and-drop image placeholder helper used for the gallery photo slots; reference only
