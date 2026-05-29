# Ortho : Intelligent Finances

A Flutter finance tracking app for managing accounts, categories, transactions, budgets, and personal financial activity with a local-first data layer and optional Supabase sync.

## Project Overview

Ortho : Intelligent Finances is designed to make everyday money management clearer and faster. Instead of treating the app as a simple collection of screens, the project is structured around a maintainable application architecture: UI, state/business workflows, local persistence, remote services, models, and configuration each have a defined responsibility.

The app is intentionally built from scratch with a custom architecture rather than relying on a one-size-fits-all starter template. That decision makes the codebase easier to extend as the product grows from a personal expense tracker into a more complete financial operating system with offline support, cloud synchronization, richer dashboards, recurring transactions, and team-friendly development workflows.

What makes this project unique is the combination of a polished fintech-style Flutter interface, a local-first Isar database, a CQRS-inspired business layer, and Supabase-backed remote synchronization. The architecture is designed so features can grow without forcing every screen to know how data is stored, synced, repaired, or migrated.

## Key Highlights

- Built with Flutter and Dart for cross-platform mobile delivery.
- Custom app architecture designed specifically for financial workflows.
- Clean separation between screens, CQRS commands/queries, local storage, sync services, models, and configuration.
- Scalable folder structure that keeps feature screens separate from application services.
- Reusable navigation, routing, theme, and design-system decisions.
- CQRS-style state/business flow through command handlers, query handlers, and a central bus.
- Service abstraction for Supabase, local database access, sync, migrations, and user identity.
- Local-first persistence with Isar for responsive offline usage.
- Connectivity-aware sync outbox for deferred remote writes.
- Centralized configuration for app routes, colors, and Supabase setup.
- Future-ready design for testing, modularization, CI/CD, analytics, and backend expansion.

## Architecture Overview

The architecture separates the app into layers so each part of the system has one clear job.

| Layer | Responsibility | Current Examples |
| --- | --- | --- |
| Presentation Layer | Renders screens, navigation, forms, dashboards, and visual fintech UI. | `lib/screens/`, `main.dart` |
| Business Logic / State Management Layer | Coordinates user actions as commands and reads as queries. | `lib/cqrs/commands.dart`, `queries.dart`, `handlers.dart`, `cqrs_bus.dart` |
| Data Layer | Stores durable local app data and generated database schemas. | `lib/models/isar_models.dart`, `lib/services/local_db.dart` |
| Service/API Layer | Handles external systems and app-level services. | `supabase_service.dart`, `sync_service.dart`, `local_user_migration.dart` |
| Model/Entity Layer | Defines finance entities used by local storage and API mapping. | Accounts, categories, transactions, transfers, budgets, recurring transactions |
| Utility/Core Layer | Provides app configuration, routes, colors, timestamp repair, sync mapping, and user identity. | `lib/config/`, selected `lib/services/` utilities |

Example folder structure:

```text
lib/
  config/
    app_colors.dart
    app_routes.dart
    supabase_config.dart
  cqrs/
    commands.dart
    queries.dart
    handlers.dart
    cqrs_bus.dart
    utils.dart
  models/
    models.dart
    isar_models.dart
    isar_models.g.dart
  screens/
    home_screen.dart
    dashboard_screen.dart
    add_transaction_screen.dart
    manage_accounts_screen.dart
    manage_categories_screen.dart
    credentials_screen.dart
    profile_screen.dart
  services/
    local_db.dart
    supabase_service.dart
    sync_service.dart
    sync_outbox.dart
    sync_mapper.dart
    user_identity.dart
    local_user_migration.dart
    timestamp_repair_service.dart
  main.dart
```

## Why This Architecture Matters

This architecture keeps the project maintainable because screens do not need to contain database, sync, or backend details. UI code can focus on user interaction while commands, queries, handlers, and services manage the actual financial workflows.

