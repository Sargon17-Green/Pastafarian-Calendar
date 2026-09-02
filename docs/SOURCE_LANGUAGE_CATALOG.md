# SourceLanguageCatalog — Filipino

Bersyon: `1.0.0-stage01`

Ang catalog ay frozen sa pagtatapos ng Stage 1. Bawat pangalan ay may permanenteng `canonicalIndex`. Ang index, hindi ang string, ang ginagamit sa normative sort, rank, unrank, selection, cache key, at mga test ng semantics.

## Patakaran sa pagsasalin

Kapag literal ang kahulugan, isinasalin ang kahulugan sa natural na Filipino. Ang buong parirala ay nananatiling iisang pangalan; halimbawa, ang mga fractional phrase ay isinasalin bilang isang buong pariralang Filipino.

Kapag pangalan ng lugar, pangalan ng sarili, o sadyang imbentong tunog ang pinagmulan, hindi ito binibigyan ng bagong kahulugan. Gumagamit ang catalog ng nakapirming Latin spelling na dokumentado rito: `Lagash`, `Palgurash`, `Akkad`, `Eridu`, `Karshumab`, `Uruk`, `Nineve`, at `Babilonia`.

Ang lokalisasyon sa hinaharap ay presentation layer lamang:

```text
canonical semantics -> canonicalIndex -> Filipino source string -> locale translation
```

Hindi kailanman binabaligtad ang daloy upang gawing semantic input ang localized string.

## Cutlet catalog

1. Bronse
2. Soro
3. Bato
4. Lagash
5. Kaisipan
6. Apat na bahagi sa siyam
7. Palgurash
8. Tambo
9. Kumpol
10. Alakdan
11. Abo
12. Trigo
13. Ilog
14. Tawa
15. Akkad
16. Sungay
17. Walang-lamang banga

## Month catalog

1. Luwad
2. Granada
3. Siko
4. Inggit
5. Eridu
6. Pasta ng ngipin
7. Tatlong bahagi sa lima
8. Karshumab
9. Tigre
10. Estanyo
11. Hamog
12. Kamanyang
13. Ikiran
14. Tadyang
15. Karob
16. Uruk
17. Hiya
18. Kamelyo
19. Tanso
20. Balon
21. Pula ng itlog
22. Bituin
23. Pulot
24. Pali
25. Batong-apog
26. Saya
27. Igos
28. Nineve
29. Palaka
30. Alkitran
31. Kandila
32. Saradong pinto
33. Linga
34. Batok
35. Pilak
36. Liryo
37. Bagyo
38. Asno
39. Harina
40. Pagsisisi
41. Babilonia
42. Dila
43. Lino
44. Asin
45. Peras
46. Bahaghari
47. Buhangin
