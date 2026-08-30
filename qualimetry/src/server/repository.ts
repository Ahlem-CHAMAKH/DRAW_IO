import crypto from "node:crypto";
import { db } from "./db.js";
import { slugify } from "../scenario-store.js";
import type { RunReport, Scenario, ScenarioStep } from "../types.js";

interface AppRow {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  created_at: string;
  updated_at: string;
  scenario_count: number;
}

interface ScenarioRow {
  id: string;
  app_id: string;
  app_name: string;
  name: string;
  slug: string;
  description: string | null;
  base_url: string;
  steps_json: string;
  created_at: string;
  updated_at: string;
}

interface RunRow {
  id: string;
  scenario_id: string;
  requested_repeats: number;
  passed: number;
  failed: number;
  started_at: string;
  finished_at: string;
  report_json: string;
}

export interface StoredApp {
  id: string;
  name: string;
  slug: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
  scenarioCount: number;
}

export interface StoredScenario extends Scenario {
  id: string;
  slug: string;
  appId: string;
  appName: string;
}

export interface StoredRun {
  id: string;
  scenarioId: string;
  requestedRepeats: number;
  passed: number;
  failed: number;
  startedAt: string;
  finishedAt: string;
  report: RunReport;
}

const SCENARIO_SELECT = `
  SELECT scenarios.*, apps.name AS app_name
  FROM scenarios
  JOIN apps ON apps.id = scenarios.app_id
`;

function rowToApp(row: AppRow): StoredApp {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    scenarioCount: row.scenario_count,
  };
}

