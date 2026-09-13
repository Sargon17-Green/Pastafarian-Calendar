# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştiren 55 aşamalı bağımsız uygulama çizgisinin tamamlanmış durumudur. Özgün 55 aşamalı geliştirme kapsamı değiştirilmemiştir.

## Güncel aşama

Aşama 55/55 `AUDIT` tamamlanmıştır. Bu saved-sum düzeltmesi yeni bir geliştirme aşaması değildir; tamamlanmış ağacın kanonik semantiğine yapılan bir düzeltmedir.

```text
SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=YES
```

## Kanonik 12 final post-stir kuralı — 2026-09-11

Tomarın güncel hükmüne göre her post-stir turunda altı kâse için **tek bir eski snapshot** alınır:

```text
S = sum(oldBowls)
R = SAVE(S + 149*r)
permutationRank = 1 + ((R - 1) mod 720)
permutation = lexicographic permutation(permutationRank)

u = old[B]
  + 3*old[P]
  + 5*old[N]
  + R
  + r
  + position^2

new[B] = SAVE(u^2 + 7*old[P]*old[N])
```

Altı `new[B]` değeri aynı `oldBowls` snapshot'ından hesaplanır ve tur sonunda birlikte commit edilir. `R` yalnız permütasyon için değil, `u` içindeki ek terim için de kullanılır.

Aşağıdaki tarihsel varyant **yanlıştır** ve yalnız mutant/regresyon malzemesi olarak saklanır:

```text
R = SAVE(S + 149*r)
# permutation R'den
u = ... + S + r + position^2   # YANLIŞ
```

`src/pastafari_calendar/post_stir_bowlsum_detour.py` artık açıkça `HISTORICAL — SUPERSEDED` olarak işaretli test-mutantıdır. Üretim yolu bu modülü import etmez. `legacy_order_memory.postStirRoundExact` kanonik saved-sum kuralını uygular.

Tarihsel `corrective56_raw_bowlsum` bayrak/alan adları geriye dönük telemetry/API uyumluluğu için kalabilir; `legacy_structure_sauce.sauceWithCurrentScars` bu bayrağın semantiği değiştirmesine izin vermez.

## Eski “Düzeltici Aşama 56” kaydı

Önceki belgeler, raw bowl sum değerinin `u` içine konmasını “düzeltme” olarak tanımlıyordu. Bu hüküm **HISTORICAL — SUPERSEDED** durumundadır. Eski rapor ve witness'lar silinmemiş, açıkça tarihsel/yanlış olarak etiketlenmiştir. Eski raw-sum çıktı değerleri kanonik expected değer olarak kullanılmamalıdır.

## Kaynak dili

Bu uygulamanın programlama dili Python, insan kaynak dili Türkçedir. Metin normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

Kanonik kaynak dil kataloğunun sürümü `1.3.2`'dir; bu düzeltme yalnız sunum adlarını düzeltir ve `canonicalIndex` değerlerini değiştirmez.

## Doğrulama

Hedefli saved-sum testi:

```text
python -m unittest discover -s tests -p "corrective_stage_56_bowlsum_detour.py" -q
```

Tam yerel doğrulama zinciri:

```text
python -m unittest discover -s tests -p "test_stage_*.py" -q
python -m unittest discover -s tests -p "integration_stage_54.py" -q
python tests/run_stage_55_audit.py
python -m unittest discover -s tests -p "corrective_stage_56_bowlsum_detour.py" -q
python -m unittest discover -s tests -p "test_acceleration_patches_27_33.py" -q
```

Bu delta hazırlanırken tam repository çalışma ağacı bu oturumun yerel yürütme ortamına indirilemediği için yukarıdaki tam zincir burada **PASS olarak iddia edilmemektedir**. Delta metadata'sı hangi kontrollerin gerçekten çalıştırıldığını ve hangilerinin hazırlanıp çalıştırılmadığını ayrı ayrı kaydeder.
