---
name: screen-design-architect
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: deep
  summary: "画面設計担当。要件成果物から必要画面・遷移・状態・UI構成・Stitch用プロンプトを生成し、Stitch出力やレビューで反復改善する。生成前に Screen Coverage Audit で網羅検査し、不足は要件へ差し戻す。"
description: >-
  project-discovery / requirements-discovery の成果物を入力に、必要画面・画面遷移・画面状態・
  UI構成・共通コンポーネント・Google Stitch 用プロンプトを生成し、Stitch 出力 /
  ユーザーフィードバック / ui-ux-review を使って UI設計を最適になるまで反復改善するスキル。
  目的は画面を作ることではなく「実装後に必要画面・必要導線・必要状態が発覚する手戻り」を減らすこと。
  画面生成の前に Screen Coverage Audit（要件・フロー・MVP境界・状態の網羅検査）を必ず通し、
  不足があれば requirements-discovery へ差し戻す。トリガー例: 「画面を設計して」「必要な画面を洗い出して」
  「画面遷移を作って」「Stitch用のプロンプトを作って」「UI設計をレビューして直して」「画面の抜け漏れを確認して」。
  このスキルは要件探索をしない（それは [[requirements-discovery]]）。要件→画面・導線・状態・UI仕様への変換、
  Stitch連携、実装引き渡し（implementation-ui-brief.md）に特化する。
  親は [[project-discovery]]。UI確定後は feature-spec-writer → implementation-planner → Claude Code 実装へ渡す。
---

# Purpose

[[project-discovery]] が生成した発見成果物を入力にして、要件を **画面・導線・状態・UI仕様** へ変換し、実装に入る前に UI設計を確定させる。

本プロジェクトの手戻りの主因は DB / API / 実装の不足ではなく、**「実装後に必要画面・必要導線・必要状態が発覚すること」** である。このスキルはそれを実装前に潰す。

このスキルの目的は **UI生成の品質向上ではなく、次のワークフローを正式に成立させること**：

```text
project-discovery
 → requirements-discovery
 → screen-design-architect
   → Screen Coverage Audit（網羅検査・不足は差し戻し）
   → Screen Catalog（user / admin 分離）
   → Flow Design
   → State Design
   → Stitch Prompt Generation（Global Design Context ＋ Screen Prompt）
 → Google Stitch
 → Stitch Review
 → Implementation UI Brief
 → Claude Code 実装
```

本プロジェクトは MVP を最終目標にしない。理想形を先に洗い出し、その後 MVP / Phase2 / 将来候補 に分類する思想を採る。

このスキルは [[project-discovery]] / [[requirements-discovery]] と [[feature-spec-writer]] の間を埋める。

# 親スキルとの関係（project-discovery が正式な親）

[[project-discovery]] は大幅に強化され、現在は次の役割を持つ。screen-design-architect はその成果物を **優先情報源** として扱う。

- 全 Discovery 成果物の統括
- `implementation-brief.md` の生成（次工程への抽出済み引き渡し情報）
- `user-flows.md` / `admin-flows.md` の生成
- requirements 群との整合管理
- `decisions.md` による意思決定管理
- [[discovery-auditor]] による横断監査

