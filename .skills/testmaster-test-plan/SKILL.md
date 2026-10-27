---
name: testmaster-test-plan
allowed-tools: Read, Grep, Glob, Bash
description: AI Testmaster のテスト項目（分母）を、対象アプリの実コードを読んでエージェント自身が網羅生成し、testmaster へ書き戻す。API課金を使わず Claude Code / Codex のサブスクで完結する。トリガー例「testmaster のテスト項目を作って」「このアプリのテスト項目を洗い出して testmaster に入れて」「改修したのでテスト項目を更新して」。対象アプリのソースから feature/endpoint を発見し、領域ごとに具体テスト項目を列挙、各項目に派生元コードの fingerprint を付けて POST /api/projects/{id}/suggestions/import に流す。
---

# testmaster-test-plan（テスト項目の生成・書き戻し / 部分・差分更新）

AI Testmaster の分母を作る担当。本スキルの主用途は **部分・差分更新**——「気になる領域だけ」
「改修した領域だけ」を素早く作り直す。**アプリ全体を取りこぼさず埋める“フル網羅”は
[[testmaster-full-plan]] の担当**（サーフェス×観点マトリクスで設計網羅率を測る）。どちらも内蔵 API
（Anthropic/OpenAI）は使わず、**このエージェント自身が実コードを読んで**生成する。追加課金は発生しない。

```text
1. 対象アプリのソースを読む（manifest 不要・実コードが一次情報）
2. 対象にする領域(area)を決める（全体でなく「今回触る領域」でよい）
3. 領域ごとに具体テスト項目を列挙（正常/入力検証/認証/異常/境界/領域固有リスク）
4. 各項目に sourceFingerprint（派生元コードの内容ハッシュ）を付与
5. POST /api/projects/{projectId}/suggestions/import で書き戻す
   （部分更新は mode="replace-areas" ＋ areas で対象領域を限定し、他領域の台帳・番号・履歴を温存）
6. 反映後の Coverage（領域別/全体%）を要約して停止
```

> **全置換(replace-all)は既定だが、既にフル網羅台帳がある所へ全置換すると台帳ごと消える。**
> 一部領域だけ作り直すときは必ず `mode="replace-areas"` を使う（下記ペイロード）。

## 入力（足りなければユーザーに確認）

- **projectId** — testmaster のプロジェクト ID（= `C:\work` 配下のフォルダ名の slug。例 `ai-chat-interview`）。
- **対象アプリのコードパス** — テスト項目を起こす対象リポジトリのルート。
- **testmaster のベース URL** — 既定 `http://localhost:3400`（開発サーバ）。

確認は一度にまとめて聞く（一問一答にしない）。

## 手順

1. **プロジェクト Context を取得** — `GET {baseUrl}/api/projects/{projectId}` を叩き、
   `project.description` / `project.context.users` / `project.context.constraints` /
   `project.context.successCriteria` を読む。これは**コードに書いていない「何が重要か・成功条件」**で、
   テストの優先度付けと受け入れ観点の土台にする。空なら無視してコードのみで進める（必須ではない）。
   404 ならプロジェクト未作成 → ユーザーに作成を促して止める。
2. **対象コードを調査** — ルーティング定義・API ハンドラ・主要画面/機能を Grep/Glob/Read で洗い出す。
   推測で増やさず、**実在する** endpoint / feature だけを対象にする。
3. **領域(area)に整理** — endpoint は資源単位（例 `API: users`）、機能は機能名、横断項目は `Project-wide`。
4. **各領域の項目を列挙** — 観点を機械的に当てて抜けを防ぐ（観点軸は [[test-planner]] のフレームを正とする）:
   - 正常系 / 入力検証(必須欠落・型不正) / 認証・認可(無トークン→401, 権限外→403) /
     権限別(ロールごとの可否) / RLS別(他人・他テナント・未認証での到達不能性) /
     異常系(404・409・5xx を出さない) / 境界・空・ページング / UI操作(二重送信・画面状態) /
     DB整合性(制約・トリガー副作用) / 領域固有リスク（コードから読み取れる分岐）。
   - description は「何を送ると、どの status/挙動になるべきか」を具体的に書く。
   - **Context を踏まえて優先度を決める**。successCriteria があれば、それを直接検証する受け入れ項目を
     `Project-wide` 領域に1〜数件足す（例: 「目標フロー全体を5分以内に完了できる」）。
     constraints/users に沿って priority(critical/high/...) を寄せる。
