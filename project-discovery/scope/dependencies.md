# 外部依存

更新日: 2026-06-20

| 依存先 | 用途 | 必須/任意 | 状態 | 引き渡し先 |
|---|---|---|---|---|
| Supabase | DB、認証、画像保存、位置検索候補 | 必須候補 | 仮置き | data / integration / nfr |
| PostGIS | 近い順検索、地図表示範囲内検索 | 必須候補 | 仮置き | data / integration |
| Google Maps Platform | 地図表示、位置検索、Places候補 | 必須候補 | 仮置き | integration / nfr |
| Google Maps Platform Pricing / Terms | 料金、無料枠、API制限、商用利用条件の確認 | 必須候補 | 要確認 | integration / nfr / operations |
| 駅/施設公式情報 | 駅構内・施設内トイレ情報、階数、改札内/外、号車情報 | 必須候補 | 方針決定・利用許諾要確認 | data / integration / legal |
| GTFS / GTFS Pathways | 駅、ホーム、出入口、構内ノード、階層、乗車位置候補 | 海外/交通データ候補 | 候補 | data / integration |
| OpenStreetMap | 公衆トイレ、施設内トイレ候補、海外候補データ | 任意候補 | 候補・ライセンス要確認 | data / integration / legal |
| Google Places | `public_bathroom` 等の候補地点、施設候補 | 任意候補 | 候補・料金/規約要確認 | data / integration / nfr |
| 画像圧縮/ぼかし処理 | 写真ステップ投稿の容量・人物映り込み対策 | 必須候補 | 方針決定・実装手段要確認 | nfr / legal / operations |
| 画像モデレーション/顔検出 | 公開前自動スキャン、顔ぼかし、確認待ち判定、通報優先度付け | 必須候補 | 方針決定・実装手段要確認 | integration / nfr / legal / operations |
| 広告/スポンサー計測 | 表示数、タップ数、コード表示数の記録 | MVP候補 | 仮置き | business / operations |
| Stripe | B2B掲載料・スポンサー枠の請求候補 | Phase2候補 | 仮置き | integration / business / contract |
| RevenueCat | 一般ユーザー向けアプリ内課金を導入する場合の候補 | 将来候補 | 仮置き | integration / business / legal |
| Apple App Store | iOS配布、TestFlight | 必須候補 | 仮置き | operations / legal |
| Google Play | Android配布 | 必須候補 | 仮置き | operations / legal |
| Expo Application Services | ビルド、配布、OTA更新 | 任意候補 | 仮置き | nfr / operations |
| ドメイン/LP/管理画面ホスティング | LP、スポンサー申込導線、管理画面公開 | 必須候補 | 要確認 | integration / nfr / operations |
| 通知/メール | 注意通知、問い合わせ、スポンサー連絡 | 必須候補 | 要確認 | integration / operations |
| メール送受信/問い合わせ管理 | 問い合わせ受付、受信確認、管理者通知、返信履歴 | MVP候補 | 方針決定・サービス選定要確認 | integration / operations / legal |
| AI問い合わせ補助 | 問い合わせ分類、優先度付け、類似回答検索、返信下書き | MVP候補 | 方針決定・実装手段要確認 | operations / data / legal / risk |
| 監視/ログ | 障害把握、費用監視、管理操作ログ | 必須候補 | 要確認 | nfr / operations |
| クラウドファンディング平台 | 支援募集、リターン提供 | 必須 | ユーザー計画あり | business / operations / contract |
| SNS | 投稿カード、称号カード、施設紹介、拡散 | 任意 | Phase2候補 | business / operations |

## 公式情報確認メモ

- React Native は Android / iOS 向けのネイティブアプリ開発に使える。公式サイトでは新規アプリに Expo などのフレームワーク利用を推奨している。
- Expo は JavaScript / TypeScript プロジェクトから Android / iOS / Web に展開でき、アプリストア配布やOTA更新の導線を持つ。
- Supabase は Postgres、Auth、Storage、Realtime、Edge Functions を提供し、Swift / Kotlin / Expo React Native / Flutter 向けの導線がある。
- Supabase の PostGIS は位置情報の近傍検索や地図表示範囲内検索に使える。
- Google Maps Platform、Supabase、Expo/EAS等の料金・無料枠・API制限・商用利用条件は変わるため、公式URLと確認日を管理画面で管理する。
- Apple Developer Program、Google Play Console、Stripe、RevenueCat、AI画像処理、通知、ホスティング、監視/ログも維持費管理の対象にする。
- 駅構内図、駅設備、商業施設トイレ情報、号車情報は公式情報を正にする。GTFS、Google Places、OpenStreetMapは初期候補や照合には使うが、正本としては扱わない。
- GTFSは駅、ホーム、出入口、構内ノード、乗車位置候補を表現できるが、トイレ詳細の有無は事業者ごとの提供データに依存する。
- OpenStreetMapは公衆トイレや施設内トイレ候補に使えるが、地域差とタグ揺れがあるため、海外展開では国/都市単位で信頼度を分ける。
- Flutter は単一コードベースで iOS / Android / Web / Desktop に展開できる。
- Swift は Apple プラットフォームで高速・安全に動くが、Android は別実装が必要になる。

参照:
- https://reactnative.dev/
- https://docs.expo.dev/
- https://supabase.com/docs
- https://supabase.com/docs/guides/database/extensions/postgis
- https://flutter.dev/development
- https://developer.apple.com/swift/
- https://developers.google.com/maps/documentation
- https://gtfs.org/documentation/schedule/reference/
- https://developers.google.com/maps/documentation/places/web-service/place-types
- https://wiki.openstreetmap.org/wiki/Tag:amenity%3Dtoilets
- https://mapsplatform.google.com/pricing/
- https://supabase.com/docs/guides/platform/billing-on-supabase
- https://expo.dev/pricing
- https://developer.apple.com/programs/
- https://play.google.com/console/about/
