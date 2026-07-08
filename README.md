# Panduan Lengkap Aplikasi ALFlow Kasir (Point of Sale)

**ALFlow Kasir** adalah aplikasi kasir pintar berbasis Android yang dirancang khusus untuk mempermudah pencatatan transaksi, manajemen stok, dan pelaporan penjualan secara lokal (Offline-first) tanpa harus selalu terhubung ke internet.

---

## 📱 Spesifikasi Aplikasi
- **Platform**: Android & iOS (Dibatasi pada ekosistem Flutter)
- **Database**: SQLite (Local Database)
- **Status Data**: Disimpan secara aman di dalam penyimpanan internal perangkat Anda. Seluruh data (termasuk foto produk, laporan PDF, dan backup) tersimpan 100% offline.
- **Arsitektur**: Menggunakan Riverpod untuk Manajemen State (*State Management*).

---

## 🌟 Deretan Fitur Utama

1. **Sistem Autentikasi & Pengaturan Akun**
   - **Registrasi & Login**: Mengamankan akses kasir dengan Username dan Password.
   - **Pengaturan Akun**: Mengganti Nama Lengkap, Nama Toko, Username, dan Password langsung di dalam aplikasi.
   - **Mode Gelap (Dark Mode)**: Tampilan nyaman untuk penggunaan di ruangan minim cahaya.

2. **Dashboard (Ringkasan Bisnis)**
   - Menampilkan ringkasan Kas (Uang Modal & Penjualan Hari Ini).
   - Menampilkan total pendapatan, grafik performa penjualan, dan produk terlaris secara visual.

3. **Sistem Shift Kasir (Buka/Tutup Kasir)**
   - **Buka Kasir**: Kasir harus memasukkan **Modal Awal** (*Opening Balance*) di laci kasir sebelum bisa memulai transaksi.
   - **Tutup Kasir**: Menghitung pencocokan jumlah uang fisik aktual di laci dengan sistem. Meminimalisir kebocoran kas toko.

4. **Manajemen Produk, Kategori, & Stok**
   - **Tambah & Edit Produk**: Mengisi nama, harga jual, harga modal, jumlah stok, hingga stok minimal (untuk notifikasi stok menipis).
   - **Kamera / Galeri**: Sematkan foto produk agar kasir mudah mengenali barang di sistem.
   - **Manajemen Stok Otomatis**: Stok otomatis berkurang setiap ada penjualan, dan Anda dapat memantau produk yang hampir habis di menu "Manajemen Stok".

5. **Kasir / Transaksi Pintar (Point of Sale)**
   - **Kalkulator Otomatis**: Ketuk produk, maka total belanjaan akan otomatis dihitung. Mendukung penambahan diskon dan perhitungan otomatis uang kembalian.
   - **Metode Pembayaran**: Menyediakan metode **Tunai** dan **QRIS**.

6. **Pengeluaran Operasional (Expenses)**
   - Mencatat pengeluaran harian toko (seperti: bayar listrik, beli galon, gaji karyawan, dll) agar perhitungan Laba Bersih akurat.

7. **Riwayat Penjualan & Laporan Keuangan (PDF)**
   - **Riwayat Transaksi**: Melihat semua riwayat barang yang laku, dilengkapi fitur **Filter Tanggal** pintar (Hari ini, 7 Hari Terakhir, 30 Hari Terakhir).
   - **Laporan Keuangan Otomatis**: Menghitung secara otomatis Omset, Harga Pokok Penjualan (HPP), Pengeluaran, Laba Kotor, dan **Laba Bersih**.
   - **Cetak Laporan PDF**: Unduh laporan keuangan dan riwayat transaksi langsung ke bentuk PDF.

8. **Backup & Restore Database**
   - Mengamankan data toko Anda dari kerusakan perangkat. Ekspor seluruh *database* (.db) ke memori internal, dan kembalikan (*Restore*) sewaktu-waktu jika Anda berpindah HP.

---

## 🛠️ Tata Cara Penggunaan Aplikasi (Langkah-langkah Praktis)

### Langkah 1: Instalasi & Perizinan (Awal)
1. Saat pertama kali aplikasi di-install dan dibuka, sistem Android akan meminta **Izin Akses File (All files access)**.
2. Anda **WAJIB** menekan **Izinkan (Allow access to manage all files)**. Ini berfungsi agar aplikasi bisa membuat folder laporan PDF, menyimpan foto produk, dan menyimpan *database backup* di HP Anda.

