# TOOLS.md

# Local Tooling

This project uses a local Godot binary and local command wrappers so Windows
PowerShell execution policy does not block the workflow.

The Godot editor binary is stored under `.tools/`, which is ignored by Git.

# Commands

Run these from the project root:

```powershell
.\tools\check_project.cmd
```

Parses the Godot project headlessly.

```powershell
.\tools\lint.cmd
```

Runs `gdlint` on project GDScript files, excluding third-party addons.

```powershell
.\tools\format.cmd
```

Runs `gdformat` on project GDScript files, excluding third-party addons.

```powershell
.\tools\test_gut.cmd
```

Runs the primary GUT unit test suite in `tests/unit`, then runs the real-click
UI smoke checks for player-facing pointer flows.

```powershell
.\tools\test_gdunit.cmd
```

Runs the secondary GdUnit4 command-line smoke suite in `tests/gdunit`.

```powershell
.\tools\smoke_render.cmd
```

Runs the game briefly and writes smoke frames to `reports/`.
Pass width and height to verify another landscape viewport, such as:

```powershell
.\tools\smoke_render.cmd 640 360
```
The tool temporarily overrides the project viewport for that run and restores
`project.godot` before it exits.
Concurrent smoke renders are serialized internally so the temporary viewport
override cannot leak into another capture.

```powershell
.\tools\verify_all.cmd
```

Runs project parse, lint, GUT plus real-click smoke checks, and GdUnit tests.

# Notes

- `reports/` is ignored by Git and contains generated test/smoke output.
- `.tools/` is ignored by Git and contains downloaded local tools.
- GUT is the primary test framework for engine unit tests.
- GdUnit4 is installed and wired for richer editor/scene tests later.
