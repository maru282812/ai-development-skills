<#
.SYNOPSIS
  .skills/*/SKILL.md のフロントマターから、管理者向けの skill 一覧ダッシュボード
  (skills-dashboard.html) を自動生成する。

.DESCRIPTION
  各 SKILL.md の name / metadata.summary / description を読み取り、
    - 概要(metadata.summary の日本語1文。無ければ description の先頭1文)
    - 起動方法(トリガー例の「...」フレーズ)
    - 分類(下の $CategoryMap)
  を抽出して、検索・カテゴリ絞り込み付きの単一 HTML を出力する。

  ルール: 各 SKILL.md の frontmatter に metadata.summary を日本語で1文書く。
  「何担当か(役割/フェーズ)＋どんなことをするか」を必ず含める。管理画面はこの値を表示する。
  データは HTML に埋め込むので file:// でも localhost でも動く。

  新しい skill を追加したら、このスクリプトを再実行するだけで一覧が更新される。
  未分類の skill は「その他」に入るので、$CategoryMap に1行足せば分類される。

.EXAMPLE
  powershell -File scripts/build-skills-dashboard.ps1
  # → skills-dashboard.html を再生成

  powershell -File scripts/build-skills-dashboard.ps1 -Serve
  # → 生成後 http://localhost:8777 で配信
#>
param(
  [switch]$Serve,
  [int]$Port = 8777
)

$ErrorActionPreference = 'Stop'
$root      = Split-Path -Parent $PSScriptRoot
$skillsDir = Join-Path $root '.skills'
$outFile   = Join-Path $root 'skills-dashboard.html'

# --- 分類定義（表示順・色つき）。新skillはここに1行足すと分類される -------------
$CategoryOrder = @(
  'Project Discovery',
  '設計・調査',
  '実装計画',
  'レビュー・テスト',
  'セットアップ・運用',
  'その他'
)
$CategoryColor = @{
  'Project Discovery'  = '#6366f1'
  '設計・調査'         = '#0ea5e9'
  '実装計画'           = '#10b981'
  'レビュー・テスト'   = '#f59e0b'
  'セットアップ・運用' = '#ec4899'
  'その他'             = '#64748b'
}
$CategoryMap = @{
  'project-discovery'        = 'Project Discovery'
  'scope-discovery'          = 'Project Discovery'
  'requirements-discovery'   = 'Project Discovery'
  'business-discovery'       = 'Project Discovery'
  'operations-discovery'     = 'Project Discovery'
  'legal-discovery'          = 'Project Discovery'
  'legal-publication-manager'= 'Project Discovery'
  'contract-discovery'       = 'Project Discovery'
  'risk-discovery'           = 'Project Discovery'
  'data-discovery'           = 'Project Discovery'
  'integration-discovery'    = 'Project Discovery'
  'metrics-discovery'        = 'Project Discovery'
  'nfr-discovery'            = 'Project Discovery'
  'discovery-planner'        = 'Project Discovery'
  'discovery-auditor'        = 'Project Discovery'

  'system-investigator'      = '設計・調査'
  'bug-investigator'         = '設計・調査'
  'data-flow-mapper'         = '設計・調査'
  'saas-product-manager'     = '設計・調査'
  'db-designer'              = '設計・調査'
  'api-designer'             = '設計・調査'
  'prompt-architect'         = '設計・調査'
  'feature-spec-writer'      = '設計・調査'
  'screen-design-architect'  = '設計・調査'

  'implementation-planner'   = '実装計画'
  'refactor-planner'         = '実装計画'
  'project-quality-tooling'  = '実装計画'

  'code-review'              = 'レビュー・テスト'
  'security-review'          = 'レビュー・テスト'
  'migration-review'         = 'レビュー・テスト'
  'ui-ux-review'             = 'レビュー・テスト'
  'test-planner'             = 'レビュー・テスト'
  'adversarial-review'       = 'レビュー・テスト'
  'legal-consistency-audit'  = 'レビュー・テスト'

  'git-init-setup'           = 'セットアップ・運用'
  'dispatch-pattern-builder' = 'セットアップ・運用'
  'ops-guide-embedder'       = 'セットアップ・運用'
  'handover-package'         = 'セットアップ・運用'

  'tacit-knowledge-extractor'= '設計・調査'
}

# --- フロントマター抽出 -----------------------------------------------------------
function Get-SkillInfo([string]$path) {
  $raw = Get-Content -Raw -Encoding UTF8 $path
  $fm  = [regex]::Match($raw, '(?s)^﻿?---\r?\n(.*?)\r?\n---')
  if (-not $fm.Success) { return $null }
  $block = $fm.Groups[1].Value
  $lines = $block -split "\r?\n"

  $name = ''
  $tier = ''
  $summaryField = ''
  $descLines = @()
  $inDesc = $false
  foreach ($ln in $lines) {
    if ($ln -match '^name:\s*(.+?)\s*$') { $name = $Matches[1]; $inDesc = $false; continue }
    if ($ln -match '^\s+reasoning-tier:\s*(\S+)\s*$') { $tier = $Matches[1]; continue }
    if ($ln -match '^\s+summary:\s*(.+?)\s*$') {
      $summaryField = $Matches[1].Trim() -replace '^"(.*)"$', '$1' -replace "^'(.*)'$", '$1'
      continue
    }
    if ($ln -match '^description:\s*(.*)$') {
      $inDesc = $true
      $rest = $Matches[1].Trim()
      if ($rest -and $rest -notmatch '^[>|][-+]?$') { $descLines += $rest }
      continue
    }
    if ($inDesc) {
      # description は最後のキー想定。別のトップレベルキー(値なし含む)が来たら終了
      if ($ln -match '^[A-Za-z][A-Za-z0-9_-]*:(\s|$)') { $inDesc = $false; continue }
      $descLines += $ln.Trim()
    }
  }
  $desc = ($descLines -join ' ') -replace '\s+', ' '
  $desc = $desc.Trim()

  # 概要 = metadata.summary（日本語・担当＋何をするか）。無ければ description の先頭1文にフォールバック
  if ($summaryField) {
    $summary = $summaryField
  } else {
    $summary = ($desc -split '。')[0].Trim()
    if ($summary) { $summary += '。' }
  }

  # トリガー例 = 「...」フレーズ
  $trigSource = $desc
  $m = [regex]::Match($desc, 'トリガー例[は:：]?\s*(.*)$')
  if ($m.Success) { $trigSource = $m.Groups[1].Value }
  $triggers = @()
  foreach ($t in [regex]::Matches($trigSource, '「([^」]+)」')) {
    $triggers += $t.Groups[1].Value
    if ($triggers.Count -ge 8) { break }
  }

  $cat = if ($CategoryMap.ContainsKey($name)) { $CategoryMap[$name] } else { 'その他' }

  [PSCustomObject]@{
    name        = $name
    category    = $cat
    tier        = $tier
    summary     = $summary
    triggers    = $triggers
    description = $desc
  }
}

# --- 収集 -------------------------------------------------------------------------
$skills = @()
foreach ($d in Get-ChildItem -Path $skillsDir -Directory | Sort-Object Name) {
  $sk = Join-Path $d.FullName 'SKILL.md'
  if (Test-Path $sk) {
    $info = Get-SkillInfo $sk
    if ($info) { $skills += $info }
  }
}

# --- 使用回数の集計 -----------------------------------------------------------------
# Claude Code のセッションログ(~/.claude/projects/*/*.jsonl)から Skill 呼び出しを数える。
# LLM を通さずローカルのログを読むだけなのでトークン消費ゼロ。過去履歴もさかのぼって集計。
# 全プロジェクト横断（skill はグローバル配布なので、どのプロジェクトで使っても1箇所に集計）。
function Get-SkillUsage {
  $counts = @{}
  $projRoot = Join-Path $env:USERPROFILE '.claude\projects'
  if (-not (Test-Path $projRoot)) { return $counts }
  $pattern = '"name":"Skill","input":\{"skill":"([^"]+)"'
  Get-ChildItem -Path $projRoot -Recurse -Filter *.jsonl -File -ErrorAction SilentlyContinue | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    foreach ($m in [regex]::Matches($text, $pattern)) {
      $n = $m.Groups[1].Value
      if ($counts.ContainsKey($n)) { $counts[$n]++ } else { $counts[$n] = 1 }
    }
  }
  return $counts
}
$usage = Get-SkillUsage
foreach ($s in $skills) {
  $c = 0
  if ($usage.ContainsKey($s.name)) { $c = [int]$usage[$s.name] }
  $s | Add-Member -NotePropertyName count -NotePropertyValue $c -Force
}

