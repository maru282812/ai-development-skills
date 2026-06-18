---
name: screen-design-architect
description: >-
  requirements-discovery の成果物を入力に、必要画面・画面遷移・画面状態・UI構成・
  共通コンポーネント・Google Stitch 用プロンプトを生成し、Stitch 出力 /
  ユーザーフィードバック / ui-ux-review を使って UI設計を最適になるまで反復改善するスキル。
  目的は画面を作ることではなく「実装後に必要画面・必要導線・必要状態が発覚する手戻り」を減らすこと。
  トリガー例: 「画面を設計して」「必要な画面を洗い出して」「画面遷移を作って」
  「Stitch用のプロンプトを作って」「UI設計をレビューして直して」「画面の抜け漏れを確認して」。
  このスキルは要件探索をしない（それは requirements-discovery）。要件→画面・導線・状態・UI仕様への変換と
  反復改善に特化する。UI確定後は feature-spec-writer → implementation-planner へ渡す。
---

# Purpose

requirements-discovery の成果物を入力にして、要件を **画面・導線・状態・UI仕様** へ変換し、実装に入る前に UI設計を確定させる。

本プロジェクトの手戻りの主因は DB / API / 実装の不足ではなく、**「実装後に必要画面・必要導線・必要状態が発覚すること」** である。このスキルはそれを実装前に潰す。

本プロジェクトは MVP を最終目標にしない。理想形を先に洗い出し、その後 MVP / Phase2 / 将来候補 に分類する思想を採る。したがって工程は次の通り：

```
requirements-discovery → 画面設計 → 画面レビュー → 画面改善 → 画面確定 → 仕様化 → 実装
```

このスキルは [[requirements-discovery]] と [[feature-spec-writer]] の間を埋める。

# このスキルの責務

- **要件探索はしない**（それは [[requirements-discovery]]）。確定済みの要件を受け取り、画面・導線・状態・UI仕様へ変換する。
- 参考HP / 参考アプリ / 参考画像 / アップロード写真を使い、情報設計・導線・デザイン方針を決定する。
- Google Stitch の出力、ユーザーコメント、[[ui-ux-review]] の結果を入力として、UI設計を最適になるまで反復改善する。
- Google Stitch は **画面生成ツール** として使うだけ。画面漏れ検出・要件カバレッジ・状態カバレッジ・導線カバレッジ・コメント反映・品質保証は **このスキルが担当する**。Stitch の出力のみを仕様として扱ってはいけない。

# 基本方針

