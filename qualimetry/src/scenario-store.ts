import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { Scenario } from "./types.js";
import { generateSpec } from "./generate.js";

const execFileAsync = promisify(execFile);

const PROJECT_ROOT = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
export const SCENARIOS_DIR = path.join(PROJECT_ROOT, "scenarios");
export const REPORTS_DIR = path.join(PROJECT_ROOT, "reports");

export function slugify(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

function scenarioDir(name: string): string {
  return path.join(SCENARIOS_DIR, slugify(name));
}

export interface SavedScenarioPaths {
  dir: string;
  jsonPath: string;
  specPath: string;
}

/** Writes scenario.json and the generated .spec.ts into scenarios/<slug>/. */
export async function saveScenario(scenario: Scenario): Promise<SavedScenarioPaths> {
  const dir = scenarioDir(scenario.name);
  await fs.mkdir(dir, { recursive: true });

  const jsonPath = path.join(dir, "scenario.json");
  const specPath = path.join(dir, `${slugify(scenario.name)}.spec.ts`);

  scenario.updatedAt = new Date().toISOString();
  await fs.writeFile(jsonPath, JSON.stringify(scenario, null, 2) + "\n", "utf8");
  await fs.writeFile(specPath, generateSpec(scenario), "utf8");

  return { dir, jsonPath, specPath };
}

export async function loadScenario(name: string): Promise<Scenario> {
  const jsonPath = path.join(scenarioDir(name), "scenario.json");
  const raw = await fs.readFile(jsonPath, "utf8");
  return JSON.parse(raw) as Scenario;
}

export interface ScenarioSummary {
  name: string;
  slug: string;
  baseUrl: string;
  stepCount: number;
  updatedAt: string;
}

export async function listScenarios(): Promise<ScenarioSummary[]> {
  await fs.mkdir(SCENARIOS_DIR, { recursive: true });
  const entries = await fs.readdir(SCENARIOS_DIR, { withFileTypes: true });
  const summaries: ScenarioSummary[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    try {
      const raw = await fs.readFile(path.join(SCENARIOS_DIR, entry.name, "scenario.json"), "utf8");
      const scenario = JSON.parse(raw) as Scenario;
      summaries.push({
        name: scenario.name,
        slug: entry.name,
        baseUrl: scenario.baseUrl,
        stepCount: scenario.steps.length,
        updatedAt: scenario.updatedAt,
      });
    } catch {
      // Not a valid scenario directory; skip it.
    }
  }

  return summaries;
}

/** Stages and commits a scenario's directory with plain git. Requires the tool to run inside a git repo. */
export async function commitScenario(scenario: Scenario, message?: string): Promise<void> {
  const dir = scenarioDir(scenario.name);
  const relDir = path.relative(process.cwd(), dir);
  await execFileAsync("git", ["add", relDir]);
  await execFileAsync("git", [
    "commit",
    "-m",
    message ?? `qualimetry: save scenario "${scenario.name}"`,
  ]);
}
