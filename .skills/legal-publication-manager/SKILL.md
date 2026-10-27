---
name: legal-publication-manager
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: standard
  summary: "法務成果物の掲載・版管理の運用担当。必要文書を「どこに載せるか/どの雛形を使うか/どう更新管理するか」に変換し、掲載設計・成果物レジストリ・更新トリガーを生成する。適法性判断はしない。"
description: >-
  [[legal-discovery]] が発見した「必要な法務成果物」を、実際に **どこに掲載するか / どの雛形を使うか /
  どう版管理・更新管理するか** に変換する運用管理スキル。法的助言・規約本文の適法性判断はしない。
  legal/legal.md / legal/legal-risk.md / legal/legal-open-questions.md と decisions.md を入力に、
  掲載設計（フッター・登録画面・決済画面・Cookieバナー・退会画面など）/ 再利用テンプレート適用 /
  成果物レジストリ（ステータス・最終更新日・レビュー担当・公開先）/ 更新トリガー定義 を生成する。
  legal/publication-plan.md / legal/legal-doc-registry.md / legal/legal-update-policy.md を出力し、
  必要に応じて legal/templates/ に再利用雛形（プレースホルダ形式）を配置する。トリガー例:
  「法務文書をどこに載せるか整理して」「規約・ポリシーの雛形を用意して」「公開前チェックリストを作って」
  「課金方式を変えたらどの法務文書を直すか決めたい」「法務成果物の状態を一覧管理したい」。
  legal-discovery の判断を上書きしない（不明点は legal-open-questions と registry に同期）。
  コードやUIは直接変更しない（掲載場所・導線・ページ要件を文書化するだけ）。雛形本文を最終版扱いしない
  （必ず 要専門家レビュー / 事業責任者確認 を残す）。何が必要かの発見は [[legal-discovery]]、
  契約条件は [[contract-discovery]]、PII前提は [[data-discovery]]、設置UIは [[screen-design-architect]]。
---

# Purpose

このスキルは **法的助言や規約本文の適法性判断をしない**。[[legal-discovery]] が「何の法務成果物が必要か」を発見した後を受けて、それを **掲載・運用管理・テンプレート適用・プロジェクト別差分管理** に変換する。

役割の境界：

- [[legal-discovery]] … 「何が必要か」を発見する（必要 / 不要 / 要専門確認）
- **legal-publication-manager（本スキル）** … 「**どこに出すか・どの雛形を使うか・どう持つか・どう更新するか**」を管理する

これにより「規約は必要と分かったが置き場所が決まっていない」「課金方式を変えたのに特商法表記が古いまま」「どの文書が公開済みか誰も把握していない」といった **掲載漏れ・更新漏れ・状態不明** を防ぐ。プロジェクト横断で再利用できる雛形を持ち、固有値はプレースホルダにする。

# 基本方針

- **法的に有効であると断定しない**。雛形本文を最終版として扱わず、必ず `要専門家レビュー` または `事業責任者確認` の状態を残す。
- [[legal-discovery]] の判断を **上書きしない**。要否の再判定はしない。不明点は `legal/legal-open-questions.md` と `legal/legal-doc-registry.md` に **同期** する。
- 共通雛形はプロジェクト横断で再利用できるようにする。各プロジェクト固有の値は **プレースホルダ** にする（例: `<サービス名>`, `<運営者名>`, `<所在地>`, `<問い合わせ先>`, `<決済方法>`, `<取得する個人情報>`, `<外部委託先>`）。
- 個人情報の分類を **独自に確定しない**（[[data-discovery]] の責務）。その結果を参照して掲載・更新管理に変換する。
- コードや UI を **直接変更しない**。必要な掲載場所・導線・ページ要件を **文書化するだけ** にする（UI 化は [[screen-design-architect]] へ）。
- 未確定・専門家レビュー項目は管理表に **残す**。勝手に「公開可」にしない。

# 重要原則: 法的助言を提供しない

- 出力は「掲載設計・状態管理・雛形のたたき台」であり、**法的結論ではない**。
- 雛形に「弁護士レビュー済み」と書かない。契約書本文を起案しない。
- 適法性の断定が必要な箇所は `要専門家レビュー` のまま残し、registry のステータスを `専門家レビュー待ち` に置く。
- 判断材料が足りない場合は捏造せず `legal/legal-open-questions.md` に積む。

# 入力

- `legal/legal.md`（[[legal-discovery]] / 必要な法務成果物インベントリ ＝ 主入力）
- `legal/legal-risk.md`（[[legal-discovery]] / 法務リスク → 更新トリガーの根拠）
- `legal/legal-open-questions.md`（[[legal-discovery]] / 未確定・要専門家レビュー → registry と同期）
- `decisions.md`（[[project-discovery]] の決定・保留・仮置きログ）
- 必要に応じて: `requirements/requirements.md` / `data/data.md`（PII・取得データ）/ `business/business-model.md`（課金方式）

