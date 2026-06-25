---
name: scope-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
description: >-
  Project Discovery の最前段（Scope Discovery）担当。requirements-discovery が「どう作るか」を固める工程なら、
  scope-discovery は「そもそも何を作るのか / どこまで作るのか / 今回は何を作らないのか」を決める工程。
  要件定義を始める前にプロジェクトの境界線（Scope）を確定する。解決したい課題・対象ユーザー・利用者区分・
  成功条件・MVP範囲・対象外範囲・運営者/管理画面の有無・利用環境(Web/LINE/アプリ)・関係者・外部依存を発見し
  scope/ 配下のドキュメントを生成する。全探索完了後は再入してMVPの線を1本引いて確定する（release-plan.md）。
  トリガー例: 「何を作るか決めたい」「プロジェクトの範囲を固めたい」「今回どこまで作るか線を引きたい」
  「対象外を明確にしたい」「要件定義の前に方向性を確定したい」「MVPの範囲を決めたい」。
  画面設計・DB設計・API設計はしない。確定後 [[requirements-discovery]] へ引き渡す。
---

# Purpose

このスキルは **「どう作るか」を決めるスキルではない**（それは [[requirements-discovery]]）。目的は、要件定義を始める **前** に、プロジェクトの **境界線（Scope）を確定する** こと。

明確化するもの：

- 何を作るのか
- 誰のために作るのか
- なぜ作るのか
- どこまで作るのか
- **今回は何を作らないのか**

この段階で境界が曖昧なまま [[requirements-discovery]] に進むと、「あれもこれも」と要件が膨張し、MVP が定義できなくなる。**まず境界を引く。作り方は決めない。**

[[project-discovery]] の最前段を担う。実務上の流れは次の通り：

```text
scope-discovery（何を/どこまで作るか）
 → requirements-discovery（どう作るか）
 → data-discovery → contract-discovery → legal-discovery → ...
 → （全探索後）scope-discovery に再入し MVP の線を1本引いて確定（release-plan.md）
```

