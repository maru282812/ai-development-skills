---
name: project-quality-tooling
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
description: >-
  新規案件の初期化時に「プロジェクト種別に応じて、どのコード整形・静的解析ツールを導入すべきか」を判定し、
  設定ファイル・scripts・README まで一貫して生成するセットアップ・スキル。
  スタック検出（Web/SaaS/管理画面/API・iOS・Android・その他）→ ツール選定 → 雛形生成 を行う。
  TypeScript/JavaScript 系（Next.js/React/Node API）→ Biome、
  Swift/iOS 系（SwiftUI/UIKit）→ SwiftLint + SwiftFormat、
  Kotlin/Android 系 → ktlint（候補: detekt / Spotless）を選定する。
  Biome を Swift へ、SwiftLint/SwiftFormat を Next.js へ入れない（スタック越境を禁止）。
  対象外・未対応スタックは無理に導入せず「確認事項」として提示する。
  生成物は biome.json / .swiftlint.yml / .swiftformat / .editorconfig 等の設定ファイル、
  package.json scripts や gradle 設定、README/運用メモ、作業ログ。トリガー例:
  「新規案件にLinter/Formatterを入れたい」「Biome入れて」「iOSのコード整形ツールを設定して」
  「この案件にどの静的解析ツールが要るか判定して」「初期テンプレートにlint/format設定を入れて」
  「Android Kotlinの整形ツールを整理して」「コード品質ツールを初期セットアップして」。
  要件・スコープの発見はしない（それは [[scope-discovery]] / [[requirements-discovery]]）。
  非機能要件としての保守性方針は [[nfr-discovery]]、実装手順分解は [[implementation-planner]] が担当。
  本スキルは「初期化時のツール選定と雛形生成」に特化する。
---

# Purpose

このスキルは **新規案件の初期化時に、コード整形（Formatter）と静的解析（Linter）ツールを「スタックに合わせて」選定し、設定ファイル・scripts・README まで一貫生成する** ためのもの。

目的は「ツールを入れること」ではなく、**案件ごとに毎回ゼロから lint/format 環境を考え直す手間と、誤ったツールを入れる事故（例: Swift に Biome）を無くすこと**。今後 Web / iOS / Android / API など複数案件で使い回せるよう、スタック非依存の判定ロジックと、スタック別の再利用テンプレートを持つ。

役割の境界：

- [[scope-discovery]] / [[requirements-discovery]] … 「何を作るか / どう作るか」を発見する
- [[nfr-discovery]] … 非機能要件として保守性・拡張性の **方針** を決める（具体ツールは決めない）
- [[implementation-planner]] … 実装手順を分解する
- **project-quality-tooling（本スキル）** … 実装着手時に「**どの整形・静的解析ツールを・どの設定で・どう実行するか**」を確定し、設定ファイル/scripts/README を生成する

# 基本方針

- **スタックを越境しない**。JS/TS には Biome、Swift には SwiftLint + SwiftFormat、Kotlin には ktlint 系。スタックに合わないツールを入れない。
  - Biome を Swift / Kotlin プロジェクトに入れない（Biome は主に JS/TS 向け）。
  - SwiftLint / SwiftFormat を Next.js / Node プロジェクトに入れない（不要な依存と初期設定の複雑化を避ける）。
- **特定スタックに過剰固定しない**。判定ロジックはスタック非依存に保ち、新スタックは選定表に行を足すだけで拡張できるようにする。
- **不明点は推測で確定しない**。スタックが特定できない・複数混在・モノレポなどは「確認事項」として提示し、勝手に導入しない。
- **確定とそうでないものを分ける**。確定スタックは導入方針＋雛形を出力、候補レベル（例: Android の ktlint vs detekt vs Spotless）は候補として列挙し、ユーザー確定を待つ。
- **一貫生成**。可能な限り「設定ファイル ＋ 実行 scripts ＋ README/運用メモ」をセットで出す。片方だけ出さない。
- **既存設定を尊重**。既存の biome.json / .swiftlint.yml 等がある場合は上書きせず、差分提案にとどめる。

# 入力

- 案件のスタック情報（言語・フレームワーク）。明示が無ければ下記「スタック検出」で推定する。
- 既存リポジトリがある場合: ルートのマニフェスト（`package.json` / `*.xcodeproj` / `Package.swift` / `build.gradle(.kts)` / `settings.gradle` 等）。
- あれば [[scope-discovery]] の `scope/` 成果物（利用環境: Web/LINE/アプリ）、[[nfr-discovery]] の `nfr/` 成果物（保守性方針）。

