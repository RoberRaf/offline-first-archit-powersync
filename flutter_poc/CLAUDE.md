# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.
For project goal, stack, schema, conflict rules, and progress see [`SPEC.md`](./SPEC.md).

---

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a specific test file
flutter analyze          # Lint/static analysis
flutter clean            # Clean build artifacts
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
```

---

## Architecture

### Code-Level Data Flow

```
UI (widgets) → DatabaseService → PowerSync db (local SQLite) ↔ LaravelConnector ↔ Laravel API (localhost:8000)
                                                             ↔ PowerSync Cloud (journeyapps.com)
```

- **PowerSync** queues local SQLite writes and uploads them to the Laravel backend via `LaravelConnector.uploadData()`. Reads from the server arrive via the PowerSync cloud endpoint.
- **`LaravelConnector`** (`lib/powersync/connector.dart`) implements `PowerSyncBackendConnector`: provides auth credentials (`fetchCredentials`) and uploads pending CRUD operations to the REST API.
- **`ApiClient`** (`lib/services/api_client.dart`) wraps Dio for HTTP calls to `http://127.0.0.1:8000/api`.

### Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry; calls `openDatabase()` before `runApp()` |
| `lib/powersync/database.dart` | Initializes global `db` (PowerSyncDatabase), connects connector |
| `lib/powersync/schema.dart` | Defines local SQLite tables: `notes`, `videos`, `quizzes` |
| `lib/powersync/connector.dart` | Syncs local changes to Laravel API; hardcoded dev JWT token |
| `lib/services/api_client.dart` | Dio HTTP client for Laravel REST API |
| `lib/models/db_model.dart` | Abstract `DbModel` base class (id, tableName, toMap, selectColumns) |
| `lib/models/note.dart` / `video.dart` / `quiz.dart` | Typed models extending `DbModel` with `fromMap` factories |
| `lib/services/database_service.dart` | Generic CRUD service wrapping PowerSyncDatabase; typed getAll* helpers |
| `lib/di.dart` | GetIt DI container; registers `DatabaseService` singleton |

### CRUD → HTTP Mapping (`connector.dart`)

| PowerSync op | HTTP method | Endpoint |
|---|---|---|
| PUT (create) | POST | `/videos`, `/notes`, `/quizzes` |
| PATCH (update) | PUT | `/videos/{id}`, `/notes/{id}`, `/quizzes/{id}` |
| DELETE | DELETE | `/videos/{id}`, `/notes/{id}`, `/quizzes/{id}` |

---

## Dev Configuration

- PowerSync cloud endpoint: `https://699d974aed1fcd0efe52dc12.powersync.journeyapps.com`
- Laravel API base URL: `http://127.0.0.1:8000/api`
- JWT token is hardcoded in `connector.dart` (dev-only POC; not for production)

## State Management

Uses `setState()` for UI state only. The PowerSync `db` is a global `late` variable initialized in `main()`. **GetIt** is used for DI: `DatabaseService` is registered as a singleton in `lib/di.dart`. Access it from widgets via `di<DatabaseService>()`.
