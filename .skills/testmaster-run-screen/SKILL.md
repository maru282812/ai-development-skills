---
name: testmaster-run-screen
allowed-tools: Read, Grep, Glob, Bash
description: AI Testmaster のテスト項目のうち「画面表示・遷移・フォーム操作系（LIFF含む）」を、ブラウザを操作して検証し、合否を testmaster の Run Log に記録する。Playwright（webapp-testing skill）で対象アプリを開き、画面描画・導線・状態・エラー画面・スクショで確認する。トリガー例「testmaster の画面項目をテストして記録して」「LIFF画面のテストを実行して」「画面表示テストを回して結果を入れて」。純粋なAPI契約系は対象外（それは testmaster-run-api）。GET /api/projects/{id} で項目を取得し、自分が実行できる項目だけ実行、POST /api/projects/{id}/runs で記録する。
---

# testmaster-run-screen（画面/LIFF テストの実行・記録）

[[testmaster-test-plan]] が作った分母のうち、**ブラウザで画面を開いて操作・目視/DOM検証が要る項目**を
Playwright で実行し、testmaster の Run Log に合否を記録する担当。記録するほど Coverage の % が上がる。
API課金は使わない（このエージェントがブラウザを操作して判定する）。

```text
1. testmaster から項目を取得（GET /api/projects/{id}）
2. 自分の担当（画面/遷移/フォーム/LIFF表示系）の項目だけ選ぶ
3. Playwright で対象アプリを開き、操作・DOM/目視・スクショで検証
4. POST /api/projects/{id}/runs で passed/failed/blocked を記録
5. 実行件数・合否・更新後の% を要約して停止
```

## 入力（足りなければ一度にまとめて確認）

- **projectId** — testmaster のプロジェクト ID（例 `ai-chat-interview`）。
- **testmaster のベース URL** — 既定 `http://localhost:3400`。
- **対象アプリのベース URL** — ブラウザで開く先（例 `http://localhost:3000`）。未起動なら起動方法を確認。
- **LIFF の扱い** — dev/モックモードの有無（下記「LIFF特有の注意」）。

## 担当範囲（どの項目を実行するか）

各 suggestion の title / description を読み、**ブラウザで画面を開かないと判定できないもの**を選ぶ:

- 画面が正しく描画される / 必要要素が出る（アンケート画面表示・プロフィール確認 等）
- 画面遷移・リダイレクト導線（`/profile/check?next=...` へ誘導 等）
- フォーム入力・送信・バリデーション表示・完了画面
- エラー画面・状態表示（設定不足の案内画面、二重回答防止画面 等）

**HTTP リクエストだけで status を見れば済む契約テストはスキップ**（[[testmaster-run-api]] の担当）。
スキップした項目は記録せず Untested のまま残す。

## 輪切り実行（対象の絞り込み）

フル網羅で分母が大きいときは、**一度に全部を実行しない**。ユーザー指定の輪切りだけ回す
（分母は全部あってよい／実行は優先度順でよい）。指定が無ければ既定は「critical+high」。

- **優先度で** — 「critical+high だけ」→ `suggestion.priority` で絞る。
- **領域で** — 「Screen /survey だけ」→ `suggestion.area` で絞る。
- **番号で** — 「TM-012〜020」→ 表示番号 `suggestion.code`（`TM-###`）の範囲で絞る。
- 絞った結果、担当外（純API系）や範囲外の項目は実行せず Untested のまま残す。

## 手順

1. **項目取得** — `GET {baseUrl}/api/projects/{projectId}` → `bundle.suggestions` を読む。404 なら未作成として止める。
2. **担当項目を抽出** — 上記「担当範囲」で対象を絞る。
3. **ブラウザ準備** — `webapp-testing` skill（Playwright）を使ってブラウザを起動し、対象アプリのベース URL を開く。
4. **LIFF特有の注意**（下記）に従い、実機/モックの前提を確認。前提が満たせない項目は無理に実行せず blocked。
5. **実行** — 項目ごとに画面を開き、操作（クリック・入力・送信）して期待挙動を DOM/目視で確認。
   - 各項目で**スクショを取得**し、記録の根拠にする。
   - description の「どの画面/要素/遷移になるべきか」に照らして判定。
6. **記録** — 各項目を `POST /runs` で記録（下記）。`suggestionId` は手順1の id。notes に観察結果＋スクショパス。
7. **要約** — 実行件数・passed/failed/blocked の内訳・更新後の領域別% を報告して停止。

## LIFF特有の注意

LIFF 画面は `liff.init` が LIFF ID と LINE ログイン文脈を要求するため、素のブラウザでは初期化に失敗しやすい。

- 対象アプリに **dev/モックモード**（`liffAuthAvailable=false` 経路、liff モック、環境変数での切替）があるか、
  コードを読んで確認する（`liff.init` / `liffAuthAvailable` / 本番モード判定の周辺）。
- モック/dev で開ける項目はそれで検証する。
- 実機 LINE が必須で代替が無い項目は **blocked**（理由: LIFF実機/モック未整備）として実行しない。
  （例: 「本番モードで設定不足なら 503/エラー画面」は dev で再現できればテスト、できなければ blocked）

## 記録ペイロード

```
POST {baseUrl}/api/projects/{projectId}/runs
Content-Type: application/json

{
  "suggestionId": "<suggestions[].id>",
  "title": "<その項目の title>",
  "result": "passed",            // passed | failed | blocked
  "notes": "アンケート画面が描画され設問が表示。screenshot: ./.tmp/survey.png"
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
> curl -sS -X POST "{baseUrl}/api/projects/{projectId}/runs" \
>   -H "Content-Type: application/json" \
>   --data-binary @payload.json
> ```
> ファイル書き出しは Write ツール等 UTF-8 で行う。`-d "{...日本語...}"` のインライン指定や
> PowerShell `Invoke-RestMethod -Body "<文字列>"` は使わない（同じ化けが起きる）。
> notes にスクショパスや観察結果の日本語を残す本スキルでは特に必須。

## 合否判定の原則

- **passed** — 期待した画面/要素/遷移/状態が出た。
- **failed** — 画面崩れ・要素欠落・誤った遷移・想定外エラー画面。notes に何がどう違ったかを残す。
- **blocked** — 環境要因で実行不能（対象未起動・LIFF実機必須でモック無し・依存外部サービス無し）。理由を notes に。

## やらないこと（境界）

- 対象アプリのコードを**書き換えない**（テストするだけ）。
- 担当外（純API契約系）の項目は**記録しない**（Untested のまま残す）。
- 本番/共有データへの破壊的操作をしない。書き込みを伴う画面操作は、テスト用データ/隔離が用意できる場合のみ。
- 推測で項目を増やさない（分母を作るのは [[testmaster-test-plan]]）。

## 関連

分母の生成・更新は [[testmaster-test-plan]]、API契約系の実行は [[testmaster-run-api]]、
ブラウザ操作の基盤は `webapp-testing` skill。本 skill は「画面/LIFF系の実行と記録」に特化する。
