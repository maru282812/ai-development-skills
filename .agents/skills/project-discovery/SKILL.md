---
name: project-discovery
description: >-
  プロジェクトを成功させるために「決めるべきこと」を全部洗い出し、不足を発見・提案し、
  意思決定を支援して、実装可能な状態まで持っていくオーケストレーター・スキル。
  要件定義書を作ることが目的ではない。要件・UX・管理・収益・運営・法務・リスク・
  データ・連携・指標・非機能・スコープの穴を発見し、決定と仮置きを分離して記録し、
  抜け漏れのない状態で次工程へ引き渡す。トリガー例:
  「プロジェクトを立ち上げたい」「何を決めればいいか分からない」「実装前に全部詰めたい」
  「要件だけじゃなく運営や法務も含めて穴を潰したい」「企画を実装可能な状態にして」。
  各フェーズは [[discovery-planner]] で次の1問に絞り、[[discovery-auditor]] で横断監査する。
  個別ドメインの深掘りは business/operations/legal/risk/data/integration/metrics/nfr/scope の
  各 *-discovery スキルへ委譲する（未実装のものは「後で実装」として扱う）。
---

# Purpose

このスキルは **要件発見（requirements-discovery）ではなく、プロジェクト発見（Project Discovery）** を担う。

成果物は「要件定義書」ひとつではない。プロジェクトを成功させるために必要な **要件 / 運営 / 法務 / 収益 / 管理 / 保守 / リスク / データ / 連携 / 指標 / 非機能 / スコープ** を発見し、意思決定を支援し、実装可能な状態まで引き上げることが目的。

核心の思想は次の通り：

```text
ユーザーが思いついた機能
 → AIが整理        ← これだけでは不十分
```

ではなく：

```text
ユーザーが思いついた機能
 → AIが不足を発見
 → AIが成功事例を元に提案
 → AIが運営面を発見
 → AIが法務面を発見
 → AIが管理画面要件を発見
 → AIが障害対応を発見
 → AIがリリース後運用を発見
```

つまりこのスキルの仕事は **「要件をまとめる」ではなく「プロジェクトの穴を見つける」**。

# 基本原則

ユーザーの発言を書き起こすだけではない。AI自身が能動的に以下を **提案** する：

- 不足している要件
- 見落としている運営課題
- 法律上の確認事項
- 収益化の課題
- スケール時の問題
- リリース後の運用課題
- 管理画面要件

そして、発見したことを **決定（decision）/ 保留（pending）/ 仮置き（assumption）** に区別して記録する。記録の仕組みが無ければ「意思決定を支援する」は成立しない。

- 未確定を勝手に確定しない。仮置きには必ず `assumption` フラグを付け、`decisions.md` / `open-questions.md` に集約する。
- 認知負荷を制御する。全項目を一度に質問してユーザーを潰さない。1サイクル＝1テーマに絞り、必ず止めてユーザー確認する（[[discovery-planner]] の停止ゲートを継承）。
- 既存コード / DB / API / UI には一切変更を加えない（このスキルは探索・意思決定支援・文書化のみ）。

# このスキルの責務と非責務

- **責務**: フェーズ全体のオーケストレーション、意思決定の状態管理（`decisions.md`）、差し戻しループの制御、Phase完了判定、次工程への引き渡し情報の抽出。
- **非責務（委譲）**: 各ドメインの深掘り質問は個別スキルへ委譲する。UI設計は [[screen-design-architect]]、実装仕様化は feature-spec-writer、実装手順分解は implementation-planner。
- **実装ループのスキルを流用しない**: [[agent-planner]] / [[agent-tester]] は実装ループ専用（git diff / typecheck / test を走らせる）。Discovery 段階には diff も走らせるコードも無い。Discovery には [[discovery-planner]] / [[discovery-auditor]] を使う。

# 成果物ツリー

最終的に `project-discovery/` 配下に以下を生成する（フェーズ未実装のものは生成されず、ステータス表に「後で実装」と残る）。

各ドメインは **`domain/<index>.md` パターン**で統一する（Discovery Suite 共通規約）。`domain/` 直下に index を1本立て、観点ごとに分割する。index ファイル名は原則 `domain/domain.md`（例外: business は `business/business-model.md`）。

