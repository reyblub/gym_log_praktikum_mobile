# GymLog - UTS Praktikum Mobile Programming

GymLog adalah aplikasi katalog latihan gym menggunakan Flutter dan Dart.
Versi praktikum menampilkan **32 data contoh dari JSON lokal** dalam 8 kategori.
Katalog, pencarian, filter, detail, ilustrasi kategori, dan favorit dapat dipakai
secara lokal. Data contoh disusun untuk demonstrasi antarmuka UTS.

## Mulai menjalankan

1. Ekstrak ZIP ke folder sederhana, misalnya
   `D:\FlutterProjects\gym_log_praktikum`.
2. Buka folder yang berisi **pubspec.yaml** di VS Code atau Android Studio.
3. Nyalakan emulator Android dan tunggu sampai layar awal Android siap.
4. Jalankan dari terminal folder project:

   ```bash
   flutter pub get
   flutter run
   ```

Jika diminta memilih perangkat, pilih emulator Android. Untuk melihat ID:

```bash
flutter devices
flutter run -d ID_PERANGKAT
```

Internet diperlukan untuk mengunduh package pada persiapan pertama. Setelah
aplikasi terpasang di Android, mode katalog lokal tidak membutuhkan internet.
Gunakan instalasi Flutter dan Android SDK yang sudah ada di laptop.
Constraint project: Dart >=3.5 dan Flutter >=3.24; JDK 17 untuk Android.

Preview melalui Chrome juga tersedia:

```bash
flutter run -d chrome
```

## Halaman dan fungsi

| Halaman | Fungsi |
| --- | --- |
| Beranda | Kelompok otot, pilihan latihan, dan pintasan menuju katalog |
| Latihan | Daftar latihan, pencarian, kategori, dan muat lebih banyak |
| Detail latihan | Kategori, alat, otot utama, panduan contoh, dan simpan favorit |
| Favorit | Membaca kembali latihan tersimpan, membuka detail, dan menghapus favorit |

Tiga tab memakai `NavigationBar` dan `IndexedStack`. Detail dibuka menggunakan
`Navigator.push` melalui `MaterialPageRoute`, dan ditutup dengan tombol kembali.
Warna, tema, dan struktur antarmuka melanjutkan project GymLog teori.
Nama launcher Android adalah **GymLog Praktikum** dan application ID memakai
akhiran `.practicum`, sehingga instalasinya terpisah dari GymLog teori.

## Data lokal dan pengolahannya

Berkas katalog: **assets/data/exercises.json**, didaftarkan pada `pubspec.yaml`.
JSON memuat `categories` dan `exercises`; setiap latihan memiliki `category_id`
yang menunjuk ke kategori. Ini adalah data contoh yang ditulis untuk praktikum.

`LocalExerciseService` membaca asset menggunakan `rootBundle.loadString`,
menguraikan JSON dengan `jsonDecode`, memeriksa struktur dan relasi kategori,
kemudian membentuk model `Exercise` dan `ExerciseCategory`.

Pencarian mengabaikan huruf besar/kecil dan mendukung nama latihan, kategori,
alat, serta otot. Pencarian dapat digabung dengan kategori. Katalog menampilkan
24 data terlebih dahulu; tombol **Muat lebih banyak** membuka sisa data.
Ilustrasi kategori memakai widget dan ikon Flutter yang tersedia secara lokal.

Favorit memakai `SharedPreferences`; salinan model disimpan sebagai JSON.
Data favorit tetap tersedia saat app dibuat ulang, selama data aplikasi tidak
dihapus. Mode lokal dan API memakai key penyimpanan berbeda.

## Struktur project

```text
assets/data/exercises.json             # 32 data dummy, 8 kategori
lib/
  main.dart                           # entry point, tab, route detail
  app_config.dart                     # mode lokal/API dan key favorit
  app_theme.dart                      # warna, tema, tipografi
  models/exercise.dart                 # model JSON lokal/API/favorit
  services/
    local_exercise_service.dart        # baca, cari, dan filter data lokal
    exercise_api.dart                  # interface bersama dan API wger
    favorite_storage.dart              # penyimpanan favorit
  controllers/gym_log_controller.dart # state halaman dan interaksi pengguna
  screens/                            # beranda, katalog, detail, favorit
  widgets/common_widgets.dart         # kartu, ilustrasi, tombol, status
test/                                 # unit test dan widget test
android/                              # project Android
web/                                  # project web
```

## Package

| Package | Fungsi |
| --- | --- |
| `shared_preferences` | Menyimpan favorit lokal |
| `shared_preferences_android` | Implementasi Android yang dipatok untuk kompatibilitas |
| `http` | Integrasi API opsional untuk pengembangan berikutnya |
| `html` | Mengubah deskripsi HTML pada data API menjadi teks |
| `cupertino_icons` | Ikon bawaan platform |
| `flutter_test` | Unit test dan widget test |

## Mode API untuk pengembangan berikutnya

Perintah biasa memilih **JSON lokal**. Implementasi API wger dari project teori
masih tersedia melalui interface yang sama. Untuk mencoba mode API:

```bash
flutter run --dart-define=USE_LOCAL_DATA=false
```

Mode API memerlukan internet dan memakai data/lisensi dari wger. Kegagalan API
menampilkan pesan error. Untuk kembali ke mode praktikum, hentikan app lalu
jalankan `flutter run` tanpa flag tersebut. Perubahan flag memerlukan menjalankan
ulang aplikasi, bukan hanya hot reload.

## Pemeriksaan pada komputer pengembang

```bash
flutter analyze
flutter test
```

Test tambahan memakai JSON yang benar-benar ada di assets, memeriksa pagination,
pencarian/filter, format rusak, detail, penyimpanan favorit, dan navigasi mode
lokal pada ukuran 360x780 serta 800x600. HTTP client diblokir dalam test lokal.
Fixture pada test API hanya untuk menguji implementasi API yang dipertahankan.

Perintah build Android jika diperlukan:

```bash
flutter build apk --release
```

Hasil APK: `build/app/outputs/flutter-apk/app-release.apk`.

**Status paket ini:** struktur JSON, pendaftaran asset, struktur project,
dan integritas ZIP diperiksa saat penyiapan. Flutter SDK/Android SDK tidak
tersedia di lingkungan penyiapan versi praktikum, sehingga `flutter analyze`,
`flutter test`, dan build APK belum dijalankan untuk revisi ini. Keberadaan test
di atas tidak berarti test tersebut sudah lolos. Jalankan pemeriksaan tersebut
serta uji emulator pada komputer yang memiliki Flutter.

## Sumber

- Data contoh lokal dan kode aplikasi: lihat `LICENSE` (MIT).
- Ikon: ikon bawaan Flutter/Material, tercantum pada lisensi framework.
- Assets Flutter: https://docs.flutter.dev/ui/assets/assets-and-images
- API opsional: https://wger.de/api/v2/
- Dokumentasi wger: https://wger.readthedocs.io/en/latest/api/api.html

Laporan praktikum dibuat terpisah setelah aplikasi berhasil dijalankan dan
hasil tampilannya diperiksa. ZIP ini berisi source project.
