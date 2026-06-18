---
name: business-discovery
description: >-
  Project Discovery の Phase5（Business Discovery）担当。収益計画書やPLを作るスキルではない。
  project / scope / metrics の成果物を入力に、「このプロダクトが事業として成立するための前提・収益構造・
  顧客価値・優先ターゲット・提供価値・成功条件」を発見し、business/ 配下に整理する。
  誰に何をどの価値で提供するか / 収益モデル / 優先顧客 / 提供価値の差別化 / 初期流入経路 /
  事業観点KPI を発見し、MVP時点で成立させる事業仮説を1本立てる。
  トリガー例: 「事業として成立するか整理したい」「ビジネスモデルを固めたい」「誰に何を売るのか決めたい」
  「収益化するか無料運用かを判断したい」「事業観点のKPIを出して」「初期ユーザーをどう集めるか整理して」。
  入力は [[scope-discovery]] / [[requirements-discovery]] / [[metrics-discovery]] の成果物。
  詳細財務予測・PL作成はしない。契約詳細は [[contract-discovery]] / [[legal-discovery]]、運用体制は
  [[operations-discovery]]、非機能は [[nfr-discovery]]、事業リスクは [[risk-discovery]] へ渡す。
  [[project-discovery]] から参照され、[[discovery-planner]] / [[discovery-auditor]] のループ内で動く。
---

# Purpose

`business-discovery` は、プロダクトが **事業として成立するための前提条件** を発見するための Discovery Skill である。[[project-discovery]] の **Phase5（Business Discovery）** を担う。

このスキルは **収益計画書・事業計画書・PL（損益計算書）を作るものではない**。詳細な財務予測・売上シミュレーション・資金計画には踏み込まない。

目的は、以下を明確にすることである。

* 誰に・何を・どの価値で提供するか（事業の核）
* 収益構造（課金するのか / 無料運用なら何で成立するのか）
* 優先すべき顧客と、後回し・対象外の顧客
* 顧客の課題と、本プロダクトを使う理由（提供価値・差別化）
* 初期ユーザーをどう集めるか（go-to-market の現実性）
* 事業観点での成功条件（business-metrics）と MVP の合否判定

[[scope-discovery]] が「何を作るか」、[[requirements-discovery]] が「どう作るか」、[[metrics-discovery]] が「何を測るか」を決めるのに対し、business-discovery は **「作って・運営し続けて事業として回るのか」** を発見する。

> business-discovery は **断定しない**。推測で事業仮説を事実化しない。不明点は `decisions.md` / `open-questions.md` に分類し、仮置き可能なものは Assumption として明示する。ただし **課金・顧客・提供価値・成功判定が曖昧なまま完了扱いにしない**。

---

# When to use

* scope / requirements / metrics の一次成果物が揃い、「これは事業として成り立つのか」を整理したいとき
* 「誰に売るのか」「無料か課金か」「初期ユーザーをどう集めるか」が曖昧なまま実装に進みそうなとき
* `scope/goals.md` の成功条件と `metrics/metrics.md` の KPI が、事業としての成功に接続できているか確認したいとき
* 運営者・支払者・利用者が分かれるサービスで、誰の価値を優先するか整理が要るとき

**使わない / 渡す先**

* 詳細財務予測・PL・資金計画 → 範囲外（作らない）
* 契約書・利用規約の中身 → [[contract-discovery]] / [[legal-discovery]]
* 運用体制・CS・障害対応の設計 → [[operations-discovery]]
* スケール・可用性・性能などの非機能 → [[nfr-discovery]]
* 炎上・不正・依存停止などの事業リスク詳細 → [[risk-discovery]]（business では「事業成立上の懸念」として最低限のみ記録）

---

# Inputs

事業は **顧客 → 課題 → 提供価値 → 収益構造 → 成功条件** の順に立ち上がる。したがって business は scope / requirements / metrics への依存が強い。参照する成果物は以下。**カッコ内が実際の生成元と実ファイル名**。

**必須（これが無いと事業成立条件を接地できない）**

* project-discovery の概要成果物（プロジェクト概要・目的）（[[project-discovery]]）
* `scope/users.md` — 利用者種別 / ペルソナ（[[scope-discovery]]）
* `scope/stakeholders.md` — 関係者 / 運営者 / 支払者（[[scope-discovery]]）
* `scope/goals.md` — 解決したい課題 / 成功条件（[[scope-discovery]]）
* `scope/mvp-boundary.md` — MVP範囲の仮説（[[scope-discovery]]）
* `requirements/requirements-checklist.md` — 機能・業務フロー（[[requirements-discovery]]）
* `requirements/screen-catalog-draft.md` — 主要画面・主要CTA・主要行動（[[requirements-discovery]]）
* `metrics/metrics.md` — North Star / KPI / 成功定義（[[metrics-discovery]]。**事業成功条件はこれと矛盾させない**）

