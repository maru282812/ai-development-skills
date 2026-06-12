# API設計リファレンス(Next.js + Supabase)

api-designer スキルの Step 2(方式選択)・Step 4(Request/Response)・Step 5(認証認可)で参照する。
Route Handler / Server Actions の探索・実装パターンは
[system-investigator の nextjs.md](../../system-investigator/references/nextjs.md) セクション2〜3を参照。

## 目次

1. [Server Actions と Route Handler の使い分け](#1-server-actions-と-route-handler-の使い分け)
2. [Request / Response / エラー形式の定石](#2-request--response--エラー形式の定石)
3. [認証・認可の置き場所](#3-認証認可の置き場所)

---

## 1. Server Actions と Route Handler の使い分け

| 観点 | Server Actions | Route Handler |
|---|---|---|
| 呼び出し元 | 自アプリのフォーム・UIイベント | 外部クライアント、webhook、モバイルアプリ、fetch |
| メソッド | 実質 POST のみ | GET/POST/PUT/PATCH/DELETE |
| 型共有 | 関数なので入出力の型が自動で共有される | 型を別途定義して共有する必要がある |
| キャッシュ/再検証 | `revalidatePath` / `revalidateTag` と統合 | 自前で制御 |
| URLを持つか | 持たない(公開仕様にならない) | 持つ(API仕様として公開できる) |

判断フロー:

1. 外部(webhook、別アプリ、curl)から叩く必要がある → **Route Handler**
2. ブラウザのデータ取得(GET、SWR/React Query で再取得したい)→ **Route Handler**(または Server Component で直接取得)
3. 自アプリのフォーム送信・ボタン操作によるミューテーション → **Server Actions**
4. 迷ったら: ミューテーションは Server Actions、読み取りは Server Component 直、外部公開だけ Route Handler

注意:

- Server Actions も HTTP エンドポイントとして露出する。**「UIから呼ぶから認可不要」は誤り**。必ず関数冒頭で認証・認可する
- 重い処理・長時間処理はどちらにも不向き(タイムアウト)。ジョブ化や Edge Functions を検討する

## 2. Request / Response / エラー形式の定石

### validation

- 外部入力(body / searchParams / formData)は必ず zod で parse してから使う
- スキーマは API 定義の近く(同ファイルまたは `lib/validations/`)に置き、UI側のフォームと共有する

```ts
const createTaskSchema = z.object({
  title: z.string().min(1).max(200),
  dueDate: z.coerce.date().optional(),
});
```

### 成功レスポンス(Route Handler)

- 一覧: `{ data: T[], total?: number }`、単体: `{ data: T }` のように包む形式をプロジェクト内で統一する
- ステータス: 取得 200 / 作成 201 / 削除 204(body なし)

### エラーレスポンス統一形式

```ts
// 全エンドポイント共通
type ApiError = {
  error: {
    code: string;      // 'UNAUTHORIZED' | 'FORBIDDEN' | 'NOT_FOUND' | 'VALIDATION_ERROR' | 'INTERNAL'
    message: string;   // ユーザー向けに出せる文言
    details?: unknown; // VALIDATION_ERROR のときの field 別エラー等
  }
}
```

| 状況 | status | code |
|---|---|---|
| 未ログイン | 401 | UNAUTHORIZED |
| 権限なし | 403 | FORBIDDEN |
| 対象なし(または権限なしを隠したい場合) | 404 | NOT_FOUND |
| 入力不正 | 400 | VALIDATION_ERROR |
| サーバ内部 | 500 | INTERNAL(詳細はログのみ。message は汎用文言) |

Server Actions では throw ではなく `{ ok: true, data } | { ok: false, error }` の判別可能 union で返すと、フォーム側でのハンドリングが安定する。

### ページネーション

- `?page=1&limit=20`(offset方式)を基本とし、limit に上限(例: 100)を設ける
- 無限スクロール・大量データはカーソル方式(`?cursor=<id>`)を検討

## 3. 認証・認可の置き場所

### 原則: コードと RLS の二重防御

| 層 | 役割 |
|---|---|
| コード(API冒頭) | 認証確認、ロール確認、明確な 401/403 をユーザーに返す |
| RLS | 最後の防壁。コードの認可漏れ・将来の実装ミスでもデータが漏れないことを保証 |

RLS「だけ」に頼ると 403 と「0件」の区別がつかずUXが悪化し、
コード「だけ」に頼ると1箇所の漏れが即情報漏洩になる。両方書く。

### 実装パターン

```ts
// Route Handler / Server Action の冒頭の定型
const supabase = await createClient(); // server client
const { data: { user } } = await supabase.auth.getUser();
if (!user) return apiError(401, 'UNAUTHORIZED');

// リソース認可(例: プロジェクトメンバーか)
const isMember = await checkProjectMember(supabase, user.id, projectId);
if (!isMember) return apiError(403, 'FORBIDDEN');
```

- `getSession()` ではなく `getUser()` を使う(サーバ側で JWT を検証するため)
- 認可ヘルパー(`checkProjectMember` 等)は `lib/auth/` に集約し、各APIで重複実装しない

### service_role を使ってよい条件

1. RLS では表現できない横断処理(集計、管理者の全件操作、webhook起点の更新)であること
2. クライアントから直接到達できないサーバ専用コードであること
3. **RLS の代わりとなる認可チェックをコードで行っていること**(認可なしの service_role は設計不備)

詳細は [security-review の security.md](../../security-review/references/security.md) を参照。
