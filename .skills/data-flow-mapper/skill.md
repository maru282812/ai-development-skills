---
name: data-flow-mapper
description: >-
  Next.js + Supabase 構成で、特定のデータ(画面の表示値・テーブル・カラム)が
  どこから来てどこへ保存されるか、流れを図解するスキル。トリガー例:
  「このデータどこから来てる?」「この値どこに保存される?」
  「この画面の値は何テーブル?」「CRUD図にして」「どこで更新してる?」
  「データの流れを整理して」「この項目の出どころは?」。
  特定データの読み書き経路の追跡・可視化が主目的の依頼ではこのスキルを使用する。
  改修箇所の特定や影響範囲の調査が主目的なら system-investigator、
  不具合の原因特定なら bug-investigator を使う。
---

# Purpose

特定のデータについて「画面 ⇄ コンポーネント ⇄ API/Server Action ⇄ Supabase テーブル」の流れを端から端まで追跡し、CRUD マトリクスとフロー図で可視化する。

system-investigator が「改修のための影響範囲」を出すのに対し、data-flow-mapper は「データの経路そのもの」を成果物にする。業務システムの仕様理解・引き継ぎ・ドキュメント化に使う。

# When To Use

- 画面に表示されている値の出どころ(テーブル・カラム)を知りたい
- 入力した値がどのテーブルにどう保存されるか知りたい
- あるテーブルがどの画面・APIから読み書きされているか一覧したい
- 機能のデータフローをドキュメント化したい

改修箇所・影響範囲が知りたいなら [system-investigator](../system-investigator/skill.md)、
データが「来ない/おかしい」原因調査なら [bug-investigator](../bug-investigator/skill.md) を使う。

# Procedure

検索手順の詳細は system-investigator の
[references/nextjs.md](../system-investigator/references/nextjs.md) /
[references/supabase.md](../system-investigator/references/supabase.md) を流用する。

### 1. 起点の特定

ユーザーの質問の起点を確定する:

- **画面起点**(「この画面の値はどこから?」)→ 対象ページのパスとコンポーネントを特定
- **テーブル起点**(「このテーブル誰が書いてる?」)→ migration からテーブル・カラム定義を確認
- **項目起点**(「この項目どこ保存?」)→ 表示ラベルから対応する state / props / カラム名を特定

### 2. 読み取り経路の追跡(画面 ← DB)

表示値から逆向きに辿る:

1. 値を描画している JSX → その値の props / state の出どころ
2. データ取得箇所: Server Component の直接 fetch / Route Handler / Server Action / クライアントの `supabase.from()` / SWR・React Query の hook
3. クエリの対象テーブル・カラム・JOIN・フィルタ条件
4. 途中の加工(map / 集計 / フォーマット)があれば記録する

### 3. 書き込み経路の追跡(画面 → DB)

入力から順向きに辿る:

1. 入力フォーム → submit ハンドラ / Server Action
2. バリデーション(zod 等)の有無と変換
3. `insert / update / delete / upsert / rpc` の対象テーブル・カラム
4. 1操作で複数テーブルに書く場合はすべて列挙する(トランザクションの有無も)

### 4. DB 側の副作用確認

画面からは見えない経路を必ず確認する:

- Database Triggers / Functions(insert をフックして別テーブルへ書く等)
- `updated_at` 等の自動更新
- Edge Functions / Database Webhooks / pg_cron
- 外部サービスとの同期(Webhook 送信、Stripe 等)

### 5. CRUD マトリクス作成

対象データに関わる全テーブル × 全操作箇所を表にする。

### 6. フロー図作成

Mermaid で読み書きの流れを図示する。読み(実線)と書き(太線 or 別色)を区別し、Client / Server / DB のレイヤーを subgraph で分ける。

# Output Template

```md
# データフロー: <対象>

## 概要
(対象データと追跡範囲のサマリ。2〜3文)

## フロー図
\```mermaid
flowchart LR
  subgraph Client
    UI[画面/コンポーネント]
  end
  subgraph Server
    SA[Server Action / API]
  end
  subgraph Supabase
    T[(テーブル)]
    TR[Trigger/Function]
  end
  UI -->|入力| SA -->|insert| T --> TR
  T -->|select| SA2[取得経路] --> UI
\```

## 読み取り経路
| 画面/箇所 | 取得方法 | テーブル.カラム | 加工 | ファイル:行 |
|---|---|---|---|---|

## 書き込み経路
| 操作契機 | 経路 | テーブル.カラム | バリデーション | ファイル:行 |
|---|---|---|---|---|

## DB側の副作用
| 種別(Trigger/Function/Webhook/cron) | 契機 | 内容 |
|---|---|---|

## CRUDマトリクス
| テーブル | C | R | U | D |
|---|---|---|---|---|
| (テーブル名) | (操作箇所) | | | |

## 注意点
- (推測箇所・未確認の経路)
```

実例は [examples/](examples/README.md) を参照。
