// 壁打ちモード用 CLI（service role 直結・リポジトリ非依存）。
// アプリを経由せず ideas / idea_reviews / idea_review_messages へ直接読み書きする。
// シート構造の正は idea-engine の lib/ai/review.ts の ReviewSheetSchema。
// review.ts の軸スキーマを変えたら本ファイルも同期すること。
//
// 認証: このスクリプトと同じフォルダの .env / .env.local を読む（無ければ process.env）。
//   NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY が必須。
//   APP_URL（任意, 既定 http://localhost:3003）はレビューURLの表示に使う。
//
// 使い方（どのディレクトリからでも可。パスはこのファイルを指す）:
//   node <このファイル> list
//   node <このファイル> show  <ideaId|タイトル部分一致>
//   node <このファイル> add   <payload.json>            新規アイデアを ideas へ登録
//   node <このファイル> init  <ideaId|タイトル部分一致>
//   node <このファイル> patch <ideaId|タイトル部分一致> <payload.json>
//
// add の payload.json:  { "title": "...", "summary": "...", "body": "...", "status": "draft|kept|archived" }
// patch の payload.json: { "user": "...", "reply": "...", "target_axis": "...", "patches": [ { "axis": "...", "value": {...} } ] }
import { createClient } from "@supabase/supabase-js";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// ===== env（スクリプト隣の .env / .env.local を優先、無ければ process.env） =====
function loadEnv() {
  const here = dirname(fileURLToPath(import.meta.url));
  const merged = { ...process.env };
  for (const name of [".env", ".env.local"]) {
    const p = join(here, name);
    if (!existsSync(p)) continue;
    for (const line of readFileSync(p, "utf8").split("\n")) {
      const t = line.trim();
      if (!t || t.startsWith("#") || !t.includes("=")) continue;
      const i = t.indexOf("=");
      const k = t.slice(0, i).trim();
      if (merged[k] === undefined || merged[k] === "") merged[k] = t.slice(i + 1).trim();
    }
  }
  return merged;
}
const env = loadEnv();
if (!env.NEXT_PUBLIC_SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
  console.error(
    "認証が不足しています。このフォルダの .env に NEXT_PUBLIC_SUPABASE_URL と SUPABASE_SERVICE_ROLE_KEY を設定してください（.env.example 参照）。"
  );
  process.exit(1);
}
const APP_URL = (env.APP_URL || "http://localhost:3003").replace(/\/$/, "");
const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

// ===== ReviewSheetSchema（idea-engine lib/ai/review.ts と同期を保つこと） =====
import { z } from "zod";
const Evidence = z.enum(["A", "B", "C"]);
const SourceSchema = z.object({
  title: z.string().default(""),
  url: z.string().default(""),
  retrieved_at: z.string().optional().default(""),
});
const FeasibilitySchema = z.object({
  verdict: z.string().default(""),
  risks: z
    .array(z.object({ risk: z.string().default(""), mitigation: z.string().default("") }))
    .default([]),
  solo_operable: z.string().default(""),
});
const PersonaSchema = z.object({
  profile: z.string().default(""),
  pain: z.string().default(""),
  reality_check: z.string().default(""),
  validation_questions: z.array(z.string()).default([]),
});
const SizeSchema = z.object({
  value: z.string().default(""),
  basis: z.string().default(""),
  evidence: Evidence.default("C"),
  sources: z.array(SourceSchema).default([]),
});
const MarketSchema = z.object({
  bottom_up: z
    .object({
      observed_market: z.string().default(""),
      sources: z.array(SourceSchema).default([]),
    })
    .default({ observed_market: "", sources: [] }),
  tam: SizeSchema.default({ value: "", basis: "", evidence: "C", sources: [] }),
  sam: SizeSchema.default({ value: "", basis: "", evidence: "C", sources: [] }),
  som: SizeSchema.default({ value: "", basis: "", evidence: "C", sources: [] }),
});
const RevenueScenarioSchema = z.object({
  name: z.string().default(""),
  price: z.number().default(0),
  count_per_month: z.number().default(0),
  monthly_revenue: z.number().default(0),
  assumptions: z.string().default(""),
});
const RevenueSimSchema = z.object({
  price_benchmark: z.string().default(""),
  scenarios: z.array(RevenueScenarioSchema).default([]),
  payer: z.string().default(""),
  model: z.string().default(""),
});
const ApproachSchema = z.object({
  channels: z
    .array(
      z.object({
        name: z.string().default(""),
        why: z.string().default(""),
        tactic: z.string().default(""),
      })
    )
    .default([]),
  first_100: z.string().default(""),
  core_message: z.string().default(""),
});
const CompetitorsSchema = z.object({
  items: z
    .array(
      z.object({
        name: z.string().default(""),
        price: z.string().default(""),
        offering: z.string().default(""),
        strength: z.string().default(""),
        weakness: z.string().default(""),
        evidence: Evidence.default("C"),
        sources: z.array(SourceSchema).default([]),
      })
    )
    .default([]),
  summary: z.string().default(""),
});
const DifferentiationSchema = z.object({
  positioning: z.string().default(""),
  moat: z.string().default(""),
  one_liner: z.string().default(""),
});
const OverallSchema = z.object({
  verdict: z.enum(["go", "hold", "no_go"]).default("hold"),
  score: z.number().default(0),
  reasons: z.array(z.string()).default([]),
  next_actions: z.array(z.string()).default([]),
});
const ReviewSheetSchema = z.object({
  feasibility: FeasibilitySchema.default({ verdict: "", risks: [], solo_operable: "" }),
  persona: PersonaSchema.default({
    profile: "",
    pain: "",
    reality_check: "",
    validation_questions: [],
  }),
  market: MarketSchema.default({}),
  revenue_sim: RevenueSimSchema.default({
    price_benchmark: "",
    scenarios: [],
    payer: "",
    model: "",
  }),
  approach: ApproachSchema.default({ channels: [], first_100: "", core_message: "" }),
  competitors: CompetitorsSchema.default({ items: [], summary: "" }),
  differentiation: DifferentiationSchema.default({ positioning: "", moat: "", one_liner: "" }),
  overall: OverallSchema.default({ verdict: "hold", score: 0, reasons: [], next_actions: [] }),
});
const REVIEW_AXES = [
  "feasibility",
  "persona",
  "market",
  "revenue_sim",
  "approach",
  "competitors",
  "differentiation",
  "overall",
];

