# examples

api-designer の使用例。実際の設計結果は `<機能名>.md` でこのディレクトリに追加する。

## 例1: タスクCRUD の API 設計

### 入力例

> タスク管理機能のAPIを設計して。一覧・作成・更新・削除。Server Actions にするか API にするかも決めて。認可チェックどこでやる?

### Skill が見る観点

- 呼び出し元は自アプリのUIのみ → ミューテーションは Server Actions、一覧は Server Component 直取得が候補
- ただし一覧でクライアント側の再取得(フィルタ変更)が頻繁 → GET の Route Handler も比較検討
- 認可: プロジェクトメンバーのみ → コード冒頭でメンバーチェック + RLS の二重防御
- validation: title 1〜200文字、status は enum、zod スキーマをフォームと共有
- エラー形式: Server Actions は `{ ok, data | error }` union
- rate limit: 認証必須の内部APIなので不要と判断

### 出力例(短縮版)

```md
# API設計: タスクCRUD

## API設計概要
ミューテーション3本は Server Actions(フォーム連携・型共有のため)。
一覧はフィルタ変更が多いため GET Route Handler とし SWR で取得。

## エンドポイント一覧
| Method/種別 | パス or 関数名 | 用途 | 認証 | 認可 |
|---|---|---|---|---|
| GET | /api/projects/[id]/tasks | 一覧(status, page) | 必須 | プロジェクトメンバー |
| Action | createTask | 作成 | 必須 | プロジェクトメンバー |
| Action | updateTask | 更新 | 必須 | プロジェクトメンバー |
| Action | deleteTask | 削除(論理) | 必須 | プロジェクトメンバー |

## Request / Response
### createTask
- Request: { projectId: uuid, title: string(1..200), dueDate?: Date }(zod: createTaskSchema)
- Response: { ok: true, data: Task } | { ok: false, error: { code, message } }

## 認証・認可
| エンドポイント | 認証 | 認可条件 | チェック場所 |
|---|---|---|---|
| 全て | getUser() | is_project_member | コード + RLS の二重 |

## Supabaseアクセス方針
server client のみ。service_role 不使用(RLSで表現可能なため)。

## 実装ファイル
| パス | 内容 |
|---|---|
| app/api/projects/[id]/tasks/route.ts | GET 一覧 |
| app/actions/tasks.ts | create/update/delete |
| lib/validations/task.ts | zod スキーマ(フォームと共有) |
```
