---
name: integration-discovery
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: standard
  summary: "Project Discovery の Phase10（Integration Discovery）担当。外部との接続点・依存先・連携責任を発見する（外部サービス/認証/通知/決済/データ入出力/失敗時対応）。API仕様・Webhook設計・技術選定はしない。"
description: >-
  Project Discovery の Phase10（Integration Discovery）担当。外部API設計や実装方式を決めるスキルではない。
  「プロジェクト外部との接続点・依存先・連携責任を発見する」工程。requirements / data / operations / business の成果物を入力に、
  何と連携する必要があるのか / 誰が管理するのか / 失敗時にどう扱うのかを明確化する。外部サービス / 認証・本人確認 /
  通知 / 決済・請求 / データ入出力 / 外部API依存 / 失敗時対応 を発見し integration/ 配下に整理する。
  トリガー例: 「外部連携を整理したい」「使う外部サービスを洗い出して」「決済が必要か整理して」
  「誰のアカウントで契約するか決めたい」「通知の送り先と失敗時対応を決めたい」「CSV取り込み・PDF出力の要否を整理して」
  「外部API停止時の扱いを詰めたい」。入力は [[requirements-discovery]] / [[data-discovery]] / [[operations-discovery]] /
  [[business-discovery]] の成果物。API仕様・Webhook設計・OAuthスコープ・DB・ER図・インフラ・技術選定はしない。
  外部停止/API制限/通知未達/決済失敗は [[risk-discovery]]、レート制限・同期頻度・可用性要求は [[nfr-discovery]]、
  利用規約・手数料・SLA・サポート条件は [[contract-discovery]] へ渡す。
  [[project-discovery]] から参照され、[[discovery-planner]] / [[discovery-auditor]] のループ内で動く。
---

# Purpose

`integration-discovery` は、**プロジェクト外部との接続点・依存先・連携責任を発見する** ための Discovery Skill である。[[project-discovery]] の **Phase10（Integration Discovery）** を担う。

このスキルは **外部API設計や実装方式を決めるものではない**。

目的は、**「何と連携する必要があるのか」「誰が管理するのか」「失敗時にどう扱うのか」** を明確化することである。

* **何と連携するか** — 利用する外部サービス・外部API・依存先
* **誰が管理するか** — 誰のアカウントで契約するか・運用責任者は誰か
* **失敗時にどう扱うか** — 外部停止・API失敗・通知未達・決済失敗時の扱い

[[requirements-discovery]] が「どう作るか」、[[data-discovery]] が「何のデータを扱うか」、[[operations-discovery]] が「誰が運営し続けるか」を決めるのに対し、integration-discovery は **「外部の何に依存し、その依存の責任と失敗を誰がどう引き受けるのか」** を発見する。

> integration-discovery は **断定しない**。推測で外部サービスや連携前提を事実化しない。不明点は `decisions.md` / `open-questions.md` に分類し、仮置き可能なものは Assumption として明示する。ただし **外部サービスの責任者・通知条件・決済責任・データ入出力・失敗時対応が宙に浮いたまま完了扱いにしない**。
>
> 特に **「外部サービスを暗黙の前提にする」ことを禁止** する。誰のアカウントで使うか不明なサービスを既定路線にしない。通知を「送る」だけで終わらせず、届かなかった場合の扱いまで発見する。

---

# When to use

主に以下の Phase が完了した後に実行する。

* [[scope-discovery]]（利用環境 Web/LINE/アプリ・外部依存の概観）
* [[requirements-discovery]]（機能・通知・決済・データ入出力を伴う画面）
* [[data-discovery]]（外部に渡す / 外部から受け取るデータ）
* [[operations-discovery]]（運営・管理業務・問い合わせ・異常時対応）
* [[business-discovery]]（決済・課金・運営主体・費用構造）

**特に [[requirements-discovery]] と [[operations-discovery]] が完了し、ユーザー行動・管理業務・通知・決済・データ入出力が見えてから実施する。** 何が起きるサービスかが未確定のまま外部連携は発見できない。

具体的なトリガー:

