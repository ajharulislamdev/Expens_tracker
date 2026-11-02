# Expense Tracker (Flutter 3.24 · GetX · Hive)

Fully offline expense tracker.

## Features
- Dashboard: Daily / Weekly / Monthly income, expense, balance, spending by category, recent items
- Transactions: add, edit, delete (swipe left, with Undo), search, filter by type / category / date range, sort by date or amount
- Reports: expense and income analytics, category breakdowns, and exports for a chosen period (**PDF** or **Excel**)
- Goals & budgets: create, edit, update progress, and delete savings goals and monthly budgets; plans are saved locally with Hive, and budget spending is entered manually
- Local account: create/sign in, edit profile details, change password, choose a local profile photo, sign out, or delete the profile
- Profile photos and account details are stored on-device in Hive; passwords are salted and hashed. Local sign-in does not encrypt transaction or plan data.
- Exports saved to `Download/ExpenseTracker` with a safe fallback

## Setup
This archive contains `lib/`, `pubspec.yaml` and config only. Create the platform folders first:

```bash
./setup.sh          # runs: flutter create ... && flutter pub get
```

Then add the permissions from `docs/AndroidManifest_snippet.xml` to
`android/app/src/main/AndroidManifest.xml` and run `flutter run`.

If you already have a project, copy `lib/` and `pubspec.yaml` into it and run `flutter pub get`.

## Architecture
```
View -> Controller (GetX) -> Repository -> HiveProvider -> Hive box
```
- `lib/app` bindings, routes, theme
- `lib/core` constants, utils, services (storage / pdf / excel)
- `lib/data` models + hand-written Hive adapters, provider, repository
- `lib/modules` home, transactions, reports (controllers / views / widgets)

No `build_runner` is needed: Hive adapters are written by hand.

## Export location logic (`StorageService`)
1. Try `/storage/emulated/0/Download/ExpenseTracker` (create + write test)
2. Request storage permission, retry
3. Request All-files access (Android 11+), retry
4. Fall back to the app's external folder (`Android/data/<package>/files/ExpenseTracker`) and tell the user

## Customising
- Currency: `AppConstants.currencySymbol` / `currencyCode`
- Categories: `AppConstants.expenseCategories` / `incomeCategories`
- PDF uses the built-in Helvetica font, so non-Latin text (e.g. Bengali) in titles will not render in the PDF. To support it, load a TTF (e.g. Noto Sans Bengali) with `pw.Font.ttf` and pass it to `pw.ThemeData.withFont`.
- Excel handles any language.

## Notes
- This code was written without a Flutter SDK in the build environment, so it has not been compiled here. If `flutter analyze` reports anything after `pub get`, send me the output and I'll fix it.
