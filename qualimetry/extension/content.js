// Injected into every page. Always listens, but only reports events to the
// background worker while a recording is active (state pushed from there).

let recording = false;

chrome.runtime.sendMessage({ type: "GET_RECORDING_STATE" }, (response) => {
  if (chrome.runtime.lastError) return;
  if (response) recording = !!response.recording;
});

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === "SET_RECORDING") {
    recording = !!message.value;
  }
});

function emit(step) {
  if (!recording) return;
  chrome.runtime.sendMessage({ type: "STEP", step }, () => {
    void chrome.runtime.lastError;
  });
}

function getSelector(el) {
  if (!el || el.nodeType !== 1) return null;
  if (el.id) return "#" + CSS.escape(el.id);

  const testAttrs = ["data-testid", "data-test", "data-cy", "data-qa"];
  for (const attr of testAttrs) {
    const v = el.getAttribute(attr);
    if (v) return `[${attr}="${v}"]`;
  }

  const name = el.getAttribute("name");
  if (name) return `${el.tagName.toLowerCase()}[name="${name}"]`;

  const parts = [];
  let node = el;
  let depth = 0;
  while (node && node.nodeType === 1 && depth < 6) {
    let part = node.tagName.toLowerCase();
    if (node.classList.length) {
      part += "." + Array.from(node.classList).slice(0, 2).join(".");
    }
    const parent = node.parentElement;
    if (parent) {
      const siblings = Array.from(parent.children).filter((c) => c.tagName === node.tagName);
      if (siblings.length > 1) {
        const idx = siblings.indexOf(node) + 1;
        part += `:nth-of-type(${idx})`;
      }
    }
    parts.unshift(part);
    if (parent && parent.id) {
      parts.unshift("#" + CSS.escape(parent.id));
      break;
    }
    node = parent;
    depth++;
  }
  return parts.join(" > ");
}

// type="password" is the strong signal, but some apps (custom "show
// password" toggles, non-native components) never literally set it, or only
// set it intermittently — so this also looks at autocomplete and common
// name/id/label hints as a fallback. Not certain, just a best-effort default
// the user can always override via the live per-field prompt below.
function isSensitiveField(el) {
  if (el.tagName !== "INPUT") return false;
  if (el.type === "password") return true;
  const auto = (el.autocomplete || el.getAttribute("autocomplete") || "").toLowerCase();
  if (auto.includes("password")) return true;
  const hints = [el.name, el.id, el.getAttribute("aria-label"), el.placeholder].filter(Boolean).join(" ").toLowerCase();
  return /pass(word)?/.test(hints);
}

function label(el) {
  if (isSensitiveField(el)) return "Password";
  const text = el.innerText || el.value || el.getAttribute("aria-label") || el.getAttribute("placeholder") || "";
  return text.trim().slice(0, 40);
}

function isEligibleField(el) {
  if (!el || !el.tagName) return false;
  if (el.tagName === "TEXTAREA" || el.tagName === "SELECT") return true;
  if (el.tagName === "INPUT") {
    const type = (el.type || "text").toLowerCase();
    return !["checkbox", "radio", "submit", "button", "hidden", "file", "image", "reset"].includes(type);
  }
  return false;
}

// ---- Live per-field prompt ----
// Shown the first time a field is focused during an active recording, so the
// user can decide right then whether to keep the typed value or turn it
// into a named runtime variable — instead of only reviewing after the fact.
// Rendered in a shadow root so the host page's CSS can't hide/override it
// (and ours can't leak into the page).

const fieldDecisions = new WeakMap(); // element -> "keep" | { variableName, sensitive }

let overlayHost = null;
let shadow = null;
let panel = null;

function ensureOverlay() {
  if (overlayHost) return;
  overlayHost = document.createElement("div");
  overlayHost.style.cssText = "all: initial; position: absolute; top: 0; left: 0; z-index: 2147483647;";
  document.documentElement.appendChild(overlayHost);
  shadow = overlayHost.attachShadow({ mode: "open" });

  const style = document.createElement("style");
  style.textContent = `
    .panel {
      position: fixed;
      width: 240px;
      background: #ffffff;
      border: 1px solid #ddd;
      border-radius: 10px;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.18);
      padding: 10px;
      font: 12px/1.4 -apple-system, "Segoe UI", Roboto, sans-serif;
      color: #1a1a1a;
    }
    .panel h4 { margin: 0 0 4px; font-size: 12px; }
    .panel p.hint { margin: 0 0 6px; color: #666; }
    .row { display: flex; gap: 6px; margin-top: 6px; }
    button {
      flex: 1;
      padding: 5px 6px;
      border-radius: 6px;
      border: 1px solid #ccc;
      background: #f6f6f6;
      cursor: pointer;
      font-size: 11.5px;
      font-family: inherit;
    }
    button.primary { background: #22c55e; border-color: #22c55e; color: #fff; font-weight: 600; }
    input[type="text"] {
      width: 100%;
      box-sizing: border-box;
      padding: 4px 6px;
      border: 1px solid #ccc;
      border-radius: 6px;
      margin-top: 6px;
      font-size: 12px;
      font-family: inherit;
    }
    label { display: flex; align-items: center; gap: 5px; margin-top: 6px; font-size: 11.5px; }
  `;
  panel = document.createElement("div");
  panel.className = "panel";
  panel.hidden = true;
  shadow.appendChild(style);
  shadow.appendChild(panel);
}

