# Offline-First POC — PowerSync + Flutter + Laravel/PostgreSQL

## POC Summary

**Original question:** Can PowerSync Cloud sit between a Flutter mobile client and a PostgreSQL backend to provide true offline-first sync — where the app remains fully functional with no network, and changes sync reliably when connectivity returns?

> Note: The original brief referenced Firestore as the backend. This POC replaced Firestore with a **local PostgreSQL database exposed via ngrok**, which is closer to the production architecture (Laravel + PostgreSQL).

### Tasks

| # | Task |
|---|------|
| 1 | Set up a Laravel/PostgreSQL backend with REST endpoints for Notes, Quizzes, and Videos |
| 2 | Configure PowerSync Cloud to replicate from PostgreSQL via logical replication |
| 3 | Integrate the PowerSync Flutter SDK into a Flutter app with a custom `LaravelConnector` |
| 4 | Prove that data created offline on Flutter syncs to PostgreSQL after reconnection |
| 5 | Prove that conflicting offline edits are handled without data corruption |

### Success Criteria

| Criterion | Target |
|---|---|
| Offline create → sync | Zero data loss after reconnect |
| Conflict resolution | No silent corruption; outcome deterministic |
| Sync performance (100 ops) | < 10 seconds on a mid-range device |
| Local DB footprint | Measured and documented |
| Error path visibility | Failed uploads surfaced, not swallowed |

---

## How PowerSync + PostgreSQL Works Under the Hood

### Server Side

**Logical replication**

PostgreSQL must be configured with `wal_level = logical`. A `PUBLICATION` is then created covering the tables PowerSync should watch:

```sql
CREATE PUBLICATION powersync FOR TABLE notes, quizzes, videos;
```

**Write-Ahead Log (WAL)**

Every `INSERT`, `UPDATE`, and `DELETE` is written to the WAL before being applied to the heap. This gives PowerSync a durable, ordered stream of changes to consume.

**Replication slot**

PowerSync creates a named logical replication slot on the PostgreSQL server. The slot tracks how far PowerSync has consumed the WAL, so no changes are missed even if the PowerSync Cloud service drops the connection temporarily.

---

### PowerSync Layer

**Sync rules**

Sync rules are YAML-based configuration deployed to the PowerSync Cloud dashboard. They define which rows each connected client receives, using bucket parameters and per-table `SELECT` queries. Example (simplified):

```yaml
bucket_definitions:
  global:
    data:
      - SELECT id, title, content, created_at, updated_at FROM notes
      - SELECT id, title, grade, created_at, updated_at FROM quizzes
      - SELECT id, title, url, created_at, updated_at FROM videos
```

**Buckets**

A bucket is a logical grouping of rows the client subscribes to. In this POC a single `global` bucket syncs all rows of all three tables to every client. Production deployments would use parameterised buckets (e.g. `bucket_definitions.user_data` scoped by `user_id`) to limit each client to its own data.

---

### Data Flow

#### Backend → Client

```
Laravel writes to PostgreSQL
  → PostgreSQL WAL captures the change
  → PowerSync Cloud reads the replication slot
  → Change is placed in the matching bucket
  → Flutter client receives the change over the PowerSync websocket
  → PowerSync SDK writes the row to local SQLite
```

#### Client → Backend

```
Flutter writes to local PowerSync SQLite (optimistic, immediate)
  → PowerSync queues the operation in its upload queue
  → LaravelConnector.uploadData() fires (Client side - It is a Flutter function)
  → Calls Laravel REST API (POST / PUT / DELETE)
  → Laravel writes to PostgreSQL
  → PostgreSQL WAL emits the change
  → PowerSync syncs the canonical row back down (idempotent, de-duplicated)
```

#### Backend Rejects a Client Change

```
Flutter writes locally (optimistic)
  → LaravelConnector.uploadData() calls the API
  → Server returns error, status code 409 for example
  → PowerSync marks the operation as failed
  → Automatic rollback of the local SQLite row
```

