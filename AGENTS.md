# AGENTS.md

## Cursor Cloud specific instructions

### Product

LifePilot is a single Flutter app under `lifepilot/` (offline-first tasks, calendar, finance). There is no backend, Docker, or Node/Python toolchain.

### VM prerequisites (one-time, not in update script)

- Flutter stable at `/home/ubuntu/flutter` with `PATH` including `/home/ubuntu/flutter/bin` (see `~/.bashrc` on this VM).
- Linux packages: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`, `libssl-dev`, `libsqlite3-dev`, `libstdc++-14-dev`, `build-essential`, `chromium-browser` / Google Chrome, `xvfb` (optional).

### Standard commands (from `lifepilot/README.md`)

| Action | Command (run in `lifepilot/`) |
|--------|--------------------------------|
| Dependencies | `flutter pub get` |
| Drift codegen | `dart run build_runner build` |
| Analyze | `flutter analyze` |
| Tests | `flutter test` |
| Web dev server | `flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1` |
| Linux desktop | `flutter run -d linux` |

### Non-obvious Cloud Agent notes

- **Drift codegen:** Run `build_runner` after `flutter clean` or schema changes; generated `app_database.g.dart` must exist before analyze/build.
- **Linux desktop build:** Requires OpenSSL dev headers (`libssl-dev`) for `sqlcipher_flutter_libs`, and `libstdc++-14-dev` so `clang++` can link.
- **Web vs native DB:** `app_database.dart` must not call `path_provider` on web (`kIsWeb` guard before `getApplicationDocumentsDirectory`).
- **App lock on web:** Biometrics are skipped when `kIsWeb` in `auth_provider.dart`; Linux desktop may still show the lock screen if `local_auth` reports device support—use web for interactive UI demos in the cloud VM.
- **Headless UI demos:** Prefer `flutter run -d web-server` on port 8080; open `http://127.0.0.1:8080/` in the Desktop pane browser.
- **Hello-world check:** `flutter test test/todo_smoke_test.dart` creates and reads a task in an in-memory database (no emulator required).
