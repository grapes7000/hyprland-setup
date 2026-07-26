# hyprland-setup Design System

## 1. Atmosphere & Identity

A compact, theme-driven command surface for Hyprland. Its signature is dense information with calm tonal grouping: the bar stays quiet until an active workspace or urgent system state needs attention.

## 2. Color

All color comes from `waybar/generated/theme.css`, generated from the active theme.

| Role | Token | Usage |
|---|---|---|
| Raised surface | `@bg_alt` | Grouped module backgrounds |
| Primary text | `@text` | Readable metadata |
| Muted text | `@text_dim` | Empty workspace indicators |
| Active accent | `@accent` | Active workspace and focused controls |
| Secondary accent | `@accent2` | Secondary status information |
| Urgent | `@urgent` | Error and urgent state |
| ANSI categories | active theme JSON `ansi_*` roles | Workspace app-category icons |

## 3. Typography

- Primary and mono: `JetBrainsMono Nerd Font`.
- Bar text: 13px; inactive workspace indicators: 12px; active workspace indicators: 13px.
- Icons are Nerd Font glyphs, emitted by scripts as UTF-8 byte escapes so source files remain ASCII-safe.

## 4. Spacing & Layout

- Base unit: 4px.
- Bar height: 34px; outer margin: 6px top and 10px horizontal.
- Module panels use 12px horizontal padding, 2px vertical padding, and 10px radius.
- Workspace buttons use 6px horizontal padding, 2px vertical padding, and 10px radius; their 6px module separation comes from the bar spacing token. Active buttons use 8px horizontal padding to accommodate the label.

## 5. Components

### Workspace button

- **Structure**: ten individual `custom/ws1` through `custom/ws10` Waybar modules. Each calls the shared workspace script with its ID and is independently clickable.
- **Interaction**: left click dispatches `hyprctl dispatch workspace <ID>`; keyboard workspace switching remains available.
- **Variants**: empty/inactive, occupied/inactive, active empty, active occupied.
- **States**: empty/inactive is its static role glyph in `@text_dim`; occupied/inactive is the dominant app-category glyph in an ANSI theme color; active is the resolved role/category glyph plus its static role label in `@accent`.
- **Sizing**: inactive buttons are icon-only at 12px; active buttons grow to 13px and add the role label while retaining the 34px bar height.
- **Accessibility**: every button emits a tooltip describing workspace role, occupancy, and dominant class. There are no numeric workspace labels or visual count bars.
- **Motion**: Waybar's existing 200ms transition applies; no additional animation.

## 6. Motion & Interaction

- Existing 200ms `cubic-bezier(0.4, 0, 0.2, 1)` transition is retained.
- Workspace state refreshes every second to match Waybar's custom-module execution contract.
- Workspace buttons provide direct pointer switching; keyboard switching remains available (`Super + 1..0`).

## 7. Depth & Surface

Tonal-shift: modules use `alpha(@bg_alt, 0.85)` grouping with no borders or shadows.

## 8. Accessibility Constraints & Accepted Debt

- Contrast follows each active theme's semantic roles; active and urgent states use their dedicated generated tokens.
- Accepted debt: workspace state is refreshed once per second, so tooltip and active-state changes can lag a Hyprland event by up to one second.
