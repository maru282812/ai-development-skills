# 隔離と一括削除（isolation-and-removal）

このスキルの2本柱の片方。操作手順は**開発・運営のための手順**であり、製品として販売・引き渡すときは
不要になる。だから最初から1つのフォルダに閉じ込め、**跡形なく剥がせる**ように作る。

## 原則

- 操作手順に関わる**全ファイルは `features/ops-guide/` の中だけ**に置く。
- サイト本体に加える変更は**マウント1箇所だけ**（1 import ＋ マーカーで囲んだ1ブロック）。
- **共有ファイル（globals.css / 共通レイアウト / 共通util 等）を編集して残骸を残さない。**
  スタイルは CSS Module 等でフォルダ内に閉じる。globals.css に `.howto` を足すと、
  フォルダを消しても CSS が残り「跡形なく」を満たせない。
- 削除は2手で終わる: ①フォルダを消す ②マーカーブロックを消す。

## ディレクトリ構成

```
features/ops-guide/
├── OpsGuidePanel.tsx        # パネル本体（表示・Copyボタン・状態）
├── steps.ts                 # ステップデータ（改修時に直すのはここ）
├── substitute.ts            # {slug}/{root} 置換ヘルパ（置換ルールの集約点）
├── ops-guide.module.css     # スコープドスタイル（globals.css は触らない）
└── README.md                # 削除手順＋マウントした正確なパスを記録
```

必要なら `uninstall.ps1` も同梱してよい（後述）。

## マウント（サイト本体に触る唯一の箇所）

運営者が最初に触る画面の先頭に、**マーカーで囲って**1ブロックだけ差し込む:

```tsx
import { OpsGuidePanel } from "@/features/ops-guide/OpsGuidePanel";

// …画面コンポーネント内、先頭付近:
{/* ops-guide:start —（販売時は features/ops-guide/ とこのブロックを削除）*/}
<OpsGuidePanel slug={selectedSlug} />
{/* ops-guide:end */}
```

- import 文とこの JSX ブロックが、サイト本体に残る唯一の痕跡。
- `selectedSlug` は「選択中プロジェクトの slug」の出所から渡す（props / 選択状態 / URL param 等）。
- マーカー文字列 `ops-guide:start` / `ops-guide:end` は grep で機械的に見つけられるよう固定する。

## 削除（販売・引き渡し時）

2手順:

1. `features/ops-guide/` を**フォルダごと削除**する。
2. マウント先ファイルから `ops-guide:start` 〜 `ops-guide:end` のブロックと、対応する
   `import { OpsGuidePanel } …` の1行を削除する。

検証: `grep -r "ops-guide\|OpsGuidePanel" .` が**0件**になれば残骸ゼロ。0件でなければ、
共有ファイルに書き込んだ残骸があるということ（原則違反なので作り直す）。

## README に固定すること

`features/ops-guide/README.md` に、将来の自分（会話文脈なし）でも消せるよう次を明記する:

```md
# ops-guide（運営者向け操作手順パネル / 販売時は削除）

これは運営・開発用の操作手順です。製品として販売・引き渡す際は削除してください。

## 削除手順
1. このフォルダ features/ops-guide/ を丸ごと削除
2. マウント先 <正確なファイルパス> から `ops-guide:start`〜`ops-guide:end` のブロックと
   `import { OpsGuidePanel } ...` の行を削除
3. 検証: `grep -r "ops-guide\|OpsGuidePanel" .` が 0 件

マウント先: <ここに実際のファイルパスを書く。例: app/(dashboard)/workspace/page.tsx>
```

`<正確なファイルパス>` は必ず実際にマウントした場所を書く（推測で空欄にしない）。

## 任意: uninstall.ps1

手作業を減らしたいなら、フォルダ削除とマーカーブロック除去を自動化するスクリプトを同梱してよい。
マウント先パスは README と同じ値を使う。

```powershell
# features/ops-guide/uninstall.ps1
param([string]$Mount = "app/(dashboard)/workspace/page.tsx")  # 実際のマウント先に合わせる
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot            # features/ops-guide
$repo = Split-Path -Parent (Split-Path -Parent $root)
# 1) マーカーブロック + import を除去
$path = Join-Path $repo $Mount
$src  = Get-Content $path -Raw
$src  = [regex]::Replace($src, "(?s)\s*\{/\* ops-guide:start.*?ops-guide:end \*/\}", "")
$src  = ($src -split "`n" | Where-Object { $_ -notmatch "features/ops-guide/OpsGuidePanel" }) -join "`n"
Set-Content -Path $path -Value $src -Encoding utf8
# 2) フォルダごと削除
Remove-Item -Recurse -Force $root
Write-Host "ops-guide removed. Verify with: grep -r ops-guide ."
```

スクリプトはあくまで補助。**フォルダ削除＋マーカー除去**という2手順が本質で、README にそれが
書いてあることが最優先。
