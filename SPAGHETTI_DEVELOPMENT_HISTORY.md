# Սպագետի զարգացման պատմություն

## Stage 1 — Bootstrap

### Ինչ կառուցվեց

Իրականացման գիծը ստեղծվեց զրոյից D լեզվով և ժամանակակից հայերեն աղբյուրային լեզվով։ Ստեղծվեցին կանոնական լեզվական կատալոգը, test-only նորմատիվ oracle-ը, տեղային թեստային harness-ը և production-ի չեզոք հիմքը։

### Մոնստրային շերտի աճը

Ավելացվեց միայն այն ընդհանուր հիմքը, որը թույլատրված է Bootstrap-ում՝ invocation-ին պատկանող context, manager, dispatcher, validator, error wrapper և metrics shell։ Այս շերտերը դեռ չեն պարունակում որևէ կոնկրետ legacy սխալ կամ ապագա patch-ի տրամաբանություն։

### Սեմանտիկ անվտանգությունը

Production bootstrap-ը նորմատիվ օրացուցային պատասխան չի հաշվարկում և oracle չի կանչում։ Metrics-ը միայն դիտարկելիության համար է։ Կատալոգի նորմատիվ կարգը որոշվում է միայն `canonicalIndex`-ով։

### Վիճակի պատկանելիության ճշգրտումը

Bootstrap-ի ownership audit-ի ընթացքում պարզվեց, որ `MonsterManager`-ը պահում էր երկարատև coordinator class reference-ներ։ Դրանք semantic state չէին պահում, բայց նույն manager-ի հաջորդ invocation-ների միջև shared mutable storage-ի ավելորդ մակերես էին ստեղծում։ Դաշտերը հեռացվեցին, coordinator class-երը դարձան `final`, և դրանք այժմ ստեղծվում են invocation-local ձևով։ Oracle-ի cache/memo ownership-ը նույնպես փակվեց instance-local/private սահմաններով, իսկ canonical oracle entry point-ը նոր calendar instance է ստեղծում յուրաքանչյուր կանչի համար։ Սա Stage 1-ի չեզոք ենթակառուցվածքի ուղղում է և ապագա patch չէ։

### Ճշգրիտ ամբողջ թվերի ճշգրտումը

Bootstrap-ի լրացուցիչ audit-ի ընթացքում հայտնաբերվեց, որ օրերի առանցքը, gate index-ները և year number-ը նախնական oracle-ում պահվում էին `long`/`int`-ով։ Դա չէր բավարարում կամայական ճշտության ամբողջ թվերի պահանջը։ Stage 1-ի ներսում դրանք փոխվեցին `BigInt`-ի, իսկ նեղ integer conversion-ները մնացին միայն նախապես սահմանափակված տեղային չափերի համար։ Սա Stage 1-ի հիմքի ուղղում է և 01–26 ապագա patch-երից ոչ մեկը չէ։

### Ինչ դեռ չի եղել

Ոչ մի DISCOVERY դեռ չի կատարվել։ Ոչ մի legacy սխալ չի ներմուծվել, և 01–26 patch-երից ոչ մեկը ներկա չէ։
