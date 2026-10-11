# تقويم الباستافاريين — خطّ C# بالعربية الكلاسيكية

هذا الخط تنفيذ تاريخي متدرّج من خمسة وخمسين طورًا. أُنشئ من شجرة خالية دون استعارة كود أو جداول متوقعة من تنفيذ آخر. اكتملت الأطوار الثلاثة عشر الأولى: التأسيس، وستة أخطاء تاريخية ورقعها، حتى رقعة استرجاع القطرات السابقة بما فيها المخفيات. المرحلة التالية `DISCOVERY 07` في الطور الرابع عشر، ولم تبدأ بعد.

## الحدود الحالية للمكتبة

يوجد في الإنتاج مساران متمايزان. تُعيد `CalendarDateSpaghetti.EvaluateLegacySave` الباقي القديم عمداً، فلا تزال تختلف عن المرجع عند مضاعفات `M = 2^127 - 1`. ويستدعي `CalendarDateSpaghetti.EvaluateSave` المدير والموزّع والمعالج القديم ثم `SavePatchWrapper`، الذي يحوّل الباقي الصفري وحده إلى `M`.

تُحفظ نتيجة المسار القديم والنتيجة المصححة في حقلي سياق منفصلين، بعد التحقق من المرشح وقبل تثبيته. لا تُغيّر القياسات والسجلات النتيجة المعيارية، ولا يُستعمل مرجع الاختبار في مسار الإنتاج.

أُضيف مسار ثالث هو `CalendarDateSpaghetti.EvaluateLegacyDayTag`، الذي ينفِّذ الصيغة التاريخية `2 * abs(day - FOUNDATION)` عن طريق المدير والموزّع ومعالج السياق. يتطابق مع المرجع قبل يوم التأسيس، ويقلّ عنه بوحدة واحدة عند التأسيس وبعده. ما زال المسار القديم يعيد النتيجة الخاطئة عمداً. أما `CalendarDateSpaghetti.EvaluateDayTag` فيستدعي المعالج القديم ثم `DayTagPatchWrapper`، فيضيف واحداً إلى العدّ عند التأسيس وما بعده ويحفظ حارس التأسيس التاريخي الزائد. لم يمسّ التصحيح مسار `SAVE` الأول.

أُضيف في الطور السادس مسار تاريخي مستقل `CalendarDateSpaghetti.EvaluateLegacyDistance(c,t)`، يستدعي `DayTagPatchWrapper.Patch` لكل يوم، ثم يحسب الفرق المطلق بين العدّادين. هذه ليست المسافة الصحيحة التي تساوي `abs(t-c)+1`؛ ففي اليوم الواحد يُنتج الطريق التاريخي صفراً عوضاً عن واحد. وتظل النتيجة التاريخية خاطئةً عمداً؛ أما واجهة `CalendarDateSpaghetti.EvaluateWorkCounts(c,t)` فتُشغّل معالج المسافة القديم ثم `PatchedCounts`، وتقارن القيمة القديمة مع `abs(t-c)`، وتُبدّلها عند الاختلاف وتضيف وحدة الشمول. وتعيد نتيجة ثابتة من خمسة حقول: `Action` و`Target` و`Distance` و`Connection` و`Direction`. لا تُحذف ندبة المسافة القديمة ولا تُستعار الحسابات من مرجع الاختبار.

في الطور الثامن أُدخل `LegacyStones.MutateStonesWrong`، وهي تُغيّر الأحجار الخمسة في موضعها واحداً بعد الآخر، فتقرأ الأحجار المتأخرة نتائج الأحجار التي تغيّرت في الدورة نفسها. تدخل العملية في مسار الإنتاج `CalendarDateSpaghetti.EvaluateLegacyStones` الذي يحفظ `46` صفاً من النتائج، لكل استدعاء نسخ مستقلة. يبقى المسار التاريخي خاطئاً عمداً، لكن `CalendarDateSpaghetti.EvaluatePatchedStones` يسلك مساراً منفصلاً: يحفظ الجدول القديم أولاً، ثم يستدعي `StonePatchWrapper` الذي يُجمّد صورة الأحجار ويُنفّذ `mutateStonesWrong` فعلياً على نسخة ثم يستبدل جميع النواتج الخمسة. أثبت الاختبار تكافؤ الصفوف الستة والأربعين مع المرجع المعياري، دون محو نتائج التاريخ.

