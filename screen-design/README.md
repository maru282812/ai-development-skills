# Screen Design: CLEAN TOILET(仮)

更新日: 2026-06-22

このディレクトリは、`project-discovery/` の要件定義をもとにした画面設計成果物です。
実装コードではなく、Expo + React Native アプリ、Web管理画面、LP/スポンサー導線を実装する前の画面・状態・遷移・コンポーネント定義です。

## 画面設計の前提

- モバイルアプリ本体: Expo + React Native + TypeScript
- 管理画面/LP/スポンサー申込: Web
- 初期公開: iOS TestFlight 先行、Android クローズドテスト同時期開始
- 初期対象国: 日本のみ
- MVPの主体験: `今すぐトイレ`、現在地周辺検索、駅攻略、トイレ詳細、写真ステップ投稿
- 商業施設攻略: Phase1では代替候補表示、Phase2でフロア別攻略へ拡張
- 広告: 導線目印・スポンサーコードとして表示し、安心度/清潔度/ランキングには影響させない

## フェーズ別の読み方

| フェーズ | 画面の考え方 |
|---|---|
| Prototype | 操作感確認。主要導線だけをクリック可能にする |
| MVP Alpha | DB/投稿/管理をつなぎ、内部で使える状態にする |
| Closed Beta | 支援者・初期ユーザーが安全に試せる状態にする |
| Public Release | 一般公開に必要な通報、問い合わせ、法務同意、運用画面を整える |
| Phase2 | 投稿動機、SNS共有、称号、スポンサー価値、施設オーナー編集を強化する |
| Phase3 | 認定制度、複数施設、請求/契約、レポート、自治体/商業施設連携へ広げる |

## 成果物

- [screen-coverage-audit.md](screen-coverage-audit.md): 画面設計前の整合性監査
- [phase-screen-plan.md](phase-screen-plan.md): フェーズ別に増える画面と画面変更
- [screen-catalog.md](screen-catalog.md): 全画面マスター
- [user-screen-catalog.md](user-screen-catalog.md): 利用者/公開画面
- [admin-screen-catalog.md](admin-screen-catalog.md): 管理者/内部/施設側画面
- [user-flow-map.md](user-flow-map.md): 利用者・施設・管理者の画面遷移
- [requirement-screen-traceability.md](requirement-screen-traceability.md): 要件から画面への対応
- [screen-state-matrix.md](screen-state-matrix.md): 画面状態一覧
- [screen-specs.md](screen-specs.md): 主要画面仕様
- [component-inventory.md](component-inventory.md): 共通コンポーネント
- [design-system-brief.md](design-system-brief.md): UI/ビジュアル方針
- [stitch-prompt.md](stitch-prompt.md): Google Stitch用プロンプト
- [implementation-ui-brief.md](implementation-ui-brief.md): 実装引き渡し用UIブリーフ
- [ui-acceptance-checklist.md](ui-acceptance-checklist.md): UI完了判定
- [stitch-session.md](stitch-session.md): Stitch実行記録
- [stitch-review.md](stitch-review.md): Stitch出力レビュー
- [stitch-feedback-log.md](stitch-feedback-log.md): フィードバック反映ログ

