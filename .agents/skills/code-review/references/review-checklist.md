# レビューチェックリスト

code-review スキルの Step 3(観点別レビュー)で使用する。
Next.js / Supabase の探索コマンドは
[system-investigator の references](../../system-investigator/references/nextjs.md) を、
セキュリティの深掘りは [security-review の security.md](../../security-review/references/security.md) を参照。

## TypeScript

- [ ] `any` / `as` の不要な使用がないか(特に外部入力への `as`)
- [ ] null / undefined の可能性を握りつぶしていないか(`!` の濫用)
- [ ] `database.types.ts` 等の生成型とドメイン型が食い違っていないか
- [ ] 関数の戻り値型が推論任せで意図とずれていないか(特に Server Actions)

## Next.js(App Router / Pages Router)

- [ ] Router の規約に従っているか(`page.tsx` / `route.ts` / `layout.tsx` の役割)
- [ ] `'use client'` が必要最小限か。サーバで済む処理をクライアントでしていないか
- [ ] Client Component に秘密の環境変数(`NEXT_PUBLIC_` なし)・サーバ専用モジュールを import していないか
- [ ] `revalidatePath` / `revalidateTag` / `router.refresh` の漏れで更新が画面に反映されないケースがないか
- [ ] 動的レンダリング/キャッシュの意図(`fetch` オプション、`dynamic` 指定)が正しいか
- [ ] middleware の認証チェックを素通りするパスを作っていないか

## Supabase クライアントの使い分け

- [ ] Client Component → browser client、Server側 → server client(cookies連携)になっているか
- [ ] `service_role` クライアントが Route Handler / Server Action / サーバ専用ファイル以外で使われていないか
- [ ] `service_role` 使用箇所で、RLSの代わりになる認可チェックをコードで行っているか

## 認証・認可

- [ ] Route Handler / Server Action の冒頭でユーザー取得・未認証時の拒否をしているか
- [ ] リソースの所有者確認(`user_id` / `organization_id` での絞り込み)があるか
- [ ] 認可チェックがUI(ボタン非表示)だけでなくサーバ側にもあるか
- [ ] `getSession()` ではなく `getUser()`(サーバ側で検証される方)を使っているか

## RLS

- [ ] 新規テーブルで RLS が有効化されているか
- [ ] クライアント直アクセス(browser client の `.from()`)に対応する操作別ポリシーがあるか
- [ ] ポリシー条件が今回の変更(カラム追加・仕様変更)と整合しているか

## Validation

- [ ] request body / searchParams / formData を zod 等で検証してから使っているか
- [ ] 文字列長・数値範囲・enum 値の制約が DB 制約と一致しているか
- [ ] ファイルアップロードのサイズ・MIMEタイプ検証があるか

## Error Handling

- [ ] Supabase 呼び出しの `error` を無視していないか(`const { data } = ...` で error を捨てる形)
- [ ] catch して握りつぶしている箇所がないか(最低限ログ、ユーザーには適切なメッセージ)
- [ ] エラーレスポンスに内部情報(スタックトレース、SQL)を含めていないか
- [ ] `error.tsx` / フォームのエラー表示など、ユーザーが失敗に気付ける導線があるか

## Build / Lint

- [ ] `npx tsc --noEmit` が通る
- [ ] `npm run lint` が通る
- [ ] `npm run build` が通る(動的APIの使用による build エラーに注意)

## UI

- [ ] ローディング・空状態・エラー状態の表示があるか
- [ ] スマホ幅でレイアウトが崩れないか(固定幅・横スクロール)
- [ ] フォーム二重送信の防止(submit 中の disabled)があるか

## 既存機能への影響

- [ ] 変更した共通関数・共有コンポーネントの全利用元を確認したか
- [ ] DBカラム変更がある場合、既存クエリ・型・画面に波及していないか
- [ ] APIレスポンス形式の変更が既存の呼び出し元を壊さないか
