# Սկզբնական ճարտարապետություն

Stage 1-ում ճարտարապետությունը դիտավորյալ դեռ չի պարունակում ապագա պատմական սպիները։ Այս փուլում թույլատրված է միայն ընդհանուր, չեզոք հիմքը։

`MonsterContext`-ը պատկանում է մեկ invocation-ի և չի կիսվում այլ կանչերի հետ։ Ներկա դաշտերը սահմանափակված են մուտքային օրերով, lifecycle-ի չեզոք վիճակով, deterministic branch trace-ով և ոչ սեմանտիկ metrics-ով։

`MonsterManager`-ը persistent field չի պահում։ Յուրաքանչյուր bootstrap invocation-ի ներսում ստեղծվում են `BaseValidationManager`, `BaseDispatcher` և `BaseErrorWrapper` final instance-ներ, ստեղծվում է նոր context, և միայն այդ invocation-ի ընթացքում այդ reference-ներն օգտագործվում են։ Dispatcher-ը գրանցում է միայն չեզոք bootstrap անցումը և կանչում է validator-ը։ `BaseErrorWrapper`-ը ստեղծում է մեքենայական կոդով սահմանված error boundary։

Metrics-ը դիտարկելիության state է և չի ընթերցվում նորմատիվ որոշում ընդունելու համար։ Այս փուլում production semantic state դեռ չի հաշվարկվում, ուստի snapshot/validate/commit մեխանիզմների կոնկրետ պատմական ձևերը չեն ավելացվել վաղաժամ։

Test-only oracle-ը production շղթայից անկախ է։ Այն սահմանում է մաքուր նորմատիվ ճշմարտությունը և չի կարող դառնալ runtime fallback կամ correction path։


## Վիճակի պատկանելիություն

Stage 1-ի ownership audit-ը ավարտված է և մանրամասն գրված է `STATE_OWNERSHIP_AUDIT.md`-ում։ Mutable module global/static/shared semantic state չկա։ Oracle-ի memo/cache state-ը instance-local է, mutable class fields-ը private են, իսկ canonical `normativeCalendarDate` entry point-ը յուրաքանչյուր invocation-ի համար նոր `OracleCalendar` է ստեղծում։


## Ճշգրիտ ամբողջ թվեր

Production context-ի `calculationDay` և `targetDay` դաշտերը `BigInt` են։ Test-only oracle-ում օրերը, դարպասների ինդեքսները, դարպասների օրերը և տարվա համարը նույնպես `BigInt` են։ Նեղ `int`/`long` արժեքներ օգտագործվում են միայն այն տեղերում, որոնց նորմատիվ սահմանը նախապես փոքր է՝ օրինակ 1..720 bowl permutation rank-ը, 6..17 կոտլետների քանակը, 3..47 ամիսների քանակը կամ մինչև 5778 օրվա ներքին offset-ը։
