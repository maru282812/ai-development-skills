# コード品質ツール 雛形カタログ（原本）

[[project-quality-tooling]] が生成する設定ファイル・scripts・README の **原本**。
プロジェクトへ複製し、`<...>` のプレースホルダを差し込む。**スタックを越境して適用しない**。

---

## 1. TypeScript / JavaScript 系（Web / SaaS / 管理画面 / Node API）→ Biome

> 対象: Next.js / React / Node.js / TypeScript。Biome は Formatter と Linter を一体提供するため、
> 新規案件では ESLint + Prettier を別途入れない（既存資産がある場合のみ移行検討）。
> Swift / Kotlin プロジェクトには入れない。

### `biome.json`

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "vcs": { "enabled": true, "clientKind": "git", "useIgnoreFile": true },
  "files": { "ignoreUnknown": false },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "javascript": {
    "formatter": { "quoteStyle": "double", "semicolons": "always" }
  },
  "organizeImports": { "enabled": true }
}
```

> バージョン（schema URL の `1.9.4`）は導入時の最新安定版に合わせる。Next.js 案件では生成物
> （`.next/` 等）が `.gitignore` 経由で除外される前提（`useIgnoreFile: true`）。

### `package.json` scripts

```json
{
  "scripts": {
    "format": "biome format --write .",
    "lint": "biome lint .",
    "check": "biome check .",
    "check:fix": "biome check --write ."
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.4"
  }
}
```

導入コマンド:

```bash
npm install --save-dev --save-exact @biomejs/biome
npx biome init   # biome.json が無い場合のみ。既存があれば上書きしない
```

### README 追記（コード品質）

```md
## コード品質（Biome）

このプロジェクトは [Biome](https://biomejs.dev/) で整形（Formatter）と静的解析（Linter）を行う。

- `npm run check` … lint + format の差分チェック（CI 用 / 変更なし）
- `npm run check:fix` … lint + format を自動修正
- `npm run format` … 整形のみ自動修正
- `npm run lint` … 静的解析のみ

> エディタ統合: VS Code は拡張「Biome」を入れ、保存時整形を有効化する。
```

---

## 2. Swift / iOS 系（SwiftUI / UIKit）→ SwiftLint + SwiftFormat

> 対象: iOS / Swift。SwiftLint = 静的解析、SwiftFormat = 整形 の分業。両方入れる。
> Biome / ESLint / Prettier は入れない。

### `.swiftlint.yml`

```yaml
# SwiftLint 設定: <案件名>
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - closure_spacing
  - explicit_init
included:
  - Sources
  - <App ターゲットのソースディレクトリ>
excluded:
  - Carthage
  - Pods
  - .build
  - <生成物 / 外部依存ディレクトリ>
line_length:
  warning: 120
  error: 200
identifier_name:
  min_length: 2
```

### `.swiftformat`

```ini
# SwiftFormat 設定: <案件名>
--swiftversion 5.9
--indent 4
--maxwidth 120
--self remove
--importgrouping testable-bottom
--exclude Pods,.build,Carthage,<生成物ディレクトリ>
```

### 導入手順 / README 追記

```md
## コード品質（SwiftLint + SwiftFormat）

- SwiftLint … 静的解析（規約違反の検出）
- SwiftFormat … コード整形

### 導入（Homebrew または Mint）

```bash
brew install swiftlint swiftformat
# もしくは Mint で固定バージョン管理:
# mint install realm/SwiftLint
# mint install nicklockwood/SwiftFormat
```

### 実行

```bash
swiftformat .        # 整形
swiftlint            # 静的解析（警告/エラー表示）
swiftlint --fix      # 自動修正可能なルールを修正
```

### Xcode Build Phase 連携（任意）

「Run Script Phase」を追加し、ビルド時に自動チェック:

```bash
if which swiftlint >/dev/null; then swiftlint; fi
```
```

> Biome の項目を iOS プロジェクトに入れないこと。

---

## 3. Kotlin / Android 系 → ktlint（候補: detekt / Spotless）

> **区分: 候補（要確定）**。プロジェクト方針（ktlint 単体 / detekt 併用 / Spotless 経由）が
> 未確定なら確定させず、候補として提示してユーザー確定を待つ。SwiftLint/SwiftFormat や Biome は入れない。

### `.editorconfig`（ktlint はこれを規約ソースにする）

```ini
root = true

[*.{kt,kts}]
indent_size = 4
indent_style = space
max_line_length = 120
insert_final_newline = true
ktlint_standard_no-wildcard-imports = enabled
```

### gradle プラグイン（候補A: ktlint-gradle）

```kotlin
// build.gradle.kts（モジュール or ルート）
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "<最新版>"
}
```

実行:

```bash
./gradlew ktlintCheck    # 静的解析
./gradlew ktlintFormat   # 自動整形
```

### 候補の整理（ユーザー確定が必要）

| 候補 | 役割 | 使いどころ |
|---|---|---|
| **ktlint** | 整形 + 基本 lint | 標準。まずこれで十分なことが多い |
| **detekt** | 高度な静的解析（複雑度・コードスメル） | 品質基準を厳しくしたい場合に ktlint と併用 |
| **Spotless** | 整形の統合ラッパ（ktlint を内包可） | 複数言語/フォーマッタを一括管理したい場合 |

### README 追記

```md
## コード品質（Kotlin / ktlint）※方針確定待ち

- `./gradlew ktlintCheck` … 静的解析
- `./gradlew ktlintFormat` … 自動整形

> detekt（高度な静的解析）や Spotless（統合ラッパ）の併用は方針に応じて検討。
```

---

## 4. 未対応 / 不明 / 混在スタック → 確認事項（設定は生成しない）

```md
## 確認事項: コード品質ツール未確定

検出したスタックが未対応または特定できないため、設定を自動生成していません。

- 主要言語/フレームワークは？（例: Go / Rust / Flutter / Python / 複数混在）
- モノレポの場合、適用範囲は？
- 既存の lint/format 設定はありますか？（ある場合は上書きしません）

> 対応スタックなら、確定後の再実行で設定ファイル・scripts・README を生成します。
> 新スタックは SKILL.md の選定表に行を追加して拡張できます（例: Go → gofmt + golangci-lint、
> Python → Ruff、Flutter/Dart → dart format + dart analyze）。
```

---

## 越境禁止マトリクス（再掲）

| プロジェクト | 入れてよい | 入れてはいけない |
|---|---|---|
| Next.js / React / Node (TS/JS) | Biome | SwiftLint / SwiftFormat / ktlint |
| iOS / Swift | SwiftLint + SwiftFormat | Biome / ESLint / Prettier |
| Android / Kotlin | ktlint（候補: detekt / Spotless） | Biome / SwiftLint / SwiftFormat |
