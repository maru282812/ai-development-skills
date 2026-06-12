# セキュリティリファレンス(Next.js + Supabase)

security-review スキルの Step 2〜6 で参照する。
code-review / migration-review / api-designer からも共通リファレンスとして参照される。

## 目次

1. [RLS 監査の手順と典型的な穴](#1-rls-監査の手順と典型的な穴)
2. [service_role / キー管理](#2-service_role--キー管理)
3. [API 認証・認可(IDOR)](#3-api-認証認可idor)
4. [個人情報・ログ・その他の経路](#4-個人情報ログその他の経路)

---

## 1. RLS 監査の手順と典型的な穴

検索コマンドは [system-investigator の supabase.md](../../system-investigator/references/supabase.md) セクション2を参照。

典型的な穴:

- **有効化漏れ**: `create table` はあるが `enable row level security` がない。anon キーで全件読める
- **select だけ守って書き込みが素通り**: select ポリシーのみ定義し、insert/update/delete が `for all` の緩いポリシーや無防備
- **update の with check 漏れ**: `using` だけだと「自分の行を他人の行に書き換える」(user_id の差し替え)を防げない
- **insert の with check が緩い**: 任意の `organization_id` を指定して他テナントに行を作れる
- **security definer 関数経由のバイパス**: ポリシーは正しくても、`security definer` 関数が無条件にデータを返す
- **ビュー経由のバイパス**: PostgreSQL のビューはデフォルトで定義者権限。`security_invoker = true` がないビューはRLSを素通りする
- **JWT クレーム頼りの条件**: `auth.jwt() ->> 'role'` 等を使う場合、そのクレームを誰が設定できるかまで確認する

監査の型: テーブルごとに「anon / 認証済み他人 / 他テナント管理者」の3視点で各操作を考える。

## 2. service_role / キー管理

### キーの性質

| キー | RLS | 置いてよい場所 |
|---|---|---|
| anon key | 効く | クライアント可(公開前提のキー) |
| service_role key | **バイパス** | サーバ専用。`NEXT_PUBLIC_` 禁止、クライアントbundleに入れない |

### 検索

```bash
rg 'service_role|SERVICE_ROLE' --glob '*.ts' --glob '*.tsx' --glob '*.env*'
rg 'NEXT_PUBLIC_' .env* --glob '*.ts'   # NEXT_PUBLIC_ にシークレットが混ざっていないか
```

### service_role 使用箇所の合格条件(すべて満たすこと)

1. サーバ専用ファイル(Route Handler / Server Action / lib のサーバ専用モジュール)にあり、`'use client'` ファイルから import されていない(`import 'server-only'` の使用が望ましい)
2. RLS では表現できない正当な理由がある(管理者の横断処理、webhook、集計)
3. **RLS の代わりとなる認可チェックをコードで明示的に行っている**
4. 操作が監査ログに残る(管理者の代行操作・個人情報操作の場合)

「とりあえず service_role なら動く」は最頻出の事故源。RLSで書けるなら server client + RLS に倒す。

## 3. API 認証・認可(IDOR)

### 全エンドポイントの列挙

```bash
rg --files -g '**/route.ts'                       # Route Handler
rg "'use server'" --glob '*.ts' -l                # Server Actions
rg 'getUser\(\)|getSession\(\)' --glob '*.ts'     # 認証チェック箇所
```

### 確認の型(エンドポイントごと)

1. **認証**: 冒頭で `getUser()` しているか。`getSession()` のみは不可(サーバ検証されない)
2. **認可**: リクエスト中の ID(params, body の projectId 等)について、
   「このユーザーがこの ID に触ってよいか」の確認があるか
3. **絞り込み**: クエリに `.eq('user_id', user.id)` / `.eq('organization_id', ...)` 相当があるか。
   **リクエスト由来の user_id をそのまま信用していたら IDOR**
4. middleware 認証の場合: `matcher` から漏れているパスがないか。API は middleware に頼らず各自で確認する

### Server Actions の注意

Server Actions は「UIにボタンを出していない」だけでは保護にならない。
HTTPエンドポイントとして露出するため、Route Handler と同じ水準の認証・認可を関数冒頭で行う。

## 4. 個人情報・ログ・その他の経路

### 個人情報

- APIレスポンス・Server Component の props に **必要なカラムだけ** select しているか(`select('*')` で email や電話番号まで返していないか)
- 一覧画面・検索APIが他ユーザーの個人情報を含んでいないか
- 退会・削除時のデータ削除方針があるか

### ログ

```bash
rg 'console\.(log|error|info)' --glob '*.ts' --glob '*.tsx'
```

- パスワード、アクセストークン、セッション、Authorization ヘッダ、個人情報の生値をログに出さない
- エラーログに request body を丸ごと出すコードは個人情報が混ざりやすい(マスキングする)

### XSS / CSRF

```bash
rg 'dangerouslySetInnerHTML' --glob '*.tsx'
```

- ユーザー入力をHTMLとして描画する箇所はサニタイズ(DOMPurify等)必須
- 状態変更を GET で実装しない(リンク踏むだけで実行される)
- Server Actions は Next.js が Origin 検証を行うが、Route Handler の POST は必要に応じて Origin/CSRF 対策を確認

### Storage

```bash
rg "\.storage\.from\(" --glob '*.ts'
rg -i 'storage' supabase/migrations/   # bucket 定義と storage.objects のポリシー
```

- public バケットに個人情報ファイルを置いていないか
- storage policy がパス(`auth.uid()` をフォルダ名に使う等)で所有者を縛っているか
- 署名付きURLの有効期限が用途に対して長すぎないか

### Edge Functions

- `verify_jwt` を無効化している関数は、代替の認証(webhook署名検証等)があるか
- シークレットのハードコードがないか(`supabase secrets` / 環境変数を使う)
