#!/usr/bin/env node
import { Command } from "commander";
import { recordScenario } from "./record.js";
import { generateSpec } from "./generate.js";
import { saveScenario, loadScenario, listScenarios, commitScenario } from "./scenario-store.js";
import { runScenario } from "./runner.js";

const program = new Command();

program
  .name("qualimetry")
  .description(
    "Record browser actions, generate test scripts, save scenarios, and replay them repeatedly."
  )
  .version("0.1.0");

program
  .command("record")
  .description("Record a new scenario by interacting with a real browser window")
  .argument("<name>", "Scenario name")
  .argument("<url>", "URL to start recording from")
  .option("-d, --description <text>", "Optional description")
  .option("--headless", "Run the recording browser headless (not useful for interactive recording)")
  .option("--commit", "git commit the saved scenario after recording")
  .option("-m, --message <msg>", "Commit message (used with --commit)")
  .action(async (name: string, url: string, opts) => {
    const scenario = await recordScenario({
      name,
      url,
      description: opts.description,
      headed: !opts.headless,
    });
    console.log(`\nRecorded ${scenario.steps.length} steps.`);

    const paths = await saveScenario(scenario);
    console.log(`Saved scenario:  ${paths.jsonPath}`);
    console.log(`Generated spec:  ${paths.specPath}`);

    if (opts.commit) {
      await commitScenario(scenario, opts.message);
      console.log(`Committed scenario "${scenario.name}" to git.`);
    }
  });

program
  .command("generate")
  .description("Regenerate the .spec.ts file for a saved scenario (e.g. after hand-editing scenario.json)")
  .argument("<name>", "Scenario name")
  .action(async (name: string) => {
    const scenario = await loadScenario(name);
    const paths = await saveScenario(scenario);
    console.log(`Regenerated spec: ${paths.specPath}`);
  });

program
  .command("list")
  .description("List saved scenarios")
  .action(async () => {
    const scenarios = await listScenarios();
    if (scenarios.length === 0) {
      console.log("No scenarios saved yet. Run `qualimetry record <name> <url>` to create one.");
      return;
    }
    for (const s of scenarios) {
      console.log(`${s.name}  (${s.slug})  ${s.stepCount} steps  ${s.baseUrl}  updated ${s.updatedAt}`);
    }
  });

program
  .command("run")
  .description("Replay a saved scenario against a real browser, optionally repeating it")
  .argument("<name>", "Scenario name")
  .option("-r, --repeat <n>", "Number of times to repeat the scenario", "1")
  .option("--headed", "Show the browser window while running")
  .option("-t, --timeout <ms>", "Per-step timeout in milliseconds", "10000")
  .option("--stop-on-failure", "Stop repeating as soon as one attempt fails")
  .action(async (name: string, opts) => {
    const scenario = await loadScenario(name);
    console.log(`Running "${scenario.name}" (${scenario.steps.length} steps) x${opts.repeat}...`);

    const report = await runScenario(scenario, {
      repeat: parseInt(opts.repeat, 10),
      headed: !!opts.headed,
      timeoutMs: parseInt(opts.timeout, 10),
      stopOnFailure: !!opts.stopOnFailure,
    });

    console.log(`\n${report.passed} passed, ${report.failed} failed out of ${report.attempts.length}.`);
    if (report.failed > 0) process.exitCode = 1;
  });

program.parseAsync(process.argv);
