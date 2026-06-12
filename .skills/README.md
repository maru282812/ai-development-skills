# Skill 選択ガイド

「今の依頼はどの Skill に投げるべきか」を3秒で判断するためのガイドです。

---

## 開発フロー と Skill の対応

```
調査
  ├─ system-investigator   使用箇所・影響範囲の調査
  ├─ bug-investigator      エラー・不具合の原因特定
  └─ data-flow-mapper      データの流れの可視化

↓

設計
  ├─ saas-product-manager  機能仕様・MVP・Phase分け
  ├─ db-designer           テーブル・RLS・migration設計
  ├─ api-designer          APIインターフェース設計
  ├─ prompt-architect      LLMプロンプト設計・改善
  └─ feature-spec-writer   AI向け実装仕様書作成

↓

実装
  └─ implementation-planner  実装計画・Phase分け・Codex指示文

↓

レビュー
  ├─ code-review           コード品質・バグ・実装漏れ
  ├─ security-review       RLS・認可・情報漏洩
  ├─ migration-review      migration SQL の安全確認
  ├─ ui-ux-review          画面の使いやすさ・導線
  └─ refactor-planner      既存コードの構造改善

↓

テスト
  └─ test-planner          テスト観点・受け入れ条件・QAチェックリスト

↓

リリース
  ├─ migration-review      本番適用前の最終確認
  └─ security-review       リリース前セキュリティ監査
```

---

## こんな時はこの Skill

---

## 使われてるか調べたい

**Skill:** `system-investigator`

例:
- Commonは使われてる？
- AbstractFileMakerはどこから呼ばれてる？
- このカラム追加したらどこ直す？
- 影響範囲は？
- このAPIの呼び出し元は？
- このテーブルはどこから参照されてる？
- 関連ファイルを探して
- 検索キーワードを洗い出して

---

## エラーの原因を調べたい

**Skill:** `bug-investigator`

例:
- PGRST205が出る
- buildは通るけど動かない
- 500エラー
- hydration error
- ログインできない
- 画面が真っ白
- データが表示されない
- 昨日まで動いていたのに動かなくなった

> エラーがない場合の構造調査は `system-investigator` を使う

---

## データの流れを知りたい

**Skill:** `data-flow-mapper`

例:
- この値はどこから来る？
- どこに保存される？
- CRUD図で言うと何してる？
- この画面はどのテーブル？
- この項目の出どころは？
- データの流れを整理して

> 改修のための影響範囲調査は `system-investigator`、バグ原因調査は `bug-investigator` を使う

---

## 機能仕様を整理したい / MVPを決めたい

**Skill:** `saas-product-manager`

例:
- 仕様を整理して
- SaaSとして考えて
- ユーザー導線を考えて
- MVPに分けて
- 優先順位を決めて
- Phase分けして
- 管理画面の仕様を考えて
- この機能どこまで作るべき？

> 仕様が固まった後の実装計画は `implementation-planner`、UI改善は `ui-ux-review` を使う

---

## DB設計したい

**Skill:** `db-designer`

例:
- テーブル設計して
- DB設計して
- カラムを考えて
- ER図を考えて
- Supabaseのテーブルを作りたい
- RLS前提で設計して
- どのテーブルに持たせる？
- 正規化した方がいい？
- リレーションどうする？

> 作成済みmigration SQLの安全確認は `migration-review` を使う

---

## API設計したい

**Skill:** `api-designer`

例:
- API設計して
- エンドポイント考えて
- route handler作って
- request / response考えて
- Server ActionsにするかAPIにするか
- 認可チェックどこでやる？
- APIのインターフェース決めて
- レスポンス形式どうする？

> DB設計は `db-designer`、実装後の確認は `code-review` / `security-review` を使う

---

## AIへの実装仕様書を作りたい

**Skill:** `feature-spec-writer`

例:
- 指示文を作って
- 仕様書にして
- Codexに投げたい
- 実装指示にまとめて
- この機能の仕様書を書いて
- AIに実装させる用の文章にして

> 要件がまだ曖昧なら先に `saas-product-manager`、大規模な実装計画は `implementation-planner` を使う

---

## 実装計画・Phase分けを作りたい

**Skill:** `implementation-planner`

例:
- 実装して（まず計画から）
- Phaseを作って
- 実装指示文を考えて
- どの順番で作る？
- どのファイルを作る？
- Codexに投げる指示文を作って
- Claude Codeに渡す実装指示を作って
- タスクに分解して

> 調査だけが目的なら `system-investigator`、DB設計は `db-designer`、API設計は `api-designer` を先に使う

---

## プロンプト設計・改善したい

**Skill:** `prompt-architect`

例:
- プロンプト設計して
- system prompt作って
- 分析プロンプトを改善して
- 回答品質を上げたい
- AIの挙動を変えたい
- 出力が安定しない
- JSONで返ってこない
- プロンプトをレビューして
- few-shot入れるべき？

> プロンプトをDBに保存する機能の設計は `db-designer`、AI呼び出しAPIの設計は `api-designer` を使う

