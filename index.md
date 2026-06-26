---
layout: default
title: CibusSanus
---

# CibusSanus

**Программный модуль учёта продаж ресторана европейской кухни**

[CibusSanus — основной репозиторий](https://github.com/cherepenkintimur-ctrl/cibussanus) | [Скачать приложение](https://github.com/cherepenkintimur-ctrl/cibussanus/releases)

---

## Что это

Автономное кроссплатформенное приложение для учёта продаж ресторана. Работает без серверов и интернета — база данных SQLite встроена прямо в приложение и создаётся автоматически при первом запуске.

---

## Возможности

- **Категории блюд** — добавление, редактирование, удаление, поиск
- **Блюда** — полный CRUD, фильтрация по активности, привязка к категориям
- **Заказы** — создание, редактирование, удаление, автоматический расчёт суммы
- **Сортировка** — по имени, цене, дате, сумме, номеру и другим параметрам
- **Экспорт в Excel** — выгрузка категорий, блюд, заказов и отчётов в .xlsx
- **Отчёты** — выручка, средний/макс/мин чек, загруженность по часам, ТОП-10 блюд
- **Автономность** — не нужен PostgreSQL, сервер или интернет

---

## Скачать

| Платформа | Файл | Ссылка |
|---|---|---|
| Windows | exe | [Скачать](https://github.com/cherepenkintimur-ctrl/cibussanus/releases) |
| Android | apk | [Скачать](https://github.com/cherepenkintimur-ctrl/cibussanus/releases) |

Приложение полностью автономно — БД создаётся автоматически.

---

## Технологии

- **Flutter** — кроссплатформенный UI
- **Dart** — язык программирования
- **SQLite** — встроенная база данных
- **Material Design 3** — дизайн
- **Excel** — экспорт отчётов

---

## Запуск из исходников

```bash
git clone https://github.com/cherepenkintimur-ctrl/cibussanus.git
cd cibussanus
flutter pub get
flutter run
```

Требуется [Flutter SDK](https://docs.flutter.dev/get-started/install).

---

## Структура проекта

```
lib/
├── main.dart                    # Точка входа
├── database/
│   ├── db_service.dart          # SQLite + миграции + данные
│   └── db_queries.dart          # Запросы для отчётов
├── models/                      # Модели данных
├── repositories/                # DAO-слой
├── screens/
│   ├── database/                # Категории, блюда
│   ├── orders/                  # Заказы
│   ├── reports/                 # Отчёты
│   └── info/                    # Справка
├── services/
│   └── excel_export_service.dart
└── widgets/
    └── app_drawer.dart
```

---

## Как работает БД

При первом запуске приложение:

1. Создаёт файл `restaurant.db` в локальной папке
2. Создаёт таблицы: `categories`, `dishes`, `orders`, `order_items`
3. Заполняет seed-данными: 7 категорий, 75 блюд, 30 заказов

Все данные хранятся локально на устройстве.

---

## Автор

Черепенькин Тимур Антонович

Программный модуль «Учёт продаж ресторана европейской кухни»

2026
