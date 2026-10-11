# lo cipra javni be lo te porsi masti be lo pamoi .e lo fanmo

## lo narmanci namcu

ni'o lo masti se namcu cu du `q_1,...,q_m`. lo porsi cu ralte lo `q_i` se pamoi namcu be lo masti `i` .i lo pamoi se viska be lo masti cu se porsi fi lo masti judri .i lo fanmo se viska be lo masti cu se porsi fi lo masti judri.

ni'o lo `D_j(F,L)` cu du lo se namcu be lo drani porsi be lo pamoi `j` masti poi lo pamoi detri be lo `j` moi masti cu zvati lo judri `F` gi'e lo fanmo detri cu zvati lo judri `L`. lo pamoi masti se pagbu cu du pa porsi .i `D_1(1,q_1)=1`. lo drata se namcu cu du li no.

## lo `q>=2` se jicmu

ni'o lo `N` cu du lo se namcu be lo purci detri. lo `q` cu du lo cnino masti se namcu. lo `f` .e lo `l` cu du lo pamoi .e lo fanmo judri be lo cnino masti.

```text
D_new(f,l) = C(l-f-1,q-2) *
             sum { D_old(F,L) : L <= l-q, and (not firstOrder or F < f) }
```

ni'o lo se judri poi purci lo `f` cu ralte lo purci masti po'o. i seni'i lo pamoi se viska be lo purci fanmo masti cu purci lo `f` va'o lo nu `F<f`. lo se judri poi balvi lo `l` cu ralte lo purci masti po'o. i seni'i lo `l-q` purci masti detri cu purci lo `l` .i lo purci fanmo masti cu purci lo cnino fanmo masti va'o lo nu `L<=l-q`.

ni'o lo cnino masti cu ralte re se stika judri `f` .e `l`. lo `q-2` cnino se stika detri cu se cuxna fi lo `l-f-1` judri be lo se kansa .i lo se namcu be lo se cuxna cu du `C(l-f-1,q-2)`. lo se narmanci ku'o ro se cuxna cu du pa cnino porsi .i ro cnino porsi cu se zbasu fi pa purci porsi .e pa se cuxna .i seni'i lo se namcu cu drani.

## lo `q=1` se jicmu

```text
D_new(p,p) = sum { D_old(F,L) : L <= p-1 }
```

ni'o lo cnino masti cu du pa detri .i lo fanmo te javni cu se cuxna lo nu `L<=p-1`. lo pamoi te javni cu se snada suni'i lo fanmo te javni, ki'u lo nu `F<=L`.

## lo se benji pamoi se detri

ni'o lo `opened` cu du lo se namcu be lo masti poi se pamoi se viska .i lo `closed` cu du lo se namcu be lo masti poi se fanmo se viska. lo pamoi te javni cu se sarcu ca lo nu lo purci fanmo masti cu na pu se pamoi se viska. lo fanmo te javni cu se sarcu ro roi ca lo nu lo purci fanmo masti cu na pu se fanmo se viska.

ni'o lo se stika porsi cu se cuxna fi lo `unrank1` .i ro se cuxna judri cu se namcu fi lo porsi be lo se slabu te javni. lo ranki cu se vimcu lo se namcu be lo na se cuxna pagbu .i lo pamoi se cuxna pagbu cu se stika.

## lo barda namcu jimte

ni'o lo se namcu be lo stika `D` cu zenba fi lo `O(m*D^2)` BigInteger se pilno te jicmu, poi `D` cu du lo detri se namcu. lo spisa se ralte cu zenba fi lo `O(D^2)` porsi judri .i lo BigInteger se bitni se namcu cu zenba fi lo mutce barda se namcu, i sena'i lo `O(D^2)` cu naljavni lo mutce barda mutce slabu memori.

ni'o ca ti lo count cu se jimte li 2048 detri .i lo `unrank1` cu se jimte li 384 detri, ki'u lo nu ro cuxna cu sarcu lo balvi se namcu krefu. lo 5778 detri nanca cu na se cipra lo mulno .i lo remoi stadi cu ca'o se zbasu gi'e na se tcita lo mulno.

## lo fanmo masti binomio te javni

ni'o lo `N` cu du lo purci detri se namcu .i lo `q` cu du lo fanmo cnino masti detri se namcu .i lo `F` .e lo `L` cu du lo pamoi .e lo fanmo judri be lo purci fanmo masti.

```text
firstOrder:
T(N,q,F,L) = C(N+q-F,q) - C(L+q-1-F,q)

alreadyOpened:
T(N,q,L) = C(N+q,q) - C(L+q-1,q)

C(n,k) = 0 when n < k
terminalTotal = sum { D_old(F,L) * T(N,q,F,L) }
```

ni'o lo `N+q` detri judri cu kakne lo nu se cuxna `q` cnino detri. lo pamoi narmanci javni cu sarcu lo nu lo cnino masti pamoi detri cu balvi lo `F` moi purci detri .i seni'i lo se cuxna se namcu cu du `C(N+q-F,q)`. lo fanmo narmanci javni cu sarcu lo nu lo cnino masti fanmo detri cu balvi lo `L` moi purci detri .i lo na se snada be lo fanmo javni cu se namcu `C(L+q-1-F,q)`. lo se namcu be lo drani se cuxna cu du lo nu vimcu lo na se snada fi lo ro se cuxna.

ni'o va'o lo nu lo cnino masti cu pu se pamoi se viska, lo pamoi javni cu na sarcu .i lo `F` cu se banzu lo nu du li no .i lo fanmo javni cu za'o sarcu. seni'i lo `alreadyOpened` se namcu cu drani.

ni'o lo fanmo masti te jicmu cu na se zbasu ca lo `terminalInsertTotal` cu se pilno. lo `EndpointTable` cu ralte lo trene se judri po'o gi'e pilno lo se binomio `BigInteger` .i lo 2048 detri count .e lo 384 detri rank cu se cipra fi lo GitHub Actions run `38162079095`.

## lo ranki se xruti

ni'o lo `rank1` cu cfari fi li pa .i ro `k` poi prami lo se cuxna masti `j` cu se namcu fi lo `countSuffix` .i lo se namcu be ro drata masti poi me lo pamoi porsi gi'e se cmima lo drani balvi se porsi cu se jmina lo ranki. lo `unrank1` cu vimcu lo sa'u te cuxna ranki gi'e cuxna lo pamoi pagbu poi drani. seni'i lo re sampla cu se xruti fi lo porsi se ranki poi drani.

ni'o lo ro porsi se ranki cu te sarcu lo `BigInteger` .i lo 5778 detri nanca cu za'o na se cipra .i lo du'o mutce barda so'i masti cu za'o nitcu lo balvi se sruri datni javni.
