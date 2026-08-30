import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const PROJECT_ROOT = path.resolve(fileURLToPath(new URL("../..", import.meta.url)));
const DATA_DIR = path.join(PROJECT_ROOT, "data");
fs.mkdirSync(DATA_DIR, { recursive: true });

export const DB_PATH = path.join(DATA_DIR, "qualimetry.db");

export const db = new DatabaseSync(DB_PATH);

db.exec(`
  PRAGMA foreign_keys = ON;

  CREATE TABLE IF NOT EXISTS apps (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS scenarios (
    id TEXT PRIMARY KEY,
    app_id TEXT REFERENCES apps(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    base_url TEXT NOT NULL,
    steps_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS runs (
    id TEXT PRIMARY KEY,
    scenario_id TEXT NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    requested_repeats INTEGER NOT NULL,
    passed INTEGER NOT NULL,
    failed INTEGER NOT NULL,
    started_at TEXT NOT NULL,
    finished_at TEXT NOT NULL,
    report_json TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_runs_scenario_id ON runs (scenario_id);
`);

// Migration for databases created before workspaces existed: add the
// column if it's missing, then give every orphaned scenario a home. This
// must run before the app_id index below — on an upgraded (pre-workspace)
// database, the column doesn't exist yet when the block above runs, since
// CREATE TABLE IF NOT EXISTS is a no-op against an already-existing table.
const DEFAULT_APP_ID = "default-app";
const scenarioColumns = db.prepare("PRAGMA table_info(scenarios)").all() as Array<{ name: string }>;
if (!scenarioColumns.some((c) => c.name === "app_id")) {
  db.exec("ALTER TABLE scenarios ADD COLUMN app_id TEXT REFERENCES apps(id) ON DELETE CASCADE");
}

const hasDefaultApp = db.prepare("SELECT id FROM apps WHERE id = ?").get(DEFAULT_APP_ID);
if (!hasDefaultApp) {
  const now = new Date().toISOString();
  db.prepare(
    `INSERT INTO apps (id, name, slug, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)`
  ).run(DEFAULT_APP_ID, "Unsorted", "unsorted", null, now, now);
}
db.prepare("UPDATE scenarios SET app_id = ? WHERE app_id IS NULL").run(DEFAULT_APP_ID);

db.exec("CREATE INDEX IF NOT EXISTS idx_scenarios_app_id ON scenarios (app_id)");
