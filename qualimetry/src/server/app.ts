import path from "node:path";
import { fileURLToPath } from "node:url";
import express, { type Request, type Response } from "express";
import archiver from "archiver";
import {
  createRun,
  createScenario,
  deleteScenario,
  getRun,
  getScenario,
  listRuns,
  listScenarios,
  updateScenario,
} from "./repository.js";
import { generateSpec } from "../generate.js";
import { runScenario } from "../runner.js";
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

  app.get("/api/scenarios", (_req, res) => {
    res.json(listScenarios());
  });

  app.post("/api/scenarios", (req: Request, res: Response) => {
    const { name, description, baseUrl, steps } = req.body ?? {};
    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ error: "`name` is required" });
    }
    if (typeof baseUrl !== "string" || !baseUrl.trim()) {
      return res.status(400).json({ error: "`baseUrl` is required" });
    }
    if (!Array.isArray(steps)) {
      return res.status(400).json({ error: "`steps` must be an array" });
    }
    const scenario = createScenario({
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

    const { repeat, headed, timeoutMs, stopOnFailure } = req.body ?? {};
    try {
      const report = await runScenario(scenario, {
        repeat: typeof repeat === "number" ? repeat : 1,
        headed: !!headed,
        timeoutMs: typeof timeoutMs === "number" ? timeoutMs : undefined,
        stopOnFailure: !!stopOnFailure,
      });
      const run = createRun(scenario.id, report);
      res.status(201).json(run);
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

  app.use(express.static(PUBLIC_DIR));

  return app;
}