> 入力が無い・未確定の場合は捏造せず、その前提を `legal/legal-open-questions.md` と registry に「情報不足」として積む。

# 出力

- `legal/publication-plan.md` … 各法務成果物の **掲載場所・設置箇所・MVP要否**
- `legal/legal-doc-registry.md` … 成果物の **ステータス・最終更新日・レビュー担当・公開先** 管理表
- `legal/legal-update-policy.md` … どの変更が起きたらどの文書を見直すかの **更新トリガー**
- `legal/templates/`（必要に応じて）… 再利用雛形（プレースホルダ形式）。雛形本文は [references/templates.md](references/templates.md) を原本として複製・差し込みする

## 雛形カタログ（references/templates.md 参照）

| 雛形ファイル | 用途 |
|---|---|
| `terms-template.md` | 利用規約 |
| `privacy-policy-template.md` | プライバシーポリシー |
| `commerce-disclosure-template.md` | 特定商取引法に基づく表記 |
| `refund-policy-template.md` | 返金ポリシー |
| `cancellation-policy-template.md` | キャンセルポリシー |
| `data-deletion-policy-template.md` | データ削除ポリシー |
| `cookie-policy-template.md` | Cookie ポリシー |

# ワークフロー

```text
1. [[legal-discovery]] の出力を読む（legal.md / legal-risk.md / legal-open-questions.md / decisions.md）
2. 必要成果物を一覧化する（legal.md のインベントリをそのまま採用。要否は再判定しない）
3. 各成果物に掲載場所を割り当てる → publication-plan.md
4. 基本雛形の有無を確認する（references/templates.md / legal/templates/）
5. 無ければ reusable template を legal/templates/ に作成する（原本は references/templates.md を複製）
6. プロジェクト固有の差し込み項目（プレースホルダ）を抽出する
7. 公開前チェックリストを作る → publication-plan.md
8. 更新トリガーを定義する → legal-update-policy.md
9. registry に状態を記録する（ステータス / 最終更新日 / レビュー担当 / 公開先）→ legal-doc-registry.md
10. 未確定・要専門家レビューを legal-open-questions.md と registry に同期
```

各ステップで判断が要る箇所は 1テーマ1問で確認する（[[discovery-planner]] の停止ゲートに準拠）。掲載場所・MVP要否・公開担当などは勝手に確定せず、未定なら registry に「未確定」で残す。

## 掲載場所の典型（publication-plan.md で割り当てる）

| 設置箇所 | 載りやすい成果物 |
|---|---|
| フッター（全画面共通） | 利用規約 / プライバシーポリシー / 特商法表記 / Cookieポリシー |
| 登録画面（同意チェック） | 利用規約 / プライバシーポリシー同意 |
| 決済画面 | 特商法表記 / 返金ポリシー / キャンセルポリシー |
| Cookie バナー | Cookieポリシー / 同意取得 |
| 退会画面 | データ削除ポリシー / 退会後の扱い |
| 専用ページ | 特商法表記 / 各ポリシー本文 |

> 設置箇所の **UI・導線そのものの設計** は [[screen-design-architect]] へ渡す。ここでは「どこに何を載せる必要があるか」を文書化するだけ。

# 禁止事項

- 法的に有効であると **断定** する
- 法律解釈を確定する
- 「弁護士レビュー済み」と書く
- 個人情報の分類を独自に確定する（[[data-discovery]] の責務）
- 契約書本文を起案する（[[contract-discovery]] / 専門家の領域）
- 既存 UI やコードを直接編集する
- [[legal-discovery]] の要否判断を上書きする

# 完了条件

- `legal/publication-plan.md` がある（各成果物の掲載場所・MVP要否・公開前チェックリスト）
- `legal/legal-doc-registry.md` がある（ステータス・最終更新日・レビュー担当・公開先）
- `legal/legal-update-policy.md` がある（更新トリガー）
- 必要な基本雛形が `legal/templates/` にある（プレースホルダ形式）
- 未確定事項と専門家レビュー項目が管理表に残っている
- 各プロジェクトで再利用できるプレースホルダ形式になっている

> 未解消の「要専門家レビュー」や未確定の掲載場所が残る間は、該当成果物を registry で「公開可」にしない（ユーザーが明示的に暫定通過を承認した場合のみ例外、その旨を記録）。

# Output Template

### legal/publication-plan.md

