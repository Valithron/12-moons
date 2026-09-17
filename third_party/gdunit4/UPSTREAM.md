# GdUnit4 provenance

- Repository: https://github.com/godot-gdunit-labs/gdUnit4
- Version: `v6.2.1`
- Commit: `08ffc7c65b61b1b2edd545616061a99973c13ce1`
- Vendored: 2026-09-17
- License: MIT; see `LICENSE`.
- Copied paths: `addons/gdUnit4/plugin.cfg`, `plugin.gd`, `runtest.cmd`,
  `runtest.sh`, `bin/`, and `src/`.
- Excluded paths: upstream `test/` self-tests and repository-only development
  furniture. Godot-generated `.uid` sidecars are also excluded; Godot
  regenerates them on import. The consuming project tests are under `tests/`.
- Local modifications: `runtest.cmd` and `runtest.sh` use Godot's headless
  mode and omit the upstream `--remote-debug tcp://127.0.0.1:0` flag. Godot
  4.7 rejects port zero before the test runner starts; headless mode preserves
  the consuming-project CLI workflow without changing framework runtime code.
