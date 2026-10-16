# Serahan Stage 15 — PATCH 07

**Cabang:** `PHP+Bahasa-Melayu`  
**Asas:** `19eff3ad1b92c24a3afe52a36b0e5decb0f717f3`  
**Tahap:** 15 daripada 55; PATCH 07; keadaan sasaran `GREEN`.

## Syarat sumber dan sejarah

`src/Legacy/LegacyVisibleGrind.php` tidak diubah. Fungsi `legacyGrindRows()` masih mempunyai sebelas baris pada indeks 0..10; `legacyRowAt` masih membaca indeks g=1..11 dengan fallback baris 0 apabila g=11. Ini dibuktikan oleh `visibleDropsLegacy` pada dispatcher `VISIBLE_GRIND_LEGACY`.

`src/Patches/GrindTablePatch07.php` menghasilkan jadual dengan sentinel pada 0 dan sebelas baris sah pada 1..11 melalui `LegacyVisibleGrind::legacyGrindRows()`. Ia menggunakan kelas legacy yang sama melalui suntikan jadual, tanpa mengubah rumus titisan atau menghapus pembaca sejarah. Laluan sah `BootstrapKernel::visibleDrops` menghala kepada `VISIBLE_GRIND_PATCH_07`.

## Ujian penerimaan

```text
php -d memory_limit=512M tests/verify_stage14_discovery07.php
php -d memory_limit=512M tests/stage15_patch07_tests.php
```

Stage 14 mesti kekal RED yang dijangka, 138 penyimpangan dan tiada ralat; pengesah mengesahkannya dengan status 0. Ujian Stage 15 mesti mengembalikan status 0 dengan 368 nilai terlihat normatif bagi lapan pasangan, 138 parut legacy, 46 ujian per-instance, dan 1,408 pemeriksaan baris sentinel. Semua regresi Stage 1–13, pemeriksaan nama kanonik, fixture dan sintaks PHP diwajibkan hijau.

## Larangan

Jangan memadam `legacyRowAt`, jangan mengubah jadual sejarah 0..10, jangan meletakkan sentinel ke dalam kaedah legacy asal, jangan memasukkan oracle ke produksi, jangan ubah `main`, dan jangan mulakan Stage 16.

## Bukti GitHub Actions

Run 38923823861 telah disahkan lulus; kedua-dua pekerjaan GitHub Actions berjaya dan semua regresi Stage 1–14 hijau.


### Bukti GitHub Actions Stage 15 — disahkan

**Run:** `38923823861`  
**SHA diperiksa:** `8fc05d7687acf128026dfdc3a61bb851f9b32adf`  
**Pekerjaan:** `verify=success`; `audit_php_bahasa_melayu=success`.

```text
RINGKASAN lulus=15 gagal=0
LULUS Stage 13 PATCH 06 positif=762 hidden=66 oracle_hidden=42 sintetik=2688 ralat=7
KEPUTUSAN MERAH_DIJANGKA divergence=138 kes=3 julat=138 lain=0
LULUS kontrak merah 07; legacy kekal salah dan sentinel hanya dalam tampalan
LULUS Stage 15 PATCH 07 kes=8 komponen=368 parut=138 ulang=46 baris_sintetik=1408
```

Semua ujian Stage 1–14, pemeriksaan nama kanonik dan fixture turut lulus. Stage 15 ialah PATCH GREEN yang diterima; Stage 16 belum bermula. Tidak terdapat handoff PHP aktif dalam `Pending_User_Execution`.
