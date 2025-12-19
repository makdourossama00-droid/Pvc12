# حاسبة نوافذ PVC (Flutter Mobile App)

هذا هو تطبيق Flutter Mobile App الذي تم تحويله من كود HTML/JavaScript، مع الالتزام الصارم بالحفاظ على جميع المعادلات والمنطق الحسابي كما هو.

## المتطلبات

- Flutter SDK مثبت ومُعد.

## تعليمات البناء (لإنشاء ملف APK)

1.  **انتقل إلى مجلد المشروع:**
    ```bash
    cd pvc_calculator
    ```

2.  **تثبيت الحزم (Dependencies):**
    يجب تثبيت حزمة `shared_preferences` لتخزين الأسعار وقائمة النوافذ محلياً.
    ```bash
    flutter pub get
    ```

3.  **بناء ملف APK:**
    لإنشاء ملف APK قابل للتثبيت على أجهزة Android، استخدم الأمر التالي:
    ```bash
    flutter build apk --release
    ```

4.  **مكان ملف APK:**
    سيتم إنشاء ملف APK في المسار التالي:
    ```
    pvc_calculator/build/app/outputs/flutter-apk/app-release.apk
    ```

## ملاحظات هامة

-   **المنطق الحسابي:** تم نقل جميع المعادلات من JavaScript إلى Dart حرفياً، وتم استخدام `double.toStringAsFixed(2)` لضمان نفس التقريب (`toFixed(2)` في JS).
-   **التخزين:** تم استبدال `localStorage` بـ `shared_preferences` لحفظ الأسعار وقائمة النوافذ.
-   **الاتجاه:** التطبيق يدعم RTL (من اليمين لليسار) بشكل كامل.

