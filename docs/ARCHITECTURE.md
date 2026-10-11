# البنية بعد الطور الثامن

## طبقة الإنتاج والمرجع

في `src/PastafarianCalendar` يوجد فهرس الأسماء العربي المجمّد وبنية المدير والموزّع والتحقق والقياسات. وفي `tests/PastafarianCalendar.Stage01Tests/Normative` يوجد المرجع المعياري المستقل. يمنع الفصل أي استدعاء إنتاجي للمرجع.

تملك كل عملية `MonsterContext` جديدًا خاصًّا بها. تبقى سجلات الفروع والقياسات والتشخيصات خارج اتخاذ القرار المعياري. لا يوجد مخزن عالمي متغير للحالة المعيارية ولا cache عابر للاستدعاءات ولا fallback إلى المرجع.

## الأثر التاريخي المعتمد

يتكون المسار القديم من `MonsterManager.Prepare` ثم `MonsterDispatcher.DispatchLegacySave` ثم `LegacySavePhaseHandler.Handle` ثم `LegacyRemainder.OldRemainder`. ينتهي في `LegacySaveResult`، ويبقى خطؤه متعمداً.

يستدعي المسار المصحح `MonsterDispatcher.DispatchSavePatched` المعالج القديم أولاً، ثم يُنفِّذ `SavePatchWrapper.SavePatch` الذي يعيد استدعاء `oldRemainder` بوصفه الأثر التاريخي الفعلي. يُفحص المرشح في `MonsterValidationManager.ValidateSavePatchResult` ويُثبت في `PatchedSaveResult`، مع المحافظة على المخرج القديم للمقارنة.

تتحقق معادلة التكافؤ للرقعة الأولى:

```text
M = 2^127 - 1
legacy = regularMod(x,M)
patched = (legacy == 0) ? M : legacy
normative = 1 + regularMod(x - 1,M)
patched == normative
```

لا تُستخدم أعداد عائمة أو تقريب في الحساب.

## اكتشاف الخلل التاريخي الثاني

يعمل `LegacyDayTag.OldDayTag` في مسار مستقل عن `SavePatchWrapper`، عبر `MonsterManager.ExecuteLegacyDayTag` ثم `MonsterDispatcher.DispatchLegacyDayTag` ثم `LegacyDayTagPhaseHandler.Handle`. تحفظ القيمة التاريخية في `LegacyDayTagResult` داخل سياق الاستدعاء الذي يملكها وحده.

القيمة القديمة هي `2 * abs(day - FOUNDATION)`. المرجع يضيف واحداً في يوم التأسيس وبعده، ولا يضيفه قبله؛ لذلك يعمل هذا المسار عمداً على إظهار الخلل، ويبقى محفوظاً بعد إضافة الرقعة في مسار مستقل. لا يُسمح بانتقال الحالة المرصودة في سجل الفروع أو القياسات إلى الحساب المعياري.

## رقعة عدّ اليوم الثانية

يُدخِل `CalendarDateSpaghetti.EvaluateDayTag` اليوم إلى المدير الجديد، فيُعدُّ الموزّع سياقاً خاصاً، ويستدعي `DispatchLegacyDayTag` أولاً. ثم ينفّذ `DayTagPatchWrapper.Patch` استدعاءً ثانياً حقيقياً للعدّ القديم ويضيف واحداً ابتداءً من يوم التأسيس. بعد ذلك يبقى حارس يوم التأسيس الزائد، ويُفحص الناتج قبل تثبيته في `PatchedDayTagResult`. تظل `LegacyDayTagResult` شاهداً مستقلاً على الخطأ التاريخي.

تُثبت الرقعة محليّاً، لجميع الأعداد الصحيحة:

```text
F = -15055671
legacy(day) = 2*abs(day-F)
patched(day) = legacy(day) + (day >= F ? 1 : 0)
if day == F && patched(day) != 1: patched(day) = 1
patched(day) == normativeDayCount(day)
```

لا يتأثر `SourceLanguageCatalog` ولا رقعة الحفظ الأولى بالمسار الجديد. ولا تُقرأ الملاحظات أو السجلات في الحساب.

## اكتشاف المسافة التاريخية الثالثة

يُنشئ `MonsterManager.ExecuteLegacyDistance(c,t)` سياقاً جديداً، ثم ينفذ الموزّع `DispatchLegacyDistance` والمعالج `LegacyDistancePhaseHandler`، الذي يستدعي `LegacyDistance.OldDistance`. تستعمل الدالة فعليّاً `DayTagPatchWrapper.Patch` لكلا اليومين، ثم تحسب `abs(tag(c)-tag(t))` وتثبت النتيجة في `LegacyDistanceResult` المملوك للسياق الواحد.

هذا الحساب القديم ليس المسافة الزمنية الصحيحة. في المرجع `distance=abs(t-c)+1`، ولذلك يختلف الحسابان لعدد كبير من الأزواج، بما في ذلك حالتا اليوم الواحد وعبور يوم التأسيس. بقيت الدالة القديمة بلا تعديل متعمّد، وأضيفت المقارنة والزيادة في غلاف منفصل للرقعة الثالثة، مع حفظ خرج الدالة القديمة في السياق.

## الرقعة الثالثة وخماسية حساب العمل