أُدخل في الطور العاشر `CalendarDateSpaghetti.EvaluateLegacyHiddenDrops(c,t)`؛ ويُنتج القطرات السبع من عدّ العمل وصفوف الأحجار المصححة، لكنه يحفظها في الذاكرة التاريخية بترتيب `hidden7, hidden6, …, hidden1`. هذه هي الندبة التاريخية الخامسة: القراءة البسيطة `storage[k]` لا تعني القطرة رقم `k`. بقي التخزين التاريخي معكوساً، لكن الرقعة الخامسة `HiddenNearnessWrapper.HiddenByNearness(k)` تحسب موضع القراءة `8-k` من المصفوفة القديمة نفسها، بلا قلب أو نسخ. تستدعي `CalendarDateSpaghetti.EvaluateHiddenDrop(c,t,k)` المسار القديم قبل تثبيت غلاف القراءة، وتحرس الملكية والمدى والتحقق قبل الالتزام.

دخل `LegacyPrior.Read(dropStore,i,back)` المسار الإنتاجي في الطور الثاني عشر عبر `CalendarDateSpaghetti.EvaluateLegacyPrior`. تقرأ هذه الدالة `dropStore[i-back]` فحسب، ولذلك تُرجع صفراً عند `i-back=0`، وترمي `IndexOutOfRangeException` عند الموضع السالب. يدخل إليها جدول القطرات الظاهرة بوصفه مدخلاً مستقلاً مملوكاً للاستدعاء؛ لا يُحسب جدول كامل في الإنتاج قبل طور بنائه، ولا تُستعار بيانات من مرجع الاختبار. أُصلحت هذه المواضع في الطور الثالث عشر بواسطة `PriorAccessWrapper.Read`: الموضع الموجب يستدعي `LegacyPrior.Read` فعلياً ويحفظ شاهده، والموضع غير الموجب يستعمل `hiddenK=1-(i-back)` من خلال `HiddenNearnessWrapper`. لا تُقلَب مصفوفة القطرات التاريخية ولا تتغير دالة `LegacyPrior` القديمة.

لا تحسب المكتبة بعدُ التاريخ الباستافاري النهائي؛ سيُنشأ هذا المسار تدريجيًّا في الأطوار اللاحقة، دون استباق عيوبها أو ترقيعاتها.

## المرجع والأسماء

يحوي مشروع الاختبار مرجعًا معياريًّا مستقلًّا باستعمال `System.Numerics.BigInteger` بلا حساب عائم. يحوي `SourceLanguageCatalog` سبعة عشر اسمًا ثابتًا للكُتَيْلات وسبعة وأربعين اسمًا للأشهر بالعربية الكلاسيكية؛ يحدَّد ترتيبها حصراً وفق `canonicalIndex`.

## البناء والاختبار

باستخدام .NET SDK 10، ومن جذر المستودع:

```text
dotnet build tests/PastafarianCalendar.Stage13Tests/PastafarianCalendar.Stage13Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage01Tests/PastafarianCalendar.Stage01Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage02Tests/PastafarianCalendar.Stage02Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage03Tests/PastafarianCalendar.Stage03Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage04Tests/PastafarianCalendar.Stage04Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage05Tests/PastafarianCalendar.Stage05Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage06Tests/PastafarianCalendar.Stage06Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage07Tests/PastafarianCalendar.Stage07Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage08Tests/PastafarianCalendar.Stage08Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage09Tests/PastafarianCalendar.Stage09Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage10Tests/PastafarianCalendar.Stage10Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage11Tests/PastafarianCalendar.Stage11Tests.csproj -c Release
dotnet run --project tests/PastafarianCalendar.Stage12Tests/PastafarianCalendar.Stage12Tests.csproj -c Release -- --verify-expected-red
dotnet run --project tests/PastafarianCalendar.Stage13Tests/PastafarianCalendar.Stage13Tests.csproj -c Release
```

التشغيل المباشر لاختبار الطور الثاني، **دون** `--verify-expected-red`، يُفترض أن ينتهي بخروج `1` بسبب خمسة اختلافات تاريخية مقصودة. لا يعني ذلك فشل رقعة الطور الثالث.