It improves testability because business actions can be tested independently from Flutter widgets. A transaction command, account query, or sync service can be validated without rebuilding the entire app experience.

It improves scalability because new finance modules can be added as new commands, queries, screens, models, and services instead of being patched into one large file. This is especially important for features like recurring payments, budgets, analytics, multi-device sync, and future backend rules.

It supports team collaboration because responsibilities are clear. One developer can work on UI screens, another on sync behavior, and another on database entities with fewer merge conflicts and less accidental coupling.

It makes debugging easier because data flow has recognizable boundaries: user action, command/query, handler, local database, sync outbox, and Supabase service.

## Tech Stack

| Area | Technology |
| --- | --- |
| Mobile Framework | Flutter |
| Language | Dart |
| State Management / Business Flow | Custom CQRS-style command and query bus with Flutter `StatefulWidget` UI state |
| Backend/API | Supabase |
| Database/Storage | Isar local database, SharedPreferences, Supabase tables |
| Authentication | Supabase Auth support through `supabase_flutter` |
| Sync/Connectivity | Connectivity Plus, custom sync outbox, timestamp repair service |
| UI/Charts/Design | Google Fonts, FL Chart, Percent Indicator, Shimmer, Material widgets |
| Code Generation | Isar Generator, Build Runner |

## Features

- Account management for organizing financial sources.
- Category management for classifying income and expenses.
- Transaction creation and tracking.
- Dashboard and home views for financial summaries.
- Budget and recurring transaction data models.
- Local-first storage using Isar.
- Optional Supabase initialization when credentials are configured.
- Connectivity-aware sync for pending local changes.
- User identity and local user migration support.
- Timestamp repair and remote reconciliation logic for safer sync behavior.
- Premium dark-mode fintech UI direction documented in `DESIGN.md`.

## Screenshots / Demo

Screenshots will be added here.

## Getting Started for Non-Technical Users

Follow these steps if you want to download and run the app on your computer.

### 1. Install Flutter

Flutter is the tool used to build and run this mobile app.

Download it from the official Flutter website:

```text
https://docs.flutter.dev/get-started/install
```

After installing Flutter, open a terminal and check that it works:

```bash
flutter doctor
```

If Flutter shows warnings, follow the instructions it gives you.

### 2. Install Git

Git is used to download the project from GitHub.

Download Git here:

```text
https://git-scm.com/downloads
```

Check that Git is installed:

```bash
git --version
```

### 3. Clone the Repository

Cloning means downloading the project to your computer.

```bash
git clone [REPO_URL]
```

Then open the project folder:

```bash
cd [PROJECT_FOLDER]
```

### 4. Open the Project

Open the folder in VS Code or Android Studio.

Recommended editors:

- VS Code with the Flutter and Dart extensions.
- Android Studio with the Flutter plugin.

### 5. Install App Packages

Run this command inside the project folder:

```bash
flutter pub get
```

This downloads the Flutter packages the app needs.

### 6. Connect a Device or Start an Emulator

You can run the app on:

- A physical Android phone with developer mode enabled.
- An Android emulator from Android Studio.
- Another Flutter-supported device.

Check available devices:

```bash
flutter devices
```

### 7. Run the App

Start the app with:

```bash
flutter run
```

Flutter will build the app and open it on the selected device.

## Developer Setup

### Requirements

- Flutter SDK installed.
- Dart SDK compatible with `>=2.19.0 <4.0.0`.
- Android Studio or VS Code.
- Android SDK for Android builds.
- Optional Supabase project for backend sync.

### Environment and API Keys

Supabase configuration currently lives in:

```text
lib/config/supabase_config.dart
```

For production or public repositories, API keys should be moved to a safer environment/config strategy such as build-time environment variables, `--dart-define`, or platform-specific secret handling.

Expected values:

```dart
const String SUPABASE_URL = '[YOUR_SUPABASE_URL]';
const String SUPABASE_ANON_KEY = '[YOUR_SUPABASE_ANON_KEY]';
```

