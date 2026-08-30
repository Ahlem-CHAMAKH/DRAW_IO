const listEl = document.getElementById("scenarioList");
const detailEl = document.getElementById("detail");
const searchEl = document.getElementById("search");
const toastEl = document.getElementById("toast");

const appSelect = document.getElementById("appSelect");
const newAppBtn = document.getElementById("newAppBtn");
const deleteAppBtn = document.getElementById("deleteAppBtn");

const deleteModal = document.getElementById("deleteModal");
const deleteModalTitle = document.getElementById("deleteModalTitle");
const deleteModalText = document.getElementById("deleteModalText");
const deleteCancel = document.getElementById("deleteCancel");
const deleteConfirm = document.getElementById("deleteConfirm");

const newAppModal = document.getElementById("newAppModal");
const newAppName = document.getElementById("newAppName");
const newAppCancel = document.getElementById("newAppCancel");
const newAppConfirm = document.getElementById("newAppConfirm");

let apps = [];
let selectedAppId = null;
let scenarios = [];
let selectedScenarioId = null;
let pendingDelete = null; // { kind: "scenario" | "app", id, name }
let toastTimer = null;

const STEP_META = {
  goto: { badge: "GO", group: "nav", verb: "Go to" },
  click: { badge: "CL", group: "action", verb: "Click" },
  dblclick: { badge: "2×", group: "action", verb: "Double-click" },
  fill: { badge: "FI", group: "input", verb: "Type into" },
  check: { badge: "CH", group: "input", verb: "Check" },
  uncheck: { badge: "UC", group: "input", verb: "Uncheck" },
  select: { badge: "SE", group: "input", verb: "Select in" },
  press: { badge: "PR", group: "action", verb: "Press" },
  assertText: { badge: "AT", group: "assert", verb: "Assert text of" },
  assertVisible: { badge: "AV", group: "assert", verb: "Assert visible" },
  assertUrl: { badge: "AU", group: "assert", verb: "Assert URL is" },
};

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));
}

function fmtDate(iso) {
  try {
    return new Date(iso).toLocaleString();
  } catch {
    return iso;
  }
}

function hostOf(url) {
  try {
    return new URL(url).host;
  } catch {
    return url;
  }
}

function showToast(message, isError) {
  clearTimeout(toastTimer);
  toastEl.textContent = message;
  toastEl.classList.toggle("error", !!isError);
  toastEl.hidden = false;
  toastTimer = setTimeout(() => (toastEl.hidden = true), 4000);
}

function rememberAppId(id) {
  try {
    localStorage.setItem("qualimetry.selectedAppId", id);
  } catch {
    // ignore (private browsing, storage disabled, etc.)
  }
}

function recallAppId() {
  try {
    return localStorage.getItem("qualimetry.selectedAppId");
  } catch {
    return null;
  }
}

async function api(path, options) {
  const res = await fetch(`/api${path}`, {
    headers: options?.body ? { "Content-Type": "application/json" } : undefined,
    ...options,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `Request failed (${res.status})`);
  }
  if (res.status === 204) return null;
  return res.json();
}

// ---- Workspaces ----

function renderAppSelect() {
  appSelect.innerHTML = apps
    .map((a) => `<option value="${esc(a.id)}">${esc(a.name)} (${a.scenarioCount})</option>`)
    .join("");
  appSelect.value = selectedAppId || "";
  deleteAppBtn.disabled = apps.length === 0;
}

async function loadApps() {
  apps = await api("/apps");
  if (apps.length === 0) {
    selectedAppId = null;
    renderAppSelect();
    return;
  }
  const recalled = recallAppId();
  selectedAppId = apps.some((a) => a.id === selectedAppId)
    ? selectedAppId
    : apps.some((a) => a.id === recalled)
      ? recalled
      : apps[0].id;
  renderAppSelect();
}

appSelect.addEventListener("change", async () => {
  selectedAppId = appSelect.value;
  rememberAppId(selectedAppId);
  selectedScenarioId = null;
  await loadScenarios();
});

newAppBtn.addEventListener("click", () => {
  newAppName.value = "";
  newAppModal.hidden = false;
  newAppName.focus();
});

newAppCancel.addEventListener("click", () => (newAppModal.hidden = true));

newAppConfirm.addEventListener("click", async () => {
  const name = newAppName.value.trim();
  if (!name) return;
  try {
    const created = await api("/apps", { method: "POST", body: JSON.stringify({ name }) });
    newAppModal.hidden = true;
    await loadApps();
    selectedAppId = created.id;
    rememberAppId(selectedAppId);
    renderAppSelect();
    await loadScenarios();
  } catch (err) {
    showToast(`Couldn't create workspace: ${err.message}`, true);
  }
});

deleteAppBtn.addEventListener("click", () => {
  const current = apps.find((a) => a.id === selectedAppId);
  if (!current) return;
  pendingDelete = { kind: "app", id: current.id, name: current.name };
  deleteModalTitle.textContent = "Delete workspace?";
  deleteModalText.textContent = `Delete "${current.name}" and all ${current.scenarioCount} scenario(s) in it? This can't be undone.`;
  deleteModal.hidden = false;
});