function rowToScenario(row: ScenarioRow): StoredScenario {
  return {
    id: row.id,
    slug: row.slug,
    appId: row.app_id,
    appName: row.app_name,
    name: row.name,
    description: row.description ?? undefined,
    baseUrl: row.base_url,
    steps: JSON.parse(row.steps_json) as ScenarioStep[],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function rowToRun(row: RunRow): StoredRun {
  return {
    id: row.id,
    scenarioId: row.scenario_id,
    requestedRepeats: row.requested_repeats,
    passed: row.passed,
    failed: row.failed,
    startedAt: row.started_at,
    finishedAt: row.finished_at,
    report: JSON.parse(row.report_json) as RunReport,
  };
}

function uniqueSlugIn(table: "apps" | "scenarios", name: string, fallback: string, excludeId?: string): string {
  const base = slugify(name) || fallback;
  let candidate = base;
  let n = 2;
  while (true) {
    const row = db.prepare(`SELECT id FROM ${table} WHERE slug = ?`).get(candidate) as
      | { id: string }
      | undefined;
    if (!row || row.id === excludeId) return candidate;
    candidate = `${base}-${n++}`;
  }
}

// ---- Apps (workspaces) ----

export interface NewAppInput {
  name: string;
  description?: string;
}

export function createApp(input: NewAppInput): StoredApp {
  const id = crypto.randomUUID();
  const slug = uniqueSlugIn("apps", input.name, "app");
  const now = new Date().toISOString();

  db.prepare(`INSERT INTO apps (id, name, slug, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)`).run(
    id,
    input.name,
    slug,
    input.description ?? null,
    now,
    now
  );

  return getApp(id)!;
}

/** Finds an app by (case-insensitive) name, or creates one — used when the extension saves a scenario by app name. */
export function findOrCreateAppByName(name: string): StoredApp {
  const trimmed = name.trim();
  const row = db.prepare("SELECT id FROM apps WHERE lower(name) = lower(?)").get(trimmed) as
    | { id: string }
    | undefined;
  if (row) return getApp(row.id)!;
  return createApp({ name: trimmed });
}

export interface UpdateAppInput {
  name?: string;
  description?: string;
}

export function updateApp(id: string, input: UpdateAppInput): StoredApp | undefined {
  const existing = getApp(id);
  if (!existing) return undefined;

  const name = input.name ?? existing.name;
  const slug = input.name && input.name !== existing.name ? uniqueSlugIn("apps", input.name, "app", existing.id) : existing.slug;
  const description = input.description ?? existing.description ?? null;
  const updatedAt = new Date().toISOString();

  db.prepare(`UPDATE apps SET name = ?, slug = ?, description = ?, updated_at = ? WHERE id = ?`).run(
    name,
    slug,
    description,
    updatedAt,
    existing.id
  );

  return getApp(existing.id);
}

export function getApp(id: string): StoredApp | undefined {
  const row = db
    .prepare(
      `SELECT apps.*, (SELECT COUNT(*) FROM scenarios WHERE scenarios.app_id = apps.id) AS scenario_count
       FROM apps WHERE apps.id = ? OR apps.slug = ?`
    )
    .get(id, id) as unknown as AppRow | undefined;
  return row ? rowToApp(row) : undefined;
}

export function listApps(): StoredApp[] {
  const rows = db
    .prepare(
      `SELECT apps.*, (SELECT COUNT(*) FROM scenarios WHERE scenarios.app_id = apps.id) AS scenario_count
       FROM apps ORDER BY apps.name COLLATE NOCASE ASC`
    )
    .all() as unknown as AppRow[];
  return rows.map(rowToApp);
}

export function deleteApp(id: string): boolean {
  const result = db.prepare("DELETE FROM apps WHERE id = ? OR slug = ?").run(id, id);
  return result.changes > 0;
}

// ---- Scenarios ----

export interface NewScenarioInput {
  appId: string;
  name: string;
  description?: string;
  baseUrl: string;
  steps: ScenarioStep[];
}

export function createScenario(input: NewScenarioInput): StoredScenario {
  const id = crypto.randomUUID();
  const slug = uniqueSlugIn("scenarios", input.name, "scenario");
  const now = new Date().toISOString();

  db.prepare(
    `INSERT INTO scenarios (id, app_id, name, slug, description, base_url, steps_json, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    id,
    input.appId,
    input.name,
    slug,
    input.description ?? null,
    input.baseUrl,
    JSON.stringify(input.steps),
    now,
    now
  );

  return getScenario(id)!;
}

export interface UpdateScenarioInput {
  appId?: string;
  name?: string;
  description?: string;
  baseUrl?: string;
  steps?: ScenarioStep[];
}

export function updateScenario(id: string, input: UpdateScenarioInput): StoredScenario | undefined {
  const existing = getScenario(id);
  if (!existing) return undefined;

  const appId = input.appId ?? existing.appId;
  const name = input.name ?? existing.name;
  const slug =
    input.name && input.name !== existing.name
      ? uniqueSlugIn("scenarios", input.name, "scenario", existing.id)
      : existing.slug;
  const description = input.description ?? existing.description ?? null;
  const baseUrl = input.baseUrl ?? existing.baseUrl;
  const steps = input.steps ?? existing.steps;
  const updatedAt = new Date().toISOString();

  db.prepare(
    `UPDATE scenarios SET app_id = ?, name = ?, slug = ?, description = ?, base_url = ?, steps_json = ?, updated_at = ?
     WHERE id = ?`
  ).run(appId, name, slug, description, baseUrl, JSON.stringify(steps), updatedAt, existing.id);

  return getScenario(existing.id);
}

export function getScenario(id: string): StoredScenario | undefined {
  const row = db
    .prepare(`${SCENARIO_SELECT} WHERE scenarios.id = ? OR scenarios.slug = ?`)
    .get(id, id) as unknown as ScenarioRow | undefined;
  return row ? rowToScenario(row) : undefined;
}

export function listScenarios(appId?: string): StoredScenario[] {
  const rows = appId
    ? (db
        .prepare(`${SCENARIO_SELECT} WHERE scenarios.app_id = (SELECT id FROM apps WHERE id = ? OR slug = ?) ORDER BY scenarios.updated_at DESC`)
        .all(appId, appId) as unknown as ScenarioRow[])
    : (db.prepare(`${SCENARIO_SELECT} ORDER BY scenarios.updated_at DESC`).all() as unknown as ScenarioRow[]);
  return rows.map(rowToScenario);
}

export function deleteScenario(id: string): boolean {
  const result = db.prepare("DELETE FROM scenarios WHERE id = ? OR slug = ?").run(id, id);
  return result.changes > 0;
}

export function createRun(scenarioId: string, report: RunReport): StoredRun {
  const id = crypto.randomUUID();
  db.prepare(
    `INSERT INTO runs (id, scenario_id, requested_repeats, passed, failed, started_at, finished_at, report_json)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    id,
    scenarioId,
    report.requestedRepeats,
    report.passed,
    report.failed,
    report.startedAt,
    report.finishedAt,
    JSON.stringify(report)
  );
  return rowToRun(db.prepare("SELECT * FROM runs WHERE id = ?").get(id) as unknown as RunRow);
}

export function listRuns(scenarioId: string): StoredRun[] {
  const rows = db
    .prepare("SELECT * FROM runs WHERE scenario_id = ? ORDER BY started_at DESC")
    .all(scenarioId) as unknown as RunRow[];
  return rows.map(rowToRun);
}

export function getRun(scenarioId: string, runId: string): StoredRun | undefined {
  const row = db
    .prepare("SELECT * FROM runs WHERE scenario_id = ? AND id = ?")
    .get(scenarioId, runId) as unknown as RunRow | undefined;
  return row ? rowToRun(row) : undefined;
}
