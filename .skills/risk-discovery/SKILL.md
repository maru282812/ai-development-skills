---
name: risk-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
description: >-
  Project Discovery の Phase8（Risk Discovery）担当。セキュリティ監査・脆弱性診断・インフラ設計をするスキルではない。
  business / operations / integration / legal / metrics の成果物を入力に、「MVP検証・事業継続・運営継続を妨げる
  主要リスクと、それを支える前提条件（assumptions）」を発見し、risk/ 配下に整理する。
  MVP成立 / 集客 / 継続 / 収益 / 運営 / 外部依存 / 法務 / 評判 の各リスクを洗い出し、
  発生可能性 × 影響度で優先順位を付け、受容(Accepted) / 軽減(Mitigated) / 後回し(Deferred) / 情報不足(Unknown) に分類する。
  トリガー例: 「リスクを洗い出して」「何が起きたら事業が失敗するか整理して」「前提条件を明確にしたい」
  「集客できなかった場合の代替を考えたい」「API停止時にサービス継続できるか整理して」「リスクの優先順位を付けて」。
  入力は [[business-discovery]] / [[operations-discovery]] / [[integration-discovery]] / [[legal-discovery]] / [[metrics-discovery]] の成果物。
  脆弱性診断・ペネトレーションテスト・インフラ/DB/API設計・実装方式の決定はしない。
  可用性/性能/バックアップ/復旧要求は [[nfr-discovery]]、返金/SLA/サポート/責任範囲は [[contract-discovery]] へ渡す。
  [[project-discovery]] から参照され、[[discovery-planner]] / [[discovery-auditor]] のループ内で動く。
---

# Purpose

`risk-discovery` は、プロジェクト・事業・運営・外部依存に存在する **主要リスクを発見し、前提条件（assumptions）を明確化する** ための Discovery Skill である。[[project-discovery]] の **Phase8（Risk Discovery）** を担う。

このスキルは **リスクを完全に排除することを目的としない**。また **セキュリティ監査・脆弱性診断を行うスキルでもない**。WAF・Redis・AWS構成・暗号化方式といった技術的対策の決定には踏み込まない。

目的は、以下を明確にすることである。

* **MVP検証・事業継続・運営継続を妨げる要因** を発見する
* どのリスクを **受容（Accepted）** し、
* どのリスクを **軽減（Mitigated）** し、
* どのリスクを **後回し（Deferred）** にし、
* どのリスクが **情報不足（Unknown）** で判断できないかを整理する
* 事業が成立する前提条件（assumptions）を明文化し、**それが崩れたら何が壊れるか** を言語化する

[[business-discovery]] が「事業として回るか」、[[operations-discovery]] が「運営し続けられるか」、[[integration-discovery]] が「外部と繋がるか」を発見するのに対し、risk-discovery は **「それらが失敗するとしたら、どの前提が崩れたときか」** を発見する。

> risk-discovery は **断定しない**。推測でリスクを過大・過小評価しない。不明点は `risk/assumptions.md` / `open-questions.md` に分類する。ただし **集客・継続・KPI計測・属人化・API依存・収益前提が曖昧なまま完了扱いにしない**。セキュリティだけをリスク扱いして他を見落とすことを最大の失敗とみなす。

---

# When to use

主に **以下の Phase が完了した後** に実行する。主要な事業仮説・運営体制・外部依存が整理された後でなければ、リスクを接地できない。

* [[business-discovery]]（Phase5）— 収益・集客・提供価値の仮説
* [[operations-discovery]]（Phase6）— 運営体制・運営業務
* [[integration-discovery]]（Phase10）— 外部依存・連携・失敗時対応
* [[legal-discovery]]（Phase7）— 法務論点
* [[metrics-discovery]]（Phase11）— KPI・計測手段

**使う場面**

* 主要仮説が出揃い「何が起きたら失敗するか」を整理したいとき
* MVP公開前に、検証・継続・集客・収益・運営の前提を点検したいとき
* 「API停止」「集客失敗」「問い合わせ急増」「担当者不在」など、特定リスクの扱いを決めたいとき

**使わない / 渡す先**

