# تقويم الباستافاريين — خطّ C# بالعربية الكلاسيكية

هذا الخط تنفيذ تاريخي متدرّج من خمسة وخمسين طورًا. أُنشئ من شجرة خالية دون استعارة كود أو جداول متوقعة من تنفيذ آخر. اكتملت الأطوار الثلاثة الأولى: التأسيس، واكتشاف خلل الباقي القديم، ثم رقعة الحفظ الأولى. الطور القادم هو `DISCOVERY 02`، ولم يبدأ تنفيذه.

## الحدود الحالية للمكتبة

يوجد في الإنتاج مساران متمايزان. تُعيد `CalendarDateSpaghetti.EvaluateLegacySave` الباقي القديم عمداً، فلا تزال تختلف عن المرجع عند مضاعفات `M = 2^127 - 1`. ويستدعي `CalendarDateSpaghetti.EvaluateSave` المدير والموزّع والمعالج القديم ثم `SavePatchWrapper`، الذي يحوّل الباقي الصفري وحده إلى `M`.

تُحفظ نتيجة المسار القديم والنتيجة المصححة في حقلي سياق منفصلين، بعد التحقق من المرشح وقبل تثبيته. لا تُغيّر القياسات والسجلات النتيجة المعيارية، ولا يُستعمل مرجع الاختبار في مسار الإنتاج.

لا تحسب المكتبة بعدُ التاريخ الباستافاري النهائي؛ سيُنشأ هذا المسار تدريجيًّا في الأطوار اللاحقة، دون استباق عيوبها أو ترقيعاتها.

## المرجع والأسماء

يحوي مشروع الاختبار مرجعًا معياريًّا مستقلًّا باستعمال `System.Numerics.BigInteger` بلا حساب عائم. يحوي `SourceLanguageCatalog` سبعة عشر اسمًا ثابتًا للكُتَيْلات وسبعة وأربعين اسمًا للأشهر بالعربية الكلاسيكية؛ يحدَّد ترتيبها حصراً وفق `canonicalIndex`.

## البناء والاختبار

باستخدام .NET SDK 10، ومن جذر المستودع:

```text
dotnet build tests/PastafarianCalendar.Stage03Tests/PastafarianCalendar.Stage03Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage01Tests/PastafarianCalendar.Stage01Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage02Tests/PastafarianCalendar.Stage02Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage03Tests/PastafarianCalendar.Stage03Tests.csproj -c Release
```

التشغيل المباشر لاختبار الطور الثاني، **دون** `--verify-expected-red`، يُفترض أن ينتهي بخروج `1` بسبب خمسة اختلافات تاريخية مقصودة. لا يعني ذلك فشل رقعة الطور الثالث.

أكّد GitHub Actions في التشغيل `38152887955` أن اختبارات التأسيس `57/57` واختبارات الرقعة `791/791` ناجحة، وأن الاختلافات التاريخية الخمسة بقيت كما هي. لا يحتاج البناء إلى حزم خارج مكتبات .NET القياسية.
