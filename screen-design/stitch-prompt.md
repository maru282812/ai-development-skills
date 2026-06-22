# Google Stitch プロンプト

更新日: 2026-06-22

## Global Design Context

EN:
Design a mobile-first app named CLEAN TOILET for people who feel anxiety about finding safe and usable restrooms outside. The product is not only a restroom map. It helps users decide where to go immediately using nearby search, station guidance, cleanliness, safety score, warning flags, stall count, restroom type, floor information, and photo step route cards.

Target users are people with urgent restroom anxiety, parents with children, older adults, travelers, contributors who post route photos, facility owners, sponsors, and operations staff.

Brand tone: practical, calm, clean, slightly pop and game-like after the urgent moment. The app blends real-world wayfinding with a light virtual badge/share-card feeling. During urgent use, keep the UI extremely direct and do not let ads or gamification compete with the path to a restroom.

Device strategy: Expo React Native for iOS and Android. Admin and sponsor application surfaces are web/desktop.

Accessibility: use readable labels, not color alone. Ensure long station names and facility names wrap safely. Main CTAs must be reachable and clear.

MVP scope: nearby search, emergency restroom, station search, station guide, restroom detail, photo step route card, photo step posting, restroom photo warning modal, lightweight state post, new location suggestion, report, admin moderation.

Ad policy: Sponsored content must be clearly labeled PR/Sponsored. Ads never affect cleanliness score, safety score, or ranking. Emergency mode must not show banners, cards, or interstitial ads; only small useful route markers are allowed.

JA補足:
- 最初の画面はLPではなく、実用画面にする
- `今すぐトイレ` を最短CTAとして目立たせる
- 現実の導線を邪魔しない範囲でポップな称号/SNSカードの余地を残す

## Screen Prompt: U-01 地図ホーム

EN:
Create a mobile map home screen. Show current location, restroom pins, safety score badges, cleanliness indicators, warning flags, a bottom candidate sheet, a large emergency CTA labeled "今すぐトイレ", station search entry, and a small "suggest missing restroom" action. Include states for location denied, no nearby restrooms, map loading, and network error. Sponsored route markers may appear as small labeled markers but never above safety information.

## Screen Prompt: U-02 今すぐトイレ

EN:
Create an urgent mode screen optimized for fast decision making. Show three to four large candidate cards: nearest, safest, likely available, and backup. Each card should show distance, time, floor, restroom type, stall count, cleanliness, safety score, and warning flags. The primary CTA is "案内開始". No banner ads, no full-screen ads, no decorative distractions. Include fallback to station search if location is denied or no results are found.

## Screen Prompt: U-05 駅攻略

EN:
Create a station guide screen. It should help users find restrooms by station, route line, platform direction, ticket gate, floor, inside/outside gate, and car-number hint. Show restroom candidates and nearby commercial-facility backup options. The screen should feel like a compact transit guide rather than a marketing page. Include missing car-number data and station data unavailable states.

## Screen Prompt: U-06 トイレ詳細

EN:
Create a restroom detail screen. Show safety score, cleanliness as a separate metric, warning flags, floor, inside/outside gate, male/female/shared/accessibility restroom types, stall count, photo step route preview, reviews, official/unconfirmed/source labels, and sponsor code below safety information. Include actions for route, post route, quick state update, report, sponsor code, and facility correction request.

## Screen Prompt: U-07 ルートカード閲覧

EN:
Create a photo-step route card viewer. Each step has a photo, direction chips, floor, landmark, and caution note. Include next/back controls, arrival action, quick state update, report action, and optional small sponsor route marker. Provide fallback display when photos are missing.

## Screen Prompt: U-08 写真ステップ投稿

EN:
Create a low-friction route photo posting flow. Use photo slots for one to three photos, start-point selector, direction chips, floor chips, landmark chips, restroom type chips, optional stall count, and crowding chips. Avoid long text fields. If any photo is marked as inside a restroom, show a required privacy confirmation modal before posting.

## Screen Prompt: A-01 管理ダッシュボード

EN:
Create a desktop web admin dashboard. Show queues for high-risk reports, photos awaiting review, new location suggestions, facility correction requests, sponsor inquiries, cost alerts, and unanswered support inquiries. Use dense but readable operational layout, with filters and clear next actions.

## Screen Prompt: A-08 外部サービス費用/アップロード先管理

EN:
Create a desktop admin cost and storage registry. Show service name, purpose, owner, billing account, official pricing URL, terms URL, last checked date, free tier, API limits, estimated monthly cost, actual cost, alert thresholds, upload storage bucket, region, visibility, retention period, and compression policy. Display threshold states at 70%, 85%, 100%, and 120%.

## Screen Prompt: A-12 法務/税務レビュー管理

EN:
Create a pre-release legal and tax review management screen. Show reviewed document, screen, version, review owner, reviewer type, comment, severity, required action, status, re-review required, due date, completion date. Public release should be blocked while high-severity items remain unresolved.

