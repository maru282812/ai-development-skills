---
name: operations-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
description: >-
  Project Discovery の Phase6（Operations Discovery）担当。機能要件・画面要件を定義するスキルではなく、
  インフラ設計・非機能設計を行うスキルでもない。「システムを継続運営するために必要な運用実態を発見する」工程。
  business / scope / requirements / metrics の成果物を入力に、運営者・管理者・サポート担当が実際に行う運営業務を整理し、
  誰が / いつ / 何を / どの頻度で行うのかを明確化する。運営主体 / 管理者と権限 / 日次・週次・月次運用 /
  問い合わせ対応 / コンテンツ更新フロー / 異常時対応 / 運営KPI / 運営負荷（手作業 vs 自動化）を発見し operations/ 配下に整理する。
  トリガー例: 「運営体制を整理したい」「誰が問い合わせ対応するか決めたい」「毎日必要な運用作業を洗い出して」
  「返金・削除依頼の対応フローを決めたい」「運営KPIを出して」「MVPで手作業運用する範囲を確定したい」。
  入力は [[business-discovery]] / [[scope-discovery]] / [[requirements-discovery]] / [[metrics-discovery]] の成果物。
  実装方法・DB・API・ER図・画面設計・非機能・インフラは決めない。運営規模・業務負荷は [[nfr-discovery]]、
  運営リスク・属人化は [[risk-discovery]]、返金/利用停止/SLA/サポート条件は [[contract-discovery]] へ渡す。
  [[project-discovery]] から参照され、[[discovery-planner]] / [[discovery-auditor]] のループ内で動く。
---

# Purpose

`operations-discovery` は、**システムを継続運営するために必要な運用実態を発見する** ための Discovery Skill である。[[project-discovery]] の **Phase6（Operations Discovery）** を担う。

このスキルは **機能要件や画面要件を定義するものではない**。また **インフラ設計や非機能設計を行うものでもない**。

目的は、運営者・管理者・サポート担当者が実際に行う運営業務を整理し、以下を明確化することである。

* **誰が** 運営・管理・サポートを担うのか
* **いつ**（日次 / 週次 / 月次 / 異常時）発生するのか
* **何を** 行うのか（作業内容）
* **どの頻度で** 行うのか

[[scope-discovery]] が「何を作るか」、[[requirements-discovery]] が「どう作るか」、[[business-discovery]] が「事業として回るか」を決めるのに対し、operations-discovery は **「作った後、誰が・どうやって運営し続けるのか」** を発見する。

> operations-discovery は **断定しない**。推測で運営体制を事実化しない。不明点は `decisions.md` / `open-questions.md` に分類し、仮置き可能なものは Assumption として明示する。ただし **運営主体・管理者・問い合わせ対応・異常時対応が宙に浮いたまま完了扱いにしない**。
>
> 特に **「自動化前提で逃げる」ことを禁止** する。MVP時点で手作業になる範囲を明確にし、運営負荷を過小評価しない。

---

# When to use

主に以下の Phase が完了した後に実行する。

* [[project-discovery]]（Phase0–1 概要・境界）
* [[scope-discovery]]（利用者・関係者・管理画面の有無）
* [[requirements-discovery]]（機能・管理機能・運用フロー）
* [[business-discovery]]（運営主体・収益構造・継続条件）

**特に [[business-discovery]] が完了し、運営主体・収益構造・継続条件が整理された後に実施する。** 誰が運営し、何で食べていくかが未確定のまま運用実態は発見できない。

具体的なトリガー:

* 「誰が問い合わせ・返金・削除依頼に対応するのか」が曖昧なまま実装に進みそうなとき
* 管理画面はあるのに「誰が何の権限で何を操作するのか」が決まっていないとき
* 「毎日 / 毎週 / 毎月、運営側で何をするのか」が言語化されていないとき
* `metrics/metrics.md` の KPI に運営観点（問い合わせ件数・対応時間・作業負荷）が接続されていないとき

**使わない / 渡す先**

