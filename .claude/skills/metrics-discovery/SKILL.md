---
name: metrics-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
description: >-
  Project Discovery の Phase11（Metrics / Success Discovery）担当。プロジェクトの目的・成功条件・利用状況を、
  後続工程で扱える「計測可能な指標」に変換する。scope/goals.md の曖昧な「成功状態」を North Star / KPIツリー /
  計測イベント / 計測手段に落とし、MVPで最低限見るべき指標を 3〜7個に絞る。KPIダッシュボード設計・SQL・BI設計・
  イベント実装はしない（計測上の意味の定義に徹する）。
  トリガー例: 「成功条件を指標化したい」「KPIを決めたい」「何を計測すればいいか整理して」「North Star を決めたい」
  「MVPで見るべき指標を絞りたい」「計測イベントを洗い出して」「KPIツリーを作って」。
  入力は [[scope-discovery]] の scope/goals.md（成功状態・KPI候補）。出力は [[business-discovery]] /
  [[nfr-discovery]] / [[risk-discovery]] / [[operations-discovery]] の入力になる。
  [[project-discovery]] から名前で参照され、[[discovery-planner]] / [[discovery-auditor]] のループ内で動く。
---

# Purpose

`metrics-discovery` は、プロジェクトの目的・成功条件・利用状況を、後続工程で扱える **計測可能な指標** に変換するための Discovery Skill である。[[project-discovery]] の **Phase11（Metrics / Success Discovery）** を担う。

この Skill は KPI ダッシュボードを設計するものではない。また、分析基盤・イベント実装・SQL・BI設計も行わない。

目的は、以下を明確にすること。

* プロジェクトが何をもって成功と判断されるか
* MVP時点で最低限見るべき指標は何か
* 将来的に追うべき指標は何か
* どのユーザー行動・業務行動を計測イベントとして扱うか
* 指標の改善判断に必要な前提・分母・頻度・責任者は何か

[[scope-discovery]] の `scope/goals.md` に置かれた **曖昧なKPI候補・成功状態** を、1か所で測定可能化するのがこの工程の存在理由である。

---

## Inputs

KPIは **機能 → ユーザー行動 → イベント → KPI** の順に立ち上がる。したがって metrics は scope より [[requirements-discovery]] への依存が強い。依存の実体は次の通り。

```text
requirements（機能・業務フロー・画面導線）
  ↓
scope（成功状態・KPI候補・MVP境界）
  ↓
metrics（North Star / KPI / イベント / 計測計画）
```

参照する成果物は以下。**カッコ内が実際の生成元と実ファイル名**。

**必須（これが無いと KPI を行動・イベントに紐付けられない）**

* `requirements/requirements-checklist.md` — 機能・業務フロー・通知連携（[[requirements-discovery]]）
* `requirements/screen-catalog-draft.md` — 主要画面・導線・状態（[[requirements-discovery]]。独立した `user-journeys.md` / `features.md` は存在しない）

**推奨（成功定義・分母・利用者区分の裏取りに使う）**

* `scope/goals.md` — 成功状態 / KPI候補（[[scope-discovery]]）
* `scope/users.md` — 利用者種別 / ペルソナ（[[scope-discovery]]。`personas.md` は無く `users.md` に集約）
* `scope/mvp-boundary.md` — MVP範囲の仮説（[[scope-discovery]]）
* `release-plan.md` — MVPの確定線（[[scope-discovery]] 再入ゲート / **root直下**）
* `decisions.md` / `open-questions.md` — 決定・未確定ログ（[[project-discovery]]）

