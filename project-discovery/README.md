# CLEAN TOILET Project Discovery

更新日: 2026-06-21

このディレクトリは、CLEAN TOILET(仮) の要件定義とプロジェクト発見の成果物です。

## 現在の位置づけ

- Phase 1 Scope Discovery: 駅・施設・街の安心トイレ攻略へ再整理済み
- Phase 2 Requirements Discovery: 写真ステップ投稿、今すぐトイレ、スポンサー導線を反映済み
- Phase 3 UX Discovery: 最短利用、投稿、スポンサー表示の導線を反映済み
- Phase 4 Admin Discovery: 投稿管理に加えスポンサー管理、施設情報修正/オーナー申請管理、外部サービス費用/アップロード先管理を反映済み
- Phase 5 Business Discovery: 導線広告・スポンサーコード・公式情報掲載・エリア協賛の事業仮説を追加済み
- Phase 6 以降: コスト上限、データ正本、外部サービス管理、アップロード先管理を反映済み。残論点は `open-questions.md` に集約

## このプロジェクトの一言説明

外出時にトイレへの不安を抱える人が、駅・施設・街のトイレまでの行き方、写真ステップ、混雑、個室数、清潔度、安心度をもとに「今すぐ行ける安心候補」を判断できる安心トイレ攻略アプリ。

## 推奨する初期方針

- MVP は `今すぐトイレ` から最短候補・安心候補・代替候補を出す体験に絞る。
- 投稿は長文レビューではなく、写真ステップ式ルートカードと選択式チップを中心にする。
- Phase1は現在地周辺検索と駅攻略を勝ち筋にする。号車、改札、階数、個室数、混雑注意、代替施設が価値になる。
- トイレ内写真は必須にせず、投稿する場合は毎回確認ポップを表示し、公開前自動スキャンの対象にする。
- 投稿型サービスなので、MVP でも最低限の通報・非公開化・管理画面は必要。
- 広告はバナーではなく、導線の目印・スポンサーコード・エリア協賛として扱う。
- 施設情報修正/オーナー申請はMVP候補、施設オーナー簡易編集はPhase2、請求/契約管理はPhase3以降に回す。
- 掲載料・広告料は、企業ごとの個別交渉ではなくプラン種別×掲載期間で一律算出する。海外向けは地域別価格表を用意する。
- 緊急時の利用では広告を邪魔にしない。広告と安心度評価は混ぜない。
- Google Maps Platform等の料金、無料枠、API制限、商用利用条件、アップロード先、月額見込み/実績は管理画面で確認できるようにする。
- MVP一般公開時の外部サービス月額上限は50,000円、先行ベータは30,000円目安にする。
- 駅構内図、駅設備、商業施設トイレ情報、号車情報は公式情報を正にし、投稿は現地補足・更新提案・実体験として扱う。
- 初期リリース対象国は日本国内のみ。海外は将来対応できるデータ構造だけ残す。
- 初期は日本全国/全世界の全量取り込みをせず、日本国内の対象駅、路線、エリア単位で段階投入する。初期対象エリアは関東を主対象にし、大阪・福岡は空港/主要駅ハブに絞る。海外は国/都市/データ種別ごとに信頼度を分ける。
- 問い合わせはメールと管理画面で受け、AIが分類・返信下書き・類似回答検索を補助し、人間が最終確認する。
- 問い合わせ回答は、承認済み回答ナレッジとして蓄積し、次回以降の回答候補に使う。
- 支援者リターンは必要最小限の個人情報で管理し、名前掲載・店舗掲載・スポンサー掲載は任意の個別同意と公開前プレビューを必須にする。
- 削除/変更依頼の「原則5営業日以内」は運営内部の対応目標にし、ユーザー向けには「受付済み」「対応中」「対応完了」の状態だけを表示する。
- 正式公開前に、法務は弁護士、税務/会計は税理士へレビュー依頼し、指摘と対応状況を管理画面またはIssueで残す。
- スマホアプリは Expo + React Native + TypeScript を第一候補にする。
- DB / 認証 / 画像保存 / 位置検索は Supabase を第一候補にする。
- 地図は初期は Google Maps Platform を第一候補にし、費用と利用規約を早期確認する。

## 主な成果物

- [scope/scope.md](scope/scope.md): スコープ入口
- [scope/mvp-boundary.md](scope/mvp-boundary.md): MVP境界
- [requirements/requirements.md](requirements/requirements.md): 要件定義入口
- [requirements/requirements-checklist.md](requirements/requirements-checklist.md): 要件チェックリスト
- [requirements/screen-catalog-draft.md](requirements/screen-catalog-draft.md): 画面カタログ草案
- [user-flows.md](user-flows.md): 利用者導線
- [admin-flows.md](admin-flows.md): 管理者導線
- [data/data.md](data/data.md): データ正本、取得元、海外精度、データ量対策
- [integration/external-services.md](integration/external-services.md): 外部サービス連携と費用管理
- [nfr/cost-constraints.md](nfr/cost-constraints.md): 維持費・API制限・アップロード制約
- [operations/operations.md](operations/operations.md): 運営設計
- [operations/operator-roles.md](operations/operator-roles.md): 運営者・管理者・サポートの役割
- [operations/operational-workflows.md](operations/operational-workflows.md): 運用ワークフロー
- [operations/support-process.md](operations/support-process.md): 問い合わせ・異常時対応
- [operations/content-management.md](operations/content-management.md): 回答ナレッジ等の更新管理
- [operations/operational-metrics.md](operations/operational-metrics.md): 運営KPI
- [operations/runbook-summary.md](operations/runbook-summary.md): 運営開始手順
- [business/business-model.md](business/business-model.md): 事業モデル
- [business/revenue.md](business/revenue.md): 収益構造
- [implementation-brief.md](implementation-brief.md): 実装前ブリーフ
- [decisions.md](decisions.md): 決定・保留・仮置きログ
- [open-questions.md](open-questions.md): 未確定事項

## 注意

このドラフトでは、ユーザーが明示した内容以外は `仮置き(assumption)` として扱う。画面設計・DB設計・実装に進む前に、`open-questions.md` の上位項目を順番に確定する。
