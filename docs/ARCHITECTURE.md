# Սկզբնական ճարտարապետություն

Stage 1-ում ճարտարապետությունը դիտավորյալ դեռ չի պարունակում ապագա պատմական սպիները։ Այս փուլում թույլատրված է միայն ընդհանուր, չեզոք հիմքը։

`MonsterContext`-ը պատկանում է մեկ invocation-ի և չի կիսվում այլ կանչերի հետ։ Ներկա դաշտերը սահմանափակված են մուտքային օրերով, lifecycle-ի չեզոք վիճակով, deterministic branch trace-ով և ոչ սեմանտիկ metrics-ով։

`MonsterManager`-ը ստեղծում է context-ը և փոխանցում է այն `BaseDispatcher`-ին։ Dispatcher-ը գրանցում է միայն չեզոք bootstrap անցումը և կանչում է `BaseValidationManager`-ը։ `BaseErrorWrapper`-ը ստեղծում է մեքենայական կոդով սահմանված error boundary։

Metrics-ը դիտարկելիության state է և չի ընթերցվում նորմատիվ որոշում ընդունելու համար։ Այս փուլում production semantic state դեռ չի հաշվարկվում, ուստի snapshot/validate/commit մեխանիզմների կոնկրետ պատմական ձևերը չեն ավելացվել վաղաժամ։

Test-only oracle-ը production շղթայից անկախ է։ Այն սահմանում է մաքուր նորմատիվ ճշմարտությունը և չի կարող դառնալ runtime fallback կամ correction path։
