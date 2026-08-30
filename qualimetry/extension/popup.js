const views = {
  idle: document.getElementById("idleView"),
  recording: document.getElementById("recordingView"),
  save: document.getElementById("saveView"),
};

const serverUrlInput = document.getElementById("serverUrl");
const idleStatus = document.getElementById("idleStatus");
const stepCountEl = document.getElementById("stepCount");
const saveSummary = document.getElementById("saveSummary");
const appNameInput = document.getElementById("appName");
const appListEl = document.getElementById("appList");
const scenarioNameInput = document.getElementById("scenarioName");
const scenarioDescriptionInput = document.getElementById("scenarioDescription");
const inputsSection = document.getElementById("inputsSection");
const inputsList = document.getElementById("inputsList");
const saveError = document.getElementById("saveError");

let currentBaseUrl = "";
let currentSteps = [];

function showView(name) {
  for (const key of Object.keys(views)) {
    views[key].hidden = key !== name;
  }
}

function sendToBackground(message) {
  return new Promise((resolve) => chrome.runtime.sendMessage(message, resolve));
}

async function loadServerUrl() {
  const stored = await chrome.storage.local.get("serverUrl");
  if (stored.serverUrl) serverUrlInput.value = stored.serverUrl;
}

serverUrlInput.addEventListener("change", () => {
  chrome.storage.local.set({ serverUrl: serverUrlInput.value.trim() });
});

async function refresh() {
  const state = await sendToBackground({ type: "GET_STEPS" });
  if (!state) return;
  currentBaseUrl = state.baseUrl || "";
  currentSteps = state.steps || [];

  if (state.recording) {
    stepCountEl.textContent = String(currentSteps.length);
    showView("recording");
  } else if (currentSteps.length > 0) {
    saveSummary.textContent = `${currentSteps.length} step(s) captured from ${currentBaseUrl}. Give it a name to save.`;
    showView("save");
    await prepareSaveView();
    renderInputsSection();
  } else {
    idleStatus.textContent = "Not recording.";
    showView("idle");
  }
}

async function prepareSaveView() {
  if (!appNameInput.value) {
    const stored = await chrome.storage.local.get("lastAppName");
    if (stored.lastAppName) appNameInput.value = stored.lastAppName;
  }

  const serverUrl = serverUrlInput.value.trim().replace(/\/+$/, "");
  try {
    const res = await fetch(`${serverUrl}/api/apps`);
    if (!res.ok) return;
    const apps = await res.json();
    appListEl.innerHTML = apps.map((a) => `<option value="${a.name.replace(/"/g, "&quot;")}"></option>`).join("");
  } catch {
    // Server unreachable — the datalist just stays empty; free text still works.
  }
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[c]);
}

function suggestVariableName(step, usedNames) {
  const base =
    (step.selectorLabel || step.selector || "value")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "")
      .slice(0, 24) || "value";
  let candidate = base;
  let n = 2;
  while (usedNames.has(candidate)) candidate = `${base}_${n++}`;
  usedNames.add(candidate);
  return candidate;
}

// Lets the user flag any recorded fill/select value as a named runtime
// variable instead of a fixed literal — not specific to any one site or
// field. Password fields are already excluded here since content.js never
// captures their real value in the first place (see isSensitiveField).
function renderInputsSection() {
  const rows = currentSteps
    .map((step, i) => ({ step, i }))
    .filter(({ step }) => (step.type === "fill" || step.type === "select") && !step.redacted);

  if (rows.length === 0) {
    inputsSection.hidden = true;
    inputsList.innerHTML = "";
    return;
  }

  const usedNames = new Set();
  inputsSection.hidden = false;
  inputsList.innerHTML = rows
    .map(({ step, i }) => {
      const label = step.selectorLabel || step.selector || "field";
      const suggested = suggestVariableName(step, usedNames);
      return `
        <div class="input-row" data-step-index="${i}">
          <div class="input-row-label">${escapeHtml(label)}: "${escapeHtml(step.value || "")}"</div>
          <label class="input-row-check">
            <input type="checkbox" class="param-toggle" />
            <span>Make this a variable</span>
          </label>
          <div class="param-fields" hidden>
            <input type="text" class="param-name" placeholder="variable name" value="${escapeHtml(suggested)}" />
            <label class="param-sensitive-label">
              <input type="checkbox" class="param-sensitive" /> Sensitive (mask value)
            </label>
          </div>
        </div>`;
    })
    .join("");

  inputsList.querySelectorAll(".param-toggle").forEach((cb) => {
    cb.addEventListener("change", () => {
      cb.closest(".input-row").querySelector(".param-fields").hidden = !cb.checked;
    });
  });
}

// Applies any "Make this a variable" choices to currentSteps before saving —
// once parameterized, the literal typed value is cleared and never sent to
// the server at all.
function applyParameterization() {
  inputsList.querySelectorAll(".input-row").forEach((row) => {
    const toggle = row.querySelector(".param-toggle");
    if (!toggle.checked) return;
    const name = row.querySelector(".param-name").value.trim();
    if (!name) return;
    const step = currentSteps[Number(row.dataset.stepIndex)];
    if (!step) return;
    step.variableName = name;
    step.sensitive = row.querySelector(".param-sensitive").checked;
    step.value = "";
  });
}

document.getElementById("startBtn").addEventListener("click", async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab || !tab.url) {
    idleStatus.textContent = "Couldn't read the active tab's URL.";
    return;
  }
  await sendToBackground({ type: "START_RECORDING", url: tab.url });
  await refresh();
});

document.getElementById("stopBtn").addEventListener("click", async () => {
  await sendToBackground({ type: "STOP_RECORDING" });
  await refresh();
});

document.getElementById("discardBtn").addEventListener("click", async () => {
  await sendToBackground({ type: "DISCARD_RECORDING" });
  await refresh();
});

document.getElementById("cancelSaveBtn").addEventListener("click", async () => {
  await sendToBackground({ type: "DISCARD_RECORDING" });
  await refresh();
});

document.getElementById("dashboardBtn").addEventListener("click", () => {
  chrome.tabs.create({ url: serverUrlInput.value.trim() });
});

document.getElementById("saveBtn").addEventListener("click", async () => {
  const name = scenarioNameInput.value.trim();
  const appName = appNameInput.value.trim();
  saveError.hidden = true;
  if (!appName) {
    saveError.textContent = "Workspace (application) name is required.";
    saveError.hidden = false;
    return;
  }
  if (!name) {
    saveError.textContent = "Scenario name is required.";
    saveError.hidden = false;
    return;
  }

  applyParameterization();

  const serverUrl = serverUrlInput.value.trim().replace(/\/+$/, "");
  try {
    const res = await fetch(`${serverUrl}/api/scenarios`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        appName,
        name,
        description: scenarioDescriptionInput.value.trim() || undefined,
        baseUrl: currentBaseUrl,
        steps: currentSteps,
      }),
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || `Server responded ${res.status}`);
    }
    await chrome.storage.local.set({ lastAppName: appName });
    await sendToBackground({ type: "DISCARD_RECORDING" });
    scenarioNameInput.value = "";
    scenarioDescriptionInput.value = "";
    await refresh();
  } catch (err) {
    saveError.textContent = `Couldn't save: ${err.message}. Is the qualimetry server running at ${serverUrl}?`;
    saveError.hidden = false;
  }
});

loadServerUrl().then(refresh);