5. **fingerprint を付与**（改修検知の要・下記ルール）。
6. **POST で書き戻す**（下記ペイロード）。**部分更新なら `mode="replace-areas"`**（対象 area 以外を温存）、
   全体を作り直すときだけ全置換（`items` の完全なセット）。
7. **結果を要約** — 反映件数と、testmaster の Coverage（同じ `GET /api/projects/{id}` の suggestions/runs から領域別%）を報告して止める。

## ペイロード（書き戻し）

**部分更新（推奨・気になる領域だけ作り直す）** — 指定 area 内だけ置き換え、他は温存:

```
POST {baseUrl}/api/projects/{projectId}/suggestions/import
Content-Type: application/json

{ "mode": "replace-areas",
  "areas": ["API: users"],
  "items": [
    {
      "area": "API: users",
      "title": "GET /users — ページング上限超過時に 400 を返す",
      "description": "limit=10000 を送り、400 と明示エラーになること（500 を出さない）。",
      "category": "boundary",
      "priority": "high",
      "level": "detailed",
      "sourceFingerprint": "<派生元コードのハッシュ>"
    }
  ]}
```

**全置換（`mode` 省略）** — 台帳全体を `items` で置き換える。既存のフル網羅台帳を潰すので、単独領域の更新には使わない。

- `area` / `title` / `sourceFingerprint` は必須。`priority` は critical|high|medium|low（既定 medium）、
  `level` は rough|detailed（既定 detailed）。
- `replace-areas` では **`items` の全 area が `areas` に含まれる**こと（範囲外の area を混ぜると 400）。
- id はサーバが **`area+title`** から安定生成する。**同じ area/title を再送すれば同じ id・同じ番号(TM-###)** になり、
  既存の run（合格/不合格の履歴）が維持される。改修は `sourceFingerprint` の変化として表れ、id は変わらない。

## fingerprint ルール（改修検知の核）

`sourceFingerprint` = **その項目の派生元コードの内容ハッシュ**。原則:

- **コードが変われば値が変わり、変わらなければ同じ値**になること。
- 粒度は「項目の根拠となるコード単位」= 関数/ハンドラ単位が理想、難しければファイル単位で可。
- 算出例（ハンドラ本体を抜き出してハッシュ）:
  ```bash
  # 例: 該当ハンドラのソース行を取り出して 16桁ハッシュ
  sed -n '120,180p' src/api/users.ts | sha1sum | cut -c1-16
  ```
  または対象ファイル全体: `sha1sum src/api/users.ts | cut -c1-16`。
- 同じ source 単位から出た複数項目は**同じ fingerprint** を共有してよい（その単位が改修されたら一斉に再テスト対象になる）。

これにより、改修後に再実行すると:
変わった source の項目は **stale（要再テスト）** に落ち、消えた source の項目は分母から外れ、
新しい source は **未検証** として分母に加わる。完了％が常に現在バージョンに対して正直になる。

## やらないこと（境界）

- 内蔵の Anthropic/OpenAI API は**呼ばない**（このエージェントが生成主体）。
- 実在しない endpoint/feature を**推測で足さない**（分母を汚さない）。
- testmaster 側のスキーマ変更・コード変更はしない（書き戻し API を使うだけ）。
- 対象アプリのコードは**変更しない**（読むだけ）。テスト項目を起こすのが仕事。
- **全置換(replace-all)で既存のフル網羅台帳を潰さない**。領域単位の更新は `mode="replace-areas"` を使う。
  複数領域を触るなら、対象領域をすべて `areas` に列挙して1回の replace-areas import にまとめる（分割送信は同一 areas 内の前回分を消す）。
- **アプリ全体の網羅（設計網羅率を出す）は本スキルの仕事ではない** → [[testmaster-full-plan]] に回す。

## 関連

アプリ全体のフル網羅生成は [[testmaster-full-plan]]。実装結果の軽量検証は [[agent-tester]]、次の一手の選定は [[agent-planner]]。
本 skill は「テスト台帳の分母を作る/更新する」ことに特化する。
