# Next.js + Supabase 既知エラーパターン集

エラーメッセージ・症状から原因候補を即座に引くためのカタログ。
ここに該当しても**必ず手順4(切り分け)で裏取りする**こと。

## 1. Supabase PostgREST エラー(PGRST系)

| コード | 意味 | よくある原因 |
|---|---|---|
| PGRST205 | テーブルが schema cache に見つからない | migration 未適用 / テーブル名のtypo / `public` 以外のスキーマ / migration 適用後に API がキャッシュ更新前 |
| PGRST116 | `.single()` で行が0件 or 複数件 | データ不在なのに `.single()` を使用 / 一意のはずの条件が複数ヒット。`.maybeSingle()` への変更を検討 |
| PGRST301 | JWT 不正・期限切れ | セッション切れ / 環境変数の anon key が別プロジェクトのもの |
| PGRST204 | カラムが見つからない | migration 未適用 / カラム名 camelCase と snake_case の不一致 |
| 42501 | permission denied | RLS有効でポリシー不足 / `GRANT` 不足(特に新規テーブル) |

**PGRST205/204 が出たら最初に確認**: `supabase/migrations/` の最新ファイルが対象環境に適用されているか(`supabase migration list` / Studio の Table Editor で実物確認)。

## 2. RLS による silent failure(エラーなし・データなし)

**症状**: エラーは出ないが select 結果が空配列 / insert が反映されない。

確認順:
1. Supabase Studio(service_role 相当)で同じクエリを実行 → データがあるなら RLS が原因確定
2. 対象テーブルの RLS が有効か、該当操作(SELECT/INSERT/UPDATE/DELETE)のポリシーが存在するか
3. ポリシー条件の `auth.uid()` と実際のセッションユーザーが一致するか
4. サーバー側コードで anon クライアントを使っていないか(cookie ベースのセッションが渡っているか)

## 3. Hydration error

**症状**: console に `Hydration failed because...` / `Text content does not match server-rendered HTML`。

| 原因パターン | 例 |
|---|---|
| サーバーとクライアントで値が変わる | `new Date()`, `Math.random()`, `window` 依存の分岐 |
| HTML の入れ子違反 | `<p>` の中に `<div>`, `<a>` の中に `<a>` |
| ブラウザ拡張が DOM を書き換え | 拡張オフ or シークレットウィンドウで再現確認 |
| localStorage 依存の初期 state | 初期レンダリングは SSR と同じ値にし、`useEffect` で更新 |

## 4. 白画面(エラーが見えない)

確認順:
1. ブラウザ console → エラーがあれば Client 実行時エラー
2. terminal / Vercel Functions ログ → あれば Server 側エラー
3. どちらにもない → `error.tsx` / ErrorBoundary が握りつぶしていないか、`loading.tsx` で止まっていないか(無限 await / 解決しない Promise)
4. レイアウトが原因のことも: `layout.tsx` で throw していると配下全ページが白くなる

## 5. 「buildは通るのに実行時に落ちる」

| 原因 | 説明 |
|---|---|
| 環境変数不足 | build 時は未参照で、実行時に `undefined`。`NEXT_PUBLIC_` プレフィックスの有無も確認(クライアントで使う変数は必須) |
| Server/Client 境界違反 | `'use client'` ファイルから server-only モジュール(service_role キー、`next/headers` 等)を import |
| 動的レンダリング | `cookies()` / `headers()` 使用ページが static 化されようとして失敗 → `export const dynamic = 'force-dynamic'` |
| migration 未適用 | 型は生成済み型定義で通るが、実 DB にテーブル/カラムがない(→ PGRST205/204) |

## 6. Auth まわり

| 症状 | 原因候補 |
|---|---|
| ログイン直後に弾かれる | middleware のセッション更新漏れ(`supabase.auth.getUser()` をmiddlewareで呼んでいない) |
| リロードでログアウトされる | cookie ベースクライアント(`@supabase/ssr`)を使わず localStorage ベースをSSRで使用 |
| redirect ループ | middleware の matcher にログインページ自身が含まれている |
| ローカルOK・本番NG | Supabase ダッシュボードの Redirect URLs に本番URLが未登録 |

## 7. 環境変数の典型ミス

- `.env.local` はあるが Vercel 等のデプロイ先に未設定
- `NEXT_PUBLIC_` なしの変数をクライアントで参照(undefined になる)
- 値の末尾に改行・空白・引用符が混入
- 別プロジェクト(dev/prod)の URL / key を混在
