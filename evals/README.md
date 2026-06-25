# evals — Skill トリガー精度の評価

このディレクトリは、自作 Skill の **発火精度（should_trigger / should_not_trigger）** を検証するためのテストケースを置く場所です。

## 目的

- 兄弟 Skill（scope vs requirements、business vs operations、risk vs nfr など）の**誤発火**を抑える
- バンドル重複 Skill（`code-review` / `security-review`）が**汎用依頼で発火しすぎない**境界を確認する
- description 改善の前後で**トリガー精度の回帰**を検出する

## ファイル

- [evals.json](evals.json) — 12 Skill 分のテストケース案（should_trigger / should_not_trigger / expected_output / notes）

## 使い方（skill-creator 連携）

評価の実行は公式 **skill-creator** を使う前提です（手動評価より再現性・分散分析が得られる）。

```text
# 1. 例集プラグイン（skill-creator を含む）を導入
/plugin install example-skills@anthropic-agent-skills

# 2. skill-creator に本 Skill と評価を渡してトリガー精度を測定・description を最適化
#    （対象 Skill ディレクトリと evals/evals.json を指定）
```

> **要確認 / 形式の注意:** 本 `evals.json` は本リポジトリ独自のスキーマ（`skills[].should_trigger` 等）です。
> skill-creator 同梱の eval フォーマットと**キー名・構造が異なる可能性**があります。
> 導入後にまず skill-creator のテンプレート eval を1件出力させ、本ファイルをそのスキーマへ変換してから実行してください。
> （[work-log.md](../work-log.md) の「未確認事項」3 参照）

## 評価観点（4軸）

1. **trigger_precision** — 想定依頼で正しく発火するか
2. **exclusivity** — 兄弟 Skill の依頼で誤発火しないか
3. **boundary** — 公式バンドルに委ねるべき汎用依頼で発火しすぎないか
4. **output** — 期待される一次成果物が宣言どおりか

## メンテナンス方針

- Skill を新規作成・description 改修するたびに、対応するケースを `evals.json` に追加する。
- 兄弟 Skill を増やしたら、既存 Skill 側の `should_not_trigger` に新スキルの代表依頼を足す（相互排他の維持）。
