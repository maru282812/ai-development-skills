#!/usr/bin/env node
// アプリ画面の自動計測（design/app.md §10 の 3・4・8・9 と AIっぽさの数値）。
// 対象プロジェクトのフォルダで実行する（playwright はそのプロジェクトの node_modules から読む）。
//   node C:/work/ai-development-skills/design/scripts/measure-app.mjs --base http://127.0.0.1:3017 --path / --out ./.runtime/measure-app [--login ./login.mjs] [--tap 44] [--widths 390,320,1280]
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { mkdirSync, writeFileSync } from "node:fs";

const args = Object.fromEntries(process.argv.slice(2).reduce((a, v, i, all) => (v.startsWith("--") ? [...a, [v.slice(2), all[i + 1]?.startsWith("--") || all[i + 1] === undefined ? "1" : all[i + 1]]] : a), []));
if (!args.base || !args.out) {
  console.error("使い方: --base <http://127.0.0.1:port> --out <出力先> [--path /] [--login <file.mjs>] [--tap 44] [--widths 390,320,1280]");
  process.exit(2);
}
const BASE = args.base.replace(/\/$/, "");
const PATH = args.path ?? "/";
if (/^[A-Za-z]:[\\/]/.test(PATH)) {
  console.error(`--path が Windows のパスに書き換えられています（${PATH}）。Git Bash では MSYS_NO_PATHCONV=1 を付けるか、--path を省略してください。`);
  process.exit(2);
}
const OUT = resolve(args.out);
const TAP = Number(args.tap ?? 44);
const WIDTHS = (args.widths ?? "390,320,1280").split(",").map(Number);
mkdirSync(OUT, { recursive: true });

let chromium;
try { ({ chromium } = createRequire(resolve("package.json"))("playwright")); }
catch { console.error("playwright が見つかりません。対象プロジェクトのフォルダで実行するか、npm i -D playwright を入れてください。"); process.exit(2); }
const login = args.login ? (await import(pathToFileURL(resolve(args.login)).href)).default : null;

async function measure(page, mobile) {
  return page.evaluate(({ TAP, mobile }) => {
    const cs = (el) => getComputedStyle(el);
    const root = document.querySelector("main") ?? document.body;
    const visible = (e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && cs(e).visibility !== "hidden"; };
    const texts = [...root.querySelectorAll("*")].filter((e) => visible(e) && [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()));
    const sizes = {};
    for (const e of texts) { const s = cs(e).fontSize; sizes[s] = (sizes[s] || 0) + 1; }
    const smallEls = texts.filter((e) => parseFloat(cs(e).fontSize) <= 12);
    const sample = (els, f) => els.slice(0, 12).map(f);
    const snippet = (e) => e.textContent.trim().replace(/\s+/g, " ").slice(0, 32);
    const devOverlay = (e) => !!e.closest("nextjs-portal, [data-nextjs-toast], [data-nextjs-dev-tools-button]");
    const taps = [...document.querySelectorAll("a[href], button, [role=button], input:not([type=hidden]), select, textarea, summary")].filter((e) => visible(e) && !devOverlay(e));
    const tapBox = (e) => {
      // ラベルで包まれた入力は、ラベル全体の大きさで判定する
      const host = e.matches("input[type=radio], input[type=checkbox]") ? (e.closest("label") ?? e) : e;
      const r = host.getBoundingClientRect();
      return { w: Math.round(r.width), h: Math.round(r.height) };
    };
    const smallTaps = mobile ? taps.filter((e) => { const b = tapBox(e); return b.h < TAP || b.w < TAP; }) : [];
    const all = [...document.querySelectorAll("body *")];
    const pick = (els, f) => ({ count: els.length, sample: sample(els, f) });
    return {
      viewport: { w: innerWidth, h: innerHeight },
      overflow: { scrollWidth: document.documentElement.scrollWidth, clientWidth: document.documentElement.clientWidth },
      pageHeight: document.documentElement.scrollHeight,
      bodyFont: cs(document.body).fontFamily,
      text: { elements: texts.length, sizes, smallTextRatio: (() => { const len = (e) => [...e.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join("").length; const all = texts.reduce((a, e) => a + len(e), 0); const small = smallEls.reduce((a, e) => a + len(e), 0); return all ? +(small / all).toFixed(2) : 0; })(), smallSample: sample(smallEls, snippet) },
      taps: { total: taps.length, smallTaps: smallTaps.length, sample: sample(smallTaps, (e) => { const b = tapBox(e); return `${snippet(e) || e.getAttribute("aria-label") || e.tagName}(${b.w}x${b.h})`; }) },
      headings: [...document.querySelectorAll("h1,h2,h3")].filter(visible).map((e) => `${e.tagName} ${snippet(e)} ${cs(e).fontSize}/${cs(e).fontWeight}`),
      slop: {
        gradients: pick(all.filter((e) => /gradient/.test(cs(e).backgroundImage)), (e) => e.className?.toString().slice(0, 40)),
        bigShadows: pick(all.filter((e) => /\b([2-9]\d|\d{3,})px/.test(cs(e).boxShadow)), (e) => e.className?.toString().slice(0, 40)),
        uppercase: pick(texts.filter((e) => cs(e).textTransform === "uppercase"), snippet),
        italic: pick(texts.filter((e) => cs(e).fontStyle === "italic"), snippet),
        negativeTracking: pick(texts.filter((e) => parseFloat(cs(e).letterSpacing) < 0), snippet),
        emoji: (root.innerText.match(/\p{Extended_Pictographic}/gu) || []).length,
        exclamation: (root.innerText.match(/[!！]/g) || []).length,
        leftStripes: pick(all.filter((e) => { const s = cs(e); return parseFloat(s.borderLeftWidth) >= 3 && parseFloat(s.borderRightWidth) <= 1; }), (e) => e.className?.toString().slice(0, 40)),
      },
    };
  }, { TAP, mobile });
}

async function focusWalk(page) {
  await page.mouse.click(1, 1);
  const seen = new Map();
  for (let i = 0; i < 120; i++) {
    await page.keyboard.press("Tab");
    const f = await page.evaluate(() => {
      const a = document.activeElement;
      if (!a || a === document.body || a.closest("nextjs-portal") || a.tagName === "NEXTJS-PORTAL") return null;
      const s = getComputedStyle(a);
      const ring = (s.outlineStyle !== "none" && parseFloat(s.outlineWidth) > 0) || (s.boxShadow !== "none" && /rgb/.test(s.boxShadow));
      return { key: a.outerHTML.slice(0, 120), label: (a.textContent || a.getAttribute("aria-label") || a.tagName).trim().slice(0, 30), ring };
    });
    if (f && !seen.has(f.key)) seen.set(f.key, f);
  }
  const list = [...seen.values()];
  return { reached: list.length, withoutRing: list.filter((f) => !f.ring).map((f) => f.label) };
}

const errors = [];
const results = {};
let browser;
try { browser = await chromium.launch({ channel: "chrome", headless: true }); } catch { browser = await chromium.launch({ headless: true }); }
try {
  for (const w of WIDTHS) {
    const mobile = w < 768;
    const ctx = await browser.newContext({ viewport: { width: w, height: mobile ? 844 : 800 }, deviceScaleFactor: mobile ? 2 : 1, isMobile: mobile, hasTouch: mobile });
    const page = await ctx.newPage();
    page.on("pageerror", (e) => errors.push(`${w}: ${e.message}`));
    page.on("console", (m) => { if (m.type() === "error") errors.push(`${w} console: ${m.text().slice(0, 200)}`); });
    if (login) await login(page, BASE);
    await page.goto(BASE + PATH, { waitUntil: "networkidle" });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: `${OUT}/${w}-fold.png` });
    await page.screenshot({ path: `${OUT}/${w}-full.png`, fullPage: true });
    const m = await measure(page, mobile);
    m.focus = await focusWalk(page);
    results[w] = m;
    writeFileSync(`${OUT}/${w}.json`, JSON.stringify(m, null, 2));
    await ctx.close();
  }
} finally {
  await browser.close();
}

