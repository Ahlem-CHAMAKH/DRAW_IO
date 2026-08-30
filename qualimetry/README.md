# qualimetry

A small CLI that takes the parts of Cypress and Selenium that matter most for
day-to-day UI testing and puts them behind one workflow:

1. **Record** — interact with a real browser; qualimetry captures your clicks,
   typing, selections, checkboxes, key presses, and navigations.
2. **Generate** — turns the recording into a readable
   [`@playwright/test`](https://playwright.dev/docs/writing-tests) spec file
   (auto-waiting, cross-browser, like Cypress's ergonomics on Selenium's
   WebDriver-style engine).
3. **Save** — writes the scenario (as portable JSON) and the generated script
   into `scenarios/<slug>/`, ready to commit to this git repo.
4. **Automate** — replays a saved scenario as many times as you want, each run
   isolated in its own browser context, with a pass/fail report and a
   screenshot on failure.

## Install

```bash
cd qualimetry
npm install         # also runs `playwright install chromium` via postinstall
npm run build
```

If `playwright install chromium` can't reach the network in your environment,
run it manually later on a machine with normal internet access:
`npx playwright install chromium`.

## Usage

Run via `npm run dev -- <command>` during development, or `node dist/cli.js
<command>` / `npx qualimetry <command>` after `npm run build`.

### Record a scenario

```bash
qualimetry record "login flow" https://example.com/login
```

Opens a real (headed) Chromium window at the given URL. Interact with the
page normally — click, type, select, check boxes, navigate. Close the browser
window when you're done; qualimetry saves the scenario automatically to
`scenarios/login-flow/`:

- `scenario.json` — the portable, hand-editable step list
- `login-flow.spec.ts` — a generated Playwright test you can also run with
  `npx playwright test`

Options: `-d, --description <text>`, `--commit` (git-commit the saved files),
`-m, --message <msg>`.

Recording needs a visible browser window, so it must be run on a machine with
a display (your laptop/dev box), not in a headless CI or server container.

### Assertions

The recorder captures interactions, not assertions — there's no reliable DOM
signal for "the user meant to check this." Add `assertText`, `assertVisible`,
or `assertUrl` steps by hand to `scenario.json` after recording, then run
`qualimetry generate <name>` to fold them into the generated spec.

### List saved scenarios

```bash
qualimetry list
```

### Automate / repeat a scenario

```bash
qualimetry run "login flow" --repeat 20 --headed
```

Replays the scenario the requested number of times (default 1), each attempt
in a fresh browser context. Prints a pass/fail line per attempt and writes a
JSON report plus a failure screenshot (when applicable) to
`reports/<slug>/`.

Options: `-r, --repeat <n>`, `--headed`, `-t, --timeout <ms>` (per-step
timeout, default 10000), `--stop-on-failure`.

### Regenerate a script after editing scenario.json

```bash
qualimetry generate "login flow"
```

## Project layout

```
qualimetry/
  src/            CLI + recorder + generator + runner source (TypeScript)
  scenarios/      saved scenarios: scenario.json + generated *.spec.ts
  reports/        JSON run reports + failure screenshots (gitignored)
```

## Design notes

- **Engine**: [Playwright](https://playwright.dev/), for Cypress-style
  auto-waiting locators plus Selenium-style multi-browser WebDriver-grade
  automation, without needing two separate engines.
- **Selectors**: prefers `id`, then `data-testid`/`data-test`/`data-cy`/`data-qa`,
  then `name`, then falls back to a short structural CSS path — robust
  enough for typical apps without requiring instrumentation, but you can
  always hand-edit `scenario.json` if a selector is fragile.
- **Isolation**: every replay attempt gets its own browser context (matching
  Cypress's per-test isolation model), so repeated runs don't leak state.
