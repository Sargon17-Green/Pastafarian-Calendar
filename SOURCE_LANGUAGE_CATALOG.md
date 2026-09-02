# Katalog Bahasa Sumber

Versi katalog: `ms-1.0.0-stage01`.

Katalog ini beku selepas Stage 1. Urutan normatif ditentukan hanya oleh `canonicalIndex`. Teks Bahasa Melayu tidak pernah digunakan untuk sort, rank, unrank, cache key semantik atau pemilihan.

## Kaedah terjemahan

Nama yang mempunyai makna leksikal diterjemahkan mengikut maknanya. Contohnya, nama yang bermakna gandum menjadi `gandum`, garam menjadi `garam`, sungai menjadi `sungai`, dan pintu tertutup menjadi `pintu tertutup`.

Bagi dua entri yang boleh membawa lebih daripada satu nuansa dalam sumber, bootstrap ini membekukan tafsiran leksikal berikut: `canonicalIndex` 1 diperlakukan sebagai gangsa dan `canonicalIndex` 8 diperlakukan sebagai gelagah. Tafsiran ini menjadi sebahagian daripada katalog Stage 1 dan tidak boleh diubah pada tahap kemudian tanpa perubahan spesifikasi yang jelas.

## Kaedah transliterasi

Nama tempat sejarah yang mempunyai ejaan Latin konvensional dikekalkan dengan ejaan katalog tetap: `Lagash`, `Akkad`, `Eridu`, `Uruk`, `Nineveh` dan `Babylon`.

Bagi nama ciptaan yang tidak mempunyai makna leksikal, transliterasi menggunakan ejaan Rumi yang tetap. Bunyi /ʃ/ ditulis `sy`; oleh itu bentuk katalog ialah `Palgurasy` dan `Karsyumab`. Huruf vokal dikekalkan mengikut bentuk sumber yang dibekukan dalam katalog. Kaedah ini tidak digunakan untuk menentukan urutan normatif; ia hanya menghasilkan rentetan paparan bagi indeks yang sudah dipilih.

## Jaminan indeks

- Potongan mempunyai indeks 1 hingga 17, setiap indeks tepat sekali.
- Bulan mempunyai indeks 1 hingga 47, setiap indeks tepat sekali.
- Semua operasi kombinatorik menggunakan indeks, bukan rentetan.
- Locale tambahan pada masa hadapan hanya boleh menterjemah rentetan Bahasa Melayu dan tidak boleh mempengaruhi semantik.