// summary.md
const mark = (ok) => (ok ? "○" : "✕");
const lines = [`# measure-app ${BASE}${PATH}`, "", `計測: ${new Date().toISOString()} / タップ基準 ${TAP}px / console エラー ${errors.length} 件`, "", "| 幅 | 4 はみ出し | 8 文字（12px以下の文字数比） | 9 押せる範囲 | 3 フォーカス |", "|---|---|---|---|---|"];
for (const [w, m] of Object.entries(results)) {
  const ov = m.overflow.scrollWidth <= m.overflow.clientWidth;
  const st = m.text.smallTextRatio <= 0.3;
  const tp = Number(w) >= 768 || m.taps.smallTaps === 0;
  const fc = m.focus.withoutRing.length === 0;
  lines.push(`| ${w} | ${mark(ov)} ${m.overflow.scrollWidth}/${m.overflow.clientWidth} | ${mark(st)} ${Math.round(m.text.smallTextRatio * 100)}%（${m.text.elements} 要素） | ${Number(w) >= 768 ? "—" : `${mark(tp)} ${m.taps.smallTaps}/${m.taps.total} が基準未満`} | ${mark(fc)} ${m.focus.reached - m.focus.withoutRing.length}/${m.focus.reached} |`);
}
const first = Object.values(results)[0];
if (first) {
  const s = first.slop;
  lines.push("", "## AIっぽさの数値（最も狭い幅）", "", `グラデーション ${s.gradients.count} / 大きい影 ${s.bigShadows.count} / 絵文字 ${s.emoji} / 大文字ラベル ${s.uppercase.count} / 斜体 ${s.italic.count} / 負の字間 ${s.negativeTracking.count} / 「！」 ${s.exclamation} / 左の色帯 ${s.leftStripes.count}`);
  lines.push("", "## 12px 以下の文字（例）", "", ...first.text.smallSample.map((t) => `- ${t}`));
  if (first.taps.sample.length) lines.push("", "## 押せる範囲が基準未満（例）", "", ...first.taps.sample.map((t) => `- ${t}`));
  if (first.focus.withoutRing.length) lines.push("", "## フォーカスリングが出ない要素", "", ...first.focus.withoutRing.map((t) => `- ${t}`));
}
if (errors.length) lines.push("", "## console エラー", "", ...errors.map((e) => `- ${e}`));
lines.push("", "人が見る項目: 1 密度 / 2 3状態 / 5 到達 / 6 色の意味 / 7 文言（design/app.md §10）");
writeFileSync(`${OUT}/summary.md`, lines.join("\n") + "\n");
console.log(lines.join("\n"));
