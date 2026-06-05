# LifePilot: Executive Workspace & Secure Personal Ledger

LifePilot is a high-fidelity, premium executive workspace application designed for distraction-free performance tracking. It provides a local-first, zero-knowledge environment consolidating personal task management, calendar scheduling, habit tracking, and personal finance ledgers into a single unified workspace.

---

## 1. Project Manifesto & Aesthetic Overview

The engineering philosophy of LifePilot prioritizes visual excellence, deep hardware integration, and a zero-trust offline privacy posture. The application is structured around a spatial glassmorphism interface optimized specifically for wide-format executive desktop environments.

### 1.1 Structural Design Language
To eliminate stretched mobile interfaces on wide viewports, LifePilot transitions from a fluid single-column layout on compact screens to an **Asymmetrical Desktop Grid Matrix (3-Column Layout)** on screens of 1000px and wider. This grid enforces a strict **1650px** viewport constraint.

The grid segments the screen into three logical columns with a **3:5:4 flex ratio**:
*   **Left Column (Flex 3):** Displays high-level system indicators, user status, the global search interface, and Zen-density ambient quotes.
*   **Center Column (Flex 5):** Serves as the primary active workspace, housing the cumulative financial analytics visualizer and the priority/urgent tasks view.
*   **Right Column (Flex 4):** Houses context projections, the weekly calendar runway, the habit mesh heatmap, and the quick-focus session deck.

#### Layout Configuration Matrix
| Layout Attribute | Compact Viewports (< 1000px) | Widescreen Desktop Viewports (>= 1000px) |
| :--- | :--- | :--- |
| **Grid Arrangement** | Single-column vertical stacking | Asymmetrical 3-column horizontal grid (3:5:4 flex ratio) |
| **Viewport Constraint** | Fluid (100% of viewport width) | Centered layout with **1650px** maximum constraint limit |
| **Left Column (Flex 3)** | Merged into main scrollable area | System Status, Global Search, and Executive Greeting |
| **Center Column (Flex 5)** | Merged into main scrollable area | Core Workspace: Finance Analytics and Urgent Tasks |
| **Right Column (Flex 4)** | Merged into main scrollable area | Context Runway, Week Strip, Habit Mesh, and Quick Focus |
| **Dock Configuration** | Screen-bottom edge navigation | Centered horizontal glass capsule dock (max width **520px**) |
| **Transition Animation** | Default route switches | Slide-fade transition pages with kinetic translation |

### 1.2 Spatial Glassmorphic Material Stack
The visual framework utilizes a layered materials stack to achieve a spatial depth effect. This is implemented via custom painters and filters in [glass_panel.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/widgets/glass_panel.dart):

