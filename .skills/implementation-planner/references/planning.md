# 実装計画リファレンス

implementation-planner スキルの Step 5(Phase分け)・Step 7(実装指示文)で参照する。

## 目次

1. [Phase 分けの原則](#1-phase-分けの原則)
2. [Next.js + Supabase の標準実装順序](#2-nextjs--supabase-の標準実装順序)
3. [AIエージェント向け指示文の書き方](#3-aiエージェント向け指示文の書き方)

---

## 1. Phase 分けの原則

- **1 Phase = 単独で動作確認できる単位**にする。「DBだけ作って終わり」でも `supabase db reset` が通れば確認可能なので1 Phaseとして成立する
- **依存の向きを一方向にする**。後の Phase が前の Phase の成果物だけに依存するように並べる。循環依存がある場合は分割粒度が間違っているサイン
- **リスクの高いものを先に**。RLS設計や認可方式など、後から変えると全体に波及するものは Phase 1 に置く
- **1 Phase の粒度はAIエージェントの1セッションで完了できる量**を目安にする(目安: 変更ファイル5個以内、新規テーブル2個以内)
- 既存機能の改修を含む場合、**「既存挙動を壊していないことの確認」を独立した完了条件**として各 Phase に入れる

## 2. Next.js + Supabase の標準実装順序

```text
Phase 1: DB(migration + RLS)
  └ supabase/migrations/*.sql、RLSポリシー、seed
Phase 2: 型定義
  └ database.types.ts 再生成、ドメイン型、zodスキーマ
Phase 3: データアクセス / Server Actions / Route Handler
  └ lib/ 配下のクエリ関数、API実装、バリデーション
Phase 4: UI
  └ 画面、コンポーネント、フォーム、エラー/ローディング表示
Phase 5: 動作確認・テスト
  └ 権限別の確認、回帰確認(test-planner の観点を流用)
```

順序を入れ替えてよいケース:

- UIモックを先に見せて仕様確定したい → Phase 1 をダミーデータUIにする
- 既存テーブルのみ使う → Phase 1 を省略
- 外部API連携が主 → 連携部分の疎通確認を最初の Phase にする

各 Phase の中身を具体化する際の参照先:

- DB: [db-designer](../../db-designer/SKILL.md)
- API: [api-designer](../../api-designer/SKILL.md)
- migration の安全性: [migration-review](../../migration-review/SKILL.md)
- テスト観点: [test-planner](../../test-planner/SKILL.md)

## 3. AIエージェント向け指示文の書き方

Codex / Claude Code に渡す指示文は、以下の構成にすると手戻りが少ない。

```md
## 目的
(1〜2文。何のための変更か)

## 前提
- スタック: Next.js (App Router) + Supabase
- 既存の関連ファイル: (パスを列挙。「探させる」より「教える」方が確実)
- 既存の実装パターン: (例: Supabaseクライアントは lib/supabase/server.ts の createClient を使う)

## やること
1. (具体的な手順。ファイルパス付き)
2. ...

## やらないこと
- (スコープ外を明示。例: UIの変更はしない、既存APIのレスポンス形式は変えない)

## 完了条件
- [ ] (検証コマンドや確認手順。例: npm run build が通る、/admin/users で一覧が表示される)
```

指示文作成時の注意:

- **ファイルパスは必ず具体的に書く**。「適切な場所に」はエージェントごとに解釈が割れる
- **既存パターンの参照先を1つ指定する**(例: 「app/api/users/route.ts と同じ構成で」)。ゼロから書かせると流儀が混ざる
- **やらないことを明示する**。エージェントは頼んでいない「ついで修正」をしがち
- migration を含む指示では「`supabase db reset` で確認」まで完了条件に含める
- 複数 Phase を一度に渡さない。1指示文 = 1 Phase