# カテゴリ順→名前順で並べる
$rank = @{}; for ($i=0; $i -lt $CategoryOrder.Count; $i++) { $rank[$CategoryOrder[$i]] = $i }
$skills = $skills | Sort-Object @{Expression={$rank[$_.category]}}, name

$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm'
$json  = ($skills | ConvertTo-Json -Depth 6 -Compress)
$catJson = ($CategoryOrder | ConvertTo-Json -Compress)
$colorJson = ($CategoryColor | ConvertTo-Json -Compress)

# --- HTML -------------------------------------------------------------------------
$html = @"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Development Skills 一覧</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body { margin:0; font-family: "Segoe UI", "Hiragino Sans", "Meiryo", system-ui, sans-serif;
         background:#0f172a; color:#e2e8f0; }
  header { position:sticky; top:0; z-index:10; background:#0f172aee; backdrop-filter:blur(8px);
           padding:18px 24px 12px; border-bottom:1px solid #1e293b; }
  h1 { margin:0 0 4px; font-size:20px; }
  .meta { font-size:12px; color:#64748b; margin-bottom:12px; }
  .controls { display:flex; gap:12px; flex-wrap:wrap; align-items:center; }
  #q { flex:1; min-width:220px; padding:9px 12px; border-radius:8px; border:1px solid #334155;
       background:#1e293b; color:#e2e8f0; font-size:14px; }
  .cats { display:flex; gap:6px; flex-wrap:wrap; }
  .cat-btn { padding:6px 11px; border-radius:999px; border:1px solid #334155; background:transparent;
             color:#cbd5e1; font-size:12px; cursor:pointer; }
  .cat-btn.active { color:#0f172a; font-weight:700; }
  main { padding:20px 24px 60px; }
  .group-title { margin:26px 0 12px; font-size:15px; display:flex; align-items:center; gap:8px; }
  .dot { width:10px; height:10px; border-radius:3px; display:inline-block; }
  .grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(320px,1fr)); gap:14px; }
  .card { background:#1e293b; border:1px solid #263449; border-radius:12px; padding:15px 16px;
          display:flex; flex-direction:column; gap:9px; }
  .card h3 { margin:0; font-size:15px; font-family:"Consolas",monospace; word-break:break-all; }
  .tag { align-self:flex-start; font-size:11px; padding:2px 8px; border-radius:999px; color:#0f172a; font-weight:700; }
  .tags-row { display:flex; gap:6px; flex-wrap:wrap; }
  .tier { font-size:11px; padding:2px 8px; border-radius:999px; font-weight:700; border:1px solid transparent; }
  .tier-deep { background:#312e81; color:#c7d2fe; border-color:#6366f1; }
  .tier-standard { background:#1e293b; color:#94a3b8; border-color:#334155; }
  .summary { font-size:13px; line-height:1.55; color:#cbd5e1; margin:0; }
  .launch { font-size:12px; color:#94a3b8; }
  .launch code { background:#0f172a; padding:1px 6px; border-radius:5px; font-size:12px; color:#a5b4fc; }
  .chips { display:flex; flex-wrap:wrap; gap:5px; }
  .chip { font-size:11px; background:#0f172a; border:1px solid #334155; color:#93c5fd;
          padding:2px 7px; border-radius:6px; }
  details { font-size:12px; color:#94a3b8; }
  details summary { cursor:pointer; color:#64748b; }
  details p { margin:6px 0 0; line-height:1.6; }
  .empty { color:#64748b; padding:40px; text-align:center; }
  .count { font-size:12px; color:#64748b; margin-left:auto; }
  .uses { margin-left:auto; align-self:center; font-size:11px; padding:2px 9px; border-radius:999px;
          background:#0f172a; border:1px solid #f59e0b55; color:#fbbf24; font-weight:700; white-space:nowrap; }
  .uses.zero { color:#475569; border-color:#334155; }
  .rank { font-family:"Consolas",monospace; color:#64748b; font-size:12px; margin-right:2px; }
</style>
</head>
<body>
<header>
  <h1>&#129302; AI Development Skills 一覧</h1>
  <div class="meta">全 <span id="total"></span> skill ・ 総呼び出し <span id="totaluses"></span> 回 ・ 生成: $generatedAt ・ 出典: <code>.skills/*/SKILL.md</code> + <code>~/.claude/projects/*.jsonl</code>（再生成: <code>scripts/build-skills-dashboard.ps1</code>）</div>
  <div class="controls">
    <input id="q" type="search" placeholder="スキル名・トリガー・説明で検索…（例: 要件 / RLS / 画面 / migration）">
    <div class="cats" id="cats"></div>
    <button id="sortbtn" class="cat-btn" title="表示順を切り替え">並び: 分類順</button>
  </div>
</header>
<main id="main"></main>

<script>
const SKILLS = $json;
const CATS   = $catJson;
const COLORS = $colorJson;

const q = document.getElementById('q');
const main = document.getElementById('main');
const catsEl = document.getElementById('cats');
const sortBtn = document.getElementById('sortbtn');
document.getElementById('total').textContent = SKILLS.length;
document.getElementById('totaluses').textContent =
  SKILLS.reduce((a,s)=>a+(s.count||0),0);

let active = 'ALL';
let byUsage = false;
const norm = s => (s||'').toLowerCase();

sortBtn.onclick = () => {
  byUsage = !byUsage;
  sortBtn.textContent = '並び: ' + (byUsage ? '使用回数順' : '分類順');
  sortBtn.classList.toggle('active', byUsage);
  if (byUsage) sortBtn.style.background = '#f59e0b';
  else sortBtn.style.background = '';
  render();
};

function makeCatBtn(label, color){
  const b = document.createElement('button');
  b.className = 'cat-btn' + (label===active?' active':'');
  b.textContent = label==='ALL' ? 'すべて' : label;
  if (label!=='ALL') b.style.borderColor = color;
  if (label===active) b.style.background = (label==='ALL' ? '#e2e8f0' : color);
  b.onclick = () => { active = label; render(); };
  return b;
}

function render(){
  // カテゴリボタン
  catsEl.innerHTML='';
  catsEl.appendChild(makeCatBtn('ALL', '#e2e8f0'));
  CATS.forEach(c => catsEl.appendChild(makeCatBtn(c, COLORS[c]||'#64748b')));

  const term = norm(q.value);
  const match = s => {
    if (active!=='ALL' && s.category!==active) return false;
    if (!term) return true;
    const hay = norm(s.name + ' ' + s.summary + ' ' + s.description + ' ' + (s.tier||'') + ' ' + (s.triggers||[]).join(' '));
    return hay.includes(term);
  };
  const list = SKILLS.filter(match);
  main.innerHTML='';
  if (!list.length){ main.innerHTML='<div class="empty">該当する skill がありません</div>'; return; }

  // 使用回数順モード: 分類をまたいで1リストにフラット表示
  if (byUsage) {
    const ranked = list.slice().sort((a,b)=>(b.count||0)-(a.count||0) || a.name.localeCompare(b.name));
    const title = document.createElement('div');
    title.className='group-title';
    title.innerHTML = '<span class="dot" style="background:#f59e0b"></span>使用回数順'+
                      '<span class="count">'+ranked.length+' skill</span>';
    main.appendChild(title);
    const grid = document.createElement('div'); grid.className='grid';
    ranked.forEach((s,i) => grid.appendChild(card(s, COLORS[s.category]||'#64748b', i+1)));
    main.appendChild(grid);
    return;
  }

  CATS.forEach(cat => {
    const items = list.filter(s => s.category===cat);
    if (!items.length) return;
    const color = COLORS[cat]||'#64748b';
    const title = document.createElement('div');
    title.className='group-title';
    title.innerHTML = '<span class="dot" style="background:'+color+'"></span>'+cat+
                      '<span class="count">'+items.length+' skill</span>';
    main.appendChild(title);
    const grid = document.createElement('div'); grid.className='grid';
    items.forEach(s => grid.appendChild(card(s, color)));
    main.appendChild(grid);
  });
}

function card(s, color, rank){
  const el = document.createElement('div'); el.className='card';
  const tags = (s.triggers||[]).map(t=>'<span class="chip">'+esc(t)+'</span>').join('');
  const n = s.count||0;
  const uses = '<span class="uses'+(n?'':' zero')+'" title="使用回数（全プロジェクト・全履歴）">'+
               (n? ('&#9650; '+n+' 回') : '未使用')+'</span>';
  const rankTag = rank ? '<span class="rank">#'+rank+'</span>' : '';
  el.innerHTML =
    '<div class="tags-row">'+rankTag+'<span class="tag" style="background:'+color+'">'+esc(s.category)+'</span>'+
    (s.tier?'<span class="tier tier-'+esc(s.tier)+'">'+esc(s.tier)+'</span>':'')+uses+'</div>'+
    '<h3>'+esc(s.name)+'</h3>'+
    '<p class="summary">'+esc(s.summary)+'</p>'+
    '<div class="launch">起動: <code>/'+esc(s.name)+'</code> または下のトリガー語を会話で言う</div>'+
    (tags?'<div class="chips">'+tags+'</div>':'')+
    (s.description?'<details><summary>説明全文</summary><p>'+esc(s.description)+'</p></details>':'');
  return el;
}
function esc(t){ return (t||'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }

q.addEventListener('input', render);
render();

// localhost 配信時のみ: リロードのたびに最新カウントを取りに行く。
// file:// で開いた場合は fetch がブロックされるので、焼き込み値のまま表示（フォールバック）。
fetch('skill-usage.json', { cache: 'no-store' })
  .then(r => r.ok ? r.json() : null)
  .then(u => {
    if (!u) return;
    SKILLS.forEach(s => s.count = u[s.name] || 0);
    document.getElementById('totaluses').textContent =
      SKILLS.reduce((a,s)=>a+(s.count||0),0);
    render();
  })
  .catch(()=>{});
</script>
</body>
</html>
"@

$html | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Generated: $outFile  ($($skills.Count) skills)"

if ($Serve) {
  # 単純なファイルサーバーではなく、リクエストのたびにログを再集計する小さなサーバー。
  # これにより「ブラウザをリロードするだけで最新の使用回数」が取れる（build 再実行不要）。
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$Port/")
  $listener.Start()
  Write-Host "Serving on http://localhost:$Port/skills-dashboard.html  (Ctrl+C to stop)"
  Write-Host "  リロードのたびに ~/.claude/projects のログを再集計して最新カウントを返します"
  try {
    while ($listener.IsListening) {
      $ctx  = $listener.GetContext()
      $path = $ctx.Request.Url.AbsolutePath
      try {
        if ($path -eq '/skill-usage.json') {
          $u = Get-SkillUsage
          $body = ($u | ConvertTo-Json -Compress)
          if (-not $body) { $body = '{}' }
          $bytes = [Text.Encoding]::UTF8.GetBytes($body)
          $ctx.Response.ContentType = 'application/json; charset=utf-8'
          $ctx.Response.Headers.Add('Cache-Control','no-store')
          $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        elseif ($path -eq '/' -or $path -eq '/skills-dashboard.html') {
          $bytes = [IO.File]::ReadAllBytes($outFile)
          $ctx.Response.ContentType = 'text/html; charset=utf-8'
          $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        else {
          $ctx.Response.StatusCode = 404
        }
      } catch {
        $ctx.Response.StatusCode = 500
      } finally {
        $ctx.Response.OutputStream.Close()
      }
    }
  } finally {
    $listener.Stop()
  }
}