// applySheetPatches と同じ: 軸へ浅くマージ→全体を再検証。落ちたパッチはスキップ。
function applyPatches(sheet, patches) {
  let current = ReviewSheetSchema.parse(sheet);
  const applied = [];
  const skipped = [];
  for (const p of patches) {
    if (!REVIEW_AXES.includes(p.axis)) {
      skipped.push({ axis: p.axis, reason: "未知の軸" });
      continue;
    }
    let value = p.value;
    if (p.axis === "revenue_sim" && Array.isArray(value?.scenarios)) {
      value = {
        ...value,
        scenarios: value.scenarios.map((s) =>
          typeof s?.price === "number" && typeof s?.count_per_month === "number"
            ? { ...s, monthly_revenue: s.price * s.count_per_month }
            : s
        ),
      };
    }
    const merged = { ...current, [p.axis]: { ...current[p.axis], ...value } };
    const parsed = ReviewSheetSchema.safeParse(merged);
    if (parsed.success) {
      current = parsed.data;
      if (!applied.includes(p.axis)) applied.push(p.axis);
    } else {
      skipped.push({ axis: p.axis, reason: parsed.error.issues[0]?.message ?? "検証エラー" });
    }
  }
  return { sheet: current, applied, skipped };
}

// ===== アイデア解決（UUID or タイトル部分一致。複数一致は候補を出して終了） =====
async function resolveIdea(key) {
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(key);
  if (isUuid) {
    const { data, error } = await supabase
      .from("ideas")
      .select("id,title,summary")
      .eq("id", key)
      .single();
    if (error || !data) fail(`アイデアが見つかりません: ${key}`);
    return data;
  }
  const { data, error } = await supabase
    .from("ideas")
    .select("id,title,summary")
    .ilike("title", `%${key}%`);
  if (error) fail(error.message);
  if (!data?.length) fail(`タイトルに「${key}」を含むアイデアがありません。list で確認してください。`);
  if (data.length > 1) {
    console.error(`「${key}」は${data.length}件に一致。id で指定してください:`);
    for (const d of data) console.error(`  ${d.id}  ${d.title}`);
    process.exit(1);
  }
  return data[0];
}

async function latestReview(ideaId) {
  const { data, error } = await supabase
    .from("idea_reviews")
    .select("id,version,sheet,verdict,updated_at")
    .eq("idea_id", ideaId)
    .order("version", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) fail(error.message);
  return data;
}

function fail(msg) {
  console.error(msg);
  process.exit(1);
}
function out(obj) {
  console.log(JSON.stringify(obj, null, 2));
}
function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (e) {
    fail(`payload の読み込みに失敗: ${e.message}`);
  }
}

// ===== サブコマンド =====
const [cmd, ...args] = process.argv.slice(2);