// ---- Scenarios ----

function renderSidebar() {
  const query = searchEl.value.trim().toLowerCase();
  const filtered = query ? scenarios.filter((s) => s.name.toLowerCase().includes(query)) : scenarios;

  if (scenarios.length === 0) {
    listEl.innerHTML = `<p class="empty">No scenarios in this workspace yet.<br />Record one with the extension, then refresh.</p>`;
    return;
  }
  if (filtered.length === 0) {
    listEl.innerHTML = `<p class="empty">No matches for "${esc(searchEl.value)}".</p>`;
    return;
  }

  listEl.innerHTML = filtered
    .map(
      (s) => `
    <button class="scenario-item ${s.id === selectedScenarioId ? "active" : ""}" data-id="${esc(s.id)}">
      <div class="scenario-item-name">${esc(s.name)}</div>
      <div class="scenario-item-meta">${esc(hostOf(s.baseUrl))} · ${s.steps.length} step${s.steps.length === 1 ? "" : "s"}</div>
    </button>`
    )
    .join("");

  listEl.querySelectorAll(".scenario-item").forEach((btn) => {
    btn.addEventListener("click", () => selectScenario(btn.dataset.id));
  });
}

function stepRow(step) {
  const meta = STEP_META[step.type] || { badge: "?", group: "action", verb: step.type };
  const targetText = step.selectorLabel || step.selector || "";
  let valueHtml = "";
  if (step.redacted) {
    valueHtml = `<span class="step-value redacted">redacted</span>`;
  } else if (step.value) {
    valueHtml = `<span class="step-value">"${esc(step.value)}"</span>`;
  }
  const urlHtml = step.url ? `<span class="step-url">${esc(step.url)}</span>` : "";

  return `
    <li class="step-item">
      <span class="step-badge ${meta.group}">${meta.badge}</span>
      <span>
        ${esc(meta.verb)}${targetText ? ` <span class="step-target">${esc(targetText)}</span>` : ""}
        ${valueHtml ? " " + valueHtml : ""}
        ${urlHtml}
      </span>
    </li>`;
}

function switchTab(root, name) {
  root.querySelectorAll(".tab-btn").forEach((b) => b.classList.toggle("active", b.dataset.tab === name));
  root.querySelectorAll(".tab-panel").forEach((p) => p.classList.toggle("active", p.dataset.tab === name));
}

async function loadSpecInto(scenario, panel) {
  if (panel.dataset.loaded) return;
  const res = await fetch(`/api/scenarios/${scenario.id}/spec`);
  const text = await res.text();
  panel.querySelector("pre").textContent = text;
  panel.dataset.loaded = "1";
}

async function loadRunsInto(scenario, panel) {
  const runs = await api(`/scenarios/${scenario.id}/runs`);
  panel.innerHTML = runs.length
    ? `<ul class="run-list">${runs
        .map(
          (r) => `
      <li>
        <span>${esc(fmtDate(r.startedAt))} · ${r.requestedRepeats} attempt${r.requestedRepeats === 1 ? "" : "s"}</span>
        <span class="badge ${r.failed === 0 ? "ok" : "fail"}">${r.passed} passed / ${r.failed} failed</span>
      </li>`
        )
        .join("")}</ul>`
    : `<p class="empty">No runs yet. Use the Run button above.</p>`;
}