### Langkah 2: Registrasi Akun Toko
Karena aplikasi dimulai tanpa data sama sekali (kosong), buatlah akun Anda:
1. Klik **"Daftar sekarang"** di bagian bawah layar Login.
2. Isi Username, Password, Nama Lengkap, dan Nama Toko/Bisnis Anda.
3. Klik **Daftar**, lalu silakan **Login** dengan akun tersebut.

### Langkah 3: Menginput Data Produk
Sebelum bisa berjualan, Anda harus mengisi etalase toko.
1. Masuk ke tab **Produk** (di bilah navigasi bawah bagian kotak-kotak).
2. Klik tombol **+ (Tambah Produk)**.
3. Anda bisa menambah Kategori (misal: "Minuman") dengan klik "Tambah Kategori Baru...".
4. Ketuk ikon gambar untuk memotret atau memilih foto produk dari Galeri.
5. Isi **Harga Jual**, **Harga Beli/Modal** (penting untuk hitung laba/rugi), **Stok Awal**, dan **Stok Minimum**.
6. Klik **Simpan**.

### Langkah 4: Buka Kasir (Memulai Shift Hari Ini)
Untuk mencegah transaksi palsu, kasir diwajibkan melakukan pembukaan kas.
1. Pindah ke tab **Dashboard Utama**.
2. Klik tombol merah **"Buka Kasir"** di bagian atas layar.
3. Masukkan jumlah **Modal Awal** (Uang receh/kembalian fisik yang ada di laci saat toko baru buka).
4. Klik Konfirmasi. Tombol tengah navigasi (ikon Mesin Kasir) sekarang sudah menyala.

### Langkah 5: Melakukan Transaksi Penjualan
1. Tekan ikon biru bulat **Mesin Kasir** di tengah menu navigasi bawah.
2. Ketuk produk yang dibeli pelanggan (tekan berkali-kali untuk menambah jumlah *quantity*).
3. Klik **Bayar** di bawah layar.
4. Masukkan jumlah **Uang Diterima** (jika pelanggan bayar tunai), aplikasi akan menghitung otomatis uang **Kembalian**.
5. Klik **Konfirmasi Pembayaran**. (Stok barang akan otomatis berkurang).

### Langkah 6: Mencatat Pengeluaran Operasional Toko
Jika ada uang kas yang keluar untuk operasional:
1. Pergi ke tab **Lainnya** (Pojok kanan bawah).
2. Pilih menu **Pengeluaran**.
3. Klik Tambah, lalu isikan nominal, kategori (misal: Listrik/Air), dan Catatannya.
4. Ini akan memotong Laba Bersih Anda nanti.

### Langkah 7: Mengecek & Mengunduh Laporan Keuangan
Di akhir hari / bulan, Anda bisa melihat hasilnya:
1. Pergi ke tab **Lainnya**, lalu pilih **Laporan Keuangan**.
2. Anda akan melihat grafik penjualan, Laba Kotor, dan Laba Bersih.
3. Untuk mengekspor dokumennya, klik **ikon PDF** di pojok kanan atas.
4. Laporan akan tersimpan di dalam folder `Documents/ALFlow_Kasir/` di *File Manager* HP Anda.

### Langkah 8: Tutup Kasir (Akhir Shift)
Saat toko tutup:
1. Kembali ke **Dashboard Utama**.
2. Klik tombol **"Tutup Kasir"** di bagian atas (menggantikan tombol Buka Kasir).
3. Hitung jumlah uang fisik yang ada di laci Anda secara nyata, lalu masukkan nominal tersebut.
4. Sistem akan menutup shift dan siap untuk buka toko lagi keesokan harinya.

### Langkah 9: Mengamankan Data (Backup)
Rutinkan langkah ini seminggu / sebulan sekali:
1. Pergi ke tab **Lainnya** -> **Backup & Restore**.
2. Klik **Buat Backup Baru**. File database toko Anda akan aman tersimpan secara fisik di memori HP. Anda bisa mencopy file tersebut ke Google Drive sebagai pengamanan ekstra!

---
_Aplikasi ini dirancang se-intuitif mungkin layaknya aplikasi kasir premium, sehingga kasir baru pun dapat memahaminya dalam hitungan menit tanpa pelatihan khusus._
