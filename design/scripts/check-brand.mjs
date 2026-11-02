#!/usr/bin/env node
// brand.json の検査と CSS 変数の書き出し（design/brand.md）。
//   node check-brand.mjs <brand.json>         検査（不合格なら終了コード 1）
//   node check-brand.mjs <brand.json> --css   検査に通れば :root の CSS 変数を標準出力へ
import { readFileSync } from "node:fs";

const [file, flag] = process.argv.slice(2);
if (!file) {
  console.error("使い方: node check-brand.mjs <brand.json> [--css]");
  process.exit(2);
}

const COLOR_KEYS = ["surface", "surfaceBand", "ink", "inkMuted", "brand", "accent", "onAccent", "line"];
const CONTRAST = [["ink", "surface"], ["ink", "surfaceBand"], ["inkMuted", "surface"], ["onAccent", "accent"]];
const MEDIA = ["app", "site", "sns", "slides"];
const USES = ["full", "accent", "none", "undecided"];
const REVEALS = ["none", "fade", "rise", "bounce", "sway", "parallax"];
const HEX = /^#[0-9a-f]{6}$/;
const CAMEL = /^[a-z][A-Za-z0-9]*$/;

const errors = [];
const warns = [];
let b;
try { b = JSON.parse(readFileSync(file, "utf8")); } catch (e) { console.error(`読めない: ${e.message}`); process.exit(1); }

const obj = (v) => typeof v === "object" && v !== null && !Array.isArray(v);
const str = (path, v) => { if (typeof v !== "string" || !v.trim()) errors.push(`${path} が空か文字列でない`); };
const num = (path, v, min = 0) => { if (typeof v !== "number" || v < min) errors.push(`${path} が ${min} 以上の数でない`); };
const weight = (path, v) => { if (!Number.isInteger(v) || v < 100 || v > 900 || v % 100) errors.push(`${path} が 100〜900 の100刻みでない`); };

if (b.kind !== "brand") errors.push('kind が "brand" でない');
if (!/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/.test(b.id ?? "")) errors.push("id が英小文字とハイフンの形でない");
for (const k of ["label", "summary", "fits", "owner", "source"]) str(k, b[k]);
if (!["active", "draft"].includes(b.status)) errors.push("status が active / draft でない");

// 色
const hex = (path, v) => { const ok = typeof v === "string" && HEX.test(v.trim().toLowerCase()); if (!ok) errors.push(`${path} が #rrggbb でない（${JSON.stringify(v)}）`); return ok ? v.trim().toLowerCase() : null; };
if (!obj(b.color)) errors.push("color が無い");
else for (const k of COLOR_KEYS) hex(`color.${k}`, b.color[k]);
if (b.colorExtra !== undefined) {
  if (!obj(b.colorExtra)) errors.push("colorExtra がオブジェクトでない");
  else for (const [k, v] of Object.entries(b.colorExtra)) { if (!CAMEL.test(k)) errors.push(`colorExtra.${k} のキーが camelCase でない`); if (COLOR_KEYS.includes(k)) errors.push(`colorExtra.${k} は color と重複`); hex(`colorExtra.${k}`, v); }
}

