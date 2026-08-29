# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 2/55, `DISCOVERY 01` durumundadır. Birinci tarihsel yanlış varsayım gerçek üretim çağrı zincirine eklenmiştir: `oldRemainder(x)` büyük sayaca göre sıradan kalanı alır ve tam katları `0` olarak bırakır.

Bu aşamada düzeltme bilerek yoktur. `M`, `2M` ve `3M` örnekleri normatif kaydetme işlemiyle ayrıştığı için yeni regresyonun kırmızı olması beklenir. `M+1` örneği uyuşur. Birinci aşamadan kalan bütün regresyonların geçmesi gerekir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Önceki regresyonlar:

```text
python -m unittest discover -s tests -p "test_stage_01.py" -v
```

Tam ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

İkinci komutun yalnızca yeni `DISCOVERY 01` regresyonunda beklenen kırmızıyı göstermesi gerekir. Düzeltme bir sonraki aşamaya aittir.
