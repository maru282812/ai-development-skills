# examples

security-review の使用例。実際のレビュー結果は `<対象名>.md` でこのディレクトリに追加する。

## 例1: リリース前のテナント分離確認

### 入力例

> マルチテナントの案件管理SaaSをリリースする前に、他のテナントのデータが見えないかセキュリティ確認して。RLS 大丈夫?

### Skill が見る観点

- 全テーブルの RLS 有効化 × 操作別ポリシーの表を作成(migrations を全件確認)
- ポリシー条件に `organization_id` の絞り込みがあるか。insert の `with check` で他テナントIDを指定できないか
- service_role 使用箇所の列挙と、各箇所のコード側認可チェックの有無
- Route Handler / Server Actions の params 由来の ID(orgId, projectId)を無検証で使っていないか(IDOR)
- ビュー・security definer 関数による RLS バイパス経路
- Storage バケットのパス権限

### 出力例(短縮版)

```md
# セキュリティレビュー: テナント分離(リリース前)

## セキュリティ判定
**リリース不可** — 他テナントのデータに到達できる経路が2件ある。

## 重大リスク
| # | 箇所 | 内容 | 攻撃シナリオ |
|---|---|---|---|
| 1 | supabase/migrations/...deals.sql | deals の insert ポリシーに with check がない | 認証済みユーザーが body の organization_id を他社IDにして行を作成できる |
| 2 | app/api/deals/[id]/route.ts:8 | service_role で id 検索のみ。org 確認なし | 他社の deal の UUID を推測・入手すれば内容を取得できる(IDOR) |

## RLS / Policy
| テーブル | RLS | select | insert | update | delete | 問題 |
|---|---|---|---|---|---|---|
| deals | ○ | org条件○ | **check なし** | org条件○ | なし(全拒否) | insert 修正必要 |
| contacts | **無効** | - | - | - | - | 即有効化 |

## service_role確認
| 箇所 | 用途 | 認可チェック | 判定 |
|---|---|---|---|
| app/api/deals/[id]/route.ts | 詳細取得 | なし | NG: server client + RLS に変更 |

## 修正指示
1. contacts に enable row level security + org ポリシーを追加する migration を作成
2. deals の insert ポリシーに with check (is_org_member(organization_id)) を追加
3. app/api/deals/[id]/route.ts を server client に変更し ...
```