したがって screen-design-architect は **自前で要件・運営・収益を作り直さない**。project-discovery が確定した内容を起点に、画面・状態・導線・Stitch・実装引き渡しへ変換する。project-discovery の成果物と矛盾する画面を作らない。境界（Scope）や要件を変える必要が出たら、勝手に変えず差し戻す（[Screen Coverage Audit](#screen-coverage-audit画面生成前の整合性監査) 参照）。

# このスキルの責務

- **要件探索はしない**（それは [[requirements-discovery]]）。確定済みの要件を受け取り、画面・導線・状態・UI仕様へ変換する。
- **画面生成の前に整合性監査（Screen Coverage Audit）を必ず実施する**。不足があれば画面設計を開始せず、[[requirements-discovery]] へ差し戻す。
- 利用者向け画面と運営向け画面を **完全に分離** して管理する（user / admin カタログ分離）。
- 各画面の **状態（初期 / 読み込み中 / 空 / エラー / 権限不足 / 成功 …）** を明示的に設計する。Stitch 出力だけでは状態が抜けるため、ここで埋める。
- 参考HP / 参考アプリ / 参考画像 / アップロード写真を使い、情報設計・導線・デザイン方針を決定する。
- Google Stitch を **画面生成ツール** として正式に連携運用する（Global Design Context ＋ Screen Prompt、セッション記録、出力レビュー）。
- Google Stitch の出力、ユーザーコメント、[[ui-ux-review]] の結果を入力として、UI設計を最適になるまで反復改善する。画面漏れ検出・要件カバレッジ・状態カバレッジ・導線カバレッジ・コメント反映・品質保証は **このスキルが担当する**。Stitch の出力のみを仕様として扱ってはいけない。
- 最終的に **Claude Code が直接実装できる粒度** の引き渡し資料（`implementation-ui-brief.md`）を生成する。

# 基本方針

- このスキルは1回出力して終わらない。[[agent-tester]] / [[agent-planner]] と同じ思想で **Audit → Report → Planning → 修正 → 反復** を回す。
- 理想形を先に洗い出してから MVP / Phase2 / 将来候補 に分類する。最初から MVP に絞らない。
- 未確定は勝手に確定しない。`open-questions` 相当は [[requirements-discovery]] / [[project-discovery]] 側へ差し戻すか、notes に残す。
- ユーザーコメントは原文引用し、解釈・反映先・修正内容・修正後Stitchプロンプトを必ず出す（[コメント対応ルール](#コメント対応ルール)）。
- 既存コード / DB / API / UI には一切変更を加えない（このスキルは設計と文書化のみ）。

## 絶対ルール（参考サイトの扱い）

参考サイトは最大限尊重する。ただし **ロゴ・文章・写真の無断コピーは禁止**。

寄せてよい対象は **情報設計・導線・レイアウト・CTA位置・余白・配色傾向・雰囲気** のみ。

# When To Use

- [[project-discovery]] / [[requirements-discovery]] で要件が固まり、次に画面・導線・UIを設計したい
- 実装後に「この画面・この導線・この状態が必要だった」と発覚する手戻りを減らしたい
- Google Stitch に渡すプロンプトを、画面漏れ・状態漏れがない形で用意したい
- Stitch 出力やユーザーコメントを受けて UI設計を反復改善したい

UI が確定したら [[feature-spec-writer]] で実装仕様書化、[[implementation-planner]] で実装手順分解へ進む。

# 入力

project-discovery が生成した内容を **優先情報源** として扱う。全ドキュメントを読み込まず、UI設計に必要なものを使う。

## 必須入力

| ファイル | 用途 | 生成元 |
|---|---|---|
| `implementation-brief.md` | UI設計向けに抽出済みの引き渡し情報・確定前提・禁止事項 | [[project-discovery]] |
| `requirements/requirements.md` | 確定要件・理想形 | [[requirements-discovery]] |
| `requirements/requirements-checklist.md` | Stage別の全要件・優先度 | [[requirements-discovery]] |
| `requirements/screen-catalog-draft.md` | 画面カタログ草案（正式カタログの起点） | [[requirements-discovery]] |
| `scope/users.md` | 利用者区分（user / admin 分離と権限設計の基準） | [[scope-discovery]] |
| `scope/mvp-boundary.md` | MVP範囲 / 後回し / 将来構想（MVP境界判定の基準） | [[scope-discovery]] |

必須入力が欠けている場合は画面設計を始めず、[[project-discovery]] に生成を依頼する。

## 条件付き入力（存在すれば優先して使う）

| ファイル | 用途 |
|---|---|
| `user-flows.md` | 利用者導線。User Flow 完走判定の基準 |
| `admin-flows.md` | 管理導線。Admin Flow 完走判定の基準 |
| `decisions.md` | 決定 / 保留 / 仮置き。仮置き(assumption)を画面に確定として持ち込まない |
| `open-questions.md` | 未確定事項。未解決を画面で勝手に確定しない |

## 追加情報（ユーザーから受け取る。不足は表で確認し、推測で埋めない）

- 参考HP URL / 参考アプリ / 参考画像 / 写真
- 絶対に寄せたいUI / 避けたいUI
- 業種 / 対象ユーザー / ブランドトーン
- デバイス方針（PC / スマホ / 両対応） / アクセシビリティ方針
- MVP / Phase2 / 将来候補 の分類方針

# 進め方（運用フロー）

このスキルは反復型。1サイクルは次の流れで進む。

```text
入力整理（必須入力の充足確認）
 → Screen Coverage Audit（網羅検査）
    ├─ 不足あり → requirements-discovery / project-discovery へ差し戻し（画面設計を始めない）
    └─ 充足   → 次へ
 → Screen Catalog 生成（screen-catalog ＋ user / admin 分離）
 → Flow Design（user-flow-map）
 → State Design（screen-state-matrix）
 → 画面詳細・コンポーネント・デザイン方針
 → Stitch Prompt 生成（Global Design Context ＋ Screen Prompt）
 → Google Stitch 実行（stitch-session に記録）
 → Stitch Review（stitch-review）
 → Implementation UI Brief 生成
 → UI Test Report（Critical/High/Medium/Low）
 → UI Planning Phase（修正優先順位 ＋ 修正用Stitchプロンプト）
 → ユーザーコメント / ui-ux-review を反映して反復
 → UI確定条件をすべて満たす → 確定
```

- 成果物の Stitch プロンプトは英語、補足説明は日本語。1つのプロンプトに全画面を詰め込まない。
- [再生成ルール](#再生成ルール) のいずれかに該当する間は、改善案を再出力し続ける。

# Screen Coverage Audit（画面生成前の整合性監査）

**画面を作る前に必ず実施する。** ここを飛ばして画面生成に入ってはいけない。[[agent-tester]] の「軽量に検証して止める」思想を UI設計に移植したゲート。

## 確認対象

| # | 検査項目 | 合格条件 | 不合格時の差し戻し先 |
|---|---|---|---|
| 1 | 要件カバレッジ | 全要件（requirements-checklist の必須項目）に対応画面が存在する | [[requirements-discovery]] |
| 2 | User Flow 完走 | `user-flows.md` の各導線が入口→完了まで画面で繋がる | [[requirements-discovery]] / [[project-discovery]] |
| 3 | Admin Flow 完走 | `admin-flows.md` の各管理導線が完走できる | [[project-discovery]]（Phase4 Admin） |
| 4 | MVP境界整合 | `scope/mvp-boundary.md` の範囲外画面を含んでいない | [[scope-discovery]] |
| 5 | 状態網羅の前提 | 各画面に必要な状態（特にエラー / 空 / 権限不足）が設計可能な情報が揃っている | [[requirements-discovery]] |
| 6 | 仮置きの混入 | `decisions.md` の未昇格 assumption を確定UIとして持ち込んでいない | [[project-discovery]] |

## 判定の出し方

```text
## Screen Coverage Audit 結果
- 要件カバレッジ: <x/y> 対応 / 未対応: <要件ID...>
- User Flow 完走: 可 / 不可（不可導線: ...）
- Admin Flow 完走: 可 / 不可（不可導線: ...）
- MVP境界: 整合 / 範囲外画面あり（...）
- 状態前提: 充足 / 不足（不足画面: ...）
- 仮置き混入: なし / あり（decision id: ...）
- 判定: 合格（画面設計開始可） / 不合格（差し戻し → <差し戻し先>）
```

**不足がある場合は画面設計を開始しない。** 差し戻し対象と理由を明示し、ユーザーに差し戻しか暫定続行（リスク明記）かを選ばせる。捏造で穴を埋めない。

# 必須成果物（`screen-design/` 配下）

成果物は `screen-design/` 配下に置く（project-discovery の成果物ツリーと並列）。

## 1. screen-coverage-audit.md — 整合性監査レポート

[Screen Coverage Audit](#screen-coverage-audit画面生成前の整合性監査) の結果と差し戻し履歴を記録する。毎サイクル更新する。

## 2. screen-catalog.md — 全画面マスター（正式成果物）

画面カタログを **正式成果物** とする。最低限、次の必須項目を持つ。

| ID | 画面名 | 種別 | MVP | 作成理由 |
|---|---|---|---|---|

- **種別**: `User` / `Admin` / `Public` / `Internal` を必ず明示する。
- **MVP**: `MVP` / `Phase2` / `将来` のいずれか。
- **作成理由**: どの要件・導線から必要になったか（source_requirement へのトレース）。

実務上は次の拡張列も持たせてよい：`purpose` / `user_role` / `source_requirement` / `main_display_items` / `main_actions` / `related_screens` / `reference_hp_elements` / `notes`。

## 3. user-screen-catalog.md — 利用者向け画面カタログ

種別 `User` / `Public` の画面のみを抽出して管理する。利用者導線で完走できる画面集合を明確にする。

## 4. admin-screen-catalog.md — 運営向け画面カタログ

種別 `Admin` / `Internal` の画面のみを抽出して管理する。管理者・スタッフの権限と運営フローを完走できる画面集合を明確にする。

> user と admin を曖昧にせず **完全に分離** する。screen-catalog.md がマスター、user/admin カタログはそのビュー。

## 5. user-flow-map.md — 導線設計

最低限、次の導線を作成する：顧客導線 / スタッフ導線 / 管理者導線 / 未ログイン導線 / エラー導線。各導線は入口→完了まで、分岐・エラーも明示する。`user-flows.md` / `admin-flows.md` を基準にし、画面ID で接続する。

## 6. requirement-screen-traceability.md — 要件↔画面トレーサビリティ

| requirement_id | requirement_summary | related_screen | related_action | related_state | covered_status | missing_reason | priority |
|---|---|---|---|---|---|---|---|

## 7. screen-state-matrix.md — 状態設計（必須成果物）

state-matrix を **必須成果物** として扱う。各画面について次の状態を定義する。Stitch 出力だけではここが抜けるため、必ず明示する。

- 初期状態（normal）
- 読み込み中（loading）
- 空状態（empty）
- エラー状態（error）
- 権限不足（forbidden）
- 成功状態（success）

加えて該当する画面には：validation_error / read_only / draft / published / archived / conflict も定義する。

## 8. screen-specs.md — 画面詳細仕様

各画面ごとに：画面目的 / 対象ユーザー / 表示項目 / 入力項目 / 操作ボタン / CTA / バリデーション / エラー表示 / 空状態 / 完了状態 / 権限不足表示 / スマホ表示 / PC表示 / 参考HPから寄せる点 / コピー禁止項目。

## 9. component-inventory.md — 共通コンポーネント一覧

例：ヘッダー / フッター / CTAボタン / カード / テーブル / フォーム / モーダル / ステッパー / タブ / アラート / バッジ / ギャラリー / 予約導線。各コンポーネントの状態バリエーションも記す。

## 10. design-system-brief.md — デザイン方針

含める内容：全体トーン / 色 / 余白 / フォント感 / 写真の使い方 / CTA方針 / セクション構成 / NG表現 / コピー禁止対象 / デバイス方針 / アクセシビリティ方針。

## 11. stitch-prompt.md — Google Stitch 用プロンプト

**Global Design Context ＋ Screen Prompt** の2層構成で生成する（[Stitch Prompt 仕様](#stitch-prompt-仕様)）。1つのプロンプトに全画面を詰めない。本文は **英語**、補足説明は **日本語**。

## 12. stitch-session.md — Stitch セッション記録

Stitch 実行を記録する。記録項目：Stitch URL / Stitch Session ID / 作成日時 / 使用プロンプト / 対象画面 / バージョン / 作成者。

## 13. stitch-review.md — Stitch 出力レビュー

Stitch の生成結果を構造的にレビューする。記録内容：生成結果評価 / 画面漏れ / 状態漏れ / 要件未対応 / UX課題 / 修正指示。

## 14. implementation-ui-brief.md — 実装引き渡し（Claude Code 直結）

Claude Code が直接実装できる粒度で出力する。内容：全画面一覧 / 遷移一覧 / コンポーネント一覧 / 状態一覧 / API依存 / 権限依存。

## 15. ui-acceptance-checklist.md — UI完成判定

[UI設計完了条件](#ui設計完了条件) の各項目を OK/NG と根拠で埋める。

## 16. stitch-feedback-log.md — フィードバック管理（反復ログ）

ユーザーコメントの反映を時系列で記録する（stitch-review.md が1出力単位の評価なのに対し、これは反復のログ）。

| feedback_id | target_screen | user_comment | interpretation | action | affected_spec | status | remaining_issue |
|---|---|---|---|---|---|---|---|

# Stitch Prompt 仕様

Stitch 連携を正式仕様化する。プロンプトは **Global Design Context（1本）＋ Screen Prompt（画面ごと）** の2層で構成する。

## Global Design Context（全体・1本）

全画面共通の前提。必ず先頭に置く。

- サービス概要（service overview）
- ターゲット（target users）
- ブランドトーン（brand tone）
- デバイス方針（device strategy: PC / mobile / both）
- アクセシビリティ方針（accessibility policy）
- 管理画面の有無（admin surface: yes/no）
- MVP範囲（MVP scope: 何を含み何を含まないか）

## Screen Prompt（画面ごと）

画面1枚ごとに次を明記する。

- 目的（purpose）
- ユーザー（user / role）
- 入力（inputs）
- 出力（outputs）
- CTA
- 状態（states: 初期 / 読み込み中 / 空 / エラー / 権限不足 / 成功）
- 必須コンポーネント（required components）

> 状態を Screen Prompt に書き込むことで、Stitch 出力での状態漏れを構造的に防ぐ。

# Stitch 連携運用フロー

```text
stitch-prompt.md（Global Design Context ＋ Screen Prompt）
 → Google Stitch で生成
 → stitch-session.md に記録（URL / Session ID / 日時 / プロンプト / 対象画面 / バージョン / 作成者）
 → stitch-review.md でレビュー（生成結果評価 / 画面漏れ / 状態漏れ / 要件未対応 / UX課題 / 修正指示）
 → 修正指示を修正用 Stitch Prompt に反映
 → 再生成（バージョンを上げて stitch-session に追記）
 → Critical / High が消えるまで反復
```

# UI Test Phase

毎サイクル、次のカバレッジを検査する。

- **要件カバレッジ**: 全要件が画面へ紐付いているか / 未対応要件がないか
- **画面カバレッジ**: 一覧 / 詳細 / 作成 / 編集 / 確認 / 完了 / 設定 / エラー が存在するか
- **状態カバレッジ**: 初期 / 空 / 読み込み中 / バリデーションエラー / エラー / 権限不足 / 成功 が存在するか
- **導線カバレッジ**: 顧客 / スタッフ / 管理者 の導線が成立するか
- **運用カバレッジ**: 通知 / 履歴 / 権限 / 複製 / ロールバック が考慮されているか
- **分離カバレッジ**: user 画面と admin 画面が分離され、各カタログが完走可能か

# UI Test Report

毎サイクル出力する。Critical / High / Medium / Low に分類する。

```text
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

```text
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

- Screen Coverage Audit が不合格
- Critical > 0
- High > 0
- 未反映コメントあり
- 未対応要件あり
- 未対応状態あり
- Stitch Review に未解消の画面漏れ / 状態漏れ / 要件未対応あり

# UI設計完了条件

以下を **すべて** 満たした場合のみ完了とする。「画面一覧が作れた」では完了にしない。

1. **要件カバレッジ 100%**（`requirement-screen-traceability.md` で全要件が画面へ紐付く）
2. **User Flow 完走可能**（`user-screen-catalog.md` ＋ `user-flow-map.md`）
3. **Admin Flow 完走可能**（`admin-screen-catalog.md` ＋ `user-flow-map.md` の管理導線）
4. **MVP境界が明確**（`screen-catalog.md` の MVP 列が全画面で確定）
5. **状態定義完了**（`screen-state-matrix.md` で全画面に必要状態がある）
6. **Stitch Prompt 作成済**（Global Design Context ＋ 全対象画面の Screen Prompt）
7. **Stitch Review 完了**（`stitch-review.md` の画面漏れ / 状態漏れ / 要件未対応 = 0）
8. **実装引き渡し資料完成**（`implementation-ui-brief.md` が全画面 / 遷移 / コンポーネント / 状態 / API依存 / 権限依存を網羅）
9. UI Test Report の Critical = 0 / High = 0
10. 未反映コメント = 0
11. `ui-acceptance-checklist.md` 全項目通過 ＋ ユーザー承認

# 最終開発フロー

```text
project-discovery
 → requirements-discovery
 → screen-design-architect
    → Screen Coverage Audit
    → Screen Catalog（user / admin 分離）
    → Flow Design
    → State Design
    → Stitch Prompt Generation
 → Google Stitch
 → Stitch Review
 → Implementation UI Brief
 → ui-ux-review / UI Test Report / UI Planning Phase
 → Stitch修正 → 反復改善 → UI確定
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

### screen-coverage-audit.md

```md
# Screen Coverage Audit
## サイクル <n>（<日付>）
- 要件カバレッジ: <x/y> / 未対応: <要件ID...>
- User Flow 完走: 可 / 不可（...）
- Admin Flow 完走: 可 / 不可（...）
- MVP境界: 整合 / 範囲外画面あり（...）
- 状態前提: 充足 / 不足（...）
- 仮置き混入: なし / あり（decision id: ...）
- 判定: 合格 / 不合格（差し戻し → ...）
## 差し戻し履歴
| # | 差し戻し先 | 理由 | 状態 |
|---|---|---|---|
```

### screen-catalog.md

```md
# 画面カタログ（マスター）
| ID | 画面名 | 種別 | MVP | 作成理由 | purpose | user_role | source_requirement | main_display_items | main_actions | related_screens | reference_hp_elements | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

種別: User / Admin / Public / Internal
MVP: MVP / Phase2 / 将来
```

### user-screen-catalog.md

```md
# 利用者向け画面カタログ（種別 User / Public）
| ID | 画面名 | MVP | 作成理由 | related_screens | notes |
|---|---|---|---|---|---|
```

### admin-screen-catalog.md

```md
# 運営向け画面カタログ（種別 Admin / Internal）
| ID | 画面名 | MVP | 必要権限 | 作成理由 | related_screens | notes |
|---|---|---|---|---|---|---|
```

### user-flow-map.md

```md
# 導線設計
## 顧客導線（入口 → … → 完了。分岐・エラーも明示。画面IDで接続）
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
| screen_id | normal(初期) | loading(読込中) | empty(空) | error(エラー) | forbidden(権限不足) | success(成功) | validation_error | read_only | draft | published | archived | conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
```

### screen-specs.md

```md
# 画面詳細仕様
## <ID> <画面名>
- 画面目的:
- 対象ユーザー:
- 表示項目:
- 入力項目:
- 操作ボタン:
- CTA:
- バリデーション:
- エラー表示:
- 空状態:
- 権限不足表示:
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
- デバイス方針:
- アクセシビリティ方針:
- NG表現:
- コピー禁止対象:
```

### stitch-prompt.md

```md
# Google Stitch プロンプト（英語本文 / 日本語補足）

## Global Design Context
（日本語補足）
> EN: Service overview / Target users / Brand tone / Device strategy /
>     Accessibility policy / Admin surface (yes-no) / MVP scope ...

## Screen Prompt: <ID> <画面名>
（日本語補足）
> EN: Purpose / User(role) / Inputs / Outputs / CTA /
>     States (initial, loading, empty, error, forbidden, success) /
>     Required components ...

## Screen Prompt: <ID> ...
## 修正版: <ID>（Stitch Review 反映）
```

### stitch-session.md

```md
# Stitch セッション記録
| version | stitch_url | session_id | 作成日時 | 対象画面 | 使用プロンプト(参照) | 作成者 |
|---|---|---|---|---|---|---|
```

### stitch-review.md

```md
# Stitch 出力レビュー
## version <v> / 対象画面 <...>
- 生成結果評価:
- 画面漏れ:
- 状態漏れ:
- 要件未対応:
- UX課題:
- 修正指示:（→ 修正用 Stitch Prompt へ）
```

### implementation-ui-brief.md

```md
# 実装UIブリーフ（Claude Code 引き渡し）
## 全画面一覧
| ID | 画面名 | 種別 | MVP | ルート(案) |
|---|---|---|---|---|
## 遷移一覧
| from | to | トリガー | 条件/権限 |
|---|---|---|---|
## コンポーネント一覧
| component | 使用画面 | 状態 |
|---|---|---|
## 状態一覧
| screen_id | 必要状態 |
|---|---|
## API依存
| screen_id | 必要データ/操作 | 依存(想定) |
|---|---|---|
## 権限依存
| screen_id | 必要ロール/権限 |
|---|---|
```

### ui-acceptance-checklist.md

```md
# UI完成判定チェックリスト
| # | 確認項目 | 状態(OK/NG) | 根拠/残課題 |
|---|---|---|---|
| 1 | 要件カバレッジ100% | | |
| 2 | User Flow 完走可能 | | |
| 3 | Admin Flow 完走可能 | | |
| 4 | MVP境界が明確 | | |
| 5 | 全画面に状態定義がある | | |
| 6 | Stitch Prompt 作成済（Global＋Screen） | | |
| 7 | Stitch Review 完了（漏れ0） | | |
| 8 | implementation-ui-brief 完成 | | |
| 9 | Critical=0 / High=0 | | |
| 10 | 未反映コメント=0 | | |
| 11 | コピー禁止要素を利用していない | | |
| 12 | feature-spec-writer へ渡せる | | |
```

### stitch-feedback-log.md

```md
# Stitch フィードバックログ
| feedback_id | target_screen | user_comment | interpretation | action | affected_spec | status | remaining_issue |
|---|---|---|---|---|---|---|---|
```

# セルフチェック

- 画面生成の前に Screen Coverage Audit を通したか（不足なら差し戻したか）
- 必須入力（implementation-brief / requirements 群 / scope/users / scope/mvp-boundary）を起点にしたか
- project-discovery の確定内容と矛盾する画面を作っていないか / 未昇格の仮置きを確定UIにしていないか
- user 画面と admin 画面を完全に分離したか（user/admin カタログが完走可能か）
- screen-catalog.md に ID / 画面名 / 種別 / MVP / 作成理由 を埋めたか（種別は User/Admin/Public/Internal）
- 全画面に状態（初期 / 読込中 / 空 / エラー / 権限不足 / 成功）を定義したか
- Stitch Prompt を Global Design Context ＋ Screen Prompt の2層で作ったか（1つに詰め込んでいないか）
- Stitch 実行を stitch-session.md に記録し、出力を stitch-review.md でレビューしたか
- implementation-ui-brief.md を Claude Code が実装できる粒度で出したか
- 要件探索を始めていないか（探索は requirements-discovery）
- ロゴ / 文章 / 写真のコピーを指示していないか（寄せるのは情報設計・導線・雰囲気のみ）
- ユーザーコメントを原文引用し、反映先と修正後Stitchプロンプトを出したか
- 既存コード / DB / API / UI に変更を加えていないか

---

関連スキル: [[project-discovery]]（親・全Discovery統括 / implementation-brief / user-flows / admin-flows / decisions 生成）/ [[requirements-discovery]]（前工程・要件探索・差し戻し先）/ [[scope-discovery]]（users / mvp-boundary の生成元・MVP境界の差し戻し先）/ [[discovery-auditor]]（横断監査の思想参照元）/ [[ui-ux-review]]（画面の使い勝手レビュー）/ [[feature-spec-writer]]（UI確定後の実装仕様書化）/ [[implementation-planner]]（実装手順分解）/ [[agent-tester]]・[[agent-planner]]（実装後の反復改善・Audit/Planning 思想の参照元）。

# 実行モデルティア

推奨ティア: **deep**（判断・設計・監査の質がモデルの推論力に依存する）。
最上位推論クラスのモデルが使えない環境でも中止しない。代わりに劣化運転として、
結論は候補＋根拠＋確信度で提示して1本に絞り込まず、工程を細かく区切って
ユーザー確認を挟み、不可逆な提案（削除・破壊的変更・本番適用）では必ず停止すること。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
