<p align="center">
  <img src="docs/banner.png" alt="Sakina — аяты и хадисы" width="100%">
</p>

<h1 align="center">Sakina — аяты и хадисы</h1>

<p align="center">
  iOS-приложение, которое в нужный момент приносит нужные слова —<br>
  аят из Корана или хадис Пророка (мир ему).
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-2B261F?style=flat-square" alt="iOS 17+">
  <img src="https://img.shields.io/badge/SwiftUI-WidgetKit-2B261F?style=flat-square" alt="SwiftUI · WidgetKit">
  <img src="https://img.shields.io/badge/license-MIT-2B261F?style=flat-square" alt="MIT">
</p>

<p align="center">
  <img src="docs/screenshots/01-cover.png" width="15%">
  <img src="docs/screenshots/02-main.png" width="15%">
  <img src="docs/screenshots/03-mood.png" width="15%">
  <img src="docs/screenshots/04-hadith.png" width="15%">
  <img src="docs/screenshots/05-widget.png" width="15%">
  <img src="docs/screenshots/06-reminders.png" width="15%">
</p>

## Возможности

- **Аят или хадис дня** — арабский текст, перевод на русский и источник.
- **«Как ты сейчас?»** — выбери состояние и получи подходящий текст.
- **Источники** — нажатие открывает аят на quran.com, хадис на sunnah.com.
- **Напоминания** — 1, 3 или 5 в день, без сервера и интернета.
- **Виджеты** — для главного экрана и экрана блокировки.
- **Поделиться** — текстом в любой мессенджер или карточкой в галерею.
- Без рекламы, регистрации и сбора данных.

Все хадисы — из сборников аль-Бухари и Муслима. Тексты находятся в [`Shared/Verse.swift`](Shared/Verse.swift).

## Сборка

1. Открыть `Sakina.xcodeproj` в Xcode.
2. В **Signing & Capabilities** выбрать свою команду для целей `Sakina` и `SakinaWidgetExtension`.
3. Запустить на iPhone или симуляторе (iOS 17+).

## Лицензия

Код — [MIT](LICENSE). Шрифты Amiri — [SIL OFL 1.1](Shared/Fonts/OFL.txt).
