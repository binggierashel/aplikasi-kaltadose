# Kalta Farm — Smart Autodosing Nutrisi AB Mix (Flutter Android)

Aplikasi Android berbasis Flutter untuk sistem **Smart Autodosing Nutrisi AB Mix pada Tanaman Melon di Greenhouse Kalta Farm**, dibangun sesuai dokumen **SKPL (KF-01 s.d. KF-13)**, **DPPL (DPPL.KF-01 s.d. DPPL.KF-13)**, serta desain antarmuka pada `prototipe-kalta-farm`.

## Fitur Utama

- **Autentikasi & Hak Akses (`KF-01`, `KF-12`, `KF-13`)**: Login & logout untuk peran **Owner** dan **Petani**, penolakan akun nonaktif, auto-logout 30 menit tidak aktif, edit profil, ubah password, serta pengelolaan akun pengguna khusus Owner dengan perlindungan **Owner aktif terakhir**.
- **Dashboard Pemantauan (`KF-02`)**: Nilai **Nutrisi / TDS (ppm)**, **Suhu larutan (°C)**, **Level air (%)**, mode operasi, grafik tren interaktif (`fl_chart`), status 4 aktuator, serta mode simulasi telemetri live (tanpa fitur pH).
- **Perangkat Kebun (`KF-03`, `KF-04`)**: Daftar perangkat bersama (tanpa penugasan Petani), pencarian, filter Online/Offline, detail perangkat, simulasi koneksi online/offline, serta tambah/edit/hapus perangkat khusus Owner.
- **Kontrol Aktuator (`KF-05`)**: Pengalihan mode **Manual / Otomatis** dengan konfirmasi, kontrol **Pompa nutrisi A**, **Pompa nutrisi B**, **Solenoid pengisian**, dan **Solenoid distribusi**, batas durasi manual aman, umpan balik ACK, serta **interlock level air rendah**.
- **Ambang Batas Sensor (`KF-06`)**: Pengaturan batas bawah/atas, target PPM, toleransi histeresis, rentang suhu larutan, serta batas pengisian & berhenti mengisi level air oleh Owner maupun Petani.
- **Perawatan & Kalibrasi Sensor TDS (`KF-07`, `KF-08`)**: Mode perawatan per perangkat yang mengunci kontrol operasional, perubahan mode, ambang batas, dan penghapusan perangkat lintas pengguna; alur panduan fisik → larutan standar & skala PPM (500/700) → draf → menunggu konfirmasi ESP (simulasi ACK / gagal / timeout) → verifikasi wajib sebelum selesai → kembali ke mode **Manual** dengan seluruh aktuator mati; dilengkapi **Riwayat kalibrasi**.
- **Grafik, Riwayat Sensor, & Ekspor Excel/CSV (`KF-09`)**: Filter perangkat, jenis sensor, rentang waktu, dan rentang tanggal, lengkap dengan ekspor berkas nyata **Excel (`.xlsx`)** dan **CSV (`;` UTF-8 BOM)**.
- **Notifikasi & Riwayat Aktivitas (`KF-10`, `KF-11`)**: Peringatan kondisi sensor/offline dengan status dibaca & tingkat bahaya, serta log audit aktivitas operasional dan administratif.
- **Penyimpanan Lokal**: Seluruh perubahan simulasi tersimpan otomatis secara lokal (`SharedPreferences`) dan dapat direset kapan saja melalui menu **Reset data simulasi awal**.

## Akun Simulasi Bawaan

| Peran | Username | Password | Status |
|---|---|---|---|
| Owner | `owner` | `owner123` | Aktif |
| Petani | `petani` | `petani123` | Aktif |
| Petani | `dewi` | `demo12345` | Aktif |
| Petani | `ahmad` | `demo12345` | Nonaktif (untuk uji tolak login) |

## Menjalankan & Build APK

```bash
flutter pub get
flutter test
flutter run
flutter build apk --release
```
