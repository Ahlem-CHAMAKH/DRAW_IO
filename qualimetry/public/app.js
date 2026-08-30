const listEl = document.getElementById("scenarioList");

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

function stepLine(step) {
  const parts = [step.type];
  if (step.selectorLabel) parts.push(`"${step.selectorLabel}"`);
  else if (step.selector) parts.push(step.selector);
  if (step.redacted) parts.push("= ●●●●●● (redacted)");
  else if (step.value) parts.push(`= "${step.value}"`);
  if (step.url) parts.push(step.url);
  return esc(parts.join(" "));
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

function card(scenario) {
  const wrapper = document.createElement("div");
  wrapper.className = "card";
  wrapper.innerHTML = `
    <div class="row" style="justify-content: space-between;">
      <div>
        <strong>${esc(scenario.name)}</strong>
        <div class="muted">${esc(scenario.baseUrl)} &middot; ${scenario.steps.length} step(s) &middot; updated ${esc(fmtDate(scenario.updatedAt))}</div>
        ${scenario.description ? `<div class="muted">${esc(scenario.description)}</div>` : ""}
      </div>
      <button class="danger" data-action="delete">Delete</button>
    </div>

    <div class="row" style="margin-top: 12px;">
      <button data-action="toggle-steps">View steps</button>
      <button data-action="toggle-spec">View script</button>
      <button data-action="toggle-runs">Run history</button>
    </div>

    <ul class="steps" data-role="steps" hidden></ul>
    <pre data-role="spec" hidden></pre>
    <div data-role="runs" hidden></div>

    <div class="row" style="margin-top: 12px;">
      <label class="muted">Repeat</label>
      <input type="number" min="1" value="1" data-role="repeat" />
      <button class="primary" data-action="run">Run</button>
      <span data-role="run-status" class="muted"></span>
    </div>
  `;

  wrapper.querySelector('[data-role="steps"]').innerHTML = scenario.steps
    .map((s) => `<li>${stepLine(s)}</li>`)
    .join("");

  wrapper.querySelector('[data-action="delete"]').addEventListener("click", async () => {
    if (!confirm(`Delete scenario "${scenario.name}"? This can't be undone.`)) return;
    await api(`/scenarios/${scenario.id}`, { method: "DELETE" });
    load();
  });

  wrapper.querySelector('[data-action="toggle-steps"]').addEventListener("click", () => {
    const el = wrapper.querySelector('[data-role="steps"]');
    el.hidden = !el.hidden;
  });

  wrapper.querySelector('[data-action="toggle-spec"]').addEventListener("click", async () => {
    const el = wrapper.querySelector('[data-role="spec"]');
    if (el.hidden && !el.textContent) {
      const res = await fetch(`/api/scenarios/${scenario.id}/spec`);
      el.textContent = await res.text();
    }
    el.hidden = !el.hidden;
  });

  wrapper.querySelector('[data-action="toggle-runs"]').addEventListener("click", async () => {
    const el = wrapper.querySelector('[data-role="runs"]');
    if (el.hidden) {
      const runs = await api(`/scenarios/${scenario.id}/runs`);
      el.innerHTML = runs.length
        ? runs
            .map(
              (r) => `
        <div class="row" style="justify-content: space-between; border-top: 1px solid var(--border); padding: 6px 0;">
          <span>${esc(fmtDate(r.startedAt))} &middot; ${r.requestedRepeats} attempt(s)</span>
          <span class="badge ${r.failed === 0 ? "ok" : "fail"}">${r.passed} passed / ${r.failed} failed</span>
        </div>`
            )
            .join("")
        : `<p class="muted">No runs yet.</p>`;
    }
    el.hidden = !el.hidden;
  });

  wrapper.querySelector('[data-action="run"]').addEventListener("click", async (e) => {
    const btn = e.currentTarget;
    const status = wrapper.querySelector('[data-role="run-status"]');
    const repeat = Number(wrapper.querySelector('[data-role="repeat"]').value) || 1;
    btn.disabled = true;
    status.textContent = `Running ${repeat} time(s)...`;
    try {
      const run = await api(`/scenarios/${scenario.id}/run`, {
        method: "POST",
        body: JSON.stringify({ repeat }),
      });
      status.textContent = `${run.passed} passed, ${run.failed} failed.`;
      const runsEl = wrapper.querySelector('[data-role="runs"]');
      runsEl.hidden = true; // force a refetch next time it's opened
      runsEl.innerHTML = "";
    } catch (err) {
      status.textContent = `Run failed: ${err.message}`;
    } finally {
      btn.disabled = false;
    }
  });

  return wrapper;
}

async function load() {
  listEl.innerHTML = `<p class="muted">Loading…</p>`;
  try {
    const scenarios = await api("/scenarios");
    listEl.innerHTML = "";
    if (scenarios.length === 0) {
      listEl.innerHTML = `<p class="empty">No scenarios yet. Record one with the extension, then refresh this page.</p>`;
      return;
    }
    for (const scenario of scenarios) {
      listEl.appendChild(card(scenario));
    }
  } catch (err) {
    listEl.innerHTML = `<p class="empty">Couldn't reach the qualimetry server: ${esc(err.message)}</p>`;
  }
}

load();
