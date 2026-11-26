# EdgePulse Scanner — اپلیکیشن اندرویدی اسکنر پروکسی آی‌پی کلودفلر (Go + Flutter)

![Platform](https://img.shields.io/badge/Platform-Android%20(API%2024%2B)-00E676?style=flat-square)
![Core](https://img.shields.io/badge/Core-Go%201.23%20(gomobile)-00ADD8?style=flat-square)
![UI](https://img.shields.io/badge/UI-Flutter%203.24%20%2F%20Dart-02569B?style=flat-square)
![CI](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20APK-2088FF?style=flat-square)

**EdgePulse Scanner** یک اپلیکیشن اندرویدی حرفه‌ای با معماری دوگانه **Go (موتور پرسرعت همزمان از طریق `gomobile`)** و **Flutter/Dart (رابط کاربری AMOLED دو‌زبانه فارسی/انگلیسی)** برای اسکن، بنچمارک و استخراج بهترین پروکسی آی‌پی‌های کلودفلر (ProxyIP) به تفکیک کشور و ریجن‌های Placement است.

---

## امکانات کلیدی (Features)

- **موتور اسکن بومی Go (`go_core/`):**
  - استخر همزمان تا ۵۰۰ گوروتین با قابلیت **توقف موقت (Pause/Resume)** و لغو لحظه‌ای.
  - تست چندمرحله‌ای TCP برای محاسبه دقیق **Min / Avg / Max Ping، جیتر (Jitter) و درصد پکت‌لاس (Packet Loss)**.
  - بررسی **TLS Handshake** با قابلیت تنظیم SNI دلخواه، ALPN (`h2,http/1.1`)، نسخه TLS (1.2/1.3) و رد کردن خطای گواهی روی IP خام.
  - تایید واقعی بودن مسیر کلودفلر از طریق **`/cdn-cgi/trace`** و استخراج خودکار **کد دیتاسنتر (Colo)** و موقعیت.
  - **تست سرعت دانلود (Speed Test)** روی بهترین کاندیداهای مرحله اول با حجم فایل قابل تنظیم (128KB تا 5MB).
  - **امتیازدهی ترکیبی (Score 0–100)** بر اساس پینگ، جیتر، پکت‌لاس، تایید Trace و سرعت دانلود.
  - پشتیبانی از ورودی‌های `IP:Port`، `CSV` و **گسترش خودکار رنج‌های CIDR** (مثل `/24`).
- **موتور پشتیبان خودکار Dart:** در صورتی که بدون کامپایل کردن `edgepulse_core.aar` مستقیم `flutter run` بگیرید، اپ بدون خطا اجرا شده و به‌طور خودکار از موتور همزمان `dart:io` استفاده می‌کند.
- **دیتابیس داخلی به تفکیک ۲۰ کشور + همگام‌سازی آنلاین از گیت‌هاب:** شامل لیست‌های آماده آلمان، هلند، فنلاند، فرانسه، بریتانیا، سوئد، سوئیس، اسپانیا، لهستان، ترکیه، امارات، آمریکا، کانادا، سنگاپور، ژاپن و... به همراه دامین‌های پویا و دکمه دریافت آنلاین جدیدترین لیست‌ها از مخازن عمومی ([NiREvil/vless](https://github.com/NiREvil/vless/blob/main/sub/ProxyIP.md) و [FoolVPN-ID/Nautica](https://github.com/FoolVPN-ID/Nautica/blob/main/proxyList.txt)).
- **خروجی چندفرمته (Export):** کپی یا اشتراک‌گذاری نتایج سالم در فرمت‌های `TXT (IP:Port)`، `CSV`، `JSON`، فرمت تک‌خطی `BPB Panel` و تولید مستقیم لینک‌های `VLESS`.
- **نسخه خط فرمان (CLI) برای Termux و دسکتاپ:** قابل اجرا در ترموکس اندروید با `scripts/setup-termux.sh`.

## ساختار پروژه (Architecture)

```text
edgepulse_scanner/
├── go_core/                     # موتور اسکن بومی Go (قابل بیلد با gomobile و CLI)
│   ├── go.mod
│   ├── models.go                # مدل‌ها، تنظیمات کامل، پارسر چندفرمته و گسترش CIDR
│   ├── scanner.go               # موتور همزمان TCP/TLS/Trace/SpeedTest/Scoring
│   ├── mobile.go                # رابط صادراتی gomobile برای اتصال به اندروید
│   ├── scanner_test.go          # تست‌های واحد Go
│   └── cmd/edgepulse-cli/       # نسخه خط فرمان برای Termux و دسکتاپ
├── android/                     # لایه بومی اندروید (Kotlin MethodChannel + EventChannel)
│   └── app/src/main/kotlin/com/edgepulse/scanner/MainActivity.kt
├── lib/                         # اپلیکیشن Flutter/Dart
│   ├── main.dart                # تم AMOLED تیره و ناوبری ۵ تب (فارسی RTL / انگلیسی)
│   ├── data/proxy_database.dart # دیتابیس داخلی پروکسی آی‌پی‌ها به تفکیک کشور + ریجن‌های Placement
│   ├── models/scan_models.dart
│   ├── services/                # پل Go/Dart، ذخیره تنظیمات، سینک گیت‌هاب، خروجی چندفرمته
│   ├── state/scanner_controller.dart
│   └── screens/                 # Dashboard، Countries، Results، Settings، History
├── scripts/
│   ├── build_all.sh             # بیلد کامل AAR هسته Go + APK فلاتر
│   └── setup-termux.sh          # نصب سریع نسخه CLI روی ترموکس
└── .github/workflows/
    └── build-android.yml        # بیلد خودکار APK در GitHub Actions
```

## راهنمای سریع بیلد APK (Quick Start)

### روش ۱: بیلد خودکار بدون نصب ابزار روی سیستم (GitHub Actions)
1. این پروژه را در یک مخزن جدید گیت‌هاب آپلود (Push) کنید.
2. وارد تب **Actions** شوید و ورک‌فلو **Build EdgePulse Android APK (Go + Flutter)** را اجرا کنید.
3. پس از پایان بیلد، فایل‌های آماده نصب `.apk` (شامل `arm64-v8a`، `armeabi-v7a` و نسخه Universal) را از بخش **Artifacts** دانلود و روی گوشی نصب کنید.

### روش ۲: بیلد محلی (Linux / macOS)
```bash
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

### روش ۳: اجرای موتور Go در ترموکس اندروید (Termux)
```bash
chmod +x scripts/setup-termux.sh
./scripts/setup-termux.sh
edgepulse-cli -in proxies.txt -out best.csv -c 64 -trace -speed
```
