// Background service worker: the single source of truth for whether a
// recording is in progress and what steps have been captured so far.
// Popup and content scripts are stateless and always ask this worker.

let recording = false;
let steps = [];
let baseUrl = "";
let nextIndex = 0;

function pushStep(raw, url) {
  steps.push({
    index: nextIndex++,
    type: raw.type,
    selector: raw.selector,
    selectorLabel: raw.selectorLabel,
    value: raw.value,
    redacted: raw.redacted,
    variableName: raw.variableName,
    sensitive: raw.sensitive,
    url,
    timestamp: Date.now(),
  });
}

function broadcastRecordingState() {
  chrome.tabs.query({}, (tabs) => {
    for (const tab of tabs) {
      if (tab.id === undefined) continue;
      chrome.tabs.sendMessage(tab.id, { type: "SET_RECORDING", value: recording }, () => {
        void chrome.runtime.lastError; // tabs without our content script (chrome://, etc.)
      });
    }
  });
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  switch (message.type) {
    case "GET_RECORDING_STATE":
      sendResponse({ recording, stepCount: steps.length });
      return true;

    case "STEP":
      if (recording) pushStep(message.step);
      sendResponse({ ok: true });
      return true;

    case "START_RECORDING":
      recording = true;
      steps = [];
      nextIndex = 0;
      baseUrl = message.url;
      pushStep({ type: "goto" }, message.url);
      broadcastRecordingState();
      sendResponse({ ok: true });
      return true;

    case "STOP_RECORDING":
      recording = false;
      broadcastRecordingState();
      sendResponse({ steps, baseUrl });
      return true;

    case "GET_STEPS":
      sendResponse({ steps, baseUrl, recording });
      return true;

    case "DISCARD_RECORDING":
      recording = false;
      steps = [];
      nextIndex = 0;
      baseUrl = "";
      broadcastRecordingState();
      sendResponse({ ok: true });
      return true;

    default:
      return false;
  }
});

chrome.webNavigation.onCommitted.addListener((details) => {
  if (!recording) return;
  if (details.frameId !== 0) return; // main frame only
  if (details.url === "about:blank") return;
  pushStep({ type: "goto" }, details.url);
});
