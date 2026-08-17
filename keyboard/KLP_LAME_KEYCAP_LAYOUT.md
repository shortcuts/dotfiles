# KLP Lame Keycaps — SplitKB Halcyon Elora v2 (Choc)

Repo: https://github.com/braindefender/KLP-Lame-Keycaps

## Switch type
Elora v2 (choc build) — Kailh Choc low-profile switches. **MX-stem keycaps will NOT fit.** Confirm repo has a choc/low-profile STEP variant before printing.

## Bambu Studio STEP import settings
- Linear Deflection: 0.003 (lower to 0.001–0.002 if curves look faceted)
- Angle Deflection: 0.50
- Split compound and compsolid into multiple objects: **checked** (file bundles multiple keycap bodies)

## Row → profile mapping
| Row | Profile |
|---|---|
| Number row | Saddle Tilted (best guess — verify against repo row-mapping diagram if present) |
| Top row | Saddle Tilted |
| Home row | Saddle |
| Bottom row | Saddle Tilted |
| Thumb cluster (7 keys/half) | Thumb |

Note: no dedicated numrow profile confirmed in repo — check README/folder names for a `Numrow`/`Flat` profile before finalizing.

## Imported STL files (`keyboard/`)
Elora v2 total key math: 6 cols × 2 halves × 4 rows = 48 main keys + 14 thumb = 62 ✓

| File | Count | Notes |
|---|---|---|
| `Choc_Stem_Choc_Size_Thumb.stl` | 14 | 7 thumb keys × 2 halves |
| `Choc_Stem_Choc_Size_Saddle_Homing.stl` | 2 | F/J-equivalent home row bump, 1 per half |
| `Choc_Stem_Choc_Size_Saddle_Tilted.stl` | 36 | number + top + bottom rows: 6 keys/row × 3 rows × 2 halves |
| `Choc_Stem_Choc_Size_Saddle.stl` | 10 | home row minus 2 homing keys |

Total keycaps: 14+2+36+10 = **62**