> 必須入力が欠けている場合、KPIを行動・イベントに接地できないため [[requirements-discovery]] に差し戻すのが原則。曖昧な箇所を推測で確定しない。仮置きは `Assumptions`（=`decisions.md` の `仮置き`）として置き、必要なら [[scope-discovery]] / [[project-discovery]] へ差し戻す（[Backward Handoff Rules](#backward-handoff-rules)）。

---

## Outputs

`metrics/` 配下に **`domain/index.md` パターン** で生成する。Discovery Suite 全体（legal / scope / data / risk / nfr も将来分割される）と揃えるため、ドメインごとに index を1本立て、詳細を分割する。

| ファイル | 役割 |
|---|---|
| `metrics/metrics.md` | **index**。探索の全体まとめ（成功定義 / サマリ / Assumptions）。**[[project-discovery]] の正式参照先**。 |
| `metrics/kpi.md` | KPIツリー（North Star / Primary / Supporting / Guardrail / Diagnostic） |
| `metrics/events.md` | 計測イベント定義（計測上の意味のみ・実装詳細なし） |
| `metrics/measurement.md` | 各指標の確認方法（Source / Event / 集計 / 頻度 / Owner） |
| `decisions.md` / `open-questions.md` | 決定・保留・仮置き・差し戻しの記録（[[project-discovery]] と同期） |

> 旧 `metrics.md`（root直下）は廃止。参照は **必ず `metrics/metrics.md`** に統一する（責務の二重化を避ける）。
> 小規模なら index の `metrics/metrics.md` 1本に集約し、kpi / events / measurement は同ファイル内のセクションでもよい。

---

## Discovery Targets

### 1. Success Definition

以下を確認する。

* このプロジェクトの成功とは何か
* 事業上の成功と、ユーザー体験上の成功を分けられるか
* MVP時点で「最低限うまくいっている」と判断する条件は何か
* 失敗と判断する条件は何か
* 成功判断に定量指標が必要か、定性判断で足りるか

出力では以下に分類する。

* Business Success
* User Success
* Operational Success
* MVP Success
* Failure Signals

---

### 2. Goal to KPI Conversion

`scope/goals.md` の目標を、計測可能な KPI に変換する。各目標について以下を整理する。

* Goal
* KPI候補
* 分子
* 分母
* 計測単位
* 計測頻度
* 目標値
* MVP時点で必要か
* 後回しでよいか
* 判断に使えるか

KPIは無理に増やさない。MVPでは **3〜7個程度** に絞る。

---

### 3. KPI Tree

KPIを以下の階層で整理する。

* North Star Metric: プロジェクト全体の価値を代表する指標
* Primary KPI: 主要な成功判断に使う指標
* Supporting KPI: Primary KPI の原因分析に使う指標
* Guardrail Metric: 改善の副作用を検知する指標
* Diagnostic Metric: 問題発見・調査用の補助指標

---

### 4. Funnel / Journey Metrics

[[requirements-discovery]] の業務フロー / `requirements/screen-catalog-draft.md` を参照し、主要導線ごとに計測ポイントを定義する。

例: 訪問 / 登録開始 / 登録完了 / 検索 / 詳細閲覧 / 予約開始 / 予約完了 / 問い合わせ / 再訪 / 継続利用。

各導線について以下を整理する。

* Journey Name
* Step
* User Action
* Success Event
* Drop-off Point
* Related KPI
* Required Event

---

### 5. Event Catalog

計測すべきイベントを定義する。各イベントには以下を含める。

* event_name
* description
* actor
* trigger
* properties
* related_kpi
* priority
* mvp_required
* notes

命名は snake_case を基本にする。

```text
reservation_started
reservation_completed
lead_generated
brief_generated
screen_viewed
search_executed
cta_clicked
```

イベントは実装詳細ではなく、**計測上の意味** で定義する。DBテーブル設計・ログ基盤設計には踏み込まない。

---

### 6. Measurement Plan

各指標について、どう確認するかを整理する。

* Metric / Source / Required Event / Aggregation / Frequency / Owner / MVP Required / Unknowns

Source の粒度: `app_event` / `admin_action` / `database_record` / `manual_check` / `external_tool` / `survey` / `support_log`。

---

### 7. Assumptions / Unknowns

入力不足がある場合は推測で確定しない。以下に分類し、`decisions.md` / `open-questions.md` に記録する（[意思決定の記録](#意思決定の記録)）。

* Assumption（=仮置き）: 仮置きして進めるもの。事実として扱わない。
* Unknown（=保留）: 判断不能なもの → `open-questions.md`。
* Needs Discovery: [[project-discovery]] / [[scope-discovery]] に戻すもの。
* Deferred: MVP後でよいもの。

---

## 質問ルール

一度に大量質問しない。常に **「次に決めるべき1件」** のみ質問する。深掘りの1問は [[discovery-planner]] が作る。

各回答は **決定 / 保留 / 仮置き / 未定 / コメント** で返せる形にする。

### 質問の優先順位

1. 成功定義（何をもって成功か）
2. North Star Metric
3. MVP Primary KPI（3〜7個に絞る）
4. KPIの分子・分母・頻度
5. 主要導線の計測イベント
6. Guardrail Metric

---

## 意思決定の記録

不明・未確定は **決定 / 保留 / 仮置き** に分類して `decisions.md` に記録する（[[project-discovery]] の決定ログ機構）。

* **決定(decision)**: ユーザーが確定した指標・目標値・成功条件。
* **保留(pending)**: 決める必要があるが未決 → `open-questions.md` へ。
* **仮置き(assumption)**: AI/暫定で置いた前提（目標値・分母など）。**事実として扱わない**。下流（business / nfr 等）へ渡る前に必ず昇格 or 解消する。

---

## Discovery Loop

```text
入力成果物（scope/goals 等）を確認
 → Goal / User / Journey / Feature / MVP の関係を読む
 → 成功条件を抽出
 → [[discovery-planner]]: 次に決めるべき1件に絞って質問（優先順位順 / 1テーマ1問）
 → ユーザー回答（必ず停止して確認）
 → Goal を KPI 候補へ変換 / MVP KPI を 3〜7個に絞る
 → Journey からイベント候補を抽出 / KPI と Event の対応を確認
 → 不足・矛盾・過剰計測を洗い出す（必要なら上流へ差し戻す）
 → metrics/ を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 [[discovery-auditor]] へ（KPIと計測の整合・過剰計測を監査）
 → business / nfr / risk / operations へ引き渡し
```

---

## Backward Handoff Rules

以下の場合は [[project-discovery]] または [[scope-discovery]] に差し戻す。差し戻し時は **質問を1つに絞る**。

* プロジェクトの目的が不明
* 成功条件が曖昧
* MVP範囲が未定
* ユーザー種別が未定
* 主要導線が未定
* KPI化できる目標が存在しない
* 計測対象の行動が不明
* 指標が多すぎて優先順位が決められない

---

## Completion Criteria

兄弟Skill共通の体裁だけでは「`登録数を増やす` とだけ書いて完了」になりかねない。metrics は **「測りたいもの ≠ 作るもの」** に陥りやすいので、metrics特有の完了条件を満たすこと（[Phase完了判定](#phase完了判定)を出す）。

* [ ] North Star Metric が定義されている
* [ ] **MVP成功判定が定義されている**（何をもって「MVPがうまくいった」と言うか）
* [ ] MVP Primary KPI が 3〜7個に絞られている
* [ ] KPIごとに分子・分母・頻度が定義されている
* [ ] **主要ユーザーフローに計測イベントが紐付いている**（イベント無しの宙に浮いたKPIが無い）
* [ ] **各KPIに計測方法（measurement）が存在する**（測定不可能な指標を完了扱いにしない）
* [ ] **各KPIに責任者(Owner) または 確認タイミング が存在する**
* [ ] MVP必須イベントと後回しイベントが分離されている
* [ ] Guardrail Metric が最低1つある
* [ ] **仮置きKPI（assumption）が `open-questions.md` に移送済み**（未昇格の仮置きが残る間は「完了」にしない。ユーザーが暫定通過を明示承認した場合のみ例外、その旨を記録）
* [ ] [[business-discovery]] / [[nfr-discovery]] に渡せる形になっている

### Phase完了判定

```text
## Phase完了判定: Metrics / Success Discovery (Phase11)
- North Star Metric: 定義済み / 未定義
- MVP成功判定: 定義済み / 未定義
- MVP Primary KPI: <n>個（3〜7に収まっているか）
- 分子・分母・頻度の充足: <x/n>
- 計測方法(measurement)を持つKPI: <x/n>
- Owner/確認タイミングを持つKPI: <x/n>
- 主要フローへのイベント紐付け: <x/y>
- Guardrail Metric: <件数>
- 未解消の保留: <件数>
- open-questions.md へ移送済みの仮置きKPI: <件数> / 未昇格の仮置き: <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

---

## Output Template

```md
# metrics-discovery

## 1. Summary
* Project:
* Metrics Discovery Status:
* Confidence:
* Main Success Definition:

## 2. Success Definition
### Business Success
| Success | Reason | MVP Required |
| ------- | ------ | ------------ |
### User Success
| Success | User Type | Reason | MVP Required |
| ------- | --------- | ------ | ------------ |
### Operational Success
| Success | Operator | Reason | MVP Required |
| ------- | -------- | ------ | ------------ |
### Failure Signals
| Signal | Meaning | Related Metric |
| ------ | ------- | -------------- |

## 3. KPI Tree
### North Star Metric
| Metric | Definition | Why it matters | MVP Required |
| ------ | ---------- | -------------- | ------------ |
### Primary KPI
| KPI | Definition | Numerator | Denominator | Frequency | Target | MVP Required |
| --- | ---------- | --------- | ----------- | --------- | ------ | ------------ |
### Supporting KPI
| KPI | Supports | Definition | Frequency |
| --- | -------- | ---------- | --------- |
### Guardrail Metrics
| Metric | Prevents | Definition | Frequency |
| ------ | -------- | ---------- | --------- |
### Diagnostic Metrics
| Metric | Used For | Definition |
| ------ | -------- | ---------- |

## 4. Goal to KPI Mapping
| Goal | KPI | Metric Type | MVP Required | Notes |
| ---- | --- | ----------- | ------------ | ----- |

## 5. Journey Metrics
| Journey | Step | User Action | Success Event | Drop-off Point | Related KPI |
| ------- | ---- | ----------- | ------------- | -------------- | ----------- |

## 6. Event Catalog
| event_name | description | actor | trigger | properties | related_kpi | priority | mvp_required |
| ---------- | ----------- | ----- | ------- | ---------- | ----------- | -------- | ------------ |

## 7. Measurement Plan
| Metric | Source | Required Event | Aggregation | Frequency | Owner | MVP Required |
| ------ | ------ | -------------- | ----------- | --------- | ----- | ------------ |

## 8. Assumptions
| Assumption | Reason | Risk | Confirm By |
| ---------- | ------ | ---- | ---------- |

## 9. Unknowns / Backward Handoff
| Unknown | Needed By | Handoff To | Question |
| ------- | --------- | ---------- | -------- |

## 10. Deferred Metrics
| Metric | Reason Deferred | Revisit Timing |
| ------ | --------------- | -------------- |
```

---

## Self Check

* [ ] 成功条件が定義されている
* [ ] North Star Metric がある
* [ ] MVP Primary KPI が 3〜7個に絞られている
* [ ] KPIごとに分子・分母・頻度がある
* [ ] 主要導線ごとにイベントがある
* [ ] MVP必須イベントと後回しイベントが分離されている
* [ ] Guardrail Metric がある
* [ ] Assumptions / Unknowns が `decisions.md` / `open-questions.md` に分離されている
* [ ] 上流への差し戻し質問が1件単位になっている
* [ ] 1テーマ1問・優先順位順に質問したか（大量質問していないか）
* [ ] SQL / DB / BI / 計測ツール設定に踏み込んでいないか
* [ ] [[business-discovery]] / [[nfr-discovery]] に渡せる

---

## Prohibited

この Skill では以下を行わない。

* SQL設計 / DBテーブル設計 / BIダッシュボード設計
* GA4 / Mixpanel / PostHog 等の具体設定
* イベント送信コードの実装
* 数値目標の根拠なき断定
* すべてを計測しようとする過剰設計
* KPIとただのログ項目の混同
* MVP外の高度分析を必須化すること
* 情報不足を仮定で確定すること（仮置きは `decisions.md` に明示）

---

## Handoff

### To [[business-discovery]]
Business Success / North Star Metric / Primary KPI / Goal to KPI Mapping / Failure Signals

### To [[nfr-discovery]]
Measurement frequency / Required event volume / Data retention needs / Reporting latency needs / Availability impact of metrics

### To [[risk-discovery]]
Failure Signals / Guardrail Metrics / Missing measurement risks / KPI gaming risks

### To [[operations-discovery]]
Metric Owner / Manual Check Items / Reporting Frequency / Operational Success Metrics

### To [[discovery-auditor]]
metrics は他Skillと違い **「測りたいもの ≠ 作るもの」** のズレが起きやすい。監査では特に以下を確認する。

* KPIが **MVP外機能に依存していないか**（MVPで測れないKPIをMVP必須にしていないか）
* **測定不可能な指標** が含まれていないか
* **イベント定義なしでKPI化** していないか（計測手段が無いKPI）
* **数値目標が根拠なく** 設定されていないか
* KPIと計測イベントの整合 / 過剰計測・KPI数（3〜7）の妥当性 / 未昇格の仮置き

---

関連スキル: [[project-discovery]]（オーケストレーター・Phase11）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（KPI・計測監査）/ 入力元: [[scope-discovery]]（goals）・[[requirements-discovery]]（導線）/ 引き渡し先: [[business-discovery]] / [[nfr-discovery]] / [[risk-discovery]] / [[operations-discovery]]。
