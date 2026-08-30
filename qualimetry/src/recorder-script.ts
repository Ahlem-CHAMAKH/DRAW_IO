/**
 * Runs inside the recorded page (via context.addInitScript). Must be self-contained —
 * no references to outer closures, only to the window.__qualimetryEmit binding that
 * record.ts installs via context.exposeBinding before this script is attached.
 */
export function installRecorder(): void {
  const w = window as unknown as { __qualimetryEmit: (step: Record<string, unknown>) => void };

  function getSelector(el: Element | null): string | null {
    if (!el || el.nodeType !== 1) return null;
    const anyEl = el as HTMLElement;
    if (anyEl.id) return "#" + CSS.escape(anyEl.id);

    const testAttrs = ["data-testid", "data-test", "data-cy", "data-qa"];
    for (const attr of testAttrs) {
      const v = el.getAttribute(attr);
      if (v) return `[${attr}="${v}"]`;
    }

    const name = el.getAttribute("name");
    if (name) return `${el.tagName.toLowerCase()}[name="${name}"]`;

    const parts: string[] = [];
    let node: Element | null = el;
    let depth = 0;
    while (node && node.nodeType === 1 && depth < 6) {
      let part = node.tagName.toLowerCase();
      if (node.classList.length) {
        part += "." + Array.from(node.classList).slice(0, 2).join(".");
      }
      const parent: Element | null = node.parentElement;
      if (parent) {
        const siblings = Array.from(parent.children).filter((c) => c.tagName === node!.tagName);
        if (siblings.length > 1) {
          const idx = siblings.indexOf(node) + 1;
          part += `:nth-of-type(${idx})`;
        }
      }
      parts.unshift(part);
      if (parent && (parent as HTMLElement).id) {
        parts.unshift("#" + CSS.escape((parent as HTMLElement).id));
        break;
      }
      node = parent;
      depth++;
    }
    return parts.join(" > ");
  }

  function label(el: Element): string {
    const anyEl = el as HTMLInputElement;
    const text =
      (el as HTMLElement).innerText ||
      anyEl.value ||
      el.getAttribute("aria-label") ||
      el.getAttribute("placeholder") ||
      "";
    return text.trim().slice(0, 40);
  }

  document.addEventListener(
    "click",
    (e) => {
      const target = e.target as Element | null;
      if (!target) return;
      const el =
        target.closest(
          'button, a, [role="button"], input[type=submit], input[type=button], input[type=checkbox], input[type=radio], label'
        ) || target;

      if (el.tagName === "INPUT") {
        const input = el as HTMLInputElement;
        if (input.type === "checkbox" || input.type === "radio") {
          w.__qualimetryEmit({
            type: input.checked ? "check" : "uncheck",
            selector: getSelector(el),
            selectorLabel: label(el),
          });
          return;
        }
      }

      w.__qualimetryEmit({ type: "click", selector: getSelector(el), selectorLabel: label(el) });
    },
    true
  );

  document.addEventListener(
    "change",
    (e) => {
      const el = e.target as Element | null;
      if (!el || !el.tagName) return;

      if (el.tagName === "SELECT") {
        const select = el as HTMLSelectElement;
        w.__qualimetryEmit({
          type: "select",
          selector: getSelector(el),
          value: select.value,
          selectorLabel: label(el),
        });
        return;
      }

      if (el.tagName === "INPUT") {
        const input = el as HTMLInputElement;
        if (input.type === "checkbox" || input.type === "radio") return; // handled on click
        w.__qualimetryEmit({
          type: "fill",
          selector: getSelector(el),
          value: input.value,
          selectorLabel: label(el),
        });
        return;
      }

      if (el.tagName === "TEXTAREA") {
        const textarea = el as HTMLTextAreaElement;
        w.__qualimetryEmit({
          type: "fill",
          selector: getSelector(el),
          value: textarea.value,
          selectorLabel: label(el),
        });
      }
    },
    true
  );

  document.addEventListener(
    "keydown",
    (e) => {
      if (e.key !== "Enter" && e.key !== "Escape" && e.key !== "Tab") return;
      const el = e.target as Element | null;
      if (!el) return;
      w.__qualimetryEmit({ type: "press", selector: getSelector(el), value: e.key, selectorLabel: label(el) });
    },
    true
  );
}