* 可用性・性能・バックアップ・復旧などの非機能要求 → [[nfr-discovery]]
* 返金条件・SLA・サポート範囲・責任範囲 → [[contract-discovery]]
* 脆弱性診断・ペネトレーションテスト・インフラ/DB/API設計 → **範囲外（行わない）**

---

# Inputs

リスクは **事業仮説・運営体制・外部依存・法務・KPI が整理された後でなければ接地できない**。参照する成果物は以下。**カッコ内が実際の生成元と実ファイル名**。

**必須（これが無いとリスクを接地できない）**

* `business/business-model.md` — 事業の核 / MVP事業仮説（[[business-discovery]]）
* `business/revenue.md` — 収益構造 / 課金前提（[[business-discovery]]）
* `business/go-to-market.md` — 初期流入経路 / 集客前提（[[business-discovery]]）
* `operations/operations.md` — 運営体制 index（[[operations-discovery]]）
* `operations/operational-workflows.md` — 日次・週次・月次運用 / 異常時対応（[[operations-discovery]]）
* `integration/integration.md` — 外部依存 index（[[integration-discovery]]）
* `integration/failure-handling.md` — 外部失敗時の扱い（[[integration-discovery]]）
* `legal/legal.md` — 法務論点・必要成果物（[[legal-discovery]]）
* `metrics/metrics.md` — North Star / KPI / 計測手段（[[metrics-discovery]]）

**推奨（裏取り・前提強化に使う）**

* `scope/users.md` — 利用者種別（[[scope-discovery]]）
* `scope/stakeholders.md` — 運営者 / 支払者 / 利用者（[[scope-discovery]]）
* `requirements/requirements-checklist.md` — 機能・業務フロー（[[requirements-discovery]]）
* `decisions.md` / `open-questions.md` — 決定・未確定ログ（[[project-discovery]]）

