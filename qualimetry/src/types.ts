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
  /** True if this step's real value was withheld at capture time (e.g. a password field). */
  redacted?: boolean;
  /** Absolute URL, only for "goto" and "assertUrl" steps. */
  url?: string;
  /** Epoch ms when the step was captured. */
  timestamp: number;
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
  screenshotPath?: string;
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
