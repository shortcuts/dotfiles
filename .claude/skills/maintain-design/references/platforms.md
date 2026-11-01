# Platforms

Detect every surface the repo ships and inspect each in its own way.

| Surface | Find it | Inspect it | Tokens usually live in |
|---|---|---|---|
| Android Compose | `build.gradle.kts` with compose; a `designsystem` module | Screenshots over adb (read the repo's testing doc first); composables; `strings.xml` | Kotlin theme files (colors, type, shapes, spacing) |
| Static wiki / web | `docs/wiki`, `*.html`, `style.css` | Serve locally (`make wiki-serve` or `python3 -m http.server`); view at 390 px and 1280 px | `:root` custom properties in the stylesheet |
| Rust TUI | `ratatui`, `crossterm`, `tui` in `Cargo.toml` | Run it in a pane at 80x24 and wide; read the screen text; check color support fallback | A `theme` module or style constants |
| CLI output | `clap`, `println!` heavy `main` | Run commands; read the output with colors on and off (`NO_COLOR`) | Style helpers |
| Mocked-UI illustrations | stageshow `kit/` imports, `Stage`/`Window` components, hero or feature-card images, `REHEARSAL.md` | Film them (`illustrations.md`); read the source for tokens and copy | The same tokens as the product (`stageshow/references/looks.md`) |
| Embedded / companion UI | Firmware displays, companion app | Read the display code; list screens | Constants |

## Rules that hold on every surface

- Read the repo's `AGENTS.md` and docs policy before proposing where a token lives.
- A wiki mirrors the app. Its palette comes from the app's tokens, so one change in Vertical 1 reaches both. Log the wiki sync as its own entry.
- Terminal: honor `NO_COLOR` and 16-color fallbacks. Never convey state by color alone; pair it with a glyph or word.
- Android: 48 dp targets, both themes checked, overlay windows wrapped in the app theme.
- Web: visible focus ring, 44 px targets, `prefers-color-scheme` and `prefers-reduced-motion` honored.

## Driving a device

If the repo documents device driving (for example "Driving the app on a device" in `docs/testing.md`), follow it and never ask the user for device state. Run `adb devices` first. No device attached: audit from source, and state that limit in the report.
