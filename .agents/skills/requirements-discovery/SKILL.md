---
name: requirements-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: standard
  summary: "実装前の要件洗い出し担当（Project Discovery の Phase2 も兼ねる）。業務フロー・利用者・状態・例外・通知・画面導線を段階式チェックリストで網羅質問し、後からの手戻りを減らす。一問一答はしない。"
description: >-
  実装に入る前に、必要要件を段階式チェックリストで網羅的に洗い出すスキル。
  業務フロー・利用者・状態・例外・通知連携・画面導線を段階ごとにまとめて質問し、
  後半で「この機能も必要だった」と発覚する手戻りを減らす。トリガー例:
  「要件を洗い出して」「何が必要か整理して」「作る前に要件を固めたい」
  「抜け漏れがないか確認して」「実装前に要件を詰めたい」「要件定義して」。
  一問一答は禁止で、段階ごとの表でまとめて質問し、ユーザーが
  「必要 / 不要 / 後で / 未定 / コメント」で返せる形式にする。
  実装仕様書への変換は feature-spec-writer、MVP分割・Phase設計は
  saas-product-manager、実装手順の分解は implementation-planner を使う。
  単独でも、[[project-discovery]] の Phase2（Requirements Discovery）としても動く。
  後者では成果物を requirements/ 配下に置き、decisions.md / 横断 open-questions.md・
  [[discovery-planner]] / [[discovery-auditor]] のループに従い、Scope は変更しない。
---

# Purpose

実装に着手する前に、必要要件を段階的に洗い出し、開発後半で「この機能も必要だった」と発覚する手戻りを減らす。

このスキルの核心は **一問一答で延々と質問しないこと**。段階ごとにチェックリスト形式の表でまとめて質問し、ユーザーが各項目を「必要 / 不要 / 後で / 未定 / コメント」でチェックしながら要件を固めていく。理想形まで含めて先に洗い出した上で、実装優先度を MVP / Phase2 / 将来 / 不要 に分類する。

feature-spec-writer / saas-product-manager が「ある程度固まった要件を仕様化する」のに対し、requirements-discovery は **まだ何が必要か分かっていない段階で、抜け漏れを段階式に発掘する** ことに特化する。

# 基本方針

- いきなり実装指示を書かない。DB / API / ロジック設計は後回しにする
- まず **業務・利用者・例外・運用・将来要件** を掘る
- 質問は1個ずつではなく、段階ごとのチェックリスト形式（表）で出す
- ユーザーは各項目に「必要 / 不要 / 後で / 未定 / コメント」で返せる
- コメント欄の内容を **次回出力に必ず反映** する
- 未定項目は勝手に確定しない（open-questions.md に集約する）
- 必要になりそうな項目は「将来必要候補」として分離する
- MVP ではなく、**理想形も含めて先に洗い出す**。ただし実装優先度は分類する
- 不要と判断したものも記録する（なぜ不要かを残す）
- 参考HP / 写真は UI / 導線 / 雰囲気の基準として扱う。著作権保護された画像・文章・ロゴの無断コピーは避ける
- 既存コード / DB / API / UI には一切変更を加えない（このスキルは探索と文書化のみ）

# When To Use

- 作りたいものはあるが、何が必要か網羅できていない
- 実装に入る前に抜け漏れを潰しておきたい
- 「後から必要だと分かる」手戻りを減らしたい
- 理想形と初期実装(MVP)を分けて優先度を付けたい

要件がある程度固まったら [[saas-product-manager]] で MVP / Phase 設計、[[feature-spec-writer]] で実装仕様書化、[[implementation-planner]] で実装手順分解に進む。

# Discovery ループとの連携（project-discovery Phase2）

このスキルは **単独でも**、**[[project-discovery]] の Phase2 としても**使える。project-discovery 配下で動くときは Discovery Suite 共通のループ・記録機構に従う。

