# スキル別 改善方針（eval駆動(TDD) vs 現状維持）

作成日: 2026-06-25

「全スキルを一律に eval ループへ載せる」のは過剰。**発火が競合するスキルだけ**を eval駆動（トリガーeval を先に書く→ `run_loop` で description を test スコア基準に最適化→適用）で詰め、
**トリガーが固有で誤発火リスクが低いスキル**は現状維持にする。判断軸は「兄弟/バンドルとキーワードが被るか」「名前・流れの中で意図的に呼ばれるか」。

## 用語

- **eval駆動(TDD)**: `evals/trigger/<skill>.json` に正例/負例(近接ケース)を書く → [run-trigger-eval.ps1](run-trigger-eval.ps1) で `run_loop` を回し、トリガー率を測って description を最適化 → `best_description` を適用。
- **現状維持(as-is)**: description に既に排他句（「〜はしない」）があり競合が小さいので、評価ループは回さず据え置き。誤発火が観測されたら A 群へ昇格。

## 判定（3層）

### A: eval駆動で詰める（競合が強い／バンドル重複）— 今回の主対象
| Skill | 競合相手 | 理由 |
|---|---|---|
| **scope-discovery** | requirements | 「範囲を決める」と「要件を詰める」が混同されやすい |
| **requirements-discovery** | scope / screen / saas-pm | 入口語が広く取りこぼし/誤発火両方が起きる |
| **business-discovery** | operations / metrics / contract | 「KPI」「価値」「収益」が他フェーズと被る |
| **operations-discovery** | business / risk / contract | 「返金」「異常時」が contract/risk と競合 |
| legal-discovery | contract / legal-publication-manager | 「何が必要か」と「契約条件」と「掲載運用」の三つ巴 |
| contract-discovery | legal / operations | 返金・SLA・責任範囲の帰属が曖昧 |
| risk-discovery | nfr / operations | 可用性・属人化の線引き |
| nfr-discovery | risk / operations | 性能・コスト・運用性の帰属 |
| integration-discovery | risk / nfr | 外部停止・レート制限の帰属 |
| metrics-discovery | business | KPI の事業観点 vs 計測定義 |
| screen-design-architect | requirements / ui-ux-review | 「画面」で三者が競合 |
| code-review | バンドル `/code-review` / security-review | 汎用はバンドル、自作は Supabase 特化に寄せる境界を数値で確認 |
| security-review | バンドル `/security-review` / code-review | 同上 |

> **A群13本すべて trigger eval を正10/負10=20件へ拡充済み**（[trigger/](trigger/)）。run_loop をそのまま回せる。
> 最優先で効果検証するなら scope / requirements / business / operations の4本から。

### B: 現状維持で十分（トリガーが固有／意図的に呼ばれる）
| Skill | 理由 |
|---|---|
| project-discovery | オーケストレータ。「立ち上げたい」で意図的に呼ばれ、キーワード誤発火が起きにくい |
| discovery-planner / discovery-auditor | フロー内で制御役として呼ばれる。単独誤発火は実害が小さい |
| agent-planner / agent-tester | 実装ループ内で位置的に呼ばれる。トリガー競合が無い |
| api-designer | 「API設計」が固有で被りが小さい |
| prompt-architect | 「プロンプト設計」が固有 |
| refactor-planner | 「リファクタ」が固有 |
| test-planner | 「テスト観点」が固有 |
| project-quality-tooling | 「Linter/Formatter初期導入」が固有 |

### C: 競合あり・次点（A-lite。Bより優先度は上、今回の主対象外）
| Skill | 競合相手 |
|---|---|
| data-discovery | db-designer（「何のデータ」vs テーブル設計） |
| legal-publication-manager | legal-discovery（発見 vs 掲載運用） |
| saas-product-manager | requirements / implementation-planner |
| db-designer | migration-review / data-discovery |
| feature-spec-writer | implementation-planner |
| implementation-planner | feature-spec-writer / saas-product-manager |
| system-investigator | bug-investigator / data-flow-mapper |
| bug-investigator | system-investigator |
| data-flow-mapper | system-investigator |
| migration-review | db-designer / security-review |
| ui-ux-review | screen-design-architect |

## 実行（A群・あなたの端末で）

`claude` CLI が通るターミナルから（A群13本を一括、または1本ずつ）:
```powershell
powershell -File evals/run-trigger-eval.ps1 -All
powershell -File evals/run-trigger-eval.ps1 -Skill scope-discovery
```
出力の `best_description`（test スコア基準で過学習回避）を、各 `.skills/<skill>/SKILL.md` の description に反映し、`scripts/sync-skills.ps1 -Apply` でミラーへ同期する。

> 注: `run_loop` は description を**書き換える提案**を返す。適用前に before/after を確認し、固有の排他句（「〜はしない」）が失われていないかを必ずチェックすること。