* 機能要件に通知・決済・地図・予約などが出てくるのに、どの外部サービスに依存するか棚卸しされていないとき
* 「決済が必要か / 誰が払うか / 入金先は誰か」が曖昧なまま実装に進みそうなとき
* 通知が「送る」とだけ書かれ、送り先・送信条件・未達時の扱いが無いとき
* `data/data.md` に外部入出力（CSV取り込み・PDF出力・既存データ移行）があるのに連携として整理されていないとき
* [[risk-discovery]] で「依存サービス停止」を挙げたいのに、依存の棚卸し元が存在しないとき

**使わない / 渡す先**

* 外部停止・API制限・通知未達・決済失敗のリスク分析 → [[risk-discovery]]（integration では「連携失敗時の扱い」として発見のみ）
* レート制限・同期頻度・データ量・可用性要求の非機能 → [[nfr-discovery]]
* 利用規約・決済手数料・返金・SLA・サポート条件の契約化 → [[contract-discovery]]
* 個人情報の外部送信・第三者提供・同意の法務 → [[legal-discovery]]
* API仕様 / Webhook / OAuthスコープ / DB / ER図 / インフラ設計 → 範囲外（[Prohibited](#prohibited)）

---

# Inputs

外部連携は **ユーザー行動・管理業務 → 外部サービス → 認証 → 通知 → 決済 → データ入出力 → 失敗時対応** の順に立ち上がる。requirements / data / operations / business への依存が強い。参照する成果物は以下。**カッコ内が実際の生成元と実ファイル名**。

**必須（これが無いと外部連携を接地できない）**

* `requirements/requirements-checklist.md` — 機能・通知・決済・入出力を伴う要件（[[requirements-discovery]]。ユーザー spec の `requirements/requirements-checklist.md` に相当）
* `requirements/screen-catalog-draft.md` — 外部連携前提の画面・操作の有無（[[requirements-discovery]]）
* `data/data.md` — 外部に渡す / 外部から受け取るデータ・所有権・個人情報（[[data-discovery]]。ユーザー spec の `data/data-inventory.md` に相当。**入出力の起点**）
* `operations/operations.md` — 運営主体・運営体制（[[operations-discovery]]。**外部アカウント管理者・通知先の起点**）
* `operations/operational-workflows.md` — 通知・入金確認・取り込みなど運用に現れる連携作業（[[operations-discovery]]）
* `business/business-model.md` — 運営主体・費用構造・課金有無（[[business-discovery]]。**決済責任の起点**）

**推奨（裏取り・前提強化に使う）**

* `scope/users.md` — 利用者種別（外部ログイン・本人確認の対象）（[[scope-discovery]]）
* `scope/stakeholders.md` — 関係者・支払者・契約主体（[[scope-discovery]]。外部アカウント契約者の手掛かり）
* `legal/legal.md`— 個人情報外部送信・第三者提供・同意の要否（[[legal-discovery]]）
* `metrics/metrics.md` — 連携が支える成功指標（[[metrics-discovery]]）
* `decisions.md` / `open-questions.md` — 決定・未確定ログ（[[project-discovery]]）

> 必須入力が欠けている場合、外部連携を接地できないため上流へ差し戻すのが原則（[Handoff / 差し戻し条件](#handoff--差し戻し条件)）。曖昧な箇所を推測で確定しない。仮置きは Assumption（=`decisions.md` の `仮置き`）として置く。

---

# Outputs

`integration/` 配下に **`domain/index.md` パターン** で生成する。Discovery Suite 全体（business / metrics / legal / scope / data / operations …）と揃えるため、ドメイン index を1本立て、観点ごとに分割する。

| ファイル | 役割 |
|---|---|
| `integration/integration.md` | **index**。利用予定の外部連携サマリ / 各観点へのリンク / 必須連携と任意連携の切り分け / 外部アカウント管理者一覧。**[[project-discovery]] が正式参照するファイル**。 |
| `integration/external-services.md` | 利用予定の外部サービス一覧（決済 / メール / SMS / LINE / Google Maps / Google Calendar / AI API / 予約 / CRM / 会計 など）。用途・必須/任意・代替可否・契約者 |
| `integration/data-flows.md` | 外部連携に伴うデータの入出力（何を・どちら向きに・誰が・どの頻度で）。`data/data.md` と接続 |
| `integration/auth-and-identity.md` | 外部認証・ログイン・本人確認・アカウント連携（LINE / Google / メール / 電話番号 / 既存顧客紐付け） |
| `integration/notifications.md` | メール・LINE・SMS・Push などの送信条件・送信先・責任範囲・未達時の扱い |
| `integration/payment-and-billing.md` | 決済・請求・返金・手数料・入金サイクル・支払者・入金先 |
| `integration/import-export.md` | CSV / PDF / Excel / 画像 / 既存システム移行などの入出力 |
| `integration/failure-handling.md` | 外部サービス障害・API失敗・通知失敗・決済失敗・連携データ不整合時の扱いと手動復旧の有無 |
| `decisions.md` / `open-questions.md` | 決定・保留・仮置き・差し戻しの記録（[[project-discovery]] と同期） |

> 小規模なら index の `integration/integration.md` 1本に集約し、他は同ファイル内のセクションでもよい。ただし **外部サービス・通知・決済・データ入出力・失敗時対応の観点は省略しない**。

---

# Discovery targets

必ず発見すること。

### 1. 外部サービス（External Services）

* 利用する外部サービス
* 代替可能か（ロックインか / 乗り換え可能か）
* 必須か任意か
* 誰のアカウントで契約するか（運営 / ユーザー / 第三者）

### 2. 認証・本人確認（Auth & Identity）

* 外部ログインの有無
* LINEログイン
* Googleログイン
* メール認証
* 電話番号認証
* 既存顧客との紐付け（既存アカウントへの統合）

### 3. 通知（Notifications）

* 何を通知するか
* 誰に通知するか
* どの経路で通知するか（メール / LINE / SMS / Push）
* 失敗時にどうするか（再送 / 手動確認 / 放置可否）

### 4. 決済（Payment & Billing）

* 決済が必要か
* 誰が支払うか
* 課金単位（都度 / 月額 / 従量）
* 返金（誰が・どの基準で）
* 手数料（誰が負担するか）
* 入金先（誰の口座に入るか）

### 5. データ入出力（Import / Export）

* CSV取り込み
* CSV出力
* PDF出力
* 画像アップロード
* 既存データ移行

### 6. 外部API依存（External API Dependencies）

* Google系API
* AI API
* 地図API
* 予約API
* SNS API
* その他外部API

### 7. 失敗時対応（Failure Handling）

* 外部API停止
* 通知未達
* 決済失敗
* 連携データ不整合
* 手動復旧の有無（誰が・どうやって）

### 8. Assumptions / Unknowns

入力不足は推測で確定しない。以下に分類して記録する。

* Assumption（仮置き）: 仮置きして進める前提。事実として扱わない。
* Unknown（保留）: 判断不能 → `open-questions.md`。
* Needs Discovery: 上流へ戻す → requirements / data / operations / business。
* Deferred: MVP後でよい。

---

# Question logic

質問は **連携要否と責任範囲を明らかにするために** 行う。**実装方式を聞いてはいけない。**

一度に大量質問しない。常に **「次に決めるべき1件」だけ** を質問する。最初は **一問だけ** 聞く設計にする。深掘りの1問は [[discovery-planner]] が作る。各回答は **決定 / 保留 / 仮置き / 未定 / コメント** で返せる形にする。

**禁止例（実装方式を聞いている）**

* Stripe の Webhook 実装はどうしますか
* OAuth のスコープは何にしますか
* API Gateway を使いますか

**許可例（連携要否・責任範囲を聞いている）**

* 決済は必要ですか
* 誰の Stripe アカウントを使いますか
* 予約完了時に誰へ通知しますか
* 通知が届かなかった場合、手動確認は必要ですか
* 既存の顧客データを取り込みますか

### 質問の優先順位

1. **必須連携の特定** — その外部サービスが無いと成立しない連携はどれか
2. 各外部サービスは **誰のアカウントで契約**するか（運営/ユーザー/第三者）
3. 通知は **何を・誰に・どの経路で**送るか
4. 通知が **届かなかった場合**どうするか（手動確認の要否）
5. 決済は必要か。必要なら **支払者・入金先・返金方針**は誰が持つか
6. **データ入出力**（CSV/PDF/画像/既存移行）の要否と向き
7. 外部停止・決済失敗・通知未達時の **手動復旧の有無**

---

# Discovery loop

```text
入力成果物（requirements / data / operations / business）を確認
 → 機能・通知・決済・データ入出力に現れる外部依存を読む
 → data/data.md の外部入出力と照合（外部に渡す/受け取るデータの抜けが無いか）
 → operations/operations.md の運営主体と照合（外部アカウント管理者・通知先が宙に浮いていないか）
 → business/business-model.md と照合（決済責任・入金先が運営主体と矛盾しないか）
 → [[discovery-planner]]: 次に決めるべき1件に絞って質問（最初は一問・優先順位順・実装方式は聞かない）
 → ユーザー回答（必ず停止して確認）
 → external-services / data-flows / auth-and-identity / notifications / payment-and-billing / import-export / failure-handling を更新
 → 必須連携と任意連携を切り分け・仮置きは Assumption として明示・保留は open-questions.md へ
 → 不足・矛盾・暗黙前提の外部サービスを洗い出す（必要なら上流へ差し戻す）
 → integration/ を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 [[discovery-auditor]] へ（外部サービス責任者・通知条件・決済責任・失敗時対応の整合を監査）
 → risk / nfr / contract / legal へ引き渡し
```

---

# Handoff / 差し戻し条件

## Backward Handoff（差し戻し）

以下の場合は上流に差し戻す。差し戻し時は **質問を1つに絞る**。

| 状況 | 差し戻し先 |
|---|---|
| 必要な通知・決済・入出力機能が要件に未定義 | [[requirements-discovery]]（機能） |
| 外部連携前提の画面が不足 | [[requirements-discovery]]（screen-catalog-draft） |
| 外部に渡すデータが未整理 | [[data-discovery]] |
| 外部から受け取るデータが未整理 | [[data-discovery]] |
| 失敗時の手動対応が運用に未整理 | [[operations-discovery]] |
| 外部アカウント管理者が不明 | [[operations-discovery]] / [[scope-discovery]]（stakeholders） |
| 決済責任・入金先が費用構造と矛盾 | [[business-discovery]] |
| 個人情報の外部送信・第三者提供・同意が未確認 | [[legal-discovery]] |

## Forward Handoff（引き渡し）

* **To [[risk-discovery]]**: 外部サービス停止 / API制限 / 通知未達 / 決済失敗 / アカウント停止のリスク
* **To [[nfr-discovery]]**: API制限 / レート制限 / 同期頻度 / データ量 / 可用性要求
* **To [[contract-discovery]]**: 外部サービス利用規約 / 決済手数料 / 返金 / SLA / サポート条件
* **To [[legal-discovery]]**: 個人情報の外部送信 / 第三者提供 / 決済 / 利用規約同意（PII が外部に渡る場合は必ず引き渡す）
* **To [[discovery-auditor]]**: 外部サービス ↔ 管理者 ↔ 失敗時対応の整合、責任者不在・通知/決済/入出力の未定義検出、未昇格の仮置き

---

# Completion criteria

兄弟Skill共通の体裁だけでは「`通知はメールで送る` とだけ書いて完了」になりかねない。integration は **「連携できる ≠ 連携の責任と失敗を引き受けられる」** に陥りやすいので、integration特有の完了条件を満たすこと（[Phase完了判定](#phase完了判定)を出す）。

* [ ] **利用する外部サービスが整理されている**（用途・代替可否つき）
* [ ] **必須連携と任意連携が分かれている**
* [ ] **外部アカウントの管理者が明確である**（誰のアカウントで契約するか）
* [ ] **通知条件と通知先が整理されている**（何を・誰に・どの経路で）
* [ ] **決済が必要な場合、支払者・入金先・返金方針が整理されている**
* [ ] **データ入出力が整理されている**（向き・対象・`data/data.md` と接続）
* [ ] **外部連携失敗時の扱いが整理されている**（停止・未達・失敗・不整合・手動復旧）
* [ ] **data / legal / operations と矛盾していない**
* [ ] **不明点が `open-questions.md` に分離されている**
* [ ] **仮置きが Assumption として明示されている**（未昇格の仮置きが残る間は完了にしない。ユーザーが暫定通過を明示承認した場合のみ例外、その旨を記録）

> 外部サービスの責任者・通知条件・決済責任・データ入出力・失敗時対応のいずれかが宙に浮いたまま完了扱いにしてはならない。

### Phase完了判定

```text
## Phase完了判定: Integration Discovery (Phase10)
- 外部サービス棚卸し: 充足 / 不足
- 必須連携 / 任意連携の切り分け: 済 / 未
- 外部アカウント管理者: 全て明確 / 不明あり
- 通知（何を/誰に/経路/未達時）: 充足 / 不足
- 決済（要否/支払者/入金先/返金/手数料）: 充足 / 不要 / 不足
- データ入出力（向き/対象/data-design.md 接続）: 充足 / 不足
- 失敗時対応（停止/未達/失敗/不整合/手動復旧）: 充足 / 不足
- data / legal / operations との整合: 整合 / 矛盾あり
- 未解消の保留: <件数>
- open-questions.md へ移送済みの仮置き: <件数> / 未昇格の仮置き: <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

---

# Output templates

### integration/integration.md（index）

```md
# 外部連携設計: <プロダクト名>

## サマリ
* Project:
* Integration Discovery Status:
* Confidence:
* 利用予定の外部連携（一文要約）:

## 連携観点（リンク）
* 外部サービス一覧: → external-services.md
* データ入出力: → data-flows.md
* 認証・本人確認: → auth-and-identity.md
* 通知: → notifications.md
* 決済・請求: → payment-and-billing.md
* インポート/エクスポート: → import-export.md
* 失敗時対応: → failure-handling.md

## 必須連携 / 任意連携の切り分け
| 外部サービス | 用途 | 必須/任意 | 代替可否 | アカウント契約者 |
| ------------ | ---- | --------- | -------- | ---------------- |

## 外部アカウント管理者一覧
| サービス | 契約者 | 運用責任者 | 備考 |
| -------- | ------ | ---------- | ---- |

## Assumptions / Unknowns（decisions.md / open-questions.md と同期）
| 種別 | 内容 | 理由 | Confirm By |
| ---- | ---- | ---- | ---------- |
```

### integration/external-services.md

```md
# 外部サービス一覧: <プロダクト名>

| サービス | 用途 | 必須/任意 | 代替可否 | アカウント契約者 | 運用責任者 |
| -------- | ---- | --------- | -------- | ---------------- | ---------- |
（決済 / メール / SMS / LINE / Google Maps / Google Calendar / AI API / 予約 / CRM / 会計 など）
```

### integration/data-flows.md

```md
# 外部連携データ入出力: <プロダクト名>

> data/data.md と接続。外部に渡す / 受け取るデータの抜けが無いか照合する。

| データ | 向き(送信/受信) | 相手サービス | 個人情報 | 頻度/契機 | 責任者 |
| ------ | --------------- | ------------ | -------- | --------- | ------ |
```

### integration/auth-and-identity.md

```md
# 外部認証・本人確認: <プロダクト名>

## 外部ログイン / 本人確認
| 方式 | 用途 | 必須/任意 | 対象ユーザー | 既存顧客との紐付け |
| ---- | ---- | --------- | ------------ | ------------------ |
（LINE / Google / メール認証 / 電話番号認証 など）
```

### integration/notifications.md

```md
# 通知: <プロダクト名>

## 送信条件と送信先
| 通知内容 | 送信先 | 経路(メール/LINE/SMS/Push) | 送信契機 | 失敗時の扱い | 責任者 |
| -------- | ------ | -------------------------- | -------- | ------------ | ------ |

## 未達時の方針
* 再送するか:
* 手動確認の要否:
* 放置可否:
```

### integration/payment-and-billing.md

```md
# 決済・請求: <プロダクト名>

## 決済概要
* 決済の要否:
* 支払者:
* 課金単位（都度/月額/従量）:
* 入金先（誰の口座）:

## 返金・手数料
| 項目 | 方針 | 責任者 | Handoff(contract/legal) |
| ---- | ---- | ------ | ----------------------- |
（返金基準 / 手数料負担 / 入金サイクル など）
```

### integration/import-export.md

```md
# インポート / エクスポート: <プロダクト名>

| 種別 | 形式(CSV/PDF/Excel/画像) | 向き(取込/出力) | 用途 | 個人情報 | 責任者 |
| ---- | ------------------------ | --------------- | ---- | -------- | ------ |
（CSV取り込み / CSV出力 / PDF出力 / 画像アップロード / 既存データ移行 など）
```

### integration/failure-handling.md

```md
# 失敗時対応: <プロダクト名>

| 事象 | 検知方法 | 一次対応 | 手動復旧の有無 | 復旧担当 | Handoff(risk) |
| ---- | -------- | -------- | -------------- | -------- | ------------- |
（外部API停止 / 通知未達 / 決済失敗 / 連携データ不整合 など）
```

---

# Self-check

* [ ] 外部サービスが暗黙前提になっていないか（誰も棚卸ししていない依存が無いか）
* [ ] 誰のアカウントで使うか不明なサービスがないか
* [ ] 必須連携と任意連携が分かれているか
* [ ] 通知が「送る」だけで終わっていないか（未達時の扱いがあるか）
* [ ] 決済失敗・通知未達・API停止時の扱いがあるか
* [ ] 個人情報を外部に渡す場合、[[legal-discovery]] に引き渡しているか
* [ ] 外部データの入出力が `data/data.md`（[[data-discovery]]）と接続されているか
* [ ] 手動復旧が `operations/`（[[operations-discovery]]）と接続されているか
* [ ] 決済責任・入金先が運営主体（[[business-discovery]]）と矛盾していないか
* [ ] 外部停止/API制限/通知未達/決済失敗を [[risk-discovery]] へ繋いだか
* [ ] レート制限・同期頻度・可用性要求を [[nfr-discovery]] へ繋いだか
* [ ] 利用規約・手数料・返金・SLA を [[contract-discovery]] へ繋いだか
* [ ] Assumptions / Unknowns が `decisions.md` / `open-questions.md` に分離されているか
* [ ] 上流への差し戻し質問が1件単位になっているか
* [ ] 最初は一問だけ・優先順位順に質問したか（大量質問していないか）
* [ ] 実装方式（Webhook / OAuthスコープ / API Gateway 等）を聞いていないか

---

# Prohibited

この Skill では以下を行わない。integration-discovery は **外部連携の「必要性・責任範囲・失敗時対応」の発見に集中する**。

* API仕様書の作成
* Webhook 設計
* OAuth スコープ設計
* DB 設計 / テーブル・カラム・ER図の作成
* インフラ設計
* 外部サービスの技術選定を勝手に確定すること
* 外部連携リスクの詳細分析（→ [[risk-discovery]]。見出し・失敗時の扱いのみ記録）
* レート制限・同期頻度・可用性などの非機能の設計・確定（→ [[nfr-discovery]]）
* 利用規約・手数料・返金・SLA・サポート条件の契約化（→ [[contract-discovery]]。連携上の発見のみ）
* 外部サービス・契約者・連携前提の推測による断定
* コード実装

---

関連スキル: [[project-discovery]]（オーケストレーター・Phase10）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（外部サービス責任者・通知条件・決済責任・失敗時対応の監査）/ 入力元: [[requirements-discovery]]（機能・通知・決済・入出力・画面）・[[data-discovery]]（外部入出力データ・所有権・個人情報）・[[operations-discovery]]（運営主体・運用フロー・異常時対応）・[[business-discovery]]（決済責任・費用構造）・[[scope-discovery]]（users/stakeholders）・[[legal-discovery]]（PII外部送信・同意）/ 引き渡し先: [[risk-discovery]] / [[nfr-discovery]] / [[contract-discovery]] / [[legal-discovery]]。

# 実行モデルティア

推奨ティア: **standard**（手順追従型のため標準クラスのモデルで品質が安定する）。
最上位推論クラスのモデルを占有する必要はない。手順から外れる複雑な判断が
必要になったら、その論点を明示して deep ティアの設計・監査系スキルへ引き渡すこと。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
