# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırkıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 40/55, `DISCOVERY 20` durumundadır.

Exact historical helper:

```text
oldStructureSauce(cDay,originalTargetDay)
```

production'a eklenmiştir.

Real calendar path user original target için sauce'u daha önce zaten hesapladığından helper mevcut final bowls ve drop-46 latch sonucunu invocation-local binding üzerinden kullanır; eski sauce phases ikinci kez çalıştırılmaz.

Standalone `sauceWithCurrentScars` current Python implementation'ın kendi production adapter zinciriyle aynı sauce sonucunu yeniden üretebilir.

Real state-machine resolved year first day değerini bilir, fakat old helper hâlâ user original target ile çağrılır ve old sauce doğrudan `LegacyStructureSelectorAdapter` inputuna gider.

Yeni normatif regression üç witness üzerinde actual selector token değerini test-only `sauce(cDay,yearFirstDay)` sonucu ile karşılaştırır ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 20` yoktur: old sauce ghost değildir, `(cDay,year.firstDay)` authoritative recomputation semantic yola girmez ve old result selector'dan ayrılmaz.

Patch 21 cutlet partition prefix-gate filter kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırkıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–39 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni original-target structure sauce versus year-first-day selector regressionunun üç alt örneği başarısız olur.