يُحضّر `MonsterManager.ExecutePatchedCounts` سياقاً منفصلاً، ويشغّل `MonsterDispatcher.DispatchPatchedCounts` المسافة التاريخية أولاً، ثم يستدعي `PatchedCounts.Calculate` الذي يُشغّل `oldDistance` مرة أخرى ويفحص فرق العدّادين أمام الفرق الزمني. إذا اختلفت القيمتان، تُستبدل القديمة بالزمنية ثم تضاف الوحدة. وإذا اتفقتا، تُضاف الوحدة إلى الناتج التاريخي نفسه. هذا التفرّع شرط تاريخي لازم لنمط الرقعة، وليس تحسيناً يمكن اختزاله.

يحفظ `MonsterContext.LegacyDistanceResult` القيمة التاريخية مستقلة عن `MonsterContext.PatchedCountsResult`. لا تُثبت الخماسية الجديدة إلا بعد فحص `MonsterValidationManager.ValidatePatchedCounts`. وهي سجل ثابت `MonsterWorkCounts(Action,Target,Distance,Connection,Direction)`:

```text
action = dayTagWithFoundationScar(calculationDay)
target = dayTagWithFoundationScar(targetDay)
legacy = oldDistance(calculationDay,targetDay)
chronological = abs(targetDay-calculationDay)
if legacy != chronological: legacy = chronological
distance = legacy+1
connection = action+target
direction = (targetDay < calculationDay ? 1 : targetDay > calculationDay ? 3 : 2)
```

يبقى أي طلب متكرر أو غير مهيأ ممنوعاً قبل الالتزام، وتظل كل سجلات الرصد خارج الحساب. لا يتصل الإنتاج بمراجع الاختبار.

## اكتشاف التحوير التاريخي الرابع للأحجار

يستدعي `MonsterManager.ExecuteLegacyStones` الموزّع `DispatchLegacyStones` ثم المعالج `LegacyStonesPhaseHandler`، الذي يولّد سلسلة الصفوف الفعلية بواسطة `LegacyStones.BuildWrongRows`. تبدأ الأحجار من البذرة `(17,29,43,71,101)`. تستدعي كل دورة من الثانية إلى السادسة والأربعين `LegacyStones.MutateStonesWrong(row,stones)`، وهي تغيّر المصفوفة نفسها بالترتيب قمح ثم شعير ثم ملح ثم مرارة ثم أحمر؛ فتقرأ بعض النواتج القيمة الجديدة بدلاً من صورة الحجر القديم.

تستعمل هذه الدالة `SavePatchWrapper` السابقة لإبقاء مجال القيم صحيحاً، ولا تُستعمل الصورة الموحدة القديمة في تحديث الأحجار الخمسة. تُنسخ نتيجة كل صف بعد وقوع التحوير كي يبقى السجل الزمني محفوظاً؛ والمصفوفات الناتجة في `MonsterContext.LegacyStoneRows` مستقلة بين الصفوف والاستدعاءات. لا يُنتَج أي `stonePatch` ولا يُنفّذ `mutateStonesWrong` على نسخة افتراضية لإصلاح النتائج: ذلك هو الطور التاسع وحده.

## الاختبارات حسب المراحل

- الطور الأول: التأسيس والمرجع والقائمة المجمدة، `57/57` ناجحًا.
- الطور الثاني: خمسة اختلافات حمراء مقصودة من تسع حالات أولية في المسار القديم، مع فحص 183 قيمة حدودية وحراسة ملكية السياق.
- الطور الثالث: `791/791` تحققاً أخضر في المسار المصحح، يشمل الحدود والأعداد الكبيرة والاحتفاظ بسلوك المسار القديم.
- الطور الرابع: `269` حالة عدّ يوم تاريخي، منها `134` متطابقة و`135` مختلفة على النحو المتوقع؛ والمدقّق الأخضر يتحقق من المعنى وحراسة السياق.
- الطور الخامس: `1091/1091` تأكيداً ناجحاً لرقعة عدّ اليوم، بما يشمل الأيام الـ`269` وفحوص السياق والندبة التاريخية.
- الطور السادس: `309` زوجاً من الأيام، منها `46` تطابقاً و`263` اختلافاً تاريخياً مقصوداً، دون مخالفة للصيغة أو ملكية السياق.
- الطور السابع: `2423` زوجاً من الأيام، و`24258/24258` تأكيداً ناجحاً على تكافؤ خماسية الحساب مع المرجع والحفاظ على مسار الخطأ القديم.
- الطور الثامن: `230` خانة أحجار عبر `46` صفاً، منها `6` مطابقة و`224` مختلفة عمداً، وصفر مخالفة غير متوقعة مع نجاح اختبارات الذاكرة وسياق الاستدعاء.

يُبقي CI الاختبار الأحمر العادي بوصفه شاهداً تاريخيًّا واضحاً، ويتحقق بصورة مستقلة من أن الخمس حالات هي وحدها الفاشلة. ثم يُشغِّل اختبارات الرقعتين الخضراوين، واختبار الطور الرابع الأحمر مع مدقّق توقيعه. اكتمل `DISCOVERY 03` مع اختبار أحمر موثق ومدقق توقيع أخضر، وثبت نجاح `PATCH 03` في الاختبار المستقل. اكتمل `DISCOVERY 04` باختباره الأحمر المقصود ومدقّق توقيعه الأخضر؛ ولم يبدأ `PATCH 04` ولا أي رقعة لاحقة.
