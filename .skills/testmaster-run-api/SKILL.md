---
name: testmaster-run-api
allowed-tools: Read, Grep, Glob, Bash
description: AI Testmaster のテスト項目のうち「API契約系」を、対象アプリへ実際に HTTP リクエストを投げて検証し、合否を testmaster の Run Log に記録する。status コード・必須フィールド・認証(401/403)・入力検証(400)・異常(404/409)・境界などを直接叩いて確認する。トリガー例「testmaster のAPI項目をテストして記録して」「API契約テストを実行して」「契約テストを回して結果を入れて」。画面描画/ブラウザ操作が要る項目は対象外（それは testmaster-run-screen）。GET /api/projects/{id} で項目を取得し、自分が実行できる項目だけ実行、POST /api/projects/{id}/runs で記録する。
---

# testmaster-run-api（API契約テストの実行・記録）

[[testmaster-test-plan]] が作った分母のうち、**HTTP で直接検証できる契約テスト**を実行し、
testmaster の Run Log に合否を記録する担当。記録するほど Coverage の % が上がる。
API課金は使わない（このエージェントが実リクエストを投げて判定する）。

```text
1. testmaster から項目を取得（GET /api/projects/{id}）
2. 自分の担当（API契約系）の項目だけ選ぶ
3. 対象アプリへ実リクエストを投げ、期待 status/挙動と照合
4. POST /api/projects/{id}/runs で passed/failed/blocked を記録
5. 実行件数・合否・更新後の% を要約して停止
```

## 入力（足りなければ一度にまとめて確認）

- **projectId** — testmaster のプロジェクト ID（例 `ai-chat-interview`）。
- **testmaster のベース URL** — 既定 `http://localhost:3400`。
- **対象アプリのベース URL** — 実際にリクエストを投げる先（例 `http://localhost:3000`）。未起動なら起動方法を確認。

## 担当範囲（どの項目を実行するか）

各 suggestion の title / description を読み、**HTTP リクエストだけで合否を判定できるもの**を選ぶ:

- status コード（200/400/401/403/404/409/503 等）の確認
- 必須フィールド欠落・型不正 → 400 系
- 認証・認可（無トークン / 不正トークン / 権限外）→ 401/403
- 異常・境界（存在しないID→404、重複→409、limit 超過、空結果、ページング）
- レスポンス本文の契約（必須キー・形）

**画面描画・遷移・フォーム操作・LIFF表示が前提の項目はスキップ**（[[testmaster-run-screen]] の担当）。
スキップした項目は記録せず Untested のまま残す。

## 輪切り実行（対象の絞り込み）

フル網羅で分母が大きいときは、**一度に全部を実行しない**。ユーザー指定の輪切りだけ回す
（分母は全部あってよい／実行は優先度順でよい、が testmaster の設計）。指定が無ければ既定は「critical+high」。

- **優先度で** — 「critical+high だけ」→ `suggestion.priority` で絞る（重要項目の実施率を先に上げる）。
- **領域で** — 「API: users だけ」→ `suggestion.area` で絞る。
- **番号で** — 「TM-012〜020」→ 表示番号 `suggestion.code`（`TM-###`）の範囲で絞る。
- 絞った結果、担当外（画面系）や範囲外の項目は実行せず Untested のまま残す。

## 手順

1. **項目取得** — `GET {baseUrl}/api/projects/{projectId}` → `bundle.suggestions`（id/title/area/description）を読む。
   404 ならプロジェクト未作成 → 止めてユーザーに促す。
2. **担当項目を抽出** — 上記「担当範囲」で対象を絞る。
3. **対象アプリ疎通確認** — ベース URL に health 等で疎通。落ちていれば起動を促す。
4. **実行** — 項目ごとに実リクエストを送る（`curl` / fetch）。description の「何を送ると、どの status/挙動になるべきか」に照らして判定。
   - 認証系は無/不正トークンで叩く。検証系は欠落・不正 body。異常系は存在しないID等。
   - リクエストとレスポンス（status＋本文要点）を控える＝記録の根拠にする。
5. **記録** — 各項目を `POST /runs` で記録（下記）。`suggestionId` は手順1で取得した id。
6. **要約** — 実行件数・passed/failed/blocked の内訳・更新後の領域別% を報告して停止。

## 記録ペイロード

```
POST {baseUrl}/api/projects/{projectId}/runs
Content-Type: application/json

{
  "suggestionId": "<suggestions[].id>",
  "title": "<その項目の title>",
  "result": "passed",            // passed | failed | blocked
  "notes": "GET /liff/survey/x 無トークン → 401 を確認。期待通り。"
}
```

run には対象項目の fingerprint がサーバ側で自動付与される。改修後に [[testmaster-test-plan]] を再実行すると
fingerprint が変わり、この合格は自動で「要再テスト」に戻る（履歴は残る）。

> **【重要】notes に日本語を含めるときの送り方（Windows 必須）**
> JSON body を**シェルのコマンドライン引数として直接渡さない**。Windows ではコンソールが UTF-8→CP932 に
> 再エンコードし、「ソ・表・能・―・〜」など 2 バイト目が `0x5C`(`\`) になる文字が JSON のエスケープを壊して
> サーバ側 `JSON.parse` が 400 になる（＝「特定の日本語だけ 400」の正体）。
> **必ずペイロードを UTF-8 ファイルに書き出してから `--data-binary @file` で送る**：
> ```bash
> # payload.json を UTF-8 (BOM なし) で書き出す → バイト列をそのまま送る
> curl -sS -X POST "{baseUrl}/api/projects/{projectId}/runs" \
>   -H "Content-Type: application/json" \
>   --data-binary @payload.json
> ```
> ファイル書き出しは Write ツール等 UTF-8 で行う。`-d "{...日本語...}"` のインライン指定や
> PowerShell `Invoke-RestMethod -Body "<文字列>"` は使わない（同じ化けが起きる）。
> どうしてもインラインで送る場合のみ notes を ASCII に限定する。

## 合否判定の原則

- **passed** — 期待した status/挙動と一致。
- **failed** — 契約違反（想定外の 5xx、認証が素通り、必須欠落が 200 等）。notes に実際の結果を残す。
- **blocked** — 環境要因で実行不能（対象未起動・依存サービス無し・隔離手段が無く破壊的で叩けない）。理由を notes に。

## やらないこと（境界）

- 対象アプリのコードを**書き換えない**（テストするだけ）。
- 担当外（画面系）の項目は**記録しない**（Untested のまま残す）。
- **本番/共有データへの破壊的操作をしない**。書き込み・削除系は、testmaster 連携の test-session 隔離
  （`POST /api/projects/{id}/integration/session` 由来）やテスト用環境がある場合のみ実行。
  隔離手段が無ければ、その項目は **blocked**（理由: 破壊的・隔離なし）にして実行しない。
- 推測で項目を増やさない（分母を作るのは [[testmaster-test-plan]]）。

## 関連

分母の生成・更新は [[testmaster-test-plan]]、画面系の実行は [[testmaster-run-screen]]。
本 skill は「API契約系の実行と記録」に特化する。
