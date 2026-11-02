---
name: security-hardening-planner
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
metadata:
  reasoning-tier: deep
  summary: "セキュリティ強化の実装指示文を作る担当。静的/動的レポートと hardening テンプレを突き合わせ、優先度順で実装エージェントにそのまま渡せる修正指示文を生成する。コード本体は直さない。"
description: >-
  リリース前セキュリティ検証で見つかった穴を、実装できる修正指示文に落とすスキル。
  静的レポート(static-report) / 動的レポート(dynamic-report) / hardening-<project>.md を読み、
  各指摘に対して「どのファイルを・どう直すか・完了条件」を優先度順でまとめ、
  Claude Code / Codex にそのまま渡せる指示文を出す。コード本体は変更しない（指示文まで）。
  トリガー例:
  「セキュリティ強化の実装指示文を作って」「見つかった穴を直す指示文にして」
  「<project> のセキュリティ修正指示を優先度順で」「hardening の指摘を実装指示に落として」
  「セキュリティコーディング指示文を作って」。
  実際に静的に検査するのは security-static-check、深掘り監査は security-review、
  実装の自走は phase-runner（このスキルはその入力＝指示文を作る）。
---

# Purpose

セキュリティ検証の結果を、**実装できる修正指示文**に変換する。
検査（穴を見つける）と実装（直す）の間を埋める。コードは直さず、指示文まで。

入力の正は対象プロジェクトの `docs/security/`:
- `static-report-<project>-<date>.md`（security-static-check の出力）
- `dynamic-report-<project>-<date>.md`（動的検証の出力。あれば）
- `hardening-<project>.md`（守りの実装チェックリスト。あれば更新、無ければ雛形から作る）

雛形の正は ai-testmaster の `docs/security/hardening-instructions-template.md`。

# When To Use

- 静的 / 動的チェックが終わり、見つかった穴を実装タスクに落としたい
- hardening-<project>.md の「要対応」を、担当者（または AI）がそのまま着手できる指示文にしたい

このスキルは指示文まで。実装の自走は phase-runner、1件ずつの実装は通常の Claude Code。

# 入力の自動決定

| 入力 | 決め方 |
|---|---|
| 対象コードパス | プロンプトの「対象コードは …」。無ければ `C:\work\<project>` |
| レポート | `<対象>/docs/security/static-report-*.md` と `dynamic-report-*.md` の最新 |
| hardening | `<対象>/docs/security/hardening-<project>.md` |

レポートも hardening も無い場合は「先に security-static-check を回してください」と伝えて止まる
（指摘の無いところに指示文は作れない）。

# Procedure

### 1. 入力を読む
- 対象の `docs/security/` を ls し、static-report / dynamic-report / hardening を読む。
- 「要対応」「GAP」「赤」「High/Medium」の項目を全部拾う。良かった点・誤検知は指示文に入れない。

### 2. 指摘を実装単位に分解
各指摘について次を埋める（コードを読んで裏取りする。推測で書かない）:
- **対象ファイル**: 実在する相対パス（grep / Read で確認）
- **現状**: 今どうなっているか（1行）
- **直し方**: 具体的な変更内容（どの関数・どの設定に何を足す）
- **完了条件**: 何が緑になれば直ったと言えるか（検証可能な形で）
- **優先度**: critical / high / medium / low（攻撃シナリオの実害で決める）

### 3. 優先度を付ける
- データ漏洩・認可突破・秘密露出に直結 = critical/high。
- ヘッダ・レート制限・dev依存の更新 = medium/low。
- 認可系の severity は enforcement 層を確認してから決める（断定せず、確信度を添える）。

### 4. 指示文を書き出す
`<対象>/docs/security/hardening-plan-<project>-<date>.md` に出す。
実装エージェントにそのまま渡せる形。優先度順。各タスクは独立して着手できる粒度にする。

### 5. hardening-<project>.md に反映
各章の「要対応」に、作った指示文タスクへの対応を1行で紐づける。

# 出力テンプレート

```md
# セキュリティ強化 実装指示文: <project> (<date>)

元: static-report-<...> / dynamic-report-<...> / hardening-<project>.md
これは実装指示文。Claude Code / Codex にタスク単位で渡す。1件直すごとに完了条件を確認する。

## 概要
- critical: <n> / high: <n> / medium: <n> / low: <n>

## タスク（優先度順）

### [critical] <タイトル>
- 対象: `<file:line>`
- 現状: <...>
- 直し方: <...（具体的な変更。コード片は最小限、やることを言葉で）>
- 完了条件: <検証可能な形。例: 他人の shop_id で叩くと 403>
- 攻撃シナリオ: <誰が・どうやって・何を取れるか>

### [high] <タイトル>
...

## 実装後の検証
- 各タスクの完了条件を満たす
- `npm run typecheck && lint && test && build` 緑
- 静的チェック再実行で新規重大ゼロ
- 動的: staging で authn/authz/rls 再回帰 + ZAP 再スキャン
```

# 停止ゲート

- コード本体は直さない（このスキルは指示文まで）。実装は別。
- 指摘が1つも無い（レポート未生成）なら、指示文を捏造せず「先に検査を」と伝えて止まる。
- 認可の severity を断定できないときは候補＋根拠＋確信度で出す（二段階）。

# 実行モデルティア

推奨: **deep**。優先度付けと直し方の具体化は判断の質が要る。
