import crypto from "node:crypto";
import { db } from "./db.js";
import { slugify } from "../scenario-store.js";
import type { RunReport, Scenario, ScenarioStep } from "../types.js";

interface ScenarioRow {
  id: string;
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

export interface StoredScenario extends Scenario {
  id: string;
  slug: string;
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

function rowToScenario(row: ScenarioRow): StoredScenario {
  return {
    id: row.id,
    slug: row.slug,
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

function uniqueSlug(name: string, excludeId?: string): string {
  const base = slugify(name) || "scenario";
  let candidate = base;
  let n = 2;
  while (true) {
    const row = db
      .prepare("SELECT id FROM scenarios WHERE slug = ?")
      .get(candidate) as { id: string } | undefined;
    if (!row || row.id === excludeId) return candidate;
    candidate = `${base}-${n++}`;
  }
}

export interface NewScenarioInput {
  name: string;
  description?: string;
  baseUrl: string;
  steps: ScenarioStep[];
}

export function createScenario(input: NewScenarioInput): StoredScenario {
  const id = crypto.randomUUID();
  const slug = uniqueSlug(input.name);
  const now = new Date().toISOString();

  db.prepare(
    `INSERT INTO scenarios (id, name, slug, description, base_url, steps_json, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(id, input.name, slug, input.description ?? null, input.baseUrl, JSON.stringify(input.steps), now, now);

  return getScenario(id)!;
}

export interface UpdateScenarioInput {
  name?: string;
  description?: string;
  baseUrl?: string;
  steps?: ScenarioStep[];
}

export function updateScenario(id: string, input: UpdateScenarioInput): StoredScenario | undefined {
  const existing = getScenario(id);
  if (!existing) return undefined;

  const name = input.name ?? existing.name;
  const slug =
    input.name && input.name !== existing.name ? uniqueSlug(input.name, existing.id) : existing.slug;
  const description = input.description ?? existing.description ?? null;
  const baseUrl = input.baseUrl ?? existing.baseUrl;
  const steps = input.steps ?? existing.steps;
  const updatedAt = new Date().toISOString();

  db.prepare(
    `UPDATE scenarios SET name = ?, slug = ?, description = ?, base_url = ?, steps_json = ?, updated_at = ?
     WHERE id = ?`
  ).run(name, slug, description, baseUrl, JSON.stringify(steps), updatedAt, existing.id);

  return getScenario(existing.id);
}

export function getScenario(id: string): StoredScenario | undefined {
  const row = db.prepare("SELECT * FROM scenarios WHERE id = ? OR slug = ?").get(id, id) as unknown as
    | ScenarioRow
    | undefined;
  return row ? rowToScenario(row) : undefined;
}

export function listScenarios(): StoredScenario[] {
  const rows = db
    .prepare("SELECT * FROM scenarios ORDER BY updated_at DESC")
    .all() as unknown as ScenarioRow[];
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
  return rowToRun(
    db.prepare("SELECT * FROM runs WHERE id = ?").get(id) as unknown as RunRow
  );
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
