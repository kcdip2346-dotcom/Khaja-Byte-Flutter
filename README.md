# Khājā Byte 🥟

Official canteen app of **ING College of Innovation and Leadership** — order food ahead, track bookings in real time, and pay with credit points.

Built with **Flutter** (app + web), powered by a **Python/Flask + SQLite** API backend.

## Features
- 🍛 Browse the daily canteen menu with live availability
- 🛒 Cart with **allergy-safe ordering** — remove specific ingredients per item
- 💳 Pay online (eSewa/Khalti placeholder), with credit points, or at the counter
- 🔔 Real-time booking status updates, queue wait estimates, and announcements
- 🎟️ Student, staff, and admin roles with separate dashboards
- 📊 Admin: revenue, transactions, menu management, users, feedback, and CSV-less reporting

## Tech stack
| Layer | Technology |
|---|---|
| Mobile + Web app | Flutter (Dart) |
| Backend API | Python 3, Flask, SQLite |
| Deployments | Vercel (web) · Render (API) · GitHub (source) |

## Demo accounts (one-tap login on the login screen)
- 👨🎓 Student — `student@ingcollege.edu.np` / `student123`
- 🧑🍳 Staff — `staff@ingcollege.edu.np` / `staff123`
- 🛡️ Admin — `admin@ingcollege.edu.np` / `admin123`

## Running locally
Backend:
```bash
cd khaja-byte
pip install -r requirements.txt
python3 app.py        # serves API on http://127.0.0.1:5001
```

Flutter web:
```bash
cd khaja-byte-flutter
flutter run -d chrome --dart-define=API_PORT=5001
```

Android APK (pointed at your machine's LAN IP):
```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=API_HOST=10.40.0.62 --dart-define=API_PORT=5001
```

Production web build (pointed at the Render API):
```bash
flutter build web --release \
  --dart-define=API_HOST=khaja-byte.onrender.com --dart-define=API_SCHEME=https
```