let activePromptEl = null;

function hidePanel() {
  if (panel) panel.hidden = true;
  activePromptEl = null;
}

function positionPanel(el) {
  const rect = el.getBoundingClientRect();
  const top = Math.max(8, Math.min(rect.bottom + 6, window.innerHeight - 170));
  const left = Math.max(8, Math.min(rect.left, window.innerWidth - 250));
  panel.style.top = `${top}px`;
  panel.style.left = `${left}px`;
}

function showFieldPrompt(el) {
  if (!recording) return;
  if (!isEligibleField(el)) return;
  if (fieldDecisions.has(el)) return; // already decided this session

  ensureOverlay();
  const likelySensitive = isSensitiveField(el);
  positionPanel(el);
  panel.hidden = false;
  activePromptEl = el;

  if (likelySensitive) {
    fieldDecisions.set(el, { variableName: "password", sensitive: true });
    panel.innerHTML = `
      <h4>Looks like a password</h4>
      <p class="hint">Its value won't be recorded. Wrong? Click below to record it as a normal value instead.</p>
      <div class="row">
        <button id="qm-ok" class="primary">OK</button>
        <button id="qm-notpw">Not a password</button>
      </div>
    `;
    shadow.getElementById("qm-ok").addEventListener("click", hidePanel);
    shadow.getElementById("qm-notpw").addEventListener("click", () => {
      fieldDecisions.set(el, "keep");
      hidePanel();
    });
    return;
  }

  panel.innerHTML = `
    <h4>Recording this input</h4>
    <p class="hint">Keep the typed value, or make it a variable you supply on each run?</p>
    <div class="row">
      <button id="qm-keep" class="primary">Keep value</button>
      <button id="qm-var">Make variable</button>
    </div>
    <div id="qm-varFields" hidden>
      <input id="qm-varName" type="text" placeholder="variable name" />
      <label><input id="qm-sensitive" type="checkbox" /> Sensitive (mask value)</label>
      <div class="row"><button id="qm-save" class="primary">Save</button></div>
    </div>
  `;
  shadow.getElementById("qm-keep").addEventListener("click", () => {
    fieldDecisions.set(el, "keep");
    hidePanel();
  });
  shadow.getElementById("qm-var").addEventListener("click", () => {
    shadow.getElementById("qm-varFields").hidden = false;
    shadow.getElementById("qm-varName").focus();
  });
  shadow.getElementById("qm-save").addEventListener("click", () => {
    const name = shadow.getElementById("qm-varName").value.trim();
    if (!name) return;
    const sensitive = shadow.getElementById("qm-sensitive").checked;
    fieldDecisions.set(el, { variableName: name, sensitive });
    hidePanel();
  });
}

document.addEventListener("focusin", (e) => showFieldPrompt(e.target), true);

// Dismiss on a click elsewhere — not on focusout, which would race clicking
// the panel's own buttons: mousedown shifts focus off the host field before
// the click event fires, so a focusout-based hide would close the panel out
// from under its own "Keep value"/"Make variable"/"Save" clicks.
document.addEventListener(
  "click",
  (e) => {
    if (!panel || panel.hidden) return;
    const path = typeof e.composedPath === "function" ? e.composedPath() : [];
    const clickedInsidePanel = path.includes(panel) || path.includes(overlayHost);
    const clickedActiveField = e.target === activePromptEl;
    if (!clickedInsidePanel && !clickedActiveField) hidePanel();
  },
  true
);

/** Builds the value/variableName/sensitive part of a fill/select step from the field's live decision (if any) or its literal value. */
function buildValuePayload(el) {
  const decision = fieldDecisions.get(el);
  if (decision && decision !== "keep") {
    return { variableName: decision.variableName, sensitive: decision.sensitive };
  }
  return { value: el.value };
}

document.addEventListener(
  "click",
  (e) => {
    const target = e.target;
    if (!target) return;
    const el =
      target.closest(
        'button, a, [role="button"], input[type=submit], input[type=button], input[type=checkbox], input[type=radio], label'
      ) || target;

    if (el.tagName === "INPUT" && (el.type === "checkbox" || el.type === "radio")) {
      emit({ type: el.checked ? "check" : "uncheck", selector: getSelector(el), selectorLabel: label(el) });
      return;
    }

    emit({ type: "click", selector: getSelector(el), selectorLabel: label(el) });
  },
  true
);

document.addEventListener(
  "change",
  (e) => {
    const el = e.target;
    if (!el || !el.tagName) return;

    if (el.tagName === "SELECT") {
      emit({ type: "select", selector: getSelector(el), selectorLabel: label(el), ...buildValuePayload(el) });
      return;
    }

    if (el.tagName === "INPUT") {
      if (el.type === "checkbox" || el.type === "radio") return; // handled on click
      emit({ type: "fill", selector: getSelector(el), selectorLabel: label(el), ...buildValuePayload(el) });
      return;
    }

    if (el.tagName === "TEXTAREA") {
      emit({ type: "fill", selector: getSelector(el), selectorLabel: label(el), ...buildValuePayload(el) });
    }
  },
  true
);

document.addEventListener(
  "keydown",
  (e) => {
    if (e.key !== "Enter" && e.key !== "Escape" && e.key !== "Tab") return;
    const el = e.target;
    if (!el) return;
    emit({ type: "press", selector: getSelector(el), value: e.key, selectorLabel: label(el) });
  },
  true
);
