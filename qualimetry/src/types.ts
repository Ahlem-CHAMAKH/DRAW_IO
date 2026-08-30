export type StepType =
  | "goto"
  | "click"
  | "dblclick"
  | "fill"
  | "check"
  | "uncheck"
  | "select"
  | "press"
  | "assertText"
  | "assertVisible"
  | "assertUrl";

export interface ScenarioStep {
  /** Sequential order within the scenario. */
  index: number;
  type: StepType;
  /** CSS/text selector understood by Playwright locators. Absent for goto/press-on-page steps. */
  selector?: string;
  /** A short human-readable description of the target element, for readability in generated scripts. */
  selectorLabel?: string;
  /** Value typed, selected, pressed, or asserted, depending on step type. */
  value?: string;
  /** True if this step's real value was withheld at capture time (e.g. a password field). Legacy — implies variableName "password", sensitive true. New recordings use variableName/sensitive directly. */
  redacted?: boolean;
  /** If set, this step's value is supplied at run time under this name instead of the literal captured value — see stepVariable(). */
  variableName?: string;
  /** True if the variable's value should be masked in the UI and never persisted (e.g. a password). */
  sensitive?: boolean;
  /** Absolute URL, only for "goto" and "assertUrl" steps. */
  url?: string;
  /** Epoch ms when the step was captured. */
  timestamp: number;
}

export interface StepVariable {
  name: string;
  sensitive: boolean;
}

/** Resolves a step's runtime variable, if any — folding the legacy `redacted` flag into the same shape. */
export function stepVariable(step: ScenarioStep): StepVariable | undefined {
  if (step.variableName) return { name: step.variableName, sensitive: step.sensitive ?? false };
  if (step.redacted) return { name: "password", sensitive: true };
  return undefined;
}

/** Deterministic env var name for a variable, used as the generated script's/CLI's override mechanism. */
export function envVarNameFor(variableName: string): string {
  const slug = variableName
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return `QUALIMETRY_VAR_${slug || "VALUE"}`;
}

export interface Scenario {
  name: string;
  description?: string;
  baseUrl: string;
  createdAt: string;
  updatedAt: string;
  steps: ScenarioStep[];
}

export interface StepResult {
  index: number;
  type: StepType;
  ok: boolean;
  durationMs: number;
  error?: string;
}

export interface RunAttemptResult {
  attempt: number;
  ok: boolean;
  startedAt: string;
  durationMs: number;
  steps: StepResult[];
  /** Relative to the server's reports/ directory, e.g. "my-scenario/attempt-1-failure.png". */
  screenshotPath?: string;
  /** Relative to the server's reports/ directory, e.g. "my-scenario/attempt-1.webm". Recorded for every attempt. */
  videoPath?: string;
  error?: string;
}

export interface RunReport {
  scenario: string;
  baseUrl: string;
  requestedRepeats: number;
  startedAt: string;
  finishedAt: string;
  passed: number;
  failed: number;
  attempts: RunAttemptResult[];
}