*   **Backdrop Blur Filters:** Evaluates at a high-intensity **24.0 Sigma** blur value using `ui.ImageFilter.blur` within [LifePilotGlassCard](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/widgets/glass_panel.dart#L57) to separate layout items from the dynamic background mesh.
*   **Alpha Tint Surfaces:** Semi-translucent panels are configured with a **3% white/dark surface opacity** to ensure maximum content readability and background integration without losing color balance.
*   **Directional Hair-line Specular Highlights:** A custom `SpecularBorderPainter` draws a precise **0.75-pixel** stroke highlight. The border uses a directional gradient (top-left highlights, bottom-right shadows) to simulate light refraction.
*   **Organic Spring Kinetics:** Motion states use custom cubic Bezier curves (`Cubic(0.2, 0.9, 0.1, 1.05)`) for spring physics during page transitions and interactive hover effects.
*   **Dynamic Spotlight Illuminator:** Interactive components track mouse movements in a `MouseRegion` to paint a dynamic spotlight highlight with a **120-unit** radius and a maximum opacity cap of **0.04**.
*   **Tactile Neomorphic Depression:** When clicked, components render top-left dark inset shadows and bottom-right light reflections to simulate mechanical click feedback.

---

## 2. Core Architectural Pillars

### 2.1 State Architecture
Reactive state distributions and database interfaces are managed via the Riverpod framework:
*   **Riverpod Notifiers:** Encapsulate domain actions and UI-consumed states. Logic for tasks, transactions, and habits is managed using Riverpod `Notifier` and `AsyncNotifier` structures.
*   **Synchronous Session Guard Providers:** Access to the underlying encrypted database requires an active session state managed by the `authSessionProvider` in [router.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/router.dart#L34). 
*   **Inactivity Session Locks:** Application lifecycle changes (such as system standby or backgrounding) cause the session provider to instantly revoke the decrypted database session. This locks the application until a valid credentials verification occurs.

### 2.2 Navigation Topology
The application uses declarative routing driven by GoRouter:
*   **Shell-Based Layouts:** Stateful navigation branches are organized under a unified `StatefulShellRoute` in [router.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/router.dart#L67), preserving individual tab states when switching views.
*   **Branch Kinetics:** Switching navigation tabs triggers a `KineticsBranchContainer` in [router.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/router.dart#L193). The outgoing view shrinks and slides out of frame, while the incoming view scales up and slides in. The direction of translation is determined by the transition index.
*   **Organic Slide-Fade Pages:** Screen changes use the [OrganicPhysicsTransitionPage](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/router.dart#L155) class, animating position (0.08 vertical offset to zero), scale (0.96 to 1.0), and opacity.

### 2.3 Hardware-Level Event Capture
LifePilot uses direct physical keyboard interception on the lock/login screen in [login_screen.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/features/auth/login_screen.dart):
*   **Post-Frame Focus Request:** The login screen requests physical keyboard focus immediately after the first frame renders:
    ```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
    ```
*   **Event Interception Pipeline:** The root view of the login interface is wrapped in a [KeyboardListener](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/features/auth/login_screen.dart#L258) using the requested `FocusNode`.
*   **Verification Vectors:** The listener intercepts input codes on `KeyDownEvent` and processes numerical entries from both main keyboard digits (`LogicalKeyboardKey.digit0` through `LogicalKeyboardKey.digit9`) and dedicated numerical keypads (`LogicalKeyboardKey.numpad0` through `LogicalKeyboardKey.numpad9`), alongside `LogicalKeyboardKey.backspace`. These characters feed straight into pin verification routines to dissolve the lock veil.

---

## 3. Storage Security Ledger (Zero-Knowledge Architecture)

LifePilot operates on a zero-knowledge data model. No user data, passwords, or transaction histories are transmitted to external servers.

```
+-------------------------------------------------------------+
|                      LifePilot Flutter UI                   |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|               Drift Database Mapping Layer                  |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|        SQLCipher Database Engine (AES-256 Encrypted)        |
+-------------------------------------------------------------+
      ^                                                 ^
      | (Secure Key Injection)                          | (C-Library FFI Overrides)
+-------------------------------+             +-----------------------------+
|  flutter_secure_storage       |             |  sqlite3 / FFI Bindings     |
|  (System Keyring Persistence) |             |  (Android workaround/so)    |
+-------------------------------+             +-----------------------------+
```

### 3.1 Database & Cryptography Configuration
The persistence engine uses the Drift framework on top of SQLite, compiled with SQLCipher bindings:
*   **AES-256 Database Encryption:** Database rows and structures are encrypted using SQLCipher. 
*   **Secure Key Generation:** A 256-bit cryptographic key is generated on first startup using a cryptographically secure random number generator (CSPRNG).
*   **Key Storage:** The key is written directly to the OS security framework (Android Keystore / iOS Keychain) using the `flutter_secure_storage` package.
*   **PRAGMA Injection:** The key is retrieved at startup and injected into the sqlite instance before executing any schema queries:
    ```dart
    rawDb.execute("PRAGMA key = '$encryptionKey';");
    ```
*   **Self-Healing Recovery:** If the database decryption fails (indicating file corruption or an invalid key), the database file is deleted, and the schema is re-initialized to prevent app startup crashes.

### 3.2 Native FFI & Initialization Workarounds
To circumvent standard Dart FFI limits and platform linker restrictions, LifePilot uses custom initialization routines in [main.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/main.dart):
*   **Android FFI Overrides:** Android systems frequently fail to resolve native FFI symbols for SQLCipher under standard sqlite configurations. LifePilot overrides this lookup sequence by routing queries through `sqlcipher_flutter_libs` bindings:
    ```dart
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
    ```
*   **C-Library Linkage:** This configuration forces the runtime to load compiled C-libraries (`libsqlite3.so` containing SQLCipher symbols) rather than the default system SQLite library.

---

## 4. Hardware Compilation & Deployment Matrix

### 4.1 Windows Desktop Architecture
Compiling the application on Windows requires building the `sqlcipher_flutter_libs` package using Visual Studio C++ build tools and CMake. The compiler needs to link against local OpenSSL headers and binaries.

#### 4.1.1 Environment Setup
1. Download the pre-compiled OpenSSL binaries for Windows (1.1.x or 3.x series).
2. Extract the files to a local folder (e.g., **`C:\Path\To\Project\.openssl`**).
3. Set the CMake root pointer in an elevated PowerShell session to point to the local OpenSSL path:
   ```powershell
   [System.Environment]::SetEnvironmentVariable("OPENSSL_ROOT_DIR", "C:\Path\To\Project\.openssl", "User")
   ```
4. Restart the development terminal to apply the updated environment variables.

#### 4.1.2 Compilation Commands
Run the code generation scripts and build the Windows executable:
```powershell
# Get Flutter dependencies
flutter pub get

# Generate Drift database files
dart run build_runner build --delete-conflicting-outputs

# Execute compile build for Windows desktop targets
flutter run -d windows
```

### 4.2 Android Target Architecture
Android targets compile SQLCipher using the Android NDK and distribute optimized binaries for supported CPU architectures.

#### 4.2.1 CPU Architecture Configurations
The build process generates native `.so` library bundles for:
*   `arm64-v8a` (Modern Android devices)
*   `x86_64` (Standard Android emulators)

#### 4.2.2 Compilation and Deployment Commands
Launch the compilation process and deploy to an active device or emulator:
```bash
# Clean cached Flutter artifacts
flutter clean

# Retrieve dependency libraries
flutter pub get

# Generate database sources
dart run build_runner build --delete-conflicting-outputs

# Run compilation and deploy to target emulator
flutter run -d emulator-5554
```
The application dynamically selects and extracts the correct CPU architecture bundle during installation, deploying SQLCipher out-of-the-box.
