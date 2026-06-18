# examples

refactor-planner の使用例。実際の計画は `<対象名>.md` でこのディレクトリに追加する。

## 例1: 肥大化したダッシュボードページの整理

### 入力例

> app/dashboard/page.tsx が600行になってて手を入れられない。データ取得もUIも全部入ってる。既存挙動を壊さず整理して。

### Skill が見る観点

- 現状の責務: 1ファイルに「3テーブルからのデータ取得 + 集計ロジック + 4セクションのUI」が同居
- 重複: 同じ tasks テーブルへのクエリが他の2画面にも別の形で存在 → repository 集約候補
- 分割方針: データ取得は lib/ へ、4セクションは components/dashboard/ の表示専用コンポーネントへ
- 影響範囲: 集計ロジックは page 内専用なので移動のみ。tasks クエリ集約は他2画面にも波及
- 段階的移行: 「新設→付け替え→削除」を Step 化し、各 Step で build + 表示確認
- 注意: 集計ロジックに怪しい挙動を見つけても、このリファクタでは直さず記録のみ

### 出力例(短縮版)

```md
# リファクタ計画: dashboard/page.tsx の分割

## リファクタ目的
600行の page.tsx を分割し、セクション単位で変更できるようにする。挙動は変えない。

## 現状の問題
| # | 箇所 | 問題 |
|---|---|---|
| 1 | page.tsx:1-150 | 3テーブルのクエリが直書き。tasks クエリは他2画面と重複 |
| 2 | page.tsx:151-600 | 4セクションのJSXが1コンポーネントに同居 |

## 分割方針
- lib/repositories/tasks.ts に tasks クエリを集約
- lib/services/dashboard.ts に集計ロジックを移動(純粋関数化)
- components/dashboard/{StatsCards,RecentTasks,ActivityFeed,DeadlineList}.tsx に分割(表示専用、propsで受ける)

## 段階的実施手順
### Step 1: components を新設し JSX を移動(データはpropsで渡す)
- 完了条件: build が通り、ダッシュボードの表示が移行前と同一
### Step 2: 集計ロジックを lib/services/dashboard.ts へ移動
### Step 3: tasks クエリを repository に集約し、まず dashboard のみ付け替え
### Step 4: 他2画面の tasks クエリを付け替え、旧コードを削除

## 回帰確認
- [ ] 各 Step 後: npx tsc --noEmit / npm run build
- [ ] ダッシュボードの4セクションの数値・並びが移行前と一致
- [ ] Step 4 後: 他2画面のタスク一覧表示
```
