# 💰 MoneyMate

**Offline-first personal finance manager with built-in bill splitting.**
Built with Flutter, Riverpod, and Drift (SQLite). No cloud, no login, no AI API — just a fast, private, on-device finance tool.

---

## 📖 What is this?

MoneyMate merges two apps people usually juggle separately — a personal expense/budget tracker and a Splitwise-style bill splitter — into one offline app. Everything lives in a local SQLite database on your device. There's no backend, no account creation, and no data ever leaves your phone unless you manually export a backup.

## ✨ Features

- 💸 **Expense tracking** — categories, receipts, notes, search & filters, soft delete with undo
- 💰 **Income tracking** — multiple sources (salary, freelance, business, etc.)
- 🤝 **Bill splitting** — groups, members, equal/exact/percentage splits, automatic debt simplification ("who owes whom")
- 🎯 **Savings goals** — target amounts, contribution history, optional cover photo
- 📊 **Budgets** — per-category monthly limits with 80/90/100% alerts
- 📈 **Analytics & rule-based insights** — no AI/LLM calls, just local calculations (month-over-month trends, budget pace, savings rate)
- 🏦 **Optional multi-account support** — off by default; toggle on in Settings if you track Cash/Bank/Card separately
- 🔁 **Recurring transactions** — rent, subscriptions, salary — with catch-up logic if the app hasn't been opened in a while
- 🔒 **Local app-lock** — optional PIN/biometric lock, purely on-device (not cloud auth)
- 💾 **Encrypted JSON backup/restore** — your manual, offline alternative to cloud sync

## 🚫 What this is explicitly NOT

- No Firebase, no cloud sync, no server of any kind
- No login/authentication — single-user, single-device by design
- No Gemini or any AI/LLM-powered features — insights are deterministic, local calculations

These are permanent architectural decisions, not gaps to be filled in later.

## 🏗 Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| State management | flutter_riverpod |
| Routing | go_router |
| Local database | drift (SQLite) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |

## 📂 Project Structure

```
lib/
├── main.dart
├── core/                  # theme, router, shared widgets, utils
├── data/
│   ├── local/
│   │   ├── database.dart       # Drift schema (18 tables)
│   │   └── connection.dart     # SQLite connection setup
│   ├── repositories/            # all business logic — UI never touches Drift directly
│   │   ├── expense_repository.dart
│   │   ├── income_repository.dart
│   │   ├── group_repository.dart       # bill-splitting core + debt simplification
│   │   ├── budget_repository.dart
│   │   ├── savings_goal_repository.dart
│   │   ├── account_repository.dart
│   │   ├── recurring_rule_repository.dart
│   │   ├── category_repository.dart
│   │   ├── split_calculator.dart       # pure split-math, no DB dependency
│   │   ├── backup_service.dart         # encrypted JSON export/import
│   │   └── seed_service.dart           # first-launch default data
│   └── providers/                # Riverpod providers wiring repositories to UI
└── features/              # one folder per screen area (expenses, income, split, etc.)
```

## 🚀 Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

See [`SETUP.md`](./SETUP.md) for a more detailed first-time setup walkthrough.

## 📚 Project Docs

Full planning documentation lives in [`docs/`](./docs):

| Doc | Contents |
|---|---|
| [`prd.md`](./docs/prd.md) | Product vision, goals, non-goals, feature priorities |
| [`architecture.md`](./docs/architecture.md) | Layering, data flow, testing strategy |
| [`rules.md`](./docs/rules.md) | Binding coding conventions and scope guardrails |
| [`phases.md`](./docs/phases.md) | Development timeline and milestones |
| [`design.md`](./docs/design.md) | Design system — colors, icons, navigation, components |
| [`memory.md`](./docs/memory.md) | Running decision log — read this first before making changes |

## ✅ Status

- [x] Phase 1 — Drift schema (18 tables), clean compile
- [x] Phase 2 — Full repository layer + Riverpod providers (Expense, Income, Category, Group/Split, Budget, Savings, Account, Recurring)
- [ ] Phase 3 — UI screens
- [ ] Phase 4 — Testing & polish
- [ ] Release

## 👤 Developer

**AngelRider** — solo Flutter developer.

## 📄 License

Personal project — license TBD.