التشغيل المباشر لاختبار الطور الرابع من غير `--verify-expected-red` ينتهي أيضاً بخروج `1` مقصود، هذه المرة بسبب `135` اختلافاً في عدّ اليوم القديم.

أكّد GitHub Actions في التشغيل `38153994461` نجاح اختبارات التأسيس `57/57`، ورقعة الحفظ الأولى `791/791`، ورقعة عدّ اليوم الثانية `1091/1091`. وتظل الحالات الخمس المختلفة في اكتشاف الحفظ، وحالات الاختلاف الـ`135` في اكتشاف عدّ اليوم، مقصودة وثابتة دون خلل إضافي. لا يحتاج البناء إلى حزم خارج مكتبات .NET القياسية.

التشغيل المباشر لمجموعة الطور السادس، من غير `--verify-expected-red`، ينتهي بخروج `1` مقصود بسبب `263` اختلافاً تاريخياً في `309` حالة، من دون أي فرق مخالف للتوقيع. أكّد تشغيل CI رقم `38154988073` نجاح مدقق الاكتشاف ونجاح جميع مجموعات الأطوار السابقة.

أثبت تشغيل CI رقم `38155964480` نجاح `24258/24258` تأكيداً للرقعة الثالثة في `2423` زوجاً من الأيام مع صفر فشل؛ وتظل الفروق القديمة في الأطوار `2` و`4` و`6` مقصودة ومتحققاً من توقيعها.

شُغّل الاختبار المباشر للطور الثامن بوصفه اختباراً أحمر مقصوداً؛ وجد `224` اختلافاً من `230` خانة في الأحجار، و`6` تطابقات فقط، ثم اجتاز اختبار التحقق المستقل جميع فحوص التوقيع والملكية. أثبت ذلك تشغيل CI رقم `38157648917`، مع نجاح جميع اختبارات الأطوار السبعة السابقة. لا يحتاج المشروع إلى حزم إضافية خارج .NET.

أكّد تشغيل CI رقم `38159020955` نجاح `1429/1429` فحصاً للرقعة الرابعة، بينها مقارنات `230` خانة أحجار مع المرجع المعياري و`54` حالة إدخال مستقلة. بقي `224` اختلافاً تاريخياً متوقعاً في مسار التحوير القديم، وصفر اختلاف غير متوقع. لا يتضمن هذا الطور أخطاء تخزين القطرات المخفية ولا إصلاحاتها اللاحقة.

أثبت CI رقم `38161153559` توقيع تخزين القطرات التاريخي في `42` موضعاً: `6` مطابقات و`36` اختلافاً مقصوداً وصفر مخالفة غير متوقعة. بقيت مجموعة الاكتشاف الخامسة حمراء في التشغيل المباشر وخضراء في مدقق التوقيع المستقل، مع نجاح كل مجموعات الأطوار التسعة السابقة.

نجح اختبار الرقعة الخامسة في GitHub Actions رقم `38163487926`: فُحصت `413` قطرة خفية عبر `59` زوجاً من الأيام ونجح `2069/2069` تحققاً، مع `354` اختلافاً تاريخياً أبقاها الغلاف مرئية في المخزن المعكوس. نجحت جميع مجموعات المراحل الأقدم، ولم يُبدأ آنذاك اكتشاف `legacyPrior` الذي نُفِّذ لاحقاً في الطور الثاني عشر.

نجح مدقق الاكتشاف السادس في تشغيل CI رقم `38165168004`: فُحصت `828` قراءة، منها `762` موضعاً موجباً مطابقاً للمرجع، و`18` صفراً خاطئاً متوقعاً، و`48` استثناء فهرسة سالبة تاريخياً، دون أي اختلاف خارج هذا التوقيع. ظل الاختبار المباشر أحمر عمداً، وبقيت الرقعات الخضراء الخمس واكتشافاتها القديمة ناجحة.

أكّد GitHub Actions رقم `38166751011` تكافؤ `1380` قراءة سابقة مع المرجع في عشرة أزواج من الأيام، منها `1270` قراءة ظاهرة عبر القديم و`110` قراءة خفية مصححة، ونجاح `13842/13842` تحققاً. ظل التوقيع التاريخي الأحمر للطور الثاني عشر ثابتاً على `18` صفراً و`48` استثناءً في ستة أزواج، ولم تُفتح بعدُ أخطاء الطحن الظاهر.