**推奨（裏取り・前提強化に使う）**

* `release-plan.md` — MVPの確定線（[[scope-discovery]] 再入ゲート / **root直下**）
* `data/data.md` — 扱うデータ・所有権・PII（[[data-discovery]]。データが価値・課金根拠になる場合に参照）
* `legal/legal.md`— 課金・規制が事業前提に効く場合（[[legal-discovery]]）
* `operations/operations.md` — 運営継続コストが収益構造に効く場合（[[operations-discovery]]。**存在すれば参照**）
* `decisions.md` / `open-questions.md` — 決定・未確定ログ（[[project-discovery]]）

> 必須入力が欠けている場合、事業成立条件を接地できないため上流へ差し戻すのが原則（[Handoff / 差し戻し条件](#handoff--差し戻し条件)）。曖昧な箇所を推測で確定しない。仮置きは Assumption（=`decisions.md` の `仮置き`）として置く。

---

# Outputs

`business/` 配下に **`domain/index.md` パターン** で生成する。Discovery Suite 全体（metrics / legal / scope / data …）と揃えるため、ドメイン index を1本立て、観点ごとに分割する。

| ファイル | 役割 |
|---|---|
| `business/business-model.md` | **index**。誰に/何を/どの価値で / 収益モデル / 費用構造 / 継続・再購入・紹介の可能性 / MVP時点で成立させる事業仮説。**[[project-discovery]] の正式参照先**。 |
| `business/customer-segments.md` | 優先顧客 / 非優先顧客 / 運営者・管理者・支払者・利用者の分離 / B2C・B2B・B2B2C・社内利用などの分類 |
| `business/value-proposition.md` | 顧客の課題 / 既存代替手段 / 本プロダクトを使う理由 / 差別化要素 / MVPで最低限証明する価値 |
| `business/revenue.md` | 課金有無 / 課金単位 / 無料運用の成立条件 / 将来課金の可能性 / 価格未定時の assumption 記録 |
| `business/go-to-market.md` | 初期流入経路 / 集客方法（営業・紹介・広告・SNS・SEO 等の候補） / 初期ユーザー獲得の現実性 / MVP公開後の検証方法 |
| `business/business-metrics.md` | `metrics/metrics.md` から事業観点KPIを抽出し 利用KPI / 収益KPI / 継続KPI / 運用KPI に分類。MVP成功判定と紐付ける |
| `decisions.md` / `open-questions.md` | 決定・保留・仮置き・差し戻しの記録（[[project-discovery]] と同期） |

> 小規模なら index の `business/business-model.md` 1本に集約し、他は同ファイル内のセクションでもよい。ただし **顧客・提供価値・収益・成功判定の4観点は省略しない**。

---

# Discovery targets

### 1. Business Model（事業の核）

* 誰に / 何を / どの価値で提供するか
* 収益モデル（課金 / 無料 / 将来課金 / 手数料 / サブスク / 広告 / 社内コスト削減 など）
* 費用構造（運営にかかる主要コスト。詳細PLは作らない）
* 継続利用 / 再購入 / 紹介が起きる可能性
* **MVP時点で成立させる事業仮説**（最初に証明する1本）

### 2. Customer Segments（優先ターゲット）

* 優先顧客（最初に価値を届ける相手）
* 非優先顧客 / 対象外
* 運営者・管理者・支払者・利用者が分かれる場合の整理（**誰の価値を優先するか**）
* 事業類型: B2C / B2B / B2B2C / 社内利用 / マッチング / プラットフォーム など

### 3. Value Proposition（提供価値）

* 顧客の課題（誰が、どれだけ困っているか）
* 既存代替手段（今どう解決しているか / 何もしていないか）
* 本プロダクトを使う理由（代替より良い点）
* 差別化要素
* **MVPで最低限証明する価値**（これが証明できなければ事業仮説は崩れる）

### 4. Revenue（収益構造）

* 課金するか / 無料運用か
* 課金単位（従量 / 定額 / 件数 / ユーザー数 / 手数料率 など）
* 無料運用の場合の成立条件（誰がコストを負担し、何の見返りで続くか）
* 将来課金の可能性とタイミング
* **価格未定時は assumption として記録**（断定しない）

### 5. Go-to-Market（初期流入）

* 初期流入経路（最低1つ）
* 集客方法の候補（営業 / 紹介 / 広告 / SNS / SEO / 既存導線 など）
* 初期ユーザー獲得の現実性（誰が・どうやって最初の N 人を連れてくるか）
* MVP公開後の検証方法（流入が成立しているかをどう確かめるか）

### 6. Business Metrics（事業観点の成功条件）

`metrics/metrics.md` から事業観点のKPIを抽出し、以下に分類する。

* 利用KPI（使われているか）
* 収益KPI（お金が回るか / 無料なら代替の価値指標）
* 継続KPI（続くか・再訪・解約）
* 運用KPI（運営コストに見合うか）

そのうえで **MVP成功判定** に紐付ける。「登録数だけ増えたら成功」のような **浅い判定を禁止** する。最低限「価値が届いた証拠」「続く兆し」「事業として割に合う兆し」のいずれかに接続する。

### 7. Business Risks（事業成立上の懸念・最低限）

事業として成立しない要因の **見出しだけ** 記録し、詳細は [[risk-discovery]] に渡す（収益前提が崩れる条件 / 集客が成立しない条件 / 継続しない条件 など）。

### 8. Assumptions / Unknowns

入力不足は推測で確定しない。以下に分類して記録する。

* Assumption（仮置き）: 仮置きして進める前提。事実として扱わない。
* Unknown（保留）: 判断不能 → `open-questions.md`。
* Needs Discovery: 上流へ戻す → scope / requirements / metrics。
* Deferred: MVP後でよい。

---

# Question logic

一度に大量質問しない。常に **「次に決めるべき1件」だけ** を質問する。最初は **一問だけ** 聞く設計にする。深掘りの1問は [[discovery-planner]] が作る。各回答は **決定 / 保留 / 仮置き / 未定 / コメント** で返せる形にする。

### 質問の優先順位

1. **誰が一番、お金・時間・手間を払ってでも解決したい課題か**（優先顧客 × 課題の強さ）
2. MVPで最初に「成功」とみなす事業成果は何か
3. 課金する予定があるか、無料で運用するか
4. 既存の代替手段は何か
5. 初期ユーザーをどう集めるか
6. 運営者にとって継続するメリットは何か

---

# Discovery loop

```text
入力成果物（project概要 / scope / requirements / metrics）を確認
 → 顧客・課題・提供価値・収益・成功条件の現状を読む
 → metrics/metrics.md の KPI・成功定義と照合（矛盾がないか）
 → [[discovery-planner]]: 次に決めるべき1件に絞って質問（最初は一問・優先順位順）
 → ユーザー回答（必ず停止して確認）
 → Business Model / Segments / Value / Revenue / GTM / Business-Metrics を更新
 → 仮置きは Assumption として明示・保留は open-questions.md へ
 → 不足・矛盾・浅い成功判定を洗い出す（必要なら上流へ差し戻す）
 → business/ を更新 / decisions.md に決定・保留・仮置きを記録
 → Phase完了判定（確信度つき）
 → 完了後 [[discovery-auditor]] へ（事業成立条件とKPIの整合を監査）
 → operations / risk / nfr / contract / legal へ引き渡し
```

---

# Handoff / 差し戻し条件

## Backward Handoff（差し戻し）

以下の場合は上流に差し戻す。差し戻し時は **質問を1つに絞る**。

| 状況 | 差し戻し先 |
|---|---|
| 優先顧客が不明 | [[scope-discovery]]（users / stakeholders） |
| MVPの提供価値が不明 | [[scope-discovery]] / [[requirements-discovery]] |
| `scope/goals.md` と `metrics/metrics.md` の成功条件が矛盾 | [[metrics-discovery]]（+ [[scope-discovery]]） |
| 収益化の有無が事業判断に必要なのに未確定 | ユーザー（決定） / 暫定は `open-questions.md` |
| ユーザー・支払者・運営者が分かれるのに未整理 | [[scope-discovery]]（stakeholders） |
| 主要CTA・主要行動が business KPI とつながっていない | [[requirements-discovery]] / [[metrics-discovery]] |

## Forward Handoff（引き渡し）

* **To [[operations-discovery]]**: 費用構造 / 運用KPI / 運営者の継続メリット / 無料運用の負担者
* **To [[risk-discovery]]**: 事業成立上の懸念（収益前提が崩れる条件 / 集客不成立 / 継続しない兆し）
* **To [[nfr-discovery]]**: 想定顧客規模 / 流入見込みからの負荷前提
* **To [[contract-discovery]] / [[legal-discovery]]**: 課金方式 / 手数料 / 紹介・パートナー前提に伴う契約・規約論点
* **To [[discovery-auditor]]**: 事業仮説 ↔ KPI ↔ 成功判定の整合、浅い成功判定の検出、未昇格の仮置き

---

# Completion criteria

兄弟Skill共通の体裁だけでは「`収益はサブスク` とだけ書いて完了」になりかねない。business は **「作れる ≠ 事業として回る」** に陥りやすいので、business特有の完了条件を満たすこと（[Phase完了判定](#phase完了判定)を出す）。

* [ ] **優先顧客が明記されている**
* [ ] **顧客課題と提供価値が対応している**（課題 → 価値の対応表がある）
* [ ] **MVPで証明する事業仮説がある**（最初に証明する1本が言語化されている）
* [ ] **`metrics/metrics.md` の KPI と `business-metrics.md` が接続されている**（事業KPIが宙に浮いていない）
* [ ] **課金有無、または無料運用の成立条件が明記されている**
* [ ] **初期流入経路が少なくとも1つある**
* [ ] MVP成功判定が「登録数だけ」のような浅い判定になっていない
* [ ] 運営者・支払者・利用者が分かれる場合、誰の価値を優先するか整理されている
* [ ] **不明点が `open-questions.md` に分離されている**
* [ ] **仮置きが Assumption として明示されている**（未昇格の仮置きが残る間は完了にしない。ユーザーが暫定通過を明示承認した場合のみ例外、その旨を記録）

> 課金・顧客・提供価値・成功判定のいずれかが曖昧なまま完了扱いにしてはならない。

### Phase完了判定

```text
## Phase完了判定: Business Discovery (Phase5)
- 優先顧客: 明記 / 未定
- 顧客課題 ↔ 提供価値の対応: 充足 / 不足
- MVP事業仮説: あり / なし
- 収益方針: 課金 / 無料(成立条件あり) / 未確定
- business-metrics ↔ metrics/metrics.md の接続: <x/n>
- 初期流入経路: <件数>（最低1）
- 成功判定の深さ: 価値到達/継続/採算のいずれかに接続 / 浅い(登録数等のみ)
- 未解消の保留: <件数>
- open-questions.md へ移送済みの仮置き: <件数> / 未昇格の仮置き: <件数>
- 確信度: 高 / 中 / 低
- 判定: 完了 / 継続 / 差し戻し
```

---

# Output templates

### business/business-model.md

```md
# 事業モデル: <プロダクト名>

## サマリ
* Project:
* Business Discovery Status:
* Confidence:
* 一文事業仮説（誰に / 何を / どの価値で）:

## 事業の核
| 誰に | 何を | どの価値で |
| ---- | ---- | ---------- |

## 収益モデル
| モデル | 内容 | 課金/無料 | MVPで成立させるか |
| ------ | ---- | --------- | ----------------- |

## 費用構造（主要コストのみ・PL作成はしない）
| コスト項目 | 種別(固定/変動) | 備考 |
| ---------- | --------------- | ---- |

## 継続・再購入・紹介の可能性
| 行動 | 起きる条件 | 根拠/仮置き |
| ---- | ---------- | ----------- |

## MVP時点で成立させる事業仮説
* 仮説:
* 成立とみなす条件:
* 崩れる条件:

## 事業成立上の懸念（最低限・詳細は risk-discovery へ）
| 懸念 | 影響 | Handoff |
| ---- | ---- | ------- |

## Assumptions / Unknowns（decisions.md / open-questions.md と同期）
| 種別 | 内容 | 理由 | Confirm By |
| ---- | ---- | ---- | ---------- |
```

### business/customer-segments.md

```md
# 顧客セグメント: <プロダクト名>

## 事業類型
* 分類: B2C / B2B / B2B2C / 社内利用 / マッチング / プラットフォーム
* 理由:

## 優先顧客
| セグメント | 課題の強さ | 支払/負担の主体か | なぜ優先か |
| ---------- | ---------- | ----------------- | ---------- |

## 非優先 / 対象外顧客
| セグメント | 理由 | 将来対象化の可能性 |
| ---------- | ---- | ------------------ |

## 役割分離（運営者・管理者・支払者・利用者）
| 役割 | 誰 | 得る価値 | 負担 |
| ---- | -- | -------- | ---- |
```

### business/value-proposition.md

```md
# 提供価値: <プロダクト名>

## 顧客課題 ↔ 提供価値
| 顧客 | 課題 | 既存代替手段 | 本プロダクトを使う理由 | 差別化要素 |
| ---- | ---- | ------------ | ---------------------- | ---------- |

## MVPで最低限証明する価値
* 証明する価値:
* 証明できたと言える条件:
* 関連KPI（business-metrics と接続）:
```

### business/revenue.md

```md
# 収益構造: <プロダクト名>

## 課金方針
* 課金有無: 課金 / 無料 / 将来課金
* 理由:

## 課金単位（課金する場合）
| 課金単位 | 内容 | 価格(未定なら assumption) |
| -------- | ---- | ------------------------- |

## 無料運用の成立条件（無料の場合）
| 負担者 | 何のコスト | 見返り | 続く条件 |
| ------ | ---------- | ------ | -------- |

## 将来課金の可能性
| タイミング | 課金対象 | 前提 |
| ---------- | -------- | ---- |

## Assumptions（価格・課金前提の仮置き）
| Assumption | 理由 | Risk | Confirm By |
| ---------- | ---- | ---- | ---------- |
```

### business/go-to-market.md

```md
# Go-to-Market: <プロダクト名>

## 初期流入経路（最低1）
| 経路 | 集客方法 | 想定獲得規模 | 現実性(高/中/低) |
| ---- | -------- | ------------ | ---------------- |

## 初期ユーザー獲得
* 誰が最初の N 人を連れてくるか:
* N の目安:
* 前提/仮置き:

## MVP公開後の検証方法
| 検証したいこと | 確認方法 | 関連KPI |
| -------------- | -------- | ------- |
```

### business/business-metrics.md

```md
# 事業KPI: <プロダクト名>

> metrics/metrics.md から事業観点で抽出。新規KPIを乱造せず、metrics と矛盾させない。

## 分類
### 利用KPI（使われているか）
| KPI | metrics由来 | MVP成功判定への寄与 |
| --- | ----------- | ------------------- |
### 収益KPI（お金が回るか / 無料なら代替価値指標）
| KPI | metrics由来 | MVP成功判定への寄与 |
| --- | ----------- | ------------------- |
### 継続KPI（続くか）
| KPI | metrics由来 | MVP成功判定への寄与 |
| --- | ----------- | ------------------- |
### 運用KPI（採算に見合うか）
| KPI | metrics由来 | MVP成功判定への寄与 |
| --- | ----------- | ------------------- |

## MVP成功判定（浅い判定の禁止）
* 成功とみなす条件（価値到達 / 継続 / 採算のいずれかに接続）:
* 失敗とみなす条件:
* 「登録数だけ増えた」を成功にしない理由:
```

---

# Self-check

* [ ] 優先顧客が明記されている
* [ ] 顧客課題と提供価値が対応している
* [ ] MVPで証明する事業仮説が1本ある
* [ ] 収益方針（課金 / 無料の成立条件）が明記されている
* [ ] 初期流入経路が最低1つある
* [ ] business-metrics が `metrics/metrics.md` と接続している（宙に浮いたKPIが無い）
* [ ] MVP成功判定が浅くない（登録数だけ等になっていない）
* [ ] 運営者・支払者・利用者が分かれる場合、誰の価値を優先するか整理されている
* [ ] Assumptions / Unknowns が `decisions.md` / `open-questions.md` に分離されている
* [ ] 上流への差し戻し質問が1件単位になっている
* [ ] 最初は一問だけ・優先順位順に質問したか（大量質問していないか）
* [ ] 詳細財務予測・PL を作っていないか
* [ ] 契約 / 運用 / 非機能 / リスク詳細を抱え込まず適切なスキルへ渡しているか

---

# Prohibited

この Skill では以下を行わない。

* 詳細な財務予測・PL（損益計算書）・資金計画の作成
* 法務契約・利用規約の中身の作成（→ [[contract-discovery]] / [[legal-discovery]]）
* 運用体制・CS・障害対応の設計（→ [[operations-discovery]]）
* 非機能要件の確定（→ [[nfr-discovery]]）
* 事業リスクの詳細分析（→ [[risk-discovery]]。見出しのみ記録）
* 顧客・課題・収益・成功判定の推測による断定
* 「登録数だけ増えたら成功」のような浅いMVP成功判定
* metrics と矛盾する独自KPIの乱造
* 情報不足を仮定で確定すること（仮置きは `decisions.md` に明示）

---

関連スキル: [[project-discovery]]（オーケストレーター・Phase5）/ [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（事業成立条件・KPI整合の監査）/ 入力元: [[scope-discovery]]（users/stakeholders/goals/mvp-boundary）・[[requirements-discovery]]（機能・導線・CTA）・[[metrics-discovery]]（KPI・成功定義）/ 引き渡し先: [[operations-discovery]] / [[risk-discovery]] / [[nfr-discovery]] / [[contract-discovery]] / [[legal-discovery]]。
