# 受け側スキルの生成テンプレート

機能ごとに作る「受け側スキル」(Claude Code / Codex に貼られて動くスキル) の雛形。
参照実装は AI Testmaster の testmaster-test-plan / testmaster-run-api / testmaster-run-screen。

## 設計原則

- **責務は一本道**: ID で対象を GET → サブスクで処理 → 結果を POST で書き戻し → 状態を進める。
- **自分が実行できる対象だけ処理する**: GET で取った対象のうち、このスキルが扱える種別だけ処理し、扱えないものは飛ばす（別の受け側スキルに任せる）。これにより「API契約系」「画面系」のように受け側を分割できる（testmaster-run-api / testmaster-run-screen の関係）。
- **冪等**: 同じ対象を二度処理しても二重書き込みにならないようにする（処理済みは飛ばす／upsert する）。
- **書き戻しは構造化**: 合否・結果・証跡を決まった形で POST する。サイトはそれを表示するだけ。
- **サブスクで完結**: ここが API 課金を回避する本体。重い推論はこのスキルを動かすエージェント（Claude Code / Codex）が行う。

## 分割の判断

処理が重い/種別が異なる場合は受け側を複数スキルに分ける:
- 生成・計画系（分母を作る） → `<feature>-plan`
- 実行・検証系 → `<feature>-run`（さらに API系 / 画面系 に割れるなら `-run-api` / `-run-screen`）

MVP は 1 本（`<feature>-run`）で始め、必要になったら割る。

## SKILL.md 雛形

```md
---
name: <feature>-run
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
description: >-
  <機能名> の対象を ID で取得し、サブスク側(Claude Code / Codex)で<重い処理>を実行して
  結果を書き戻すスキル。API 課金を使わない。
  トリガー例:「<feature> の対象を処理して書き戻して」「studyId を渡すので解析して」
  「<feature>-run を実行して」。GET /api/<resource>/{id} で対象を取得し、
  自分が処理できる対象だけ実行、POST /api/<resource>/{id}/<writeback> で書き戻す。
---

# Purpose
<機能名> の対象を取得し、サブスクで <重い処理> を行い、結果を書き戻す。
サイトは LLM を呼ばない。重い処理はこのスキルを動かすエージェントが担う（=API課金回避）。

# Inputs
- 対象ID（例: studyId）
- API ベースURL
- 認証トークン（必要なら環境変数 / ユーザー貼り付け）

# Procedure
### 1. 対象を取得
- `GET /api/<resource>/{id}`（または status=未処理 で一覧取得）
- 処理に必要な情報が揃っているか確認。欠けていれば中断して報告する。

### 2. 処理できる対象を選別
- このスキルが扱える種別だけ残す。扱えないものは「別スキル対象」として飛ばす。
- 処理済み（status=処理済）は飛ばす（冪等）。

### 3. サブスクで処理
- <解析 / 生成 / 検証 の具体手順>
- 出力を書き戻し用の構造（合否 / 結果 / 証跡）に整える。

### 4. 書き戻し
- `POST /api/<resource>/{id}/<writeback>` に結果を送る。
- 成功で対象の status を前進。失敗時は失敗状態＋理由を残す。

### 5. 完了報告
- 何件処理 / 何件スキップ / 何件失敗 をユーザーに要約する。

# 注意
- 二重書き込み防止（同じIDの再実行で壊れない）
- API キーをサイト側に置かない（この方式の前提）
- 大量件数は分割実行し、途中失敗から再開できるようにする
```

## 配置とミラー

原本は `.skills/<feature>-run/` に置き、`.agents/skills/`・`.claude/skills/` にミラーする
（[[skills-directory-layout]] の規約）。受け側スキルは対象アプリ側のリポジトリに置く場合もある
（testmaster-* は AI Testmaster 側に存在）——どこに置くかはユーザーと決める。
