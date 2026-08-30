import path from "node:path";
import { fileURLToPath } from "node:url";
import express, { type Request, type Response } from "express";
import archiver from "archiver";
import {
  createApp as createWorkspace,
  createRun,
  createScenario,
  deleteApp as deleteWorkspace,
  deleteScenario,
  findOrCreateAppByName,
  getApp as getWorkspace,
  getRun,
  getScenario,
  listApps as listWorkspaces,
  listRuns,
  listScenarios,
  updateApp as updateWorkspace,
  updateScenario,
} from "./repository.js";
import { generateSpec } from "../generate.js";
import { checkSelector, runScenario } from "../runner.js";
import { REPORTS_DIR } from "../scenario-store.js";
import type { ScenarioStep } from "../types.js";

const PROJECT_ROOT = path.resolve(fileURLToPath(new URL("../..", import.meta.url)));
const PUBLIC_DIR = path.join(PROJECT_ROOT, "public");
const EXTENSION_DIR = path.join(PROJECT_ROOT, "extension");

export function createApp() {
  const app = express();
  app.use(express.json({ limit: "2mb" }));

  // Permissive CORS: this is a single-tenant local MVP with no auth, and the
  // extension's own host_permissions already govern what it may call.
  app.use((req: Request, res: Response, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
    res.header("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.sendStatus(204);
    next();
  });

  app.get("/api/apps", (_req, res) => {
    res.json(listWorkspaces());
  });

  app.post("/api/apps", (req: Request, res: Response) => {
    const { name, description } = req.body ?? {};
    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ error: "`name` is required" });
    }
    const workspace = createWorkspace({
      name,
      description: typeof description === "string" ? description : undefined,
    });
    res.status(201).json(workspace);
  });

  app.get("/api/apps/:id", (req: Request, res: Response) => {
    const workspace = getWorkspace(req.params.id);
    if (!workspace) return res.status(404).json({ error: "Workspace not found" });
    res.json(workspace);
  });

  app.put("/api/apps/:id", (req: Request, res: Response) => {
    const workspace = updateWorkspace(req.params.id, req.body ?? {});
    if (!workspace) return res.status(404).json({ error: "Workspace not found" });
    res.json(workspace);
  });

  app.delete("/api/apps/:id", (req: Request, res: Response) => {
    const ok = deleteWorkspace(req.params.id);
    if (!ok) return res.status(404).json({ error: "Workspace not found" });
    res.status(204).send();
  });

  app.get("/api/scenarios", (req: Request, res: Response) => {
    const appId = typeof req.query.appId === "string" ? req.query.appId : undefined;
    res.json(listScenarios(appId));
  });

  app.post("/api/scenarios", (req: Request, res: Response) => {
    const { name, description, baseUrl, steps, appId, appName } = req.body ?? {};
    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ error: "`name` is required" });
    }
    if (typeof baseUrl !== "string" || !baseUrl.trim()) {
      return res.status(400).json({ error: "`baseUrl` is required" });
    }
    if (!Array.isArray(steps)) {
      return res.status(400).json({ error: "`steps` must be an array" });
    }

    let resolvedAppId: string;
    if (typeof appId === "string" && appId.trim()) {
      const workspace = getWorkspace(appId);
      if (!workspace) return res.status(400).json({ error: `Workspace "${appId}" not found` });
      resolvedAppId = workspace.id;
    } else if (typeof appName === "string" && appName.trim()) {
      resolvedAppId = findOrCreateAppByName(appName).id;
    } else {
      return res.status(400).json({ error: "`appId` or `appName` is required" });
    }

    const scenario = createScenario({
      appId: resolvedAppId,
      name,
      description: typeof description === "string" ? description : undefined,
      baseUrl,
      steps: steps as ScenarioStep[],
    });
    res.status(201).json(scenario);
  });

  app.get("/api/scenarios/:id", (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });
    res.json(scenario);
  });

  app.get("/api/scenarios/:id/spec", (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });
    res.type("text/plain").send(generateSpec(scenario));
  });

  app.put("/api/scenarios/:id", (req: Request, res: Response) => {
    const scenario = updateScenario(req.params.id, req.body ?? {});
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });
    res.json(scenario);
  });

  app.delete("/api/scenarios/:id", (req: Request, res: Response) => {
    const ok = deleteScenario(req.params.id);
    if (!ok) return res.status(404).json({ error: "Scenario not found" });
    res.status(204).send();
  });

  app.post("/api/scenarios/:id/run", async (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });

    const { repeat, headed, timeoutMs, stopOnFailure, variables } = req.body ?? {};
    try {
      const report = await runScenario(scenario, {
        repeat: typeof repeat === "number" ? repeat : 1,
        headed: !!headed,
        timeoutMs: typeof timeoutMs === "number" ? timeoutMs : undefined,
        stopOnFailure: !!stopOnFailure,
        variables: variables && typeof variables === "object" ? variables : undefined,
      });
      const run = createRun(scenario.id, report);
      res.status(201).json(run);
    } catch (err) {
      res.status(500).json({ error: err instanceof Error ? err.message : String(err) });
    }
  });

  app.post("/api/scenarios/:id/check-selector", async (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });

    const { selector, url } = req.body ?? {};
    if (typeof selector !== "string" || !selector.trim()) {
      return res.status(400).json({ error: "`selector` is required" });
    }
    const targetUrl = typeof url === "string" && url.trim() ? url : scenario.baseUrl;

    try {
      const result = await checkSelector(targetUrl, selector);
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: err instanceof Error ? err.message : String(err) });
    }
  });

  app.get("/api/scenarios/:id/runs", (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });
    res.json(listRuns(scenario.id));
  });

  app.get("/api/scenarios/:id/runs/:runId", (req: Request, res: Response) => {
    const scenario = getScenario(req.params.id);
    if (!scenario) return res.status(404).json({ error: "Scenario not found" });
    const run = getRun(scenario.id, req.params.runId);
    if (!run) return res.status(404).json({ error: "Run not found" });
    res.json(run);
  });

  app.get("/api/extension/download", (_req: Request, res: Response) => {
    res.attachment("qualimetry-extension.zip");
    const archive = archiver("zip", { zlib: { level: 9 } });
    archive.on("error", (err) => res.status(500).end(String(err)));
    archive.pipe(res);
    archive.directory(EXTENSION_DIR, "qualimetry-extension");
    archive.finalize();
  });

  // Failure screenshots and per-attempt videos, served under paths relative
  // to REPORTS_DIR (e.g. /reports/my-scenario/attempt-1.webm).
  app.use("/reports", express.static(REPORTS_DIR));

  app.use(express.static(PUBLIC_DIR));

  return app;
}
