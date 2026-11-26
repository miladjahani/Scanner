# miliscanner — اسکنر پروکسی آی‌پی کلودفلر (Go + Flutter)

![Platform](https://img.shields.io/badge/Platform-Android%20(API%2024%2B)-00E676?style=flat-square)
![IPv6](https://img.shields.io/badge/IPv4%20%2B%20IPv6-Ready-B388FF?style=flat-square)
![Core](https://img.shields.io/badge/Core-Go%201.23%20(gomobile)-00ADD8?style=flat-square)
![UI](https://img.shields.io/badge/UI-Flutter%20Bento-02569B?style=flat-square)
![Support](https://img.shields.io/badge/Support-%40miliconfig-29B6F6?style=flat-square)

**miliscanner** یک اپلیکیشن اندرویدی با معماری دوگانه است: موتور پرسرعت همزمان **Go** (از طریق `gomobile`) و رابط کاربری **Flutter/Dart** با طراحی تیره بنتو (Bento) و دو زبان فارسی/انگلیسی.
این اپ آی‌پی‌های پروکسی کلودفلر را اسکن، بنچمارک و بهینه می‌کند؛ روی **IPv4 و IPv6**.

کانال پشتیبانی: [@miliconfig](https://t.me/miliconfig)

---

## امکانات

- **اسکن IPv4 و IPv6:** پارس خودکار `IP:Port`، `[IPv6]:Port`، آدرس خام IPv6 و رنج‌های CIDR نسخه ۴ و ۶ (مثل `2606:4700:1000::/48`).
- **موتور بومی Go:** استخر همزمان تا ۵۰۰ کارگر، توقف/ادامه لحظه‌ای، تست چندمرحله‌ای TCP برای Min/Avg/Max Ping، جیتر و پکت‌لاس.
- **بررسی TLS و Trace:** Handshake با SNI/ALPN/نسخه TLS دلخواه و تایید مسیر کلودفلر با `/cdn-cgi/trace` برای استخراج Colo.
- **تست سرعت دانلود (Speed Test)** روی کاندیداهای برتر و امتیازدهی ترکیبی ۰ تا ۱۰۰.
- **موتور پشتیبان Dart:** اگر هسته Go کامپایل نشده باشد، اپ بدون خطا با موتور همزمان `dart:io` کار می‌کند.
- **دیتابیس ۲۰ کشور:** آلمان، هلند، فنلاند، فرانسه، بریتانیا، سوئد، سوئیس، اسپانیا، لهستان، ترکیه، امارات، آمریکا، کانادا، سنگاپور، ژاپن، استرالیا، برزیل، ایرلند، هند و لتونی، همراه با به‌روزرسانی آنلاین لیست‌ها.
- **خروجی کامل و انعطاف‌پذیر:**
  - جداکننده **خط جدید** یا **کاما**
  - **با پورت** (`1.2.3.4:443`) یا **بدون پورت** (`1.2.3.4`)
  - **هشتگ کشور** برای گروه‌بندی (`#DE`، `#NL`، …)
  - فیلتر **فقط IPv6**، خروجی `CSV`، `JSON` و لینک‌های `VLESS`
  - کپی سریع یا اشتراک فایل
- **طراحی بناو (Bento) مدرن:** کارت‌های گوشه‌گرد، تایپوگرافی درشت و اعداد زنده؛ همراه با **دموی ۱۸ نتیجه‌ای** برای دیدن چیدمان بدون اسکن.
- **بدون نمایش دامنه‌های پویا:** کاربر فقط آدرس‌های آی‌پی و رنج‌هایی را می‌بیند که اسکن می‌کند.
- **نسخه خط فرمان** برای Termux و دسکتاپ.

---

## ساختار پروژه

```text
miliscanner/
├── android/                     # لایه بومی اندروید (Kotlin MethodChannel + EventChannel)
│   └── app/src/main/
│       ├── kotlin/com/edgepulse/scanner/MainActivity.kt
│       └── res/drawable/ic_miliscanner.xml   # لوگوی اپ (M + ذره‌بین)
├── go_core/                     # موتور اسکن بومی Go
│   ├── models.go                # مدل‌ها، پارسر IPv4/IPv6 و گسترش CIDR
│   ├── scanner.go               # TCP/TLS/Trace/SpeedTest/Scoring
│   ├── mobile.go                # رابط gomobile برای اندروید
│   ├── scanner_test.go          # تست‌های واحد (شامل IPv6)
│   └── cmd/edgepulse-cli/       # نسخه خط فرمان
├── lib/
│   ├── main.dart                # تم AMOLED و ناوبری ۵ تب (فارسی RTL / انگلیسی)
│   ├── widgets/mili_logo.dart   # لوگوی برداری M + ذره‌بین
│   ├── data/proxy_database.dart # دیتابیس کشورها و رنج‌های IPv6
│   ├── models/scan_models.dart  # مدل‌ها و گزینه‌های خروجی
│   ├── services/                # پل Go/Dart، ذخیره تنظیمات، سینک، خروجی
│   ├── state/scanner_controller.dart
│   └── screens/                 # Dashboard، Countries، Results، Settings، History
└── scripts/
    ├── build_all.sh
    └── setup-termux.sh
```

---

## دریافت APK

نسخه‌های آماده نصب در بخش **Releases** همین مخزن منتشر می‌شوند:

| فایل | مناسب برای |
| --- | --- |
| `miliscanner-*-arm64-v8a.apk` | اکثر گوشی‌های جدید (۶۴ بیتی) — پیشنهادی |
| `miliscanner-*-armeabi-v7a.apk` | گوشی‌های قدیمی‌تر ۳۲ بیتی |
| `miliscanner-*-x86_64.apk` | امولاتور و دستگاه‌های x86_64 |
| `miliscanner-*-universal.apk` | نسخه Universal (همه معماری‌ها) |

پس از دانلود، گزینه **Install unknown apps** را برای مرورگر یا فایل‌منیجر فعال و APK را نصب کنید.

## بیلد

```bash
# بیلد کامل AAR هسته Go + APK فلاتر (Linux / macOS)
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

- بیلد خودکار: ورک‌فلو **Build miliscanner Android APK (Go + Flutter)** در تب Actions.
- اجرای CLI در Termux:

```bash
chmod +x scripts/setup-termux.sh
./scripts/setup-termux.sh
edgepulse-cli -in proxies.txt -out best.csv -c 64 -trace -speed
```

## پشتیبانی

سوال، پیشنهاد یا گزارش خطا: [@miliconfig](https://t.me/miliconfig)
