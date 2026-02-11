# Proyek 4 - Modul 1

# Self Reflection — Single Responsibility Principle (SRP)

## Bagaimana prinsip SRP membantu saat menambahkan fitur *History Logger*?

Saat menambahkan fitur **History Logger**, saya merasakan secara langsung bagaimana prinsip **Single Responsibility Principle (SRP)** sangat membantu dalam proses pengembangan.

SRP menyatakan bahwa setiap kelas harus memiliki **satu tanggung jawab utama**.  
Dalam proyek ini, saya membagi tanggung jawab menjadi:

- **CounterController** -> Mengelola logika bisnis (perhitungan step, validasi input, dan pencatatan history)
- **CounterView** -> Bertanggung jawab terhadap tampilan dan interaksi pengguna

---

## Dampak SRP dalam Pengembangan

### 1. Perubahan Lebih Terarah
Saat menambahkan fitur history, saya hanya perlu memodifikasi bagian **Controller**, tanpa harus mengubah struktur View secara besar-besaran.

### 2. Kode Lebih Terorganisir
Logika seperti:
- Parsing input
- Validasi angka
- Penambahan history
- Pembatasan jumlah history

Semua berada di satu tempat, sehingga tidak tercampur dengan kode UI.

### 3. Mudah Dikembangkan
Karena struktur sudah terpisah dengan jelas:
- Saya bisa menambahkan limit history tanpa menyentuh tampilan.
- Saya bisa mengubah format penyimpanan history tanpa mengubah UI.
- Risiko bug akibat perubahan menjadi lebih kecil.

---

## Refleksi Pribadi

SRP membantu saya berpikir lebih terstruktur dalam merancang arsitektur aplikasi, terutama dalam membedakan antara:
- **Business Logic**
- **Presentation Layer**

Prinsip ini membuat kode lebih scalable dan lebih mudah dipahami.

---