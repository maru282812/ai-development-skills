#!/usr/bin/env node
// inventory.mjs — 対象 Next.js アプリの「サーフェス台帳」を決定論的に列挙する。
// 設計網羅率マトリクスの横軸を、LLM の発想ではなく機械列挙で作るのが目的
// （抜けを「思いつき」ではなく「走査結果」で防ぐ）。LLM は出力を分類・観点付けするだけ。
//
// 使い方:
//   node inventory.mjs <targetRoot> [outFile]
//     targetRoot : 対象アプリのリポジトリルート（例 c:\work\ai-chat-interview）
//     outFile    : 省略時 stdout。指定すると surfaces.json を書き出す。
//
// 出力(JSON): { surfaces: [ { key, kind, name, area, applicablePerspectives, na } ] }
//   - applicablePerspectives は「まず埋めるべき既定観点」。skill が実コードを読んで
//     authn/authz/rls/ui/db-integrity 等を足し引きし、対象外は na(理由付き)にする。
//   - area は skill が生成するテスト項目の area と一致させる結合キー。
//
// 依存なし・読み取りのみ。app router を主対象にし、pages router / 非対応構成は
// SKILL の「フォールバック」に従い skill 側が手で surfaces を起こす。

import fs from "node:fs";
import path from "node:path";

const HTTP_METHODS = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"];
const SDK_HINTS = [
  { dep: "@line/bot-sdk", name: "LINE Messaging API" },
  { dep: "@line/liff", name: "LINE LIFF" },
  { dep: "stripe", name: "Stripe" },
  { dep: "@stripe/stripe-js", name: "Stripe (client)" },
  { dep: "openai", name: "OpenAI API" },
  { dep: "@anthropic-ai/sdk", name: "Anthropic API" },
  { dep: "resend", name: "Resend email" },
  { dep: "nodemailer", name: "SMTP email" },
  { dep: "twilio", name: "Twilio" },
  { dep: "@supabase/supabase-js", name: "Supabase" },
];

function walk(dir, out = []) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    if (entry.name === "node_modules" || entry.name === ".next" || entry.name.startsWith(".git")) {
      continue;
    }
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, out);
    } else {
      out.push(full);
    }
  }
  return out;
}

// app router のファイルパスからルート URL を導く。
// route groups "(x)" は除去、"[id]"→"{id}"、"[...slug]"→"{...slug}"。
function routePathFromApp(appDir, file) {
  const rel = path.relative(appDir, path.dirname(file)).split(path.sep).filter(Boolean);
  const segments = [];
  for (const seg of rel) {
    if (seg.startsWith("(") && seg.endsWith(")")) continue; // route group
    if (seg.startsWith("@")) continue; // parallel route slot
    const dyn = seg.replace(/^\[\.\.\.(.+)\]$/, "{...$1}").replace(/^\[(.+)\]$/, "{$1}");
    segments.push(dyn);
  }
  return `/${segments.join("/")}` || "/";
}

function detectMethods(source) {
  const found = new Set();
  const fnRe = /export\s+(?:async\s+)?function\s+([A-Z]+)\b/g;
  const constRe = /export\s+const\s+([A-Z]+)\s*[:=]/g;
  for (const re of [fnRe, constRe]) {
    let m;
    while ((m = re.exec(source))) {
      if (HTTP_METHODS.includes(m[1])) found.add(m[1]);
    }
  }
  return [...found];
}

function surface(kind, name, area, applicablePerspectives) {
  return { key: `${kind}:${name}`, kind, name, area, applicablePerspectives, na: [] };
}

function collectEndpoints(appDir, files) {
  const surfaces = [];
  for (const file of files) {
    const base = path.basename(file);
    if (base !== "route.ts" && base !== "route.tsx" && base !== "route.js") continue;
    const source = fs.readFileSync(file, "utf8");
    const methods = detectMethods(source);
    if (methods.length === 0) continue;
    const routePath = routePathFromApp(appDir, file);
    for (const method of methods) {
      const name = `${method} ${routePath}`;
      // 既定観点: どの endpoint にも当てるべき芯。auth/rls/db は skill が実コードで足す。
      surfaces.push(surface("api", name, `API ${name}`, ["normal", "validation", "error", "boundary"]));
    }
  }
  return surfaces;
}

function collectScreens(appDir, files) {
  const surfaces = [];
  for (const file of files) {
    const base = path.basename(file);
    if (base !== "page.tsx" && base !== "page.jsx" && base !== "page.js") continue;
    const routePath = routePathFromApp(appDir, file);
    const name = `Page ${routePath}`;
    surfaces.push(surface("screen", name, `Screen ${routePath}`, ["ui", "normal", "error"]));
  }
  return surfaces;
}

function collectTables(root) {
  const surfaces = [];
  const migrationsDir = path.join(root, "supabase", "migrations");
  const files = walk(migrationsDir).filter((f) => f.endsWith(".sql"));
  const seen = new Set();
  const re = /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?["']?([a-zA-Z0-9_]+)["']?/gi;
  for (const file of files) {
    const source = fs.readFileSync(file, "utf8");
    let m;
    while ((m = re.exec(source))) {
      const table = m[1];
      if (seen.has(table)) continue;
      seen.add(table);
      surfaces.push(surface("table", `table ${table}`, `DB ${table}`, ["db-integrity", "rls"]));
    }
  }
  return surfaces;
}

function collectIntegrations(root) {
  const surfaces = [];
  const pkgPath = path.join(root, "package.json");
  if (!fs.existsSync(pkgPath)) return surfaces;
  let deps = {};
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
    deps = { ...pkg.dependencies, ...pkg.devDependencies };
  } catch {
    return surfaces;
  }
  for (const hint of SDK_HINTS) {
    if (deps[hint.dep]) {
      surfaces.push(
        surface("integration", hint.name, `Integration ${hint.name}`, ["normal", "error", "domain-specific"]),
      );
    }
  }
  return surfaces;
}

function findAppDir(root) {
  for (const candidate of [path.join(root, "app"), path.join(root, "src", "app")]) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function main() {
  const [, , targetRoot, outFile] = process.argv;
  if (!targetRoot) {
    process.stderr.write("usage: inventory.mjs <targetRoot> [outFile]\n");
    process.exit(2);
  }
  const root = path.resolve(targetRoot);
  const appDir = findAppDir(root);

  const surfaces = [];
  if (appDir) {
    const appFiles = walk(appDir);
    surfaces.push(...collectEndpoints(appDir, appFiles));
    surfaces.push(...collectScreens(appDir, appFiles));
  }
  surfaces.push(...collectTables(root));
  surfaces.push(...collectIntegrations(root));

  const result = {
    surfaces,
    meta: {
      targetRoot: root,
      appDir: appDir || null,
      counts: {
        api: surfaces.filter((s) => s.kind === "api").length,
        screen: surfaces.filter((s) => s.kind === "screen").length,
        table: surfaces.filter((s) => s.kind === "table").length,
        integration: surfaces.filter((s) => s.kind === "integration").length,
      },
      note: appDir
        ? "app router detected. Refine applicablePerspectives against real code before import."
        : "No app/ dir found. Fill surfaces manually per SKILL fallback (pages router / non-Next.js).",
    },
  };

  const json = JSON.stringify(result, null, 2);
  if (outFile) {
    fs.writeFileSync(outFile, json, "utf8");
    process.stderr.write(`inventory: wrote ${surfaces.length} surfaces to ${outFile}\n`);
  } else {
    process.stdout.write(`${json}\n`);
  }
}

main();
