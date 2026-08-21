---
name: implementation-planner
allowed-tools: Read, Write, Edit, Grep, Glob
metadata:
  reasoning-tier: standard
  summary: "実装計画づくり担当。Next.js + Supabase の機能開発で、目的・変更対象・実装順序・Phase分けを整理し、Codex/Claude Code にそのまま渡せる実装指示文を作る。"
description: >-
  Next.js + Supabase の機能開発で、実装前に目的・変更対象・実装順序・Phase分けを
  整理し、Codex / Claude Code にそのまま渡せる実装指示文を作成するスキル。
  トリガー例:
  「実装して」「Phase を作って」「実装指示文を考えて」「どの順番で作る?」
  「どのファイルを作る?」「この機能を追加したい」「実装フェーズに分けて」
  「Codex に投げる指示文を作って」「Claude Code に渡す実装指示を作って」
  「実装計画を立てて」「タスクに分解して」。
  新機能追加・既存機能改修の実装計画づくり、AIコーディングエージェント向けの
  指示文作成が含まれる依頼ではこのスキルを使用する。
---

# Purpose

実装に着手する前に、目的・前提・変更対象・実装順序を整理し、
人間にも AI コーディングエージェント(Codex / Claude Code)にも渡せる実装計画を作成する。

整理する内容:

- 実装の目的(なぜ作るのか)
- 現状の前提(既存コード・既存テーブル・既存API)
- 実装対象(何を作る/変えるのか)
- 変更ファイル候補(新規作成 / 修正)
- DB変更の有無(テーブル・カラム・RLS・migration)
- API変更の有無(Route Handler / Server Actions)
- UI変更の有無(画面・コンポーネント)
- 実装順序と Phase 分け
- そのまま投げられる実装指示文

# When To Use

- 新機能を追加したいが、どこから手を付けるか決めたい
- 実装をフェーズに分けて段階的に進めたい
- Codex / Claude Code に渡す実装指示文を作りたい
- どのファイルを作成・修正するか事前に洗い出したい
- 複数人(または複数セッション)で分担するためにタスク分解したい

対象外(このスキルは使わない):

- 環境構築・PCセットアップ・ツール導入・アカウント作成など、コードを1行も書かない準備工程(Phase 0系)。
  このスキルの Phase は「コード実装の依存順(DB→型→API→UI)」であって作業手順書ではないため噛み合わない。
  git/GitHub の初期化は [git-init-setup](../git-init-setup/SKILL.md)、それ以外の準備工程は要件定義成果物から直接手順化する。

調査だけが目的なら [system-investigator](../system-investigator/SKILL.md)、
DB設計の詳細は [db-designer](../db-designer/SKILL.md)、
API設計の詳細は [api-designer](../api-designer/SKILL.md) を先に使うこと。

# Procedure

### 1. 目的とゴールの確認

- 何を実現したいのか、完成時にユーザーが何をできるようになるかを1〜2文で言語化する
- 不明な点(仕様の曖昧さ)はこの時点で質問するか、仮定として明示する

### 2. 現状調査

- 関連する既存コード・テーブル・APIを把握する
- 調査が必要な場合は [system-investigator](../system-investigator/SKILL.md) の手順に従う
- 既存の実装パターン(Supabaseクライアントの使い分け、ディレクトリ構成、バリデーション方法)を確認し、計画をそれに合わせる

### 3. 変更対象の洗い出し

以下の観点で「変更あり/なし」を判定し、ありの場合は具体化する:

| 観点 | 確認内容 |
|---|---|
| DB | 新規テーブル / カラム追加 / RLS / migration の要否 |
| API | Route Handler / Server Actions の新規・変更 |
| UI | 画面 / コンポーネント / 導線の新規・変更 |
| 型 | TypeScript型定義 / zodスキーマ / database.types.ts 再生成 |
| その他 | Edge Functions / cron / Storage / 環境変数 |

### 4. ファイル別変更内容の列挙

- 新規作成するファイルと修正するファイルをパス付きで列挙する
- 各ファイルについて「何をするか」を1行で書く

### 5. Phase 分け

- 依存関係に従って順序付ける。基本順序: **DB → 型 → API/Server Actions → UI → テスト/動作確認**
- 各 Phase は「単独で動作確認できる単位」にする
- Phase 間の依存(Phase 2 は Phase 1 の migration 適用が前提、など)を明記する
- Phase 分けの考え方は [references/planning.md](references/planning.md) を参照

### 6. 注意点・完了条件の整理

- 既存機能への影響、RLS漏れ、認可漏れなどリスクを列挙する
- 「何ができたら完了か」を検証可能な形で書く

### 7. 実装指示文の作成

- Phase ごと(または全体)に、Codex / Claude Code にそのまま貼れる指示文を作る
- 指示文には前提・対象ファイル・期待動作・完了条件を含める
- 書き方は [references/planning.md](references/planning.md) の指示文テンプレートに従う

# Output Template

```md
# 実装計画: <機能名>

## 実装目的
(何を実現するか。完成時にできるようになること)

## 前提
- 既存の関連コード・テーブル・API
- 仮定した仕様(要確認のもの)

## 変更対象
| 領域 | 変更有無 | 内容 |
|---|---|---|
| DB | あり/なし | |
| API | あり/なし | |
| UI | あり/なし | |
| 型定義 | あり/なし | |

## 実装フェーズ
### Phase 1: <名前>
- 内容 / 依存 / 完了条件

### Phase 2: <名前>
...

## ファイル別変更内容
| 種別 | パス | 変更内容 |
|---|---|---|
| 新規 | | |
| 修正 | | |

## 注意点
- 既存機能への影響 / RLS / 認可 / その他リスク

## 完了条件
- [ ] (検証可能な形で列挙)

## Codex / Claude Code 用指示文
(Phase ごとに、そのまま貼れる指示文)
```

実例は [examples/](examples/README.md) を参照。

# 実行モデルティア

推奨ティア: **standard**（手順追従型のため標準クラスのモデルで品質が安定する）。
最上位推論クラスのモデルを占有する必要はない。手順から外れる複雑な判断が
必要になったら、その論点を明示して deep ティアの設計・監査系スキルへ引き渡すこと。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
