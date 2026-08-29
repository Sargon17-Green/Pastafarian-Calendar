# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 30/55, `DISCOVERY 15` durumundadır.

Yeni tarihsel helper:

```text
oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n
```

olarak korunur.

`LegacyGateQuestionAdapter`, signed step işaretini kaybedip `abs(signed_step)` değerini helper'a verir. Sonuç olarak negatif gate sorguları Foundation'ın negatif tarafı yerine pozitif tarafını sorar.

Real calendar state-machine bu yolu `signed_step=-1` ile gerçekten çalıştırır.

Yeni normatif regresyon `-1`, `-2` ve `-10` değerlerinde actual adapter sonucunu `FOUNDATION_DAY-abs(step)` beklentisiyle karşılaştırır ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 15` yoktur. Negatif signed step için corrected question-day detour'u eklenmemiştir.

Patch 16 year-limit kodu da henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–29 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni negative-gate normatif regresyonunun `-1`, `-2` ve `-10` alt örnekleri başarısız olur.