> 必須入力が欠けている場合、リスクを推測で確定せず上流へ差し戻すのが原則（[Handoff](#handoff--差し戻し条件)）。「依存先が未整理だからリスク判定不能」という状態自体を Unknown として記録する。

---

# Outputs

`risk/` 配下に **`domain/index.md` パターン** で生成する。Discovery Suite 全体（business / operations / metrics …）と揃えるため、ドメイン index を1本立て、観点ごとに分割する。

| ファイル | 役割 |
|---|---|
| `risk/risk.md` | **index**。主要リスクの要約 / リスク分類サマリ / assumptions への導線。**[[project-discovery]] の正式参照先**。 |
| `risk/business-risks.md` | 事業リスク（収益不成立 / 単価不足 / 採算割れ など） |
| `risk/operational-risks.md` | 運営リスク（属人化 / 問い合わせ過多 / 手作業破綻 など） |
| `risk/integration-risks.md` | 外部依存リスク（API停止 / 規約変更 / アカウント停止 / 価格改定 など） |
| `risk/legal-risks.md` | 法務リスク（個人情報 / 決済 / 利用規約 / 第三者提供 など） |
| `risk/adoption-risks.md` | 利用・継続・集客リスク（初期獲得失敗 / リピートされない / 習慣化されない など） |
| `risk/risk-register.md` | **全リスク一覧**。優先度 / 発生可能性 / 影響度 / 対応方針 を一表で管理 |
| `risk/assumptions.md` | 事業成立の前提条件 / 成立しない場合に崩壊する仮説 |
| `decisions.md` / `open-questions.md` | 決定・保留・仮置き・差し戻しの記録（[[project-discovery]] と同期） |

> 小規模なら index の `risk/risk.md` と `risk/risk-register.md` / `risk/assumptions.md` の3本に集約し、観点別は同ファイル内のセクションでもよい。ただし **risk-register（優先順位）と assumptions（前提条件）は省略しない**。

---

# Discovery targets

必ず発見すること。**セキュリティに偏らず、以下8カテゴリを必ず一巡する**。

### 1. MVP成立リスク

* 検証に必要なユーザーが集まらない
* 検証データが取れない
* KPIが測定できない（`metrics/metrics.md` の計測手段が実在しない / 接続されていない）

### 2. 集客リスク

* 初期ユーザー獲得失敗
* 想定流入が不足する
* CPA（獲得単価）が悪化する

### 3. 継続リスク

* 一度使って終わる
* リピートされない
* 習慣化されない

### 4. 収益リスク

* 課金されない
* 単価が不足する
* 採算割れする

### 5. 運営リスク

* 属人化（特定担当者に依存）
* 問い合わせ過多
* 手作業が破綻する

### 6. 外部依存リスク

* API停止
* 利用規約変更
* アカウント停止
* 価格改定

### 7. 法務リスク

* 個人情報
* 決済
* 利用規約
* 第三者提供

### 8. 評判リスク

* 誤通知
* 誤課金
* 炎上
* 信頼失墜

### 9. Assumptions / Unknowns

入力不足は推測で確定しない。以下に分類して記録する。

* Assumption（前提）: 事業が成立するための前提条件。崩れたら何が壊れるかをセットで書く。
* Unknown（情報不足）: 判断不能 → `open-questions.md` ＋ risk-register に Unknown として残す。
* Deferred: MVP後でよい。
* Needs Discovery: 上流へ戻す → business / operations / integration / legal / metrics。

---

# Question logic

質問は **「何が起きると事業・運営・検証が失敗するか」** を明らかにするために行う。技術的対策の質問は禁止する。

一度に大量質問しない。常に **「次に検証すべきリスク仮説」1件だけ** を質問する（深掘りの1問は [[discovery-planner]] が作る）。各回答は **受容 / 軽減 / 後回し / 情報不足 / コメント** で返せる形にする。

**禁止例（技術対策・インフラに踏み込む質問）**

* Redisを入れますか
* WAFを導入しますか
* AWS構成はどうしますか

**許可例（失敗条件を明らかにする質問）**

* API停止時にサービス継続できますか
* 集客できなかった場合の代替手段はありますか
* 問い合わせが10倍になった場合どうなりますか
* 主要担当者が不在になったら運営できますか

### 質問の優先順位

1. 何が起きたら **MVP検証そのものが成立しないか**（ユーザー / データ / KPI計測）
2. 集客が成立しなかった場合、どうするか
3. 一度使って終わった場合、何が崩れるか
4. 主要な外部依存（API / アカウント）が止まったらどうなるか
5. 運営が属人化・破綻する条件は何か
6. 収益前提が崩れる条件は何か

---

# Discovery loop

```text
入力成果物（business / operations / integration / legal / metrics）を確認
 → 8カテゴリ（MVP成立 / 集客 / 継続 / 収益 / 運営 / 外部依存 / 法務 / 評判）の現状リスクを読む
 → metrics/metrics.md の計測手段が実在し KPI に接続しているか照合（KPI未接続リスクの検出）
 → [[discovery-planner]]: 次に検証すべきリスク仮説を1件に絞って質問（最初は一問・優先順位順・技術対策は聞かない）
 → ユーザー回答（必ず停止して確認）
 → 該当カテゴリの risk ファイルを更新 / risk-register に 発生可能性 × 影響度 × 対応方針 を記録
 → 対応方針を Accepted / Mitigated / Deferred / Unknown に分類
 → 前提条件を assumptions.md に追記（崩れたら何が壊れるかをセットで）
 → [[discovery-auditor]]: KPI未接続 / 属人化 / API依存 / 収益前提崩壊 / 集客前提崩壊 / 法務前提崩壊 を検出
 → 不足・矛盾を洗い出す（必要なら上流へ差し戻す）
 → risk/ を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 nfr-discovery / contract-discovery へ引き渡し
```

---

# Risk classification

すべてのリスクは risk-register 上で **発生可能性（高/中/低）× 影響度（高/中/低）** で評価し、対応方針を以下の4区分のいずれかに必ず分類する。

### Accepted（受容）

* リスクを認識した上で、対応せず受け入れる。**なぜ受容してよいか** の理由を必ず書く。

### Mitigated（軽減）

* 発生可能性または影響度を下げる。**具体的な軽減策（運営・事業・連携レベル。技術対策の設計はしない）** を書く。

### Deferred（後回し）

* MVP時点では扱わず後回しにする。**いつ・何をトリガーに再検討するか** を書く。

### Unknown（情報不足）

* 判断材料が足りず分類できない。`open-questions.md` に移送し、**何が分かれば分類できるか** を書く。

> Unknown を残したまま「完了」にしてはならない。Unknown は risk-register 上に明示して残し続ける。

---

# Handoff / 差し戻し条件

## Backward Handoff（差し戻し）

以下の場合は上流に差し戻す。差し戻し時は **質問を1つに絞る**。

| 状況 | 差し戻し先 |
|---|---|
| 収益モデル / 集客モデルが崩壊する前提なのに事業仮説が未整理 | [[business-discovery]] |
| 運営体制が不足 / 属人化していてリスク判定できない | [[operations-discovery]] |
| 外部API依存が整理されておらず停止リスクを評価できない | [[integration-discovery]] |
| 法務論点が未整理でリスク評価できない | [[legal-discovery]] |
| KPIが計測不能 / リスク監視指標が無い | [[metrics-discovery]] |

## Forward Handoff（引き渡し）

* **To [[nfr-discovery]]**: 可用性要求 / 性能要求 / バックアップ要求 / 復旧要求（外部依存・データ消失リスクから導かれる非機能要求）
* **To [[contract-discovery]]**: 返金条件 / SLA / サポート範囲 / 責任範囲（誤課金・障害・外部停止リスクから導かれる契約論点）
* **To [[discovery-auditor]]**: KPI未接続 / 属人化 / API依存 / 収益前提崩壊 / 集客前提崩壊 / 法務前提崩壊 の検出、未昇格の仮置き、assumptions の明文化漏れ

---

# Completion criteria

兄弟Skill共通の体裁だけでは「`セキュリティ` とだけ書いて完了」になりかねない。risk は **セキュリティに偏って集客・継続・KPI計測リスクを見落としやすい** ので、risk特有の完了条件を満たすこと（[Phase完了判定](#phase完了判定)を出す）。

* [ ] **MVP成立リスク** が整理されている
* [ ] **集客リスク** が整理されている
* [ ] **継続リスク** が整理されている
* [ ] **収益リスク** が整理されている
* [ ] **運営リスク**（属人化・問い合わせ過多・手作業破綻）が整理されている
* [ ] **外部依存リスク**（API停止・規約変更・アカウント停止・価格改定）が整理されている
* [ ] **法務リスク** が整理されている
* [ ] **評判リスク** が整理されている
* [ ] **risk-register にリスク優先順位が存在する**（発生可能性 × 影響度）
* [ ] すべてのリスクに **対応方針（Accepted / Mitigated / Deferred / Unknown）が存在する**
* [ ] **assumptions が明文化されている**（崩れたら何が壊れるかとセット）
* [ ] **不明点が `open-questions.md` に分離され、Unknown として register に残っている**

> セキュリティだけをリスク扱いし、集客・継続・KPI計測・属人化・API依存を見落としたまま完了にしてはならない。

### Phase完了判定

```text
## Phase完了判定: Risk Discovery (Phase8)
- MVP成立リスク: 整理 / 不足
- 集客リスク: 整理 / 不足
- 継続リスク: 整理 / 不足
- 収益リスク: 整理 / 不足
- 運営リスク（属人化含む）: 整理 / 不足
- 外部依存リスク（API依存含む）: 整理 / 不足
- 法務リスク: 整理 / 不足
- 評判リスク: 整理 / 不足
- risk-register の優先順位: あり / なし
- 対応方針の網羅: <分類済み/全件>（Accepted/Mitigated/Deferred/Unknown）
- assumptions の明文化: あり / なし
- 未解消の Unknown: <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

---

# Output templates

### risk/risk.md（index）

```md
# リスク: <プロダクト名>

## サマリ
* Project:
* Risk Discovery Status:
* Confidence:
* 最重要リスク（上位3）:

## リスク分類サマリ
| カテゴリ | 主要リスク | 最高優先度 | 対応方針の内訳 |
| -------- | ---------- | ---------- | -------------- |
| MVP成立 | | | Accepted/Mitigated/Deferred/Unknown |
| 集客 | | | |
| 継続 | | | |
| 収益 | | | |
| 運営 | | | |
| 外部依存 | | | |
| 法務 | | | |
| 評判 | | | |

## 参照
* 全リスク一覧: risk/risk-register.md
* 前提条件: risk/assumptions.md
```

### risk/risk-register.md

```md
# リスクレジスタ: <プロダクト名>

| ID | カテゴリ | リスク（何が起きると失敗するか） | 発生可能性(高/中/低) | 影響度(高/中/低) | 優先度 | 対応方針(Accepted/Mitigated/Deferred/Unknown) | 対応内容 / 再検討トリガー |
| -- | -------- | -------------------------------- | -------------------- | ---------------- | ------ | --------------------------------------------- | ------------------------- |
| R1 | | | | | | | |

> 優先度 = 発生可能性 × 影響度 から導く。Unknown は判断材料が揃うまで残す。
```

### risk/assumptions.md

```md
# 前提条件（Assumptions）: <プロダクト名>

> 事業・運営・検証が成立するために「正しいと仮定している」前提。崩れたら何が壊れるかをセットで書く。

| ID | 前提（成立を仮定していること） | 根拠 / 出典 | 崩れたら壊れるもの | 関連リスクID | 確認方法 / Confirm By |
| -- | ------------------------------ | ----------- | ------------------ | ------------ | --------------------- |
| A1 | | | | R? | |
```

### risk/business-risks.md / operational-risks.md / integration-risks.md / legal-risks.md / adoption-risks.md（共通フォーマット）

```md
# <カテゴリ>リスク: <プロダクト名>

| リスク（失敗条件） | 発生する前提 / トリガー | 発生可能性 | 影響度 | 対応方針 | 軽減策・代替手段（技術設計はしない） | register ID |
| ------------------ | ----------------------- | ---------- | ------ | -------- | ------------------------------------ | ----------- |
| | | | | | | R? |

## このカテゴリの assumptions（崩れると前提が崩壊する仮説）
| 前提 | 崩れたら | assumptions ID |
| ---- | -------- | -------------- |
```

---

# Self-check

* [ ] セキュリティだけをリスク扱いしていないか
* [ ] 集客リスクを忘れていないか
* [ ] 継続リスクを忘れていないか
* [ ] KPI計測不能リスクを忘れていないか
* [ ] 属人化を見逃していないか
* [ ] API依存を見逃していないか
* [ ] 8カテゴリ（MVP成立 / 集客 / 継続 / 収益 / 運営 / 外部依存 / 法務 / 評判）を一巡したか
* [ ] すべてのリスクに対応方針（Accepted / Mitigated / Deferred / Unknown）が付いているか
* [ ] risk-register に優先順位（発生可能性 × 影響度）があるか
* [ ] assumptions が明文化され、「崩れたら何が壊れるか」とセットになっているか
* [ ] Unknown を残したまま完了にしていないか
* [ ] 技術対策（Redis / WAF / AWS構成）の質問・決定をしていないか
* [ ] 非機能要求・契約論点を抱え込まず nfr / contract へ渡しているか
* [ ] 最初は一問だけ・優先順位順に質問したか（大量質問していないか）

---

# Prohibited

この Skill では以下を行わない。risk-discovery は **「失敗する前提条件の発見」** に集中する。

* 脆弱性診断
* ペネトレーションテスト
* インフラ設計
* AWS設計
* DB設計
* API設計
* 実装方式の決定
* 技術的セキュリティ対策（WAF / Redis / 暗号化方式 等）の決定
* 可用性・性能・バックアップ・復旧などの非機能要求の確定（→ [[nfr-discovery]]）
* 返金条件・SLA・サポート範囲・責任範囲の確定（→ [[contract-discovery]]）
* リスクの過大・過小評価を推測で断定すること（不明は Unknown として残す）
* セキュリティだけをリスク扱いし、集客・継続・KPI計測・属人化・API依存を見落とすこと

---

関連スキル: [[project-discovery]]（オーケストレーター・Phase8）/ [[discovery-planner]]（次に検証すべきリスク仮説1件）/ [[discovery-auditor]]（KPI未接続・属人化・API依存・収益/集客/法務前提崩壊の検出）/ 入力元: [[business-discovery]]（収益・集客・事業仮説）・[[operations-discovery]]（運営体制・属人化）・[[integration-discovery]]（外部依存・失敗時対応）・[[legal-discovery]]（法務論点）・[[metrics-discovery]]（KPI・計測手段）/ 引き渡し先: [[nfr-discovery]]（可用性/性能/バックアップ/復旧）・[[contract-discovery]]（返金/SLA/サポート/責任範囲）。