---

## migration SQLを確認したい

**Skill:** `migration-review`

例:
- migration確認して
- SQL確認して
- Supabase migration大丈夫？
- RLSが足りてる？
- 既存データ壊れない？
- rollbackできる？
- 本番適用して大丈夫？
- この ALTER TABLE危なくない？

> これから設計する段階は `db-designer`、アプリ全体のセキュリティ確認は `security-review` を使う

---

## セキュリティを確認したい

**Skill:** `security-review`

例:
- セキュリティ確認して
- RLS大丈夫？
- service_role危なくない？
- 個人情報大丈夫？
- 認可漏れない？
- 情報漏洩しない？
- 他人のデータ見えない？
- anon keyで何ができる？

> コード品質全般は `code-review`、migration単体は `migration-review` を使う

---

## テスト観点・確認項目を作りたい

**Skill:** `test-planner`

例:
- テスト観点を考えて
- 動作確認項目を作って
- 受け入れ条件を作って
- QA観点を出して
- E2Eテスト考えて
- 手動確認手順を作って
- regressionを確認して
- チェックリスト作って
- 何を確認すればいい？

---

## コードをレビューしたい

**Skill:** `code-review`

例:
- レビューして
- 問題ないか見て
- バグがないか確認して
- 実装漏れは？
- 設計的に大丈夫？
- このコードでいい？
- buildは通るけど不安
- この実装どう思う？

> セキュリティを深く見たいなら `security-review`、migration SQLは `migration-review`、構造整理は `refactor-planner` を使う

---

## UI/UXを改善したい

**Skill:** `ui-ux-review`

例:
- UI見て
- UX改善して
- 画面導線を考えて
- 管理画面を使いやすくして
- ボタン配置どうする？
- フォームを改善して
- スマホで使いやすくして
- この画面わかりにくい
- 文言を直して

> 機能仕様の整理は `saas-product-manager`、コード品質確認は `code-review` を使う

---

## コードを整理・リファクタしたい

**Skill:** `refactor-planner`

例:
- リファクタして
- 共通化して
- 責務分離して
- 重複を減らして
- service / repositoryに分けて
- ファイルが大きい
- 保守しやすくして
- このコンポーネント分割して

> 機能追加を伴う場合は、先にこのSkillで整理 → 後で `implementation-planner` で機能追加の2段に分ける

---

## 一覧表

| やりたいこと | Skill |
|---|---|
| 使用箇所調査・影響範囲分析 | `system-investigator` |
| エラー・不具合の原因調査 | `bug-investigator` |
| データの流れ・CRUD可視化 | `data-flow-mapper` |
| 機能仕様整理・MVP・Phase分け | `saas-product-manager` |
| DB設計・RLS・migration案 | `db-designer` |
| API設計・エンドポイント設計 | `api-designer` |
| AI向け実装仕様書作成 | `feature-spec-writer` |
| 実装計画・Codex指示文作成 | `implementation-planner` |
| LLMプロンプト設計・改善 | `prompt-architect` |
| migration SQL安全確認 | `migration-review` |
| セキュリティ確認・RLS監査 | `security-review` |
| テスト観点・受け入れ条件 | `test-planner` |
| コードレビュー・品質確認 | `code-review` |
| UI/UX改善・導線確認 | `ui-ux-review` |
| リファクタ・構造整理 | `refactor-planner` |

---

## よくある質問からの逆引き

```
「使われてる？」
→ system-investigator

「どこ直す？」
→ system-investigator

「影響範囲は？」
→ system-investigator

「なぜ動かない？」
→ bug-investigator

「エラーが出る」
→ bug-investigator

「どのテーブル？」
→ data-flow-mapper

「値はどこから来る？」
→ data-flow-mapper

「仕様を整理して」
→ saas-product-manager

「MVPに分けて」
→ saas-product-manager

「DB設計して」
→ db-designer

「API設計して」
→ api-designer

「仕様書作って」「Codexに投げる文章にして」
→ feature-spec-writer

「実装指示文作って」「どの順番で作る？」
→ implementation-planner

「プロンプト設計して」「出力が安定しない」
→ prompt-architect

「migration確認して」「SQL大丈夫？」
→ migration-review

「セキュリティ大丈夫？」「RLS漏れない？」
→ security-review

「テスト観点出して」「何を確認すればいい？」
→ test-planner

「レビューして」「バグないか見て」
→ code-review

「UI見て」「使いにくい」「文言直して」
→ ui-ux-review

「リファクタして」「共通化して」「ファイルが大きい」
→ refactor-planner
```

---

## Skill 間の連携パターン

よく使われる組み合わせ順序:

```
新機能開発
saas-product-manager → db-designer → api-designer → feature-spec-writer → implementation-planner

リリース前チェック
code-review → migration-review → security-review → test-planner

バグ対応
bug-investigator → system-investigator（影響範囲）→ implementation-planner（修正計画）

リファクタ
system-investigator → refactor-planner → test-planner（regression確認）
```
