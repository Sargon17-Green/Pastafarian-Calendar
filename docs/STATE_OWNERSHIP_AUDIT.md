# Սեմանտիկ վիճակի պատկանելիության ստուգում — Stage 1

Այս ստուգումը վերաբերում է միայն Stage 1-ին և չի ներմուծում որևէ ապագա legacy կամ patch տրամաբանություն։

## Մոդուլի մակարդակի վիճակ

`source/pastafari/catalog.d` մոդուլում կան միայն `enum` manifest հաստատուններ և ֆունկցիաներ։ `cutletCatalog`-ը և `monthCatalog`-ը փոփոխական runtime storage չեն և չեն կարող կրել կանչերի պատմություն։

`source/pastafari/monster_base.d` մոդուլում mutable module global, `static`, `shared` կամ `__gshared` վիճակ չկա։

`tests/normative_oracle.d` մոդուլում նույնպես mutable module global, `static`, `shared` կամ `__gshared` վիճակ չկա։ Մոդուլի մակարդակում կան միայն `enum` հաստատուններ, alias-ներ, տիպեր և ֆունկցիաներ։

## Արտադրական համատեքստի պատկանելիությունը

`MonsterContext`-ը ստեղծվում է յուրաքանչյուր `MonsterManager.bootstrap` կանչի ներսում։ `calculationDay` և `targetDay`-ը `BigInt` արժեքային դաշտեր են՝ copy-on-write արժեքային semantics-ով։ `branchTrace` slice-ը և `MetricBook.counters` associative array-ը սկսվում են դատարկ վիճակից և առաջին փոփոխության ժամանակ պատկանում են տվյալ invocation-ին։ Ոչ մի reference դեպի context-ը manager-ում չի պահպանվում կանչի ավարտից հետո։

Նախնական տարբերակում `MonsterManager`-ը պահում էր validator/dispatcher/error-wrapper class reference-ներ manager-ի դաշտերում։ Դրանք սեմանտիկ state չունեին, բայց այդ storage-ը ընդհանուր էր նույն manager-ի հաջորդ invocation-ների համար և արտաքին փոփոխության հնարավոր մակերես էր։ Stage 1-ի ownership ուղղմամբ այդ դաշտերը հեռացվել են։ `BaseValidationManager`, `BaseDispatcher` և `BaseErrorWrapper` այժմ `final` class-եր են և ստեղծվում են տեղային՝ յուրաքանչյուր invocation-ի ընթացքում։ `MonsterManager`-ը persistent field չունի։

## Զանգվածների և հատվածների հղումային անկախությունը

Oracle-ի այն ֆունկցիաները, որոնք mutate են անում փոխանցված զանգվածի աշխատանքային տարբերակը, նախ վերցնում են սեփական պատճենը՝ օրինակ bowl state-ի համար օգտագործվում է `.dup`։ Նոր stone row-երը առանձին allocation-ներ են և չեն կիսում mutable row storage։

`WeavingFamily`-ի constructor-ը պարտադիր պահում է `lengths.dup`, այնպես որ caller-ի հետագա փոփոխությունը չի փոխում ընտանիքի count/unrank semantics-ը։ Մյուս DP family-ները պահում են scalar constructor input և իրենց memo associative array-ը պատկանում է միայն տվյալ class instance-ին։ Այդ memo-ն որևէ այլ family կամ invocation չի կիսում։

`SauceResult`-ի զանգվածները ստեղծվում են տվյալ sauce invocation-ի ներսում։ Մեկ վերադարձված արդյունքի bowl/order զանգվածի արտաքին փոփոխությունը չի կարող փոխել առանձին sauce invocation-ի արդեն վերադարձված կամ հետագայում հաշվարկվող արդյունքը։

## Նորմատիվ oracle-ի դասային հղումները և պահոցը

`OracleCalendar`-ը `final` class է։ Նրա `gates`, `minKnown` և `maxKnown` դաշտերը private instance state են։ Դրանք module global չեն։ Դարպասների cache-ը deterministic է և գոյություն ունի միայն տվյալ `OracleCalendar` instance-ի ներսում։

Stage 1-ի canonical test-only entry point-ը `normativeCalendarDate` է։ Այն յուրաքանչյուր կանչի համար ստեղծում է նոր `OracleCalendar`, ուստի տարբեր normative invocation-ներ չեն կիսում gate cache կամ այլ mutable class state։

## Դասային հղումների եզրակացություն

Production bootstrap-ի class reference-ներից ոչ մեկը չի պահպանվում invocation-ից invocation։ Oracle-ի mutable class reference-ները ստեղծվում են տվյալ գործողության համար և չեն պահվում module global registry-ում։ Բոլոր class-երը, որոնք պահում են mutable memo/cache state, `final` են, իսկ նրանց mutable դաշտերը private են։

## Կատարման հետընթացային ստուգումներ

`tests/stage01_tests.d`-ում ավելացվել են հետևյալ ownership regression-ները.

- նույն `MonsterManager`-ով երկու և կրկնվող invocation-ների `branchTrace` և metrics state-ի անկախություն,
- երկու անկախ stone table-ի և նույն table-ի տարբեր row-երի storage-ի անկախություն,
- caller-ի `monthLengths` slice-ի mutation-ից `WeavingFamily`-ի անկախություն,
- երկու նույնական sauce invocation-ների արդյունքների storage-ի անկախություն,
- երկու `OracleCalendar` instance-ներում դրական և բացասական gate հաշվարկների պատմությունից անկախ հավասարություն,
- ամբողջական canonical oracle entry point-ի compile-time հասանելիություն։

Այս regression-ների աղբյուրային ծածկույթը պատրաստ է, բայց տվյալ աշխատանքային միջավայրում D compiler չկա, ուստի դրանց native կատարումը դեռ չի հաստատվել։

## Եզրակացություն

Stage 1-ի source-level ownership audit-ը ավարտված է։ Օրերի առանցքի, դարպասների ինդեքսների և տարիների համարների համար 64-bit սահմանափակում չի մնացել։ Չկա mutable module global կամ static semantic state, invocation-ների միջև shared mutable production storage չկա, mutable slice/class storage-ի պատկանելիությունը սահմանված է, իսկ history-dependent cache-ը canonical oracle entry point-ում մեկ invocation-ի սահմաններից դուրս չի ապրում։ Մնացած միակ չկատարված քայլը native D build/run-ն է։