- 進行は [[discovery-planner]] の停止ゲートに従い、Stage を一度に全部進めず **1サイクル＝1テーマ**でユーザー確認を挟む（一問一答ではなく Stage 単位の表で出す本スキルの原則と両立する）。
- 確定した要件は `decisions.md` に **決定 / 保留 / 仮置き(assumption)** で記録する（[[project-discovery]] の決定ログ機構）。未定・要確認は横断 `open-questions.md` に集約し、独自に二重作成しない。
- Scope は [[scope-discovery]] が確定済み。requirements-discovery は **Scope を変更しない**。境界の変更が要る場合は [[scope-discovery]] に差し戻す。
- 入力として `scope/scope.md` / `scope/users.md` / `scope/goals.md` / `scope/mvp-boundary.md`（[[scope-discovery]]）を参照し、Stage 0 の重複質問を避ける。
- 全フェーズ完了後は [[discovery-auditor]] が横断監査する。未昇格の仮置きが残る間は「完了」にしない。
- UI 生成（stitch 等）は [[screen-design-architect]]、最終 implementation-brief は [[project-discovery]] が統括する（[Stage 8](#stage-8成果物生成) の生成条件参照）。

# 進め方（運用フロー）

- 進行は Stage 0〜8 の段階式。各 Stage は **表でまとめて1回で提示** し、ユーザーの回答を待ってから次へ進む。勝手に先のステージへ進めない。
- **一問一答にしない**。「この項目は必要ですか？」を1件ずつ聞かず、必ずその Stage の全項目を1つの表で出す。
- 前 Stage の回答・コメントは **次 Stage 以降も引き継ぐ**。同じことを再質問しない。コメントは次回出力に必ず反映する（[コメント対応ルール](#コメント対応ルール)）。
- Stage が進むほど「未定」「将来必要候補」が溜まる。これらは確定させず、Stage 7 の優先度整理と `open-questions.md` に集約する。
- 最後に Stage 8 で成果物を生成するまで、DB / API / ロジックの設計や実装指示は書かない。

# Procedure

進行は Stage 0〜8 の段階式。各 Stage は **表でまとめて提示** し、ユーザーの回答を待ってから次へ進む。勝手に先のステージへ進めない。

### Stage 0：入力整理

ユーザーから以下を受け取る（不足は表で確認する。推測で埋めない）。

- 作りたいもの
- 参考HP / 参考アプリ / 参考画像
- 対象業種
- 利用者
- 既に決まっている要件
- 絶対に寄せたい参考
- 避けたいこと

### Stage 1：業務フロー確認

業務フローを下記の正準テーブルで提案する（列は固定）。

| 項目 | 必要性候補 | 推奨判断 | 理由 | ユーザー回答 | コメント |
|---|---|---|---|---|---|
| 新規登録 | 高 | 必要 | （理由） |  |  |
| 予約 | 高 | 必要 | （理由） |  |  |
| 変更 | … | … | … |  |  |

確認する代表項目：新規登録 / 予約 / 変更 / キャンセル / 問い合わせ / 通知 / 管理者確認 / 承認 / 公開 / 下書き / 履歴 / 複製 / 削除 / 復元

> Stage 2〜6 も同じ列構成（項目 / 必要性候補 / 推奨判断 / 理由 / ユーザー回答 / コメント）の表で提示する。ユーザー回答欄は **必要 / 不要 / 後で / 未定 / コメント** で返せるようにする。

### Stage 2：利用者・権限確認

確認する項目：顧客 / スタッフ / 店長 / 管理者 / 外部業者 / 未ログインユーザー / ログイン済みユーザー / 編集できる人 / 閲覧だけできる人 / 承認できる人 / 削除できる人

### Stage 3：データ・状態確認

確認する項目：0件状態 / 1件状態 / 大量件数 / 下書き / 公開 / 非公開 / 無効化 / 削除済み / ロック状態 / 重複 / 未入力 / 入力途中 / エラー / 完了 / 期限切れ / キャンセル済み

### Stage 4：例外・トラブル確認

確認する項目：同姓同名 / 電話番号変更 / メール変更 / 重複予約 / 誤登録 / 操作ミス / 途中離脱 / 通信失敗 / 権限不足 / データ不整合 / 後から修正 / ロールバック / 監査ログ

### Stage 5：通知・連携確認

確認する項目：メール通知 / LINE通知 / SMS通知 / 管理者通知 / 顧客通知 / リマインド / 期限通知 / 完了通知 / 失敗通知 / 外部予約連携 / Googleカレンダー連携 / 決済連携 / CSV出力 / PDF出力

### Stage 6：画面・導線確認

確認する項目：トップ / 一覧 / 詳細 / 新規作成 / 編集 / 確認 / 完了 / エラー / 設定 / 履歴 / プレビュー / 比較 / 複製 / 公開 / アーカイブ / ロールバック / スマホ表示 / PC表示

### Stage 7：優先度整理

Stage 1〜6 の全項目を以下に分類する。理想形を洗い出した上で、全部を MVP に入れない。

- MVP必須
- Phase2
- 将来必要候補
- 不要
- 未定
- 要確認

### Stage 8：成果物生成

`requirements/` 配下に **`domain/index.md` パターン**で生成する（Discovery Suite 共通規約）。

| ファイル | 内容 | 備考 |
|---|---|---|
| `requirements/requirements.md` | **index**。探索の全体まとめ（背景・確定要件・理想形）。**[[project-discovery]] の正式参照先**。 | 常に生成 |
| `requirements/requirements-checklist.md` | Stage 1〜6 の全項目と回答・優先度の一覧 | 常に生成 |
| `requirements/screen-catalog-draft.md` | 画面カタログ草案（画面 / 役割 / 主要項目 / 状態）→ [[screen-design-architect]] への入力 | 常に生成 |
| `requirements/comment-resolution-log.md` | コメント対応ログ | 常に生成 |
| `requirements/stitch-prompt.md` | Stitch 等のUI生成プロンプト草案 | **単独利用時のみ**。project-discovery 配下では UI 生成は [[screen-design-architect]] に委譲し、ここでは作らない |
| `implementation-brief.md` | 実装前ブリーフ（MVP範囲・前提・禁止事項） | **単独利用時のみ**。project-discovery 配下では最終ブリーフは [[project-discovery]] が統括するため生成しない |
| `open-questions.md` | 未定・要確認の集約 | project-discovery 配下では **横断 `open-questions.md` に統合**（独自に二重作成しない） |

# 質問形式・回答形式のルール

- **一問一答は禁止**。必ず段階ごとの表でまとめて出す
- 各項目にユーザーが返しやすいよう、回答欄は **必要 / 不要 / 後で / 未定 / コメント** を提示する
- 推奨判断には必ず理由を添える（ユーザーが判断できるように）

### 出力例（Stage 1 業務フロー）

| 項目 | 推奨 | 理由 | 回答 | コメント |
|---|---|---|---|---|
| 予約変更 | 必要 | 予約後の変更は高確率で発生するため |  |  |
| キャンセル | 必要 | 運用上ほぼ必須 |  |  |
| 決済 | 後で | 初期は予約だけでも成立するため |  |  |

# コメント対応ルール

ユーザーがコメントを返した場合、**次回出力で必ず** 以下を行う。

- コメントを **原文で引用** する
- 対応方針（interpretation / action）を示す
- 反映先（どのファイル・どの要件）を示す
- 反映後の要件を更新する
- 未反映の場合は理由を書く

コメントは `comment-resolution-log.md` に下記の表で記録する。

| comment_id | user_comment | interpretation | action | affected_requirement | status | remaining_question |
|---|---|---|---|---|---|---|

# 重要ルール

- 「最高を目指す」要件探索はする。ただし全部を MVP に入れない
- 理想形と初期実装(MVP)を分ける
- 不要と判断したものも、なぜ不要かを含めて記録する
- 未定を放置せず `open-questions.md` に集約する
- 参考HP / 写真は UI / 導線 / 雰囲気の基準として扱う
- 著作権保護された画像・文章・ロゴの無断コピーは避ける
- 既存コード / DB / API / UI には変更を加えない

# Output Template

各成果物のひな形。

### requirements/requirements.md

```md
# 要件探索: <プロダクト名>

## 背景・目的
（作りたいもの / 対象業種 / 利用者 / 解決したい課題）

## 参考
- 参考HP / アプリ / 画像（UI・導線・雰囲気の基準として）
- 絶対に寄せたい参考:
- 避けたいこと:

## 確定している要件
（Stage 0 で受け取った既定要件）

## 理想形（全部入り）
（MVP を意識せず、あるべき姿として洗い出した要件）
```

### requirements/requirements-checklist.md

```md
# 要件チェックリスト

## Stage 1 業務フロー
| 項目 | 推奨 | 理由 | 回答 | 優先度 | コメント |
|---|---|---|---|---|---|

## Stage 2 利用者・権限
| 項目 | 推奨 | 理由 | 回答 | 優先度 | コメント |
|---|---|---|---|---|---|

## Stage 3 データ・状態
（同形式）

## Stage 4 例外・トラブル
（同形式）

## Stage 5 通知・連携
（同形式）

## Stage 6 画面・導線
（同形式）
```

### requirements/screen-catalog-draft.md

```md
# 画面カタログ草案
| 画面 | 役割 | 主要表示項目 | 主要操作 | 状態(空/読込/エラー) | 対象ユーザー | 優先度 |
|---|---|---|---|---|---|---|
```

### requirements/stitch-prompt.md（単独利用時のみ）

```md
# Stitch 用プロンプト草案

## 全体トーン
（参考HP・画像から抽出した雰囲気。著作権物のコピーは指示しない）

## 画面ごとのプロンプト
### <画面名>
- 目的:
- 主要要素:
- 導線:
- レスポンシブ: スマホ / PC
```

### implementation-brief.md（単独利用時のみ / project-discovery 配下では project-discovery が統括）

```md
# 実装前ブリーフ

## MVP範囲
- 含む（理由付き）:
- 含まない（Phase2 / 将来 / 不要、理由付き）:

## 前提・制約
（既存システム / 技術前提 / 運用前提）

## 禁止事項
- 既存コード / DB / API / UI を変更しない 等

## 次の工程
- 仕様化: feature-spec-writer
- MVP/Phase設計: saas-product-manager
- 実装手順分解: implementation-planner
```

### open-questions.md

```md
# 未確定事項
| # | 項目 | 内容 | 種別(未定/要確認) | 確認相手 | 影響範囲 |
|---|---|---|---|---|---|
```

### requirements/comment-resolution-log.md

```md
# コメント対応ログ
| comment_id | user_comment | interpretation | action | affected_requirement | status | remaining_question |
|---|---|---|---|---|---|---|
```

# セルフチェック

- 一問一答になっていないか（段階ごとの表で出しているか）
- 未定項目を勝手に確定していないか（open-questions.md にあるか）
- ユーザーのコメントを原文引用し、反映先を示したか
- 理想形と MVP を分けて優先度を付けたか
- 不要と判断したものも理由付きで記録したか
- 既存コード / DB / API / UI に変更を加えていないか
- （project-discovery 配下のとき）`decisions.md` / 横断 `open-questions.md` に記録し、Scope を変更せず、UI生成・最終ブリーフを二重生成していないか

---

関連スキル（Discovery）: [[project-discovery]]（Phase2 としての親）/ [[scope-discovery]]（前段・境界確定）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（横断監査）/ [[screen-design-architect]]（要件→画面・次工程）。
関連スキル（実装系）: [[feature-spec-writer]]（実装仕様書化）/ [[saas-product-manager]]（MVP・Phase設計）/ [[implementation-planner]]（実装手順分解）/ [[ui-ux-review]]（画面の使い勝手改善）。

# 実行モデルティア

推奨ティア: **standard**（手順追従型のため標準クラスのモデルで品質が安定する）。
最上位推論クラスのモデルを占有する必要はない。手順から外れる複雑な判断が
必要になったら、その論点を明示して deep ティアの設計・監査系スキルへ引き渡すこと。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