### Build Flavors

Build flavors are not currently configured. The project can be extended with `dev`, `staging`, and `prod` flavors when separate Supabase projects or release environments are introduced.

### Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
flutter build apk --release
```

If Isar model changes require generated code updates, run:

```bash
dart run build_runner build
```

## How to Run the App

```bash
git clone [REPO_URL]
cd [PROJECT_FOLDER]
flutter pub get
flutter run
```

## Project Structure

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, local database initialization, optional Supabase setup, sync bootstrapping, main navigation. |
| `lib/config/` | App-level configuration such as routes, colors, and Supabase setup. |
| `lib/cqrs/` | Commands, queries, handlers, and bus used to separate write and read workflows. |
| `lib/models/` | Plain Dart models and Isar database entities. |
| `lib/screens/` | Flutter UI screens for home, dashboard, transactions, accounts, categories, credentials, and profile. |
| `lib/services/` | Local database, Supabase, sync, migration, identity, mapping, and repair services. |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Platform-specific Flutter project files. |
| `DESIGN.md` | Product and visual design system for the premium fintech UI direction. |
| `supabase/` | Supabase-related project files and backend setup assets. |

## System Design Decisions

### Custom Architecture

The app uses a custom architecture because finance apps need clear boundaries around data integrity, offline behavior, and user workflows. A transaction is not just a UI event; it affects accounts, categories, summaries, sync state, timestamps, and future analytics. The architecture reflects that by giving data and workflow logic dedicated layers.

### Layer Separation

UI screens are separated from business commands and services so the presentation layer remains easy to change. The app can redesign the home screen, dashboard, or transaction form without rewriting persistence and sync logic.

### CQRS-Inspired Flow

Commands represent write operations such as creating accounts, categories, transactions, transfers, budgets, and recurring transactions. Queries represent read operations such as fetching accounts, categories, transactions, budgets, recurring items, transfers, and summaries. This gives the codebase a clear mental model: commands change state, queries read state.

### Local-First Data

Isar is used as the local database so the app can stay fast and usable even before or without a successful remote sync. This is important for finance tracking, where users expect their data entry to feel immediate.

### Service Abstraction

Supabase, local storage, sync, migration, timestamp repair, and user identity are wrapped in services. This keeps backend details out of screens and makes future changes easier, such as replacing the sync strategy, adding retries, introducing encryption, or moving to a different backend.

### Sync Outbox

The sync outbox pattern allows local changes to be queued and synchronized when connectivity is available. This is a practical foundation for better offline support because the app does not need to fail immediately when the network is unavailable.

### Future Scalability

The app can scale by adding new feature modules, expanding the CQRS handlers, adding repository interfaces, introducing automated tests, and separating features into packages when the codebase grows.

## Future Improvements

- Add unit tests for CQRS handlers and services.
- Add widget tests for key screens and forms.
- Add integration tests for transaction, account, category, and sync workflows.
- Introduce CI/CD for automated analysis, tests, and release builds.
- Move secrets to environment-based configuration.
- Add analytics for feature usage and app health.
- Improve offline conflict resolution and sync retry policies.
- Add performance profiling for dashboard and chart-heavy screens.
- Modularize large features into dedicated packages or feature folders.
- Expand backend policies, validation, and migrations.
- Add richer financial reports, exports, and notification workflows.

## Contribution Guide

Contributions are welcome.

1. Fork the repository.
2. Create a new branch:

```bash
git checkout -b feature/your-feature-name
```

3. Make your changes.
4. Run checks before submitting:

```bash
flutter analyze
flutter test
```

5. Commit your work:

```bash
git commit -m "Add your feature"
```

6. Push your branch:

```bash
git push origin feature/your-feature-name
```

7. Open a pull request with a clear description of what changed and why.

## Author

Developed and architected by [YOUR NAME]

Role: Flutter Developer / Software Architect / System Design Enthusiast
