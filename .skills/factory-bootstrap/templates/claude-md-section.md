## 製造ループ

このリポジトリは共通の製造ループ（Loop Engineering）で開発する。基盤の canonical は
`C:\work\ai-development-skills\.skills\`（factory-bootstrap / phase-runner / verification-loop）。

- **検証レシピ**: `docs/VERIFY.md` が唯一の真実。実装後は必ず §1 Gates を緑にし、
  §2 Runtime Verify（ユーザーから見て動くか）まで確認する。
- **大型実装（4 Phase 以上）**: 実装指示書を作ってから phase-runner で自走する。
  進捗は `phase-status.md` に永続化し、各 Phase は Gates → Runtime Verify → 独立 Checker →
  Receipt（証拠付き記録）を経てから次へ進む。
- **保守**: `/loop` の巡回内容は `.claude/loop.md` に従う。
- **Human Gate**: `docs/VERIFY.md` §4 に該当する変更（DB migration・認証認可・課金・
  個人情報・本番環境・破壊的操作・デプロイ）は自動で完結させず、必ず人間の判断を挟む。