* 想定負荷・データ量・可用性・性能などの非機能 → [[nfr-discovery]]
* 運営リスク・属人化・サポート崩壊の詳細分析 → [[risk-discovery]]（operations では「運営継続上の懸念」として最低限のみ記録）
* 返金・利用停止・SLA・サポート条件の契約化 → [[contract-discovery]]
* DB / API / ER図 / 画面 / インフラ設計 → 範囲外（[Prohibited](#prohibited)）

---

# Inputs

運営実態は **運営主体 → 役割 → 日常運用 → 問い合わせ → 異常時 → 運営負荷 → 運営KPI** の順に立ち上がる。business / scope / requirements / metrics への依存が強い。参照する成果物は以下。**カッコ内が実際の生成元と実ファイル名**。

**必須（これが無いと運営実態を接地できない）**

* `scope/users.md` — 利用者種別 / ペルソナ（[[scope-discovery]]）
* `scope/stakeholders.md` — 関係者 / 運営者 / 管理者 / 支払者（[[scope-discovery]]。**運営主体の起点**）
* `requirements/requirements-checklist.md` — 機能・業務フロー・管理機能（[[requirements-discovery]]）
* `requirements/screen-catalog-draft.md` — 管理画面・運営側操作の有無（[[requirements-discovery]]）
* `business/business-model.md` — 運営主体 / 費用構造 / 継続条件（[[business-discovery]]。**正式 index**）
* `business/revenue.md` — 課金・返金・無料運用の負担者（[[business-discovery]]。返金/キャンセル運用の起点）
* `business/go-to-market.md` — 初期流入・運営側集客作業の有無（[[business-discovery]]）
* `metrics/metrics.md` — North Star / KPI / 成功定義（[[metrics-discovery]]。**運営KPIはこれと矛盾させない**）

**推奨（裏取り・前提強化に使う）**

* `data/data.md` — 扱うデータ / 更新責任者 / 削除条件（[[data-discovery]]。データ更新・削除依頼運用の根拠。ユーザー spec の `data/data-inventory.md` に相当）
* `legal/legal.md`— 返金・削除・通報の法務要件が運用に効く場合（[[legal-discovery]]）
* `decisions.md` / `open-questions.md` — 決定・未確定ログ（[[project-discovery]]）

> 必須入力が欠けている場合、運営実態を接地できないため上流へ差し戻すのが原則（[Handoff / 差し戻し条件](#handoff--差し戻し条件)）。曖昧な箇所を推測で確定しない。仮置きは Assumption（=`decisions.md` の `仮置き`）として置く。

---

# Outputs

`operations/` 配下に **`domain/index.md` パターン** で生成する。Discovery Suite 全体（business / metrics / legal / scope / data …）と揃えるため、ドメイン index を1本立て、観点ごとに分割する。

| ファイル | 役割 |
|---|---|
| `operations/operations.md` | **index**。運営主体 / 体制サマリ / 各観点へのリンク / MVP時点の手作業範囲。**[[project-discovery]] が正式参照するファイル**。 |
| `operations/operator-roles.md` | 運営者・管理者・サポート担当の役割整理。誰が・何人で・どの権限で運営するか |
| `operations/operational-workflows.md` | 日次・週次・月次の運用作業。発生タイミング / 担当 / 頻度 / 所要 |
| `operations/support-process.md` | 問い合わせ対応 / クレーム対応 / 障害時対応 / エスカレーション経路 |
| `operations/content-management.md` | 運営側が更新する情報 / 更新頻度 / 承認フロー / 公開フロー |
| `operations/operational-metrics.md` | 運営KPI（問い合わせ件数 / 対応時間 / 作業負荷 / 人的コスト）。`metrics/metrics.md` と接続 |
| `operations/runbook-summary.md` | 運営開始時に必要な手順の要約（誰が・何を・どの順で始めるか） |
| `decisions.md` / `open-questions.md` | 決定・保留・仮置き・差し戻しの記録（[[project-discovery]] と同期） |

> 小規模なら index の `operations/operations.md` 1本に集約し、他は同ファイル内のセクションでもよい。ただし **運営主体・役割・日常運用・問い合わせ対応・異常時対応・運営KPIの観点は省略しない**。

---

# Discovery targets

必ず発見すること。

### 1. 運営主体（Operations Owner）

* 誰が運営するか
* 個人か法人か
* 何人で運営するか（運営チームの規模）
* 専任か兼任か（本業の片手間か）

### 2. 管理者（Administrators）

* 管理画面を利用する人は誰か
* 権限種別（全権 / 限定 / 閲覧のみ など）
* 管理者が複数いる場合の役割分担

### 3. 日常運用（Operational Workflows）

* 毎日発生する作業（例: 投稿確認 / 入金確認 / 通知対応）
* 毎週発生する作業（例: レポート / 在庫更新）
* 毎月発生する作業（例: 請求 / 集計 / 締め）
* 各作業の所要時間・担当・頻度

### 4. 問い合わせ（Support / Inquiries）

* 問い合わせ経路（メール / フォーム / LINE / 電話 / SNS など）
* 対応担当
* 対応目標時間（一次応答 / 解決まで）

### 5. コンテンツ更新（Content Management）

* 更新対象（お知らせ / 商品 / 料金 / 規約 / FAQ など）
* 更新頻度
* 承認者（誰の承認で公開されるか）
* 公開フロー

### 6. ユーザー対応（User Operations）

* キャンセル対応
* 返金対応（誰が・どの基準で）
* 削除依頼対応（アカウント / データ）
* アカウント問い合わせ（ログイン不能・本人確認 など）

### 7. 異常時対応（Incident / Abuse Response）

* 障害時（誰が気づき・誰が動くか）
* 不正利用（検知・対処）
* 通報対応（誹謗中傷 / 違反コンテンツ）
* 緊急停止（誰が・どの権限で止められるか）

### 8. 運営負荷（Operational Load）

* 人手が必要な部分
* 自動化可能な部分
* **MVP時点で手作業運用する部分**（最初から自動化しない範囲を明示）
* 属人化している部分（1人しかできない作業）

### 9. Assumptions / Unknowns

入力不足は推測で確定しない。以下に分類して記録する。

* Assumption（仮置き）: 仮置きして進める前提。事実として扱わない。
* Unknown（保留）: 判断不能 → `open-questions.md`。
* Needs Discovery: 上流へ戻す → business / requirements / scope。
* Deferred: MVP後でよい。

---

# Question logic

質問は **運営実態を明らかにするために** 行う。**実装方法を聞いてはいけない。**

一度に大量質問しない。常に **「次に決めるべき1件」だけ** を質問する。最初は **一問だけ** 聞く設計にする。深掘りの1問は [[discovery-planner]] が作る。各回答は **決定 / 保留 / 仮置き / 未定 / コメント** で返せる形にする。

**禁止例（実装方法を聞いている）**

* AWS は何を使いますか
* DB は何ですか
* Redis は必要ですか

**許可例（運営実態を聞いている）**

* 問い合わせは誰が対応しますか
* 返金対応は誰が行いますか
* 毎日確認が必要な業務はありますか

### 質問の優先順位

1. **誰がこのサービスを運営するか**（運営主体・人数・専任/兼任）
2. 管理画面を誰が・どの権限で使うか
3. 問い合わせは誰が・どの経路で・どの目標時間で対応するか
4. 毎日 / 毎週 / 毎月、運営側で必ず発生する作業は何か
5. 返金・キャンセル・削除依頼は誰がどう対応するか
6. 障害・通報・不正が起きたとき誰が動くか（緊急停止の権限）
7. MVP時点で手作業になる範囲はどこか

---

# Discovery loop

```text
入力成果物（business / scope / requirements / metrics）を確認
 → 運営主体・役割・日常運用・問い合わせ・異常時対応の現状を読む
 → business/business-model.md の運営主体・費用構造と照合（運営者不在になっていないか）
 → metrics/metrics.md の KPI と運営KPIの接続可能性を確認
 → [[discovery-planner]]: 次に決めるべき1件に絞って質問（最初は一問・優先順位順・実装方法は聞かない）
 → ユーザー回答（必ず停止して確認）
 → operator-roles / operational-workflows / support-process / content-management / operational-metrics / runbook-summary を更新
 → 仮置きは Assumption として明示・保留は open-questions.md へ
 → 不足・矛盾・運営負荷の過小評価を洗い出す（必要なら上流へ差し戻す）
 → operations/ を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 [[discovery-auditor]] へ（運営主体・KPI接続・運営負荷の整合を監査）
 → nfr / risk / contract へ引き渡し
```

---

# Handoff / 差し戻し条件

## Backward Handoff（差し戻し）

以下の場合は上流に差し戻す。差し戻し時は **質問を1つに絞る**。

| 状況 | 差し戻し先 |
|---|---|
| 運営主体が未確定（誰が運営するか不明） | [[business-discovery]]（運営主体・継続条件） |
| 管理機能が不足し運営フローが実現不可 | [[requirements-discovery]]（管理機能） |
| 管理者ユーザーの定義が不足 | [[scope-discovery]]（users / stakeholders） |
| 返金・キャンセルの運用が課金前提と矛盾 | [[business-discovery]]（revenue） |
| 運営KPIに対応する metrics が存在しない | [[metrics-discovery]] |
| 運営の継続コストが費用構造と矛盾 | [[business-discovery]]（business-model） |

## Forward Handoff（引き渡し）

* **To [[nfr-discovery]]**: 運営規模 / 想定ユーザー数 / 業務負荷（スケール時の運用負荷前提）
* **To [[risk-discovery]]**: 運営リスク / 属人化リスク / サポート崩壊リスク
* **To [[contract-discovery]]**: 返金 / 利用停止 / SLA / サポート条件（契約・規約に落とす論点）
* **To [[discovery-auditor]]**: 運営主体 ↔ 役割 ↔ 運営KPI の整合、運営者・管理者・サポート担当の不在検出、未昇格の仮置き

---

# Completion criteria

兄弟Skill共通の体裁だけでは「`問い合わせはメールで対応` とだけ書いて完了」になりかねない。operations は **「作れる ≠ 運営し続けられる」** に陥りやすいので、operations特有の完了条件を満たすこと（[Phase完了判定](#phase完了判定)を出す）。

* [ ] **運営主体が確定している**（誰が・個人/法人・何人で）
* [ ] **管理者が定義されている**（誰が・どの権限で管理画面を使うか）
* [ ] **日常運用が整理されている**（日次・週次・月次の作業が洗い出されている）
* [ ] **問い合わせ対応が整理されている**（経路・担当・目標時間）
* [ ] **異常時対応が整理されている**（障害・不正・通報・緊急停止）
* [ ] **運営KPIが存在し `metrics/metrics.md` と接続されている**（宙に浮いていない）
* [ ] **運営負荷が把握できる**（人手が必要な部分・自動化可能な部分の切り分け）
* [ ] **MVP時点の手作業範囲が明確である**（自動化前提で逃げていない）
* [ ] **不明点が `open-questions.md` に分離されている**
* [ ] **仮置きが Assumption として明示されている**（未昇格の仮置きが残る間は完了にしない。ユーザーが暫定通過を明示承認した場合のみ例外、その旨を記録）

> 運営主体・管理者・問い合わせ対応・異常時対応のいずれかが宙に浮いたまま完了扱いにしてはならない。

### Phase完了判定

```text
## Phase完了判定: Operations Discovery (Phase6)
- 運営主体: 確定（誰/個人法人/人数） / 未定
- 管理者と権限: 定義済 / 不足
- 日常運用（日次/週次/月次）: 充足 / 不足
- 問い合わせ対応（経路/担当/目標時間）: 充足 / 不足
- 異常時対応（障害/不正/通報/緊急停止）: 充足 / 不足
- 運営KPI ↔ metrics/metrics.md の接続: <x/n>
- 運営負荷の把握（手作業 vs 自動化）: 明確 / 過小評価の疑い
- MVP時点の手作業範囲: 明確 / 曖昧
- 未解消の保留: <件数>
- open-questions.md へ移送済みの仮置き: <件数> / 未昇格の仮置き: <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

---

# Output templates

### operations/operations.md（index）

```md
# 運営設計: <プロダクト名>

## サマリ
* Project:
* Operations Discovery Status:
* Confidence:
* 運営主体（誰が / 個人・法人 / 何人で）:
* 運営体制の一文要約:

## 運営体制（リンク）
* 運営者・管理者・サポート: → operator-roles.md
* 日常運用: → operational-workflows.md
* 問い合わせ・異常時対応: → support-process.md
* コンテンツ更新: → content-management.md
* 運営KPI: → operational-metrics.md
* 運営開始手順: → runbook-summary.md

## MVP時点で手作業運用する範囲（自動化前提で逃げない）
| 業務 | 手作業/自動化 | 担当 | MVP後に自動化予定か |
| ---- | ------------- | ---- | ------------------- |

## 運営継続上の懸念（最低限・詳細は risk-discovery へ）
| 懸念 | 影響 | Handoff |
| ---- | ---- | ------- |

## Assumptions / Unknowns（decisions.md / open-questions.md と同期）
| 種別 | 内容 | 理由 | Confirm By |
| ---- | ---- | ---- | ---------- |
```

### operations/operator-roles.md

```md
# 運営者・管理者・サポート: <プロダクト名>

## 運営主体
* 個人 / 法人:
* 人数:
* 専任 / 兼任:

## 役割整理
| 役割 | 誰 | 担当範囲 | 権限種別 | 専任/兼任 |
| ---- | -- | -------- | -------- | --------- |

## 管理画面の権限
| 権限 | できること | 付与対象 |
| ---- | ---------- | -------- |
```

### operations/operational-workflows.md

```md
# 日常運用: <プロダクト名>

## 日次
| 作業 | 担当 | トリガー/時間帯 | 所要 | 手作業/自動化 |
| ---- | ---- | --------------- | ---- | ------------- |

## 週次
| 作業 | 担当 | 頻度 | 所要 | 手作業/自動化 |
| ---- | ---- | ---- | ---- | ------------- |

## 月次
| 作業 | 担当 | 頻度 | 所要 | 手作業/自動化 |
| ---- | ---- | ---- | ---- | ------------- |
```

### operations/support-process.md

```md
# サポート・異常時対応: <プロダクト名>

## 問い合わせ対応
| 経路 | 対応担当 | 一次応答目標 | 解決目標 |
| ---- | -------- | ------------ | -------- |

## ユーザー対応（キャンセル / 返金 / 削除依頼 / アカウント）
| 種別 | 担当 | 判断基準 | 連携先(法務/契約) |
| ---- | ---- | -------- | ----------------- |

## 異常時対応
| 事象 | 検知方法 | 一次対応 | エスカレーション先 | 緊急停止権限者 |
| ---- | -------- | -------- | ------------------ | -------------- |
```

### operations/content-management.md

```md
# コンテンツ更新: <プロダクト名>

## 更新対象と頻度
| 更新対象 | 更新頻度 | 更新者 | 承認者 | 公開フロー |
| -------- | -------- | ------ | ------ | ---------- |
```

### operations/operational-metrics.md

```md
# 運営KPI: <プロダクト名>

> metrics/metrics.md と接続。運営観点で抽出し、矛盾する独自KPIを乱造しない。

## 運営KPI
| KPI | 測定対象 | metrics由来 | 目標/閾値 | 過負荷の兆候 |
| --- | -------- | ----------- | --------- | ------------ |
（問い合わせ件数 / 一次応答時間 / 解決時間 / 作業負荷 / 人的コスト など）

## 運営が回らなくなる条件（サポート崩壊の閾値）
* 条件:
* 観測指標:
* 対処/Handoff（→ risk-discovery）:
```

### operations/runbook-summary.md

```md
# 運営開始手順（要約）: <プロダクト名>

## 運営開始時に必要な手順
| 順序 | 手順 | 担当 | 前提 |
| ---- | ---- | ---- | ---- |

## 開始時点で決まっている必要がある運営事項
* [ ] 運営主体・連絡先
* [ ] 管理者アカウントと権限
* [ ] 問い合わせ経路の開設
* [ ] 返金・削除依頼の対応窓口
* [ ] 緊急停止の権限者
```

---

# Self-check

* [ ] 運営者不在になっていないか（誰も運営しない設計になっていないか）
* [ ] 管理者不在になっていないか
* [ ] サポート担当不在になっていないか
* [ ] 問い合わせ対応が宙に浮いていないか（経路はあるが担当が居ない、等）
* [ ] 運営KPIが `metrics/metrics.md` と接続されているか（宙に浮いたKPIが無いか）
* [ ] 運営負荷を過小評価していないか
* [ ] 自動化前提で逃げていないか（MVPの手作業範囲を明示したか）
* [ ] 返金・削除依頼など法務/契約に跨る運用を適切に [[legal-discovery]] / [[contract-discovery]] へ繋いだか
* [ ] 異常時の緊急停止権限者が定義されているか
* [ ] Assumptions / Unknowns が `decisions.md` / `open-questions.md` に分離されているか
* [ ] 上流への差し戻し質問が1件単位になっているか
* [ ] 最初は一問だけ・優先順位順に質問したか（大量質問していないか）
* [ ] 実装方法（AWS / DB / Redis 等）を聞いていないか

---

# Prohibited

この Skill では以下を行わない。operations-discovery は **運営実態の発見に集中する**。

* AWS 設計 / インフラ設計
* DB 設計 / テーブル・カラム・ER図の作成
* API 設計
* 画面設計（→ [[requirements-discovery]] / screen-design-architect）
* 非機能要件の設計・確定（→ [[nfr-discovery]]）
* 実装方法の決定
* 運営リスクの詳細分析（→ [[risk-discovery]]。見出しのみ記録）
* 返金・SLA・サポート条件の契約化（→ [[contract-discovery]]。運用上の発見のみ）
* 運営主体・担当・運用負荷の推測による断定
* 「自動化するから運営不要」のような運営負荷の過小評価
* metrics と矛盾する独自KPIの乱造
* 情報不足を仮定で確定すること（仮置きは `decisions.md` に明示）

---

関連スキル: [[project-discovery]]（オーケストレーター・Phase6）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（運営主体・KPI接続・運営負荷の監査）/ 入力元: [[business-discovery]]（運営主体・費用構造・継続条件・revenue・go-to-market）・[[scope-discovery]]（users/stakeholders）・[[requirements-discovery]]（機能・管理機能・運用フロー）・[[metrics-discovery]]（KPI・成功定義）/ 引き渡し先: [[nfr-discovery]] / [[risk-discovery]] / [[contract-discovery]]。