if (cmd === "list") {
  const { data: ideas, error } = await supabase
    .from("ideas")
    .select("id,title,summary,created_at")
    .order("created_at", { ascending: false });
  if (error) fail(error.message);
  const { data: reviews } = await supabase
    .from("idea_reviews")
    .select("idea_id,version,verdict")
    .order("version", { ascending: true });
  const latest = new Map((reviews ?? []).map((r) => [r.idea_id, r]));
  out(
    (ideas ?? []).map((i) => ({
      id: i.id,
      title: i.title,
      review: latest.has(i.id)
        ? { version: latest.get(i.id).version, verdict: latest.get(i.id).verdict }
        : null,
    }))
  );
} else if (cmd === "show") {
  if (!args[0]) fail("使い方: show <ideaId|タイトル部分一致>");
  const idea = await resolveIdea(args[0]);
  const review = await latestReview(idea.id);
  out({
    idea,
    review: review
      ? { id: review.id, version: review.version, verdict: review.verdict, sheet: ReviewSheetSchema.parse(review.sheet ?? {}) }
      : null,
    hint: review ? undefined : "レビュー未作成。init で空シートを作れます。",
  });
} else if (cmd === "add") {
  if (!args[0]) fail("使い方: add <payload.json>  （{title, summary?, body?, status?}）");
  const p = readJson(args[0]);
  if (!p.title || typeof p.title !== "string") fail("add には title（文字列）が必須です。");
  const status = ["draft", "kept", "archived"].includes(p.status) ? p.status : "draft";
  const { data, error } = await supabase
    .from("ideas")
    .insert({
      title: p.title,
      summary: p.summary ?? null,
      body: p.body ?? null,
      status,
      model_used: "claude-code-kabeuchi",
    })
    .select("id,title,status")
    .single();
  if (error) fail(error.message);
  out({ ok: true, idea: data, review_url: `${APP_URL}/ideas/${data.id}/review` });
} else if (cmd === "init") {
  if (!args[0]) fail("使い方: init <ideaId|タイトル部分一致>");
  const idea = await resolveIdea(args[0]);
  const existing = await latestReview(idea.id);
  const version = (existing?.version ?? 0) + 1;
  const sheet = ReviewSheetSchema.parse({});
  const { data, error } = await supabase
    .from("idea_reviews")
    .insert({
      idea_id: idea.id,
      version,
      sheet,
      verdict: sheet.overall.verdict,
      model_used: "claude-code-kabeuchi",
    })
    .select("id,version")
    .single();
  if (error) fail(error.message);
  out({ ok: true, idea: { id: idea.id, title: idea.title }, review: data });
} else if (cmd === "patch") {
  if (!args[0] || !args[1]) fail("使い方: patch <ideaId|タイトル部分一致> <payload.json>");
  const idea = await resolveIdea(args[0]);
  const review = await latestReview(idea.id);
  if (!review) fail("レビューがありません。先に init を実行してください。");

  const payload = readJson(args[1]);
  const patches = Array.isArray(payload.patches) ? payload.patches : [];

  const { sheet, applied, skipped } = applyPatches(review.sheet ?? {}, patches);

  const msgs = [];
  if (payload.user)
    msgs.push({
      review_id: review.id,
      role: "user",
      content: payload.user,
      target_axis: payload.target_axis ?? null,
    });
  if (payload.reply)
    msgs.push({
      review_id: review.id,
      role: "assistant",
      content: payload.reply,
      target_axis: payload.target_axis ?? null,
      sheet_patch: patches,
    });
  if (msgs.length) {
    const { error: me } = await supabase.from("idea_review_messages").insert(msgs);
    if (me) fail(me.message);
  }

  if (applied.length > 0) {
    const upd = { sheet, updated_at: new Date().toISOString() };
    if (applied.includes("overall")) upd.verdict = sheet.overall.verdict;
    const { error: ue } = await supabase.from("idea_reviews").update(upd).eq("id", review.id);
    if (ue) fail(ue.message);
  }

  try {
    await supabase.from("usage_events").insert({ event: "idea_review_kabeuchi_patch" });
  } catch {
    // 計測の失敗は無視
  }

  out({
    ok: true,
    idea: { id: idea.id, title: idea.title },
    version: review.version,
    applied,
    skipped,
    verdict: applied.includes("overall") ? sheet.overall.verdict : review.verdict,
    review_url: `${APP_URL}/ideas/${idea.id}/review`,
  });
} else {
  fail(`使い方: node kabeuchi.mjs <list|show|add|init|patch> ...
  list                        アイデア一覧（最新レビューの版と判定つき）
  show  <idea>                最新の精査シートを表示
  add   <payload.json>        新規アイデアを ideas へ登録（{title, summary?, body?, status?}）
  init  <idea>                空の精査シートを新規作成（version+1）
  patch <idea> <payload.json> シートへパッチ適用＋会話履歴を保存`);
}
