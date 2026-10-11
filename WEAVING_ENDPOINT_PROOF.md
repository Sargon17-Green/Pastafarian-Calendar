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

ni'o ca ti lo count cu se jimte li 512 detri .i lo `unrank1` cu se jimte li 96 detri, ki'u lo nu ro cuxna cu sarcu lo balvi se namcu krefu. lo 5778 detri nanca cu na se cipra lo mulno .i lo remoi stadi cu ca'o se zbasu gi'e na se tcita lo mulno.
