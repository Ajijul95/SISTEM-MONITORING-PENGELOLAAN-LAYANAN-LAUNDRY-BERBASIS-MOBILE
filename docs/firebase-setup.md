# HDP LAUNDRY: Firebase Setup

Aplikasi memakai Firebase Authentication dan Cloud Firestore. Pengelolaan akun memakai Firebase Auth client pada Firebase app kedua dan Firestore Rules; Cloud Functions/Admin SDK tidak digunakan. Pastikan `android/app/google-services.json` menunjuk ke project Firebase yang benar.

## Persiapan

1. Aktifkan Email/Password di Firebase Authentication.
2. Buat Cloud Firestore pada project tersebut.
3. Pasang Firebase CLI dan login dengan akun yang berhak deploy aturan.
4. Dari root repository, jalankan `firebase use --add` untuk memilih project.
5. Deploy aturan Firestore bila diperlukan: `firebase deploy --only firestore:rules`.
6. Jalankan `flutter pub get`, kemudian `flutter run`.

## Owner pertama

Buat satu user awal melalui Firebase Console > Authentication > Users. Salin UID-nya, lalu buat `users/{uid}` di Firestore dengan field `uid`, `name`, `email`, `phone`, `role: "Owner"`, dan `isActive: true`. Owner dapat membuat akun Petugas dari menu **Kelola Akun**. Pelanggan baru mendaftar sendiri melalui tombol **Daftar sebagai pelanggan** di halaman login; Firestore Rules membatasi profil baru ke UID Auth miliknya sendiri dengan role `Pelanggan`.

## Alur aplikasi

- Hanya Owner/Petugas yang membuat order; pelanggan hanya membaca order miliknya.
- Order baru mendapat nomor berurutan `HDP-001`, `HDP-002`, dan seterusnya melalui transaksi counter Firestore.
- Status cucian tersimpan pada `laundryStatus`: `Antrean`, `Di Cuci`, `Siap Ambil`, `Selesai`.
- Order dibuat dengan `paymentStatus: "Belum Dibayar"` dan `paymentMethod: null`. Petugas memilih Cash/QRIS saat mengonfirmasi pembayaran.
- Transaksi hanya dihitung sebagai omzet setelah `paymentStatus` menjadi `Lunas`; approval mengisi jumlah, waktu, dan identitas Petugas sekali saja.
- Laporan Owner menyediakan filter periode dan ekspor PDF/Excel. Nota order memuat hanya field yang ditentukan aplikasi.

Firestore Rules berada di `firebase/firestore.rules`, dan jalur deploy didefinisikan dalam `firebase.json`. Verifikasi akses melalui Firebase Emulator sebelum merilis jika tersedia; deploy aturan ke project aktif sebelum pengujian multi-akun. Penambahan akun membuat kredensial melalui Firebase Auth app kedua agar sesi Owner tetap aktif. Penghapusan akun dari aplikasi hanya menghapus profil Firestore; penghapusan user Firebase Auth lain memerlukan hak Admin dan tidak dilakukan. Aplikasi tidak menyediakan foto profil.

## Data lama

Dokumen order lama tidak dihapus. Tampilan mengenali beberapa nilai status lama, tetapi order baru dan perubahan status memakai field `laundryStatus` yang baru. Data lokal SharedPreferences tidak otomatis dimigrasikan ke Firestore.
