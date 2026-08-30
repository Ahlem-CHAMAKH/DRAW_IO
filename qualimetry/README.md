# qualimetry

A small web app that takes the parts of Cypress and Selenium that matter most
for day-to-day UI testing and puts them behind one workflow:

1. **Record** — a browser extension captures your clicks, typing, selections,
   checkboxes, key presses, and navigations on any site you're already
   browsing.
2. **Generate** — every scenario gets a readable
   [`@playwright/test`](https://playwright.dev/docs/writing-tests) spec file
   (auto-waiting, cross-browser).
3. **Save** — the scenario is POSTed straight to the qualimetry server and
   persisted in a SQLite database, grouped into a **workspace** per
   application (e.g. "Facebook", "Internal CRM") so each app's scenarios
   stay together.
4. **Automate** — replay a saved scenario from the web dashboard as many
   times as you want; each run is isolated in its own browser context, with
   a pass/fail report per attempt.

There's also a CLI (`src/cli.ts`) for recording/running scenarios as local
files without the extension or server — see [CLI usage](#cli-alternative-no-server)
below.

## Architecture

```
extension/     Chrome (MV3) extension — records page interactions, saves to the server
src/server/    Express API + SQLite (via node:sqlite) — scenarios, runs, extension zip
public/        Static web dashboard (install page + scenario list/run UI)
src/           Shared core: types, script generator, Playwright runner, CLI
data/          qualimetry.db (gitignored, created on first server run)
```

## Install & run the server

```bash
cd qualimetry
npm install         # also runs `playwright install chromium` via postinstall
npm run build
npm run server       # http://localhost:4300
```

If your npm blocks lifecycle scripts (you'll see an `allow-scripts` warning),
run `npm approve-scripts --allow-scripts-pending` first, then re-run
`npm install`. If `playwright install chromium` still can't reach the
network, run `npx playwright install chromium` manually afterwards —
required for the **run** step (headless replay), not for recording or saving
scenarios.

The server uses Node's built-in `node:sqlite` module, which is experimental
in Node 22 and needs the `--experimental-sqlite` flag — already wired into
the `server` and `dev:server` npm scripts, so you don't need to pass it
yourself. Requires Node ≥ 22.5.

Once running, open **http://localhost:4300** for install instructions and
**http://localhost:4300/scenarios.html** for the dashboard.

## Install the extension

1. Visit http://localhost:4300 and click **Download qualimetry-extension.zip**
   (or just point "Load unpacked" at the `extension/` folder directly if
   you're running from a checkout).
2. Unzip it.
3. Open `chrome://extensions`, enable **Developer mode**.
4. Click **Load unpacked**, select the unzipped `qualimetry-extension` folder.
5. Pin the extension to your toolbar.

## Record a scenario

Open the extension popup on the page you want to test:

- **Start recording** — captures clicks, typed values, selects, checkboxes,
  Enter/Escape/Tab key presses, and page navigations. Password fields are
  never captured — see [Security notes](#security-notes).
- **Stop & review** — freezes the capture; give it a **workspace** (the
  application it belongs to — free text, autocompleted from existing
  workspaces, created automatically if new), a scenario name, an optional
  description, and **Save**. It's saved to whichever server URL is set in
  the popup (defaults to `http://localhost:4300`).

Assertions aren't auto-recorded — there's no reliable DOM signal for "the
user meant to check this." Add `assertText`, `assertVisible`, or `assertUrl`
steps by hand via `PUT /api/scenarios/:id` (or the CLI's local-file flow)
after recording.

## Workspaces

Scenarios are grouped by **workspace** (one per application under test).
Every install starts with a default "Unsorted" workspace. On the dashboard,
use the selector at the top of the sidebar to switch workspaces, create a
new one (**+**), or delete one (**×** — this also deletes every scenario in
it). The extension resolves or creates a workspace by name on save, so you
never have to leave the page you're recording to set one up.

## Run scenarios

On the **Scenarios** dashboard: pick a workspace, select a scenario, view
its captured steps or generated Playwright script, set a repeat count, and
click **Run**. Each run launches a real (headless) Chromium browser,
replays the scenario the requested number of times — one isolated browser
context per attempt — and stores a pass/fail report you can revisit under
**Run history**.

## API

| Method | Path                             | Purpose                              |
| ------ | -------------------------------- | ------------------------------------- |
| GET    | `/api/apps`                      | List workspaces (with scenario counts) |
| POST   | `/api/apps`                      | Create a workspace (`{ name, description? }`) |
| GET    | `/api/apps/:id`                  | Get one (by id or slug)               |
| PUT    | `/api/apps/:id`                  | Rename/update                         |
| DELETE | `/api/apps/:id`                  | Delete (cascades to its scenarios + runs) |
| GET    | `/api/scenarios`                 | List scenarios (optionally `?appId=`) |
| POST   | `/api/scenarios`                 | Create a scenario; needs `appId` **or** `appName` (used by extension — resolves-or-creates the workspace) |
| GET    | `/api/scenarios/:id`             | Get one (by id or slug)               |
| PUT    | `/api/scenarios/:id`             | Update appId/name/description/baseUrl/steps |
| DELETE | `/api/scenarios/:id`             | Delete                                |
| GET    | `/api/scenarios/:id/spec`        | Generated Playwright spec (text)      |
| POST   | `/api/scenarios/:id/run`         | Replay (`{ repeat, headed, timeoutMs, stopOnFailure }`) |
| GET    | `/api/scenarios/:id/runs`        | Run history                           |
| GET    | `/api/scenarios/:id/runs/:runId` | One run's full report                 |
| GET    | `/api/extension/download`        | Zipped extension folder               |

## CLI (alternative, no server)

For local-only use without the extension/server/DB, the original CLI still
works against files under `scenarios/`:

```bash
node dist/cli.js record "my flow" https://example.com   # interactive, needs a display
node dist/cli.js list
node dist/cli.js run "my flow" --repeat 20
node dist/cli.js generate "my flow"
```

See `--help` on any command for options.

## Security notes

- **Password fields are redacted at capture time.** The recorder never
  stores the literal text typed into an `<input type="password">` — it
  saves an empty value with a `redacted` flag. The generated script reads
  `process.env.QUALIMETRY_SECRET` instead (also honored by the runner on
  replay), so a login scenario can still run without the real credential
  ever touching the database, a scenario file, or a generated script.
- The dashboard escapes all scenario-supplied text before rendering it, so
  a scenario name/description containing HTML can't inject into the page.

## Design notes

- **Engine**: [Playwright](https://playwright.dev/), for Cypress-style
  auto-waiting locators plus Selenium-style multi-browser automation.
- **Selectors**: prefers `id`, then `data-testid`/`data-test`/`data-cy`/`data-qa`,
  then `name`, then a short structural CSS path.
- **Isolation**: every replay attempt gets its own browser context (matching
  Cypress's per-test isolation model).
- **No auth yet**: the server is single-tenant with permissive CORS, meant
  for local/trusted-network use. Add auth before exposing it publicly.
