# Next.js 調査リファレンス

system-investigator スキルの Step 2(関連ファイル検索)・Step 6(画面/コンポーネント確認)で参照する。

## 目次

1. [ルーティング規則(App Router / Pages Router)](#1-ルーティング規則app-router--pages-router)
2. [Route Handler と Server Actions の探し方](#2-route-handler-と-server-actions-の探し方)
3. [Supabaseクライアントの使い分けと配置パターン](#3-supabaseクライアントの使い分けと配置パターン)
4. [状態管理の追跡方法](#4-状態管理の追跡方法)

---

## 1. ルーティング規則(App Router / Pages Router)

### どちらのRouterか見分ける

| 確認ポイント | App Router | Pages Router |
|---|---|---|
| ディレクトリ | `app/` (または `src/app/`) が存在 | `pages/` (または `src/pages/`) が存在 |
| 画面ファイル名 | `page.tsx` / `page.jsx` | 任意のファイル名(例: `index.tsx`, `users.tsx`) |
| レイアウト | `layout.tsx` | `_app.tsx`, `_document.tsx` |
| APIルート | `app/api/**/route.ts` | `pages/api/**/*.ts` |

両方存在する場合(移行中プロジェクト)は両方を調査対象とする。

### App Router のルーティング規則

- ディレクトリ構造がそのままURLパスになる: `app/users/[id]/page.tsx` → `/users/:id`
- 特殊ファイル: `page.tsx`(画面), `layout.tsx`(レイアウト), `loading.tsx`, `error.tsx`, `route.ts`(APIエンドポイント)
- `(group)` のような括弧付きディレクトリはURLに含まれない(ルートグループ)
- `[id]` は動的セグメント、`[...slug]` はキャッチオール
- `@modal` のような `@` 付きはParallel Routes

検索例:
```bash
# 画面ファイルの一覧
rg --files -g 'app/**/page.tsx'
# 特定キーワードを含む画面を探す
rg 'キーワード' app/ --glob '**/page.tsx' -l
```

### Pages Router のルーティング規則

- ファイルパスがそのままURL: `pages/users/[id].tsx` → `/users/:id`
- `pages/api/` 配下はAPIエンドポイント
- `getServerSideProps` / `getStaticProps` 内のデータ取得処理も調査対象

## 2. Route Handler と Server Actions の探し方

### Route Handler (App Router)

- 場所: `app/api/**/route.ts` (api以外の配下にも置ける)
- `export async function GET/POST/PUT/PATCH/DELETE` がエンドポイント定義

```bash
# Route Handler の一覧
rg --files -g '**/route.ts' -g '**/route.tsx'
# 特定テーブルを操作しているRoute Handlerを探す
rg "from\('table_name'\)" app/api/
```

### API Routes (Pages Router)

- 場所: `pages/api/**/*.ts`
- `export default function handler(req, res)` 形式

### Server Actions

- `'use server'` ディレクティブを持つ関数。配置場所は自由(`app/actions/`, `lib/actions/` などプロジェクトによる)
- ファイル先頭の `'use server'`(ファイル全体がServer Action)と、関数内先頭の `'use server'`(その関数のみ)の2パターンがある

```bash
# Server Actions を全て洗い出す
rg "'use server'" --glob '*.ts' --glob '*.tsx' -l
# 呼び出し元を探す(form action やイベントハンドラから)
rg 'action=\{' --glob '*.tsx'
rg 'import.*from.*actions' --glob '*.tsx'
```

### 型定義の確認

- リクエスト/レスポンスの型は `types/` ディレクトリ、または各route/actionファイル内に定義されることが多い
- zod等のバリデーションスキーマ(`z.object(...)`)も型情報源として確認する

```bash
rg 'z\.object' lib/ types/ app/
```

## 3. Supabaseクライアントの使い分けと配置パターン

Next.jsでは実行コンテキストごとに異なるSupabaseクライアントを使う。
それぞれの生成箇所を特定し、どちら経由のアクセスかを区別すること。

| 用途 | 典型的なファイル | 使用ライブラリ/関数 |
|---|---|---|
| Client Component用 | `lib/supabase/client.ts`, `utils/supabase/client.ts` | `createBrowserClient` (`@supabase/ssr`) / `createClient` (`@supabase/supabase-js`) |
| Server Component / Route Handler / Server Action用 | `lib/supabase/server.ts`, `utils/supabase/server.ts` | `createServerClient` (`@supabase/ssr`) + `cookies()` |
| middleware用 | `middleware.ts`, `lib/supabase/middleware.ts` | `createServerClient` + リクエスト/レスポンスのcookie操作 |
| 管理者権限(RLSバイパス) | `lib/supabase/admin.ts` 等 | `service_role` キーで `createClient` |

調査手順:
```bash
# クライアント生成箇所を特定
rg 'createBrowserClient|createServerClient|createClient' --glob '*.ts' -l
# service_role(RLSバイパス)の使用箇所 — 影響範囲分析で特に重要
rg 'service_role|SERVICE_ROLE' --glob '*.ts'
# middleware の認証処理
rg 'supabase' middleware.ts
```

注意点:
- 旧構成では `@supabase/auth-helpers-nextjs` (`createClientComponentClient` / `createServerComponentClient` / `createRouteHandlerClient`)が使われている場合がある
- Client側クライアント経由のクエリは**RLSの影響を受ける**、`service_role` 経由は**受けない** — Step 3のRLS調査と突き合わせること

## 4. 状態管理の追跡方法

まずプロジェクトで何が使われているか `package.json` の依存関係で確認する
(`zustand`, `@reduxjs/toolkit`, `jotai`, `recoil`, `swr`, `@tanstack/react-query` など)。

### React標準(useState / useContext)

```bash
# 対象データを扱うstateを探す
rg 'useState.*キーワード' --glob '*.tsx'
# Context経由の場合はProvider定義から追う
rg 'createContext|useContext' --glob '*.tsx' -l
```

### Zustand

- ストア定義: `rg 'create\(' --glob '*store*'` または `rg 'zustand'  -l`
- 使用箇所: ストアのhook名(例: `useUserStore`)で検索

### Redux

- slice定義: `rg 'createSlice' -l`
- 使用箇所: `useSelector` / `useDispatch` とaction名で検索

### サーバーステート(SWR / TanStack Query)

- `useSWR('key', ...)` / `useQuery({ queryKey: [...] })` のキー文字列で検索すると、同一データを参照するコンポーネントを横断的に特定できる
- mutation(`useMutation`, `mutate`)はデータ更新箇所なのでCRUD整理に含める

### Propsの追跡

- 対象データを表示するコンポーネントを特定したら、Propsの型定義 → 親コンポーネントでの使用箇所、と上流へ遡る
- `rg '<ComponentName' --glob '*.tsx'` で使用箇所(親)を特定する
