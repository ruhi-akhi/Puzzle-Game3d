# Echo Labyrinth — Game Documentation (ruhi.md)

> **Echo Labyrinth** is a Dark Sci-Fi 2D Puzzle Game built with Flutter.
> Runs on Android (Play Store), Windows (PC), and Web (itch.io).

---

## Quick Start

```bash
cd "e:\Puzzle Game3d"
flutter pub get
flutter test
flutter run -d chrome     # Web (works without Developer Mode)
flutter run -d windows    # PC (requires Windows Developer Mode)
```

### Flutter Install (already done on this PC)
Flutter is installed at: `C:\Users\WALTON\flutter`
Added to user PATH. Open a **new terminal** and run `flutter --version`.

If Windows build fails with symlink error, enable **Developer Mode**:
`Settings → Privacy & Security → For developers → Developer Mode ON`
Or run: `start ms-settings:developers`

---

## Game Concept

Player is trapped in a mysterious labyrinth. Each level has a door or goal — solve puzzles with limited moves (20-50). Wrong moves require reset.

**Art Style:** Pixel Art feel, Dark Sci-Fi, Neon Glow (cyan/pink/purple), smooth animations.

---

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys / WASD | Move |
| On-screen buttons | Mobile touch |
| Refresh icon | Restart level |
| Undo icon | Undo last move |

---

## Mechanics (Implemented)

| Mechanic | World | Description |
|----------|-------|-------------|
| Movement | 1 | Grid-based movement |
| Key & Door | 1 | Collect key, open door |
| Push Box (Sokoban) | 1 | Push boxes onto goals |
| Laser | 2 | Avoid laser beams |
| Mirror | 2 | Reflect lasers with / and \ |
| Red/Blue Switch | 2 | Toggle doors |
| Ice Tile | 3 | Slide until stopped |
| Shadow Clone | 4 | Shadow copies previous moves |
| Gravity Flip | 5 | Flip gravity on pads |
| Teleporter | 6 | Warp between T and t |
| Move Limit | All | Run out = lose |
| Star Rating | All | Fewer moves = more stars |

---

## Tile Legend

| Char | Tile | Char | Tile |
|------|------|------|------|
| `#` | Wall | `K` | Key |
| `.` | Floor | `D` | Door |
| `@` | Player | `B` | Box |
| `G` | Goal | `L` | Laser |
| `/` | Mirror | `R` | Red Switch |
| `I` | Ice | `T/t` | Teleporter |
| `g` | Gravity Pad | `C` | Clone Spawn |

---

## Worlds & Levels (16 total)

| World | Name | Levels | Mechanic |
|-------|------|--------|----------|
| 1 | Tutorial | 5 | Movement, Keys, Boxes |
| 2 | Laser Lab | 3 | Laser, Mirror, Switch |
| 3 | Frozen Depths | 2 | Ice |
| 4 | Echo Chamber | 2 | Shadow Clone |
| 5 | Gravity Well | 2 | Gravity Flip |
| 6 | Final Mix | 2 | Teleporter, Mixed |

---

## Star System

- 3 stars: moves <= 50% of max
- 2 stars: moves <= 75% of max
- 1 star: level complete

---

## Project Structure

```
lib/
  main.dart
  game/models/     - tile_type, level_data, game_state
  game/systems/    - game_engine, laser_system
  game/services/   - level_loader, progress_service
  game/rendering/  - game_painter (neon graphics)
  ui/screens/      - menu, world select, level select, game
  ui/widgets/      - game_board, neon_button
assets/levels/     - JSON level files per world
test/              - unit tests
```

---

## Adding New Levels

Create `assets/levels/world_X/level_YY.json`:

```json
{
  "id": 106,
  "name": "My Level",
  "world": 1,
  "maxMoves": 25,
  "mechanics": ["movement"],
  "grid": ["##########", "#@.......#", "#.......G#", "##########"]
}
```

Update `levelCount` in `lib/game/models/level_data.dart`.

---

## Build & Publish

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Play Store AAB
flutter build windows --release      # Windows EXE
flutter build web --release          # itch.io (upload build/web/)
```

---

## Tech Stack

- Flutter 3.2+
- Flame Engine (dependency ready)
- CustomPainter for neon rendering
- JSON levels + SharedPreferences progress
- Google Fonts (Orbitron)

---

## Tests

```bash
flutter test
```

Tests cover: movement, walls, win condition, keys, box push, stars, JSON parsing.

---

## Roadmap

**Phase 1 (Done):** Core mechanics, 16 levels, UI, progress save, tests
**Phase 2:** 100+ levels, audio, level editor, bomb/time switch
**Phase 3:** Play Store, itch.io, ads, IAP

---

*Echo Labyrinth — June 2026*
