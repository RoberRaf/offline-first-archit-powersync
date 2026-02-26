# PowerSync + PostgreSQL Offline-First PoC

## Goal

Prove that PowerSync Cloud can sit between a Flutter mobile client and a Laravel/PostgreSQL backend to provide true offline-first sync with conflict resolution — specifically for educational data patterns — without data loss or state divergence across devices.

---

## Stack

| Layer | Technology |
|---|---|
| Mobile Client | Flutter |
| Local DB (client) | SQLite via PowerSync SDK |
| Sync Service | PowerSync Cloud (hosted) |
| Backend | Laravel (PHP) |
| Database | PostgreSQL 18 (local, exposed via ngrok) |
| Dashboard | Filament *(deferred)* |

---

## Data Flow

```
Flutter (PowerSync local SQLite)
    ↓ writes via HTTP (Dio)       ↑ sync down via PowerSync Cloud
Laravel API  →  PostgreSQL  ←  PowerSync Cloud reads WAL
```

---

## Agreed Database Schema

### `videos`
| Column | Type | Notes |
|---|---|---|
| id | UUID | Primary key, client-generated |
| name | VARCHAR(255) | Video name |
| offset | INTEGER | Playback position in seconds, default 0 |
| is_completed | BOOLEAN | default false |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### `notes`
| Column | Type | Notes |
|---|---|---|
| id | UUID | Primary key, client-generated |
| title | VARCHAR(255) | |
| content | TEXT | |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### `quizzes`
| Column | Type | Notes |
|---|---|---|
| id | UUID | Primary key, client-generated |
| name | VARCHAR(255) | |
| grade | DECIMAL(5,2) | default 0 |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

---

## Flutter Project Structure

```
lib/
  models/
    db_model.dart         ← abstract base class with CRUD interface
    note.dart
    video.dart
    quiz.dart
  services/
    api_client.dart       ← Dio HTTP client (base URL, headers, timeouts)
    database_service.dart ← PowerSync SQLite CRUD, accepts DbModel
  powersync/
    schema.dart           ← local SQLite schema definition
    connector.dart        ← PowerSyncBackendConnector, upload queue handler
    database.dart         ← DB initialisation and PowerSync connection
  main.dart
```

---

## Success Criteria

| Criteria | Target |
|---|---|
| Data loss across all scenarios | Zero |
| Sync time for 100 queued operations | < 5 seconds |
| Conflict resolution | Deterministic per collection rules |
| PowerSync local DB size (single student) | < 20MB |
| Stability on 2GB RAM device during sync burst | No crashes |

### Conflict Resolution Strategy Per Table

| Table | Strategy |
|---|---|
| videos | Last-write-wins on `offset` and `is_completed` |
| notes | Last-write-wins on `title` and `content` |
| quizzes | Last-write-wins on `grade` |

---

## Steps

### Phase 1 — Laravel + PostgreSQL Backend ✅

- [x] Create Laravel project
- [x] Configure `.env` for local PostgreSQL (`db: laravel`, `user: root`, `pass: 123456789`)
- [x] Enable PostgreSQL logical replication (`wal_level = logical`)
- [x] Create migrations for `videos`, `notes`, `quizzes` with UUID primary keys
- [x] Create Eloquent models with `HasUuids` trait
- [x] Create API routes using `apiResource` for all three tables
- [x] Create `VideoController`, `NoteController`, `QuizController` (no auth)
- [x] Test all endpoints via Postman — confirmed writes land in PostgreSQL

---

### Phase 2 — PowerSync Cloud Setup ✅

- [x] Create PowerSync Cloud account and new instance (`laravel-poc`)
- [x] Install and configure ngrok to expose local PostgreSQL (`7.tcp.eu.ngrok.io:14523`)
- [x] Enable SSL on local PostgreSQL (self-signed certificate)
- [x] Grant `root` user replication privileges
- [x] Add replication entry to `pg_hba.conf`
- [x] Create `powersync` publication covering `notes`, `quizzes`, `videos`
- [x] Connect PowerSync Cloud to PostgreSQL — status: connected
- [x] Define and deploy sync rules (global bucket, all rows, all three tables)

---

### Phase 3 — Flutter Client Setup ✅

- [x] Add dependencies: `powersync`, `dio`, `path`, `path_provider`, `uuid`
- [x] Create `lib/powersync/schema.dart` — local SQLite schema
- [x] Create `lib/services/api_client.dart` — Dio service with GET, POST, PUT, DELETE
- [x] Create `lib/powersync/connector.dart` — upload queue handler using `ApiClient`
- [x] Create `lib/powersync/database.dart` — DB init and PowerSync connection
- [x] Create abstract `DbModel` base class with `toMap()`, `tableName`, `selectColumns`
- [x] Create `Note`, `Video`, `Quiz` model classes extending `DbModel`
- [x] Create `DatabaseService` with generic and typed CRUD methods
- [x] Wire `openDatabase()` in `main.dart`
- [x] Verify app starts without errors
- [x] Test sync down: inserted row in PostgreSQL → appeared in Flutter local DB ✅
- [x] Test sync up: inserted row in Flutter → appeared in PostgreSQL ✅

---

### Phase 4 — Offline Queue Testing 🔄 In Progress

- [ ] **Scenario A** — Create records offline on all three tables → reconnect → verify PostgreSQL reflects all data correctly
- [ ] **Scenario B** — Update same record on two devices offline → both reconnect → observe and document conflict resolution outcome per table
- [ ] **Scenario C** — Queue 100+ offline operations → measure sync time and ordering correctness on reconnect
- [ ] Measure sync latency for 100 queued operations
- [ ] Measure local SQLite DB size after a full student dataset
- [ ] Verify no duplicate rows after reconnect (idempotency check)
- [ ] Check PowerSync dashboard sync logs for errors or skipped operations

---

### Phase 5 — Verify Conflict Behaviour ⏳ Pending

- [ ] Document actual conflict behaviour observed vs intended strategy per table
- [ ] Confirm `grade` conflict resolution matches server-wins expectation
- [ ] Confirm `offset` / `is_completed` behaves as last-write-wins
- [ ] Confirm notes last-write-wins is acceptable or flag if merge strategy is needed

---

### Phase 6 — Filament Dashboard ⏳ Deferred

- [ ] Install Filament in Laravel project
- [ ] Create resources for `Video`, `Note`, `Quiz`
- [ ] Verify data written from Flutter is visible in Filament dashboard in real time

---

---

## Notes & Decisions

- **ngrok free tier** reassigns a new URL on every restart — the PowerSync dashboard database connection must be updated each time ngrok is restarted.
- **UUID IDs** are generated client-side by Flutter using the `uuid` package, before the record ever reaches the server. This is required for offline-first insert correctness.
- **Boolean in SQLite** — PowerSync's local SQLite has no boolean type. `is_completed` is stored as integer (`0`/`1`) and cast to Dart `bool` in `Video.fromMap()`.
- **No authentication** in this PoC — all rows sync to all clients. User scoping will be added in a later phase via PowerSync sync rule parameters.