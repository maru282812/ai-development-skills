---
name: security-static-check
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
metadata:
  reasoning-tier: standard
  summary: "リリース前の静的セキュリティチェック実行担当。起動不要・staging不要で、依存CVE/秘密混入/バンドル漏出/認証認可の机上点検/RLSテストを順に回し、結果を hardening レポートに積む。"
description: >-
  Next.js + Supabase プロジェクトのリリース前「静的」セキュリティチェックを
  コマンド一発で回す実行スキル。コードを読んで穴を探す層（起動・staging 不要）。
  依存の既知脆弱性(npm audit) / 秘密情報の混入(gitleaks) / ビルド成果物への漏出 /
  認証・認可の机上点検 / RLS 単体テスト を順に実行し、結果を docs/security に積む。
  トリガー例:
  「静的セキュリティチェックして」「<project> のセキュリティを静的に見て」
  「リリース前のセキュリティ確認（静的）」「npm audit と秘密混入を確認して」
  「依存の脆弱性を見て」「鍵が漏れてないか確認して」「バンドルに秘密が出てないか」。
  深掘りの AI レビューは security-review（Supabase 権限モデル特化）に委ねる。
  起動して攻撃する動的検証は別（testmaster 回帰 + ZAP）。
---

# Purpose

対象プロジェクトのルートで、リリース前の **静的** セキュリティチェックを決定論的に回す。
起動も staging も不要。手順の正は ai-testmaster の
`docs/security/static-check-playbook.md`（あれば読んで従う）。無ければ本スキルの手順で回す。

このスキルは **防御側の検証** を実行する。攻撃ツールは作らない。

# When To Use

- リリース前・マージ前に、起動せず静的にセキュリティの当たりを取りたい
- 依存の既知脆弱性・秘密情報の混入・認可の空欄を一度に洗い出したい

深掘り（RLS 行レベル到達性・service_role 到達範囲・テナント横断 IDOR）は
[security-review](../security-review/SKILL.md) を併用する。
起動して実際に他人データへ到達できるか試す動的検証は testmaster 回帰 + ZAP（別手順）。

# 入力の自動決定

| 入力 | 決め方 |
|---|---|
| 対象コードパス | プロンプトの「対象コードは …」。無ければ `C:\work\<project>` |
| レポート出力先 | `<対象>/docs/security/static-report-<project>-<date>.md`。docs/security が無ければ作る |
| hardening 反映先 | `<対象>/docs/security/hardening-<project>.md`（あれば追記、無ければ作成を提案） |

埋まらない対象パスだけ最初に1回確認する。以後は止めずに回す。

# Procedure

対象プロジェクトのルートに cd してから、上から順に実行する。各ステップの結果は控える。

### 1. 依存の既知脆弱性
```bash
npm audit --omit=dev
```
- high / critical を数える。各々が **本番ランタイム依存か、dev/ビルドツール依存か** を切り分ける
  （例: wrangler / miniflare 経由の undici は dev 側）。本番側の high/critical を最優先。
- `npm audit fix` で直るものは提案（破壊的変更は lockfile 差分を見てから）。
- フレームワーク本体（Next.js 等）の既知 CVE に該当バージョンでないか確認する。
- osv-scanner があれば併用: `osv-scanner --lockfile=package-lock.json`

### 2. 秘密情報の混入
```bash
# NEXT_PUBLIC に秘密が乗っていないか（ANON_KEY は公開前提なので除外）
git grep -nE "NEXT_PUBLIC_[A-Z_]*(SERVICE|SECRET|PRIVATE|TOKEN|KEY)" -- . | grep -v ANON_KEY
# 実鍵の混入（ドキュメントの説明文・テストのダミー値は誤検知として除外する）
git grep -nE "sk_live_[0-9A-Za-z]{10,}|service_role.*eyJ|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY" -- . ':(exclude).env.example'
# env が無視されているか
git check-ignore .env.local .env*.local
```
- gitleaks があれば優先: `gitleaks detect --no-banner`
- 実鍵が見つかったら **ローテーション必須**（履歴から消すだけでは漏れ扱い）。

### 3. ビルド成果物への漏出
```bash
npm run build
grep -rnE "service_role|SUPABASE_SERVICE_ROLE|sk_live_" .next/static .open-next 2>/dev/null | head
```
- クライアントチャンクに秘密が出たら import 経路を辿り `server-only` でサーバ側に閉じ込める。

### 4. 認証・認可の机上点検
```bash
# Route Handler / Server Action の総数
grep -rln "export async function \(GET\|POST\|PUT\|PATCH\|DELETE\)\|['\"]use server['\"]" src app 2>/dev/null | wc -l
# getUser の出現数（共通ガードに集約している場合は数が合わなくて正常）
grep -rn "auth.getUser\|getUser(" src app 2>/dev/null | wc -l
# ID をそのままクエリに使う IDOR の当たり
grep -rnE "\.eq\('id'|params\.(id|slug)|searchParams" src app 2>/dev/null | head -40
```
- getUser 数が Route/Action 数より少ないとき、**共通ガード（middleware / guard 関数）で集約**しているのか、
  **本当に抜けている**のかを必ず確認する。前者は正常、後者は穴。guard の実体を Read して判定する。
- IDOR 候補は「所有者 / テナントで絞っているか」を1件ずつ確認する。

### 5. RLS 単体テスト（あれば）
```bash
npm run db:test   # 例: supabase/tests/rls.sql。スクリプト名は package.json で確認
```
- 無ければ「保護テーブルごとに他テナント0行を確認する SQL が無い」ことを GAP として報告する（自動では書かない）。

### 6. AI レビューの委譲（任意・重い）
- 汎用: Claude Code 組み込み `/security-review`。
- Supabase 権限モデル特化: [security-review](../security-review/SKILL.md) を Read して従う。
- 本スキルは机上の当たりまで。深掘り結果も同じレポートに統合する。

# 出力

`docs/security/static-report-<project>-<date>.md` に次を書く:

```md
# 静的セキュリティレポート: <project> (<date>)

## 判定
問題なし / 要対応 / リリース不可 —（要約）

## 結果
| 項目 | 結果 | 判定 |
|---|---|---|
| npm audit (本番依存の high/critical) | <n>件 | ○/△/× |
| npm audit (dev/ビルド依存) | <n>件 | 参考 |
| 秘密混入 (gitleaks/grep) | <n>件（実鍵/誤検知の内訳） | ○/× |
| バンドル漏出 | 有/無 | ○/× |
| 認可の空欄（guard 未集約で getUser 抜け） | <n>箇所 | ○/× |
| RLS テスト | 緑/赤/無 | ○/×/GAP |

## 要対応（優先度順・箇所つき）
1. ...

## 誤検知として除外したもの
- ...（根拠つき）
```

出た要対応は `hardening-<project>.md` の該当章に積む。

# 停止ゲート

- 破壊的操作（`npm audit fix --force`、鍵のローテーション実行、履歴書き換え）は **自分でやらず提案して止まる**。
- 認可の抜けが「穴」か「guard 集約」か判定できないときは、断定せず候補＋根拠＋確信度で返す
  （認可指摘は二段階: enforcement 層を確認してから severity を付ける）。

# 実行モデルティア

推奨: **standard**。コマンド実行と机上の切り分けが主。認可の深掘り判断が要るときだけ deep に委譲。
