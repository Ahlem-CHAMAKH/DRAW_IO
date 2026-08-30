import { chromium } from "@playwright/test";
import type { Scenario, ScenarioStep, StepType } from "./types.js";
import { installRecorder } from "./recorder-script.js";

export interface RecordOptions {
  name: string;
  url: string;
  headed?: boolean;
  description?: string;
}

interface RawEmittedStep {
  type: StepType;
  selector?: string;
  selectorLabel?: string;
  value?: string;
}

/**
 * Launches a real browser against `url`, records the user's clicks, fills,
 * selects, checks, and key presses as scenario steps, and resolves once the
 * user closes the browser window.
 */
export async function recordScenario(opts: RecordOptions): Promise<Scenario> {
  const browser = await chromium.launch({ headless: opts.headed === false });
  const context = await browser.newContext();

  const steps: ScenarioStep[] = [];
  let index = 0;

  const pushStep = (raw: RawEmittedStep, url?: string) => {
    steps.push({
      index: index++,
      type: raw.type,
      selector: raw.selector,
      selectorLabel: raw.selectorLabel,
      value: raw.value,
      url,
      timestamp: Date.now(),
    });
  };

  await context.exposeBinding("__qualimetryEmit", (_source, raw: RawEmittedStep) => {
    pushStep(raw);
  });
  await context.addInitScript(installRecorder);

  const page = await context.newPage();

  pushStep({ type: "goto" }, opts.url);
  await page.goto(opts.url, { waitUntil: "domcontentloaded" });

  let readyForNav = false;
  page.on("load", () => {
    readyForNav = true;
  });
  page.on("framenavigated", (frame) => {
    if (frame !== page.mainFrame()) return;
    if (!readyForNav) return; // skip the initial goto we already recorded
    const url = frame.url();
    if (url === "about:blank") return;
    pushStep({ type: "goto" }, url);
  });

  console.log(`\nRecording started. Interact with the browser window; close it when you're done.\n`);

  await new Promise<void>((resolve) => {
    context.on("close", () => resolve());
    page.on("close", () => {
      context.close().catch(() => undefined);
    });
  });

  await browser.close().catch(() => undefined);

  const now = new Date().toISOString();
  return {
    name: opts.name,
    description: opts.description,
    baseUrl: opts.url,
    createdAt: now,
    updatedAt: now,
    steps,
  };
}
