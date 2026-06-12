# examples

implementation-planner の使用例。実際の計画結果は `<機能名>.md` でこのディレクトリに追加する。

## 例1: お知らせ機能の追加

### 入力例

> 管理画面からお知らせを登録して、ユーザーのトップページに表示する機能を追加したい。実装フェーズに分けて、Claude Code に渡す指示文も作って。

### Skill が見る観点

- 既存に `announcements` 相当のテーブル・画面がないか(system-investigator の手順で確認)
- DB変更あり(新規テーブル + RLS)、API変更あり(管理側CRUD)、UI変更あり(管理画面 + トップページ)
- 管理者のみ書き込み可・全ユーザー読み取り可、という権限要件 → RLS設計が Phase 1
- 既存の管理画面のCRUD実装パターン(どの画面を参照実装にするか)

### 出力例(短縮版)

```md
# 実装計画: お知らせ機能

## 実装目的
管理者がお知らせを登録・公開し、ユーザーのトップページに表示できるようにする。

## 変更対象
| 領域 | 変更有無 | 内容 |
|---|---|---|
| DB | あり | announcements テーブル新規 + RLS |
| API | あり | Server Actions(管理側 create/update/delete) |
| UI | あり | /admin/announcements 一覧・編集、トップページ表示 |

## 実装フェーズ
### Phase 1: DB
- migration 作成(announcements: id, title, body, published_at, created_at, updated_at)
- RLS: SELECT は published_at <= now() の行を全員可、書き込みは admin ロールのみ
- 完了条件: supabase db reset が通り、RLSが anon で検証できる

### Phase 2: 管理画面CRUD
### Phase 3: トップページ表示

## Codex / Claude Code 用指示文
(Phase 1 の指示文)
## 目的
お知らせ機能のDB基盤を作る。
## 前提
- Supabase migration は supabase/migrations/ に配置
- RLS の書き方は既存の 20240xx_create_posts.sql を参照
## やること
1. announcements テーブルの migration を作成 ...
## やらないこと
- UI・APIの実装はしない
## 完了条件
- [ ] supabase db reset が成功する
```
