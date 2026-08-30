import path from "node:path";
import fs from "node:fs/promises";
import { chromium, expect, type Page } from "@playwright/test";
import type { RunAttemptResult, RunReport, Scenario, ScenarioStep, StepResult } from "./types.js";
import { REPORTS_DIR, slugify } from "./scenario-store.js";

export interface RunOptions {
  repeat?: number;
  headed?: boolean;
  timeoutMs?: number;
  stopOnFailure?: boolean;
}

async function executeStep(page: Page, step: ScenarioStep, timeoutMs: number): Promise<void> {
  const locator = step.selector ? page.locator(step.selector) : undefined;

  switch (step.type) {
    case "goto":
      await page.goto(step.url ?? "", { waitUntil: "domcontentloaded", timeout: timeoutMs });
      return;
    case "click":
      await locator!.click({ timeout: timeoutMs });
      return;
    case "dblclick":
      await locator!.dblclick({ timeout: timeoutMs });
      return;
    case "fill":
      await locator!.fill(step.redacted ? process.env.QUALIMETRY_SECRET ?? "" : step.value ?? "", {
        timeout: timeoutMs,
      });
      return;
    case "check":
      await locator!.check({ timeout: timeoutMs });
      return;
    case "uncheck":
      await locator!.uncheck({ timeout: timeoutMs });
      return;
    case "select":
      await locator!.selectOption(step.value ?? "", { timeout: timeoutMs });
      return;
    case "press":
      if (locator) await locator.press(step.value ?? "Enter", { timeout: timeoutMs });
      else await page.keyboard.press(step.value ?? "Enter");
      return;
    case "assertText":
      await expect(locator!).toHaveText(step.value ?? "", { timeout: timeoutMs });
      return;
    case "assertVisible":
      await expect(locator!).toBeVisible({ timeout: timeoutMs });
      return;
    case "assertUrl":
      await expect(page).toHaveURL(step.url ?? "", { timeout: timeoutMs });
      return;
    default:
      throw new Error(`Unsupported step type: ${step.type}`);
  }
}

async function runAttempt(
  scenario: Scenario,
  attempt: number,
  opts: Required<Pick<RunOptions, "headed" | "timeoutMs">>,
  screenshotDir: string
): Promise<RunAttemptResult> {
  const browser = await chromium.launch({ headless: !opts.headed });
  const context = await browser.newContext();
  const page = await context.newPage();

  const startedAt = new Date().toISOString();
  const start = Date.now();
  const stepResults: StepResult[] = [];
  let screenshotPath: string | undefined;
  let attemptError: string | undefined;

  for (const step of scenario.steps) {
    const stepStart = Date.now();
    try {
      await executeStep(page, step, opts.timeoutMs);
      stepResults.push({ index: step.index, type: step.type, ok: true, durationMs: Date.now() - stepStart });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      stepResults.push({ index: step.index, type: step.type, ok: false, durationMs: Date.now() - stepStart, error: message });
      attemptError = `Step ${step.index} (${step.type}) failed: ${message}`;
      try {
        screenshotPath = path.join(screenshotDir, `attempt-${attempt}-failure.png`);
        await page.screenshot({ path: screenshotPath });
      } catch {
        screenshotPath = undefined;
      }
      break;
    }
  }

  await context.close().catch(() => undefined);
  await browser.close().catch(() => undefined);

  return {
    attempt,
    ok: !attemptError,
    startedAt,
    durationMs: Date.now() - start,
    steps: stepResults,
    screenshotPath,
    error: attemptError,
  };
}

/** Replays a scenario `repeat` times, isolating each run in its own browser context, like Cypress test isolation. */
export async function runScenario(scenario: Scenario, opts: RunOptions = {}): Promise<RunReport> {
  const repeat = Math.max(1, opts.repeat ?? 1);
  const headed = opts.headed ?? false;
  const timeoutMs = opts.timeoutMs ?? 10_000;
  const stopOnFailure = opts.stopOnFailure ?? false;

  const slug = slugify(scenario.name);
  const screenshotDir = path.join(REPORTS_DIR, slug);
  await fs.mkdir(screenshotDir, { recursive: true });

  const startedAt = new Date().toISOString();
  const attempts: RunAttemptResult[] = [];

  for (let i = 1; i <= repeat; i++) {
    const result = await runAttempt(scenario, i, { headed, timeoutMs }, screenshotDir);
    attempts.push(result);
    console.log(
      `  attempt ${i}/${repeat}: ${result.ok ? "PASS" : "FAIL"} (${result.durationMs}ms)` +
        (result.error ? ` — ${result.error}` : "")
    );
    if (!result.ok && stopOnFailure) break;
  }

  const report: RunReport = {
    scenario: scenario.name,
    baseUrl: scenario.baseUrl,
    requestedRepeats: repeat,
    startedAt,
    finishedAt: new Date().toISOString(),
    passed: attempts.filter((a) => a.ok).length,
    failed: attempts.filter((a) => !a.ok).length,
    attempts,
  };

  const reportPath = path.join(screenshotDir, `report-${Date.now()}.json`);
  await fs.writeFile(reportPath, JSON.stringify(report, null, 2) + "\n", "utf8");

  return report;
}
