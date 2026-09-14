# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştiren 55 aşamalı bağımsız uygulama çizgisinin tamamlanmış durumudur. Özgün 55 aşamalı geliştirme kapsamı değiştirilmemiştir; sonraki düzeltmeler tamamlanmış ağacın kanonik semantiğini, performansını ve sürüm doğrulamasını sağlamlaştırır.

Paket sürümü `1.0.0` olarak hazırlanmıştır ve Python `>=3.11` gerektirir.

## Durum

Aşama 55/55 `AUDIT` tamamlanmıştır. 2026-09-11 tarihli saved-sum düzeltmesi yeni bir geliştirme aşaması değildir; tamamlanmış ağacın kanonik semantiğine yapılan düzeltmedir.

```text
SPAGHETTI_MONSTER_IMPLEMENTATION_COMPLETE=YES
```

## Kurulum

Depo kökünden:

```text
python -m pip install .
```

Geliştirme ağacını doğrudan çalıştırırken `src` dizinini Python yoluna eklemek yeterlidir.

## Genel API

Paketin ana dönüşüm çağrısı `calendar_date_spaghetti(calculation_day, target_day)` fonksiyonudur. Her iki girdi de kanonik `dayIndex` eksenindeki tam sayılardır. Foundation dayIndex değeri `-15055671`'dir.

```python
from pastafari_calendar import calendar_date_spaghetti

sonuc = calendar_date_spaghetti(739834, 739834)
print(sonuc)
```

Bu 2026 regresyon tanığı şu sonucu verir:

```text
SpaghettiDateResult(year_number=5000, cutlet_name='Böbrek', day_in_cutlet=306, month_name='Dil', day_in_month=23)
```

Dışa aktarılan diğer genel adlar `SpaghettiDateResult`, `sauceWithScars` ve `SOURCE_LANGUAGE_CATALOG` değerleridir.

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

`src/pastafari_calendar/post_stir_bowlsum_detour.py` açıkça `HISTORICAL — SUPERSEDED` olarak işaretli test-mutantıdır. Üretim yolu bu modülü import etmez. `legacy_order_memory.postStirRoundExact` kanonik saved-sum kuralını uygular.

Tarihsel `corrective56_raw_bowlsum` bayrak/alan adları geriye dönük telemetry/API uyumluluğu için kalabilir; `legacy_structure_sauce.sauceWithCurrentScars` bu bayrağın semantiği değiştirmesine izin vermez.

## Eski “Düzeltici Aşama 56” kaydı

Önceki belgeler, raw bowl sum değerinin `u` içine konmasını “düzeltme” olarak tanımlıyordu. Bu hüküm **HISTORICAL — SUPERSEDED** durumundadır. Eski rapor ve witness'lar silinmemiş, açıkça tarihsel/yanlış olarak etiketlenmiştir. Eski raw-sum çıktı değerleri kanonik expected değer olarak kullanılmamalıdır.

## Kaynak dili

Bu uygulamanın programlama dili Python, insan kaynak dili Türkçedir. Metin normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

Kanonik kaynak dil kataloğunun sürümü `1.3.2`'dir; bu düzeltme yalnız sunum adlarını düzeltir ve `canonicalIndex` değerlerini değiştirmez.

## Soğuk başlangıç performansı

Modern tarihler için üretim kapı önbelleği, bağlayıcı kapı-aralığı kuralından türetilmiş statik kontrol noktalarıyla yeniden demirlenir. Bu bir semantik kısayol değildir: aynı kapı dizisini daha yakın, deterministik bir başlangıç noktasından yürür.

Release regresyonu iki 2026 production dönüşümünü temiz bir Python sürecinde çalıştırır ve 45 saniyelik geniş bir üst sınır uygular. Bu sınır bir performans vaadi değildir; eski 120+ saniyelik soğuk başlangıç gerilemesinin geri dönmesini yakalamak içindir.

## Eski Python uygulamasıyla diferansiyel regresyon

Altı tarihsel tanık, eski Python uygulamasındaki sonuçlarla kanonik köfte ve ay indeksleri üzerinden karşılaştırılır. Bu eski uygulama yalnız **regresyon kanıtıdır** ve normatif otorite değildir. Çelişki halinde İbranice Tomar ve bağımsız normatif referans üstündür.

## Doğrulama

GitHub Actions'taki final doğrulama zinciri aşağıdaki grupları çalıştırır:

```text
python -m unittest discover -s tests -p "test_stage_*.py" -q
python -m unittest discover -s tests -p "integration_stage_54.py" -q
python tests/run_stage_55_audit.py
python -m unittest discover -s tests -p "corrective_stage_56_bowlsum_detour.py" -q
python -m unittest discover -s tests -p "test_acceleration_patches_27_33.py" -q
python -m unittest discover -s tests -p "test_release_legacy_python_differential.py" -q
```

Mevcut final doğrulama toplamı **421 PASS** olarak sabitlenmiştir:

- 365 historical regression
- 10 Aşama 54 integration
- 21 Aşama 55 final audit
- 7 kanonik saved-sum discriminator
- 12 acceleration correctness/regression
- 6 eski Python diferansiyel regresyon

Release hazırlık zincirinde bu testlere ek olarak temiz sdist/wheel kurulumu, taze sanal ortam smoke testleri ve son SHA256 doğrulaması ayrı adımlarda yapılır.
