# قنادی آیلین 🧁

بازی اندروید (Flutter) با مرحله‌ها، امتیاز، سکه و فروشگاه.

## ساخت نسخه انتشار
1. یک بار workflow به اسم «Create Keystore» رو اجرا کن، فایل‌ها رو دانلود و **جای امن نگه‌دار** (اگه گم بشه دیگه نمی‌تونی بازی رو آپدیت کنی).
2. در Settings > Secrets and variables > Actions این چهار Secret رو بساز: KEYSTORE_BASE64 ، KEYSTORE_PASSWORD ، KEY_ALIAS ، KEY_PASSWORD
3. workflow «Build Release» رو اجرا کن (یا تگ v1.0.0 بزن). فایل aylin-bakery.apk و aylin-bakery.aab ساخته می‌شه.

آپدیت‌ها: هر بار workflow اجرا بشه شماره بیلد خودکار زیاد می‌شه و با همون کلید امضا می‌شه. برای نسخه جدید، version رو در pubspec.yaml عوض کن.
شناسه برنامه: com.aylin.aylin_bakery (هیچ‌وقت عوضش نکن).
