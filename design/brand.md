# ブランドの書式（brand.json）

ブランド層 = 店・会社・自社サービスの色と書体を、**サイト・SNS・資料・アプリから同じ1ファイルで引く**ための書式。
棚卸し §4 の4 で「mood.json 形式を流用」と決めたもの（2026-11-02）。

## 1. 置き場

| ブランド | 置き場 |
|---|---|
| 自社（YOTTO と自社サービス） | このハブの `design/brands/<id>/brand.json` |
| 顧客（店・会社） | その案件のリポジトリ。website-sales-ai なら `sites/<slug>/brand.json` |

正本が別にある場合（例: YOTTO は claude.ai artifact「YOTTO Design System」）は `canonical` に書き、**値を変えるときは正本 → brand.json の順に写す**。brand.json を正本より先に直さない。

## 2. 形

mood.json（website-sales-ai `lib/moods/schema.ts`）と**同じキーを同じ意味で持つ**。だから brand.json は website-sales-ai で「雰囲気の型」としてそのまま読める（ブランド固有のキーは未知キーとして警告され、捨てられるだけ）。

| キー | 必須 | 中身 |
|---|---|---|
| `id` `label` `summary` `fits` | ○ | mood と同じ。`id` は英小文字とハイフン。`fits` はこのブランドを何に使うか（mood の「向く業種」の欄） |
| `color` | ○ | mood と同じ8役（surface / surfaceBand / ink / inkMuted / brand / accent / onAccent / line）。コントラスト基準も同じ（ink・inkMuted・onAccent は 4.5 以上） |
| `type` `shape` `motion` `photo` | ○ | mood と同じ。正本に定めが無い項目は無理に埋めず、`source` に「定めなし→既定値」と書く |
| `source` `status` | ○ | mood と同じ（status は active / draft） |
| `kind` | ○ | `"brand"`（mood と見分ける） |
| `owner` | ○ | 誰のブランドか（社名・店名） |
| `canonical` | 任意 | 正本の場所（URL・ファイル）。無ければこのファイルが正本 |
| `extendsMood` | 任意 | 下敷きにした雰囲気の型の id（顧客ブランドを MOODS から起こしたとき） |
| `colorExtra` | 任意 | 8役に入らない色（例: onBrand・accentText・ok）。キーは camelCase、値は #rrggbb |
| `radiusExtra` | 任意 | `shape.radius` 以外の角丸（px）。例: `{ "md": 14, "pill": 999 }` |
| `logo` | 任意 | `{ "files": {...}, "minSizePx": n, "clearSpace": "文" }`。ファイルはこの brand.json からの相対パス |
| `voice` | 任意 | `{ "tone": "文", "do": [...], "dont": [...] }`。言葉づかい。**推測で埋めない** |
| `rules` | 任意 | 媒体をまたぐ運用ルールの文の配列（例: 「accent の CTA は1画面に1か所」） |
| `media` | ○ | 媒体ごとにブランドをどこまで使うか。`app` `site` `sns` `slides` の4つ。各 `{ "use": "full" \| "accent" \| "none" \| "undecided", "note": "文" }` |

`media.use` の意味:
- `full` … 色・書体・形をすべて使う
- `accent` … 面は中立のまま、アクセント色とロゴだけ使う（アプリ画面の既定。design/app.md §2）
- `none` … 使わない（その媒体の基準や案件の値に従う）
- `undecided` … まだ決めていない。使う前に人に確認する

## 3. 検査と書き出し

```
node C:/work/ai-development-skills/design/scripts/check-brand.mjs <brand.json>          # 検査（不合格なら終了コード 1）
node C:/work/ai-development-skills/design/scripts/check-brand.mjs <brand.json> --css    # :root の CSS 変数を標準出力へ
```

CSS 変数名は `--b-` ＋ キーのケバブケース（`--b-surface-band`、`--b-accent-text`、`--b-radius-md`、`--b-font-heading`）。
SNS 画像・資料・アプリへ持ち込むときは、この出力をその案件のトークンファイルに**写して**使う（プロジェクト内のデザインシステムが最優先なのは変わらない）。

## 4. やらないこと

- 媒体の基準（余白・文字の大きさ・密度）を brand.json に書かない。それは `design/` の媒体ファイルの仕事。
- サイト設計書（website-sales-ai の `design-md-*.md`）を置き換えない。設計書は「何を作るか」、brand.json は「誰の色と書体か」。
- 未確認の値（ロゴの最小サイズ、言葉づかい）を推測で埋めない。