function renderDetail(scenario) {
  detailEl.innerHTML = `
    <div class="detail-header">
      <div>
        <h2 class="detail-title">${esc(scenario.name)}</h2>
        <div class="detail-sub">
          <span>${esc(scenario.baseUrl)}</span>
          <span class="faint">·</span>
          <span>updated ${esc(fmtDate(scenario.updatedAt))}</span>
        </div>
        ${scenario.description ? `<p class="detail-description">${esc(scenario.description)}</p>` : ""}
      </div>
      <button class="danger" data-action="delete">Delete</button>
    </div>

    <div class="run-bar">
      <button class="primary" data-action="run">▶ Run</button>
      <label for="repeatInput">Repeat</label>
      <input id="repeatInput" type="number" min="1" value="1" />
      <span class="run-status" data-role="run-status"></span>
    </div>

    <div class="tabs">
      <button class="tab-btn active" data-tab="steps">Steps (${scenario.steps.length})</button>
      <button class="tab-btn" data-tab="script">Script</button>
      <button class="tab-btn" data-tab="runs">Run history</button>
    </div>

    <div class="tab-panel active" data-tab="steps">
      <ul class="step-list">${scenario.steps.map(stepRow).join("") || `<p class="empty">No steps recorded.</p>`}</ul>
    </div>

    <div class="tab-panel" data-tab="script">
      <div class="code-block">
        <button class="ghost copy-btn" data-action="copy-script">Copy</button>
        <pre>Loading…</pre>
      </div>
    </div>

    <div class="tab-panel" data-tab="runs">
      <p class="muted">Loading…</p>
    </div>
  `;

  detailEl.querySelectorAll(".tab-btn").forEach((btn) => {
    btn.addEventListener("click", async () => {
      switchTab(detailEl, btn.dataset.tab);
      if (btn.dataset.tab === "script") {
        await loadSpecInto(scenario, detailEl.querySelector('.tab-panel[data-tab="script"]'));
      } else if (btn.dataset.tab === "runs") {
        await loadRunsInto(scenario, detailEl.querySelector('.tab-panel[data-tab="runs"]'));
      }
    });
  });

  detailEl.querySelector('[data-action="copy-script"]').addEventListener("click", async (e) => {
    const pre = detailEl.querySelector('.tab-panel[data-tab="script"] pre');
    try {
      await navigator.clipboard.writeText(pre.textContent);
      e.currentTarget.textContent = "Copied!";
      setTimeout(() => (e.currentTarget.textContent = "Copy"), 1500);
    } catch {
      showToast("Couldn't copy to clipboard.", true);
    }
  });

  detailEl.querySelector('[data-action="delete"]').addEventListener("click", () => {
    pendingDelete = { kind: "scenario", id: scenario.id, name: scenario.name };
    deleteModalTitle.textContent = "Delete scenario?";
    deleteModalText.textContent = `Delete "${scenario.name}"? This can't be undone.`;
    deleteModal.hidden = false;
  });

  detailEl.querySelector('[data-action="run"]').addEventListener("click", async (e) => {
    const btn = e.currentTarget;
    const status = detailEl.querySelector('[data-role="run-status"]');
    const repeat = Number(detailEl.querySelector("#repeatInput").value) || 1;
    btn.disabled = true;
    status.className = "run-status";
    status.textContent = `Running ${repeat} time(s)…`;
    try {
      const run = await api(`/scenarios/${scenario.id}/run`, {
        method: "POST",
        body: JSON.stringify({ repeat }),
      });
      status.className = `run-status ${run.failed === 0 ? "ok" : "fail"}`;
      status.textContent = `${run.passed} passed, ${run.failed} failed.`;
      const runsPanel = detailEl.querySelector('.tab-panel[data-tab="runs"]');
      if (runsPanel.classList.contains("active")) await loadRunsInto(scenario, runsPanel);
    } catch (err) {
      status.className = "run-status fail";
      status.textContent = `Run failed: ${err.message}`;
    } finally {
      btn.disabled = false;
    }
  });
}

function selectScenario(id) {
  selectedScenarioId = id;
  renderSidebar();
  const scenario = scenarios.find((s) => s.id === id);
  if (scenario) renderDetail(scenario);
}

searchEl.addEventListener("input", renderSidebar);

// ---- Delete modal (handles both scenarios and workspaces) ----

deleteCancel.addEventListener("click", () => {
  deleteModal.hidden = true;
  pendingDelete = null;
});

deleteConfirm.addEventListener("click", async () => {
  if (!pendingDelete) return;
  const { kind, id } = pendingDelete;
  deleteModal.hidden = true;
  pendingDelete = null;

  try {
    if (kind === "scenario") {
      await api(`/scenarios/${id}`, { method: "DELETE" });
      showToast("Scenario deleted.");
      if (selectedScenarioId === id) selectedScenarioId = null;
      await loadScenarios();
    } else {
      await api(`/apps/${id}`, { method: "DELETE" });
      showToast("Workspace deleted.");
      if (selectedAppId === id) selectedAppId = null;
      await loadApps();
      await loadScenarios();
    }
  } catch (err) {
    showToast(`Couldn't delete: ${err.message}`, true);
  }
});

// ---- Bootstrapping ----

async function loadScenarios() {
  if (!selectedAppId) {
    scenarios = [];
    listEl.innerHTML = `<p class="empty">No workspace selected.</p>`;
    detailEl.innerHTML = `<div class="detail-empty">Create a workspace to get started.</div>`;
    return;
  }

  scenarios = await api(`/scenarios?appId=${encodeURIComponent(selectedAppId)}`);

  if (scenarios.length === 0) {
    selectedScenarioId = null;
    renderSidebar();
    detailEl.innerHTML = `<div class="detail-empty">No scenarios in this workspace yet.<br />Record one with the extension, then refresh.</div>`;
    return;
  }

  if (!selectedScenarioId || !scenarios.some((s) => s.id === selectedScenarioId)) {
    selectedScenarioId = scenarios[0].id;
  }

  renderSidebar();
  const scenario = scenarios.find((s) => s.id === selectedScenarioId);
  if (scenario) renderDetail(scenario);
}

async function load() {
  try {
    await loadApps();
  } catch (err) {
    detailEl.innerHTML = `<div class="detail-empty">Couldn't reach the qualimetry server: ${esc(err.message)}</div>`;
    listEl.innerHTML = "";
    return;
  }

  if (apps.length === 0) {
    detailEl.innerHTML = `<div class="detail-empty">No workspaces yet. Click "+" to create one, or record a scenario with the extension — it creates its workspace automatically.</div>`;
    listEl.innerHTML = "";
    return;
  }

  await loadScenarios();
}

load();