```md
# 法務成果物 掲載プラン: <サービス名>

## サマリ
（どの成果物をどこに載せるかの1〜3行説明）

## 掲載割り当て
| 成果物 | 掲載場所 | 設置箇所(導線) | MVP要否(必須/後回し) | 公開前必須チェック | 備考 |
|---|---|---|---|---|---|
| 利用規約 | 登録画面/フッター | 同意チェックボックス | 必須 | 同意ログ保存の手当て | screen-design-architect へ |
| プライバシーポリシー | フッター | 専用ページ | 必須 | 取得項目と一致 | data-discovery と照合 |
| 特商法表記 | 専用ページ/決済画面 | 決済前に到達可能 | 必須 | 運営者情報の確定 | 要専門家レビュー |
| 返金ポリシー | フッター/決済画面 | 決済前に明示 | 後回し | 返金条件の確定 | 未確定 |

## 公開前チェックリスト
- [ ] 必須成果物がすべて registry で「公開可」以上
- [ ] 各成果物の掲載場所が確定している
- [ ] プレースホルダがプロジェクト値に差し替え済み
- [ ] 要専門家レビュー項目が解消 or 承認済み
- [ ] 同意取得が必要な成果物の同意ログ手当てを data-discovery に確認
```

### legal/legal-doc-registry.md

```md
# 法務成果物レジストリ: <サービス名>

| 成果物 | ステータス | 最終更新日 | レビュー担当 | 公開URL/配置先 | 要専門家レビュー | 備考 |
|---|---|---|---|---|---|---|
| 利用規約 | 雛形適用済み | 2026-06-20 | <担当> | /legal/terms | 推奨 | プレースホルダ未差替 |
| プライバシーポリシー | プロジェクト調整中 | 2026-06-20 | <担当> | /legal/privacy | 推奨 | data-discovery 待ち |
| 特商法表記 | 専門家レビュー待ち | - | <担当> | /legal/commerce | 必須 | 運営者情報未確定 |

> ステータス: 未作成 / 雛形適用済み / プロジェクト調整中 / 専門家レビュー待ち / 公開可 / 公開済み
```

### legal/legal-update-policy.md

```md
# 法務文書 更新ポリシー: <サービス名>

| 発生した変更 | 見直す法務文書 | 理由 | 確認相手 |
|---|---|---|---|
| 課金方式の変更 | 特商法表記 / 返金 / キャンセル | 表示義務・自動更新説明 | 事業責任者 |
| 取得データの変更 | プライバシーポリシー / 同意 | 取得項目の開示 | data-discovery |
| 外部サービス追加 | プライバシーポリシー / 委託先一覧 | 第三者提供・委託 | data-discovery |
| ユーザー投稿機能の追加 | 利用規約(投稿ガイドライン) | 権利侵害・削除フロー | 事業責任者 |
| 未成年利用の追加 | 利用規約 / 同意フロー | 親権者同意 | 要専門家レビュー |
| 越境移転・海外利用者の追加 | プライバシーポリシー | GDPR/CCPA等 | 要専門家レビュー |
| 運営者情報の変更 | 特商法表記 | 表記義務 | 事業責任者 |
```

# セルフチェック

- [[legal-discovery]] の要否判断を **上書きしていない**か（要否を再判定していないか）
- 雛形本文を最終版扱いしていないか（`要専門家レビュー` / `事業責任者確認` を残したか）
- 「弁護士レビュー済み」と書いていないか / 適法性を断定していないか
- 固有値を **プレースホルダ** にし、プロジェクト横断で再利用可能にしたか
- 個人情報の分類を独自確定せず、[[data-discovery]] の結果を参照したか
- 掲載場所の UI 設計に踏み込まず、[[screen-design-architect]] にリンクしたか
- 既存 UI・コードを直接編集していないか
- 3つの主成果物（publication-plan / registry / update-policy）が揃ったか
- 未確定・要専門家レビューを registry と `legal/legal-open-questions.md` に同期したか
- 掲載場所・公開担当が未定の箇所を勝手に確定していないか

---

関連スキル: 入力元 [[legal-discovery]]（何が必要か）/ [[contract-discovery]]（契約条件）/ [[data-discovery]]（PII・取得データ）/ [[business-discovery]]（課金方式）/ 引き渡し先 [[screen-design-architect]]（掲載UI・同意導線）/ 進行補助 [[discovery-planner]]（次の1問）/ [[discovery-auditor]]（横断監査）/ オーケストレーター [[project-discovery]]。

# 実行モデルティア

推奨ティア: **standard**（手順追従型のため標準クラスのモデルで品質が安定する）。
最上位推論クラスのモデルを占有する必要はない。手順から外れる複雑な判断が
必要になったら、その論点を明示して deep ティアの設計・監査系スキルへ引き渡すこと。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
