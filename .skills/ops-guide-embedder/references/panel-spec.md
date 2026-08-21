# 実行手順パネル 仕様（panel-spec）

運営者向けの「番号付き実行手順パネル」の中身とデータ構造。実装は対象サイトの
`features/ops-guide/` に置く。ここでは**何を満たすか**を定義し、フレームワークに合わせて実装する。
既定スタックは Next.js App Router + React/TS。

## 目次
- ステップのデータ構造
- 実行場所タグ（place）
- 動的置換（{slug} / {root}）
- パネルの表示要件（UI）
- 状態（空 / 通常）
- testmaster を範とする出力イメージ

## ステップのデータ構造

ステップは本文直書きせず、`features/ops-guide/steps.ts` に構造化データとして持つ。
1箇所を直せば手順全体が直り、改修時の同期がしやすくなる。

```ts
// features/ops-guide/steps.ts
export type OpsPlace = "site" | "claude-code" | "other-project";

export type OpsStep = {
  no: number;                 // 表示順（1始まり）
  place: OpsPlace;            // 実行場所タグ
  body: string;              // 説明文 or 貼り付けるコマンド/実行文。{slug} {root} を含められる
  copyable?: boolean;        // true なら Copy ボタンを出す（コマンド/実行文は true）
  project?: string;          // place === "other-project" のとき、連携先プロジェクト名
};

export const OPS_STEPS: OpsStep[] = [
  { no: 1, place: "site", body: 'Projects で「{slug}」を選択する' },
  { no: 2, place: "site", body: "Context を記入して Save" },
  { no: 3, place: "claude-code", body: "{slug} のテスト項目を作って。対象コードは {root}", copyable: true },
  // …実際のサイトの操作フローに合わせて列挙する
];
```

## 実行場所タグ（place）

各ステップが「どこで実行するか」を運営者が一目で分かるようにバッジ表示する。最低限この3種:

| place            | 表示ラベル例        | 意味                                             |
|------------------|---------------------|--------------------------------------------------|
| `site`           | サイト              | このサイトの画面上で操作する                     |
| `claude-code`    | Claude Code         | 実行文をコピーして Claude Code / Codex に貼る     |
| `other-project`  | 連携: {project}     | 別プロジェクト側で操作・実行する（横断連携）      |

`other-project` は `project` を添えて「連携: ai-chat-interview」のように出す。
サイト量産の原本では、ディスパッチや他プロジェクトとの連携で「どこで何をするか」を
明示することが目的なので、このタグを曖昧にしない。

## 動的置換（{slug} / {root}）

ステップ本文に絶対パスを直書きしない。次のプレースホルダを**実行時に置換**する:

- `{slug}` → 選択中プロジェクトの slug（例: `ai-chat-interview`）
- `{root}` → `c:\work\{slug}`（例: `c:\work\ai-chat-interview`）

置換は `features/ops-guide/` 内のヘルパ1つに集約する:

```ts
// features/ops-guide/substitute.ts
export function substitute(body: string, slug: string): string {
  const root = `c:\\work\\${slug}`;
  return body.replaceAll("{root}", root).replaceAll("{slug}", slug);
}
```

こうすると、別プロジェクトを開いて slug が変わるだけで、同じ手順が新しい slug / root で出る。
root の組み立てルール（`c:\work\{slug}`）が変わってもここ1箇所を直せばよい。

## パネルの表示要件（UI）

- 対象画面（運営者が最初に触る画面）の**先頭**に置く。
- 番号付きのリスト or テーブルで、`# / 場所バッジ / 内容` を1行ずつ表示。
- `copyable` なステップは **Copy ボタン**を出し、押すと**置換後の本文**をクリップボードにコピーする（`{root}` 展開済みを渡す）。
- 説明文（`copyable` でない）はコピー不要。コマンド/実行文（`copyable`）は等幅表示で見分けられるようにする。
- スタイルは `features/ops-guide/` 内に閉じる（CSS Module 等）。**globals.css を触らない**（削除時の残骸防止）。

## 状態（空 / 通常）

- **slug 未選択**: 「プロジェクトを選択すると操作手順が表示されます」等の空状態を出す（クラッシュさせない）。
- **通常**: slug から root を組み立て、全ステップを置換して表示。

## testmaster を範とする出力イメージ

`ai-chat-interview` を開いたときに出る想定（各コマンドに Copy ボタン・場所タグ付き）:

| # | 場所        | 内容 / プロンプト                                                             |
|---|-------------|------------------------------------------------------------------------------|
| 1 | サイト      | Projects で「ai-chat-interview」を選択する                                    |
| 2 | サイト      | Context を記入して Save                                                       |
| 3 | Claude Code | ai-chat-interview のテスト項目を作って。対象コードは c:\work\ai-chat-interview |
| 4 | Claude Code | ai-chat-interview のAPI項目をテストして記録して                              |
| 5 | Claude Code | ai-chat-interview の画面項目をテストして記録して                            |
| 6 | Claude Code | ai-chat-interview のテスト台帳を対抗レビューして                            |
| 7 | Claude Code | 対抗レビューの指摘を反映して ai-chat-interview のテスト項目を作り直して。対象コードは c:\work\ai-chat-interview |

別プロジェクトを追加しても、そのプロジェクトを開けば slug と root が差し替わって同じ手順が出る。
