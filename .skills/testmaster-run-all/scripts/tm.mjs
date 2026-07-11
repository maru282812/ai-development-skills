#!/usr/bin/env node
// tm.mjs — AI Testmaster 用の固定 I/O ヘルパー。
// testmaster-run-all（無人周回）が使う全ての HTTP / fingerprint をこの1本に集約する。
// 目的: アドホックな curl / sha1sum を排除し、許可設定を「このスクリプト1つ」で済ませて自走させる。
//
// 使い方:
//   node tm.mjs get   <tmBase> <projectId>                         -> project bundle(JSON) を stdout
//   node tm.mjs import <tmBase> <projectId> <bodyFile>             -> POST /suggestions/import
//         bodyFile は import リクエストボディそのもの（生バイトをそのまま送る）:
//           全置換 : { "items": [...] }  （または { "mode":"replace-all", "items":[...], "surfaces":[...] }）
//           部分置換: { "mode":"replace-areas", "areas":["API: users"], "items":[...] }
//         → replace-areas は areas 内だけ置き換え他エリアを温存。番号(code)と run 履歴は id 一致分を維持。
//   node tm.mjs run   <tmBase> <projectId> <runFile>              -> POST /runs (合否1件記録)
//   node tm.mjs fp    <sourceFile> [startLine] [endLine]          -> 派生元コードの16桁ハッシュ
//   node tm.mjs req   <METHOD> <url> [--json <file>] [--header k:v]... [--token <bearer>]
//                                                                   -> 対象アプリへ実リクエスト。STATUS + body を出力
//   node tm.mjs ping  <url>                                        -> 疎通確認 (STATUS のみ / 落ちてれば DOWN)
//
// 全ファイルは UTF-8 のバイト列をそのまま body に載せる（Windows の CP932 化けを回避）。

import fs from "node:fs";
import crypto from "node:crypto";

const [, , cmd, ...rest] = process.argv;

function die(msg, code = 2) {
  process.stderr.write(`tm.mjs: ${msg}\n`);
  process.exit(code);
}

function parseFlags(args) {
  const out = { _: [], headers: {}, json: null, token: null, statusOnly: false };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--json") out.json = args[++i];
    else if (a === "--header") {
      const h = args[++i] || "";
      const idx = h.indexOf(":");
      if (idx > 0) out.headers[h.slice(0, idx).trim()] = h.slice(idx + 1).trim();
    } else if (a === "--token") out.token = args[++i];
    else if (a === "--status-only") out.statusOnly = true;
    else out._.push(a);
  }
  return out;
}

async function readBody(res) {
  const buf = Buffer.from(await res.arrayBuffer());
  return buf.toString("utf8");
}

async function main() {
  if (cmd === "get") {
    const [tmBase, projectId] = rest;
    if (!tmBase || !projectId) die("usage: get <tmBase> <projectId>");
    const res = await fetch(`${tmBase}/api/projects/${projectId}`);
    const body = await readBody(res);
    if (res.status === 404) die(`project not found (404): ${projectId}`, 3);
    if (!res.ok) die(`GET failed: ${res.status}\n${body}`, 4);
    process.stdout.write(body);
    return;
  }

  if (cmd === "import" || cmd === "run") {
    const [tmBase, projectId, file] = rest;
    if (!tmBase || !projectId || !file) die(`usage: ${cmd} <tmBase> <projectId> <file>`);
    const bytes = fs.readFileSync(file); // raw UTF-8 bytes
    const path = cmd === "import"
      ? `${tmBase}/api/projects/${projectId}/suggestions/import`
      : `${tmBase}/api/projects/${projectId}/runs`;
    const res = await fetch(path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: bytes,
    });
    const body = await readBody(res);
    process.stdout.write(`STATUS ${res.status}\n${body}\n`);
    if (!res.ok) process.exit(5);
    return;
  }

  if (cmd === "fp") {
    const [file, start, end] = rest;
    if (!file) die("usage: fp <sourceFile> [startLine] [endLine]");
    let text = fs.readFileSync(file, "utf8");
    if (start) {
      const lines = text.split(/\r?\n/);
      const s = Math.max(1, parseInt(start, 10)) - 1;
      const e = end ? parseInt(end, 10) : lines.length;
      text = lines.slice(s, e).join("\n");
    }
    const hash = crypto.createHash("sha1").update(text, "utf8").digest("hex").slice(0, 16);
    process.stdout.write(hash + "\n");
    return;
  }

  if (cmd === "req") {
    const f = parseFlags(rest);
    const [method, url] = f._;
    if (!method || !url) die("usage: req <METHOD> <url> [--json <file>] [--header k:v]... [--token <bearer>]");
    const headers = { ...f.headers };
    let body;
    if (f.json) {
      body = fs.readFileSync(f.json);
      if (!headers["Content-Type"]) headers["Content-Type"] = "application/json";
    }
    if (f.token) headers["Authorization"] = `Bearer ${f.token}`;
    let res;
    try {
      res = await fetch(url, { method: method.toUpperCase(), headers, body, redirect: "manual" });
    } catch (e) {
      process.stdout.write(`STATUS 0\nREQUEST_ERROR ${e.message}\n`);
      process.exit(6);
    }
    if (f.statusOnly) {
      process.stdout.write(`STATUS ${res.status}\n`);
      return;
    }
    const text = await readBody(res);
    const shown = text.length > 4000 ? text.slice(0, 4000) + `\n…(${text.length - 4000} more bytes)` : text;
    process.stdout.write(`STATUS ${res.status}\n${shown}\n`);
    return;
  }

  if (cmd === "ping") {
    const [url] = rest;
    if (!url) die("usage: ping <url>");
    try {
      const res = await fetch(url, { method: "GET", redirect: "manual" });
      process.stdout.write(`STATUS ${res.status}\n`);
    } catch (e) {
      process.stdout.write(`DOWN ${e.message}\n`);
      process.exit(7);
    }
    return;
  }

  die(`unknown command: ${cmd || "(none)"}. see header for usage.`, 1);
}

main().catch((e) => die(e.stack || String(e), 99));
