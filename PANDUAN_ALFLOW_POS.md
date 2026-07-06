# Panduan Lengkap Aplikasi ALFlow POS (Point of Sale)

**ALFlow POS** adalah aplikasi kasir pintar berbasis Android yang dirancang khusus untuk mempermudah pencatatan transaksi, manajemen stok, dan pelaporan penjualan secara lokal (Offline-first) tanpa harus selalu terhubung ke internet.

---

## 📱 Spesifikasi Aplikasi
- **Platform**: Android & iOS (Dapat di-_build_ menggunakan Flutter)
- **Database**: SQLite (Local Database)
- **Status Data**: Disimpan secara aman di dalam penyimpanan perangkat HP. Aplikasi di-_build_ dengan keadaan bersih (Nol data) agar pengguna dapat menyusun etalasenya sendiri.
- **Arsitektur**: Menggunakan Riverpod untuk Manajemen State (*State Management*).

---

## 🌟 Deretan Fitur Utama

1. **Sistem Autentikasi (Keamanan)**
   - **Registrasi & Login**: Pengguna bisa membuat akun Admin dengan aman.
   - **Ingat Saya**: Fitur untuk menyimpan kredensial agar tidak perlu mengetik _username_ dan _password_ berulang kali.

2. **Dashboard (Ringkasan Bisnis)**
   - Menampilkan total pendapatan harian, mingguan, hingga bulanan.
   - Menampilkan grafik performa penjualan dan produk terlaris secara visual.

3. **Manajemen Produk & Kategori**
   - **Tambah & Edit Produk**: Memungkinkan untuk mengisi nama, harga jual, harga modal, jumlah stok, hingga stok minimal (untuk peringatan limit stok).
   - **Foto Produk**: Setiap produk bisa disematkan foto agar mudah dikenali di menu Kasir.
   - **Kategori Produk**: Produk dapat dikelompokkan ke dalam berbagai kategori (misal: Makanan, Minuman). Anda dapat menambah atau menghapus kategori.
   - **Tarik untuk Memperbarui (Pull-to-refresh)**: Cukup usap layar ke bawah untuk memuat ulang data stok dan produk terbaru.

4. **Kasir / Transaksi Pintar**
   - **Kalkulator Otomatis**: Ketuk produk, maka total belanjaan akan otomatis dihitung.
   - **Metode Pembayaran Ringkas**: Menyediakan metode **Tunai** dan **QRIS**.
   - **Cetak Struk/Laporan**: Dapat menghasilkan struk dalam bentuk PDF.

5. **Riwayat Penjualan (Laporan)**
   - Mencatat secara otomatis setiap transaksi yang berhasil.
   - Dilengkapi dengan fitur unduh Laporan Penjualan (PDF Report) untuk audit keuangan.

6. **Backup & Keamanan Data**
   - Karena berbasis *offline*, disediakan fitur untuk mencadangkan data (Backup Database) untuk mencegah hilangnya riwayat penjualan dan stok barang.

---

## 🛠️ Tata Cara Penggunaan Aplikasi

### Langkah 1: Pengaturan Awal (Registrasi)
Karena aplikasi dimulai tanpa data sama sekali (kosong), hal pertama yang harus dilakukan adalah membuat akun Admin.
1. Saat pertama kali membuka aplikasi, klik tulisan **"Daftar sekarang"** di bagian bawah layar Login.
2. Isi Username, Password, Nama Lengkap, dan Nama Bisnis Anda.
3. Klik **Daftar**, kemudian login menggunakan akun yang baru saja dibuat. Anda boleh mencentang **"Ingat saya"** agar _login_ selanjutnya lebih mudah.

### Langkah 2: Mengatur Kategori Produk
Sebelum menginput barang, buatlah keranjangnya terlebih dahulu.
1. Masuk ke menu **Produk** (di bilah navigasi bawah).
2. Klik tombol **+ Tambah** atau ikon pensil untuk Edit produk.
3. Di dalam menu tersebut, pada kolom **Pilih Kategori**, klik **"Tambah Kategori Baru..."**
4. Ketikkan nama kategorinya (misal: "Minuman") lalu Simpan. (Untuk menghapusnya, pilih kategorinya lalu klik ikon tempat sampah merah).

### Langkah 3: Menginput Data Produk
1. Buka kembali menu **Produk**.
2. Klik tombol **+ Tambah**.
3. Ketuk ikon Kamera untuk memasukkan foto barang.
4. Isi kelengkapan datanya: Nama, Harga Jual, Harga Beli/Modal, Stok awal, dan Stok Minimal.
5. Pilih Kategori yang sesuai.
6. Klik **Simpan**. (Coba *scroll*/tarik layar ke bawah jika produk tidak langsung muncul untuk me-*refresh* tampilan).

### Langkah 4: Melakukan Transaksi (Kasir)
1. Pindah ke menu **Dashboard Utama / Ikon Mesin Kasir** di tengah navigasi bawah.
2. Anda akan melihat deretan produk beserta foto dan stok tersisa.
3. Ketuk pada foto produk untuk menambahkannya ke keranjang pelanggan.
4. Total harga akan muncul. Setelah selesai, klik tombol **Bayar**.
5. Pilih metode pembayaran: **Tunai** atau **QRIS**.
6. Konfirmasi pembayaran. Transaksi selesai dan stok barang akan otomatis berkurang dari _database_!

### Langkah 5: Mengecek Laporan Penjualan
1. Pindah ke menu **Riwayat**.
2. Di sana Anda dapat melihat semua histori barang apa saja yang laku dan kapan terjual.
3. Anda bisa menggunakan fitur Ekspor/Cetak Laporan ke PDF untuk pencatatan pembukuan bulanan.

---
_Aplikasi dirancang se-intuitif mungkin layaknya aplikasi kasir modern (seperti Moka atau Pawoon), sehingga pegawai kasir yang baru pun dapat memahaminya dalam hitungan menit._