> 入力が無い・スタックが特定できない場合は捏造せず、「確認事項」として未確定のまま提示する。

# 出力

- **選定結果**: 採用ツール・設定ファイル名・実行コマンド・確定/候補/確認事項の区分。
- **設定ファイル**: スタックに応じた雛形（[references/tool-templates.md](references/tool-templates.md) を原本に複製・差し込み）。
- **実行 scripts**: `package.json` の scripts、または gradle タスク等。
- **README / 運用メモ**: 導入手順・実行方法・CI への組み込み案。
- **作業ログ**: 調査 / ギャップ分析 / 改善案 / 実装可否とリスク。

# スタック検出（Stack Detection）

明示が無ければ、以下のシグナルから推定する。**断定できないものは確認事項に回す**。

| シグナル | 推定スタック |
|---|---|
| `package.json` に `next` / `react` | Web / SaaS / 管理画面（TS/JS） |
| `package.json` に `express` / `fastify` / `nest` 等のみ（UIなし） | Node API（TS/JS） |
| `tsconfig.json` あり / `.ts` `.tsx` 中心 | TypeScript 系（→ Biome） |
| `*.xcodeproj` / `*.xcworkspace` / `Package.swift` / `.swift` | iOS / Swift |
| `build.gradle(.kts)` / `settings.gradle` / `.kt` | Android / Kotlin |
| 複数スタック混在 / モノレポ / シグナルなし | **確認事項**（勝手に決めない） |

# ツール選定ルール（Tool Selection Rules）

| 案件種別 | 主な技術 | 整形・静的解析ツール | 設定ファイル | 実行コマンド | 区分 |
|---|---|---|---|---|---|
| Web / SaaS / 管理画面 | Next.js / React / TypeScript | **Biome**（format + lint を一体提供） | `biome.json` | `npm run check` / `npm run format` / `npm run lint` | 確定 |
| Node API | TypeScript / Node.js | **Biome** | `biome.json` | 同上 | 確定 |
| iOS | Swift / SwiftUI / UIKit | **SwiftLint + SwiftFormat** | `.swiftlint.yml` / `.swiftformat` | `swiftlint` / `swiftformat .` | 確定 |
| Android | Kotlin | **ktlint**（候補: detekt / Spotless） | `.editorconfig` / `build.gradle(.kts)` | `./gradlew ktlintCheck` / `ktlintFormat` | 候補（要確定） |
| その他 / 不明 / 混在 | 不明 | **未導入** | なし | なし | 確認事項 |

補足:

- **Biome は Formatter と Linter を一体提供**するため、TS/JS 案件で ESLint + Prettier を別々に入れる必要は基本的にない（既存資産がある場合のみ移行を検討）。
- **Swift は分業**。SwiftLint = 静的解析、SwiftFormat = 整形。両方入れる。
- **Android の ktlint は「候補」扱い**。プロジェクト方針（detekt 併用、Spotless 経由かなど）が未確定なら確定させず、候補として提示してユーザー確定を待つ。
- **越境禁止**: Swift/Kotlin に Biome、Next.js/Node に SwiftLint/SwiftFormat を入れない。

# 生成ファイル（Generated Files）

雛形の本文は [references/tool-templates.md](references/tool-templates.md) を原本とする。

- TS/JS（Biome）: `biome.json` ＋ `package.json` scripts ＋ README 追記
- iOS（Swift）: `.swiftlint.yml` ＋ `.swiftformat` ＋ README 追記（Mint/Homebrew 導入手順、Build Phase 連携メモ）
- Android（Kotlin）: `.editorconfig` ＋ gradle プラグイン設定 ＋ README 追記（候補注記つき）
- 未対応スタック: 設定は生成せず、「確認事項テンプレート」を出力

# ワークフロー

```text
1. 入力/リポジトリからスタックを検出（スタック検出表）
2. 断定できない要素を洗い出す（混在・モノレポ・シグナル不足 → 確認事項へ）
3. スタックごとに選定ルール表を適用（確定 / 候補 / 確認事項に区分）
4. 既存の設定ファイルの有無を確認（あれば上書きせず差分提案）
5. 確定スタックの設定ファイル・scripts・README を生成（references/tool-templates.md を複製・差し込み）
6. 候補レベルはユーザーに1問で確定を促す（複数論点を一度に投げない）
7. 確認事項を明示（未対応・混在は無理に導入しない）
8. 作業ログを残す（調査 / ギャップ分析 / 改善案 / 実装可否とリスク）
```

判断が要る箇所（候補の確定、モノレポでの適用範囲など）は 1テーマ1問で確認する（[[discovery-planner]] の停止ゲートに準拠）。

