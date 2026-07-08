# examples

code-review の使用例。実際のレビュー結果は `<対象の簡潔な名前>.md` でこのディレクトリに追加する。

## 例1: プロフィール編集機能のレビュー

### 入力例

> プロフィール編集機能を実装した。build は通るけど不安なのでレビューして。

### Skill が見る観点

- `git diff` で変更ファイルを特定 → `app/profile/edit/page.tsx`、`app/actions/profile.ts` など
- Server Action `updateProfile` の冒頭で `getUser()` による認証確認があるか
- 更新対象を `user_id` で絞っているか(他人のプロフィールを更新できないか)
- formData を zod で検証しているか
- `revalidatePath('/profile')` の漏れで更新が画面に反映されないケースがないか
- Supabase の `error` を握りつぶしていないか

### 出力例(短縮版)

```md
# レビュー結果: プロフィール編集機能

## 総評
機能は動作するが、認可とバリデーションに重大な問題が2件あり、このままのマージは不可。

## 重大な問題
| # | ファイル:行 | 内容 | 理由 |
|---|---|---|---|
| 1 | app/actions/profile.ts:12 | formData の user_id をそのまま update の条件に使用 | 他人の user_id を送れば他人のプロフィールを更新できる。auth.getUser() の id を使うべき |
| 2 | app/actions/profile.ts:18 | display_name が未検証 | 空文字・500文字超が DB制約 (varchar(50)) と衝突し500エラーになる |

## 修正推奨
| # | ファイル:行 | 内容 | 理由 |
|---|---|---|---|
| 1 | app/actions/profile.ts:25 | error を捨てている | 失敗してもユーザーに成功表示される |

## 確認コマンド
npx tsc --noEmit / npm run lint / npm run build

## 修正指示文
app/actions/profile.ts を修正:
1. updateProfile 冒頭で supabase.auth.getUser() を呼び、未認証なら throw。
   update の .eq('user_id', ...) には formData ではなく user.id を使う。
2. zod で display_name (1〜50文字) を検証 ...
```