> **Note — Sync rules vs. conflict resolution**
> Sync rules (the YAML deployed to the PowerSync dashboard) are solely concerned with *data routing*: they define which rows each client receives. They play no part in resolving conflicts.
> Conflict resolution is the responsibility of the **backend**. When a client uploads a change, the Laravel API can inspect the incoming payload, compare it against the current server state, and decide whether to accept, reject, or merge the change (returning an appropriate HTTP status code such as 409 to signal a conflict).
> By default — if the backend applies no additional logic — the outcome is **last-write-wins**: whichever upload reaches the server last overwrites the previous value.

---

## Test Results

### Scenario A — Offline create on all three tables → reconnect

Put the device into airplane mode. Created one Note and one Video. Restored connectivity.

**Result:** ✅ All records appeared in PostgreSQL with correct field values; zero data loss across all tables.

---

### Scenario B — Same record updated on two devices offline → both reconnect

**Quiz (grade field — server enforces business rules):**
- Device 1 offline: updated grade to `5`
- Device 2 offline: updated same quiz grade to `9`
- Device 1 reconnected first → grade `5` written to PostgreSQL
- Device 2 reconnected → upload returned HTTP 409 (confilct)
- Result: Device 2's local optimistic value was **rolled back** from `9` to `5`; server state preserved

**Note (content field — last-write-wins):**
- Both devices edited the same note offline
- Both synced successfully; final content matched the last-uploaded timestamp
- Result: ✅ No data loss; outcome deterministic given the LWW policy

---

### Scenario C — 100 queued offline operations → reconnect

Created 100 records across one table while offline, then restored connectivity.

| Metric | Result |
|---|---|
| Sync time | 3–5 seconds (Android emulator, 2 GB RAM) |
| Record ordering | ✅ Correct — operations replayed in queue order |
| Crashes | None observed |

---

### Local DB Sizes (measured on Android emulator)

| File | Size (idle) | Size (after 100-op burst) |
|---|---|---|
| `powersync.db` | 4 KB | ~230 KB |
| `powersync.db-wal` | 300 KB | ~3 MB |

WAL size grows quickly with burst writes. Even a modest number of additional operations pushed `powersync.db-wal` to ~3 MB and `powersync.db` to ~230 KB.

---

## Repository Structure

```
offline_first/
├── flutter_poc/          # Flutter app (PowerSync SDK, LaravelConnector, UI)
│   ├── lib/
│   │   ├── powersync/    # database.dart, schema.dart, connector.dart
│   │   ├── services/     # database_service.dart, api_client.dart
│   │   ├── models/       # note.dart, quiz.dart, video.dart
│   │   └── view/         # per-entity tabs + sync status bar
│   └── pubspec.yaml
└── laravel/              # Laravel 11 REST API + PostgreSQL migrations
    ├── app/
    │   ├── Http/Controllers/
    │   └── Models/
    ├── database/migrations/
    └── routes/api.php
```

## Key Dependencies

| Layer | Package / Tool | Purpose |
|---|---|---|
| Flutter | `powersync` | Offline SQLite + sync engine |
| Flutter | `dio` | HTTP client for upload connector |
| Flutter | `get_it` | Service locator / DI |
| Backend | Laravel 11 | REST API framework |
| Backend | PostgreSQL | Primary database with logical replication |
| Infra | PowerSync Cloud | Replication broker |
| Infra | ngrok | Expose local PostgreSQL + Laravel during POC |

---

## Running the POC Locally

### Prerequisites