// コントラスト（WCAG 2）
const lum = (h) => { const c = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255).map((x) => (x <= 0.03928 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4)); return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]; };
const ratio = (a, c) => { const [x, y] = [lum(a), lum(c)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const contrasts = [];
if (obj(b.color) && COLOR_KEYS.every((k) => HEX.test(String(b.color[k]).toLowerCase()))) {
  for (const [fg, bg] of CONTRAST) {
    const r = ratio(b.color[fg].toLowerCase(), b.color[bg].toLowerCase());
    const shown = (Math.floor(r * 10) / 10).toFixed(1); // 切り捨て（4.46 を 4.5 と見せない）
    contrasts.push(`${fg}/${bg} ${shown}`);
    if (r < 4.5) errors.push(`コントラスト不足 ${fg}/${bg} = ${shown}（4.5 以上が必要）`);
  }
}

// 書体
if (!obj(b.type)) errors.push("type が無い");
else {
  weight("type.headingWeight", b.type.headingWeight);
  weight("type.bodyWeight", b.type.bodyWeight);
  if (typeof b.type.headingTracking !== "number") errors.push("type.headingTracking が数でない");
  if (typeof b.type.verticalAccent !== "boolean") errors.push("type.verticalAccent が真偽値でない");
  if (b.type.fonts !== undefined) {
    for (const role of ["heading", "body"]) if (!obj(b.type.fonts?.[role])) errors.push(`type.fonts.${role} が無い`);
    for (const [role, f] of Object.entries(b.type.fonts ?? {})) {
      if (!["heading", "body", "latin"].includes(role)) { errors.push(`type.fonts.${role} は未知の役割`); continue; }
      if (!/^[A-Za-z0-9][A-Za-z0-9 ]*$/.test(f?.family ?? "")) errors.push(`type.fonts.${role}.family が Google Fonts の書体名の形でない`);
      if (!["serif", "sans-serif"].includes(f?.generic)) errors.push(`type.fonts.${role}.generic が serif / sans-serif でない`);
      if (!Array.isArray(f?.weights) || !f.weights.length) errors.push(`type.fonts.${role}.weights が無い`);
      else { f.weights.forEach((w, i) => weight(`type.fonts.${role}.weights[${i}]`, w)); if (f.weights.some((w, i) => i && w <= f.weights[i - 1])) errors.push(`type.fonts.${role}.weights が昇順・重複なしでない`); }
    }
    const hw = b.type.fonts?.heading?.weights;
    if (Array.isArray(hw) && !hw.includes(b.type.headingWeight)) warns.push(`headingWeight ${b.type.headingWeight} が見出し書体の weights に無い`);
  }
}

// 形・動き・写真
if (!obj(b.shape)) errors.push("shape が無い"); else { num("shape.radius", b.shape.radius); str("shape.rule", b.shape.rule); str("shape.texture", b.shape.texture); }
if (b.radiusExtra !== undefined) { if (!obj(b.radiusExtra)) errors.push("radiusExtra がオブジェクトでない"); else for (const [k, v] of Object.entries(b.radiusExtra)) num(`radiusExtra.${k}`, v); }
if (!obj(b.motion)) errors.push("motion が無い");
else { if (!REVEALS.includes(b.motion.reveal)) errors.push(`motion.reveal が ${REVEALS.join(" / ")} のどれでもない`); num("motion.durationMs", b.motion.durationMs); num("motion.distancePx", b.motion.distancePx); str("motion.easing", b.motion.easing); if (typeof b.motion.parallax !== "boolean") errors.push("motion.parallax が真偽値でない"); }
if (!obj(b.photo)) errors.push("photo が無い"); else for (const k of ["role", "treatment", "placement"]) str(`photo.${k}`, b.photo[k]);

// 媒体
if (!obj(b.media)) errors.push("media が無い");
else for (const m of MEDIA) {
  const v = b.media[m];
  if (!obj(v)) { errors.push(`media.${m} が無い`); continue; }
  if (!USES.includes(v.use)) errors.push(`media.${m}.use が ${USES.join(" / ")} のどれでもない`);
  if (v.use === "undecided") warns.push(`media.${m} は未決。使う前に人に確認する`);
}
if (b.rules !== undefined && (!Array.isArray(b.rules) || b.rules.some((r) => typeof r !== "string"))) errors.push("rules が文字列の配列でない");
if (b.voice === undefined) warns.push("voice が無い（言葉づかいは推測で埋めない）");

if (flag === "--css") {
  if (errors.length) { console.error(errors.map((e) => `✕ ${e}`).join("\n")); process.exit(1); }
  const kebab = (s) => s.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);
  const font = (f) => (f ? `"${f.family}", ${f.generic}` : null);
  const lines = [`/* brand: ${b.id}（${file} から書き出し。値を変えるときは brand.json${b.canonical ? " の正本" : ""}を先に直す） */`, ":root {"];
  for (const [k, v] of Object.entries({ ...b.color, ...(b.colorExtra ?? {}) })) lines.push(`  --b-${kebab(k)}: ${v.toLowerCase()};`);
  lines.push(`  --b-radius: ${b.shape.radius}px;`);
  for (const [k, v] of Object.entries(b.radiusExtra ?? {})) lines.push(`  --b-radius-${kebab(k)}: ${v}px;`);
  for (const role of ["heading", "body", "latin"]) { const f = font(b.type.fonts?.[role]); if (f) lines.push(`  --b-font-${role}: ${f};`); }
  lines.push(`  --b-heading-weight: ${b.type.headingWeight};`, `  --b-body-weight: ${b.type.bodyWeight};`, `  --b-heading-tracking: ${b.type.headingTracking}em;`, "}");
  console.log(lines.join("\n"));
  process.exit(0);
}

console.log(`# ${b.id ?? "?"}（${file}）`);
if (contrasts.length) console.log(`コントラスト: ${contrasts.join(" / ")}`);
for (const w of warns) console.log(`△ ${w}`);
for (const e of errors) console.log(`✕ ${e}`);
console.log(errors.length ? `不合格（${errors.length} 件）` : "合格");
process.exit(errors.length ? 1 : 0);
