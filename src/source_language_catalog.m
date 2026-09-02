:- module source_language_catalog.
:- interface.

:- import_module list.
:- import_module maybe.

:- type catalog_kind
    --->    cutlet
    ;       month.

:- type catalog_entry
    --->    catalog_entry(
                canonical_index :: int,
                source_text     :: string
            ).

:- func catalog_version = string.
:- func cutlet_entries = list(catalog_entry).
:- func month_entries = list(catalog_entry).
:- func resolve(catalog_kind, int) = maybe(string).
:- pred catalog_is_frozen is semidet.

:- implementation.

catalog_version = "mn-MN-source-v1".

cutlet_entries = [
    catalog_entry(1,  "Хүрэл"),
    catalog_entry(2,  "Үнэг"),
    catalog_entry(3,  "Бөөр"),
    catalog_entry(4,  "Лагаш"),
    catalog_entry(5,  "Бодол"),
    catalog_entry(6,  "Есний дөрөв"),
    catalog_entry(7,  "Фалгураш"),
    catalog_entry(8,  "Зэгс"),
    catalog_entry(9,  "Усан үзмийн багц"),
    catalog_entry(10, "Хилэнц"),
    catalog_entry(11, "Үнс"),
    catalog_entry(12, "Буудай"),
    catalog_entry(13, "Гол"),
    catalog_entry(14, "Инээд"),
    catalog_entry(15, "Аккад"),
    catalog_entry(16, "Эвэр"),
    catalog_entry(17, "Хоосон ваар")
].

month_entries = [
    catalog_entry(1,  "Шавар"),
    catalog_entry(2,  "Анар"),
    catalog_entry(3,  "Тохой"),
    catalog_entry(4,  "Атаархал"),
    catalog_entry(5,  "Эриду"),
    catalog_entry(6,  "Шүдний оо"),
    catalog_entry(7,  "Тавны гурав"),
    catalog_entry(8,  "Каршумаб"),
    catalog_entry(9,  "Бар"),
    catalog_entry(10, "Цагаан тугалга"),
    catalog_entry(11, "Манан"),
    catalog_entry(12, "Гүгэл"),
    catalog_entry(13, "Ээрүүл"),
    catalog_entry(14, "Хавирга"),
    catalog_entry(15, "Кароб"),
    catalog_entry(16, "Урук"),
    catalog_entry(17, "Ичгүүр"),
    catalog_entry(18, "Тэмээ"),
    catalog_entry(19, "Зэс"),
    catalog_entry(20, "Худаг"),
    catalog_entry(21, "Өндөгний шар"),
    catalog_entry(22, "Од"),
    catalog_entry(23, "Зөгийн бал"),
    catalog_entry(24, "Дэлүү"),
    catalog_entry(25, "Шохойн чулуу"),
    catalog_entry(26, "Баяр хөөр"),
    catalog_entry(27, "Инжир"),
    catalog_entry(28, "Ниневе"),
    catalog_entry(29, "Мэлхий"),
    catalog_entry(30, "Битум"),
    catalog_entry(31, "Лаа"),
    catalog_entry(32, "Хаалттай хаалга"),
    catalog_entry(33, "Гүнжид"),
    catalog_entry(34, "Дагз"),
    catalog_entry(35, "Мөнгө"),
    catalog_entry(36, "Сараана"),
    catalog_entry(37, "Шуурга"),
    catalog_entry(38, "Илжиг"),
    catalog_entry(39, "Гурил"),
    catalog_entry(40, "Харамсал"),
    catalog_entry(41, "Вавилон"),
    catalog_entry(42, "Хэл"),
    catalog_entry(43, "Маалинга"),
    catalog_entry(44, "Давс"),
    catalog_entry(45, "Лийр"),
    catalog_entry(46, "Нум"),
    catalog_entry(47, "Элс")
].

resolve(Kind, Index) = Result :-
    (
        Kind = cutlet,
        Result = resolve_in(cutlet_entries, Index)
    ;
        Kind = month,
        Result = resolve_in(month_entries, Index)
    ).

:- func resolve_in(list(catalog_entry), int) = maybe(string).

resolve_in([], _) = no.
resolve_in([catalog_entry(I, S) | Rest], Wanted) = Result :-
    ( if I = Wanted then
        Result = yes(S)
    else
        Result = resolve_in(Rest, Wanted)
    ).

catalog_is_frozen :-
    catalog_version = "mn-MN-source-v1",
    cutlet_entries = Cutlets,
    month_entries = Months,
    list.length(Cutlets) = 17,
    list.length(Months) = 47.
