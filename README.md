# تقويم الباستافاريين — خطّ C# بالعربية الكلاسيكية

هذا الخط تنفيذ تاريخي متدرّج من خمسة وخمسين طورًا. أُنشئ من شجرة خالية دون استعارة كود أو جداول متوقعة من تنفيذ آخر. اكتملت الأطوار السبعة الأولى: التأسيس، واكتشاف خلل الحفظ ورقعته، واكتشاف خلل عدّ اليوم ورقعته، ثم اكتشاف خلل المسافة بين العدّادين ورقعته الثالثة. الطور القادم هو `DISCOVERY 04`، ولم يبدأ تنفيذه.

## الحدود الحالية للمكتبة

يوجد في الإنتاج مساران متمايزان. تُعيد `CalendarDateSpaghetti.EvaluateLegacySave` الباقي القديم عمداً، فلا تزال تختلف عن المرجع عند مضاعفات `M = 2^127 - 1`. ويستدعي `CalendarDateSpaghetti.EvaluateSave` المدير والموزّع والمعالج القديم ثم `SavePatchWrapper`، الذي يحوّل الباقي الصفري وحده إلى `M`.

تُحفظ نتيجة المسار القديم والنتيجة المصححة في حقلي سياق منفصلين، بعد التحقق من المرشح وقبل تثبيته. لا تُغيّر القياسات والسجلات النتيجة المعيارية، ولا يُستعمل مرجع الاختبار في مسار الإنتاج.

أُضيف مسار ثالث هو `CalendarDateSpaghetti.EvaluateLegacyDayTag`، الذي ينفِّذ الصيغة التاريخية `2 * abs(day - FOUNDATION)` عن طريق المدير والموزّع ومعالج السياق. يتطابق مع المرجع قبل يوم التأسيس، ويقلّ عنه بوحدة واحدة عند التأسيس وبعده. ما زال المسار القديم يعيد النتيجة الخاطئة عمداً. أما `CalendarDateSpaghetti.EvaluateDayTag` فيستدعي المعالج القديم ثم `DayTagPatchWrapper`، فيضيف واحداً إلى العدّ عند التأسيس وما بعده ويحفظ حارس التأسيس التاريخي الزائد. لم يمسّ التصحيح مسار `SAVE` الأول.

أُضيف في الطور السادس مسار تاريخي مستقل `CalendarDateSpaghetti.EvaluateLegacyDistance(c,t)`، يستدعي `DayTagPatchWrapper.Patch` لكل يوم، ثم يحسب الفرق المطلق بين العدّادين. هذه ليست المسافة الصحيحة التي تساوي `abs(t-c)+1`؛ ففي اليوم الواحد يُنتج الطريق التاريخي صفراً عوضاً عن واحد. وتظل النتيجة التاريخية خاطئةً عمداً؛ أما واجهة `CalendarDateSpaghetti.EvaluateWorkCounts(c,t)` فتُشغّل معالج المسافة القديم ثم `PatchedCounts`، وتقارن القيمة القديمة مع `abs(t-c)`، وتُبدّلها عند الاختلاف وتضيف وحدة الشمول. وتعيد نتيجة ثابتة من خمسة حقول: `Action` و`Target` و`Distance` و`Connection` و`Direction`. لا تُحذف ندبة المسافة القديمة ولا تُستعار الحسابات من مرجع الاختبار.

لا تحسب المكتبة بعدُ التاريخ الباستافاري النهائي؛ سيُنشأ هذا المسار تدريجيًّا في الأطوار اللاحقة، دون استباق عيوبها أو ترقيعاتها.

## المرجع والأسماء

يحوي مشروع الاختبار مرجعًا معياريًّا مستقلًّا باستعمال `System.Numerics.BigInteger` بلا حساب عائم. يحوي `SourceLanguageCatalog` سبعة عشر اسمًا ثابتًا للكُتَيْلات وسبعة وأربعين اسمًا للأشهر بالعربية الكلاسيكية؛ يحدَّد ترتيبها حصراً وفق `canonicalIndex`.

## البناء والاختبار

باستخدام .NET SDK 10، ومن جذر المستودع:

```text
dotnet build tests/PastafarianCalendar.Stage07Tests/PastafarianCalendar.Stage07Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage01Tests/PastafarianCalendar.Stage01Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage02Tests/PastafarianCalendar.Stage02Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage03Tests/PastafarianCalendar.Stage03Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage04Tests/PastafarianCalendar.Stage04Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage05Tests/PastafarianCalendar.Stage05Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage06Tests/PastafarianCalendar.Stage06Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage07Tests/PastafarianCalendar.Stage07Tests.csproj -c Release
```

التشغيل المباشر لاختبار الطور الثاني، **دون** `--verify-expected-red`، يُفترض أن ينتهي بخروج `1` بسبب خمسة اختلافات تاريخية مقصودة. لا يعني ذلك فشل رقعة الطور الثالث.

التشغيل المباشر لاختبار الطور الرابع من غير `--verify-expected-red` ينتهي أيضاً بخروج `1` مقصود، هذه المرة بسبب `135` اختلافاً في عدّ اليوم القديم.

أكّد GitHub Actions في التشغيل `38153994461` نجاح اختبارات التأسيس `57/57`، ورقعة الحفظ الأولى `791/791`، ورقعة عدّ اليوم الثانية `1091/1091`. وتظل الحالات الخمس المختلفة في اكتشاف الحفظ، وحالات الاختلاف الـ`135` في اكتشاف عدّ اليوم، مقصودة وثابتة دون خلل إضافي. لا يحتاج البناء إلى حزم خارج مكتبات .NET القياسية.

التشغيل المباشر لمجموعة الطور السادس، من غير `--verify-expected-red`، ينتهي بخروج `1` مقصود بسبب `263` اختلافاً تاريخياً في `309` حالة، من دون أي فرق مخالف للتوقيع. أكّد تشغيل CI رقم `38154988073` نجاح مدقق الاكتشاف ونجاح جميع مجموعات الأطوار السابقة.

أثبت تشغيل CI رقم `38155964480` نجاح `24258/24258` تأكيداً للرقعة الثالثة في `2423` زوجاً من الأيام مع صفر فشل؛ وتظل الفروق القديمة في الأطوار `2` و`4` و`6` مقصودة ومتحققاً من توقيعها. لم يبدأ طور `DISCOVERY 04` أو أي عيب لاحق.
