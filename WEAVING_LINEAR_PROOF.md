# lo pa se stika te jicmu be lo masti porsi

## lo pamoi .e lo fanmo javni

ni'o lo masti cu se porsi fi lo judri be lo pamoi se viska .e lo fanmo se viska .i lo pamoi se viska be lo masti poi se namcu li j cu purci lo pamoi se viska be lo masti poi se namcu li j+1 .i lo fanmo se viska cu se porsi sa'u.

ni'o lo `N_j` cu du lo se namcu be lo djedi be lo pamoi `j` masti .i lo fanmo se viska be lo `j` moi masti cu du lo `N_j` moi djedi. va'o lo nu lo drata masti cu balvi lo fanmo se viska be lo `j` moi masti kei lo fanmo javni cu na drani. seni'i lo fanmo judri cu na nitcu lo tcadu te jicmu namcu: ri cu du lo `N_j` sa'u.

## lo pamoi masti stodi namcu

ni'o lo `A_j(f)` cu du lo se namcu be lo drani porsi be lo pamoi `j` masti poi lo pamoi se viska be lo `j` moi masti cu zvati lo `f` moi djedi. lo fanmo judri cu du lo `N_j` sa'u. lo `q_1` cu du lo djedi be lo pamoi masti.

```text
A_1(1) = 1
A_1(f) = 0 for f != 1
N_1 = q_1
```

## lo cnino masti be za'u pa djedi

ni'o lo `N` cu du lo se namcu be lo purci djedi .i lo `q` cu du lo cnino masti djedi .i lo `f` cu du lo pamoi se viska judri be lo cnino masti.

```text
if first opening must be ordered:
    A_new(f) = C(N+q-f-1, q-2) * sum(A_old(F) for F < f)

if first opening already happened before this suffix:
    A_new(f) = C(N+q-f-1, q-2) * sum(A_old(F) for all F)

1 <= f <= N+1
N_new = N+q
```

ni'o lo fanmo se viska be lo cnino masti cu zvati lo `N+q` moi djedi .i lo cnino masti cu ralte lo `q-2` drata djedi be lo pamoi .e lo fanmo .i ri cu se cuxna fi lo `N+q-f-1` se judri. lo purci masti fanmo se viska cu zvati lo `N` moi djedi .i ri cu se pu lo cnino masti fanmo djedi sa'u.

ni'o va'o lo nu lo cnino masti na pu se pamoi se viska kei lo purci masti pamoi judri cu se purci lo cnino `f` moi djedi. seni'i lo `F<f` cu te javni. va'o lo nu lo cnino masti cu pu se pamoi se viska pu lo se benji suffix kei lo pamoi javni cu na se sarcu .i seni'i lo `F` cu se cuxna ro drata se judri.

## lo cnino masti be pa djedi

```text
A_new(N+1) = sum(A_old(F) for all F)
A_new(f) = 0 for f != N+1
```

ni'o lo pa djedi masti cu se fanmo se viska fi lo fanmo djedi be lo cnino se jmina porsi. ri cu se pamoi se viska fi lo sa'u fanmo djedi. seni'i lo binomio te jicmu cu na sarcu.

## lo se sruri datni jimte

ni'o ro se jmina cu pilno lo `BigInteger[]` be lo `N+q+2` se judri .i lo purci se jmina namcu .e lo cnino se jmina namcu cu se ralte pa moi ma'i lo jmina se mokca .i lo se sruri datni se namcu cu zenba sepa'a lo `O(N)` .i lo se namcu be lo nu samcpli cu zenba sepa'a lo `O(m*N)` BigInteger te pilno, lo bitni co'u se namcu cu se zmadu gi'e zenba lo pindi temci.

ni'o lo `MonsterWeavingLinearCounter` cu pilno lo nu na se galfi lo se benji `lengths` gi'e benji lo `count` .e lo `countAfterPrefix` .i lo `opened` .e lo `closed` cu ralte lo cfari se jicmu fi lo prefix .i lo tcadu te javni cu za'o drani.

ni'o lo 47 masti cu ralte lo 5778 djedi fi lo `46*123+120` .i lo GitHub Actions run `38164523435` cu cipra lo se namcu fi lo Java `-Xmx256m` .e lo `NormativeOracle` .e lo `MonsterWeavingEndpointDP`. ri cu snada.

## lo to'e se zbasu se cuxna

ni'o lo `count` cu na se du lo `unrank1`. lo `MonsterWeavingLinearCounter` cu na fanva lo ranki fi lo mulno 5778 djedi. lo `MonsterCanonicalWeaving` cu za'o se jimte li 512 djedi .i lo `MonsterCalendarResolver` cu nitcu lo se cuxna `weaving`. seni'i lo remoi stadi cu za'o na se mulno.

## lo lexicographic ranki se cuxna

ni'o lo `unrank1` cu cfari fi lo `count` .e lo `rank`. ro `id` poi te porsi fi lo cmalu `id` cu se cipra fi lo `countSuffix` va'o lo nu lo `id` cu se jmina lo se cuxna prefix. lo ranki cu se vimcu lo se namcu be lo na se cuxna pagbu, gi'e cuxna lo pamoi pagbu poi vasru lo ranki.

ni'o lo `rank1` cu cfari fi li pa .i ri cu jmina lo se namcu be ro pagbu poi se te porsi purci lo se cuxna `id`. seni'i lo se xruti ranki cu du lo cfari ranki fi lo drani `unrank1` .i lo drani prefix cu se facki fi lo `opened` .e lo `closed` se jicmu.

ni'o lo `MAX_UNRANK_DAYS` cu du li 512 .i lo `MAX_DAYS` be lo `count` cu du li 5778 .i lo GitHub Actions run `38164930943` cu se cipra lo lexicographic ranki .i lo run `38165113120` cu se cipra lo vo moi kabri .e lo 32 moi tcita, lo 492 .e lo 512 djedi se namcu. lo 5778 djedi unrank cu za'o na se zbasu.
