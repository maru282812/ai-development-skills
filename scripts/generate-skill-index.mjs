#!/usr/bin/env node
// Generate .skills/development-router/skills-index.md from each skill's frontmatter.
// Uses metadata.summary when present, otherwise the head of description.
// Run: node scripts/generate-skill-index.mjs
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const repo = dirname(dirname(fileURLToPath(import.meta.url)));
const skillsDir = join(repo, ".skills");
const outDir = join(skillsDir, "development-router");
const outFile = join(outDir, "skills-index.md");

function parseFrontmatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  return m ? m[1] : "";
}

function getScalar(fm, key) {
  const m = fm.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  if (!m) return null;
  let v = m[1].trim();
  if (v === ">" || v === ">-" || v === "|" || v === "|-") return null; // block scalar
  return v.replace(/^"(.*)"$/, "$1");
}

function getBlock(fm, key) {
  // matches "key: >-" (or >, |, |-) followed by indented lines
  const re = new RegExp(`^(\\s*)${key}:\\s*[>|][-+]?\\s*\\r?\\n((?:\\1[ \\t]+.*(?:\\r?\\n|$))+)`, "m");
  const m = fm.match(re);
  if (!m) return null;
  return m[2]
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean)
    .join(" ");
}

function getSummary(fm) {
  const m = fm.match(/^\s+summary:\s*(.+)$/m);
  if (!m) return null;
  return m[1].trim().replace(/^"(.*)"$/, "$1");
}

function extractTriggers(desc) {
  if (!desc) return null;
  const m = desc.match(/トリガー例[:：]?\s*(.+)/s);
  if (!m) return null;
  const t = m[1].replace(/\s+/g, " ").trim();
  return t.length > 180 ? t.slice(0, 180) + "…" : t;
}

const entries = [];
for (const dir of readdirSync(skillsDir, { withFileTypes: true })) {
  if (!dir.isDirectory() || dir.name === "development-router") continue;
  const skillMd = join(skillsDir, dir.name, "SKILL.md");
  if (!existsSync(skillMd)) continue;
  const fm = parseFrontmatter(readFileSync(skillMd, "utf8"));
  const name = getScalar(fm, "name") ?? dir.name;
  const desc = getBlock(fm, "description") ?? getScalar(fm, "description") ?? "";
  let summary = getSummary(fm);
  if (!summary) {
    summary = desc.length > 220 ? desc.slice(0, 220) + "…" : desc;
  }
  const triggers = extractTriggers(desc);
  let entry = `- **${name}** — ${summary}`;
  if (triggers) entry += `\n  - トリガー例: ${triggers}`;
  entries.push(entry);
}

entries.sort();
const body = `# Skill Index（自動生成 — 編集禁止）

このファイルは \`node scripts/generate-skill-index.mjs\` が各スキルの frontmatter から生成する。
手で編集しない。スキルを追加・変更したら再生成すること。

本文の場所: \`C:\\work\\ai-development-skills\\.skills\\<name>\\SKILL.md\`

${entries.join("\n")}
`;

if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
writeFileSync(outFile, body, "utf8");
console.log(`wrote ${outFile} (${entries.length} skills)`);
