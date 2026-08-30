import path from "node:path";
import os from "node:os";
import fs from "node:fs/promises";
import { chromium, expect, type Page } from "@playwright/test";
import { envVarNameFor, stepVariable, type RunAttemptResult, type RunReport, type Scenario, type ScenarioStep, type StepResult } from "./types.js";
import { REPORTS_DIR, slugify } from "./scenario-store.js";

export interface RunOptions {
  repeat?: number;
  headed?: boolean;
  timeoutMs?: number;
  stopOnFailure?: boolean;
  /** Values for this run's variablized steps (by variable name), for this run only — never persisted. Falls back to process.env.QUALIMETRY_VAR_<NAME> per variable. */
  variables?: Record<string, string>;
}

/** Resolves a fill/select step's actual value: the run's supplied variable, then the matching env var, then "". */
function resolveValue(step: ScenarioStep, variables: Record<string, string>): string {
  const variable = stepVariable(step);
  if (!variable) return step.value ?? "";
  return variables[variable.name] ?? process.env[envVarNameFor(variable.name)] ?? "";
}

async function executeStep(
  page: Page,
  step: ScenarioStep,
  timeoutMs: number,
  variables: Record<string, string>
): Promise<void> {
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
      await locator!.fill(resolveValue(step, variables), { timeout: timeoutMs });
      return;
    case "check":
      await locator!.check({ timeout: timeoutMs });
      return;
    case "uncheck":
      await locator!.uncheck({ timeout: timeoutMs });
      return;
    case "select":
      await locator!.selectOption(resolveValue(step, variables), { timeout: timeoutMs });
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

/**
 * Runs one attempt. Screenshot/video paths returned in the result are
 * relative to REPORTS_DIR (e.g. "my-scenario/attempt-1.webm") so the server
 * can serve them directly under /reports/ without leaking filesystem layout.
 */
async function runAttempt(
  scenario: Scenario,
  attempt: number,
  opts: Required<Pick<RunOptions, "headed" | "timeoutMs">> & { variables: Record<string, string> },
  reportDir: string,
  slug: string
): Promise<RunAttemptResult> {
  const browser = await chromium.launch({ headless: !opts.headed });
  const videoTmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "qualimetry-video-"));
  const context = await browser.newContext({
    recordVideo: { dir: videoTmpDir, size: { width: 1280, height: 720 } },
  });
  const page = await context.newPage();

  const startedAt = new Date().toISOString();
  const start = Date.now();
  const stepResults: StepResult[] = [];
  let screenshotPath: string | undefined;
  let attemptError: string | undefined;

  for (const step of scenario.steps) {
    const stepStart = Date.now();
    try {
      await executeStep(page, step, opts.timeoutMs, opts.variables);
      stepResults.push({ index: step.index, type: step.type, ok: true, durationMs: Date.now() - stepStart });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      stepResults.push({ index: step.index, type: step.type, ok: false, durationMs: Date.now() - stepStart, error: message });
      attemptError = `Step ${step.index} (${step.type}) failed: ${message}`;
      try {
        await page.screenshot({ path: path.join(reportDir, `attempt-${attempt}-failure.png`) });
        screenshotPath = `${slug}/attempt-${attempt}-failure.png`;
      } catch {
        screenshotPath = undefined;
      }
      break;
    }
  }

  // Every attempt gets a video, like Cypress records every run by default —
  // page.video() must be read before context.close() invalidates the handle,
  // but saveAs() itself needs to run after close() to see the finalized file.
  const video = page.video();
  await context.close().catch(() => undefined);

  let videoPath: string | undefined;
  if (video) {
    try {
      await video.saveAs(path.join(reportDir, `attempt-${attempt}.webm`));
      videoPath = `${slug}/attempt-${attempt}.webm`;
    } catch {
      videoPath = undefined;
    }
  }

  await browser.close().catch(() => undefined);
  await fs.rm(videoTmpDir, { recursive: true, force: true }).catch(() => undefined);

  return {
    attempt,
    ok: !attemptError,
    startedAt,
    durationMs: Date.now() - start,
    steps: stepResults,
    screenshotPath,
    videoPath,
    error: attemptError,
  };
}

/** Replays a scenario `repeat` times, isolating each run in its own browser context, like Cypress test isolation. */
export async function runScenario(scenario: Scenario, opts: RunOptions = {}): Promise<RunReport> {
  const repeat = Math.max(1, opts.repeat ?? 1);
  const headed = opts.headed ?? false;
  const timeoutMs = opts.timeoutMs ?? 10_000;
  const stopOnFailure = opts.stopOnFailure ?? false;
  const variables = opts.variables ?? {};

  const slug = slugify(scenario.name);
  const screenshotDir = path.join(REPORTS_DIR, slug);
  await fs.mkdir(screenshotDir, { recursive: true });

  const startedAt = new Date().toISOString();
  const attempts: RunAttemptResult[] = [];

  for (let i = 1; i <= repeat; i++) {
    const result = await runAttempt(scenario, i, { headed, timeoutMs, variables }, screenshotDir, slug);
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

export interface SelectorCheckResult {
  count: number;
  visible: boolean;
  outerHtmlSnippet?: string;
}

/**
 * Cypress-style "Selector Playground": loads `url` fresh (no prior scenario
 * steps replayed) and reports how many elements `selector` matches right
 * now. Useful for spotting a fragile or conditionally-rendered selector
 * before wiring it into a full run — but since it doesn't replay preceding
 * steps, it can't reproduce state that only exists mid-scenario (e.g. after
 * a login or a validation error).
 */
export async function checkSelector(url: string, selector: string, timeoutMs = 8000): Promise<SelectorCheckResult> {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: timeoutMs });
    const locator = page.locator(selector);
    const count = await locator.count();

    let visible = false;
    let outerHtmlSnippet: string | undefined;
    if (count > 0) {
      try {
        visible = await locator.first().isVisible();
        const html = await locator.first().evaluate((el) => el.outerHTML);
        outerHtmlSnippet = html.length > 300 ? html.slice(0, 300) + "…" : html;
      } catch {
        // Element existed for count() but errored on inspection (detached, etc.) — leave defaults.
      }
    }

    return { count, visible, outerHtmlSnippet };
  } finally {
    await browser.close().catch(() => undefined);
  }
}
