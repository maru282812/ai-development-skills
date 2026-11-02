---
name: security-hardening-implement
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
metadata:
  reasoning-tier: deep
  summary: "公開前の予防的セキュリティ強化を一気に実装する担当。検査結果を待たず、hardeningテンプレ9章(認証/認可/RLS/秘密情報/入力検証/webhook署名/レート制限/ヘッダ/依存)を対象の実コードに当てて実装する。破壊的変更だけ止める。"
description: >-
  リリース/公開の前に、テストを待たず予防的にセキュリティの守りを実装するスキル。
  hardening-instructions-template.md の9章(認証・認可・RLS・秘密情報・入力検証・
  webhook署名・レート制限・セキュリティヘッダ・依存)を対象プロジェクトの実コードに当てて、
  各章の完了条件を満たすまで実装する。検査(静的/動的)の前段=予防実装。
  トリガー例:
  「セキュリティ強化を一気に実装して」「公開前にセキュリティを固めて」
  「テスト前に守りを実装して」「hardening の9章を実装して」
  「セキュリティコーディングして」「先回りでセキュリティ対策を入れて」。
  検査で見つけるのは security-static-check、検査結果を受けた改修指示は security-hardening-planner、
  本スキルは「検査の前に守りを作る」実装担当。
---

# Purpose

公開前に、検査結果を待たず **予防的に** セキュリティの守りを実装する。
順番は「S0 本スキルで強化実装 → S1/S2 で検査 → S3 で指摘を改修」。本スキルは S0。

実装の正は ai-testmaster の `docs/security/hardening-instructions-template.md`（9章）。
対象プロジェクトに `hardening-<project>.md` があればそれを優先（埋め済みの実例）。

これは防御の実装。攻撃ツールは作らない。

# When To Use

- 公開/リリース前に、テストより先にセキュリティの守りを固めたい
- 認証・認可・RLS・秘密情報・レート制限・ヘッダを先回りで入れたい

検査（穴探し）は security-static-check / testmaster 動的、改修指示は security-hardening-planner。

# 入力の自動決定

| 入力 | 決め方 |
|---|---|
| 対象コードパス | プロンプトの「対象コードは …」。無ければ `C:\work\<project>` |
| 実装チェックリスト | `<対象>/docs/security/hardening-<project>.md`。無ければ template から作って埋める |
| スタック | package.json / 構成から判定（Next.js+Supabase 前提。別なら章の意図を読み替え） |

# Procedure

### 0. 対象を把握
- 構成（Route Handler / Server Action / middleware / supabase / 外部連携）を列挙する。
- `hardening-<project>.md` があれば読む。無ければ template を元に対象向けに作る。
- 「守るべきもの」(個人情報/テナントデータ/課金/管理操作)を先に確定する。

### 1〜9. 各章を実コードに当てて実装
template の9章を順に。各章、対象の実ファイルを読んで現状を確認し、足りない守りを実装する:

1. **認証**: 各 Route/Action の先頭で getUser。middleware 任せにしない。公開面は理由を明記。
2. **認可/IDOR**: リソース取得を所有者/テナントで絞る。ID を信用しない。ロールをサーバで確認。
3. **RLS**: 保護テーブルで有効化・操作別ポリシー・GRANT。`db:test` を緑に。
4. **秘密情報**: NEXT_PUBLIC に秘密を入れない。service_role を server-only に閉じる。
5. **入力検証**: zod 等でサーバ側検証。SQL パラメータ化。dangerouslySetInnerHTML を避ける。
6. **webhook/外部**: 署名検証。SSRF 防止。変更系を GET にしない。
7. **レート制限**: 公開面・ログインに連打制限(429)・失敗回数制限・列挙防止。
8. **ヘッダ/Cookie**: HSTS/nosniff/X-Frame(or CSP)/CSP。認証Cookie を HttpOnly+Secure。
9. **依存/ログ**: audit の high/critical を解消or記録。ログに PII/トークンを出さない。

各章の「完了条件」(template 記載)を満たすまで実装する。

### 検証ゲート
実装後、対象の既定コマンドで緑を確認する（package.json で実コマンドを調べる）:
```
npm run typecheck && npm run lint && npm run test && npm run build
npm run db:test   # RLS(あれば)
```

### 記録
実装した章・変更ファイル・残した項目を `hardening-<project>.md` に反映する。

# 停止ゲート（重要）

CLAUDE.md の方針に従う。公開前の予防実装なので基本は止めずに進めるが、次だけ止めて確認:
- **破壊的変更**: DROP / データ消失の恐れ / 本番環境への適用。適用前に一言確認。
- **重い設計判断**: 認可モデルの作り替え・課金ロジック変更・外部連携の大改修で仕様が曖昧なとき。
- RLS/GRANT の適用は staging で先に確認し、本番適用は確認を挟む（GRANT 漏れ事故の予防）。

migration を伴うとき: 生成から適用まで実装の一部として進めるが、破壊的なら確認。
RLS だけでなく GRANT の付与漏れを必ず確認する。

# 実行モデルティア

推奨: **deep**。認証・認可・RLS の実装は判断の質が要る。
