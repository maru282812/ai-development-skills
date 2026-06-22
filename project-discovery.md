# CLEAN TOILET 要件定義入口

更新日: 2026-06-20

このファイルは、`project-discovery` 方式で作成した要件定義の入口です。詳細な成果物は [project-discovery/README.md](project-discovery/README.md) 以下に分割して管理します。

## 現時点の推奨結論

- プロダクトの軸: 「トイレ検索アプリ」ではなく、駅・施設・街の **安心トイレ攻略アプリ**
- 最短体験: アプリ起動後に `今すぐトイレ` を押すだけで、最短候補・安心候補・代替候補を出す
- MVP: 現在地/駅名検索、地図表示、トイレ詳細、写真ステップ式ルート投稿、清潔度/安心度、混雑・個室数などの軽量投稿、通報、最低限の管理画面
- 投稿体験: 文章入力ではなく「写真 + 選択式チップ」でルートカードを作れるようにする。トイレ内写真は投稿前に毎回確認ポップを表示する
- 収益仮説: 施設掲載単体ではなく、導線の目印広告・スポンサーコード・公式情報掲載・エリア協賛・公式ルートカードで企業から収益化する
- 掲載/広告料金: 企業ごとの個別交渉ではなく、プラン種別×掲載期間で一律算出する。海外向けは地域別価格表で通貨・税を調整する
- 維持費管理: Google Maps Platform等の料金・無料枠・API制限・商用利用条件と、画像等のアップロード先を管理画面で確認できるようにする
- MVP月額上限: 先行ベータは30,000円/月目安、一般公開MVPは50,000円/月上限。70%注意、85%警告、100%運営確認、120%高コスト機能制限
- データ方針: 駅構内図・駅設備・商業施設トイレ情報・号車情報は公式を正にし、投稿は現地補足・更新提案・実体験として扱う
- 初期対象国: 日本国内のみ。海外は将来対応できるデータ構造だけ残す
- データ量対策: 日本全国/全世界全量ではなく、日本国内の対象駅・路線・エリア単位で段階投入する。海外は国/都市/データ種別ごとに信頼度を分ける
- 運営体制: 問い合わせはメールと管理画面で受け、AIが分類・返信下書き・類似回答検索を補助し、人間が最終確認する
- 回答ナレッジ: 人間またはAIが作成した回答を承認済みナレッジとして蓄積し、次回以降の回答候補に使う
- 初期技術: Expo + React Native + TypeScript
- DB/BaaS: Supabase
- 位置検索: Supabase PostGIS
- 地図: Google Maps Platform を第一候補
- 管理: Web管理画面
- Git: `main` + `feature/*` + tag から開始し、必要に応じて `develop` / `release/*` を追加

## 重要な未決事項

最初の攻略対象は、現在地周辺検索 → 駅攻略 → 商業施設攻略の優先順位で進める方針に決定済みです。Phase1では現在地周辺検索と駅攻略を入れ、商業施設はフル攻略ではなく代替候補として基本表示します。

次に決めるべきことは「スポンサー表示ルール」です。緊急時、通常時、投稿後、SNS共有時で、導線広告・関連広告・スポンサーコードの表示量をどう分けるかを確定する必要があります。アフィリエイトリンクは扱わない方針です。

駅・施設データについては「公式を正」にする方針が決定済みです。初期リリースは日本国内のみで進めます。残る論点は、公式構内図や商業施設マップの転載・保存・加工に必要な利用許諾、日本国内の初期対象駅/路線/エリア、海外対応を開始する条件、運営の最終承認者・緊急停止権限者、支援者リターン/個人情報管理です。詳細は `open-questions.md` の9件に集約しています。

## 広告/スポンサーの原則

- 広告はバナーではなく、導線の目印・スポンサーコード・エリア協賛として扱う
- 掲載料・広告料はプラン種別×掲載期間で一律算出する
- スポンサーコードは、コード表示数を主指標、タップ数を補助指標、自己申告利用数を成果推定、店舗報告を任意の補助指標にする
- トイレの安全情報・最短案内より広告を優先表示しない
- 緊急時モードでは広告を非表示または最小化する
- 安心度・清潔度・ランキングは広告で買わせない
- `Sponsored` / `PR` 表記を明確にする

## 成果物

- [Project Discovery README](project-discovery/README.md)
- [スコープ](project-discovery/scope/scope.md)
- [MVP境界](project-discovery/scope/mvp-boundary.md)
- [要件定義](project-discovery/requirements/requirements.md)
- [要件チェックリスト](project-discovery/requirements/requirements-checklist.md)
- [画面カタログ草案](project-discovery/requirements/screen-catalog-draft.md)
- [利用者導線](project-discovery/user-flows.md)
- [管理導線](project-discovery/admin-flows.md)
- [外部サービス連携](project-discovery/integration/external-services.md)
- [データ発見](project-discovery/data/data.md)
- [コスト制約](project-discovery/nfr/cost-constraints.md)
- [運用ワークフロー](project-discovery/operations/operational-workflows.md)
- [運営設計](project-discovery/operations/operations.md)
- [サポート・異常時対応](project-discovery/operations/support-process.md)
- [実装前ブリーフ](project-discovery/implementation-brief.md)
- [事業モデル](project-discovery/business/business-model.md)
- [収益構造](project-discovery/business/revenue.md)
- [意思決定ログ](project-discovery/decisions.md)
- [未確定事項](project-discovery/open-questions.md)
