# eval-kit

AI出力の **回帰テスト** キット。承認済みの正解（golden）と実出力を自動照合する。
このフォルダを **まるごとプロジェクトにコピペ** して使う。

## なぜこの形か（設計の核）

- **一人で全部チェックできない** → 人間が一度承認した golden と機械が照合する。
- **「同じ脳みそだとテストの意味がない」** → 2段で断つ:
  1. できる限り **決定論アサーション**（分岐・フラグ・構造はLLMを通さない）。
  2. 自由回答だけ **Judge分離**（被験と別系統のモデルで採点 / 根拠引用を強制）。

## フォルダ構成（エンジンとケースの分離）

```
eval-kit/
├─ promptfooconfig.yaml          ← エンジン（汎用・公式化したら触らない）
├─ judge/rubric.md               ← 採点プロンプト（根拠引用を強制）
├─ prompts/under-test.md         ← ★被験プロンプト（mode B の検証対象。project固有）
├─ cases/
│   ├─ _template.golden.yaml.example   ← 空テンプレ（コピー元）
│   └─ <機能名>.golden.yaml            ← ★プロジェクト固有（差し替え対象）
└─ scripts/run.ps1 | run.sh      ← npx promptfoo eval のラッパ
```

**コピペ後に触るのは `cases/`・`judge/rubric.md`・`prompts/under-test.md` だけ。**
エンジン（`promptfooconfig.yaml`）は原則そのまま。
（mode A = アプリAPIを叩く場合、`prompts/under-test.md` は未使用。）

## 使い方

1. `ANTHROPIC_API_KEY` を環境変数に設定（被験・Judge両方が使う）。
2. `promptfooconfig.yaml` の `providers` を、テスト対象に合わせて設定:
   - (A) アプリのAPIを叩いて実出力を検証（推奨）
   - (B) 生のモデルを直接検証
3. `cases/_template.golden.yaml.example` を `cases/<機能名>.golden.yaml` にコピーし、
   ケースを書く。**期待出力は人間が承認してから確定**する（この承認が唯一の正解固定工程）。
4. 実行:
   - Windows: `./scripts/run.ps1`
   - その他: `./scripts/run.sh`
   - 結果閲覧: `npx promptfoo@latest view`

## アサーションの使い分け

| 種類 | 使うもの | 例 |
|---|---|---|
| 分岐 / フラグ / 定型文 | `contains` `not-contains` `equals` `regex` | 公式案件フラグONで免責文が入る |
| 構造 | `is-json`（スキーマ可） | `{answer, followup}` を返す |
| ロジック | `javascript` | 文字数・件数などの数値条件 |
| 自由回答の質 | `llm-rubric`（Judge分離） | 深掘り質問が的確で誘導的でない |

迷ったら **決定論側に寄せる**。LLM判定は本当に自由な部分だけに使う。

## 公式化の流れ

アンケート用に `cases/survey.golden.yaml` を育てる → 汎用パターンが見えたら
`_template.golden.yaml.example` に逆輸入 → 以後どのプロジェクトでも同じ枠で書ける。
