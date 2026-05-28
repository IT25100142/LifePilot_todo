# 🧭 LifePilot

[![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.9.0-blue.svg)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State--Management-Riverpod%202.6-purple.svg)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Database-Drift%20(SQLite)-green.svg)](https://drift.simonbinder.eu/)
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform-orange.svg)](#)
[![License](https://img.shields.io/badge/License-Private-red.svg)](#)

**LifePilot** is an elegant, offline-first productivity and personal finance companion built with Flutter. By storing all user data strictly on-device, LifePilot guarantees total privacy, high speed, and reliability without requiring a internet connection or cloud storage. 

---

## 🌟 Key Features

### 1. 📊 Central Dashboard
- **Daily Glance**: Review today's events, overdue or due tasks, and budget allocations in one unified screen.
- **Financial Status Widget**: Displays a clean, dynamic income vs. expense progress ring and overall account balance using [fl_chart](https://pub.dev/packages/fl_chart).
- **Quick Action FAB**: Add tasks, transactions, or calendar events in a single click from anywhere.

### 2. 📝 Task Manager (To-Do)
- **Flexible Prioritization**: Classify tasks as **Low**, **Medium**, or **High** priority.
- **Categorization & Tags**: Assign items to custom categories (e.g., Work, Personal, Study) and comma-separated tags for fast filtering.
- **Due Dates & Local Reminders**: Schedule specific deadlines and receive push notifications on time using [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications).
- **Reactive Updates**: Check off completed tasks immediately and watch progress propagate globally in real time.

### 3. 📅 Calendar & Scheduler
- **Daily Agenda**: Visual scheduler tracking starting and ending times for calendar events.
- **Reminders**: Schedule event reminders to trigger ahead of meetings, habits, or milestones.
- **Unified Sync**: Events coexist alongside tasks to give you a complete picture of your day.

### 4. 💸 Personal Finance Ledger
- **Transaction Tracker**: Log and document all income and expense transactions.
- **Category Budgets**: Categorize spending (e.g., Food, Transport, Bills, Shopping, Salary) with visual color codings.
- **Visual Analytics**: Interactive donut charts highlighting expense distribution to understand spending patterns.

### 5. ⚙️ Settings & Local Backup
- **Appearance Settings**: Seamlessly switch between Light, Dark, and System theme configurations.
- **Custom Currency**: Customize the app's default currency symbol (defaults to `LKR`, works offline for any custom currency code).
- **Import/Export Data**: 
  - Export database contents to a human-readable **JSON** file or spreadsheet-compatible **CSV** file.
  - Restore existing settings and ledger entries by importing a previously backed up JSON file.
- **Data Erasure**: Securely purge all localized data on demand.

---

## 🎨 Design & Aesthetics

LifePilot is built with a premium, state-of-the-art visual style:
- **Glassmorphism**: Leverages a custom [GlassPanel](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/widgets/glass.dart) container using back-layered image/blur filtration for a modern, glass-like effect.
- **Cohesive Palette**: Centered around deep teal and forest green colors (`0xFF286C63`) with accent alerts, ensuring interfaces look clean, polished, and accessible.
- **Micro-animations**: Smooth tab switching via GoRouter's Shell routing and responsive touch feedback.

---

## 🏗️ Architecture & Codebase Structure

LifePilot follows a **feature-first** project layout, segregating code by business modules to allow developers to build and scale features independently.

```
lib/
├── app/                  # Application-wide settings, routing, and themes
│   ├── app.dart          # MaterialApp configuration & theme loaders
│   ├── router.dart       # GoRouter configuration using StatefulShellRoute
│   └── theme.dart        # Custom light/dark themes and glassmorphic decoration
├── core/                 # Shared widgets, utilities, constants, and services
│   ├── constants/        # Default constants (default categories, metadata)
│   ├── services/         # Device notifications, CSV/JSON file exporter
│   ├── utils/            # Shared helper classes (date helpers, formatting)
│   └── widgets/          # Reusable UI widgets (cards, empty states, glass overlays)
├── data/                 # SQLite persistence layer
│   └── database/         # Drift database definition, code generators, and providers
└── features/             # Business modules containing Screens and State Providers
    ├── calendar/         # Agenda lists & event reminders
    ├── dashboard/        # Centralized analytics, agenda feeds, and quick actions
    ├── finance/          # Cash transaction loggers, balance sheets, and donut charts
    ├── settings/         # Theme toggles, currency codes, and backup configurations
    └── todo/             # List configurations, priority queues, and task status cards
```

### Core File Reference Links
* **Entry Point**: [lib/main.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/main.dart) - Initializes bindings and boots the Riverpod `ProviderScope`.
* **Root Application**: [lib/app/app.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/app.dart) - Configures page routers, widgets, and styles.
* **Routing Table**: [lib/app/router.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/router.dart) - Manages the shell layout structure, maintaining tab states.
* **App Themes**: [lib/app/theme.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/app/theme.dart) - Configures material themes, dark/light styles, and visual details.
* **App Constants**: [lib/core/constants/app_constants.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/constants/app_constants.dart) - Constants containing application defaults.
* **Database Engine**: [lib/data/database/app_database.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/data/database/app_database.dart) - Declares Drift schemas, query transactions, and data import/export mappings.
* **Import/Export Service**: [lib/core/services/export_service.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/services/export_service.dart) - Serializes tables into JSON/CSV buffers and schedules document picking.
* **Local Notifications**: [lib/core/services/notification_service.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/lib/core/services/notification_service.dart) - Schedules timed background local push alarms on the host system.

---

## 🗃️ Database Schema

All local tables are managed reactively via SQLite and compiled using [Drift](https://pub.dev/packages/drift).

| Table | Class | Primary Attributes | Description |
| :--- | :--- | :--- | :--- |
| `tasks` | `Tasks` | `id`, `title`, `description`, `dueDate`, `reminderAt`, `priority`, `tags`, `isCompleted` | Records tasks, priority levels, deadlines, and notifications. |
| `events` | `CalendarEvents` | `id`, `title`, `description`, `date`, `startTime`, `endTime`, `reminderAt` | Manages scheduled meetings and calendar events. |
| `transactions` | `FinanceEntries` | `id`, `title`, `amount`, `category`, `date`, `note`, `type` | Stores income/expense ledger transactions. |
| `categories` | `Categories` | `id`, `name`, `type`, `colorValue`, `iconName` | Links customized tags to specific tasks or financial activities. |
| `app_settings` | `AppSettingsTable`| `id`, `themeMode`, `currency`, `demoSeeded` | Stores device-level configurations. |

---

## 🛠️ Developer Setup & Guidelines

To run or build LifePilot locally on your machine, follow these steps:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.9.0` recommended)
- [Dart SDK](https://dart.dev/get-started) (included inside the Flutter toolchain)
- A connected physical device, emulator, or simulator

### 1. Fetch Dependencies
Install the package dependencies defined in [pubspec.yaml](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/pubspec.yaml):
```bash
flutter pub get
```

### 2. Generate Drift Database Code
Since LifePilot utilizes Drift for database mappings, you must generate the reactive boilerplate code before running:
```bash
# Run once to compile
dart run build_runner build --delete-conflicting-outputs

# Alternatively, watch files for auto-generation during development
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Run the App
Launch the application on your active emulator or connected hardware:
```bash
flutter run
```

---

## 🧪 Automated Testing

LifePilot includes an automated unit test suite checking core services, data models, and helper logic.

### Test Coverage
- **Date Helpers**: Assures date boundary rules logic works correctly (e.g., comparing days without times).
- **Financial Statistics Summary**: Validates income/expense aggregations, net balance maths, and sub-category sorting values.
- **Unique Notifications Mapping**: Assures task and event notification ID ranges do not conflict.

### Running Tests
Execute the test runner:
```bash
flutter test
```
The test suite definition is located in [test/life_pilot_utils_test.dart](file:///c:/Users/chamidu/Documents/TO-DO/lifepilot/test/life_pilot_utils_test.dart).
