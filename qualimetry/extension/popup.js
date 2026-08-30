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