scope-discovery は **最初に境界を引き、最後に MVP の線を確定する** ゲートとして両端で機能する（[再入: MVP確定ゲート](#再入-mvp-確定ゲート)）。

# このスキルの責務

明らかにするもの：

- 解決したい課題 / 対象ユーザー / 利用者区分 / 利用シーン
- 成功条件 / MVP範囲 / 対象外範囲
- 運営者の存在 / 管理画面の有無
- 利用環境（Web / スマホ / LINE / LIFF / アプリ / 管理画面）
- 関係者 / 外部サービス依存 / リリース優先順位

# やってはいけないこと（禁止事項）

## 実装設計
DB設計 / テーブル設計 / API設計 / 技術選定 / ER図。→ 後工程の担当。

## UI設計
画面レイアウト / ワイヤーフレーム / デザイン提案。→ [[screen-design-architect]] の担当。

## 仮定で埋める
情報不足を勝手に確定しない。**不明点は質問する**か、`decisions.md` に `保留 / 仮置き(assumption)` として登録する。仮置きは事実として扱わない。

## 「どう作るか」への踏み込み
機能の詳細仕様・画面導線・状態遷移は [[requirements-discovery]] 以降の担当。ここは境界の確定に徹する。

# 入力

- ユーザーの初期インプット（作りたいもの / 課題 / 参考 / 既決事項 / 制約）
- `decisions.md` / `open-questions.md`（[[project-discovery]] の決定・未確定ログ / 既存の場合）

> 不足は推測で埋めず質問する。それでも未確定なものは `assumption` として置き `open-questions.md` に積む。

# 出力

`scope/` 配下に生成する。

| ファイル | 内容 |
|---|---|
| `scope/scope.md` | **index**。境界サマリ（一言説明 / MVPの線 / 対象・対象外の要点）と各観点ファイルへの導線。**[[project-discovery]] が最初に参照する入口**。 |
| `scope/project-overview.md` | プロジェクト名 / 一言説明 / 解決したい課題 / 背景 / なぜ作るのか |
| `scope/users.md` | 誰が使うか / 利用者種別 / 主利用者 / 副利用者 / 運営者 |
| `scope/goals.md` | 成功とは何か / KPI候補 / ユーザー価値 / 事業価値 |
| `scope/mvp-boundary.md` | 最初に必要な機能 / 無くてもよい機能 / 後回し機能 / 将来構想 |
| `scope/in-scope.md` | 今回作るもの（対象） |
| `scope/out-of-scope.md` | 今回作らないもの（対象外・必ず明文化） |
| `scope/channels.md` | 利用環境（Web / スマホ / LINE / LIFF / アプリ / 管理画面） |
| `scope/stakeholders.md` | オーナー / 運営者 / 管理者 / 顧客 / スタッフ / 外部企業 |
| `scope/dependencies.md` | 外部依存（LINE / Google / Stripe / Hotpepper / SNS / WordPress 等） |
| `release-plan.md` | **再入時のみ**: 全要件を MVP / Phase2 / 将来 / 不要 に分類し MVP の線を確定 |

# 探索対象

## 1. プロジェクト概要 → `scope/project-overview.md`
プロジェクト名 / 一言説明 / 解決したい課題 / 背景 / なぜ作るのか。

## 2. ユーザー → `scope/users.md`
誰が使うか / 利用者種別 / 主利用者 / 副利用者 / 運営者。

## 3. ゴール → `scope/goals.md`
成功とは何か / KPI候補 / ユーザー価値 / 事業価値。
→ KPI候補は曖昧でよい（測定可能化は [[metrics-discovery]] へ）。

## 4. MVP → `scope/mvp-boundary.md`
最初に必要な機能 / 無くてもよい機能 / 後回し機能 / 将来構想。
→ ここは **MVPの仮説**。最終的な線の確定は [再入ゲート](#再入-mvp-確定ゲート)で行う。

## 5. スコープ境界 → `scope/in-scope.md` / `scope/out-of-scope.md`
- **対象**: 今回作るもの
- **対象外**: 今回作らないもの（**必ず明文化する**。暗黙の「やらない」を残さない）

## 6. 利用環境 → `scope/channels.md`
Web / スマホ / LINE / LIFF / アプリ / 管理画面 など。

## 7. 関係者 → `scope/stakeholders.md`
オーナー / 運営者 / 管理者 / 顧客 / スタッフ / 外部企業。

## 8. 外部依存 → `scope/dependencies.md`
LINE / Google / Stripe / Hotpepper / SNS / WordPress など。
→ 確定した外部依存は [[integration-discovery]] / [[legal-discovery]]（第三者提供）の前提になる。

## 9. 利用シーン【補完】
主要な利用シーン（いつ・どこで・どの端末で使うか）。利用環境とユーザーの裏取りに使い、対象外の判断材料にする。

# 質問ルール

一度に大量質問しない。常に **「次に決めるべき1件」** のみ質問する。深掘りの1問は [[discovery-planner]] が作る。

各回答は **決定 / 保留 / 仮置き / 未定 / コメント** で返せる形にする。

## 質問の優先順位

1. 課題
2. ユーザー
3. ゴール
4. MVP
5. 対象外
6. 外部依存

# 意思決定の記録

不明な場合は **決定 / 保留 / 仮置き** に分類して `decisions.md` に記録する（[[project-discovery]] の決定ログ機構）。

- **決定(decision)**: ユーザーが確定した境界。
- **保留(pending)**: 決める必要があるが未決 → `open-questions.md` へ。
- **仮置き(assumption)**: AI/暫定で置いた前提。**事実として扱わない**。下流（requirements 以降）へ渡る前に必ず昇格 or 解消する。

# 進め方（Discovery ループ）

```text
初期インプット整理
 → [[discovery-planner]]: 次に決めるべき1件に絞って質問（優先順位順 / 1テーマ1問）
 → ユーザー回答（必ず停止して確認）
 → scope/ 配下を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 [[discovery-auditor]] へ（境界の矛盾・対象外の漏れを監査）
 → [[requirements-discovery]] へ引き渡し
```

# 完了条件

以下が全て埋まっていること（[Phase完了判定](#phase完了判定)を出す）。

- 誰の課題か
- 何を作るか
- なぜ作るか
- MVP範囲
- 対象外範囲
- 利用者区分
- 管理者有無
- 外部依存

未昇格の仮置き(assumption)が残る間は「完了」にしない（ユーザーが暫定通過を明示承認した場合のみ例外、その旨を記録）。

## Phase完了判定

```text
## Phase完了判定: Scope Discovery
- 探索対象カバー率: <x/8>
- 対象外(out-of-scope)の明文化: 完了 / 未完了
- 未解消の保留: <件数>
- 未昇格の仮置き(assumption): <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

# 再入: MVP 確定ゲート

scope-discovery は最前段で境界を引くだけでなく、**全探索（requirements 〜 nfr 等）が終わった後に再入し、MVP の線を1本引いて確定する** ゲートとしても機能する（旧 Phase13 の役割を継承）。

- 全フェーズの要件を **MVP / Phase2 / 将来 / 不要** に分類する。
- MVP の線を **1本に確定** し、`decisions.md` に `decision` として記録する（仮置きのままにしない）。
- 判断基準: **成功状態への寄与 × コスト × リスク**。
- 確定結果を `release-plan.md` に出力する。
- [[discovery-auditor]] が「MVP線が引かれているか」を確認する前提工程。

> この再入は、最前段で置いた `scope/mvp-boundary.md` の仮説を、下流の発見（データ・法務・契約・非機能）を踏まえて確定に昇格させる工程。最前段の段階で `release-plan.md` は作らない。

# 差し戻しループ（再入可能性）

scope は一度引いて終わりではない。下流の発見が境界を揺らしたら scope-discovery に差し戻す。

- [[requirements-discovery]] は **Scope を変更してはならない**。Scope変更が必要になったら scope-discovery に差し戻す。
- [[legal-discovery]] / [[contract-discovery]] で重い法務・契約要件が判明 → MVP範囲・対象外を再検討。
- [[nfr-discovery]] でコスト/スケール制約が判明 → MVPの線を引き直す。
- 差し戻しが起きたら該当 `decisions.md` を更新し、影響フェーズを再オープンする。

# 引き渡し

完了後は [[requirements-discovery]] に引き渡す。全ドキュメントではなく、要件探索に必要な境界情報を渡す。

| 引き渡し先 | 渡す情報 |
|---|---|
| [[requirements-discovery]] | project-overview / users / goals / mvp-boundary / in-scope / out-of-scope / stakeholders / dependencies（**Scopeは変更不可**） |
| [[integration-discovery]] | dependencies（外部依存） |
| [[metrics-discovery]] | goals（KPI候補 → 測定可能化） |
| [[discovery-auditor]] | 境界（in/out）・MVP仮説（監査対象） |

# Output Template

### scope/project-overview.md
```md
# プロジェクト概要: <プロダクト名>
## 一言説明
## 解決したい課題
## 背景
## なぜ作るのか
```

### scope/users.md
```md
# ユーザー
## 利用者種別
## 主利用者
## 副利用者
## 運営者
```

### scope/goals.md
```md
# ゴール
## 成功とは何か
## KPI候補（metrics-discovery で測定可能化）
## ユーザー価値
## 事業価値
```

### scope/mvp-boundary.md
```md
# MVP境界（仮説）
## 最初に必要な機能
## 無くてもよい機能
## 後回し機能
## 将来構想
```

### scope/in-scope.md / scope/out-of-scope.md
```md
# 対象（今回作るもの）
- …

# 対象外（今回作らないもの・明文化必須）
- …（理由）
```

### scope/channels.md
```md
# 利用環境
- Web / スマホ / LINE / LIFF / アプリ / 管理画面（該当のみ）
```

### scope/stakeholders.md
```md
# 関係者
| 関係者 | 役割 | 主/副 |
|---|---|---|
```

### scope/dependencies.md
```md
# 外部依存
| 依存先 | 用途 | 必須/任意 | 引き渡し先 |
|---|---|---|---|
```

### release-plan.md（再入ゲートで生成）
```md
# リリース計画: <プロダクト名>
## MVPの線（確定）
| 機能 | 区分(MVP/Phase2/将来/不要) | 根拠(寄与×コスト×リスク) |
|---|---|---|
## 対象外（今回やらない）
## 保留・仮置き（decisions.md と同期）
```

# セルフチェック

- 「どう作るか」に踏み込まず、境界（何を/どこまで/何を作らないか）の確定に留めたか
- **対象外（out-of-scope）を明文化したか**（暗黙の「やらない」を残していないか）
- DB / API / UI / 技術選定に踏み込んでいないか
- 情報不足を仮定で埋めず、質問 or `decisions.md` に保留/仮置きとして登録したか
- 1テーマ1問・優先順位順に質問したか（大量質問していないか）
- KPI候補を曖昧なまま [[metrics-discovery]] に渡したか（無理に確定していないか）
- 引き渡しで [[requirements-discovery]] に「Scopeは変更不可」を明示したか
- 再入ゲートで MVP の線を1本確定し `release-plan.md` / `decisions.md` に記録したか（仮置きのままにしていないか）
- 既存コード / DB / API / UI に変更を加えていないか

---

関連スキル: [[project-discovery]]（オーケストレーター）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（境界・MVP監査）/ 引き渡し先: [[requirements-discovery]]（どう作るか）/ [[integration-discovery]]（外部依存）/ [[metrics-discovery]]（KPI）/ 差し戻し連携: [[legal-discovery]] / [[contract-discovery]] / [[nfr-discovery]]。