- このスキルは1回出力して終わらない。[[agent-tester]] / [[agent-planner]] と同じ思想で **Test → Report → Planning → 修正 → 反復** を回す。
- 理想形を先に洗い出してから MVP / Phase2 / 将来候補 に分類する。最初から MVP に絞らない。
- 未確定は勝手に確定しない。`open-questions` 相当は requirements-discovery 側へ差し戻すか、notes に残す。
- ユーザーコメントは原文引用し、解釈・反映先・修正内容・修正後Stitchプロンプトを必ず出す（[コメント対応ルール](#コメント対応ルール)）。
- 既存コード / DB / API / UI には一切変更を加えない（このスキルは設計と文書化のみ）。

## 絶対ルール（参考サイトの扱い）

参考サイトは最大限尊重する。ただし **ロゴ・文章・写真の無断コピーは禁止**。

寄せてよい対象は **情報設計・導線・レイアウト・CTA位置・余白・配色傾向・雰囲気** のみ。

# When To Use

- requirements-discovery で要件が固まり、次に画面・導線・UIを設計したい
- 実装後に「この画面・この導線・この状態が必要だった」と発覚する手戻りを減らしたい
- Google Stitch に渡すプロンプトを、画面漏れ・状態漏れがない形で用意したい
- Stitch 出力やユーザーコメントを受けて UI設計を反復改善したい

UI が確定したら [[feature-spec-writer]] で実装仕様書化、[[implementation-planner]] で実装手順分解へ進む。

# 入力

## requirements-discovery の成果物

- `requirements/requirements.md`
- `requirements/requirements-checklist.md`
- `requirements/screen-catalog-draft.md`
- `open-questions.md`
- `requirements/comment-resolution-log.md`

## 追加情報（ユーザーから受け取る。不足は表で確認し、推測で埋めない）

- 参考HP URL / 参考アプリ / 参考画像 / 写真
- 絶対に寄せたいUI / 避けたいUI
- 業種 / 対象ユーザー
- MVP / Phase2 / 将来候補 の分類方針

# 進め方（運用フロー）

このスキルは反復型。1サイクルは次の流れで進む。

```
入力整理
 → 成果物生成（10ファイル）
 → UI Test Phase（カバレッジ検査）
 → UI Test Report（Critical/High/Medium/Low）
 → UI Planning Phase（修正優先順位 + 修正用Stitchプロンプト）
 → Stitch 修正 / ユーザーコメント / ui-ux-review
 → 成果物更新（反復）
 → UI確定条件をすべて満たす → 確定
```

- 成果物の Stitch プロンプトは英語、補足説明は日本語。1つのプロンプトに全画面を詰め込まない。
- [再生成ルール](#再生成ルール) のいずれかに該当する間は、改善案を再出力し続ける。

# 必須成果物（10ファイル）

## 1. screen-catalog.md — 全画面一覧

| screen_id | screen_name | purpose | user_role | priority | source_requirement | main_display_items | main_actions | related_screens | reference_hp_elements | notes |
|---|---|---|---|---|---|---|---|---|---|---|

## 2. user-flow-map.md — 導線設計

最低限、次の導線を作成する：顧客導線 / スタッフ導線 / 管理者導線 / 未ログイン導線 / エラー導線。

## 3. requirement-screen-traceability.md — 要件と画面の対応表

| requirement_id | requirement_summary | related_screen | related_action | related_state | covered_status | missing_reason | priority |
|---|---|---|---|---|---|---|---|

## 4. screen-state-matrix.md — 全画面の状態定義

最低限の状態：normal / empty / loading / validation_error / error / forbidden / success / read_only / draft / published / archived / conflict。

## 5. screen-specs.md — 画面詳細仕様

各画面ごとに：画面目的 / 対象ユーザー / 表示項目 / 入力項目 / 操作ボタン / CTA / バリデーション / エラー表示 / 空状態 / 完了状態 / スマホ表示 / PC表示 / 参考HPから寄せる点 / コピー禁止項目。

## 6. component-inventory.md — 共通コンポーネント一覧

例：ヘッダー / フッター / CTAボタン / カード / テーブル / フォーム / モーダル / ステッパー / タブ / アラート / バッジ / ギャラリー / 予約導線。

## 7. design-system-brief.md — デザイン方針

含める内容：全体トーン / 色 / 余白 / フォント感 / 写真の使い方 / CTA方針 / セクション構成 / NG表現 / コピー禁止対象。

## 8. stitch-prompt.md — Google Stitch 用プロンプト

以下を **分割して** 生成する（1つに全画面を詰めない）：全体デザイン / トップページ / 主要導線 / 管理画面 / モバイル版 / 修正版。

Stitch プロンプトは **英語**、補足説明は **日本語**。

## 9. ui-acceptance-checklist.md — UI完成判定

確認項目：全要件が画面に対応 / 全画面に状態がある / 導線が成立 / スマホ対応 / 管理画面が存在 / エラー状態がある / 空状態がある / 完了状態がある / 参考HPに十分寄っている / コピー禁止要素を使っていない / feature-spec-writer へ渡せる。

## 10. stitch-feedback-log.md — フィードバック管理

| feedback_id | target_screen | user_comment | interpretation | action | affected_spec | status | remaining_issue |
|---|---|---|---|---|---|---|---|

# UI Test Phase

毎サイクル、次のカバレッジを検査する。

- **要件カバレッジ**: 全要件が画面へ紐付いているか / 未対応要件がないか
- **画面カバレッジ**: 一覧 / 詳細 / 作成 / 編集 / 確認 / 完了 / 設定 / エラー が存在するか
- **状態カバレッジ**: normal / empty / loading / validation_error / error / forbidden / success が存在するか
- **導線カバレッジ**: 顧客 / スタッフ / 管理者 の導線が成立するか
- **運用カバレッジ**: 通知 / 履歴 / 権限 / 複製 / ロールバック が考慮されているか

# UI Test Report

毎サイクル出力する。Critical / High / Medium / Low に分類する。

```
Critical
- 予約変更導線が存在しない

High
- 管理画面エラー導線が存在しない

Medium
- スマホCTAが弱い

Low
- テーブルソート未定義
```

# UI Planning Phase

UI Test Report を受け取り、修正優先順位を決める。各優先度ごとに次を出す。

```
Priority 1
- 問題
- 理由
- 修正方針
- 影響画面
- 修正用Stitchプロンプト

Priority 2 ...
Priority 3 ...
```

# コメント対応ルール

ユーザーコメントを受けたら、**必ず** 次を出力する。

- 原文引用
- 解釈（interpretation）
- 反映先（affected_screen / affected_spec）
- 修正内容（action）
- 修正後Stitchプロンプト

記録は `stitch-feedback-log.md` の表に残す（feedback_id / target_screen / user_comment / interpretation / action / affected_spec / status / remaining_issue）。

# 再生成ルール

次のいずれかが存在する間は、改善案を再出力する。

- Critical > 0
- High > 0
- 未反映コメントあり
- 未対応要件あり
- 未対応状態あり

# UI設計完了条件

以下を **すべて** 満たすこと。

1. `requirement-screen-traceability.md` で全要件が画面へ紐付いている
2. `screen-state-matrix.md` で全画面に必要状態がある
3. UI Test Report の Critical = 0
4. UI Test Report の High = 0
5. 未反映コメント = 0
6. `ui-acceptance-checklist.md` 全項目通過
7. ユーザー承認

# 最終開発フロー

```
requirements-discovery
 → screen-design-architect
 → Google Stitch
 → ui-ux-review
 → UI Test Report
 → UI Planning Phase
 → Stitch修正
 → 反復改善
 → UI確定
 → feature-spec-writer
 → implementation-planner
 → Claude Code
 → agent-tester
 → agent-planner
 → 反復改善
 → 完成
```

# Output Template

各成果物のひな形。

### screen-catalog.md

```md
# 画面カタログ
| screen_id | screen_name | purpose | user_role | priority | source_requirement | main_display_items | main_actions | related_screens | reference_hp_elements | notes |
|---|---|---|---|---|---|---|---|---|---|---|
```

### user-flow-map.md

```md
# 導線設計

## 顧客導線
（入口 → … → 完了。分岐・エラーも明示）

## スタッフ導線
## 管理者導線
## 未ログイン導線
## エラー導線
```

### requirement-screen-traceability.md

```md
# 要件↔画面 トレーサビリティ
| requirement_id | requirement_summary | related_screen | related_action | related_state | covered_status | missing_reason | priority |
|---|---|---|---|---|---|---|---|
```

### screen-state-matrix.md

```md
# 画面状態マトリクス
| screen_id | normal | empty | loading | validation_error | error | forbidden | success | read_only | draft | published | archived | conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
```

### screen-specs.md

```md
# 画面詳細仕様

## <screen_id> <画面名>
- 画面目的:
- 対象ユーザー:
- 表示項目:
- 入力項目:
- 操作ボタン:
- CTA:
- バリデーション:
- エラー表示:
- 空状態:
- 完了状態:
- スマホ表示:
- PC表示:
- 参考HPから寄せる点:
- コピー禁止項目:
```

### component-inventory.md

```md
# 共通コンポーネント一覧
| component | 用途 | 使用画面 | 状態バリエーション | 備考 |
|---|---|---|---|---|
```

### design-system-brief.md

```md
# デザイン方針
- 全体トーン:
- 色:
- 余白:
- フォント感:
- 写真の使い方:
- CTA方針:
- セクション構成:
- NG表現:
- コピー禁止対象:
```

### stitch-prompt.md

```md
# Google Stitch プロンプト（英語本文 / 日本語補足）

## 全体デザイン
（日本語補足）
> EN: ...

## トップページ
## 主要導線
## 管理画面
## モバイル版
## 修正版
```

### ui-acceptance-checklist.md

```md
# UI完成判定チェックリスト
| # | 確認項目 | 状態(OK/NG) | 根拠/残課題 |
|---|---|---|---|
| 1 | 全要件が画面に対応している | | |
| 2 | 全画面に状態がある | | |
| 3 | 導線が成立している | | |
| 4 | スマホ対応している | | |
| 5 | 管理画面が存在する | | |
| 6 | エラー状態がある | | |
| 7 | 空状態がある | | |
| 8 | 完了状態がある | | |
| 9 | 参考HPに十分寄っている | | |
| 10 | コピー禁止要素を利用していない | | |
| 11 | feature-spec-writerへ渡せる | | |
```

### stitch-feedback-log.md

```md
# Stitch フィードバックログ
| feedback_id | target_screen | user_comment | interpretation | action | affected_spec | status | remaining_issue |
|---|---|---|---|---|---|---|---|
```

# セルフチェック

- 要件探索を始めていないか（探索は requirements-discovery）
- 全要件が画面へ紐付いているか（traceability に未対応がないか）
- 全画面に必要状態を定義したか
- 顧客 / スタッフ / 管理者 / 未ログイン / エラー の導線が成立しているか
- Stitch プロンプトを画面ごとに分割したか（1つに詰め込んでいないか）
- ロゴ / 文章 / 写真のコピーを指示していないか（寄せるのは情報設計・導線・雰囲気のみ）
- ユーザーコメントを原文引用し、反映先と修正後Stitchプロンプトを出したか
- UI Test Report を Critical/High/Medium/Low で出したか
- 既存コード / DB / API / UI に変更を加えていないか

---

関連スキル: [[requirements-discovery]]（前工程・要件探索）/ [[ui-ux-review]]（画面の使い勝手レビュー）/ [[feature-spec-writer]]（UI確定後の実装仕様書化）/ [[implementation-planner]]（実装手順分解）/ [[agent-tester]]・[[agent-planner]]（実装後の反復改善・思想の参照元）。
