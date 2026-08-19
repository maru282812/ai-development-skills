---
name: factory-bootstrap
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
metadata:
  reasoning-tier: standard
  summary: "製造ループ（Loop Engineering）基盤を対象プロジェクトへ薄く設置する担当。stack を検出して docs/VERIFY.md（検証レシピ）・.claude/loop.md（保守ループ既定）を生成し、CLAUDE.md に製造ループ節を追記する。既存ファイルは上書きしない。"
description: >-
  全プロジェクト共通の製造ループ（要件→計画→実装→検証→独立レビュー→Receipt→Human Gate）を、
  対象リポジトリへ「薄いフットプリント」で設置する bootstrap 担当。対象 repo の stack と既存資産
  （package.json scripts / テスト / E2E / CI / CLAUDE.md / AGENTS.md）を検出し、実在するコマンドだけで
  docs/VERIFY.md（そのrepoの検証レシピ）を具体化し、.claude/loop.md（保守ループ既定）を置き、
  CLAUDE.md に製造ループ節を冪等に追記する。未整備ギャップ（E2Eなし・typecheckなし等）は
  レポートで提示して止まる。CI設定・テスト実装・アプリコードの変更はしない。
  トリガー例:
  「ループエンジニアリングを導入して」「製造ループを入れて」「Factory を bootstrap して」
  「このプロジェクトに loop 基盤を設置して」「製造工程を整えて」「VERIFY.md を作って」
  「新規プロジェクトの製造ラインを整備して」。
  実装の自走そのものは phase-runner、実行時検証の実施は verification-loop（本スキルは設置のみ）。
---

# factory-bootstrap（製造ループ基盤の設置）

どのプロジェクトでも同じ「製造ループ」で開発が回るように、対象リポジトリへ基盤を**薄く**設置する。
基盤の本体（スキル・テンプレ）は ai-development-skills が canonical で、各 repo には最小限のファイルだけ置く。

## 標準製造ループ（全プロジェクト共通の型）

```text
DISCOVER / SPEC ─ 何を作るか            → project-discovery / requirements-discovery / feature-spec-writer
      ↓
PLAN ─ Phase分け・受け入れ条件          → implementation-planner
      ↓
┌──────────── 製造ループ（phase-runner が自走）────────────┐
│ MAKER（fresh subagent が Phase N を実装）                  │
│   ↓                                                        │
│ GATES（typecheck / lint / test / build — VERIFY.md 準拠）  │
│   ↓                                                        │
│ RUNTIME VERIFY（ユーザーから見て動くか — verification-loop）│
│   ↓                                                        │
│ CHECKER（maker と別の fresh subagent が独立レビュー）      │
│   ↓ NG(軽微) → MAKER へ戻す / NG(重い) → 停止して報告     │
│   ↓ OK                                                     │
│ RECEIPT（証拠付き製造記録を phase-status.md に残す）       │
└──────────────── 次の Phase へ ────────────────────────────┘
      ↓ 全 Phase done
HUMAN GATE（人間が最終判断 — 下記リスト）
      ↓
MERGE / RELEASE
      ↓
MAINTAIN（/loop + .claude/loop.md — 保守ループ）
```

- **Build は `/goal` / phase-runner 中心**（停止条件 = 受け入れ条件＋全ゲート緑）。
- **Maintain は `/loop` 中心**（.claude/loop.md が既定の巡回内容）。

## 対象 repo に置くもの（薄いフットプリント）

```text
<target>\
├── CLAUDE.md          ← 「製造ループ」節を末尾に追記（無ければ最小新規）
├── .claude\
│   └── loop.md        ← 保守ループの既定（templates/loop.md を具体化）
└── docs\
    └── VERIFY.md      ← このrepoの検証レシピ（templates/VERIFY.md を具体化）
```

phase-status.md は phase-runner が実行時に作る（ここでは置かない）。

## 手順

### 1. 対象 repo の現状を検出する