# 禁止事項

- スタックに合わないツールを入れる（Biome を Swift/Kotlin に、SwiftLint/SwiftFormat を Next.js/Node に）。
- スタックが特定できないのに推測で導入を確定する。
- 候補レベル（Android の ktlint 系など）を勝手に確定する。
- 既存の設定ファイルを確認せず上書きする。
- 設定ファイルだけ / scripts だけ、と片側だけ生成して一貫性を欠く。
- 要件・スコープの発見に踏み込む（[[scope-discovery]] / [[requirements-discovery]] の責務）。

# 完了条件（Completion Criteria）

- 案件種別からスタックを検出し、導入すべき整形・静的解析ツールを判定できている。
- TS/Next.js 案件で **Biome 導入方針**（設定 + scripts + README）が出力されている。
- iOS/Swift 案件で **SwiftLint + SwiftFormat 導入方針** が出力されている。
- Android/Kotlin 案件で ktlint を **候補として**（必要なら detekt/Spotless も）整理して提示している。
- 対象外・未対応・混在スタックは、無理に導入せず **確認事項** として提示している。
- 確定スタックでは設定ファイル・scripts・README が **一貫生成** されている。
- 作業ログに「調査」「ギャップ分析」「改善案」「実装可否とリスク」が残っている。

# 差し戻し条件（Rejection Criteria）

以下のいずれかなら、生成を止めて確認・差し戻す。

- スタックが特定できない / 複数混在 / モノレポで適用範囲が未確定。
- 既存の lint/format 設定があり、上書き可否がユーザー未確認。
- 候補レベルのツール（Android 系など）が未確定のまま。
- スタックに合わないツールを入れる指示になっている（越境）。
- 設定ファイル・scripts・README のいずれかが欠け、一貫性が崩れている。

# Handoff to Implementation

生成した設定ファイル・scripts・README は、[[implementation-planner]] の実装計画 / Codex・Claude Code への指示文に組み込む。CI 連携（PR で `check` を走らせる等）の具体手順は実装フェーズへ渡す。本スキルは「初期化時の選定と雛形生成」までを担当する。

# Output Template

### 選定結果サマリ

```md
# コード品質ツール選定: <案件名>

## 検出スタック
- <検出結果（例: Web/SaaS = Next.js + TypeScript）>
- 根拠シグナル: <package.json に next / tsconfig.json あり 等>

## 選定結果
| スタック | 採用ツール | 設定ファイル | 実行コマンド | 区分 |
|---|---|---|---|---|
| Web/SaaS | Biome | biome.json | npm run check / format | 確定 |

## 確認事項（未確定 / 要ユーザー判断）
- [ ] <例: モノレポの場合、Biome をルート一括か workspace 別か>
- [ ] <例: Android は ktlint 単体か detekt 併用か>

## 生成ファイル
- [ ] biome.json
- [ ] package.json scripts（check / format / lint）
- [ ] README の「コード品質」節
```

### 確認事項テンプレート（未対応 / 混在スタック）

```md
## 確認事項: コード品質ツール未確定

検出したスタックが未対応または特定できないため、ツールを自動導入していません。
以下を確認してください。

- 主要言語/フレームワークは何ですか？（例: Go / Rust / Flutter / 複数混在）
- モノレポの場合、どの範囲に適用しますか？
- 既存の lint/format 設定はありますか？（ある場合は上書きしません）

> 確定後に再実行すると、対応スタックなら設定ファイル・scripts・README を生成します。
> 未対応スタックは選定表への追加（行追加）で拡張できます。
```

# セルフチェック

- スタックに合わないツールを入れていないか（越境していないか）。
- スタック特定不能・混在を「確認事項」に回し、推測で確定していないか。
- 候補レベル（Android 系）を勝手に確定していないか。
- 既存設定の有無を確認し、上書きしていないか。
- 確定スタックで設定ファイル・scripts・README を一貫生成したか。
- 作業ログに 調査 / ギャップ分析 / 改善案 / 実装可否とリスク を残したか。
- 要件・スコープ発見に踏み込んでいないか（[[scope-discovery]] / [[requirements-discovery]] へ）。

---

関連スキル: 入力元 [[scope-discovery]]（利用環境）/ [[nfr-discovery]]（保守性方針）/ 引き渡し先 [[implementation-planner]]（実装計画・CI連携）/ 進行補助 [[discovery-planner]]（次の1問）/ オーケストレーター [[project-discovery]]。雛形本文は [references/tool-templates.md](references/tool-templates.md)。
