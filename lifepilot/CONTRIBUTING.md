# Contributing to LifePilot

Welcome to **LifePilot**! This guide describes how to initialize your workspace, run checks locally, and follow development standards to ensure local data encryption and data recovery systems remain stable.

## 🚀 Onboarding & Workspace Initialization

To initialize your development workspace:

1. **Prerequisites**: Ensure you have Flutter SDK installed (matching version `^3.9.0`).
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Generate Source Code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Local Database Verification**: Run the app to automatically seed demo data.

---

## 🛠️ Essential Development Commands

### Running the App Locally
```bash
flutter run
```

### Formatting Code
Enforce Dart style guidelines:
```bash
dart format .
```

### Static Analysis
Verify there are no analyzer warnings or errors:
```bash
flutter analyze
```

### Running the Test Suite
Run unit, integration, and widget tests:
```bash
flutter test
```

### Generating Test Coverage Report
```bash
flutter test --coverage
# This generates a coverage/lcov.info file
```

---

## 🔒 Relational Database Safeguard Rules

LifePilot uses an offline-first relational database persistent model (Drift/SQLite) encrypted with SQLCipher, which interfaces with a versioned relational backup/restore system.

To protect the schema integrity and prevent users from experiencing data loss or restoring corrupted backups, you **MUST** adhere to the following rules:

### 1. Migrations & Schema Versions
* Any modification to tables in `lib/data/database/app_database.dart` requires an increment of the `schemaVersion` number in `AppDatabase`.
* You must add a corresponding migration step inside the `onUpgrade` transition logic of the `MigrationStrategy` in `AppDatabase`.

### 2. Backup Payload Sync
* If you modify any columns in the database tables, you must update the DTO mapping payloads in `lib/core/models/backup_payload_v2.dart` to match.
* Ensure all optional or nullable properties parse safely with default fallback parameters to maintain backwards compatibility.

### 3. Mandatory Integration Test Coverage
* If you modify any tables, you **MUST** update the complex integration test fixtures in [app_database_restore_v2_test.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/test/app_database_restore_v2_test.dart).
* Add assertions to ensure new columns map correctly between `BackupPayloadV2` and the database.
* Ensure financial calculations (balances) reconcile properly.
* Verify that any missing or invalid parent maps throw a `BackupRestoreException` and trigger an atomic database transaction rollback.

---

## 🚦 Local CI Pre-flight Verification

Before committing or pushing any code, run the local verification script to check formatting, static analysis, and test suites:
```bash
./run_linters.sh
```
This script will fail immediately if any step fails. Ensure it completes with `All checks passed successfully!` before submitting a pull request.

---

## 🔐 Git identity requirement

- This project requires that commits are made using the GitHub account with the email: `it25100142@my.sliit.lk`.
- The repository includes a pre-commit hook in `.githooks/pre-commit` that will refuse commits unless `git user.email` matches that address.
- To enable the hooks for your local checkout, run (PowerShell):

  ```powershell
  .\scripts\setup-hooks.ps1
  ```

  To also set your local repository git identity with the required email and your name, run:

  ```powershell
  .\scripts\setup-hooks.ps1 -SetUser -UserName "Your Name"
  ```

If you prefer not to use the hooks, make sure your commits still use the required email:

```powershell
git config user.email "it25100142@my.sliit.lk"
git config user.name "Your Name"
```

If you need an allowed exception (e.g., CI or a different machine), contact the maintainers to arrange it.