- 対象 repo の絶対パスを確定する（不明ならこの1点だけ確認して以後止めない）。
- 以下を検出して「既存資産インベントリ」を作る:
  - `package.json` の scripts（typecheck / lint / test / build / e2e / dev の実在コマンド名）
  - テスト（vitest / jest / playwright 等の設定ファイル）
  - CI（`.github/workflows/`）
  - `CLAUDE.md` / `AGENTS.md` / `.claude/` / `phase-status*.md` の有無
  - dev server の起動コマンドとポート（runtime verify に必要）
- **実在しないコマンドを VERIFY.md に書かない。** 無いものはギャップとして最終レポートに載せる。

### 2. docs/VERIFY.md を生成する

`templates/VERIFY.md` を読み、検出結果で具体化して `<target>\docs\VERIFY.md` に書く。

- Gates 節: 実在する scripts だけを実行順で列挙する。
- Runtime Verify 節: dev server 起動コマンド・確認すべき主要画面/フロー（CLAUDE.md や README から把握できる範囲。不明なら `<TODO: 主要フローを記入>` として残す）。
- Human Gate 節: 下記標準リストをそのまま入れ、repo 固有の危険操作があれば追記する。
- 既に `docs/VERIFY.md` がある場合は上書きせず、差分（標準に足りない節）だけ追記提案する。

### 3. .claude/loop.md を設置する

`templates/loop.md` を `<target>\.claude\loop.md` にコピーし、repo 名・CI 有無に合わせて具体化する。
既にあれば上書きしない（差分提案のみ）。

### 4. CLAUDE.md に製造ループ節を追記する

`templates/claude-md-section.md` の内容を CLAUDE.md 末尾に追記する。

- **冪等にする**: 既に `## 製造ループ` 見出しがあれば追記しない（内容が古ければ差分提案）。
- CLAUDE.md が無ければ、この節だけを持つ最小 CLAUDE.md を新規作成する。
- 既存の記述は一切上書き・削除しない。

### 5. 完了レポート

```md
# Factory Bootstrap レポート: <repo名>

## 設置したもの
| ファイル | 状態（新規 / 追記 / 既存のためスキップ） |

## 既存資産インベントリ
| 資産 | 有無 | 備考 |
（gates / テスト / E2E / CI / CLAUDE.md / AGENTS.md / phase-status）

## ギャップ（このrepoの製造ループがまだ欠くもの）
- [ ] 例: typecheck script が無い → package.json に追加を推奨
- [ ] 例: E2E 未整備 → 保守ループでは手動確認扱い

## 次の一手
- 実装指示書があるなら phase-runner で自走（VERIFY.md がゲートとして使われる）
- 検証だけ回すなら verification-loop
```

ギャップの解消（script追加・テスト実装・CI設定）は**このスキルではやらない**。
やるかどうかは人間が決める（レポートで止まる）。

## Human Gate 標準リスト（全プロジェクト共通）

以下は自動ループで完結させず、必ず人間の判断を挟む:

- DB migration の本番適用（適用前に [migration-review](../migration-review/SKILL.md)）
- 認証・認可・RLS の変更
- 課金・決済まわり
- 個人情報の扱いの変更
- 本番環境変数・シークレット
- 外部APIとの契約的な連携変更
- 破壊的操作（データ削除・強制push等）
- 本番デプロイ / リリース

## やらないこと（境界）

- アプリコード・テストコード・CI 設定の実装（設置対象は上記3ファイルのみ）。
- 既存ファイルの上書き・削除（追記と新規のみ。衝突は差分提案で止まる）。
- 実装の自走（それは [phase-runner](../phase-runner/SKILL.md)）・検証の実施（それは [verification-loop](../verification-loop/SKILL.md)）。
- ギャップ（E2E不在等）の勝手な解消。

## 関連

設置後の自走 [phase-runner](../phase-runner/SKILL.md) / 実行時検証 [verification-loop](../verification-loop/SKILL.md) /
新規プロジェクト立ち上げからの一気通貫 [project-kickoff](../project-kickoff/SKILL.md)（§5.5 で本スキルを呼ぶ）/
lint・format の初期整備 [project-quality-tooling](../project-quality-tooling/SKILL.md)。

# 実行モデルティア

推奨ティア: **standard**（検出とテンプレ具体化の手順追従型）。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
