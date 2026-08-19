---
name: verification-loop
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, Skill
metadata:
  reasoning-tier: standard
  summary: "実装後の実行時検証ループ担当。docs/VERIFY.md のレシピに従い Gates（typecheck/lint/test/build）→ Runtime Verify（dev server起動・画面表示・主要操作・console error・スクショ）を回し、緑になるまで軽微修正を反復、重い問題は停止。証拠付き Receipt を出す。"
description: >-
  「コードが正しい」ではなく「ユーザーから見て機能が動く」を検証するループ。
  対象 repo の docs/VERIFY.md（factory-bootstrap が設置した検証レシピ）を唯一の真実として、
  §1 Gates → §2 Runtime Verify（dev server 起動・実画面表示・主要操作・状態変化・console error・
  スクリーンショット・E2E）を実行し、NG が軽微なら修正して最初から再確認（最大2周）、
  重い（DB/認可/課金/破壊系/ロジック）なら直さず停止して報告する。
  結果は証拠付き Receipt（変更・ゲート結果・確認内容・スクショ所在）として出す。
  トリガー例:
  「実装を検証して」「動くか確認して」「verification loop を回して」「実機で確認して」
  「画面まで含めて検証して」「検証レシピどおり確認して」「Receipt を残して」。
  静的な軽量チェックと次指示の抽出は agent-tester / agent-planner、テスト台帳での網羅検証は
  testmaster 系、レシピの設置は factory-bootstrap（本スキルは実行担当）。
---

# verification-loop（実行時検証ループ）

実装直後に走り、**ユーザー視点で機能が動くこと**を検証するループ。
単に `npm test` を回すのではなく、実画面・実操作・実データまで確認して証拠を残す。

## 位置づけ（似たスキルとの違い）

| スキル | 役割 |
|---|---|
| [agent-tester](../agent-tester/SKILL.md) | 静的な軽量チェック（diff/typecheck/test/lint と影響スキャン）＋次サイクル制御 |
| **verification-loop（本スキル）** | **実行時検証**（dev server・画面・操作・console・E2E）を緑になるまで反復 |
| testmaster 系 | テスト台帳（分母）ベースの網羅検証・合否記録 |

phase-runner の各 Phase 内では「RUNTIME VERIFY」工程として本スキルの手順が使われる。

## 手順

### 1. レシピを読む

- 対象 repo の `docs/VERIFY.md` を読む。これが唯一の真実。
- **無い場合**: [factory-bootstrap](../factory-bootstrap/SKILL.md) での設置を提案しつつ、
  今回はその場で導出する（package.json の実在 scripts ＋ CLAUDE.md/README から主要フローを把握）。
  導出した内容は最後に VERIFY.md 化を提案する。

### 2. Gates（VERIFY.md §1）

- 列挙されたコマンドを順に実行する。**存在しないコマンドをでっち上げない。**
- 赤が出たら: 軽微（下記線引き）なら修正して**そのゲートの最初から**再実行。重いなら §5 へ。

### 3. Runtime Verify（VERIFY.md §2）

- dev server を起動する（`/run` スキルがあれば利用してよい）。
- 主要画面 / フローを実際に操作する。ブラウザ操作が必要なら
  webapp-testing（Playwright）を使う:
  - 画面が表示される・崩れていない（**スクリーンショットを保存**し所在を記録）
  - 主要操作が最後まで通り、**状態変化（DB/表示）まで**確認する
  - console error / network error が出ていない
- E2E がレシピにあれば実行する。
- NG が出たら: 軽微なら修正して **§2 Gates からやり直す**（修正が既存確認を壊しうるため）。
  この反復は**最大2周**。超えたら §5 へ。

### 4. Receipt を出す

検証が全緑になったら、証拠付き Receipt を出力する（phase-runner 配下で動いている場合は
phase-status.md のフェーズ別ログに転記される）:

```md
## Receipt: <対象（Phase N / 改修名）> — <日時>
- 変更ファイル: <一覧>
- Gates: <コマンド: 結果> ...（すべて緑の証拠）
- Runtime Verify:
  - 確認した画面/フロー: <内容>
  - 操作と状態変化: <内容>
  - console: エラーなし / <検出内容>
  - スクショ: <保存場所>
  - E2E: <結果 / 未整備>
- 修正した軽微NG: <内容 / なし>
- 残課題（重い・要人間判断）: <内容 / なし>
```

### 5. 停止条件（重い NG / 反復超過）

以下は**直さずに停止**し、Receipt に「残課題」として明記して報告する:

- DB/スキーマ/migration・認証認可・課金・外部連携・破壊的操作・ロジック仕様の変更が必要なもの
- 仕様が曖昧で複数解釈できるもの（人間が決める）
- 軽微修正の反復が2周を超えても緑にならないもの（失敗出力を添える）
- VERIFY.md §4 Human Gate に該当するもの

## 軽微 / 重いの線引き（phase-runner と同一哲学）

- **軽微**: UI文言・typo・明らかな小バグ・単一ファイル小diff・ロジック非変更。
- **重い**: 上記停止条件のいずれか。**テストや assert を緩めて緑にするのは禁止**（ゲート改変 = 重い）。

## やらないこと（境界）

- 機能実装・リファクタ（それは maker / phase-runner）。
- テスト台帳の生成・網羅判定（それは testmaster 系）。
- VERIFY.md の Human Gate に該当する操作の実行。
- 検証をスキップして Receipt だけ書くこと（証拠の無い Receipt を作らない）。

## 関連

レシピの設置 [factory-bootstrap](../factory-bootstrap/SKILL.md) / 自走オーケストレータ [phase-runner](../phase-runner/SKILL.md) /
静的軽量チェック [agent-tester](../agent-tester/SKILL.md) / 原因切り分け [bug-investigator](../bug-investigator/SKILL.md) /
migration 安全確認 [migration-review](../migration-review/SKILL.md)。

# 実行モデルティア

推奨ティア: **standard**（レシピ追従型）。原因不明の失敗の切り分けが必要になったら
bug-investigator へ論点を渡す。具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