```text
project-discovery/
├─ scope/                     ← Phase1  [[scope-discovery]]（境界確定。旧 project-vision を吸収）
│   ├─ scope.md               （index: 境界サマリ / 各観点への導線）
│   ├─ project-overview.md    （誰の課題か / なぜ作るのか / 背景）
│   ├─ users.md               （利用者区分 / 主・副利用者 / 運営者）
│   ├─ goals.md               （成功状態 / KPI候補 / 価値）
│   ├─ mvp-boundary.md        （MVP仮説 / 後回し / 将来構想）
│   ├─ in-scope.md / out-of-scope.md （対象 / 対象外・明文化）
│   ├─ channels.md            （Web / LINE / アプリ / 管理画面）
│   ├─ stakeholders.md        （関係者）
│   └─ dependencies.md        （外部依存）
├─ requirements/              ← Phase2  [[requirements-discovery]]
│   ├─ requirements.md        （index: 背景・確定要件・理想形）
│   ├─ requirements-checklist.md （Stage1〜6 全項目・回答・優先度）
│   └─ screen-catalog-draft.md   （画面カタログ草案 → screen-design-architect へ）
├─ user-flows.md              ← Phase3  project-discovery
├─ admin-flows.md             ← Phase4  project-discovery
├─ business/                  ← Phase5  [[business-discovery]]（index: business/business-model.md ＋ customer-segments / value-proposition / revenue / go-to-market / business-metrics）
├─ operations/                ← Phase6  [[operations-discovery]]（index: operations/operations.md ＋ operator-roles / operational-workflows / support-process / content-management / operational-metrics / runbook-summary）
├─ contract/                  ← Phase7a [[contract-discovery]]（index: contract/contract.md ＋ contract-inventory / contract-open-questions）
├─ legal/                     ← Phase7  [[legal-discovery]]（index: legal/legal.md ＋ legal-risk / legal-open-questions）
├─ risk/                      ← Phase8  [[risk-discovery]]（index: risk/risk.md ＋ business-risks / operational-risks / integration-risks / … / assumptions）
├─ data/                      ← Phase9  [[data-discovery]]（index: data/data.md）
├─ integration/               ← Phase10 [[integration-discovery]]（index: integration/integration.md ＋ external-services / data-flows / auth-and-identity / notifications / payment-and-billing / import-export / failure-handling）
├─ metrics/                   ← Phase11 [[metrics-discovery]]（index: metrics/metrics.md ＋ kpi / events / measurement）
├─ nfr/                       ← Phase12 [[nfr-discovery]]（index: nfr/nfr.md ＋ performance / availability / security / operability / maintainability / scalability / …）
├─ release-plan.md            ← Phase13 [[scope-discovery]] 再入（MVP の線を確定するゲート）
├─ decisions.md               ← 横断: 決定/保留/仮置きログ（最重要）
├─ open-questions.md          ← 横断: 未確定事項（decisions.md の裏返し）
└─ implementation-brief.md    ← 引き渡し: 次工程へ抽出して渡す
```

# フェーズ一覧と実装ステータス

