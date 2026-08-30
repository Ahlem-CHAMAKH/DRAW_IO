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

function label(el) {
  const text = el.innerText || el.value || el.getAttribute("aria-label") || el.getAttribute("placeholder") || "";
  return text.trim().slice(0, 40);
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
      emit({ type: "select", selector: getSelector(el), value: el.value, selectorLabel: label(el) });
      return;
    }

    if (el.tagName === "INPUT") {
      if (el.type === "checkbox" || el.type === "radio") return; // handled on click
      emit({ type: "fill", selector: getSelector(el), value: el.value, selectorLabel: label(el) });
      return;
    }

    if (el.tagName === "TEXTAREA") {
      emit({ type: "fill", selector: getSelector(el), value: el.value, selectorLabel: label(el) });
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
