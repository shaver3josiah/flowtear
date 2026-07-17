// Uncorked Release Cockpit — a local, AI-free maintenance and release panel.
// Run `npm run cockpit`, open http://localhost:4499, and every routine chore
// (dependency refresh, tests, parity, tag-and-push releases that trigger the
// TestFlight pipeline) is a button. Zero npm dependencies: Node stdlib only,
// shelling out to the same git / npm / gh commands you'd type yourself.
// Binds to 127.0.0.1 only — this panel is for the person at this keyboard.

import { createServer } from "node:http";
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const PORT = 4499;

// One chore at a time — two overlapping git operations is how repos get hurt.
let busy = null;

const run = (cmd, args, timeout = 300000) =>
  new Promise((resolve) => {
    execFile(cmd, args, { cwd: ROOT, timeout, shell: true, windowsHide: true },
      (err, stdout, stderr) => resolve({
        ok: !err,
        out: [stdout, stderr].filter(Boolean).join("\n").trim(),
        code: err?.code ?? 0,
      }));
  });

// ---- chores ------------------------------------------------------------

async function status() {
  const [branch, changes, tag, behind] = await Promise.all([
    run("git", ["branch", "--show-current"]),
    run("git", ["status", "--short"]),
    run("git", ["describe", "--tags", "--abbrev=0"]),
    run("git", ["rev-list", "--count", "@{u}..HEAD"]),
  ]);
  const runs = await run("gh", ["run", "list", "--limit", "6", "--json",
    "displayTitle,workflowName,conclusion,status,headBranch,createdAt"]);
  let ci = [];
  try { ci = JSON.parse(runs.out); } catch { /* gh missing or offline */ }
  return {
    branch: branch.out, dirty: changes.out, lastTag: tag.out,
    unpushed: Number(behind.out) || 0, ci,
  };
}

async function outdated() {
  // npm exits 1 when anything is outdated — that's data, not failure.
  const r = await run("npm", ["outdated", "--json"]);
  let deps = {};
  try { deps = JSON.parse(r.out || "{}"); } catch { /* no output = up to date */ }
  return { deps };
}

async function updateDep(name, target) {
  // Semver-safe refresh by default; an explicit @latest is the owner's call.
  const spec = target === "latest" ? `${name}@latest` : name;
  const arg = target === "latest" ? ["install", spec] : ["update", name];
  return { install: await run("npm", arg), then: await outdated() };
}

async function gates() {
  const tests = await run("npm", ["test"]);
  const parity = await run("npm", ["run", "check:parity"]);
  return { tests, parity, green: tests.ok && parity.ok };
}

async function release(version, message) {
  if (!/^v\d+\.\d+\.\d+$/.test(version)) {
    return { ok: false, log: "Version must look like v1.2.3." };
  }
  const steps = [];
  const step = async (label, cmd, args) => {
    const r = await run(cmd, args);
    steps.push(`$ ${cmd} ${args.join(" ")}\n${r.out}`);
    if (!r.ok) throw new Error(label);
    return r;
  };
  try {
    // The gate is the whole point: an AI-free release is safe because the
    // same checks CI runs must pass locally before anything leaves.
    const g = await gates();
    steps.push(g.tests.out, g.parity.out);
    if (!g.green) throw new Error("tests/parity failed — nothing was pushed");
    const dirty = await run("git", ["status", "--short"]);
    if (dirty.out) {
      await step("stage", "git", ["add", "-A"]);
      await step("commit", "git", ["commit", "-m", `${version}: ${message || "maintenance release"}`]);
    }
    await step("push", "git", ["push"]);
    await step("tag", "git", ["tag", version]);
    await step("push tag", "git", ["push", "origin", version]);
    return { ok: true, log: steps.join("\n\n") };
  } catch (e) {
    return { ok: false, log: `${steps.join("\n\n")}\n\nSTOPPED: ${e.message}` };
  }
}

// ---- http --------------------------------------------------------------

const routes = {
  "GET /api/status": () => status(),
  "GET /api/outdated": () => outdated(),
  "POST /api/update": (b) => updateDep(b.name, b.target),
  "POST /api/gates": () => gates(),
  "POST /api/release": (b) => release(b.version, b.message),
};

createServer(async (req, res) => {
  const key = `${req.method} ${req.url}`;
  if (key === "GET /") {
    res.setHeader("content-type", "text/html; charset=utf-8");
    return res.end(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "index.html")));
  }
  const handler = routes[key];
  if (!handler) { res.statusCode = 404; return res.end("{}"); }
  if (busy) {
    res.statusCode = 409;
    return res.end(JSON.stringify({ error: `Busy: ${busy}` }));
  }
  busy = key;
  try {
    let body = {};
    if (req.method === "POST") {
      const chunks = [];
      for await (const c of req) chunks.push(c);
      try { body = JSON.parse(Buffer.concat(chunks).toString() || "{}"); } catch { }
    }
    const result = await handler(body);
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify(result));
  } catch (e) {
    res.statusCode = 500;
    res.end(JSON.stringify({ error: String(e) }));
  } finally {
    busy = null;
  }
}).listen(PORT, "127.0.0.1", () => {
  console.log(`Uncorked cockpit → http://localhost:${PORT}`);
});