フェーズは **線形ではない**。後段の発見が前段を更新する（[差し戻しループ](#差し戻しループ再入可能性)）。

| Phase | 名前 | 成果物 | 担当スキル | 実装ステータス |
|---|---|---|---|---|
| 0 | Input Intake | （会話） | project-discovery | ✅ 実装済 |
| 1 | Scope Discovery | scope/ 配下（scope ＋ project-overview / users / goals / mvp-boundary / in-scope / out-of-scope / channels / stakeholders / dependencies） | [[scope-discovery]] | ✅ 実装済（要件定義の前に境界を引く。旧 Phase1 project-vision を吸収） |
| 2 | Requirements Discovery | requirements/ 配下（requirements ＋ requirements-checklist / screen-catalog-draft） | [[requirements-discovery]] | ✅ 実装済（既存流用 → Discovery ループへ統合済） |
| 3 | UX Discovery | user-flows.md | project-discovery | ✅ 実装済 |
| 4 | Admin Discovery | admin-flows.md | project-discovery | ✅ 実装済 |
| 5 | Business Discovery | business/ 配下（business-model / customer-segments / value-proposition / revenue / go-to-market / business-metrics） | [[business-discovery]] | ✅ 実装済（事業成立条件の発見。詳細財務予測・PLは作らない。metrics と矛盾させない） |
| 6 | Operations Discovery | operations/ 配下（operations / operator-roles / operational-workflows / support-process / content-management / operational-metrics / runbook-summary） | [[operations-discovery]] | ✅ 実装済（運用実態の発見。実装方法・DB・API・画面・非機能・インフラは決めない。metrics と矛盾させない） |
| 7a | Contract Discovery | contract/contract.md / contract/contract-inventory.md / contract/contract-open-questions.md | [[contract-discovery]] | ✅ 実装済（Legal の前提として契約・返金・SLA・サポート・責任範囲・データ/成果物所有権を整理。番号は暫定で次回Phase整理時に振り直す） |
| 7 | Legal Discovery | legal/legal.md / legal/legal-risk.md / legal/legal-open-questions.md | [[legal-discovery]] | ✅ 実装済（必要法務成果物の発見。適法性は断定せず要専門家レビュー） |
| 8 | Risk Discovery | risk/risk.md | [[risk-discovery]] | ✅ 実装済 |
| 9 | Data Discovery | data/data.md | [[data-discovery]] | ✅ 実装済 |
| 10 | Integration Discovery | integration/ 配下（integration / external-services / data-flows / auth-and-identity / notifications / payment-and-billing / import-export / failure-handling） | [[integration-discovery]] | ✅ 実装済（外部連携の必要性・責任範囲・失敗時対応の発見。API仕様・Webhook・OAuthスコープ・DB・ER図・インフラ・技術選定は決めない） |
| 11 | Metrics Discovery | metrics/（正式参照: metrics/metrics.md） | [[metrics-discovery]] | ✅ 実装済 |
| 12 | NFR Discovery | nfr/nfr.md | [[nfr-discovery]] | ✅ 実装済 |
| 13 | Scope / MVP Gate（再入確定） | release-plan.md | [[scope-discovery]] | ✅ 実装済（Phase1 の scope-discovery に再入し MVP の線を確定） |
| — | 横断監査 | （レポート） | [[discovery-auditor]] | ✅ 実装済 |

> ⏳ のフェーズに到達したら、対応スキルが未実装である旨をユーザーに伝え、`decisions.md` に「このドメインは未探索（assumption: 後続で実施）」として記録し、スキップするか暫定的に project-discovery 内で浅く扱うかをユーザーに選ばせる。勝手に深掘りを捏造しない。

# 実装済フェーズの中身

## Phase 0：Input Intake

ユーザーから受け取る（不足は表で確認。推測で埋めない）。

- 作りたいもの / 解決したい課題
- 対象ユーザー・業種
- 参考HP / 参考アプリ / 参考画像
- すでに決まっていること
- 制約（予算 / 期限 / 技術 / 体制）

## Phase 1：Scope Discovery → `scope/` 配下（[[scope-discovery]] へ委譲）

**「どう作るか」の前に「何を / どこまで / 何を作らないか」の境界を引く工程**。深掘りは [[scope-discovery]] スキルへ委譲し、その成果物（index `scope/scope.md` ＋ `scope/project-overview.md` / `users.md` / `goals.md` / `mvp-boundary.md` / `in-scope.md` / `out-of-scope.md` / `channels.md` / `stakeholders.md` / `dependencies.md`）をこのフェーズの成果物として取り込む。

旧 Phase1（project-vision.md: 誰の課題か / なぜ解決したいか / 成功状態 / MVP仮説 / 将来構想）は **scope-discovery が吸収**した（project-overview + goals + mvp-boundary）。成功状態は **後で Phase11(Metrics) で測定可能なKPIに落とす** 前提で、ここでは言語化に留めてよい（曖昧なら `assumption` フラグ）。Scope は確定後 [[requirements-discovery]] が変更してはならず、変更が要る場合は [[scope-discovery]] に差し戻す。

## Phase 2：Requirements Discovery → `requirements/` 配下

機能を発見し、必須 / 推奨 / 将来 / 不要候補 に分類する。深掘りは [[requirements-discovery]] スキルへ委譲し、その成果物（index `requirements/requirements.md` ＋ `requirements/requirements-checklist.md` / `requirements/screen-catalog-draft.md`）をこのフェーズの成果物として取り込む。UI 草案（stitch 等）と最終 implementation-brief は **このスキル側で扱う**（[次工程への引き渡し](#次工程への引き渡し)）。

## Phase 3：UX Discovery → `user-flows.md`

利用者導線を整理する：初回利用 / ログイン / 検索 / 登録 / 投稿 / 購入 / 問い合わせ / 解約 / 通知。各導線の入口→完了、分岐・エラーも明示する。

## Phase 4：Admin Discovery → `admin-flows.md`

管理画面要件を発見する。必ず確認：管理者は存在するか / スタッフ権限は必要か / 承認機能 / 投稿管理 / 問い合わせ管理 / レポート / KPI確認。

# 意思決定の状態管理（最重要・このスキルの土台）

「意思決定を支援する」を成立させる中核機構。`decisions.md` が無ければ [[discovery-auditor]] の監査は空振りする。

## decisions.md（決定ログ）

各項目を **決定 / 保留 / 仮置き(assumption)** に区別して記録する。

| id | テーマ | 内容 | 区分(決定/保留/仮置き) | 確信度(高/中/低) | 根拠・前提 | Phase | 更新日 |
|---|---|---|---|---|---|---|---|

- **決定(decision)**: ユーザーが明示的に確定したもの。
- **保留(pending)**: 決める必要があるが未決。`open-questions.md` と対応。
- **仮置き(assumption)**: AI または暫定で置いた前提。**確定ではない**。下流（画面設計・実装）へ渡る前に必ず昇格 or 解消する。

前提(assumption)と決定(decision)を分離することで、[[discovery-auditor]] が矛盾を検出でき、「仮置きのまま画面設計に渡った」事故を防げる。

## open-questions.md（未確定事項）

`decisions.md` の保留・仮置きの裏返し。「何を・誰が・いつまでに決めるか」を管理する。

| # | 項目 | 内容 | 種別(保留/仮置き/要確認) | 確認相手 | 影響Phase | 期限 |
|---|---|---|---|---|---|---|

# Phase完了基準と確信度

各 Phase は「終わったか」を判定できなければループが止まらない／早すぎる引き渡しが起きる。各フェーズ終了時に必ず判定する。

```text
## Phase完了判定: Phase<N> <名前>
- 必須項目カバー率: <x/y>
- 未解消の保留: <件数>
- 未昇格の仮置き(assumption): <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し（→ どのPhaseへ）
```

未昇格の仮置きが残るフェーズは「完了」にしない（浅い暫定として明示的に通す場合のみ例外、その旨を記録）。

# 差し戻しループ（再入可能性）

Phase 1→13 の一方通行ではない。後段の発見が前段を更新する。

- 例: Phase5(Business) で課金モデルが決まると Phase2 の必須機能が変わる → Phase2 を差し戻して更新。
- 例: Phase9(Data) で PII の保持期間が決まると Phase7(Legal)・Phase8(Risk) が更新される。

差し戻しが発生したら `decisions.md` の該当行を更新し、影響Phaseを再オープンする。[[discovery-auditor]] が Phase間矛盾を検出したときも同様に差し戻す。

# Agent連携（Discovery ループ）

各フェーズは次のループで進める。**実装ループの [[agent-planner]] / [[agent-tester]] は使わない**（カテゴリ違反）。

```text
フェーズ着手
 → [[discovery-planner]]: 次に決めるべき1問に絞る（意思決定を1件に）
 → ユーザー回答（必ず停止して確認）
 → decisions.md / open-questions.md を更新
 → フェーズ成果物を更新
 → Phase完了判定
 → 全フェーズ後 [[discovery-auditor]]: 横断監査（決定 vs 仮置き / Phase間矛盾 / 幽霊ドキュメント）
 → 差し戻し or 引き渡し
```

# 完了条件

全フェーズ（実装済 + ユーザーがスキップを承認した未実装フェーズ）が完了判定を通過し、[[discovery-auditor]] が以下を確認したとき完了とする。

- 全ドキュメント横断で矛盾が無い
- 未昇格の仮置き(assumption)が下流に渡らない（解消 or ユーザー承認済み）
- MVP の線が `release-plan.md`（または暫定）で1本引かれている
- 実装引き継ぎに必要な情報が `implementation-brief.md` に揃っている

# 次工程への引き渡し

[[screen-design-architect]] へ渡す際は **全ドキュメントを渡さない**。UI設計に必要な情報だけを抽出する。

- 渡す: `requirements/requirements.md` / `requirements/requirements-checklist.md` / `requirements/screen-catalog-draft.md` / `user-flows.md` / `admin-flows.md` から画面設計に必要な部分
- 原則渡さない: 法務 / 運営 / 収益 / リスク情報

`implementation-brief.md` にこの抽出結果と、確定済みの前提・禁止事項・未解決の仮置き（あれば明示）をまとめる。

# Output Template

### Phase1 Scope（[[scope-discovery]] が生成）

旧 `project-vision.md` は廃止し、[[scope-discovery]] の `scope/` 配下に吸収した（Output Template は [[scope-discovery]] 参照）。
- 誰の課題か / なぜ作るか → `scope/project-overview.md`
- 成功状態（Metrics で測定可能化する前提）→ `scope/goals.md`
- MVP仮説 / 将来構想 → `scope/mvp-boundary.md`
- 対象 / 対象外 → `scope/in-scope.md` / `scope/out-of-scope.md`

### decisions.md

```md
# 意思決定ログ
| id | テーマ | 内容 | 区分(決定/保留/仮置き) | 確信度 | 根拠・前提 | Phase | 更新日 |
|---|---|---|---|---|---|---|---|
```

### open-questions.md

```md
# 未確定事項
| # | 項目 | 内容 | 種別(保留/仮置き/要確認) | 確認相手 | 影響Phase | 期限 |
|---|---|---|---|---|---|---|
```

### user-flows.md

```md
# 利用者導線
## <導線名>（入口 → … → 完了。分岐・エラーも明示）
```

### admin-flows.md

```md
# 管理導線
## 管理者の有無 / 権限 / 承認 / 投稿管理 / 問い合わせ管理 / レポート / KPI確認
```

### implementation-brief.md

```md
# 実装前ブリーフ（次工程引き渡し用）
## screen-design-architect へ渡す情報（抽出）
## 確定済み前提
## 未解決の仮置き（あれば明示）
## 禁止事項
## 次工程: screen-design-architect → feature-spec-writer → implementation-planner
```

# セルフチェック

- ユーザー発言の書き起こしで終わっていないか（AIが穴を発見・提案したか）
- 仮置き(assumption)に必ずフラグを付け、`decisions.md` / `open-questions.md` に集約したか
- 1サイクル＝1テーマに絞り、停止してユーザー確認したか（認知負荷制御）
- 未実装フェーズに到達したとき、捏造せず「後で実装」として扱いユーザーに選ばせたか
- 後段の発見で前段を差し戻したか（一方通行になっていないか）
- 各Phaseで完了判定（確信度つき）を出したか
- 引き渡しで全ドキュメントを渡さず、UI設計に必要な情報だけ抽出したか
- 実装ループの [[agent-planner]] / [[agent-tester]] を誤って流用していないか（discovery 用を使ったか）
- 既存コード / DB / API / UI に変更を加えていないか

---

関連スキル: [[discovery-planner]]（次に決める1問）/ [[discovery-auditor]]（横断監査）/ [[requirements-discovery]]（Phase2 機能発見）/ [[data-discovery]]（Phase9 データ発見）/ [[legal-discovery]]（Phase7 必要法務成果物の発見）/ [[screen-design-architect]]（UI設計・次工程）。[[scope-discovery]]（最前段の境界確定 + 再入MVPゲート）。個別ドメイン: [[metrics-discovery]]（Phase11 実装済）/ [[business-discovery]]（Phase5 実装済・事業成立条件）/ [[operations-discovery]]（Phase6 実装済・運用実態の発見）/ [[integration-discovery]]（Phase10 実装済・外部連携の発見）/ [[contract-discovery]]（Phase7a 実装済・契約条件と相手の発見）/ [[risk-discovery]]（Phase8 実装済）/ [[nfr-discovery]]（Phase12 実装済）。
