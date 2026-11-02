---
name: development-router
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Skill
metadata:
  reasoning-tier: standard
  summary: "全開発スキルの司令塔。依頼を分類し、ai-development-skills の専門スキル本文を必要な分だけ読み込んで作業する。"
description: >-
  開発作業の司令塔ルーター。開発系の依頼では最初に必ずこのスキルを起動する。
  対象: 要件定義・スコープ確定・MVP分割・実装計画・実装指示文/仕様書作成・
  バグ/エラー調査・影響範囲/使用箇所調査・データフロー追跡・コードレビュー・
  セキュリティレビュー・敵対的レビュー・リファクタ計画・DB設計・API設計・
  画面設計・UI/UXレビュー・テスト計画・testmaster（項目生成/API/画面/対抗レビュー/全周回）・
  project-discovery 全フェーズ（scope/requirements/screen/integration/business/operations/
  legal/contract/risk/metrics/nfr/data）・壁打ち（アイデア精査）・git初期化・
  品質ツーリング・引き継ぎ資料・プロンプト設計・ディスパッチ方式構築 など開発全般。
  トリガー例: 「要件を洗い出して」「実装計画を立てて」「実装して」「指示文を作って」
  「エラー調査して」「動かない」「レビューして」「テーブル設計して」「API設計して」
  「テスト項目を作って」「testmaster を回して」「壁打ち」「discovery を進めて」
  「どこで使われてる?」「このデータどこから来てる?」「リファクタしたい」「git作成」。
  迷ったら起動してよい。インデックスを読んで該当が無ければ通常対応に戻る。
---

# development-router（開発スキルの司令塔）

依頼を分類し、`C:\work\ai-development-skills\.skills\` にある専門スキルのうち
**必要な1〜2個だけ** を読み込んで、その手順に従って作業する。
41個以上のスキル概要を毎セッション読み込む代わりに、このルーター1個で代表する。

## 手順

1. **インデックスを読む**
   `C:\work\ai-development-skills\.skills\development-router\skills-index.md` を Read する。
   （無ければ `C:\work\ai-development-skills\.skills\` を ls して frontmatter から判断する）

2. **依頼を分類し、スキルを最大2個選ぶ**
   - インデックスの summary / トリガー例と照合する。
   - 3個以上は選ばない。迷ったら主担当1個に絞る（本文内の参照で必要になれば後から読む）。
   - どれにも該当しなければ、このルーターを離れて通常対応する。

3. **選んだスキルの本文を読み、従う**
   `C:\work\ai-development-skills\.skills\<name>\SKILL.md` を Read し、
   その内容を「いま起動されたスキル」として扱い、手順・停止ゲート・出力形式に従う。

## ルール

- **Skill ツールでこれらのスキルを呼ばない。** グローバル/プロジェクトに登録されていないため失敗する。必ず上記パスを Read して本文に従う。
- **スキル間参照も Read で解決する。** 本文中の `[[skill-name]]` や「〜スキルを使う」という指示は、`C:\work\ai-development-skills\.skills\<skill-name>\SKILL.md` を Read して従う（testmaster-run-all のようなオーケストレータも同様）。
- **プロジェクトローカルのスキルが優先。** 現在のプロジェクトに同じ目的のスキルが登録されている場合（例: ai-tube の aitube-run、ai-person の persona-predict、ai-servey の discovery-brief-writer / discovery-procedure-analyzer）は、そちらを Skill ツールで起動する。
- **インデックスに無い名前を発明しない。** 該当スキルが見つからなければ通常対応でよい。
- スキル本文が見つからない・インデックスと食い違う場合は `.skills/` を ls して現物を確認し、必要なら `node scripts/generate-skill-index.mjs` の再実行をユーザーに提案する。

## メンテナンス（ai-development-skills 側の作業）

- スキルを追加・改名・説明変更したら `node scripts/generate-skill-index.mjs` で index を再生成する。
- このルーターのグローバル登録は `~/.claude/skills/development-router/` のコピー。ルーター本文を変えたらコピーも更新する（index はマスター側を直接読むためコピー不要）。
