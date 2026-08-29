# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin elli dördüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 54/55, `INTEGRATION` durumundadır ve `GREEN` olarak tamamlanmıştır.

Bütün yirmi altı discovery/patch çifti artık tek authoritative `calendar_date_spaghetti(calculation_day,target_day)` yolunda birleşir. Eski dispatcher/handler zinciri ve bütün historical scar'lar fiziksel olarak kalır ve önce çalışır; Aşama 39 terminal metni artık yalnız diagnostic scar'dır.

`FinalSpaghettiIntegrationManager` uzun program-counter state machine üzerinden gate cache, legacy 5781 candidate universe + late 5778 filter, year 5000, sequential year walk, guarded bad-key cache, structure ghost, cutlet filter, distinct-name detour, virtual month-length list, weaving ghost + exact DP unrank, month-name detour, contiguous-month ghost ve target dahil occurrence-count sonucunu birleştirir.

`sauceWithScars` production'ın mevcut patched sauce zincirini kullanır; test-only oracle hiçbir production yolundan import veya call edilmez.

Final sonuç tam beş alandır: year number, source-language cutlet name, day-in-cutlet, source-language month name ve day-in-month.

Integration testleri kaynak tüketimini historical regression process'inden ayırmak için ayrı Python process'te çalıştırılır. Bu yalnız test harness izolasyonudur; production semantics veya mode değiştirmez.

Aşama 55 audit kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- `calendar_date_spaghetti` artık authoritative integrated beş alanlı tarih sonucunu üretir; bütün historical başlangıç/patch zinciri fiziksel olarak korunur.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Historical regressions:

```text
python -m unittest discover -s tests -p "test_stage_*.py" -v
```

Beklenen: `365/365 PASS`.

Aşama 54 integration suite, ayrı ve taze Python process'inde:

```text
python -m unittest discover -s tests -p "integration_stage_54.py" -v
```

Beklenen: `10/10 PASS`.

Toplam doğrulama: `375` test, `0 failure`, `0 error`; depo durumu `GREEN`.