- PHP 8.2+, Composer
- PostgreSQL 14+ (running locally)
- ngrok account (free tier is enough)
- Flutter SDK 3.x, Android emulator or physical device
- A PowerSync Cloud project (free tier: [powersync.com](https://powersync.com))

---

### Step 1 — Start Laravel and run migrations

```bash
cd laravel
composer install
cp .env.example .env          # then fill in DB_DATABASE, DB_USERNAME, DB_PASSWORD
php artisan key:generate
php artisan migrate           # creates notes, quizzes, videos tables in PostgreSQL
php artisan serve             # starts API at http://127.0.0.1:8000
```

Verify the API is up:

```bash
curl http://127.0.0.1:8000/api/notes   # should return []
```

---

### Step 2 — Enable logical replication in PostgreSQL

PowerSync requires `wal_level = logical`. Set it once, then restart PostgreSQL.

**Find your postgresql.conf:**

```bash
psql -U postgres -c "SHOW config_file;"
```

**Edit the file** and set (or add) the line:

```
wal_level = logical
```

**Restart PostgreSQL** (adjust the service name for your OS):

```bash
# macOS (Homebrew)
brew services restart postgresql@16

# Linux (systemd)
sudo systemctl restart postgresql
```

**Verify:**

```bash
psql -U postgres -c "SHOW wal_level;"
# Expected output:  wal_level
# ─────────────────
#  logical
```

**Create the publication** (run once, as the database owner):

```sql
psql -U postgres -d <your_database_name>
CREATE PUBLICATION powersync FOR TABLE notes, quizzes, videos;
```

---

### Step 3 — Expose PostgreSQL and Laravel via ngrok

Two tunnels are needed: one TCP tunnel for PostgreSQL (port 5432).

Open two terminal tabs and run each command in its own tab:

**PostgreSQL TCP tunnel:**

```bash
ngrok tcp 5432
```

Note the forwarding address, e.g. `tcp://0.tcp.ngrok.io:12345`. The host is `0.tcp.ngrok.io` and the port is `12345`.
Note: use the following command to get Server Certificate to be added into Powersync

```bash
# macOS 
cat /opt/homebrew/var/postgresql@18/server.crt
```

> The ngrok URLs change on every restart. Update PowerSync dashboard (Step 4) whenever you restart ngrok.

---

### Step 4 — Configure PowerSync Cloud

1. Log in to the PowerSync dashboard and open your project.

2. **Add a database connection:**
   - Go to **Connections** → **New Connection**
   - Type: **PostgreSQL**
   - Host: the ngrok TCP host (e.g. `0.tcp.ngrok.io`)
   - Port: the ngrok TCP port (e.g. `12345`)
   - Database: your PostgreSQL database name
   - Username / Password: your PostgreSQL credentials
   - Test the connection — it should show a green checkmark
   - add Server Certificate 
```bash
# macOS 
cat /opt/homebrew/var/postgresql@18/server.crt
```

3. **Deploy sync rules:**
   - Go to **Sync Rules** and paste (or confirm) the following YAML, then click **Deploy**:

   ```yaml
   bucket_definitions:
     global:
       data:
         - SELECT * FROM notes
         - SELECT * FROM quizzes
         - SELECT * FROM videos
   ```

4. **Get the instance URL and a dev token:**
   - The instance URL is shown in the project overview, e.g. `https://xxxxxxxxxxxxxxxxxxxxxxxx.powersync.journeyapps.com`
   - Go to **Auth** → **Generate dev token** to get a temporary JWT for local testing

---

### Step 5 — Wire the credentials into the Flutter app

Open `flutter_poc/lib/powersync/connector.dart` and replace the placeholder values in `fetchCredentials()`:

```dart
// flutter_poc/lib/powersync/connector.dart

@override
Future<PowerSyncCredentials?> fetchCredentials() async {
  return PowerSyncCredentials(
    endpoint: 'https://xxxxxxxxxxxxxxxxxxxxxxxx.powersync.journeyapps.com', // from Step 4
    token: 'eyJ...',   // dev token from Step 4
  );
}
```
---

### Step 6 — Run the Flutter app

```bash
cd flutter_poc
flutter pub get
flutter run              # pick the target when prompted, or pass -d <device-id>
```

The app should connect to PowerSync and display the sync status bar at the top. Any records you create will appear in PostgreSQL (check with `psql`) and any records written directly to PostgreSQL via Laravel will sync down to the app.
